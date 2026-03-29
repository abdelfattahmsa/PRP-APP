import 'package:flutter/material.dart';

/// Central color palette — matches the web app aesthetic
class AppColors {
  AppColors._();

  // Core backgrounds
  static const bg = Color(0xFF09080D);
  static const surface = Color(0xFF0E0C14);
  static const card = Color(0xFF131120);
  static const cardAlt = Color(0xFF171526);
  static const border = Color(0xFF1E1B2C);

  // Brand
  static const gold = Color(0xFFC8A050);
  static const goldLight = Color(0xFFE8C97A);
  static const goldDim = Color(0xFF5A4418);

  // Category colors
  static const deen = Color(0xFF54C478);
  static const pmp = Color(0xFF6A8EF0);
  static const cfi = Color(0xFF4AAAE0);
  static const health = Color(0xFFD07848);
  static const kyberia = Color(0xFFAA70EE);
  static const work = Color(0xFFC09840);
  static const fasting = Color(0xFFE08840);
  static const commute = Color(0xFF3AB8A8);

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
  static const textPrimary = Color(0xFFDDD6F0);
  static const textSecondary = Color(0xFF7A7090);
  static const textMuted = Color(0xFF2E2840);

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
    return categoryColor(key).withOpacity(0.08);
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
      cardTheme: CardTheme(
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
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.bg,
          elevation: 0,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
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
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        selectedIconTheme: IconThemeData(color: AppColors.gold),
        unselectedIconTheme: IconThemeData(color: AppColors.textSecondary),
        selectedLabelTextStyle: TextStyle(
          color: AppColors.gold,
          fontSize: 10,
          fontFamily: 'IBMPlexMono',
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontFamily: 'IBMPlexMono',
        ),
        indicatorColor: Color(0x22C8A050),
        labelType: NavigationRailLabelType.all,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.gold.withOpacity(0.15),
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
        height: 70,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
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
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.cardAlt,
        contentTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        behavior: SnackBarBehavior.floating,
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
                ? AppColors.gold.withOpacity(0.3)
                : AppColors.border),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.gold,
        inactiveTrackColor: AppColors.border,
        thumbColor: AppColors.gold,
        overlayColor: Color(0x22C8A050),
      ),
    );
  }

  static const _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'PlayfairDisplay',
      fontSize: 48,
      fontWeight: FontWeight.w900,
      color: AppColors.textPrimary,
      letterSpacing: -1,
    ),
    displayMedium: TextStyle(
      fontFamily: 'PlayfairDisplay',
      fontSize: 36,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'PlayfairDisplay',
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'PlayfairDisplay',
      fontSize: 22,
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
      fontSize: 15,
      color: AppColors.textPrimary,
      height: 1.6,
    ),
    bodyMedium: TextStyle(
      fontSize: 13,
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
      letterSpacing: 1.0,
      color: AppColors.textSecondary,
    ),
  );
}
