import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/exceptions/album_failure.dart';
import '../../data/repositories/album_repository.dart';
import '../../domain/entities/add_photos_result.dart';
import 'album_detail_notifier.dart';
import 'album_detail_state.dart';
import 'album_photo_picker_state.dart';

part 'album_photo_picker_notifier.g.dart';

/// 写真ピッカー画面のローカル状態。
/// 写真ソースは photoListProvider を画面側で watch するので、
/// このノティファイアは選択状態と submit のみ管理する。
@Riverpod(keepAlive: false)
class AlbumPhotoPickerNotifier extends _$AlbumPhotoPickerNotifier {
  @override
  AlbumPhotoPickerState build(String albumId) {
    final detail = ref.watch(albumDetailProvider(albumId));
    final existing = detail is AlbumDetailLoaded
        ? detail.detail.photos.map((p) => p.id).toSet()
        : <String>{};
    return AlbumPhotoPickerState(existingIds: existing);
  }

  void toggle(String photoId) {
    if (state.existingIds.contains(photoId)) return;
    final next = Set<String>.from(state.selected);
    if (next.contains(photoId)) {
      next.remove(photoId);
    } else {
      next.add(photoId);
    }
    state = state.copyWith(selected: next);
  }

  /// アルバムに写真を追加する。成功時は AddPhotosResult を返し、
  /// 画面側で skipped 件数を SnackBar 表示するなどに使う。
  Future<AddPhotosResult> submit() async {
    if (state.submitting) {
      throw AlbumFailure('add_photos_failed', '送信中です');
    }
    if (state.selected.isEmpty) {
      throw AlbumFailure('add_photos_failed', '写真が選択されていません');
    }
    state = state.copyWith(submitting: true);
    try {
      final result = await ref
          .read(albumRepositoryProvider)
          .addPhotos(albumId, state.selected.toList());
      // 詳細側を最新化
      await ref.read(albumDetailProvider(albumId).notifier).onPhotosAdded();
      return result;
    } finally {
      state = state.copyWith(submitting: false);
    }
  }
}
