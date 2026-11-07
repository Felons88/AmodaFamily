import 'package:flutter/material.dart';

/// Design tokens for the Kinplora warm food-app palette.
/// Cream surfaces, deep forest green primary, terracotta/amber accents,
/// sage secondary — light theme feels like a modern pantry app, dark theme
/// is a warm charcoal rather than cold black-green.
abstract final class FamilyCircleColors {
  // ---- Dark theme (warm charcoal) ----
  static const background = Color(0xFF1C1917);
  static const surface = Color(0xFF26221E);
  static const surfaceElevated = Color(0xFF2E2924);
  static const surfaceHighest = Color(0xFF38322C);
  static const card = Color(0xFF23201B);
  static const primary = Color(0xFF9CCB8E);
  static const primaryDark = Color(0xFF2F6B3F);
  static const primaryContainer = Color(0xFF2E4A34);
  static const onPrimaryContainer = Color(0xFFC9E8CE);
  static const tertiary = Color(0xFFE0815A);
  static const sage = Color(0xFF9DB5A0);
  static const text = Color(0xFFFAF4EC);
  static const muted = Color(0xFFC4BCAE);
  static const warning = Color(0xFFE8B45C);
  static const error = Color(0xFFE86A5A);
  static const outline = Color(0xFF4A4238);

  // ---- Freshness tokens (dark) ----
  static const fresh = Color(0xFF7FC98B);
  static const expiringSoon = Color(0xFFE8B45C);
  static const expired = Color(0xFFE86A5A);

  // ---- Light theme (warm cream) ----
  static const lightBackground = Color(0xFFFAF4EA);
  static const lightSurface = Color(0xFFFFFDF8);
  static const lightSurfaceElevated = Color(0xFFF3EAD9);
  static const lightSurfaceHighest = Color(0xFFEBDDC4);
  static const lightCard = Color(0xFFFFFDF8);
  static const lightText = Color(0xFF2B241B);
  static const lightMuted = Color(0xFF7C7263);
  static const lightOutline = Color(0xFFE3D6C2);
  static const lightPrimary = Color(0xFF2F6B3F);
  static const lightPrimaryContainer = Color(0xFFD9EBD8);
  static const lightOnPrimaryContainer = Color(0xFF14301C);
  static const lightTertiary = Color(0xFFB85C38);
  static const lightSage = Color(0xFF6E8A66);

  // ---- Freshness tokens (light) ----
  static const lightFresh = Color(0xFF3E9B5F);
  static const lightExpiringSoon = Color(0xFFD9822B);
  static const lightExpired = Color(0xFFD94F3C);
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
          onPrimary: const Color(0xFF1C1917),
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
          seedColor: FamilyCircleColors.lightPrimary,
          brightness: Brightness.light,
          surface: FamilyCircleColors.lightSurface,
          error: const Color(0xFFB3261E),
        ).copyWith(
          primary: FamilyCircleColors.lightPrimary,
          onPrimary: Colors.white,
          primaryContainer: FamilyCircleColors.lightPrimaryContainer,
          onPrimaryContainer: FamilyCircleColors.lightOnPrimaryContainer,
          secondary: FamilyCircleColors.lightTertiary,
          tertiary: FamilyCircleColors.lightTertiary,
          surface: FamilyCircleColors.lightSurface,
          surfaceDim: FamilyCircleColors.lightSurfaceHighest,
          surfaceBright: FamilyCircleColors.lightSurface,
          surfaceContainerLowest: FamilyCircleColors.lightBackground,
          surfaceContainerLow: FamilyCircleColors.lightBackground,
          surfaceContainer: FamilyCircleColors.lightCard,
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
      textTheme: TextTheme(
        displaySmall: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineMedium: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        headlineSmall: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        titleSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(fontSize: 16, height: 1.45),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.4),
        bodySmall: const TextStyle(fontSize: 12.5, height: 1.35),
        labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        labelSmall: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 21,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
        actionsIconTheme: IconThemeData(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: dark ? FamilyCircleColors.card : scheme.surface,
        elevation: dark ? 0.5 : 1,
        shadowColor: dark
            ? Colors.black.withValues(alpha: 0.35)
            : const Color(0xFF8A7A5E).withValues(alpha: 0.18),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primary.withValues(alpha: 0.16),
        disabledColor: scheme.surfaceContainerHigh.withValues(alpha: 0.4),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        shape: const StadiumBorder(),
        labelStyle: TextStyle(color: scheme.onSurface, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark
            ? FamilyCircleColors.surfaceElevated
            : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
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
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
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
