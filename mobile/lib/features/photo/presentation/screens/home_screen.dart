import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/photo_list_notifier.dart';
import '../providers/photo_list_state.dart';
import '../providers/photo_list_view.dart';
import '../providers/photo_upload_notifier.dart';
import '../providers/photo_upload_state.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.extentAfter < 400) {
      ref.read(photoListProvider.notifier).loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(photoListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('dAIary')),
      body: switch (state) {
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
              onNotification: _onScroll,
              child: GridView.builder(
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
                  return _PhotoCell(view: items[index]);
                },
              ),
            ),
          ),
      },
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

class _PhotoCell extends StatelessWidget {
  const _PhotoCell({required this.view});

  final PhotoListItemView view;

  @override
  Widget build(BuildContext context) {
    final url = view.signedThumbnailUrl;
    return GestureDetector(
      onTap: () => context.push('/photo/${view.item.id}'),
      child: ColoredBox(
        color: Colors.grey.shade200,
        child: url == null
            ? const Center(
                child: Icon(Icons.broken_image, color: Colors.grey),
              )
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
      ),
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
