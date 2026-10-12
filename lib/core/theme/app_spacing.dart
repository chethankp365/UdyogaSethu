import 'package:flutter/material.dart';

/// Spacing, Radius, and Elevation Tokens based on 8pt grid.
class AppSpacing {
  AppSpacing._();

  // Spacing Scale
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;
  static const double huge = 48.0;

  // Touch Target & Layout Limits
  static const double minTouchTarget = 48.0;
  static const double maxContentWidth = 480.0;

  /// Standard bottom padding for scrollable views sitting above or under a Floating Action Button
  /// or bottom navigation bar, ensuring the last item can scroll fully clear without being obscured.
  static const double fabBottomPadding = 128.0;

  /// Shared EdgeInsets helper for list views that sit under a floating action button
  static const EdgeInsets fabListPadding = EdgeInsets.fromLTRB(16.0, 16.0, 16.0, fabBottomPadding);

  /// Shared bottom spacer for scroll views that sit under a floating action button
  static const Widget fabBottomSpacer = SizedBox(height: fabBottomPadding);

  // Border Radius Tokens
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusButton = 14.0;
  static const double radiusCard = 16.0;
  static const double radiusLg = 20.0;
  static const double radiusPill = 999.0;

  // BorderRadius Objects
  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusButton = BorderRadius.circular(radiusButton);
  static final BorderRadius borderRadiusCard = BorderRadius.circular(radiusCard);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusPill = BorderRadius.circular(radiusPill);

  // Soft Elevation Shadows
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0F0F172A),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x1A0F172A),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x260F172A),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
}
