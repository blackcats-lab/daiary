class AlbumFailure implements Exception {
  AlbumFailure(this.code, this.message);

  /// 主な値:
  /// - `network` 通信エラー
  /// - `service_failed` Edge Function 呼び出し失敗
  /// - `create_failed` POST /albums 失敗
  /// - `not_found` 該当アルバムが存在しない
  /// - `update_failed` PATCH /albums/:id 失敗
  /// - `delete_failed` DELETE /albums/:id 失敗
  /// - `add_photos_failed` POST /albums/:id/photos 失敗
  /// - `remove_photos_failed` DELETE /albums/:id/photos 失敗
  /// - `unauthenticated` 認証エラー
  /// - `unknown` その他
  final String code;
  final String message;

  @override
  String toString() => 'AlbumFailure($code): $message';
}
