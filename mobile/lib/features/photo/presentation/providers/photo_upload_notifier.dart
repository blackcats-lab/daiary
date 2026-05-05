import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/exceptions/photo_failure.dart';
import '../../../camera/domain/entities/captured_image.dart';
import '../../data/repositories/photo_upload_repository.dart';
import 'photo_upload_state.dart';

part 'photo_upload_notifier.g.dart';

@Riverpod(keepAlive: false)
class PhotoUploadNotifier extends _$PhotoUploadNotifier {
  @override
  PhotoUploadState build() => const PhotoUploadState.idle();

  Future<void> upload(CapturedImage image) async {
    state = const PhotoUploadState.uploading();
    try {
      final uploaded =
          await ref.read(photoUploadRepositoryProvider).upload(image);
      state = PhotoUploadState.success(uploaded);
    } on PhotoFailure catch (f) {
      state = PhotoUploadState.failure(f);
    } catch (e) {
      state = PhotoUploadState.failure(
        PhotoFailure('unknown', 'アップロード中に予期せぬエラーが発生しました: $e'),
      );
    }
  }

  void reset() {
    state = const PhotoUploadState.idle();
  }
}
