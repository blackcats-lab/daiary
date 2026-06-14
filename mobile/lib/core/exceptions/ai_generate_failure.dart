class AiGenerateFailure implements Exception {
  AiGenerateFailure(this.code, this.message, {this.remaining, this.limit});

  /// 主な値:
  /// - `unauthenticated` ログインしていない
  /// - `rate_limited` 当日の利用上限に到達（remaining/limit に値が入る）
  /// - `network` 通信エラー
  /// - `image_too_large` 画像が 1.5MB を超過（base64 で 2MB 制限を超える）
  /// - `service_failed` AI Edge Function が 4xx/5xx、または photos PATCH が失敗
  /// - `unknown` その他
  final String code;
  final String message;
  final int? remaining;
  final int? limit;

  @override
  String toString() => 'AiGenerateFailure($code): $message';
}
