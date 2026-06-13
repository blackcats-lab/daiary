import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/photo_filter.dart';
import '../providers/photo_list_notifier.dart';
import '../providers/photo_list_state.dart';
import '../providers/photo_list_view.dart';
import '../providers/photo_search_notifier.dart';
import '../providers/photo_search_state.dart';
import '../providers/photo_tags_provider.dart';
import '../providers/photo_upload_notifier.dart';
import '../providers/photo_upload_state.dart';
import '../widgets/photo_grid_cell.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = SearchController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(photoListProvider.notifier).load();
    });
    // 撮影完了で一覧を再取得する。
    ref.listenManual<PhotoUploadState>(photoUploadProvider, (prev, next) {
      if (next is PhotoUploadSuccess) {
        ref.read(photoListProvider.notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _onScrollFeed(ScrollNotification notification) {
    if (notification.metrics.extentAfter < 400) {
      ref.read(photoListProvider.notifier).loadMore();
    }
    return false;
  }

  bool _onScrollSearch(ScrollNotification notification) {
    if (notification.metrics.extentAfter < 400) {
      ref.read(photoSearchProvider.notifier).loadMore();
    }
    return false;
  }

  PhotoFilter get _filter {
    final s = ref.read(photoSearchProvider);
    return switch (s) {
      PhotoSearchIdle() => const PhotoFilter(),
      PhotoSearchLoading(:final filter) => filter,
      PhotoSearchLoaded(:final filter) => filter,
      PhotoSearchError(:final filter) => filter,
    };
  }

  void _selectTag(String? tag) {
    ref
        .read(photoSearchProvider.notifier)
        .applyFilter(_filter.copyWith(tag: tag));
  }

  void _toggleFavorite() {
    final f = _filter;
    ref
        .read(photoSearchProvider.notifier)
        .applyFilter(f.copyWith(favoriteOnly: !f.favoriteOnly));
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(photoSearchProvider);
    final filter = switch (searchState) {
      PhotoSearchIdle() => const PhotoFilter(),
      PhotoSearchLoading(:final filter) => filter,
      PhotoSearchLoaded(:final filter) => filter,
      PhotoSearchError(:final filter) => filter,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('dAIary'),
        actions: [
          _SearchAnchor(
            controller: _searchController,
            onTagSelected: _selectTag,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _FilterBar(
            filter: filter,
            onToggleFavorite: _toggleFavorite,
            onClearTag: () => _selectTag(null),
          ),
        ),
      ),
      body: filter.isActive
          ? _SearchResults(onScroll: _onScrollSearch)
          : _Feed(onScroll: _onScrollFeed),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/camera');
            case 2:
              context.go('/albums');
            case 3:
              context.go('/settings');
          }
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.photo_library_outlined), label: '写真'),
          NavigationDestination(
              icon: Icon(Icons.camera_alt_outlined), label: 'カメラ'),
          NavigationDestination(
              icon: Icon(Icons.collections_outlined), label: 'アルバム'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined), label: '設定'),
        ],
      ),
    );
  }
}

/// AppBar の検索ボタン。タップで候補タグ一覧をオーバーレイ表示し、選択で絞り込む。
class _SearchAnchor extends ConsumerWidget {
  const _SearchAnchor({required this.controller, required this.onTagSelected});

  final SearchController controller;
  final void Function(String tag) onTagSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchAnchor(
      searchController: controller,
      builder: (context, ctrl) => IconButton(
        icon: const Icon(Icons.search),
        tooltip: 'タグで検索',
        onPressed: ctrl.openView,
      ),
      suggestionsBuilder: (context, ctrl) {
        final query = ctrl.text.trim();
        final tagsAsync = ref.watch(photoTagsProvider);
        return tagsAsync.when(
          loading: () => const [
            Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          error: (_, __) => const [
            ListTile(title: Text('タグの取得に失敗しました')),
          ],
          data: (tags) {
            final filtered = query.isEmpty
                ? tags
                : tags
                    .where((t) => t.toLowerCase().contains(query.toLowerCase()))
                    .toList();
            if (filtered.isEmpty) {
              return const [ListTile(title: Text('一致するタグがありません'))];
            }
            return [
              for (final tag in filtered)
                ListTile(
                  leading: const Icon(Icons.tag),
                  title: Text(tag),
                  onTap: () {
                    onTagSelected(tag);
                    ctrl.closeView(tag);
                  },
                ),
            ];
          },
        );
      },
    );
  }
}

/// お気に入りトグルと選択中タグの chip を並べる帯。
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filter,
    required this.onToggleFavorite,
    required this.onClearTag,
  });

  final PhotoFilter filter;
  final VoidCallback onToggleFavorite;
  final VoidCallback onClearTag;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: FilterChip(
                label: const Text('お気に入り'),
                avatar: Icon(
                  filter.favoriteOnly ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                ),
                selected: filter.favoriteOnly,
                onSelected: (_) => onToggleFavorite(),
              ),
            ),
          ),
          if (filter.tag != null && filter.tag!.isNotEmpty)
            Center(
              child: InputChip(
                label: Text(filter.tag!),
                onDeleted: onClearTag,
              ),
            ),
        ],
      ),
    );
  }
}

class _Feed extends ConsumerWidget {
  const _Feed({required this.onScroll});

  final bool Function(ScrollNotification) onScroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(photoListProvider);
    return switch (state) {
      PhotoListInitial() || PhotoListLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
      PhotoListError(:final failure) => _ErrorView(
          message: failure.message,
          onRetry: () => ref.read(photoListProvider.notifier).refresh(),
        ),
      PhotoListLoaded(:final items) when items.isEmpty => _EmptyView(
          onRefresh: () => ref.read(photoListProvider.notifier).refresh(),
        ),
      PhotoListLoaded(:final items, :final loadingMore) => RefreshIndicator(
          onRefresh: () => ref.read(photoListProvider.notifier).refresh(),
          child: NotificationListener<ScrollNotification>(
            onNotification: onScroll,
            child: _PhotoGrid(items: items, loadingMore: loadingMore),
          ),
        ),
    };
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.onScroll});

  final bool Function(ScrollNotification) onScroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(photoSearchProvider);
    return switch (state) {
      PhotoSearchIdle() || PhotoSearchLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
      PhotoSearchError(:final failure) => _ErrorView(
          message: failure.message,
          onRetry: () =>
              ref.read(photoSearchProvider.notifier).applyFilter(state.filter),
        ),
      PhotoSearchLoaded(:final items) when items.isEmpty => const Center(
          child: Text(
            '条件に一致する写真がありません',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      PhotoSearchLoaded(:final items, :final loadingMore) =>
        NotificationListener<ScrollNotification>(
          onNotification: onScroll,
          child: _PhotoGrid(items: items, loadingMore: loadingMore),
        ),
    };
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({required this.items, required this.loadingMore});

  final List<PhotoListItemView> items;
  final bool loadingMore;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: items.length + (loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return PhotoGridCell(view: items[index]);
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: const [
          SizedBox(height: 120),
          Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Center(
            child: Text(
              'まだ写真がありません',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: Text(
              '下のカメラタブから撮影しましょう',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(message, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('再試行')),
        ],
      ),
    );
  }
}
