import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'captured_image.freezed.dart';

enum CaptureSource { camera, gallery }

@freezed
abstract class CapturedImage with _$CapturedImage {
  const factory CapturedImage({
    required File processedFile,
    required int sizeBytes,
    required int width,
    required int height,
    required DateTime capturedAt,
    required CaptureSource source,
  }) = _CapturedImage;
}
