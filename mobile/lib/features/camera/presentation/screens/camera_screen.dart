import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/captured_image.dart';
import '../providers/camera_controller_notifier.dart';
import '../providers/camera_state.dart';
import '../providers/image_capture_notifier.dart';
import '../providers/image_capture_state.dart';
import '../widgets/camera_controls_bar.dart';
import '../widgets/camera_preview_view.dart';
import '../widgets/permission_denied_view.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cameraControllerProvider.notifier).initialize();
    });
  }

  Future<void> _onShutter() async {
    final image =
        await ref.read(imageCaptureProvider.notifier).captureFromCamera();
    if (!mounted) return;
    if (image != null) {
      _goToPreview(image);
    } else {
      _maybeShowFailure();
    }
  }

  Future<void> _onPickGallery() async {
    final image =
        await ref.read(imageCaptureProvider.notifier).captureFromGallery();
    if (!mounted) return;
    if (image != null) {
      _goToPreview(image);
    } else {
      _maybeShowFailure();
    }
  }

  void _goToPreview(CapturedImage image) {
    context.push('/camera/preview', extra: image);
    ref.read(imageCaptureProvider.notifier).reset();
  }

  void _maybeShowFailure() {
    final s = ref.read(imageCaptureProvider);
    if (s is ImageCaptureFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.failure.message)),
      );
      ref.read(imageCaptureProvider.notifier).reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraControllerProvider);
    final captureState = ref.watch(imageCaptureProvider);
    final busy = captureState is ImageCaptureCapturing ||
        captureState is ImageCaptureProcessing;

    return Scaffold(
      backgroundColor: Colors.black,
      body: switch (cameraState) {
        CameraInitial() || CameraInitializing() => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        CameraPermissionDenied(:final permanently) => PermissionDeniedView(
            permanently: permanently,
            onRetry: () =>
                ref.read(cameraControllerProvider.notifier).initialize(),
            onOpenSettings: () => ref
                .read(cameraControllerProvider.notifier)
                .openAppSettingsPage(),
          ),
        CameraError(:final failure) => _ErrorView(
            message: failure.message,
            onRetry: () =>
                ref.read(cameraControllerProvider.notifier).initialize(),
            onPickGallery: _onPickGallery,
          ),
        CameraReady(:final controller, :final flash) => Stack(
            children: [
              Positioned.fill(child: CameraPreviewView(controller: controller)),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => context.go('/home'),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: CameraControlsBar(
                  flash: flash,
                  busy: busy,
                  onShutter: _onShutter,
                  onSwitchLens: () =>
                      ref.read(cameraControllerProvider.notifier).switchLens(),
                  onCycleFlash: () =>
                      ref.read(cameraControllerProvider.notifier).cycleFlash(),
                  onPickFromGallery: _onPickGallery,
                ),
              ),
              if (busy)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x66000000),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onPickGallery,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onPickGallery;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 64),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onRetry, child: const Text('再試行')),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onPickGallery,
              child: const Text(
                'ギャラリーから選択',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
