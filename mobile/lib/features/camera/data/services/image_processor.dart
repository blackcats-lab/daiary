import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

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

    final target = await _targetDimensions(source, maxLongEdge);

    final XFile? compressed;
    try {
      compressed = await FlutterImageCompress.compressAndGetFile(
        source.absolute.path,
        outPath,
        format: CompressFormat.jpeg,
        minWidth: target.$1,
        minHeight: target.$2,
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

  /// flutter_image_compress の minWidth/minHeight は「両辺がこの値以上になる」
  /// 下限指定（短辺基準）で、正方形指定 (1024, 1024) だと 4032x3024 は
  /// 1365x1024（長辺 1365）になり、片辺が 1024 未満のパノラマ等は一切
  /// リサイズされない。元画像の寸法から「長辺 = maxLongEdge」となる目標サイズを
  /// 計算して渡すことで、仕様（長辺 1024px）と 1.5MB のアップロード上限を守る。
  Future<(int, int)> _targetDimensions(File source, int maxLongEdge) async {
    final dims = await _readDimensions(source);
    if (dims.$1 <= 0 || dims.$2 <= 0) {
      // 寸法が読めない場合（対応外コーデック等）は従来通りの下限指定に留める
      return (maxLongEdge, maxLongEdge);
    }
    final longEdge = max(dims.$1, dims.$2);
    if (longEdge <= maxLongEdge) return dims; // 拡大はしない
    final scale = maxLongEdge / longEdge;
    return (
      max(1, (dims.$1 * scale).round()),
      max(1, (dims.$2 * scale).round()),
    );
  }

  /// 画像ヘッダのみデコードして寸法を返す。失敗時は (0, 0)。
  Future<(int, int)> _readDimensions(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return await _dimensionsFromBytes(bytes);
    } catch (_) {
      return (0, 0);
    }
  }

  Future<(int, int)> _dimensionsFromBytes(Uint8List bytes) async {
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      return (descriptor.width, descriptor.height);
    } catch (_) {
      return (0, 0);
    } finally {
      descriptor?.dispose();
      buffer?.dispose();
    }
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

    final target = await _targetDimensions(source, maxLongEdge);

    final XFile? compressed;
    try {
      compressed = await FlutterImageCompress.compressAndGetFile(
        source.absolute.path,
        outPath,
        format: CompressFormat.jpeg,
        minWidth: target.$1,
        minHeight: target.$2,
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
