import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';
import 'package:udyogasethu/core/widgets/app_button.dart';
import 'package:udyogasethu/features/onboarding/data/bootstrap_service.dart';

/// Intro / Onboarding Screen matching Screen 2 in UI_REFERENCE.md.
class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  Future<void> _completeIntro({required bool isSkip}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SharedPrefKeys.hasSeenIntro, true);

    if (!mounted) return;
    ref.read(appSessionProvider.notifier).setSessionStatus(AuthSessionStatus.signedOut);

    if (isSkip) {
      context.go(AppRoutes.login);
    } else {
      context.go(AppRoutes.language);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar: Logo (left) & Skip button (right)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/logo_small.png',
                    height: 38,
                    fit: BoxFit.contain,
                  ),
                  TextButton(
                    onPressed: () => _completeIntro(isSkip: true),
                    child: Text(
                      'Skip',
                      style: AppTypography.titleSmall(AppColors.headerGreenDark).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 2. Main Headline & Subheadline
              Text(
                'Built for India. For Every Worker.',
                style: AppTypography.displayMedium(AppColors.headerGreenDark).copyWith(
                  fontSize: 22,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Find jobs, grow skills, earn better and live with dignity.',
                style: AppTypography.bodyMedium(AppColors.textMuted),
              ),

              const SizedBox(height: 16),

              // 3. Central Hero Photo / Illustration
              Expanded(
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/intro_hero.svg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 4. Three Feature Cards Grid
              const Row(
                children: [
                  Expanded(
                    child: _FeatureTile(
                      svgAsset: 'assets/images/feature_find_jobs.svg',
                      title: 'Find Jobs\nNear You',
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _FeatureTile(
                      svgAsset: 'assets/images/feature_secure_payments.svg',
                      title: 'Secure\nPayments',
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _FeatureTile(
                      svgAsset: 'assets/images/feature_ai_voice.svg',
                      title: 'AI Voice\nAssistant',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 5. Bottom Primary Pill Action Button (Next ->)
              AppButton(
                label: 'Next ->',
                onPressed: () => _completeIntro(isSkip: false),
                variant: AppButtonVariant.primary,
                fullWidth: true,
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final String svgAsset;
  final String title;

  const _FeatureTile({
    required this.svgAsset,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.paleMint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderGreen),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 48,
            width: 48,
            child: SvgPicture.asset(svgAsset),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTypography.bodySmall(AppColors.textDark).copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
