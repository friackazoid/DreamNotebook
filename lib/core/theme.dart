import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    const seed = Color(0xFF4A6A5A);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F4EF),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
      ),
    );
  }

  static ThemeData dark() {
    const seed = Color(0xFF8FB39B);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF1B1E1D),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
      ),
    );
  }
}
