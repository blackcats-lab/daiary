import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// dAIary ブランドカラーパレット。
/// 出典: docs/dAIary_brand_design.jsx
class DaiaryColors {
  const DaiaryColors._();

  /// AI 強調・主要 CTA
  static const Color brandGold = Color(0xFFC4956A);

  /// 主要テキスト・ダーク背景
  static const Color deepBrown = Color(0xFF2D2420);

  /// 標準背景・カード
  static const Color cream = Color(0xFFF5EFE8);

  /// グラデーション・ホバー
  static const Color warmAccent = Color(0xFFE8A87C);

  /// 補助色
  static const Color softGray = Color(0xFF8B8580);
  static const Color lineGray = Color(0xFFE8E2DA);
  static const Color errorRed = Color(0xFFC85A4F);
  static const Color successGreen = Color(0xFF6B8E5A);
}

/// dAIary 用 ThemeData ファクトリ。
class DaiaryTheme {
  const DaiaryTheme._();

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: DaiaryColors.brandGold,
        primary: DaiaryColors.brandGold,
        onPrimary: Colors.white,
        secondary: DaiaryColors.warmAccent,
        surface: DaiaryColors.cream,
        onSurface: DaiaryColors.deepBrown,
        error: DaiaryColors.errorRed,
      ),
      scaffoldBackgroundColor: DaiaryColors.cream,
      textTheme: _textTheme(base.textTheme, DaiaryColors.deepBrown),
      appBarTheme: const AppBarTheme(
        backgroundColor: DaiaryColors.cream,
        foregroundColor: DaiaryColors.deepBrown,
        elevation: 0,
        centerTitle: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: DaiaryColors.brandGold,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: DaiaryColors.brandGold,
        brightness: Brightness.dark,
        primary: DaiaryColors.brandGold,
        onPrimary: DaiaryColors.deepBrown,
        secondary: DaiaryColors.warmAccent,
        surface: DaiaryColors.deepBrown,
        onSurface: DaiaryColors.cream,
        error: DaiaryColors.errorRed,
      ),
      scaffoldBackgroundColor: DaiaryColors.deepBrown,
      textTheme: _textTheme(base.textTheme, DaiaryColors.cream),
      appBarTheme: const AppBarTheme(
        backgroundColor: DaiaryColors.deepBrown,
        foregroundColor: DaiaryColors.cream,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, Color onSurface) {
    final serif = GoogleFonts.playfairDisplayTextTheme(base);
    final sans = GoogleFonts.notoSansJpTextTheme(base);
    return base.copyWith(
      displayLarge: serif.displayLarge?.copyWith(color: onSurface, fontWeight: FontWeight.w700),
      displayMedium: serif.displayMedium?.copyWith(color: onSurface, fontWeight: FontWeight.w700),
      displaySmall: serif.displaySmall?.copyWith(color: onSurface, fontWeight: FontWeight.w700),
      headlineLarge: serif.headlineLarge?.copyWith(color: onSurface),
      headlineMedium: serif.headlineMedium?.copyWith(color: onSurface),
      headlineSmall: serif.headlineSmall?.copyWith(color: onSurface),
      titleLarge: sans.titleLarge?.copyWith(color: onSurface, fontWeight: FontWeight.w500),
      titleMedium: sans.titleMedium?.copyWith(color: onSurface, fontWeight: FontWeight.w500),
      titleSmall: sans.titleSmall?.copyWith(color: onSurface, fontWeight: FontWeight.w500),
      bodyLarge: sans.bodyLarge?.copyWith(color: onSurface),
      bodyMedium: sans.bodyMedium?.copyWith(color: onSurface),
      bodySmall: sans.bodySmall?.copyWith(color: onSurface.withValues(alpha: 0.7)),
      labelLarge: sans.labelLarge?.copyWith(color: onSurface, fontWeight: FontWeight.w500),
    );
  }
}
