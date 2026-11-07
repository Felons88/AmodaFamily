import 'package:flutter/material.dart';

abstract final class FamilyCircleColors {
  static const background = Color(0xFF101411);
  static const surface = Color(0xFF1B211D);
  static const surfaceElevated = Color(0xFF252D27);
  static const primary = Color(0xFF65D36E);
  static const primaryDark = Color(0xFF215C35);
  static const text = Color(0xFFF5F7F2);
  static const muted = Color(0xFFB6C2B9);
  static const warning = Color(0xFFEAB65F);
  static const error = Color(0xFFFF746C);
  static const outline = Color(0xFF38443C);
}

abstract final class FamilyCircleTheme {
  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: FamilyCircleColors.primary,
      brightness: Brightness.dark,
      surface: FamilyCircleColors.surface,
      error: FamilyCircleColors.error,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: FamilyCircleColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: FamilyCircleColors.surface,
      ),
    );
  }

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: FamilyCircleColors.primaryDark,
      brightness: Brightness.light,
    );
    return ThemeData(useMaterial3: true, colorScheme: scheme);
  }
}
