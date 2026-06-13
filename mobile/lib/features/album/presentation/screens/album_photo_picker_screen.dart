import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/exceptions/album_failure.dart';
import '../../../photo/presentation/providers/photo_list_notifier.dart';
import '../../../photo/presentation/providers/photo_list_state.dart';
import '../providers/album_photo_picker_notifier.dart';

class AlbumPhotoPickerScreen extends ConsumerStatefulWidget {
  const AlbumPhotoPickerScreen({super.key, required this.albumId});

  final String albumId;

  @override
  ConsumerState<AlbumPhotoPickerScreen> createState() =>
      _AlbumPhotoPickerScreenState();
}

class _AlbumPhotoPickerScreenState
    extends ConsumerState<AlbumPhotoPickerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 写真ソースは既存 PhotoListNotifier を再利用
      ref.read(photoListProvider.notifier).load();
    });
  }

  Future<void> _submit() async {
    final notifier =
        ref.read(albumPhotoPickerProvider(widget.albumId).notifier);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await notifier.submit();
      if (!mounted) return;
      final added = result.added.length;
      final skipped = result.skipped.length;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            skipped == 0
                ? '$added 枚を追加しました'
                : '$added 枚を追加しました（$skipped 枚はスキップ）',
          ),
        ),
      );
      context.pop();
    } on AlbumFailure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(f.message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('追加に失敗しました: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickerState = ref.watch(albumPhotoPickerProvider(widget.albumId));
    final listState = ref.watch(photoListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('写真を選択'),
        actions: [
          TextButton(
            onPressed: pickerState.selected.isEmpty || pickerState.submitting
                ? null
                : _submit,
            child: Text('${pickerState.selected.length} 枚追加'),
          ),
        ],
      ),
      body: switch (listState) {
        PhotoListInitial() ||
        PhotoListLoading() =>
          const Center(child: CircularProgressIndicator()),
        PhotoListError(:final failure) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(failure.message, textAlign: TextAlign.center),
            ),
          ),
        PhotoListLoaded(:final items) when items.isEmpty => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                '追加できる写真がありません',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        PhotoListLoaded(:final items) => GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final view = items[index];
              final inAlbum = pickerState.existingIds.contains(view.item.id);
              final selected = pickerState.selected.contains(view.item.id);
              return _PickerCell(
                signedUrl: view.signedThumbnailUrl,
                disabled: inAlbum,
                selected: selected,
                onTap: inAlbum
                    ? null
                    : () => ref
                        .read(albumPhotoPickerProvider(widget.albumId).notifier)
                        .toggle(view.item.id),
              );
            },
          ),
      },
    );
  }
}

class _PickerCell extends StatelessWidget {
  const _PickerCell({
    required this.signedUrl,
    required this.disabled,
    required this.selected,
    required this.onTap,
  });

  final String? signedUrl;
  final bool disabled;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                placeholder: (_, __) => const SizedBox.shrink(),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            // 既にアルバムに含まれる写真は半透明 + チェックマーク
            if (disabled)
              Container(
                color: const Color(0xCCFFFFFF),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.grey,
                  size: 28,
                ),
              )
            // 選択中は黒オーバーレイ + チェック
            else if (selected)
              Container(
                color: const Color(0x66000000),
                alignment: Alignment.topRight,
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.check_circle,
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
