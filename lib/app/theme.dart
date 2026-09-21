import 'package:flutter/material.dart';

/// Original visual system: clean, modern, high-contrast casual-puzzle look.
/// The board and clues are always the visual priority; chrome stays quiet.
class AppTheme {
  AppTheme._();

  // Brand palette (original).
  static const Color primary = Color(0xFF3D5AFE); // indigo accent
  static const Color primaryDark = Color(0xFF2536C9);
  static const Color accent = Color(0xFFFF7043); // warm coral for rewards
  static const Color surface = Color(0xFFF6F7FB);
  static const Color card = Colors.white;
  static const Color ink = Color(0xFF1B1E28);
  static const Color inkSoft = Color(0xFF5B6070);
  static const Color line = Color(0xFFD8DCE8);
  static const Color gridLine = Color(0xFFB9C0D4);
  static const Color gridMajor = Color(0xFF6B718A);
  static const Color filled = Color(0xFF2B2F3A);
  static const Color crossed = Color(0xFFB0B6C8);
  static const Color success = Color(0xFF2E9E5B);
  static const Color heart = Color(0xFFE0445B);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: surface,
      ),
      scaffoldBackgroundColor: surface,
      fontFamily: 'Roboto',
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }
}
