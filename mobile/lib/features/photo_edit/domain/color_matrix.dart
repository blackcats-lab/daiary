import 'dart:math' as math;

/// 4x5 カラーマトリクス（20 要素）のユーティリティ。
///
/// ColorFilter.matrix と同じ行優先 20 要素レイアウト:
///   [ R': r0 r1 r2 r3 r4
///     G': r5 r6 r7 r8 r9
///     B': r10 r11 r12 r13 r14
///     A': r15 r16 r17 r18 r19 ]
/// 各出力チャンネル = 係数·(R,G,B,A) + オフセット(列 5, 0-255 スケール)。
class ColorMatrix {
  const ColorMatrix._();

  /// 恒等行列（無変換）。
  static const List<double> identity = [
    1, 0, 0, 0, 0, //
    0, 1, 0, 0, 0, //
    0, 0, 1, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  /// 2 つの 4x5 マトリクスを合成する（a を b の後に適用 = a·b）。
  /// 5 行目は暗黙の [0,0,0,0,1] として扱う。
  static List<double> multiply(List<double> a, List<double> b) {
    assert(a.length == 20 && b.length == 20);
    final out = List<double>.filled(20, 0);
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 5; col++) {
        var sum = 0.0;
        for (var k = 0; k < 4; k++) {
          sum += a[row * 5 + k] * b[k * 5 + col];
        }
        // b の 5 行目は [0,0,0,0,1] なので、col==4 のとき a の定数項を加える
        if (col == 4) sum += a[row * 5 + 4];
        out[row * 5 + col] = sum;
      }
    }
    return out;
  }

  /// 複数マトリクスを左から順に合成する（先頭が最初に適用される）。
  static List<double> compose(List<List<double>> matrices) {
    var result = identity;
    for (final m in matrices) {
      result = multiply(m, result);
    }
    return result;
  }

  /// 明るさ調整。[value] は -1.0〜1.0（0 で無変換）。
  /// 各チャンネルに value*255 のオフセットを加える。
  static List<double> brightness(double value) {
    final b = value * 255.0;
    return [
      1, 0, 0, 0, b, //
      0, 1, 0, 0, b, //
      0, 0, 1, 0, b, //
      0, 0, 0, 1, 0, //
    ];
  }

  /// コントラスト調整。[value] は -1.0〜1.0（0 で無変換）。
  static List<double> contrast(double value) {
    final c = value + 1.0; // 0..2 の係数
    final t = (1.0 - c) * 127.5; // 中心 127.5 を保つオフセット
    return [
      c, 0, 0, 0, t, //
      0, c, 0, 0, t, //
      0, 0, c, 0, t, //
      0, 0, 0, 1, 0, //
    ];
  }

  /// 彩度調整。[value] は -1.0〜1.0（0 で無変換、-1 で完全グレースケール）。
  /// 輝度係数は Rec.601。
  static List<double> saturation(double value) {
    final s = value + 1.0; // 0..2
    const lr = 0.3086, lg = 0.6094, lb = 0.0820;
    final sr = (1 - s) * lr;
    final sg = (1 - s) * lg;
    final sb = (1 - s) * lb;
    return [
      sr + s, sg, sb, 0, 0, //
      sr, sg + s, sb, 0, 0, //
      sr, sg, sb + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }

  /// 色相回転（プリセット用）。[degrees] 度。
  static List<double> hueRotate(double degrees) {
    final rad = degrees * math.pi / 180.0;
    final cos = math.cos(rad);
    final sin = math.sin(rad);
    const lr = 0.213, lg = 0.715, lb = 0.072;
    return [
      lr + cos * (1 - lr) + sin * (-lr),
      lg + cos * (-lg) + sin * (-lg),
      lb + cos * (-lb) + sin * (1 - lb),
      0, 0, //
      lr + cos * (-lr) + sin * 0.143,
      lg + cos * (1 - lg) + sin * 0.140,
      lb + cos * (-lb) + sin * (-0.283),
      0, 0, //
      lr + cos * (-lr) + sin * (-(1 - lr)),
      lg + cos * (-lg) + sin * lg,
      lb + cos * (1 - lb) + sin * lb,
      0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }
}
