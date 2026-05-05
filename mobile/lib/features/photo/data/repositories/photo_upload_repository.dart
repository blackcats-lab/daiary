import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/exceptions/photo_failure.dart';
import '../../../../services/supabase_service.dart';
import '../../../camera/data/services/image_processor.dart';
import '../../../camera/domain/entities/captured_image.dart';
import '../../../camera/presentation/providers/image_capture_notifier.dart';
import '../../domain/entities/uploaded_photo.dart';

part 'photo_upload_repository.g.dart';

/// 撮影/取り込み済みの画像を Supabase Storage にアップロードし、
/// photos Edge Function 経由でメタデータを作成する Repository。
class PhotoUploadRepository {
  PhotoUploadRepository({
    required ImageProcessor processor,
    SupabaseClient? client,
  })  : _processor = processor,
        _client = client ?? SupabaseService.client;

  final ImageProcessor _processor;
  final SupabaseClient _client;

  static const _uuid = Uuid();
  static const _bucket = 'photos';

  Future<UploadedPhoto> upload(CapturedImage image) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw PhotoFailure('unauthenticated', 'ログインが必要です');
    }

    final photoId = _uuid.v4();
    final originalPath = '$userId/$photoId.jpg';
    final thumbPath = '$userId/thumb_$photoId.jpg';

    File? thumbFile;
    try {
      thumbFile = await _processor.generateThumbnail(image.processedFile);

      final originalBytes = await image.processedFile.readAsBytes();
      final thumbBytes = await thumbFile.readAsBytes();

      try {
        await Future.wait([
          _client.storage.from(_bucket).uploadBinary(
                originalPath,
                originalBytes,
                fileOptions: const FileOptions(
                  contentType: 'image/jpeg',
                  cacheControl: '3600',
                  upsert: false,
                ),
              ),
          _client.storage.from(_bucket).uploadBinary(
                thumbPath,
                thumbBytes,
                fileOptions: const FileOptions(
                  contentType: 'image/jpeg',
                  cacheControl: '3600',
                  upsert: false,
                ),
              ),
        ]);
      } on StorageException catch (e) {
        throw PhotoFailure('upload_failed', e.message);
      }

      final body = <String, dynamic>{
        'storage_path': originalPath,
        'thumbnail_path': thumbPath,
        'file_size': image.sizeBytes,
        'original_filename': '$photoId.jpg',
        if (image.width > 0) 'width': image.width,
        if (image.height > 0) 'height': image.height,
      };

      FunctionResponse response;
      try {
        response = await SupabaseService.invokeFunction('photos', body: body);
      } on FunctionException catch (e) {
        await _compensateRemove([originalPath, thumbPath]);
        throw PhotoFailure('metadata_failed', 'メタデータの作成に失敗しました (${e.status})');
      }

      if (response.status != 201) {
        await _compensateRemove([originalPath, thumbPath]);
        throw PhotoFailure(
          'metadata_failed',
          'メタデータの作成に失敗しました (status=${response.status})',
        );
      }

      final data = response.data;
      if (data is! Map || data['photo'] is! Map) {
        await _compensateRemove([originalPath, thumbPath]);
        throw PhotoFailure('metadata_failed', '想定外のレスポンス形式です');
      }
      final photo = (data['photo'] as Map).cast<String, dynamic>();
      return UploadedPhoto(
        id: photo['id'] as String,
        storagePath: photo['storage_path'] as String,
        thumbnailPath: (photo['thumbnail_path'] as String?) ?? thumbPath,
        createdAt: DateTime.parse(photo['created_at'] as String),
      );
    } on PhotoFailure {
      rethrow;
    } on SocketException catch (e) {
      throw PhotoFailure('network', 'ネットワークに接続できませんでした: ${e.message}');
    } catch (e) {
      throw PhotoFailure('unknown', '予期せぬエラーが発生しました: $e');
    } finally {
      if (thumbFile != null) {
        unawaited(thumbFile.delete().catchError((_) => thumbFile!));
      }
    }
  }

  Future<void> _compensateRemove(List<String> paths) async {
    try {
      await _client.storage.from(_bucket).remove(paths);
    } catch (_) {
      // 補償削除のエラーは握りつぶす（孤児が残るがメイン処理の失敗を上書きしない）
    }
  }
}

@Riverpod(keepAlive: false)
PhotoUploadRepository photoUploadRepository(Ref ref) {
  return PhotoUploadRepository(processor: ref.read(imageProcessorProvider));
}
