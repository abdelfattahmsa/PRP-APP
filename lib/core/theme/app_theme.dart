import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
// DESIGN SYSTEM v2.0 — Life Plan
// ══════════════════════════════════════════════════════════════

/// Spacing system based on 4px grid
class Spacing {
  Spacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double xxl = 40;

  /// Standard page padding (responsive)
  static EdgeInsets pagePadding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = w >= 768 ? 24.0 : 16.0;
    return EdgeInsets.symmetric(horizontal: h, vertical: lg);
  }

  /// Standard card padding
  static const cardPadding = EdgeInsets.all(md);
  static const cardPaddingCompact = EdgeInsets.symmetric(horizontal: md, vertical: sm);
}

/// Responsive breakpoints
class Breakpoints {
  Breakpoints._();
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < tablet;
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= tablet && w < desktop;
  }
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;
  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;
}

/// Central color palette
class AppColors {
  AppColors._();

  // Core backgrounds
  static const bg = Color(0xFF08070C);
  static const surface = Color(0xFF0D0B13);
  static const card = Color(0xFF12101E);
  static const cardHover = Color(0xFF171526);
  static const cardAlt = Color(0xFF171526);
  static const border = Color(0xFF1E1B2C);
  static const borderLight = Color(0xFF2A2640);

  // Brand
  static const gold = Color(0xFFC8A050);
  static const goldLight = Color(0xFFE8C97A);
  static const goldDim = Color(0xFF5A4418);
  static const goldFaint = Color(0xFF2A2010);

  // Category colors
  static const deen = Color(0xFF54C478);
  static const pmp = Color(0xFF6A8EF0);
  static const cfi = Color(0xFF4AAAE0);
  static const health = Color(0xFFD07848);
  static const kyberia = Color(0xFFAA70EE);
  static const work = Color(0xFFC09840);
  static const fasting = Color(0xFFE08840);
  static const commute = Color(0xFF3AB8A8);
  static const rest = Color(0xFF6B6080);

  // Semantic
  static const success = Color(0xFF54C478);
  static const error = Color(0xFFE05050);
  static const warning = Color(0xFFE08840);
  static const info = Color(0xFF6A8EF0);

  // Event types
  static const personal = Color(0xFFE879A0);
  static const islamic = Color(0xFF54C478);
  static const finance = Color(0xFF3AB8A8);
  static const quran = Color(0xFF7ED4A0);
  static const travel = Color(0xFFF0C060);
  static const family = Color(0xFFF06870);
  static const done = Color(0xFF405040);

  // Text
  static const textPrimary = Color(0xFFE0DAF0);
  static const textSecondary = Color(0xFF7A7090);
  static const textMuted = Color(0xFF3A3450);

  static Color categoryColor(String key) {
    return switch (key) {
      'deen' => deen,
      'pmp' => pmp,
      'study' || 'cfi' => cfi,
      'health' => health,
      'kyb' || 'kyberia' => kyberia,
      'work' => work,
      'fast' || 'fasting' => fasting,
      'com' || 'commute' => commute,
      'rest' => rest,
      'personal' => personal,
      'islamic' => islamic,
      'finance' => finance,
      'quran' => quran,
      'travel' => travel,
      'family' => family,
      'done' => done,
      'milestone' => gold,
      _ => textSecondary,
    };
  }

  static Color categoryBg(String key) {
    return categoryColor(key).withValues(alpha: 0.08);
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.kyberia,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.bg,
        onSecondary: AppColors.bg,
        onSurface: AppColors.textPrimary,
      ),
      fontFamily: 'IBMPlexMono',
      textTheme: _textTheme,
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.bg,
          elevation: 0,
          minimumSize: const Size(0, 44), // 44px min tap target
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: const TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: const TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
          minimumSize: const Size(0, 44),
          textStyle: const TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.gold.withValues(alpha: 0.15),
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.gold, size: 22);
          }
          return const IconThemeData(color: AppColors.textSecondary, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.gold,
              fontSize: 10,
              fontFamily: 'IBMPlexMono',
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontFamily: 'IBMPlexMono',
          );
        }),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        height: 64,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textSecondary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardAlt,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.card,
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 10,
          color: AppColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.gold : AppColors.textSecondary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.gold.withValues(alpha: 0.3)
                : AppColors.border),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.gold,
        inactiveTrackColor: AppColors.border,
        thumbColor: AppColors.gold,
        overlayColor: Color(0x22C8A050),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.cardAlt,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        textStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          fontFamily: 'IBMPlexMono',
        ),
      ),
    );
  }

  static const _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'PlayfairDisplay',
      fontSize: 40,
      fontWeight: FontWeight.w900,
      color: AppColors.textPrimary,
      letterSpacing: -1,
    ),
    displayMedium: TextStyle(
      fontFamily: 'PlayfairDisplay',
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'PlayfairDisplay',
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'PlayfairDisplay',
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'PlayfairDisplay',
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    titleLarge: TextStyle(
      fontFamily: 'PlayfairDisplay',
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontFamily: 'IBMPlexMono',
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleSmall: TextStyle(
      fontFamily: 'IBMPlexMono',
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      letterSpacing: 0.5,
    ),
    bodyLarge: TextStyle(
      fontSize: 14,
      color: AppColors.textPrimary,
      height: 1.6,
    ),
    bodyMedium: TextStyle(
      fontSize: 12,
      color: AppColors.textPrimary,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 11,
      color: AppColors.textSecondary,
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontFamily: 'IBMPlexMono',
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    labelMedium: TextStyle(
      fontFamily: 'IBMPlexMono',
      fontSize: 10,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.8,
    ),
    labelSmall: TextStyle(
      fontFamily: 'IBMPlexMono',
      fontSize: 9,
      fontWeight: FontWeight.w400,
      letterSpacing: 1.5,
      color: AppColors.textSecondary,
    ),
  );
}
