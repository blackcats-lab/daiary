import 'package:daiary/core/utils/tag_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeOne', () {
    test('前後空白を除去し # を 1 つ付与', () {
      expect(TagNormalizer.normalizeOne('  海  '), '#海');
    });

    test('既存の # は二重化しない', () {
      expect(TagNormalizer.normalizeOne('#海'), '#海');
      expect(TagNormalizer.normalizeOne('##海'), '#海');
    });

    test('空文字・空白のみ・# のみは null', () {
      expect(TagNormalizer.normalizeOne(''), null);
      expect(TagNormalizer.normalizeOne('   '), null);
      expect(TagNormalizer.normalizeOne('#'), null);
    });
  });

  group('normalizeList', () {
    test('重複を大文字小文字無視で除去し順序を保つ', () {
      expect(
        TagNormalizer.normalizeList(['#海', '海', '#Sea', '#sea', '#空']),
        ['#海', '#Sea', '#空'],
      );
    });

    test('最大 30 件でクランプ', () {
      final input = List.generate(40, (i) => 'tag$i');
      expect(TagNormalizer.normalizeList(input), hasLength(30));
    });
  });

  group('validateForAdd', () {
    test('正常時は null', () {
      expect(TagNormalizer.validateForAdd('海', const ['#空']), null);
    });

    test('空入力はエラー', () {
      expect(TagNormalizer.validateForAdd('  ', const []), isNotNull);
    });

    test('重複はエラー', () {
      expect(TagNormalizer.validateForAdd('#海', const ['#海']), isNotNull);
    });

    test('50 字超はエラー', () {
      expect(TagNormalizer.validateForAdd('a' * 51, const []), isNotNull);
    });

    test('30 件到達済みはエラー', () {
      final existing = List.generate(30, (i) => '#tag$i');
      expect(TagNormalizer.validateForAdd('#new', existing), isNotNull);
    });
  });
}
