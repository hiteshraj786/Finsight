import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF7F3DFF);
  static const Color primaryDark = Color(0xFF660FE6);
  static const Color primaryContainer = Color(0xFFEEE5FF);
  static const Color accentGold = Color(0xFFFCAC12);
  static const Color accentGoldLight = Color(0xFFFEF4E4);

  // Surfaces & Backgrounds
  static const Color background = Color(0xFFFBF9FE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFF5F3F8);

  // Borders & Dividers
  static const Color border = Color(0xFFF0ECFC);
  static const Color borderLight = Color(0xFFE9E3F8);

  // Transaction Dynamics
  static const Color debit = Color(0xFFFD3C4A);
  static const Color debitLight = Color(0xFFFFF1F2);
  static const Color credit = Color(0xFF00A86B);
  static const Color creditLight = Color(0xFFE6F7F0);

  // Status & Badges
  static const Color pendingText = Color(0xFFFCAC12);
  static const Color pendingBg = Color(0xFFFEF4E4);
  static const Color needsCheckText = Color(0xFFFCAC12);
  static const Color needsCheckBg = Color(0xFFFEF4E4);
  static const Color confirmedText = Color(0xFF00A86B);
  static const Color confirmedBg = Color(0xFFE6F7F0);
  static const Color ignoredText = Color(0xFF91919F);
  static const Color ignoredBg = Color(0xFFF1F1F3);
  static const Color autoTagText = Color(0xFF7F3DFF);
  static const Color autoTagBg = Color(0xFFEEE5FF);

  // Typography Colors
  static const Color textPrimary = Color(0xFF1B1B1F);
  static const Color textSecondary = Color(0xFF6C6A7B);
  static const Color textMuted = Color(0xFF91919F);
}

class AppTheme {
  AppTheme._();

  static const double cardRadius = 20.0;
  static const double pillRadius = 9999.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      fontFamilyFallback: const ['sans-serif'],
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.primary,
        secondary: AppColors.accentGold,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.debit,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: AppColors.border, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryContainer,
        disabledColor: AppColors.ignoredBg,
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: const StadiumBorder(
          side: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
    );
  }
}
