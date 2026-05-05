import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/exceptions/album_failure.dart';
import '../../data/repositories/album_repository.dart';
import '../../domain/entities/album_summary.dart';
import 'album_list_state.dart';
import 'album_list_view.dart';

part 'album_list_notifier.g.dart';

/// アルバム一覧の状態管理。タブ切替で破棄しないため keepAlive: true。
@Riverpod(keepAlive: true)
class AlbumListNotifier extends _$AlbumListNotifier {
  @override
  AlbumListState build() => const AlbumListState.initial();

  /// 初回読み込み。state が initial / error の時のみ実行する。
  Future<void> load() async {
    if (state is AlbumListLoaded || state is AlbumListLoading) return;
    await _fetch();
  }

  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    state = const AlbumListState.loading();
    try {
      final repo = ref.read(albumRepositoryProvider);
      final summaries = await repo.fetchList();
      final urls = await Future.wait(
        summaries.map((s) => repo.createSignedUrl(s.coverThumbnailPath)),
      );
      state = AlbumListState.loaded(
        items: [
          for (var i = 0; i < summaries.length; i++)
            AlbumListItemView(
              summary: summaries[i],
              signedCoverUrl: urls[i],
            ),
        ],
      );
    } on AlbumFailure catch (f) {
      state = AlbumListState.error(f);
    } catch (e) {
      state = AlbumListState.error(
        AlbumFailure('unknown', '予期せぬエラーが発生しました: $e'),
      );
    }
  }

  /// 作成成功時に一覧の先頭に追加する楽観更新。
  void prependOptimistically(AlbumSummary album) {
    final s = state;
    if (s is! AlbumListLoaded) return;
    state = s.copyWith(
      items: [AlbumListItemView(summary: album), ...s.items],
    );
  }

  /// 削除成功時に一覧から除去する楽観更新（PR-H で使用）。
  void removeOptimistically(String albumId) {
    final s = state;
    if (s is! AlbumListLoaded) return;
    state = s.copyWith(
      items: s.items.where((v) => v.summary.id != albumId).toList(),
    );
  }

  /// 名前変更時の楽観更新（PR-H で使用）。
  void updateNameOptimistically(String albumId, String name) {
    final s = state;
    if (s is! AlbumListLoaded) return;
    state = s.copyWith(items: [
      for (final v in s.items)
        if (v.summary.id == albumId)
          v.copyWith(summary: v.summary.copyWith(name: name))
        else
          v,
    ]);
  }
}
