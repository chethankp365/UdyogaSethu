import 'package:flutter/material.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_spacing.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';

enum InfoBannerType { safety, warning, demoMode, emergency }

class InfoBanner extends StatelessWidget {
  final String text;
  final InfoBannerType type;
  final IconData? icon;

  const InfoBanner({
    super.key,
    required this.text,
    this.type = InfoBannerType.safety,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color textClr;
    IconData defaultIcon;

    switch (type) {
      case InfoBannerType.safety:
        bg = const Color(0xFFECFDF5);
        border = AppColors.cardBorderGreen;
        textClr = AppColors.headerGreenDark;
        defaultIcon = Icons.lock_outline_rounded;
        break;
      case InfoBannerType.warning:
        bg = const Color(0xFFFEF3C7);
        border = const Color(0xFFFCD34D);
        textClr = AppColors.darkOrange;
        defaultIcon = Icons.warning_amber_rounded;
        break;
      case InfoBannerType.demoMode:
        bg = const Color(0xFFFFFBEB);
        border = AppColors.amberOrange;
        textClr = const Color(0xFF92400E);
        defaultIcon = Icons.info_outline_rounded;
        break;
      case InfoBannerType.emergency:
        bg = AppColors.dangerBackground;
        border = const Color(0xFFFCA5A5);
        textClr = AppColors.sosRed;
        defaultIcon = Icons.error_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, color: textClr, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall(textClr).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
