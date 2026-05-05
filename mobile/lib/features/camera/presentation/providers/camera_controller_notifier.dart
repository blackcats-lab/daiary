import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/exceptions/camera_failure.dart';
import '../../data/services/permission_service.dart';
import 'camera_state.dart';

part 'camera_controller_notifier.g.dart';

@Riverpod(keepAlive: false)
PermissionService permissionService(Ref ref) => PermissionService();

/// CameraController のライフサイクルを管理する Notifier。
/// - initialize() で権限要求 → デバイス列挙 → controller 初期化
/// - 撮影/前後切替/フラッシュ切替を提供
/// - dispose() で controller を解放
@Riverpod(keepAlive: false)
class CameraControllerNotifier extends _$CameraControllerNotifier {
  CameraController? _controller;
  bool _disposed = false;

  @override
  CameraState build() {
    ref.onDispose(() {
      _disposed = true;
      // Riverpod の dispose 中は state を参照できないため、保持していた
      // controller 参照だけを使って解放する。
      final c = _controller;
      _controller = null;
      c?.dispose();
    });
    return const CameraState.initial();
  }

  Future<void> initialize() async {
    if (_disposed) return;
    state = const CameraState.initializing();
    final perm = await ref.read(permissionServiceProvider).requestCamera();
    if (_disposed) return;
    if (perm.isPermanentlyDenied) {
      state = const CameraState.permissionDenied(permanently: true);
      return;
    }
    if (!perm.isGranted) {
      state = const CameraState.permissionDenied(permanently: false);
      return;
    }

    try {
      final cameras = await availableCameras();
      if (_disposed) return;
      if (cameras.isEmpty) {
        state = CameraState.error(
          CameraFailure('no_camera', 'カメラが見つかりませんでした'),
        );
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (_disposed) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      state = CameraState.ready(
        controller: controller,
        lens: back.lensDirection,
        flash: FlashMode.off,
        cameras: cameras,
      );
    } catch (e) {
      if (_disposed) return;
      state = CameraState.error(
        CameraFailure('init_failed', 'カメラの起動に失敗しました'),
      );
    }
  }

  Future<XFile?> takePicture() async {
    final current = state;
    if (current is! CameraReady) return null;
    try {
      final file = await current.controller.takePicture();
      return file;
    } catch (e) {
      throw CameraFailure('capture_failed', '撮影に失敗しました');
    }
  }

  Future<void> switchLens() async {
    final current = state;
    if (current is! CameraReady) return;
    if (current.cameras.length < 2) return;

    final next = current.cameras.firstWhere(
      (c) => c.lensDirection != current.lens,
      orElse: () => current.cameras.first,
    );

    final oldController = current.controller;
    final newController = CameraController(
      next,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await newController.initialize();
      if (_disposed) {
        await newController.dispose();
        return;
      }
      _controller = newController;
      await oldController.dispose();
      state = CameraState.ready(
        controller: newController,
        lens: next.lensDirection,
        flash: FlashMode.off,
        cameras: current.cameras,
      );
    } catch (e) {
      if (_disposed) return;
      state = CameraState.error(
        CameraFailure('init_failed', 'カメラ切替に失敗しました'),
      );
    }
  }

  Future<void> cycleFlash() async {
    final current = state;
    if (current is! CameraReady) return;
    final next = switch (current.flash) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      FlashMode.always => FlashMode.off,
      FlashMode.torch => FlashMode.off,
    };
    try {
      await current.controller.setFlashMode(next);
      state = current.copyWith(flash: next);
    } catch (_) {
      // フラッシュ未対応端末は静かに無視
    }
  }

  Future<void> openAppSettingsPage() async {
    await openAppSettings();
  }
}
