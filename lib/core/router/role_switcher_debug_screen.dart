import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_spacing.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';
import 'package:udyogasethu/core/widgets/app_button.dart';
import 'package:udyogasethu/core/widgets/app_card.dart';
import 'package:udyogasethu/core/widgets/responsive_container.dart';
import 'package:udyogasethu/core/widgets/status_chip.dart';
import 'package:udyogasethu/features/farmer/data/farmer_home_repository.dart';

class RoleSwitcherDebugScreen extends ConsumerWidget {
  const RoleSwitcherDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionData = ref.watch(appSessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dev Role & Shell Switcher'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ResponsiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Current Active State Info Card
              AppCard(
                child: Column(
                  children: [
                    Text(
                      'ACTIVE APP SESSION STATE',
                      style: AppTypography.label(AppColors.primaryTeal),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        StatusChip(
                          label: 'Status: ${sessionData.status.name}',
                          style: StatusChipStyle.info,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        StatusChip(
                          label: 'Role: ${sessionData.activeRole.name}',
                          style: StatusChipStyle.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Role Shell Jumper Section
              Text(
                '1. Select Role Shell to Open',
                style: AppTypography.titleMedium(textColor),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  _RoleButton(
                    title: 'Job Seeker Shell',
                    subtitle: 'Home, Jobs, Mic, Chat, Profile',
                    icon: Icons.work_outline,
                    color: AppColors.primaryTeal,
                    isSelected: sessionData.activeRole == UserRole.seeker,
                    onTap: () {
                      ref.read(appSessionProvider.notifier).updateSession(
                            status: AuthSessionStatus.ready,
                            role: UserRole.seeker,
                          );
                      context.go(AppRoutes.seekerHome);
                    },
                  ),
                  _RoleButton(
                    title: 'Job Provider Shell',
                    subtitle: 'Home, Workers, Mic, Chat, Profile',
                    icon: Icons.business_center_outlined,
                    color: AppColors.darkOrange,
                    isSelected: sessionData.activeRole == UserRole.provider,
                    onTap: () {
                      ref.read(appSessionProvider.notifier).updateSession(
                            status: AuthSessionStatus.ready,
                            role: UserRole.provider,
                          );
                      context.go(AppRoutes.providerHome);
                    },
                  ),
                  _RoleButton(
                    title: 'Farmer Marketplace Shell',
                    subtitle: 'Home, Market, Mic, Chat, Profile',
                    icon: Icons.agriculture_outlined,
                    color: AppColors.emerald,
                    isSelected: sessionData.activeRole == UserRole.farmer,
                    onTap: () {
                      ref.read(appSessionProvider.notifier).updateSession(
                            status: AuthSessionStatus.ready,
                            role: UserRole.farmer,
                          );
                      context.go(AppRoutes.farmerHome);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Session Lifecycle Status Selector
              Text(
                '2. Override Session Lifecycle Status',
                style: AppTypography.titleMedium(textColor),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Column(
                  children: AuthSessionStatus.values.map((status) {
                    final isSelected = sessionData.status == status;
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? AppColors.primaryTeal : AppColors.textMuted,
                        ),
                        title: Text(
                          status.name.toUpperCase(),
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.primaryTeal : textColor,
                          ),
                        ),
                        subtitle: Text(_getStatusDescription(status)),
                        onTap: () {
                          ref.read(appSessionProvider.notifier).setSessionStatus(status);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Quick Actions
              AppButton(
                label: '🎨 Open Design System Gallery (/dev/gallery)',
                onPressed: () => context.push(AppRoutes.devGallery),
                variant: AppButtonVariant.secondary,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: '⚡ Open Connection Debug (/dev/connection)',
                onPressed: () => context.push(AppRoutes.devConnection),
                variant: AppButtonVariant.secondary,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: '🔍 Edge Function Health & Mandi Sync (/dev/edge-health)',
                onPressed: () => context.push(AppRoutes.devEdgeHealth),
                variant: AppButtonVariant.secondary,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: '⏱ Lifecycle Test Panel (/dev/lifecycle)',
                onPressed: () => context.push(AppRoutes.devLifecycle),
                variant: AppButtonVariant.secondary,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Farmer Home Testing Controls
              Text(
                '3. Farmer Simulation Controls (P6.1)',
                style: AppTypography.titleMedium(textColor),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.thunderstorm_rounded, color: Color(0xFF0284C7)),
                  title: const Text(
                    'Simulate Rain Forecast',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Triggers moderate rain advisory & "Book Harvest Helpers" advice card.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: ref.watch(simulatedRainForecastProvider),
                  onChanged: (val) {
                    ref.read(simulatedRainForecastProvider.notifier).setSimulated(val);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusDescription(AuthSessionStatus status) {
    switch (status) {
      case AuthSessionStatus.booting:
        return 'Initial app boot splash screen.';
      case AuthSessionStatus.needsOnboarding:
        return 'Language & intro onboarding flow.';
      case AuthSessionStatus.signedOut:
        return 'Signed out, requires OTP / Google login.';
      case AuthSessionStatus.needsRole:
        return 'Authenticated but needs role selection from role tree.';
      case AuthSessionStatus.needsProfile:
        return 'Authenticated but needs role wizard setup.';
      case AuthSessionStatus.ready:
        return 'Fully ready, active role shell unlocked.';
      case AuthSessionStatus.suspended:
        return 'Account suspended, shows appeal page.';
      case AuthSessionStatus.roleConflict:
        return 'Role conflict: account registered as a different role.';
    }
  }
}

class _RoleButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AppCard(
        onTap: onTap,
        borderColor: isSelected ? color : null,
        backgroundColor: isSelected ? color.withValues(alpha: 0.1) : null,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
              color: isSelected ? color : AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
