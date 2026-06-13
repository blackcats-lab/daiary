import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// カラーマトリクスを画像に焼き込んで JPEG として書き出すサービス。
///
/// プレビュー（ColorFilter.matrix）と同一の行列を Canvas で適用するため、
/// 見た目と保存結果が一致する。原寸は前処理済み（長辺 ≤1024px）の想定。
class PhotoEditRenderer {
  /// [source] に [matrix]（20 要素）を適用し、JPEG ファイルとして書き出す。
  /// matrix が恒等なら元画像をそのまま再エンコードする。
  Future<File> render(File source, List<double> matrix) async {
    final bytes = await source.readAsBytes();
    final image = await decodeImageFromList(bytes);
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()
        ..filterQuality = FilterQuality.high
        ..colorFilter = ColorFilter.matrix(matrix);
      canvas.drawImage(image, Offset.zero, paint);
      final picture = recorder.endRecording();
      final rendered = await picture.toImage(image.width, image.height);
      try {
        final pngData =
            await rendered.toByteData(format: ui.ImageByteFormat.png);
        if (pngData == null) {
          throw StateError('画像のエンコードに失敗しました');
        }
        return _writeJpeg(pngData.buffer.asUint8List());
      } finally {
        rendered.dispose();
        picture.dispose();
      }
    } finally {
      image.dispose();
    }
  }

  /// PNG バイト列を JPEG q80 に再圧縮してキャッシュへ書き出す。
  Future<File> _writeJpeg(Uint8List pngBytes) async {
    final jpeg = await FlutterImageCompress.compressWithList(
      pngBytes,
      format: CompressFormat.jpeg,
      quality: 80,
    );
    final dir = await getTemporaryDirectory();
    final out = File(
      '${dir.path}/edit_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await out.writeAsBytes(jpeg, flush: true);
    return out;
  }
}
