class PhotoFailure implements Exception {
  PhotoFailure(this.code, this.message);

  /// 主な値:
  /// - `unauthenticated` ログインしていない
  /// - `upload_failed` Storage アップロード失敗
  /// - `metadata_failed` photos POST 失敗（Storage の補償 delete 後にスロー）
  /// - `list_failed` 一覧の取得に失敗
  /// - `detail_failed` 詳細の取得に失敗
  /// - `update_failed` PATCH 失敗（お気に入り等）
  /// - `delete_failed` DELETE 失敗
  /// - `not_found` 該当写真が存在しない or 削除済み
  /// - `network` 通信エラー
  /// - `unknown` その他
  final String code;
  final String message;

  @override
  String toString() => 'PhotoFailure($code): $message';
}
