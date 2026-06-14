/// メール・パスワードの入力バリデーション。
/// UI 層の controller 値を直接受け取り、エラーメッセージを返す（null = OK）。
class AuthValidators {
  const AuthValidators._();

  static final RegExp _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'メールアドレスを入力してください';
    if (!_emailRe.hasMatch(trimmed)) return 'メールアドレスの形式が不正です';
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) return 'パスワードを入力してください';
    if (value.length < 6) return 'パスワードは 6 文字以上で入力してください';
    return null;
  }
}
