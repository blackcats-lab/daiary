import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/exceptions/photo_failure.dart';
import '../../data/repositories/photo_list_repository.dart';
import '../../domain/entities/photo_filter.dart';
import '../../domain/entities/photo_list_item.dart';
import 'photo_list_view.dart';
import 'photo_search_state.dart';

part 'photo_search_notifier.g.dart';

/// タグ・お気に入りによる検索結果の状態管理。
///
/// フィード（photoListProvider, keepAlive）とは分離し autoDispose で持つ。
/// 検索を抜けたら破棄され、フィード側のキャッシュを壊さない。
@riverpod
class PhotoSearchNotifier extends _$PhotoSearchNotifier {
  static const int _pageSize = 30;

  /// applyFilter の世代カウンタ。連打時に古いレスポンスが新しいフィルタの
  /// 結果を上書きしないよう、await 後に世代が進んでいたら結果を破棄する。
  int _requestSeq = 0;

  @override
  PhotoSearchState build() => const PhotoSearchState.idle();

  /// フィルタを適用して検索する。空フィルタなら idle に戻す。
  Future<void> applyFilter(PhotoFilter filter) async {
    final seq = ++_requestSeq;
    if (filter.isEmpty) {
      state = const PhotoSearchState.idle();
      return;
    }
    state = PhotoSearchState.loading(filter);
    try {
      final repo = ref.read(photoListRepositoryProvider);
      final page = await repo.fetchPage(
        limit: _pageSize,
        tag: filter.tag,
        favoriteOnly: filter.favoriteOnly,
      );
      final views = await _buildViews(repo, page.items);
      if (seq != _requestSeq) return; // 後続のフィルタ操作が優先
      state = PhotoSearchState.loaded(
        filter: filter,
        items: views,
        nextBefore: page.nextBefore,
      );
    } on PhotoFailure catch (f) {
      if (seq != _requestSeq) return;
      state = PhotoSearchState.error(filter: filter, failure: f);
    } catch (e) {
      if (seq != _requestSeq) return;
      state = PhotoSearchState.error(
        filter: filter,
        failure: PhotoFailure('unknown', '予期せぬエラーが発生しました: $e'),
      );
    }
  }

  /// 検索を解除してフィード表示に戻る。
  void clear() {
    _requestSeq++; // 実行中の applyFilter の結果を無効化する
    state = const PhotoSearchState.idle();
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! PhotoSearchLoaded) return;
    if (current.nextBefore == null || current.loadingMore) return;

    state = current.copyWith(loadingMore: true);
    try {
      final repo = ref.read(photoListRepositoryProvider);
      final page = await repo.fetchPage(
        before: current.nextBefore,
        limit: _pageSize,
        tag: current.filter.tag,
        favoriteOnly: current.filter.favoriteOnly,
      );
      final additional = await _buildViews(repo, page.items);
      // await 中の楽観更新・フィルタ変更を尊重して最新 state に追記する
      final latest = state;
      if (latest is! PhotoSearchLoaded ||
          !latest.loadingMore ||
          latest.filter != current.filter) {
        return;
      }
      final existingIds = {for (final v in latest.items) v.item.id};
      state = PhotoSearchState.loaded(
        filter: latest.filter,
        items: [
          ...latest.items,
          ...additional.where((v) => !existingIds.contains(v.item.id)),
        ],
        nextBefore: page.nextBefore,
      );
    } catch (_) {
      final latest = state;
      if (latest is PhotoSearchLoaded && latest.loadingMore) {
        state = latest.copyWith(loadingMore: false);
      }
    }
  }

  /// 詳細画面での削除を検索結果にも反映する（loaded のときのみ）。
  void removeOptimistically(String photoId) {
    final s = state;
    if (s is! PhotoSearchLoaded) return;
    state = s.copyWith(
      items: s.items.where((v) => v.item.id != photoId).toList(),
    );
  }

  /// 詳細画面でのお気に入りトグルを検索結果にも反映する。
  /// お気に入りフィルタ中に false へ変わった写真は結果から除外する。
  void updateFavoriteOptimistically(String photoId, bool isFavorite) {
    final s = state;
    if (s is! PhotoSearchLoaded) return;
    if (s.filter.favoriteOnly && !isFavorite) {
      state = s.copyWith(
        items: s.items.where((v) => v.item.id != photoId).toList(),
      );
      return;
    }
    state = s.copyWith(items: [
      for (final v in s.items)
        if (v.item.id == photoId)
          v.copyWith(item: v.item.copyWith(isFavorite: isFavorite))
        else
          v,
    ]);
  }

  /// caption / ai_tags の手動編集を検索結果にも反映する。
  void updateItemOptimistically(
    String photoId, {
    List<String>? aiTags,
    String? caption,
  }) {
    final s = state;
    if (s is! PhotoSearchLoaded) return;
    state = s.copyWith(items: [
      for (final v in s.items)
        if (v.item.id == photoId)
          v.copyWith(
            item: v.item.copyWith(
              aiTags: aiTags ?? v.item.aiTags,
              caption: caption ?? v.item.caption,
            ),
          )
        else
          v,
    ]);
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
}
