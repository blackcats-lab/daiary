import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/exceptions/camera_failure.dart';
import '../../domain/entities/captured_image.dart';

part 'image_capture_state.freezed.dart';

@freezed
sealed class ImageCaptureState with _$ImageCaptureState {
  const factory ImageCaptureState.idle() = ImageCaptureIdle;
  const factory ImageCaptureState.capturing() = ImageCaptureCapturing;
  const factory ImageCaptureState.processing() = ImageCaptureProcessing;
  const factory ImageCaptureState.success(CapturedImage image) =
      ImageCaptureSuccess;
  const factory ImageCaptureState.failure(CameraFailure failure) =
      ImageCaptureFailure;
}
