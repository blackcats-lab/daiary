import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../../../../core/exceptions/camera_failure.dart';
import '../../domain/repositories/image_source_repository.dart';

class ImageSourceRepositoryImpl implements ImageSourceRepository {
  ImageSourceRepositoryImpl([ImagePicker? picker])
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<File?> pickFromGallery() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return null;
      return File(picked.path);
    } catch (e) {
      throw CameraFailure('picker_cancelled', 'ギャラリーから画像を取得できませんでした');
    }
  }
}
