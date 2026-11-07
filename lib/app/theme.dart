import 'package:flutter/material.dart';

/// Design tokens from docs/design_system/DESIGN_SYSTEM.md.
abstract final class FamilyCircleColors {
  static const background = Color(0xFF0E120F);
  static const surface = Color(0xFF171D19);
  static const surfaceElevated = Color(0xFF212A23);
  static const surfaceHighest = Color(0xFF2A342B);
  static const card = Color(0xFF1B221D);
  static const primary = Color(0xFF65D36E);
  static const primaryDark = Color(0xFF215C35);
  static const primaryContainer = Color(0xFF2B4A33);
  static const onPrimaryContainer = Color(0xFFB9F3C0);
  static const tertiary = Color(0xFFE8A04C);
  static const text = Color(0xFFF5F7F2);
  static const muted = Color(0xFFB6C2B9);
  static const warning = Color(0xFFEAB65F);
  static const error = Color(0xFFFF746C);
  static const outline = Color(0xFF38443C);

  // Light-mode variant per design system contract.
  static const lightBackground = Color(0xFFF5F7F3);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceElevated = Color(0xFFEFF2EC);
  static const lightSurfaceHighest = Color(0xFFE3E8E0);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF1A1F1B);
  static const lightMuted = Color(0xFF5A675E);
  static const lightOutline = Color(0xFFC9D2C9);
  static const lightPrimary = Color(0xFF215C35);
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
          onPrimary: const Color(0xFF0E120F),
          primaryContainer: FamilyCircleColors.primaryContainer,
          onPrimaryContainer: FamilyCircleColors.onPrimaryContainer,
          secondary: FamilyCircleColors.tertiary,
          tertiary: FamilyCircleColors.tertiary,
          surface: FamilyCircleColors.surface,
          surfaceDim: FamilyCircleColors.background,
          surfaceBright: FamilyCircleColors.surfaceHighest,
          surfaceContainerLowest: FamilyCircleColors.background,
          surfaceContainerLow: FamilyCircleColors.surface,
          surfaceContainer: FamilyCircleColors.card,
          surfaceContainerHigh: FamilyCircleColors.surfaceElevated,
          surfaceContainerHighest: FamilyCircleColors.surfaceHighest,
          outline: FamilyCircleColors.outline,
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
          primary: FamilyCircleColors.lightPrimary,
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFD6EFD8),
          onPrimaryContainer: const Color(0xFF0F3A1C),
          secondary: FamilyCircleColors.tertiary,
          tertiary: FamilyCircleColors.tertiary,
          surface: FamilyCircleColors.lightSurface,
          surfaceDim: FamilyCircleColors.lightSurfaceHighest,
          surfaceBright: FamilyCircleColors.lightSurface,
          surfaceContainerLowest: FamilyCircleColors.lightBackground,
          surfaceContainerLow: FamilyCircleColors.lightBackground,
          surfaceContainer: FamilyCircleColors.lightSurface,
          surfaceContainerHigh: FamilyCircleColors.lightSurfaceElevated,
          surfaceContainerHighest: FamilyCircleColors.lightSurfaceHighest,
          outline: FamilyCircleColors.lightOutline,
          outlineVariant: FamilyCircleColors.lightOutline,
          onSurfaceVariant: FamilyCircleColors.lightMuted,
        );
    return _base(scheme, FamilyCircleColors.lightBackground);
  }

  static ThemeData _base(ColorScheme scheme, Color scaffold) {
    final dark = scheme.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      visualDensity: VisualDensity.standard,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme().apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
        actionsIconTheme: IconThemeData(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: dark ? FamilyCircleColors.card : scheme.surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primary.withValues(alpha: 0.18),
        disabledColor: scheme.surfaceContainerHigh.withValues(alpha: 0.4),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: TextStyle(color: scheme.onSurface, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark
            ? FamilyCircleColors.surfaceElevated
            : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        focusElevation: 3,
        hoverElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 10,
        iconColor: Colors.grey,
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 3,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: scheme.primary.withValues(alpha: 0.22),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerHeight: 0,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primary.withValues(alpha: 0.15),
        circularTrackColor: scheme.primary.withValues(alpha: 0.15),
      ),
    );
  }
}
