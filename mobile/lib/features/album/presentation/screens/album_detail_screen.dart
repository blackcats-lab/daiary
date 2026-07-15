import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/exceptions/album_failure.dart';
import '../../domain/entities/album_photo.dart';
import '../providers/album_detail_notifier.dart';
import '../providers/album_detail_state.dart';

class AlbumDetailScreen extends ConsumerStatefulWidget {
  const AlbumDetailScreen({super.key, required this.albumId});

  final String albumId;

  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(albumDetailProvider(widget.albumId).notifier).load();
    });
  }

  Future<void> _confirmDeleteAlbum() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('アルバムを削除'),
        content: const Text('このアルバムを削除しますか？\n（写真自体は削除されません）'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(albumDetailProvider(widget.albumId).notifier)
          .deleteAlbum();
    } on AlbumFailure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(f.message)));
    }
  }

  Future<void> _confirmRemoveSelected(int count) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('アルバムから削除'),
        content: Text('$count 枚の写真をアルバムから外しますか？\n（写真自体は削除されません）'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(albumDetailProvider(widget.albumId).notifier)
          .removeSelected();
    } on AlbumFailure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(f.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(albumDetailProvider(widget.albumId));

    // 削除完了で一覧へ戻る。
    // pop() だと「編集画面から削除」時に最上位の編集画面だけが閉じ、
    // 削除済みアルバムの詳細画面に取り残されるため go で一覧まで戻す。
    ref.listen<AlbumDetailState>(albumDetailProvider(widget.albumId),
        (prev, next) {
      if (next is AlbumDetailLoaded && next.deleted) {
        context.go('/albums');
      }
    });

    return Scaffold(
      appBar: _buildAppBar(state),
      body: switch (state) {
        AlbumDetailInitial() ||
        AlbumDetailLoading() =>
          const Center(child: CircularProgressIndicator()),
        AlbumDetailError(:final failure) => _ErrorView(
            message: failure.message,
            onRetry: () => ref
                .read(albumDetailProvider(widget.albumId).notifier)
                .refresh(),
          ),
        AlbumDetailLoaded() => _LoadedBody(
            albumId: widget.albumId,
            state: state,
          ),
      },
      floatingActionButton: state is AlbumDetailLoaded && !state.selectionMode
          ? FloatingActionButton.extended(
              onPressed: () =>
                  context.push('/albums/${widget.albumId}/add-photos'),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('写真を追加'),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(AlbumDetailState state) {
    final loaded = state is AlbumDetailLoaded ? state : null;
    final notifier = ref.read(albumDetailProvider(widget.albumId).notifier);

    if (loaded != null && loaded.selectionMode) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: notifier.toggleSelectionMode,
        ),
        title: Text('${loaded.selected.length} 枚を選択'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '選択した写真を削除',
            onPressed: loaded.selected.isEmpty || loaded.removingPhotos
                ? null
                : () => _confirmRemoveSelected(loaded.selected.length),
          ),
        ],
      );
    }

    final title = loaded?.detail.album.name ?? 'アルバム';
    return AppBar(
      title: GestureDetector(
        onTap: loaded == null
            ? null
            : () => context.push('/albums/${widget.albumId}/edit'),
        child: Text(title),
      ),
      actions: [
        if (loaded != null && loaded.detail.photos.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.checklist),
            tooltip: '選択モード',
            onPressed: notifier.toggleSelectionMode,
          ),
        if (loaded != null)
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: '編集',
            onPressed: () => context.push('/albums/${widget.albumId}/edit'),
          ),
        if (loaded != null)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'アルバムを削除',
            onPressed: loaded.deleting ? null : _confirmDeleteAlbum,
          ),
      ],
    );
  }
}

class _LoadedBody extends ConsumerWidget {
  const _LoadedBody({required this.albumId, required this.state});

  final String albumId;
  final AlbumDetailLoaded state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = state.detail.photos;
    if (photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.collections_outlined,
                size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '写真がありません',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push('/albums/$albumId/add-photos'),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('写真を追加'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(albumDetailProvider(albumId).notifier).refresh(),
      child: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photo = photos[index];
          final url = state.signedUrls[photo.id];
          final selected = state.selected.contains(photo.id);
          return _PhotoCell(
            photo: photo,
            signedUrl: url,
            selectionMode: state.selectionMode,
            selected: selected,
            onTap: state.selectionMode
                ? () => ref
                    .read(albumDetailProvider(albumId).notifier)
                    .togglePhoto(photo.id)
                : () => context.push('/photo/${photo.id}'),
            onLongPress: state.selectionMode
                ? null
                : () {
                    ref
                        .read(albumDetailProvider(albumId).notifier)
                        .toggleSelectionMode();
                    ref
                        .read(albumDetailProvider(albumId).notifier)
                        .togglePhoto(photo.id);
                  },
          );
        },
      ),
    );
  }
}

class _PhotoCell extends StatelessWidget {
  const _PhotoCell({
    required this.photo,
    required this.signedUrl,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final AlbumPhoto photo;
  final String? signedUrl;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ColoredBox(
        color: Colors.grey.shade200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (signedUrl == null)
              const Center(
                child: Icon(Icons.broken_image, color: Colors.grey),
              )
            else
              CachedNetworkImage(
                imageUrl: signedUrl!,
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
            if (selectionMode)
              Container(
                color: selected ? const Color(0x66000000) : Colors.transparent,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.all(4),
                child: Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: Colors.white,
                  size: 22,
                ),
              ),
          ],
        ),
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
