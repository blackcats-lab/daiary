/// 認証処理で発生する例外を UI 層に伝えるための型。
///
/// SDK 固有の AuthException を直接 throw せず、本クラスでラップして
/// [code] によるメッセージ切り替えを Repository 層で吸収する。
class AuthFailure implements Exception {
  AuthFailure(this.code, this.message);

  /// 主な値:
  /// - `invalid_credentials` メール/パスワード不一致
  /// - `email_taken` 既存メール
  /// - `weak_password` パスワードが弱い
  /// - `network` 通信エラー
  /// - `unknown` その他
  final String code;
  final String message;

  @override
  String toString() => 'AuthFailure($code): $message';
}
