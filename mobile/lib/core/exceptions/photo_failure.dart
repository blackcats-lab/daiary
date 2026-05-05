class PhotoFailure implements Exception {
  PhotoFailure(this.code, this.message);

  /// 主な値:
  /// - `unauthenticated` ログインしていない
  /// - `upload_failed` Storage アップロード失敗
  /// - `metadata_failed` photos POST 失敗（Storage の補償 delete 後にスロー）
  /// - `network` 通信エラー
  /// - `unknown` その他
  final String code;
  final String message;

  @override
  String toString() => 'PhotoFailure($code): $message';
}
