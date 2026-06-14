import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/exceptions/photo_failure.dart';
import '../../data/repositories/photo_list_repository.dart';
import 'photo_detail_state.dart';
import 'photo_list_notifier.dart';
import 'photo_search_notifier.dart';

part 'photo_detail_notifier.g.dart';

/// 写真詳細画面の状態管理。photoId を family で受ける。
/// お気に入りトグル / 論理削除 / 共有用 File 取得をオーケストレートする。
@Riverpod(keepAlive: false)
class PhotoDetailNotifier extends _$PhotoDetailNotifier {
  @override
  PhotoDetailState build(String photoId) => const PhotoDetailState.initial();

  Future<void> load() async {
    state = const PhotoDetailState.loading();
    try {
      final repo = ref.read(photoListRepositoryProvider);
      final detail = await repo.fetchDetail(photoId);
      final url = await repo.createOriginalSignedUrl(detail.storagePath);
      state = PhotoDetailState.loaded(
        detail: detail,
        signedOriginalUrl: url,
      );
    } on PhotoFailure catch (f) {
      state = PhotoDetailState.error(f);
    } catch (e) {
      state = PhotoDetailState.error(
        PhotoFailure('unknown', '予期せぬエラーが発生しました: $e'),
      );
    }
  }

  Future<void> toggleFavorite() async {
    final s = state;
    if (s is! PhotoDetailLoaded || s.favoriteUpdating) return;
    final next = !s.detail.isFavorite;

    // 楽観更新
    state = s.copyWith(
      favoriteUpdating: true,
      detail: s.detail.copyWith(isFavorite: next),
    );

    try {
      final repo = ref.read(photoListRepositoryProvider);
      final actual = await repo.toggleFavorite(photoId, next);
      final current = state;
      if (current is PhotoDetailLoaded) {
        state = current.copyWith(
          favoriteUpdating: false,
          detail: current.detail.copyWith(isFavorite: actual),
        );
      }
      ref
          .read(photoListProvider.notifier)
          .updateFavoriteOptimistically(photoId, actual);
      ref
          .read(photoSearchProvider.notifier)
          .updateFavoriteOptimistically(photoId, actual);
    } on PhotoFailure catch (_) {
      // ロールバック
      state = s.copyWith(favoriteUpdating: false);
      rethrow;
    } catch (_) {
      state = s.copyWith(favoriteUpdating: false);
      rethrow;
    }
  }

  Future<void> delete() async {
    final s = state;
    if (s is! PhotoDetailLoaded || s.deleting) return;
    state = s.copyWith(deleting: true);
    try {
      await ref.read(photoListRepositoryProvider).softDelete(photoId);
      ref.read(photoListProvider.notifier).removeOptimistically(photoId);
      ref.read(photoSearchProvider.notifier).removeOptimistically(photoId);
      final current = state;
      if (current is PhotoDetailLoaded) {
        state = current.copyWith(deleting: false, deleted: true);
      }
    } on PhotoFailure catch (_) {
      state = s.copyWith(deleting: false);
      rethrow;
    } catch (_) {
      state = s.copyWith(deleting: false);
      rethrow;
    }
  }

  /// caption を手動更新する。空文字は消去（null 送信）。
  Future<void> updateCaption(String? caption) async {
    await _updateMeta(caption: caption, updateCaption: true);
  }

  /// ai_tags を手動更新する。
  Future<void> updateTags(List<String> tags) async {
    await _updateMeta(aiTags: tags);
  }

  Future<void> _updateMeta({
    String? caption,
    bool updateCaption = false,
    List<String>? aiTags,
  }) async {
    final s = state;
    if (s is! PhotoDetailLoaded || s.metaUpdating) return;
    state = s.copyWith(metaUpdating: true);
    try {
      final updated = await ref.read(photoListRepositoryProvider).updateMeta(
            photoId,
            caption: caption,
            updateCaption: updateCaption,
            aiTags: aiTags,
          );
      final current = state;
      if (current is PhotoDetailLoaded) {
        state = current.copyWith(metaUpdating: false, detail: updated);
      }
      // 一覧・検索結果のタグオーバーレイ / caption を最新化
      ref.read(photoListProvider.notifier).updateItemOptimistically(
            photoId,
            aiTags: updated.aiTags,
            caption: updated.caption,
          );
      ref.read(photoSearchProvider.notifier).updateItemOptimistically(
            photoId,
            aiTags: updated.aiTags,
            caption: updated.caption,
          );
    } on PhotoFailure catch (_) {
      state = s.copyWith(metaUpdating: false);
      rethrow;
    } catch (_) {
      state = s.copyWith(metaUpdating: false);
      rethrow;
    }
  }

  /// 写真編集から戻った後に詳細を再取得する。
  /// 署名 URL に再取得時刻のクエリを付け、編集後の画像で
  /// cached_network_image のキャッシュを確実に更新する。
  Future<void> reloadAfterEdit() async {
    final s = state;
    if (s is! PhotoDetailLoaded) return;
    try {
      final repo = ref.read(photoListRepositoryProvider);
      final detail = await repo.fetchDetail(photoId);
      final url = await repo.createOriginalSignedUrl(detail.storagePath);
      final busted = url == null
          ? null
          : '$url&v=${DateTime.now().millisecondsSinceEpoch}';
      state =
          PhotoDetailState.loaded(detail: detail, signedOriginalUrl: busted);
    } on PhotoFailure catch (f) {
      state = PhotoDetailState.error(f);
    }
  }

  /// 共有 / AI 再生成用に Storage から原寸を一時ファイルに落として返す。
  Future<File?> prepareLocalFile() async {
    final s = state;
    if (s is! PhotoDetailLoaded) return null;
    return ref
        .read(photoListRepositoryProvider)
        .downloadOriginalToTmp(s.detail.storagePath);
  }

  void setSharing(bool value) {
    final s = state;
    if (s is! PhotoDetailLoaded) return;
    state = s.copyWith(sharing: value);
  }

  void setPreparingAi(bool value) {
    final s = state;
    if (s is! PhotoDetailLoaded) return;
    state = s.copyWith(preparingAi: value);
  }
}
