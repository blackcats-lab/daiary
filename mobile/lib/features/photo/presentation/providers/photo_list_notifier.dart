import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/exceptions/photo_failure.dart';
import '../../data/repositories/photo_list_repository.dart';
import '../../domain/entities/photo_list_item.dart';
import 'photo_list_state.dart';
import 'photo_list_view.dart';

part 'photo_list_notifier.g.dart';

/// 写真一覧の状態管理。タブ切替で破棄しないため keepAlive: true。
@Riverpod(keepAlive: true)
class PhotoListNotifier extends _$PhotoListNotifier {
  static const int _pageSize = 30;

  @override
  PhotoListState build() => const PhotoListState.initial();

  /// 初回読み込み。state が initial / error の時のみ実行する。
  /// 既に loaded / loading の場合は何もしない（タブ復帰時の不要な再読込を回避）。
  Future<void> load() async {
    if (state is PhotoListLoaded || state is PhotoListLoading) return;
    await _fetchInitial();
  }

  /// 強制再読み込み。Pull-to-refresh / 撮影完了時に呼ぶ。
  Future<void> refresh() async {
    await _fetchInitial();
  }

  Future<void> _fetchInitial() async {
    state = const PhotoListState.loading();
    try {
      final repo = ref.read(photoListRepositoryProvider);
      final page = await repo.fetchPage(limit: _pageSize);
      final views = await _buildViews(repo, page.items);
      state = PhotoListState.loaded(
        items: views,
        nextBefore: page.nextBefore,
      );
    } on PhotoFailure catch (f) {
      state = PhotoListState.error(f);
    } catch (e) {
      state = PhotoListState.error(
        PhotoFailure('unknown', '予期せぬエラーが発生しました: $e'),
      );
    }
  }

  /// 末尾までスクロールしたときの追加読み込み。
  Future<void> loadMore() async {
    final current = state;
    if (current is! PhotoListLoaded) return;
    if (current.nextBefore == null) return;
    if (current.loadingMore) return;

    state = current.copyWith(loadingMore: true);
    try {
      final repo = ref.read(photoListRepositoryProvider);
      final page = await repo.fetchPage(
        before: current.nextBefore,
        limit: _pageSize,
      );
      final additional = await _buildViews(repo, page.items);
      state = PhotoListState.loaded(
        items: [...current.items, ...additional],
        nextBefore: page.nextBefore,
      );
    } on PhotoFailure {
      // 追加読み込み失敗は loaded を維持して loadingMore を畳む。
      // 全画面エラーにすると既存表示が消えてしまうため。
      state = current.copyWith(loadingMore: false);
    } catch (_) {
      state = current.copyWith(loadingMore: false);
    }
  }

  Future<List<PhotoListItemView>> _buildViews(
    PhotoListRepository repo,
    List<PhotoListItem> items,
  ) async {
    final urls = await Future.wait(
      items.map((it) =>
          repo.createThumbnailSignedUrl(it.thumbnailPath ?? it.storagePath)),
    );
    return [
      for (var i = 0; i < items.length; i++)
        PhotoListItemView(item: items[i], signedThumbnailUrl: urls[i]),
    ];
  }

  /// 詳細画面で削除された直後に一覧から該当写真を即時除去する。
  /// 削除 API 自体は詳細側で呼び済みなので、ここでは state の更新のみ。
  void removeOptimistically(String photoId) {
    final s = state;
    if (s is! PhotoListLoaded) return;
    state = s.copyWith(
      items: s.items.where((v) => v.item.id != photoId).toList(),
    );
  }

  /// 詳細画面でお気に入りトグルされた直後に一覧側のフラグを書き換える。
  void updateFavoriteOptimistically(String photoId, bool isFavorite) {
    final s = state;
    if (s is! PhotoListLoaded) return;
    state = s.copyWith(items: [
      for (final v in s.items)
        if (v.item.id == photoId)
          v.copyWith(item: v.item.copyWith(isFavorite: isFavorite))
        else
          v,
    ]);
  }
}
