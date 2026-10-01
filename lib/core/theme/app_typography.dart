import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography System for UdyogaSethu.
/// Latin primary font: Outfit via Google Fonts.
/// Indic fallback fonts: Noto Sans (Kannada, Telugu, Devanagari, Tamil, Bengali, Oriya).
class AppTypography {
  AppTypography._();

  static const List<String> fontFallbacks = [
    'Noto Sans Kannada',
    'Noto Sans Telugu',
    'Noto Sans Devanagari',
    'Noto Sans Tamil',
    'Noto Sans Bengali',
    'Noto Sans Oriya',
    'Roboto',
    'sans-serif',
  ];

  static TextStyle _baseStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double height = 1.3,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    ).copyWith(
      fontFamilyFallback: fontFallbacks,
    );
  }

  // Display & Title Styles
  static TextStyle displayLarge(Color color) => _baseStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: color,
      );

  static TextStyle displayMedium(Color color) => _baseStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: color,
      );

  static TextStyle titleLarge(Color color) => _baseStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: color,
      );

  static TextStyle titleMedium(Color color) => _baseStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle titleSmall(Color color) => _baseStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // Body Styles
  static TextStyle bodyLarge(Color color) => _baseStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: color,
      );

  static TextStyle bodyMedium(Color color) => _baseStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: color,
      );

  static TextStyle bodySmall(Color color) => _baseStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: color,
      );

  // Button & Label Styles
  static TextStyle button(Color color) => _baseStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle label(Color color) => _baseStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: color,
      );
}
