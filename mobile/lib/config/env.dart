import 'package:flutter_dotenv/flutter_dotenv.dart';

/// .env から読み込んだ環境変数へのアクセサ。
/// 値が無い場合は空文字を返す（Supabase.initialize で例外になる前提）。
class Env {
  const Env._();

  static String get env => dotenv.maybeGet('ENV') ?? 'dev';

  static String get supabaseUrl => dotenv.maybeGet('SUPABASE_URL') ?? '';

  static String get supabaseAnonKey => dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '';

  static bool get isProduction => env == 'prod';
  static bool get isStaging => env == 'staging';
  static bool get isDevelopment => env == 'dev';
}
