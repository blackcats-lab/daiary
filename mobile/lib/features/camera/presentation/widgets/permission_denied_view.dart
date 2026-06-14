import 'package:flutter/material.dart';

class PermissionDeniedView extends StatelessWidget {
  const PermissionDeniedView({
    super.key,
    required this.permanently,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final bool permanently;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined,
                color: Colors.white70, size: 64),
            const SizedBox(height: 16),
            Text(
              permanently ? '設定アプリでカメラへのアクセスを許可してください。' : 'カメラへのアクセスが必要です。',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: permanently ? onOpenSettings : onRetry,
              child: Text(permanently ? '設定を開く' : '許可する'),
            ),
          ],
        ),
      ),
    );
  }
}
