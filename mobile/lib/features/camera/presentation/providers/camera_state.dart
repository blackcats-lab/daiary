import 'package:camera/camera.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/exceptions/camera_failure.dart';

part 'camera_state.freezed.dart';

@freezed
sealed class CameraState with _$CameraState {
  const factory CameraState.initial() = CameraInitial;
  const factory CameraState.initializing() = CameraInitializing;
  const factory CameraState.ready({
    required CameraController controller,
    required CameraLensDirection lens,
    required FlashMode flash,
    required List<CameraDescription> cameras,
  }) = CameraReady;
  const factory CameraState.permissionDenied({required bool permanently}) =
      CameraPermissionDenied;
  const factory CameraState.error(CameraFailure failure) = CameraError;
}
