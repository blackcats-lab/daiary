import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../services/supabase_service.dart';
import '../../../album/presentation/providers/album_list_notifier.dart';
import '../../../photo/presentation/providers/photo_list_notifier.dart';
import '../../../photo/presentation/providers/photo_search_notifier.dart';
import '../../../photo/presentation/providers/photo_tags_provider.dart';
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

    _sub?.cancel();
    _sub = repo.watchAuthState().listen((user) {
      final previous = state;
      state = user;
      // 明示的な signOut() を経ないユーザー変化（トークン失効・別アカウント切替）でも
      // 前ユーザーのキャッシュが残らないようにする
      if (previous != null && previous.id != user?.id) {
        _invalidateUserScopedProviders();
      }
    });
    ref.onDispose(() => _sub?.cancel());

    return initial;
  }

  /// サインアップ。戻り値が true なら自動ログイン成立、
  /// false なら確認メール送信済み（未ログインのまま）。
  Future<bool> signUp({required String email, required String password}) async {
    final repo = ref.read(authRepositoryProvider);
    final user = await repo.signUp(email: email, password: password);
    if (user == null) return false;
    state = user;
    return true;
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
    _invalidateUserScopedProviders();
  }

  /// ユーザー固有データを持つ keepAlive provider を破棄する。
  ///
  /// photoListProvider / albumListProvider は keepAlive のため、サインアウトしても
  /// 前ユーザーの写真・アルバム（署名 URL 含む）が state に残り続ける。
  /// 破棄しないと同一端末で別アカウントにログインした際、load() が
  /// 「既に loaded」で早期 return して前ユーザーのデータが表示されてしまう。
  void _invalidateUserScopedProviders() {
    ref.invalidate(photoListProvider);
    ref.invalidate(photoSearchProvider);
    ref.invalidate(photoTagsProvider);
    ref.invalidate(albumListProvider);
  }
}
