import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../photo/presentation/providers/photo_list_notifier.dart';
import '../../../photo/presentation/providers/photo_upload_notifier.dart';
import '../../../photo/presentation/providers/photo_upload_state.dart';
import '../../domain/entities/captured_image.dart';

class CapturePreviewScreen extends ConsumerWidget {
  const CapturePreviewScreen({super.key, required this.image});

  final CapturedImage image;

  String get _sizeLabel {
    final kb = image.sizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(photoUploadProvider);
    final isUploading = state is PhotoUploadUploading;

    ref.listen<PhotoUploadState>(photoUploadProvider, (prev, next) {
      switch (next) {
        case PhotoUploadSuccess():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('アップロードしました')),
          );
          // 一覧を再取得してからホームへ。ホーム側 listen に依存しない
          // ことで、reset() で state が idle に戻ったあとでも確実に
          // 反映される。
          ref.read(photoListProvider.notifier).refresh();
          ref.read(photoUploadProvider.notifier).reset();
          context.go('/home');
        case PhotoUploadFailure(:final failure):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
          ref.read(photoUploadProvider.notifier).reset();
        case _:
          break;
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: isUploading ? null : () => context.pop(),
                      ),
                      const Spacer(),
                      Text(
                        _sizeLabel,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                Expanded(
                  child: InteractiveViewer(
                    child: Center(
                      child: Image.file(
                        image.processedFile,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  color: Colors.black,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: isUploading ? null : () => context.pop(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('再撮影'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            disabledBackgroundColor: Colors.white24,
                            disabledForegroundColor: Colors.white70,
                          ),
                          onPressed: isUploading
                              ? null
                              : () => ref
                                  .read(photoUploadProvider.notifier)
                                  .upload(image),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('次へ'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isUploading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x99000000),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'アップロード中…',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
