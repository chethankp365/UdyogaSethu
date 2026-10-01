import 'package:flutter/material.dart';

/// UdyogaSethu Color Palette & Design Tokens
/// Sampled from official reference designs (Built Project & Prototype slides).
class AppColors {
  AppColors._();

  // Primary Brand Greens
  static const Color headerGreenDark = Color(0xFF0D6548);
  static const Color headerGreenGradientEnd = Color(0xFF064E3B);
  static const Color primaryTeal = Color(0xFF00875A);
  static const Color emerald = Color(0xFF10B981);
  static const Color paleMint = Color(0xFFE6F4EA);
  static const Color mintBackground = Color(0xFFF0FDF4);
  static const Color cardBorderGreen = Color(0xFFA7F3D0);

  // Accents & Actions
  static const Color amberOrange = Color(0xFFFF9900);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color darkOrange = Color(0xFFE65100);

  // Safety & Emergency
  static const Color sosRed = Color(0xFFDC2626);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color dangerBackground = Color(0xFFFEF2F2);

  // Navy Dark Panel Theme Tokens
  static const Color navyBackground = Color(0xFF0B132B);
  static const Color navyCard = Color(0xFF1E293B);
  static const Color navyCardSecondary = Color(0xFF132238);
  static const Color navyBorder = Color(0xFF334155);

  // Light Theme Neutrals
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color dividerLight = Color(0xFFCBD5E1);

  // Semantic Feedback Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Shimmer colors
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);
  static const Color shimmerBaseDark = Color(0xFF1E293B);
  static const Color shimmerHighlightDark = Color(0xFF334155);

  // Primary Header Gradient
  static const LinearGradient headerGradient = LinearGradient(
    colors: [headerGreenDark, headerGreenGradientEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
