import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/exceptions/album_failure.dart';
import '../../data/repositories/album_repository.dart';
import 'album_create_state.dart';
import 'album_list_notifier.dart';

part 'album_create_notifier.g.dart';

/// アルバム作成画面の状態管理。成功時に AlbumListNotifier に楽観的に追加する。
@Riverpod(keepAlive: false)
class AlbumCreateNotifier extends _$AlbumCreateNotifier {
  @override
  AlbumCreateState build() => const AlbumCreateState.idle();

  Future<void> create(String name) async {
    if (state is AlbumCreateSubmitting) return;
    state = const AlbumCreateState.submitting();
    try {
      final repo = ref.read(albumRepositoryProvider);
      final album = await repo.create(name: name.trim());
      ref.read(albumListProvider.notifier).prependOptimistically(album);
      state = AlbumCreateState.success(album);
    } on AlbumFailure catch (f) {
      state = AlbumCreateState.failure(f);
    } catch (e) {
      state = AlbumCreateState.failure(
        AlbumFailure('unknown', '予期せぬエラーが発生しました: $e'),
      );
    }
  }

  void reset() => state = const AlbumCreateState.idle();
}
