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
  static Future<FunctionResponse> invokeFunction(
    String name, {
    Map<String, dynamic>? body,
  }) {
    return client.functions.invoke(name, body: body);
  }
}
