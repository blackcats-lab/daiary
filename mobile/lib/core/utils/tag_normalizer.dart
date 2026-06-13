/// AI ハッシュタグの正規化ユーティリティ。
///
/// 手動編集 UI とサーバ仕様（最大 30 件 / 各 50 字）の整合を取る。
class TagNormalizer {
  const TagNormalizer._();

  static const int maxCount = 30;
  static const int maxLength = 50;

  /// 1 件のタグを正規化する。
  /// - 前後空白を除去
  /// - 先頭の `#` を 1 つ付与（既に付いていれば二重化しない）
  /// 空文字なら null を返す。
  static String? normalizeOne(String raw) {
    var t = raw.trim();
    if (t.isEmpty) return null;
    // 先頭の連続する # を 1 つに畳む
    t = t.replaceFirst(RegExp(r'^#+'), '');
    if (t.isEmpty) return null;
    return '#$t';
  }

  /// タグリストを正規化する。順序を保ったまま重複（大文字小文字無視）を除去し、
  /// 最大件数でクランプする。
  static List<String> normalizeList(Iterable<String> raw) {
    final seen = <String>{};
    final result = <String>[];
    for (final r in raw) {
      final t = normalizeOne(r);
      if (t == null) continue;
      final key = t.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      result.add(t);
      if (result.length >= maxCount) break;
    }
    return result;
  }

  /// 単一タグが追加可能かを検証する。問題なければ null、あればエラーメッセージ。
  static String? validateForAdd(String raw, List<String> existing) {
    final t = normalizeOne(raw);
    if (t == null) return 'タグを入力してください';
    if (t.length > maxLength) return 'タグは $maxLength 文字以内で入力してください';
    if (existing.any((e) => e.toLowerCase() == t.toLowerCase())) {
      return 'すでに追加されています';
    }
    if (existing.length >= maxCount) return 'タグは最大 $maxCount 件までです';
    return null;
  }
}
