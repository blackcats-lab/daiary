import 'dart:io';

import 'package:flutter/painting.dart' show decodeImageFromList;
import 'package:image_cropper/image_cropper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/exceptions/photo_failure.dart';
import '../../../../services/supabase_service.dart';
import '../../../camera/data/services/image_processor.dart';
import '../../../camera/presentation/providers/image_capture_notifier.dart';
import '../services/photo_edit_renderer.dart';

part 'photo_edit_repository.g.dart';

/// 写真編集（トリミング・回転・フィルタ）の永続化を担う Repository。
class PhotoEditRepository {
  PhotoEditRepository({
    required ImageProcessor processor,
    required PhotoEditRenderer renderer,
    SupabaseClient? client,
  })  : _processor = processor,
        _renderer = renderer,
        _client = client ?? SupabaseService.client;

  final ImageProcessor _processor;
  final PhotoEditRenderer _renderer;
  final SupabaseClient _client;

  static const _bucket = 'photos';

  /// image_cropper のネイティブ UI でトリミング/回転する。
  /// キャンセル時は null を返す。
  Future<File?> crop(File source) async {
    final result = await ImageCropper().cropImage(
      sourcePath: source.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'トリミング',
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'トリミング'),
      ],
    );
    return result == null ? null : File(result.path);
  }

  /// フィルタ/調整のマトリクスを焼き込んだ JPEG を生成する。
  Future<File> applyMatrix(File source, List<double> matrix) {
    return _renderer.render(source, matrix);
  }

  /// 編集後の画像を Storage に上書き保存し、photos の寸法・サイズを更新する。
  ///
  /// [storagePath] / [thumbnailPath] は既存の写真パス（同パス upsert で上書き）。
  /// 戻り値はキャッシュバスター付きで再取得するための新しい署名なしパス情報。
  Future<void> saveEdited({
    required String photoId,
    required String storagePath,
    required String thumbnailPath,
    required File editedFile,
  }) async {
    final originalBytes = await editedFile.readAsBytes();
    final dims = await _decodeDimensions(editedFile);

    final thumbFile = await _processor.generateThumbnail(editedFile);
    final thumbBytes = await thumbFile.readAsBytes();

    try {
      await Future.wait([
        _client.storage.from(_bucket).uploadBinary(
              storagePath,
              originalBytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                cacheControl: '3600',
                upsert: true,
              ),
            ),
        _client.storage.from(_bucket).uploadBinary(
              thumbnailPath,
              thumbBytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                cacheControl: '3600',
                upsert: true,
              ),
            ),
      ]);
    } on StorageException catch (e) {
      throw PhotoFailure('upload_failed', '画像の保存に失敗しました: ${e.message}');
    }

    // 寸法・ファイルサイズを更新（トリミングで変わるため）
    final body = <String, dynamic>{
      'file_size': originalBytes.length,
      if (dims != null) ...{'width': dims.$1, 'height': dims.$2},
    };
    try {
      final response = await SupabaseService.invokeFunction(
        'photos/$photoId',
        method: HttpMethod.patch,
        body: body,
      );
      if (response.status != 200) {
        throw PhotoFailure('update_failed', '寸法の更新に失敗しました');
      }
    } on FunctionException catch (e) {
      throw PhotoFailure('update_failed', '寸法の更新に失敗しました (${e.status})');
    } finally {
      await thumbFile.delete().catchError((_) => thumbFile);
    }
  }

  Future<(int, int)?> _decodeDimensions(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = await decodeImageFromList(bytes);
      final dims = (image.width, image.height);
      image.dispose();
      return dims;
    } catch (_) {
      return null;
    }
  }
}

@riverpod
PhotoEditRepository photoEditRepository(Ref ref) {
  return PhotoEditRepository(
    processor: ref.read(imageProcessorProvider),
    renderer: PhotoEditRenderer(),
  );
}
