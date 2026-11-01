import 'package:flutter/material.dart';

/// FinSight App Color Palette
/// Primary: #7F3DFF (Vibrant Purple)
class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF7F3DFF);
  static const Color primaryLight = Color(0xFFEEE5FF);
  static const Color primaryDark = Color(0xFF5B1FCC);

  // Secondary
  static const Color secondary = Color(0xFFFC8B3D);

  // Backgrounds
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF6F6F6);
  static const Color scaffoldBackground = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF212325);
  static const Color textSecondary = Color(0xFF91919F);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFFC6C6C6);

  // Status
  static const Color success = Color(0xFF00A86B);
  static const Color error = Color(0xFFFD3C4A);
  static const Color warning = Color(0xFFFCAC12);

  // Borders & Dividers
  static const Color border = Color(0xFFF1F1FA);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color inputBorder = Color(0xFFF1F1FA);

  // Onboarding
  static const Color onboardingDotActive = Color(0xFF7F3DFF);
  static const Color onboardingDotInactive = Color(0xFFD3BDFF);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF8B47FF), Color(0xFF7F3DFF)],
  );

  // PIN Screen
  static const Color pinBackground = Color(0xFF7F3DFF);

  // Account Card
  static const Color accountCardPurple = Color(0xFF7F3DFF);
}
