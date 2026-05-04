import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/captured_image.dart';

class CapturePreviewScreen extends StatelessWidget {
  const CapturePreviewScreen({super.key, required this.image});

  final CapturedImage image;

  String get _sizeLabel {
    final kb = image.sizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  Text(
                    _sizeLabel,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                      onPressed: () => context.pop(),
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
                      // TODO(sprint1-#6): Storage アップロードと photos POST を実装
                      onPressed: null,
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
    );
  }
}
