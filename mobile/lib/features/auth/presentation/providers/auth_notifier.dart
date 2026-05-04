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

/// 認証状態を保持する AsyncNotifier。
///
/// build() で現在のセッションを返し、watchAuthState() で SDK の変化を購読する。
/// signIn / signUp / signOut の各メソッドはオプティミスティックではなく、
/// 完了後に SDK の onAuthStateChange が build() の値を更新する想定。
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  Stream<AuthUser?> build() {
    final repo = ref.watch(authRepositoryProvider);
    return repo.watchAuthState();
  }

  Future<void> signUp({required String email, required String password}) async {
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () async => repo.signUp(email: email, password: password));
  }

  Future<void> signIn({required String email, required String password}) async {
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () async => repo.signIn(email: email, password: password));
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.signOut();
      return null;
    });
  }
}
