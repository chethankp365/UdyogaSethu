import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';
import 'package:udyogasethu/core/widgets/app_card.dart';

/// Debug screen displaying all bundled image and SVG assets for verification.
class DevAssetsScreen extends StatelessWidget {
  const DevAssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Gallery (/dev/assets)'),
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Brand Logos', style: AppTypography.titleLarge(AppColors.textDark)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AssetCard(
                    title: 'logo.png',
                    subtitle: 'Main Splash & Auth Logo',
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AssetCard(
                    title: 'logo_small.png',
                    subtitle: 'App Bar Logo',
                    child: Image.asset(
                      'assets/images/logo_small.png',
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Hero & Splash Vector Artwork', style: AppTypography.titleLarge(AppColors.textDark)),
            const SizedBox(height: 12),
            _AssetCard(
              title: 'splash_city_bridge.svg',
              subtitle: 'Splash Screen City-Village Bridge',
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                ),
                child: SvgPicture.asset(
                  'assets/images/splash_city_bridge.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _AssetCard(
              title: 'intro_hero.svg',
              subtitle: 'Intro Screen Hero Illustration',
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                ),
                child: SvgPicture.asset(
                  'assets/images/intro_hero.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Intro Feature Icons', style: AppTypography.titleLarge(AppColors.textDark)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AssetCard(
                    title: 'feature_find_jobs.svg',
                    subtitle: 'Find Jobs Near You',
                    child: SizedBox(
                      height: 80,
                      child: SvgPicture.asset('assets/images/feature_find_jobs.svg'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AssetCard(
                    title: 'feature_secure_payments.svg',
                    subtitle: 'Secure Payments',
                    child: SizedBox(
                      height: 80,
                      child: SvgPicture.asset('assets/images/feature_secure_payments.svg'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AssetCard(
                    title: 'feature_ai_voice.svg',
                    subtitle: 'AI Voice Assistant',
                    child: SizedBox(
                      height: 80,
                      child: SvgPicture.asset('assets/images/feature_ai_voice.svg'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Role Selector Card Artwork', style: AppTypography.titleLarge(AppColors.textDark)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AssetCard(
                    title: 'role_worker.svg',
                    subtitle: 'Job Seeker Role',
                    child: SizedBox(
                      height: 100,
                      child: SvgPicture.asset('assets/images/role_worker.svg'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AssetCard(
                    title: 'role_farmer.svg',
                    subtitle: 'Farmer Role',
                    child: SizedBox(
                      height: 100,
                      child: SvgPicture.asset('assets/images/role_farmer.svg'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AssetCard(
                    title: 'role_provider.svg',
                    subtitle: 'Provider Role',
                    child: SizedBox(
                      height: 100,
                      child: SvgPicture.asset('assets/images/role_provider.svg'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Empty State Placeholders', style: AppTypography.titleLarge(AppColors.textDark)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AssetCard(
                    title: 'empty_jobs.svg',
                    subtitle: 'No Jobs / Search Empty',
                    child: SizedBox(
                      height: 120,
                      child: SvgPicture.asset('assets/images/empty_jobs.svg'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AssetCard(
                    title: 'empty_notifications.svg',
                    subtitle: 'No Notifications Empty',
                    child: SizedBox(
                      height: 120,
                      child: SvgPicture.asset('assets/images/empty_notifications.svg'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _AssetCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          child,
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTypography.titleSmall(AppColors.textDark),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: AppTypography.bodySmall(AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
