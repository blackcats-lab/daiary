import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/exceptions/photo_failure.dart';
import '../../../photo/presentation/providers/photo_list_notifier.dart';
import '../../data/repositories/photo_edit_repository.dart';
import '../../domain/color_matrix.dart';
import '../../domain/filter_presets.dart';
import 'photo_edit_state.dart';

part 'photo_edit_notifier.g.dart';

/// 写真編集画面の状態管理。photoId を family で受ける。
@riverpod
class PhotoEditNotifier extends _$PhotoEditNotifier {
  @override
  PhotoEditState build(String photoId) => const PhotoEditState();

  /// 編集対象のローカルファイルを設定する（画面初期化時に渡す）。
  void setWorkingFile(File file) {
    state = state.copyWith(workingFile: file);
  }

  void selectFilter(int index) => state = state.copyWith(filterIndex: index);
  void setBrightness(double v) => state = state.copyWith(brightness: v);
  void setContrast(double v) => state = state.copyWith(contrast: v);
  void setSaturation(double v) => state = state.copyWith(saturation: v);

  /// プレビュー / 保存に使う合成カラーマトリクス。
  /// 適用順: フィルタ → 彩度 → コントラスト → 明るさ。
  List<double> get currentMatrix {
    return ColorMatrix.compose([
      FilterPresets.all[state.filterIndex].matrix,
      ColorMatrix.saturation(state.saturation),
      ColorMatrix.contrast(state.contrast),
      ColorMatrix.brightness(state.brightness),
    ]);
  }

  /// image_cropper でトリミング/回転し、結果を workingFile に反映する。
  Future<void> crop() async {
    final file = state.workingFile;
    if (file == null) return;
    final cropped = await ref.read(photoEditRepositoryProvider).crop(file);
    if (cropped != null) {
      state = state.copyWith(workingFile: cropped);
    }
  }

  /// 調整・フィルタを焼き込んで Storage へ上書き保存する。
  /// 成功したら saved=true（画面側で pop + 詳細 reload）。
  Future<void> save({
    required String storagePath,
    required String thumbnailPath,
  }) async {
    final file = state.workingFile;
    if (file == null || state.saving) return;
    state = state.copyWith(saving: true, errorMessage: null);
    try {
      final repo = ref.read(photoEditRepositoryProvider);
      // 調整・フィルタがあれば焼き込み、無ければトリミング結果をそのまま使う
      final rendered = state.hasAdjustments
          ? await repo.applyMatrix(file, currentMatrix)
          : file;
      await repo.saveEdited(
        photoId: photoId,
        storagePath: storagePath,
        thumbnailPath: thumbnailPath,
        editedFile: rendered,
      );
      // フィードのサムネを最新化（署名 URL は再取得される）
      await ref.read(photoListProvider.notifier).refresh();
      state = state.copyWith(saving: false, saved: true);
    } on PhotoFailure catch (f) {
      state = state.copyWith(saving: false, errorMessage: f.message);
    } catch (e) {
      state = state.copyWith(saving: false, errorMessage: '保存に失敗しました: $e');
    }
  }
}
