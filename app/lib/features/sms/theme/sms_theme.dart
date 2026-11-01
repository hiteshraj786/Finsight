import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart' as core;

/// Colours for the SMS / Activity screens. Each getter returns the light or
/// dark value for the theme the app is currently using, so widgets pick up a
/// theme change the next time they build.
class AppColors {
  AppColors._();

  /// Whether the app is drawn dark, resolving "follow system".
  static bool get isDark => switch (core.AppTheme.themeMode.value) {
    ThemeMode.dark => true,
    ThemeMode.light => false,
    ThemeMode.system =>
      PlatformDispatcher.instance.platformBrightness == Brightness.dark,
  };

  static Color _pick(Color light, Color dark) => isDark ? dark : light;

  /// Call at the top of a screen's build so it rebuilds, and re-reads these
  /// colours, when the app switches between light and dark.
  static void rebuildOnThemeChange(BuildContext context) => Theme.of(context);

  // Brand
  static Color get primary =>
      _pick(const Color(0xFF7F3DFF), const Color(0xFFA475FF));
  static Color get primaryDark =>
      _pick(const Color(0xFF660FE6), const Color(0xFF8B5CF6));
  static Color get primaryContainer =>
      _pick(const Color(0xFFEEE5FF), const Color(0xFF2E2347));
  static Color get accentGold =>
      _pick(const Color(0xFFFCAC12), const Color(0xFFFFC04D));
  static Color get accentGoldLight =>
      _pick(const Color(0xFFFEF4E4), const Color(0xFF3A2E14));

  // Surfaces & Backgrounds
  static Color get background =>
      _pick(const Color(0xFFFBF9FE), const Color(0xFF15121B));
  static Color get surface =>
      _pick(const Color(0xFFFFFFFF), const Color(0xFF1F1B26));
  static Color get surfaceContainer =>
      _pick(const Color(0xFFF5F3F8), const Color(0xFF2A2633));

  // Borders & Dividers
  static Color get border =>
      _pick(const Color(0xFFF0ECFC), const Color(0xFF2F2A3A));
  static Color get borderLight =>
      _pick(const Color(0xFFE9E3F8), const Color(0xFF3B3548));

  // Transaction Dynamics
  static Color get debit =>
      _pick(const Color(0xFFFD3C4A), const Color(0xFFFF6B76));
  static Color get debitLight =>
      _pick(const Color(0xFFFFF1F2), const Color(0xFF3A1D22));
  static Color get credit =>
      _pick(const Color(0xFF00A86B), const Color(0xFF3DD69C));
  static Color get creditLight =>
      _pick(const Color(0xFFE6F7F0), const Color(0xFF15302A));

  // Status & Badges
  static Color get pendingText => accentGold;
  static Color get pendingBg => accentGoldLight;
  static Color get needsCheckText => accentGold;
  static Color get needsCheckBg => accentGoldLight;
  static Color get confirmedText => credit;
  static Color get confirmedBg => creditLight;
  static Color get ignoredText =>
      _pick(const Color(0xFF91919F), const Color(0xFF9A98A8));
  static Color get ignoredBg =>
      _pick(const Color(0xFFF1F1F3), const Color(0xFF2A2830));
  static Color get autoTagText => primary;
  static Color get autoTagBg => primaryContainer;

  // Typography Colors
  static Color get textPrimary =>
      _pick(const Color(0xFF1B1B1F), const Color(0xFFF2F0F7));
  static Color get textSecondary =>
      _pick(const Color(0xFF6C6A7B), const Color(0xFFB4B1C2));
  static Color get textMuted =>
      _pick(const Color(0xFF91919F), const Color(0xFF8A8799));

  /// Soft card shadow; none in dark mode, where shadows only muddy surfaces.
  static List<BoxShadow> get cardShadow => isDark
      ? const []
      : const [
          BoxShadow(
            color: Color(0x0F7F3DFF),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ];
}

class AppTheme {
  AppTheme._();

  static const double cardRadius = 20.0;
  static const double pillRadius = 9999.0;

  /// Theme for the SMS / Activity screens in the app's current brightness.
  static ThemeData get current {
    final brightness = AppColors.isDark ? Brightness.dark : Brightness.light;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Inter',
      fontFamilyFallback: const ['sans-serif'],
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.surface,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.primary,
        secondary: AppColors.accentGold,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerHigh: AppColors.surfaceContainer,
        outline: AppColors.borderLight,
        outlineVariant: AppColors.border,
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
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        dragHandleColor: AppColors.borderLight,
      ),
      popupMenuTheme: PopupMenuThemeData(color: AppColors.surface),
      dialogTheme: DialogThemeData(backgroundColor: AppColors.surface),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(color: AppColors.textSecondary),
        hintStyle: TextStyle(color: AppColors.textMuted),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.borderLight),
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
