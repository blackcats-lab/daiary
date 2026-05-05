class CameraFailure implements Exception {
  CameraFailure(this.code, this.message);

  /// 主な値:
  /// - `permission_denied` 一時的な権限拒否
  /// - `permission_permanent` 永続的な権限拒否（設定アプリ誘導）
  /// - `no_camera` 利用可能なカメラデバイスなし
  /// - `init_failed` CameraController 初期化失敗
  /// - `capture_failed` takePicture 失敗
  /// - `processing_failed` 画像前処理（圧縮/HEIC変換）失敗
  /// - `cache_failed` キャッシュディレクトリ書き込み失敗
  /// - `picker_cancelled` ユーザーがギャラリー選択をキャンセル
  /// - `unknown` その他
  final String code;
  final String message;

  @override
  String toString() => 'CameraFailure($code): $message';
}
