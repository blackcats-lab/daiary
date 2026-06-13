import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/album_list_notifier.dart';
import '../providers/album_list_state.dart';
import '../providers/album_list_view.dart';

class AlbumListScreen extends ConsumerStatefulWidget {
  const AlbumListScreen({super.key});

  @override
  ConsumerState<AlbumListScreen> createState() => _AlbumListScreenState();
}

class _AlbumListScreenState extends ConsumerState<AlbumListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(albumListProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(albumListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('アルバム'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新しいアルバム',
            onPressed: () => context.push('/albums/new'),
          ),
        ],
      ),
      body: switch (state) {
        AlbumListInitial() ||
        AlbumListLoading() =>
          const Center(child: CircularProgressIndicator()),
        AlbumListError(:final failure) => _ErrorView(
            message: failure.message,
            onRetry: () => ref.read(albumListProvider.notifier).refresh(),
          ),
        AlbumListLoaded(:final items) when items.isEmpty => _EmptyView(
            onCreate: () => context.push('/albums/new'),
            onRefresh: () => ref.read(albumListProvider.notifier).refresh(),
          ),
        AlbumListLoaded(:final items) => RefreshIndicator(
            onRefresh: () => ref.read(albumListProvider.notifier).refresh(),
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) => _AlbumCell(view: items[index]),
            ),
          ),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
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
            icon: Icon(Icons.photo_library_outlined),
            label: '写真',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            label: 'カメラ',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_outlined),
            label: 'アルバム',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: '設定',
          ),
        ],
      ),
    );
  }
}

class _AlbumCell extends StatelessWidget {
  const _AlbumCell({required this.view});

  final AlbumListItemView view;

  @override
  Widget build(BuildContext context) {
    final url = view.signedCoverUrl;
    return GestureDetector(
      onTap: () => context.push('/albums/${view.summary.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url != null)
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => ColoredBox(color: Colors.grey.shade200),
                errorWidget: (_, __, ___) => ColoredBox(
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.collections_outlined, color: Colors.grey),
                  ),
                ),
              )
            else
              ColoredBox(
                color: Colors.grey.shade300,
                child: const Center(
                  child: Icon(Icons.collections_outlined,
                      size: 48, color: Colors.grey),
                ),
              ),
            // 下部グラデ + テキスト
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 24, 10, 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      view.summary.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${view.summary.photoCount} 枚',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onCreate, required this.onRefresh});

  final VoidCallback onCreate;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.collections_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'まだアルバムがありません',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('新しいアルバムを作成'),
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
  final Future<void> Function() onRetry;

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
