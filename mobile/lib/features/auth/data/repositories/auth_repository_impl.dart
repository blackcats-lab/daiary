import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../../core/exceptions/auth_failure.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// AuthRepository の Supabase 実装。
/// SDK 固有の AuthException を AuthFailure に変換して上位層に伝える。
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource);

  final AuthRemoteDataSource _dataSource;

  @override
  AuthUser? get currentUser => _toEntity(_dataSource.currentUser);

  @override
  Stream<AuthUser?> watchAuthState() {
    return _dataSource.onAuthStateChange
        .map((state) => _toEntity(state.session?.user));
  }

  @override
  Future<AuthUser> signUp(
      {required String email, required String password}) async {
    try {
      final res = await _dataSource.signUp(email: email, password: password);
      final user = res.user;
      if (user == null) {
        throw AuthFailure('unknown', 'サインアップに失敗しました（user が null）');
      }
      return _toEntity(user)!;
    } on AuthException catch (e) {
      throw _mapException(e);
    } catch (_) {
      throw AuthFailure('unknown', '予期せぬエラーが発生しました');
    }
  }

  @override
  Future<AuthUser> signIn(
      {required String email, required String password}) async {
    try {
      final res = await _dataSource.signInWithPassword(
          email: email, password: password);
      final user = res.user;
      if (user == null) {
        throw AuthFailure('unknown', 'ログインに失敗しました（user が null）');
      }
      return _toEntity(user)!;
    } on AuthException catch (e) {
      throw _mapException(e);
    } catch (_) {
      throw AuthFailure('unknown', '予期せぬエラーが発生しました');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _dataSource.signOut();
    } on AuthException catch (e) {
      throw _mapException(e);
    }
  }

  AuthUser? _toEntity(User? user) {
    if (user == null) return null;
    return AuthUser(
      id: user.id,
      email: user.email ?? '',
      createdAt: DateTime.tryParse(user.createdAt),
    );
  }

  AuthFailure _mapException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return AuthFailure('invalid_credentials', 'メールアドレスまたはパスワードが違います');
    }
    if (msg.contains('already registered') || msg.contains('already exists')) {
      return AuthFailure('email_taken', 'このメールアドレスは既に登録されています');
    }
    if (msg.contains('password') && msg.contains('weak')) {
      return AuthFailure('weak_password', 'パスワードが脆弱です（6 文字以上推奨）');
    }
    if (msg.contains('network') || msg.contains('failed host lookup')) {
      return AuthFailure('network', 'ネットワークに接続できませんでした');
    }
    return AuthFailure('unknown', e.message);
  }
}
