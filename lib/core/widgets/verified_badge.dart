import 'package:flutter/material.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_spacing.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';

enum VerifiedBadgeType { worker, farmer, customer }

class VerifiedBadge extends StatelessWidget {
  final VerifiedBadgeType type;
  final String? customText;

  const VerifiedBadge({
    super.key,
    this.type = VerifiedBadgeType.worker,
    this.customText,
  });

  @override
  Widget build(BuildContext context) {
    String text;
    switch (type) {
      case VerifiedBadgeType.worker:
        text = customText ?? 'UDYOGASETHU VERIFIED ✓';
        break;
      case VerifiedBadgeType.farmer:
        text = customText ?? 'VERIFIED FARMER ✓';
        break;
      case VerifiedBadgeType.customer:
        text = customText ?? 'VERIFIED CUSTOMER ✓';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal.withValues(alpha: 0.15),
        borderRadius: AppSpacing.borderRadiusPill,
        border: Border.all(color: AppColors.primaryTeal, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified,
            color: AppColors.primaryTeal,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTypography.label(AppColors.primaryTeal).copyWith(
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
