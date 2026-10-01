import 'package:flutter/material.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_spacing.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';

class SearchBarWithMic extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onMicTap;
  final VoidCallback? onFilterTap;

  const SearchBarWithMic({
    super.key,
    this.hintText = 'Search jobs, services...',
    this.controller,
    this.onChanged,
    this.onMicTap,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.navyCard : Colors.white;
    final borderColor = isDark ? AppColors.navyBorder : AppColors.borderLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppSpacing.borderRadiusPill,
        border: Border.all(color: borderColor),
        boxShadow: isDark ? null : AppSpacing.shadowSm,
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.md),
          const Icon(Icons.search, color: AppColors.textMuted, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTypography.bodyMedium(textColor),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTypography.bodyMedium(AppColors.textMuted),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (onFilterTap != null)
            IconButton(
              onPressed: onFilterTap,
              icon: const Icon(Icons.tune, color: AppColors.textMuted, size: 20),
              tooltip: 'Filter',
              constraints: const BoxConstraints(
                minWidth: AppSpacing.minTouchTarget,
                minHeight: AppSpacing.minTouchTarget,
              ),
            ),
          IconButton(
            onPressed: onMicTap,
            icon: const Icon(Icons.mic, color: AppColors.primaryTeal, size: 22),
            tooltip: 'Voice Search',
            constraints: const BoxConstraints(
              minWidth: AppSpacing.minTouchTarget,
              minHeight: AppSpacing.minTouchTarget,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
