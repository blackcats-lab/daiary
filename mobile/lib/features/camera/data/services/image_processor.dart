import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/exceptions/camera_failure.dart';
import '../../domain/entities/captured_image.dart';

/// 撮影/取り込みした画像を AI 送信向けの形式に揃える。
/// 仕様: 長辺 1024px / JPEG q80 / HEIC→JPEG。
/// 出典: docs/architecture.md L40-51
class ImageProcessor {
  static const int _defaultMaxLongEdge = 1024;
  static const int _defaultQuality = 80;

  /// [source] を圧縮・リサイズし、キャッシュディレクトリに JPEG で書き出した
  /// File を返す。失敗時は CameraFailure('processing_failed') を throw。
  Future<CapturedImage> process(
    File source, {
    required CaptureSource origin,
    int maxLongEdge = _defaultMaxLongEdge,
    int quality = _defaultQuality,
  }) async {
    final outDir = await _ensureOutputDir();
    final outPath =
        '${outDir.path}/cap_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final XFile? compressed;
    try {
      compressed = await FlutterImageCompress.compressAndGetFile(
        source.absolute.path,
        outPath,
        format: CompressFormat.jpeg,
        minWidth: maxLongEdge,
        minHeight: maxLongEdge,
        quality: quality,
        keepExif: false,
      );
    } catch (e) {
      throw CameraFailure('processing_failed', '画像の変換に失敗しました');
    }

    if (compressed == null) {
      throw CameraFailure('processing_failed', '画像の変換に失敗しました');
    }

    final outFile = File(compressed.path);
    final bytes = await outFile.length();
    final dimensions = await _readDimensions(outFile);

    return CapturedImage(
      processedFile: outFile,
      sizeBytes: bytes,
      width: dimensions.$1,
      height: dimensions.$2,
      capturedAt: DateTime.now(),
      source: origin,
    );
  }

  Future<Directory> _ensureOutputDir() async {
    try {
      final tmp = await getTemporaryDirectory();
      final dir = Directory('${tmp.path}/daiary_capture');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } catch (e) {
      throw CameraFailure('cache_failed', 'キャッシュディレクトリの確保に失敗しました');
    }
  }

  Future<(int, int)> _readDimensions(File file) async {
    // flutter_image_compress は dimension を返さないため、
    // Image decoder を簡易的に使う代わりに 0 で埋めて UI 側で再計測する。
    // ここでは厳密な値が不要なので 0 を返す（必要になったら image パッケージで補う）。
    return (0, 0);
  }

  /// 一覧画面用のサムネ。長辺 256px / JPEG q70。
  /// 出力先は process() と同じキャッシュディレクトリ配下。
  Future<File> generateThumbnail(
    File source, {
    int maxLongEdge = 256,
    int quality = 70,
  }) async {
    final outDir = await _ensureOutputDir();
    final outPath =
        '${outDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final XFile? compressed;
    try {
      compressed = await FlutterImageCompress.compressAndGetFile(
        source.absolute.path,
        outPath,
        format: CompressFormat.jpeg,
        minWidth: maxLongEdge,
        minHeight: maxLongEdge,
        quality: quality,
        keepExif: false,
      );
    } catch (e) {
      throw CameraFailure('processing_failed', 'サムネイル生成に失敗しました');
    }

    if (compressed == null) {
      throw CameraFailure('processing_failed', 'サムネイル生成に失敗しました');
    }

    return File(compressed.path);
  }
}
