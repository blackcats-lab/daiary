import 'dart:io';

/// ギャラリーから 1 枚画像を取得する責務を持つ抽象。
/// 実装は `data/repositories/image_source_repository_impl.dart`。
abstract class ImageSourceRepository {
  /// ギャラリーから 1 枚選択。ユーザーがキャンセルした場合は null を返す。
  /// 権限拒否や picker 失敗は CameraFailure を throw する。
  Future<File?> pickFromGallery();
}
