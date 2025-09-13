import 'package:flutter/material.dart';

class AppTheme {
  // Core palettes inspired by the provided mock: deep blacks and white inks.
  static const _blackBg = Color(0xFF000000);
  static const _blackSurface = Color(0xFF0E0E10);
  static const _inkWhite = Color(0xFFFFFFFF);
  static const _inkGrey = Color(0xFF9E9E9E);

  static ColorScheme get _darkColorScheme => const ColorScheme(
    brightness: Brightness.dark,
    primary: _inkWhite,
    onPrimary: _blackBg,
    secondary: _inkGrey,
    onSecondary: _blackBg,
    error: Color(0xFFFF4D4F),
    onError: _blackBg,
    background: _blackBg,
    onBackground: _inkWhite,
    surface: _blackSurface,
    onSurface: _inkWhite,
  );

  // Light is the inverse: white background, black inks.
  static ColorScheme get _lightColorScheme => const ColorScheme(
    brightness: Brightness.light,
    primary: Colors.black,
    onPrimary: Colors.white,
    secondary: Color(0xFF606060),
    onSecondary: Colors.white,
    error: Color(0xFFB00020),
    onError: Colors.white,
    background: Colors.white,
    onBackground: Colors.black,
    surface: Colors.white,
    onSurface: Colors.black,
  );

  static ThemeData get dark {
    final scheme = _darkColorScheme;
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.background,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.background,
        foregroundColor: scheme.onBackground,
        centerTitle: true,
        elevation: 0,
      ),
      textTheme: const TextTheme().apply(
        bodyColor: scheme.onBackground,
        displayColor: scheme.onBackground,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary.withOpacity(0.2),
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(52),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static ThemeData get light {
    final scheme = _lightColorScheme;
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.background,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.background,
        foregroundColor: scheme.onBackground,
        centerTitle: true,
        elevation: 0,
      ),
      textTheme: const TextTheme().apply(
        bodyColor: scheme.onBackground,
        displayColor: scheme.onBackground,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary.withOpacity(0.2),
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(52),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
