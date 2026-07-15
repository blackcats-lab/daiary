import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/exceptions/album_failure.dart';
import '../../data/repositories/album_repository.dart';
import 'album_detail_state.dart';
import 'album_list_notifier.dart';

part 'album_detail_notifier.g.dart';

/// アルバム詳細画面の状態管理。albumId を family で受ける。
@Riverpod(keepAlive: false)
class AlbumDetailNotifier extends _$AlbumDetailNotifier {
  @override
  AlbumDetailState build(String albumId) => const AlbumDetailState.initial();

  Future<void> load() async {
    state = const AlbumDetailState.loading();
    await _fetch();
  }

  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    try {
      final repo = ref.read(albumRepositoryProvider);
      final detail = await repo.fetchDetail(albumId);
      // サムネイル URL を並列取得
      final urls = await Future.wait(
        detail.photos.map((p) async {
          final path = p.thumbnailPath ?? p.storagePath;
          return MapEntry(p.id, await repo.createSignedUrl(path));
        }),
      );
      state = AlbumDetailState.loaded(
        detail: detail,
        signedUrls: Map.fromEntries(urls),
      );
    } on AlbumFailure catch (f) {
      state = AlbumDetailState.error(f);
    } catch (e) {
      state = AlbumDetailState.error(
        AlbumFailure('unknown', '予期せぬエラーが発生しました: $e'),
      );
    }
  }

  // ===== 選択モード =====

  void toggleSelectionMode() {
    final s = state;
    if (s is! AlbumDetailLoaded) return;
    state = s.copyWith(
      selectionMode: !s.selectionMode,
      selected: const {},
    );
  }

  void togglePhoto(String photoId) {
    final s = state;
    if (s is! AlbumDetailLoaded) return;
    final next = Set<String>.from(s.selected);
    if (next.contains(photoId)) {
      next.remove(photoId);
    } else {
      next.add(photoId);
    }
    state = s.copyWith(selected: next);
  }

  // ===== 編集 =====

  Future<void> updateName(String name) async {
    final s = state;
    if (s is! AlbumDetailLoaded || s.updating) return;
    state = s.copyWith(updating: true);
    try {
      final updated = await ref
          .read(albumRepositoryProvider)
          .update(albumId, name: name.trim());
      // await 中に state が変わっている可能性があるため、取得前のスナップショット
      // ではなく最新 state に反映する（cover_thumbnail_path / photo_count は維持）
      final latest = state;
      if (latest is AlbumDetailLoaded) {
        final newSummary = latest.detail.album.copyWith(
          name: updated.name,
          updatedAt: updated.updatedAt,
        );
        state = latest.copyWith(
          updating: false,
          detail: latest.detail.copyWith(album: newSummary),
        );
      }
      ref
          .read(albumListProvider.notifier)
          .updateNameOptimistically(albumId, updated.name);
    } on AlbumFailure catch (_) {
      _collapseUpdating();
      rethrow;
    } catch (_) {
      _collapseUpdating();
      rethrow;
    }
  }

  void _collapseUpdating() {
    final latest = state;
    if (latest is AlbumDetailLoaded && latest.updating) {
      state = latest.copyWith(updating: false);
    }
  }

  // ===== 削除 =====

  Future<void> deleteAlbum() async {
    final s = state;
    if (s is! AlbumDetailLoaded || s.deleting) return;
    state = s.copyWith(deleting: true);
    try {
      await ref.read(albumRepositoryProvider).delete(albumId);
      ref.read(albumListProvider.notifier).removeOptimistically(albumId);
      final current = state;
      if (current is AlbumDetailLoaded) {
        state = current.copyWith(deleting: false, deleted: true);
      }
    } on AlbumFailure catch (_) {
      state = s.copyWith(deleting: false);
      rethrow;
    } catch (_) {
      state = s.copyWith(deleting: false);
      rethrow;
    }
  }

  /// 選択モードで選んだ写真をアルバムから一括除外する。
  /// 写真自体は削除されない（中間テーブルから消すだけ）。
  Future<void> removeSelected() async {
    final s = state;
    if (s is! AlbumDetailLoaded || s.removingPhotos) return;
    if (s.selected.isEmpty) return;
    final ids = s.selected.toList();

    state = s.copyWith(removingPhotos: true);
    try {
      final removed =
          await ref.read(albumRepositoryProvider).removePhotos(albumId, ids);
      final removedSet = removed.toSet();
      // 楽観的に除去
      final newPhotos =
          s.detail.photos.where((p) => !removedSet.contains(p.id)).toList();
      state = s.copyWith(
        removingPhotos: false,
        selectionMode: false,
        selected: const {},
        detail: s.detail.copyWith(
          photos: newPhotos,
          album: s.detail.album.copyWith(photoCount: newPhotos.length),
        ),
      );
      // アルバム一覧（keepAlive）の件数・カバーも最新化する
      ref.read(albumListProvider.notifier).refresh();
    } on AlbumFailure catch (_) {
      state = s.copyWith(removingPhotos: false);
      rethrow;
    } catch (_) {
      state = s.copyWith(removingPhotos: false);
      rethrow;
    }
  }

  /// 写真追加 picker から戻ってきた直後に呼ぶ。
  Future<void> onPhotosAdded() async {
    await refresh();
    // アルバム一覧（keepAlive）は自動更新されないため、件数・カバーを最新化する
    ref.read(albumListProvider.notifier).refresh();
  }
}
