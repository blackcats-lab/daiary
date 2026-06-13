import 'color_matrix.dart';

/// 写真編集のプリセットフィルタ。
/// 要件 F-CAM-004「プリセット 10 種類以上」を満たす 11 種。
class FilterPreset {
  const FilterPreset({required this.label, required this.matrix});

  final String label;

  /// ColorFilter.matrix に渡す 20 要素のカラーマトリクス。
  final List<double> matrix;
}

class FilterPresets {
  const FilterPresets._();

  /// グレースケール（彩度 0）。
  static const List<double> _mono = [
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  /// セピア。
  static const List<double> _sepia = [
    0.393, 0.769, 0.189, 0, 0, //
    0.349, 0.686, 0.168, 0, 0, //
    0.272, 0.534, 0.131, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  /// 高コントラストモノクロ（ノワール）。
  static final _noir = ColorMatrix.multiply(ColorMatrix.contrast(0.35), _mono);

  /// 鮮やか（彩度 +、コントラスト微増）。
  static final _vivid = ColorMatrix.compose([
    ColorMatrix.saturation(0.4),
    ColorMatrix.contrast(0.1),
  ]);

  /// 暖色寄り。
  static const List<double> _warm = [
    1.1, 0, 0, 0, 8, //
    0, 1.0, 0, 0, 4, //
    0, 0, 0.9, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  /// 寒色寄り。
  static const List<double> _cool = [
    0.9, 0, 0, 0, 0, //
    0, 1.0, 0, 0, 2, //
    0, 0, 1.1, 0, 10, //
    0, 0, 0, 1, 0, //
  ];

  /// フェード（コントラスト下げ + 持ち上げ）。
  static final _fade = ColorMatrix.multiply(
    ColorMatrix.brightness(0.06),
    ColorMatrix.contrast(-0.25),
  );

  /// ヴィンテージ（セピア寄り + 彩度落とし）。
  static final _vintage = ColorMatrix.multiply(
    ColorMatrix.saturation(-0.3),
    _sepia,
  );

  /// フィルム（彩度やや上げ + わずかに暖色）。
  static final _film = ColorMatrix.multiply(
    const <double>[
      1.05, 0, 0, 0, 4, //
      0, 1.0, 0, 0, 0, //
      0, 0, 0.95, 0, 2, //
      0, 0, 0, 1, 0, //
    ],
    ColorMatrix.saturation(0.15),
  );

  /// ドリーミー（明るめ + 彩度下げ）。
  static final _dreamy = ColorMatrix.compose([
    ColorMatrix.brightness(0.1),
    ColorMatrix.saturation(-0.15),
    ColorMatrix.contrast(-0.1),
  ]);

  static final List<FilterPreset> all = [
    const FilterPreset(label: 'オリジナル', matrix: ColorMatrix.identity),
    const FilterPreset(label: 'モノクロ', matrix: _mono),
    FilterPreset(label: 'ノワール', matrix: _noir),
    const FilterPreset(label: 'セピア', matrix: _sepia),
    FilterPreset(label: 'ヴィヴィッド', matrix: _vivid),
    const FilterPreset(label: 'ウォーム', matrix: _warm),
    const FilterPreset(label: 'クール', matrix: _cool),
    FilterPreset(label: 'フェード', matrix: _fade),
    FilterPreset(label: 'ヴィンテージ', matrix: _vintage),
    FilterPreset(label: 'フィルム', matrix: _film),
    FilterPreset(label: 'ドリーミー', matrix: _dreamy),
  ];
}
