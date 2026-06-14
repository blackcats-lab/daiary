import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/exceptions/photo_failure.dart';
import '../providers/trash_notifier.dart';
import '../providers/trash_state.dart';

class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trashProvider.notifier).load();
    });
  }

  Future<void> _onTapItem(TrashItemView view) async {
    final action = await showModalBottomSheet<_TrashAction>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('復元する'),
              onTap: () => Navigator.pop(ctx, _TrashAction.restore),
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: const Text('完全に削除する',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () => Navigator.pop(ctx, _TrashAction.delete),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    if (action == _TrashAction.restore) {
      await _restore(view.item.id);
    } else {
      await _confirmDelete(view.item.id);
    }
  }

  Future<void> _restore(String photoId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(trashProvider.notifier).restore(photoId);
      messenger.showSnackBar(const SnackBar(content: Text('復元しました')));
    } on PhotoFailure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(f.message)));
    }
  }

  Future<void> _confirmDelete(String photoId) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('完全に削除'),
        content: const Text('この写真を完全に削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('完全に削除'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(trashProvider.notifier).permanentDelete(photoId);
      messenger.showSnackBar(const SnackBar(content: Text('完全に削除しました')));
    } on PhotoFailure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(f.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trashProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('ゴミ箱')),
      body: switch (state) {
        TrashInitial() || TrashLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
        TrashError(:final failure) => _ErrorView(
            message: failure.message,
            onRetry: () => ref.read(trashProvider.notifier).load(),
          ),
        TrashLoaded(:final items) when items.isEmpty => const _EmptyView(),
        TrashLoaded(:final items) => Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  '削除した写真は 30 日後に自動的に完全削除されます',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(2),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _TrashCell(
                    view: items[index],
                    onTap: () => _onTapItem(items[index]),
                  ),
                ),
              ),
            ],
          ),
      },
    );
  }
}

enum _TrashAction { restore, delete }

class _TrashCell extends StatelessWidget {
  const _TrashCell({required this.view, required this.onTap});

  final TrashItemView view;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = view.signedThumbnailUrl;
    final remaining = view.item.remainingDays();
    return GestureDetector(
      onTap: onTap,
      child: ColoredBox(
        color: Colors.grey.shade200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url == null)
              const Center(child: Icon(Icons.broken_image, color: Colors.grey))
            else
              ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.black26,
                  BlendMode.darken,
                ),
                child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
              ),
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'あと$remaining日',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
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
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('ゴミ箱は空です', style: TextStyle(color: Colors.grey)),
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
