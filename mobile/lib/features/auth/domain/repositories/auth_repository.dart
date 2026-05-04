import '../entities/auth_user.dart';

/// 認証関連のリポジトリ抽象。
/// 実装は data/repositories/auth_repository_impl.dart。
abstract class AuthRepository {
  /// 現在のセッションから AuthUser を返す。未ログインなら null。
  AuthUser? get currentUser;

  /// 認証状態の変化を購読するストリーム。サインアウトや別端末でのログアウトも検知。
  Stream<AuthUser?> watchAuthState();

  /// メール + パスワードでサインアップし、自動ログイン。
  Future<AuthUser> signUp({required String email, required String password});

  /// メール + パスワードでサインイン。
  Future<AuthUser> signIn({required String email, required String password});

  /// サインアウト。ローカルセッションも消える。
  Future<void> signOut();
}
