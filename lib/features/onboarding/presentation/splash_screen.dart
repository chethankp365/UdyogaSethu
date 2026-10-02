import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';
import 'package:udyogasethu/features/onboarding/data/bootstrap_service.dart';

/// Splash Screen matching Screen 1 in UI_REFERENCE.md.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger real bootstrapping after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bootstrapProvider.notifier).runBootstrap();
    });
  }

  void _navigateAfterBootstrap(AuthSessionStatus status, UserRole role) {
    if (!mounted) return;
    switch (status) {
      case AuthSessionStatus.needsOnboarding:
        context.go(AppRoutes.intro);
        break;
      case AuthSessionStatus.signedOut:
        context.go(AppRoutes.login);
        break;
      case AuthSessionStatus.needsRole:
        context.go(AppRoutes.roleTree);
        break;
      case AuthSessionStatus.needsProfile:
        context.go('/profile-setup/${role.name}');
        break;
      case AuthSessionStatus.ready:
        context.go(AppSessionNotifier.getHomeForRole(role));
        break;
      case AuthSessionStatus.suspended:
        context.go(AppRoutes.suspended);
        break;
      case AuthSessionStatus.booting:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bootstrapState = ref.watch(bootstrapProvider);

    // Listen for bootstrap completion and navigate smoothly
    ref.listen<BootstrapState>(bootstrapProvider, (previous, next) {
      if (next.isDone && (previous == null || !previous.isDone)) {
        final session = ref.read(appSessionProvider);
        _navigateAfterBootstrap(session.status, session.activeRole);
      }
    });

    final pctInt = (bootstrapState.progress * 100).clamp(0, 100).toInt();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // 1. UdyogaSethu Brand Logo
              Image.asset(
                'assets/images/logo.png',
                height: 90,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 8),

              // 2. Main Tagline (Green/Orange split styling)
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Bridging Work. ',
                      style: AppTypography.titleMedium(AppColors.headerGreenDark).copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: 'Empowering Lives.',
                      style: AppTypography.titleMedium(AppColors.darkOrange).copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 3. Central Banner Illustration (City skyline & village bridge)
              SizedBox(
                height: 220,
                child: SvgPicture.asset(
                  'assets/images/splash_city_bridge.svg',
                  fit: BoxFit.contain,
                ),
              ),

              const Spacer(),

              // 4. Progress Bar Track & Fill
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.paleMint,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: constraints.maxWidth * bootstrapState.progress,
                        decoration: BoxDecoration(
                          color: AppColors.warningOrange,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // 5. Progress Label & Percentage
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Initializing UdyogaSethu...',
                    style: AppTypography.bodySmall(AppColors.textMuted),
                  ),
                  Text(
                    '$pctInt%',
                    style: AppTypography.bodySmall(AppColors.textDark).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 6. Feature Pills Row (AI Matching • Secure • Verified)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _FeaturePill(icon: Icons.auto_awesome_rounded, label: 'AI Matching'),
                  SizedBox(width: 8),
                  _FeaturePill(icon: Icons.shield_rounded, label: 'Secure'),
                  SizedBox(width: 8),
                  _FeaturePill(icon: Icons.verified_rounded, label: 'Verified'),
                ],
              ),

              const SizedBox(height: 20),

              // 7. Version Footer
              Text(
                'Version ${bootstrapState.versionString}',
                style: AppTypography.bodySmall(AppColors.textMuted),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.paleMint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderGreen),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.headerGreenDark),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.bodySmall(AppColors.headerGreenDark).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
