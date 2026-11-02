import 'package:flutter/material.dart';
class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF7F3DFF);
  static const primaryDark = Color(0xFF660FE6);
  static const primaryContainer = Color(0xFFEEE5FF);
  static const accentGold = Color(0xFFFCAC12);
  static const accentGoldLight = Color(0xFFFEF4E4);

  // Surfaces & Backgrounds
  static const background = Color(0xFFFBF9FE);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceContainer = Color(0xFFF5F3F8);

  // Borders & Dividers
  static const border = Color(0xFFF0ECFC);
  static const borderLight = Color(0xFFE9E3F8);

  // Transaction Dynamics
  static const debit = Color(0xFFFD3C4A);
  static const debitLight = Color(0xFFFFF1F2);
  static const credit = Color(0xFF00A86B);
  static const creditLight = Color(0xFFE6F7F0);

  // Status & Badges
  static const pendingText = accentGold;
  static const pendingBg = accentGoldLight;
  static const needsCheckText = accentGold;
  static const needsCheckBg = accentGoldLight;
  static const confirmedText = credit;
  static const confirmedBg = creditLight;
  static const ignoredText = Color(0xFF91919F);
  static const ignoredBg = Color(0xFFF1F1F3);
  static const autoTagText = primary;
  static const autoTagBg = primaryContainer;

  // Typography Colors
  static const textPrimary = Color(0xFF1B1B1F);
  static const textSecondary = Color(0xFF6C6A7B);
  static const textMuted = Color(0xFF91919F);

  static void rebuildOnThemeChange(BuildContext context) => Theme.of(context);
}

class AppTheme {
  AppTheme._();

  static const double cardRadius = 20.0;
  static const double pillRadius = 9999.0;

  static ThemeData get current {
    return lightTheme;
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      fontFamilyFallback: const ['sans-serif'],
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme(
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
      appBarTheme: AppBarTheme(
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
          side: BorderSide(color: AppColors.border, width: 1.5),
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
          side: BorderSide(color: AppColors.border, width: 1.5),
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
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: StadiumBorder(
          side: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
    );
  }
}
