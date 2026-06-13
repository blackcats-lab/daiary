import 'package:daiary/features/photo_edit/domain/color_matrix.dart';
import 'package:daiary/features/photo_edit/domain/filter_presets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('multiply', () {
    test('恒等行列との積は元の行列', () {
      final m = ColorMatrix.brightness(0.2);
      final result = ColorMatrix.multiply(ColorMatrix.identity, m);
      for (var i = 0; i < 20; i++) {
        expect(result[i], closeTo(m[i], 1e-9));
      }
    });

    test('恒等×恒等は恒等', () {
      final result =
          ColorMatrix.multiply(ColorMatrix.identity, ColorMatrix.identity);
      for (var i = 0; i < 20; i++) {
        expect(result[i], closeTo(ColorMatrix.identity[i], 1e-9));
      }
    });
  });

  group('brightness', () {
    test('0 は恒等', () {
      final m = ColorMatrix.brightness(0);
      for (var i = 0; i < 20; i++) {
        expect(m[i], closeTo(ColorMatrix.identity[i], 1e-9));
      }
    });

    test('正の値は各 RGB 行にオフセットを加える', () {
      final m = ColorMatrix.brightness(0.5);
      expect(m[4], closeTo(127.5, 1e-6)); // R オフセット
      expect(m[9], closeTo(127.5, 1e-6)); // G オフセット
      expect(m[14], closeTo(127.5, 1e-6)); // B オフセット
    });
  });

  group('contrast', () {
    test('0 は恒等', () {
      final m = ColorMatrix.contrast(0);
      for (var i = 0; i < 20; i++) {
        expect(m[i], closeTo(ColorMatrix.identity[i], 1e-9));
      }
    });
  });

  group('saturation', () {
    test('0 は恒等', () {
      final m = ColorMatrix.saturation(0);
      for (var i = 0; i < 20; i++) {
        expect(m[i], closeTo(ColorMatrix.identity[i], 1e-9));
      }
    });

    test('-1（完全グレースケール）は 3 行が同じ輝度係数になる', () {
      final m = ColorMatrix.saturation(-1);
      // R/G/B 各行の RGB 係数が等しい（行ごとに同じ重み）
      expect(m[0], closeTo(m[5], 1e-9));
      expect(m[5], closeTo(m[10], 1e-9));
      expect(m[1], closeTo(m[6], 1e-9));
      expect(m[2], closeTo(m[7], 1e-9));
    });
  });

  group('compose', () {
    test('空リストは恒等', () {
      final m = ColorMatrix.compose([]);
      for (var i = 0; i < 20; i++) {
        expect(m[i], closeTo(ColorMatrix.identity[i], 1e-9));
      }
    });

    test('恒等のみの合成は恒等', () {
      final m = ColorMatrix.compose([
        ColorMatrix.identity,
        ColorMatrix.brightness(0),
        ColorMatrix.contrast(0),
        ColorMatrix.saturation(0),
      ]);
      for (var i = 0; i < 20; i++) {
        expect(m[i], closeTo(ColorMatrix.identity[i], 1e-6));
      }
    });
  });

  group('FilterPresets', () {
    test('11 種以上のプリセットがある', () {
      expect(FilterPresets.all.length, greaterThanOrEqualTo(11));
    });

    test('各プリセットは 20 要素の行列を持つ', () {
      for (final p in FilterPresets.all) {
        expect(p.matrix.length, 20, reason: p.label);
      }
    });

    test('オリジナルは恒等行列', () {
      expect(FilterPresets.all.first.label, 'オリジナル');
      for (var i = 0; i < 20; i++) {
        expect(FilterPresets.all.first.matrix[i],
            closeTo(ColorMatrix.identity[i], 1e-9));
      }
    });

    test('ラベルが重複しない', () {
      final labels = FilterPresets.all.map((p) => p.label).toSet();
      expect(labels.length, FilterPresets.all.length);
    });
  });
}
