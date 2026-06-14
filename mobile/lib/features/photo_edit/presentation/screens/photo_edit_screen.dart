import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/filter_presets.dart';
import '../providers/photo_edit_notifier.dart';

/// 写真編集画面。トリミング/回転（image_cropper）+ 明るさ/コントラスト/彩度
/// スライダー + プリセットフィルタ。プレビューは ColorFilter.matrix でライブ表示。
class PhotoEditScreen extends ConsumerStatefulWidget {
  const PhotoEditScreen({
    super.key,
    required this.photoId,
    required this.sourceFile,
    required this.storagePath,
    required this.thumbnailPath,
  });

  final String photoId;
  final File sourceFile;
  final String storagePath;
  final String thumbnailPath;

  @override
  ConsumerState<PhotoEditScreen> createState() => _PhotoEditScreenState();
}

class _PhotoEditScreenState extends ConsumerState<PhotoEditScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(photoEditProvider(widget.photoId).notifier)
          .setWorkingFile(widget.sourceFile);
    });
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(photoEditProvider(widget.photoId).notifier).save(
          storagePath: widget.storagePath,
          thumbnailPath: widget.thumbnailPath,
        );
    final state = ref.read(photoEditProvider(widget.photoId));
    if (!mounted) return;
    if (state.saved) {
      messenger.showSnackBar(const SnackBar(content: Text('保存しました')));
      context.pop(true);
    } else if (state.errorMessage != null) {
      messenger.showSnackBar(SnackBar(content: Text(state.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(photoEditProvider(widget.photoId));
    final notifier = ref.read(photoEditProvider(widget.photoId).notifier);
    final file = state.workingFile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('写真を編集'),
        actions: [
          TextButton(
            onPressed: state.saving ? null : _save,
            child: state.saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: file == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.black,
                    width: double.infinity,
                    child: ColorFiltered(
                      colorFilter: ColorFilter.matrix(notifier.currentMatrix),
                      child: Image.file(file, fit: BoxFit.contain),
                    ),
                  ),
                ),
                _Controls(
                  photoId: widget.photoId,
                  onCrop: () => notifier.crop(),
                ),
              ],
            ),
    );
  }
}

class _Controls extends ConsumerWidget {
  const _Controls({required this.photoId, required this.onCrop});

  final String photoId;
  final VoidCallback onCrop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(photoEditProvider(photoId));
    final notifier = ref.read(photoEditProvider(photoId).notifier);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // フィルタカルーセル
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: FilterPresets.all.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = state.filterIndex == index;
                return ChoiceChip(
                  label: Text(FilterPresets.all[index].label),
                  selected: selected,
                  onSelected: (_) => notifier.selectFilter(index),
                );
              },
            ),
          ),
          const Divider(height: 8),
          // トリミングボタン
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextButton.icon(
                onPressed: onCrop,
                icon: const Icon(Icons.crop),
                label: const Text('トリミング・回転'),
              ),
            ),
          ),
          // 調整スライダー
          _AdjustSlider(
            label: '明るさ',
            value: state.brightness,
            onChanged: notifier.setBrightness,
          ),
          _AdjustSlider(
            label: 'コントラスト',
            value: state.contrast,
            onChanged: notifier.setContrast,
          ),
          _AdjustSlider(
            label: '彩度',
            value: state.saturation,
            onChanged: notifier.setSaturation,
          ),
        ],
      ),
    );
  }
}

class _AdjustSlider extends StatelessWidget {
  const _AdjustSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: -1.0,
              max: 1.0,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
