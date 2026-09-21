import 'package:flutter/material.dart';

/// Original visual system: clean, modern, high-contrast casual-puzzle look.
///
/// Brand colors are fixed. Neutral/surface colors resolve from [brightness],
/// which the app sets each build to the effective (light/dark) mode. Because
/// the neutrals are getters, existing `AppTheme.ink`-style call sites keep
/// working and simply return the right value for the current mode.
class AppTheme {
  AppTheme._();

  /// Set by the app before building, so the getters below resolve correctly.
  static Brightness brightness = Brightness.light;
  static bool get _dark => brightness == Brightness.dark;

  // --- Brand palette (identical in both modes) ---
  static const Color primary = Color(0xFF3D5AFE);
  static const Color primaryDark = Color(0xFF2536C9);
  static const Color accent = Color(0xFFFF7043);
  static const Color success = Color(0xFF2E9E5B);
  static const Color heart = Color(0xFFE0445B);

  // --- Neutral palette (mode-aware) ---
  static Color get surface =>
      _dark ? const Color(0xFF0F1117) : const Color(0xFFF6F7FB);
  static Color get card =>
      _dark ? const Color(0xFF1B1F2A) : Colors.white;
  static Color get boardBg =>
      _dark ? const Color(0xFF232838) : Colors.white;
  static Color get ink =>
      _dark ? const Color(0xFFF1F3FA) : const Color(0xFF1B1E28);
  static Color get inkSoft =>
      _dark ? const Color(0xFF9BA2B6) : const Color(0xFF5B6070);
  static Color get line =>
      _dark ? const Color(0xFF2C3242) : const Color(0xFFD8DCE8);
  static Color get gridLine =>
      _dark ? const Color(0xFF3A4152) : const Color(0xFFB9C0D4);
  static Color get gridMajor =>
      _dark ? const Color(0xFF6B7690) : const Color(0xFF6B718A);
  static Color get filled =>
      _dark ? const Color(0xFFE8EAF2) : const Color(0xFF2B2F3A);
  static Color get crossed =>
      _dark ? const Color(0xFF6B7288) : const Color(0xFFB0B6C8);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: b,
      primary: primary,
      surface: isDark ? const Color(0xFF0F1117) : const Color(0xFFF6F7FB),
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: 'Roboto',
    );
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: isDark
            ? const Color(0xFFF1F3FA)
            : const Color(0xFF1B1E28),
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        color: isDark ? const Color(0xFF1B1F2A) : Colors.white,
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
