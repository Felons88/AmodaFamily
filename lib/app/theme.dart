import 'package:flutter/material.dart';

/// Design tokens from docs/design_system/DESIGN_SYSTEM.md.
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

  // Light-mode variant per design system contract.
  static const lightBackground = Color(0xFFF6F7F3);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF1A1F1B);
  static const lightMuted = Color(0xFF5A675E);
}

abstract final class FamilyCircleTheme {
  static ThemeData get dark {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: FamilyCircleColors.primary,
          brightness: Brightness.dark,
          surface: FamilyCircleColors.surface,
          error: FamilyCircleColors.error,
        ).copyWith(
          primary: FamilyCircleColors.primary,
          onPrimary: FamilyCircleColors.background,
          surfaceContainerHighest: FamilyCircleColors.surfaceElevated,
          outlineVariant: FamilyCircleColors.outline,
          onSurfaceVariant: FamilyCircleColors.muted,
        );
    return _base(scheme, FamilyCircleColors.background);
  }

  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: FamilyCircleColors.primaryDark,
          brightness: Brightness.light,
          surface: FamilyCircleColors.lightSurface,
          error: const Color(0xFFB3261E),
        ).copyWith(
          primary: FamilyCircleColors.primaryDark,
          onSurfaceVariant: FamilyCircleColors.lightMuted,
        );
    return _base(scheme, FamilyCircleColors.lightBackground);
  }

  static ThemeData _base(ColorScheme scheme, Color scaffold) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.brightness == Brightness.dark
            ? FamilyCircleColors.surfaceElevated
            : scheme.surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.brightness == Brightness.dark
            ? FamilyCircleColors.surfaceElevated
            : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 8,
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.2),
      ),
      tabBarTheme: const TabBarThemeData(dividerHeight: 0),
      bottomSheetTheme: const BottomSheetThemeData(showDragHandle: true),
    );
  }
}
