import 'package:flutter/material.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_spacing.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';
import 'package:udyogasethu/core/widgets/app_button.dart';
import 'package:udyogasethu/core/widgets/app_card.dart';
import 'package:udyogasethu/core/widgets/rating_stars.dart';

class JobCard extends StatelessWidget {
  final String title;
  final String employerName;
  final bool isEmployerVerified;
  final double rating;
  final int reviewCount;
  final String distanceText;
  final String payRateText;
  final String? imageUrl;
  final String? isHotJobBadge;
  final VoidCallback? onApply;
  final VoidCallback? onTap;

  const JobCard({
    super.key,
    required this.title,
    required this.employerName,
    required this.rating,
    required this.reviewCount,
    required this.distanceText,
    required this.payRateText,
    this.isEmployerVerified = true,
    this.imageUrl,
    this.isHotJobBadge,
    this.onApply,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Job Thumbnail Avatar
          ClipRRect(
            borderRadius: AppSpacing.borderRadiusMd,
            child: Container(
              width: 56,
              height: 56,
              color: isDark ? AppColors.navyCardSecondary : AppColors.paleMint,
              child: imageUrl != null
                  ? Image.network(imageUrl!, fit: BoxFit.cover)
                  : const Icon(
                      Icons.engineering_outlined,
                      color: AppColors.primaryTeal,
                      size: 30,
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Job Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isHotJobBadge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.darkOrange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '🔥 $isHotJobBadge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  title,
                  style: AppTypography.titleMedium(textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        employerName,
                        style: AppTypography.bodySmall(AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isEmployerVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.primaryTeal,
                        size: 14,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    RatingStars(rating: rating, reviewCount: reviewCount),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '• $distanceText',
                      style: AppTypography.bodySmall(AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Pay & Apply Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.paleMint,
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Text(
                  payRateText,
                  style: AppTypography.label(AppColors.headerGreenDark),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Apply',
                onPressed: onApply,
                fullWidth: false,
                variant: AppButtonVariant.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
