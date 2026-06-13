import 'package:daiary/core/exceptions/photo_failure.dart';
import 'package:daiary/features/photo/data/repositories/photo_list_repository.dart';
import 'package:daiary/features/photo/domain/entities/photo_filter.dart';
import 'package:daiary/features/photo/domain/entities/photo_list_item.dart';
import 'package:daiary/features/photo/domain/entities/photo_list_page.dart';
import 'package:daiary/features/photo/presentation/providers/photo_search_notifier.dart';
import 'package:daiary/features/photo/presentation/providers/photo_search_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// fetchPage / createThumbnailSignedUrl だけを差し替える fake。
/// 親の SupabaseService.client を避けるためダミー URL でクライアントを渡す
/// （construct は遅延接続なのでネットワークは発生しない）。
class _FakeRepository extends PhotoListRepository {
  _FakeRepository(this._pages)
      : super(client: SupabaseClient('http://localhost', 'test-anon-key'));

  final List<PhotoListPage> _pages;
  int _index = 0;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<PhotoListPage> fetchPage({
    DateTime? before,
    int limit = 30,
    String? tag,
    bool favoriteOnly = false,
  }) async {
    calls.add({'tag': tag, 'favoriteOnly': favoriteOnly, 'before': before});
    return _pages[_index++];
  }

  @override
  Future<String?> createThumbnailSignedUrl(String path) async =>
      'signed://$path';
}

class _ThrowingRepository extends PhotoListRepository {
  _ThrowingRepository()
      : super(client: SupabaseClient('http://localhost', 'test-anon-key'));

  @override
  Future<PhotoListPage> fetchPage({
    DateTime? before,
    int limit = 30,
    String? tag,
    bool favoriteOnly = false,
  }) async {
    throw PhotoFailure('list_failed', 'boom');
  }
}

PhotoListItem _item(String id, {bool favorite = false}) => PhotoListItem(
      id: id,
      storagePath: '$id.jpg',
      createdAt: DateTime.utc(2026, 6, 13),
      isFavorite: favorite,
    );

ProviderContainer _containerWith(PhotoListRepository repo) {
  final c = ProviderContainer(
    overrides: [photoListRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('初期状態は idle', () {
    final c = _containerWith(_FakeRepository(const []));
    expect(c.read(photoSearchProvider), isA<PhotoSearchIdle>());
  });

  test('空フィルタ適用は idle のまま', () async {
    final c = _containerWith(_FakeRepository(const []));
    await c.read(photoSearchProvider.notifier).applyFilter(const PhotoFilter());
    expect(c.read(photoSearchProvider), isA<PhotoSearchIdle>());
  });

  test('タグフィルタで検索すると loaded になり repository にタグが渡る', () async {
    final repo = _FakeRepository([
      PhotoListPage(items: [_item('a'), _item('b')], nextBefore: null),
    ]);
    final c = _containerWith(repo);

    await c
        .read(photoSearchProvider.notifier)
        .applyFilter(const PhotoFilter(tag: '#海'));

    final s = c.read(photoSearchProvider);
    expect(s, isA<PhotoSearchLoaded>());
    expect((s as PhotoSearchLoaded).items, hasLength(2));
    expect(repo.calls.single['tag'], '#海');
  });

  test('お気に入りフィルタが repository に伝わる', () async {
    final repo = _FakeRepository([
      PhotoListPage(items: [_item('a', favorite: true)], nextBefore: null),
    ]);
    final c = _containerWith(repo);

    await c
        .read(photoSearchProvider.notifier)
        .applyFilter(const PhotoFilter(favoriteOnly: true));

    expect(repo.calls.single['favoriteOnly'], true);
  });

  test('検索失敗で error 状態になる', () async {
    final c = _containerWith(_ThrowingRepository());
    await c
        .read(photoSearchProvider.notifier)
        .applyFilter(const PhotoFilter(tag: '#x'));
    expect(c.read(photoSearchProvider), isA<PhotoSearchError>());
  });

  test('clear で idle に戻る', () async {
    final repo = _FakeRepository([
      PhotoListPage(items: [_item('a')], nextBefore: null),
    ]);
    final c = _containerWith(repo);
    await c
        .read(photoSearchProvider.notifier)
        .applyFilter(const PhotoFilter(tag: '#海'));
    c.read(photoSearchProvider.notifier).clear();
    expect(c.read(photoSearchProvider), isA<PhotoSearchIdle>());
  });

  test('お気に入りフィルタ中に false へ変わった写真は結果から除外', () async {
    final repo = _FakeRepository([
      PhotoListPage(
        items: [_item('a', favorite: true), _item('b', favorite: true)],
        nextBefore: null,
      ),
    ]);
    final c = _containerWith(repo);
    await c
        .read(photoSearchProvider.notifier)
        .applyFilter(const PhotoFilter(favoriteOnly: true));

    c
        .read(photoSearchProvider.notifier)
        .updateFavoriteOptimistically('a', false);

    final s = c.read(photoSearchProvider) as PhotoSearchLoaded;
    expect(s.items.map((v) => v.item.id), ['b']);
  });
}
