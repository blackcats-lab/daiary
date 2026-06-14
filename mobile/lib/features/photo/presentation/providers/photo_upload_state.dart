import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/exceptions/photo_failure.dart';
import '../../domain/entities/uploaded_photo.dart';

part 'photo_upload_state.freezed.dart';

@freezed
sealed class PhotoUploadState with _$PhotoUploadState {
  const factory PhotoUploadState.idle() = PhotoUploadIdle;
  const factory PhotoUploadState.uploading() = PhotoUploadUploading;
  const factory PhotoUploadState.success(UploadedPhoto photo) =
      PhotoUploadSuccess;
  const factory PhotoUploadState.failure(PhotoFailure failure) =
      PhotoUploadFailure;
}
