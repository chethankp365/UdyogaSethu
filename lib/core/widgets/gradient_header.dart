import 'package:flutter/material.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_spacing.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';
import 'package:udyogasethu/core/widgets/user_avatar.dart';

class GradientHeader extends StatelessWidget {
  final String greeting;
  final String userName;
  final String location;
  final String? avatarUrl;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSosTap;
  final Widget? child;

  const GradientHeader({
    super.key,
    required this.greeting,
    required this.userName,
    required this.location,
    this.avatarUrl,
    this.onNotificationTap,
    this.onProfileTap,
    this.onSosTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppSpacing.radiusLg),
          bottomRight: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Bar with Logo, SOS pill, Notification Bell, Avatar
              Row(
                children: [
                  // Logo Text
                  Text(
                    'UDYOGA SETU',
                    style: AppTypography.titleMedium(AppColors.amberOrange).copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // SOS Pill Button
                  if (onSosTap != null) ...[
                    Material(
                      color: AppColors.sosRed,
                      borderRadius: AppSpacing.borderRadiusPill,
                      child: InkWell(
                        onTap: onSosTap,
                        borderRadius: AppSpacing.borderRadiusPill,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.shield_outlined, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'SOS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  // Notification Bell
                  IconButton(
                    onPressed: onNotificationTap,
                    icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                    tooltip: 'Notifications',
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.minTouchTarget,
                      minHeight: AppSpacing.minTouchTarget,
                    ),
                  ),
                  // User Avatar
                  UserAvatar(
                    avatarPath: avatarUrl,
                    name: userName,
                    radius: 18,
                    backgroundColor: Colors.white24,
                    textColor: Colors.white,
                    onTap: onProfileTap,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Greeting line
              Text(
                '$greeting $userName 👋',
                style: AppTypography.titleLarge(Colors.white),
              ),
              const SizedBox(height: AppSpacing.xs),
              // Location Chip
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, color: AppColors.amberOrange, size: 16),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      location,
                      style: AppTypography.bodySmall(Colors.white.withValues(alpha: 0.9)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (child != null) ...[
                const SizedBox(height: AppSpacing.lg),
                child!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
