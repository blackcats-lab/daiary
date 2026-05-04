import 'package:permission_handler/permission_handler.dart';

/// Camera / Photos 権限のリクエストを 1 箇所にラップする。
class PermissionService {
  Future<PermissionStatus> requestCamera() => Permission.camera.request();

  Future<PermissionStatus> requestPhotos() async {
    final photos = await Permission.photos.request();
    if (photos.isGranted || photos.isLimited) return photos;
    // Android 12 以下では photos が unsupported 扱いになるため storage を試す
    if (photos.isDenied) {
      final storage = await Permission.storage.request();
      if (storage.isGranted) return storage;
    }
    return photos;
  }

  Future<bool> openSettings() => openAppSettings();
}
