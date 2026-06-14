import 'package:freezed_annotation/freezed_annotation.dart';

part 'uploaded_photo.freezed.dart';

@freezed
abstract class UploadedPhoto with _$UploadedPhoto {
  const factory UploadedPhoto({
    required String id,
    required String storagePath,
    required String thumbnailPath,
    required DateTime createdAt,
  }) = _UploadedPhoto;
}
