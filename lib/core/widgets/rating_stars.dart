import 'package:flutter/material.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_spacing.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double iconSize;

  const RatingStars({
    super.key,
    required this.rating,
    this.reviewCount,
    this.iconSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          color: AppColors.amberOrange,
          size: iconSize,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          rating.toStringAsFixed(1),
          style: AppTypography.bodySmall(textColor).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (reviewCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: AppTypography.bodySmall(AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}
