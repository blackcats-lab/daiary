import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../services/supabase_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_notifier.g.dart';

/// AuthRepository の Provider。
/// Phase 0 で `services/supabase_service.dart` に定義した SupabaseService を経由する。
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  final dataSource = AuthRemoteDataSource(SupabaseService.client);
  return AuthRepositoryImpl(dataSource);
}

/// 認証状態を保持する Notifier。
///
/// build() で SDK の `currentUser` を**即時**返す（loading にしない）。
/// 一度確定した状態は `onAuthStateChange` Stream を購読して `state` で更新する。
/// 旧実装の `Stream<AuthUser?>` build は、保存セッションが無いケースで
/// `INITIAL_SESSION` イベントが emit されず loading のままになる SDK 挙動に
/// 引っかかっていたため、本実装に置き換えた。
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  StreamSubscription<AuthUser?>? _sub;

  @override
  AuthUser? build() {
    final repo = ref.watch(authRepositoryProvider);
    final initial = repo.currentUser;

    // ===== DEBUG（バグ調査用、解決後削除） =====
    debugPrint('[AuthNotifier] build initial=$initial');

    _sub?.cancel();
    _sub = repo.watchAuthState().listen((user) {
      debugPrint('[AuthNotifier] watchAuthState emit user=$user');
      state = user;
    });
    ref.onDispose(() => _sub?.cancel());

    return initial;
  }

  Future<void> signUp({required String email, required String password}) async {
    final repo = ref.read(authRepositoryProvider);
    final user = await repo.signUp(email: email, password: password);
    state = user;
  }

  Future<void> signIn({required String email, required String password}) async {
    final repo = ref.read(authRepositoryProvider);
    final user = await repo.signIn(email: email, password: password);
    state = user;
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    state = null;
  }
}
