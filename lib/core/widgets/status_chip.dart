import 'package:flutter/material.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_spacing.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';

enum StatusChipStyle { success, warning, danger, info, neutral }

class StatusChip extends StatelessWidget {
  final String label;
  final StatusChipStyle style;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const StatusChip({
    super.key,
    required this.label,
    this.style = StatusChipStyle.neutral,
    this.icon,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color text;
    Color border;

    if (isSelected) {
      bg = isDark ? AppColors.emerald : AppColors.primaryTeal;
      text = Colors.white;
      border = bg;
    } else {
      switch (style) {
        case StatusChipStyle.success:
          bg = AppColors.paleMint;
          text = AppColors.headerGreenDark;
          border = AppColors.cardBorderGreen;
          break;
        case StatusChipStyle.warning:
          bg = const Color(0xFFFEF3C7);
          text = AppColors.darkOrange;
          border = const Color(0xFFFCD34D);
          break;
        case StatusChipStyle.danger:
          bg = AppColors.dangerBackground;
          text = AppColors.sosRed;
          border = const Color(0xFFFCA5A5);
          break;
        case StatusChipStyle.info:
          bg = const Color(0xFFEFF6FF);
          text = AppColors.info;
          border = const Color(0xFFBFDBFE);
          break;
        case StatusChipStyle.neutral:
          bg = isDark ? AppColors.navyCardSecondary : const Color(0xFFF1F5F9);
          text = isDark ? AppColors.textLight : AppColors.textDark;
          border = isDark ? AppColors.navyBorder : AppColors.borderLight;
          break;
      }
    }

    final chipWidget = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppSpacing.borderRadiusPill,
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: text),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.bodySmall(text).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusPill,
        child: chipWidget,
      );
    }

    return chipWidget;
  }
}
