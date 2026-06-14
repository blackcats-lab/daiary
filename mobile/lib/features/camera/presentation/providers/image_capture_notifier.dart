import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/exceptions/camera_failure.dart';
import '../../data/repositories/image_source_repository_impl.dart';
import '../../data/services/image_processor.dart';
import '../../domain/entities/captured_image.dart';
import '../../domain/repositories/image_source_repository.dart';
import 'camera_controller_notifier.dart';
import 'image_capture_state.dart';

part 'image_capture_notifier.g.dart';

@Riverpod(keepAlive: false)
ImageProcessor imageProcessor(Ref ref) => ImageProcessor();

@Riverpod(keepAlive: false)
ImageSourceRepository imageSourceRepository(Ref ref) =>
    ImageSourceRepositoryImpl();

/// 撮影 / ギャラリー取り込み / 前処理を一連で実行するオーケストレータ。
@Riverpod(keepAlive: false)
class ImageCaptureNotifier extends _$ImageCaptureNotifier {
  @override
  ImageCaptureState build() => const ImageCaptureState.idle();

  Future<CapturedImage?> captureFromCamera() async {
    state = const ImageCaptureState.capturing();
    try {
      final xfile =
          await ref.read(cameraControllerProvider.notifier).takePicture();
      if (xfile == null) {
        state = const ImageCaptureState.idle();
        return null;
      }
      state = const ImageCaptureState.processing();
      final processed = await ref
          .read(imageProcessorProvider)
          .process(File(xfile.path), origin: CaptureSource.camera);
      state = ImageCaptureState.success(processed);
      return processed;
    } on CameraFailure catch (f) {
      state = ImageCaptureState.failure(f);
      return null;
    } catch (_) {
      state = ImageCaptureState.failure(
        CameraFailure('unknown', '撮影中に予期せぬエラーが発生しました'),
      );
      return null;
    }
  }

  Future<CapturedImage?> captureFromGallery() async {
    final perm = await ref.read(permissionServiceProvider).requestPhotos();
    if (!perm.isGranted && !perm.isLimited) {
      state = ImageCaptureState.failure(
        CameraFailure(
          perm.isPermanentlyDenied
              ? 'permission_permanent'
              : 'permission_denied',
          '写真へのアクセスが許可されていません',
        ),
      );
      return null;
    }

    state = const ImageCaptureState.capturing();
    try {
      final source =
          await ref.read(imageSourceRepositoryProvider).pickFromGallery();
      if (source == null) {
        state = const ImageCaptureState.idle();
        return null;
      }
      state = const ImageCaptureState.processing();
      final processed = await ref
          .read(imageProcessorProvider)
          .process(source, origin: CaptureSource.gallery);
      state = ImageCaptureState.success(processed);
      return processed;
    } on CameraFailure catch (f) {
      state = ImageCaptureState.failure(f);
      return null;
    } catch (_) {
      state = ImageCaptureState.failure(
        CameraFailure('unknown', '画像取り込み中に予期せぬエラーが発生しました'),
      );
      return null;
    }
  }

  void reset() {
    state = const ImageCaptureState.idle();
  }
}
