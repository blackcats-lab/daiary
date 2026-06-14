import 'package:daiary/features/trash/data/repositories/trash_repository.dart';
import 'package:daiary/features/trash/domain/entities/trash_item.dart';
import 'package:daiary/features/trash/presentation/providers/trash_notifier.dart';
import 'package:daiary/features/trash/presentation/providers/trash_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeTrashRepository extends TrashRepository {
  _FakeTrashRepository(this._items)
      : super(client: SupabaseClient('http://localhost', 'test-anon-key'));

  final List<TrashItem> _items;
  final List<String> restored = [];
  final List<String> deleted = [];

  @override
  Future<List<TrashItem>> fetchTrash() async => _items;

  @override
  Future<void> restore(String photoId) async => restored.add(photoId);

  @override
  Future<void> permanentDelete(String photoId) async => deleted.add(photoId);

  @override
  Future<String?> createThumbnailSignedUrl(String path) async => null;
}

TrashItem _item(String id) => TrashItem(
      id: id,
      storagePath: '$id.jpg',
      deletedAt: DateTime.utc(2026, 6, 1),
    );

void main() {
  test('remainingDays は 30 - 経過日数、負にならない', () {
    final item = TrashItem(
      id: 'a',
      storagePath: 'a.jpg',
      deletedAt: DateTime.utc(2026, 6, 1),
    );
    expect(item.remainingDays(now: DateTime.utc(2026, 6, 11)), 20);
    expect(item.remainingDays(now: DateTime.utc(2026, 7, 15)), 0);
  });

  test('load でゴミ箱を取得し loaded になる', () async {
    final repo = _FakeTrashRepository([_item('a'), _item('b')]);
    final c = ProviderContainer(
      overrides: [trashRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);

    await c.read(trashProvider.notifier).load();
    final s = c.read(trashProvider);
    expect(s, isA<TrashLoaded>());
    expect((s as TrashLoaded).items, hasLength(2));
  });

  test('完全削除でリストから消え repository が呼ばれる', () async {
    final repo = _FakeTrashRepository([_item('a'), _item('b')]);
    final c = ProviderContainer(
      overrides: [trashRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);

    await c.read(trashProvider.notifier).load();
    await c.read(trashProvider.notifier).permanentDelete('a');

    final s = c.read(trashProvider) as TrashLoaded;
    expect(s.items.map((v) => v.item.id), ['b']);
    expect(repo.deleted, ['a']);
  });
}
