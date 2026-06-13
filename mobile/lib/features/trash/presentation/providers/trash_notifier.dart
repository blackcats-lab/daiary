import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/exceptions/photo_failure.dart';
import '../../../photo/presentation/providers/photo_list_notifier.dart';
import '../../data/repositories/trash_repository.dart';
import '../../domain/entities/trash_item.dart';
import 'trash_state.dart';

part 'trash_notifier.g.dart';

/// ゴミ箱画面の状態管理。autoDispose（画面を閉じたら破棄）。
@riverpod
class TrashNotifier extends _$TrashNotifier {
  @override
  TrashState build() => const TrashState.initial();

  Future<void> load() async {
    state = const TrashState.loading();
    try {
      final repo = ref.read(trashRepositoryProvider);
      final items = await repo.fetchTrash();
      state = TrashState.loaded(await _buildViews(repo, items));
    } on PhotoFailure catch (f) {
      state = TrashState.error(f);
    } catch (e) {
      state = TrashState.error(PhotoFailure('unknown', '予期せぬエラー: $e'));
    }
  }

  /// 復元。成功したらゴミ箱から除き、フィード一覧を再取得する。
  Future<void> restore(String photoId) async {
    final s = state;
    if (s is! TrashLoaded) return;
    await ref.read(trashRepositoryProvider).restore(photoId);
    _removeFromState(photoId);
    // 復元写真がフィードに戻るため一覧を最新化
    await ref.read(photoListProvider.notifier).refresh();
  }

  /// 完全削除。成功したらゴミ箱から除く（フィードには元々無い）。
  Future<void> permanentDelete(String photoId) async {
    final s = state;
    if (s is! TrashLoaded) return;
    await ref.read(trashRepositoryProvider).permanentDelete(photoId);
    _removeFromState(photoId);
  }

  void _removeFromState(String photoId) {
    final s = state;
    if (s is! TrashLoaded) return;
    state = TrashState.loaded(
      s.items.where((v) => v.item.id != photoId).toList(),
    );
  }

  Future<List<TrashItemView>> _buildViews(
    TrashRepository repo,
    List<TrashItem> items,
  ) async {
    final urls = await Future.wait(
      items.map((it) =>
          repo.createThumbnailSignedUrl(it.thumbnailPath ?? it.storagePath)),
    );
    return [
      for (var i = 0; i < items.length; i++)
        TrashItemView(item: items[i], signedThumbnailUrl: urls[i]),
    ];
  }
}
