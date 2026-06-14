import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';

/// 認証済みユーザーを表す Domain エンティティ。
/// `supabase_flutter` の User クラスから必要最小限のフィールドだけ抽出する。
@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String id,
    required String email,
    DateTime? createdAt,
  }) = _AuthUser;
}
