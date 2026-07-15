import '../entities/auth_user.dart';

/// 認証関連のリポジトリ抽象。
/// 実装は data/repositories/auth_repository_impl.dart。
abstract class AuthRepository {
  /// 現在のセッションから AuthUser を返す。未ログインなら null。
  AuthUser? get currentUser;

  /// 認証状態の変化を購読するストリーム。サインアウトや別端末でのログアウトも検知。
  Stream<AuthUser?> watchAuthState();

  /// メール + パスワードでサインアップする。
  ///
  /// セッションが即時発行された場合（メール確認無効の環境）は AuthUser を返し
  /// 自動ログインになる。メール確認が必要な環境ではセッションが発行されないため
  /// null を返す（確認メール送信済み・未ログイン）。
  Future<AuthUser?> signUp({required String email, required String password});

  /// メール + パスワードでサインイン。
  Future<AuthUser> signIn({required String email, required String password});

  /// サインアウト。ローカルセッションも消える。
  Future<void> signOut();
}
