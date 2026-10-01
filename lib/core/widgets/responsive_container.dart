import 'package:flutter/material.dart';
import 'package:udyogasethu/core/theme/app_spacing.dart';

/// Wraps content to constrain maximum width on larger screens (tablet/desktop)
/// to maintain mobile-first visual fidelity while staying centered.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Alignment alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = AppSpacing.maxContentWidth,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
