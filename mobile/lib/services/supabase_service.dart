import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase クライアントへのアクセス窓口。
/// `Supabase.initialize` は `main.dart` で済ませている前提。
class SupabaseService {
  const SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static String? get currentUserId => currentUser?.id;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  /// Edge Function を JWT 自動付与で呼び出す。
  /// GET の場合は [body] を null にして [queryParameters] を使う。
  static Future<FunctionResponse> invokeFunction(
    String name, {
    HttpMethod method = HttpMethod.post,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) {
    return client.functions.invoke(
      name,
      method: method,
      body: body,
      queryParameters: queryParameters,
    );
  }
}
