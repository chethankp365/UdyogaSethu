import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
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
/// Guarantees at least 1.8 seconds of splash screen visibility ("Initializing UdyogaSethu...")
/// before transitioning to onboarding or home screens.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  /// Static flag indicating whether Boot Splash has completed its minimum 1.8s display time.
  static bool isSplashReadyToNavigate = false;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  late final DateTime _mountTime;
  Timer? _minDisplayTimer;
  StreamSubscription<dynamic>? _connectivitySubscription;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _mountTime = DateTime.now();
    SplashScreen.isSplashReadyToNavigate = false;

    // Listen to network changes to auto-retry bootstrapping when connection returns
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection && ref.read(bootstrapProvider).error != null) {
        ref.read(bootstrapProvider.notifier).runBootstrap();
      }
    });

    // Trigger bootstrapping post frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bootstrapProvider.notifier).runBootstrap();
      _scheduleMinimumSplashCheck();
    });
  }

  void _scheduleMinimumSplashCheck() {
    final elapsed = DateTime.now().difference(_mountTime);
    final remainingMs = (1800 - elapsed.inMilliseconds).clamp(0, 1800);

    _minDisplayTimer?.cancel();
    _minDisplayTimer = Timer(Duration(milliseconds: remainingMs), () {
      _checkAndNavigate();
    });
  }

  void _checkAndNavigate() {
    if (!mounted || _hasNavigated) return;
    final bootstrapState = ref.read(bootstrapProvider);

    if (bootstrapState.isDone) {
      _hasNavigated = true;
      SplashScreen.isSplashReadyToNavigate = true;
      final session = ref.read(appSessionProvider);
      _navigateAfterBootstrap(session.status, session.activeRole);
    }
  }

  void _navigateAfterBootstrap(AuthSessionStatus status, UserRole role) {
    if (!mounted) return;
    switch (status) {
      case AuthSessionStatus.needsOnboarding:
        context.go(AppRoutes.intro);
        break;
      case AuthSessionStatus.signedOut:
        context.go(AppRoutes.language);
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
      case AuthSessionStatus.roleConflict:
        context.go(AppRoutes.roleConflict);
        break;
      case AuthSessionStatus.booting:
        break;
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _minDisplayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bootstrapState = ref.watch(bootstrapProvider);

    // Listen for bootstrap state updates
    ref.listen<BootstrapState>(bootstrapProvider, (previous, next) {
      if (next.isDone) {
        _checkAndNavigate();
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
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: SvgPicture.asset(
                      'assets/images/splash_city_bridge.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // 4. Progress Bar / Error View
              if (bootstrapState.error != null) ...[
                if (bootstrapState.isOffline) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warningOrange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warningOrange),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.wifi_off_rounded, color: AppColors.warningOrange, size: 36),
                        const SizedBox(height: 8),
                        const Text(
                          'No Internet Connection',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'No internet connection. Check Wi-Fi or mobile data',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                        if (kDebugMode && bootstrapState.error != 'No internet connection. Check Wi-Fi or mobile data') ...[
                          const SizedBox(height: 6),
                          Text(
                            bootstrapState.error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54, fontSize: 11, fontFamily: 'monospace'),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.headerGreenDark,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              onPressed: () {
                                ref.read(bootstrapProvider.notifier).runBootstrap();
                              },
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Retry'),
                            ),
                            if (bootstrapState.canOpenOffline) ...[
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.headerGreenDark,
                                  side: const BorderSide(color: AppColors.headerGreenDark),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                onPressed: () {
                                  ref.read(bootstrapProvider.notifier).openOffline();
                                },
                                icon: const Icon(Icons.offline_pin_outlined, size: 18),
                                label: const Text('Open Offline'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.sosRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.sosRed),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.sosRed, size: 36),
                        const SizedBox(height: 8),
                        const Text(
                          'Failed to initialize app',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.sosRed, fontSize: 16),
                        ),
                        if (kDebugMode) ...[
                          const SizedBox(height: 4),
                          Text(
                            bootstrapState.error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black87, fontSize: 12, fontFamily: 'monospace'),
                          ),
                        ],
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.headerGreenDark,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            ref.read(bootstrapProvider.notifier).runBootstrap();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Bootstrapping'),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      bootstrapState.statusText.isEmpty ? 'Initializing UdyogaSethu...' : bootstrapState.statusText,
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
              ],

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

              // 7. Version Footer (Long press in debug mode opens Dev Menu)
              GestureDetector(
                onLongPress: kDebugMode
                    ? () {
                        showModalBottomSheet(
                          context: context,
                          builder: (ctx) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const ListTile(
                                  leading: Icon(Icons.bug_report_rounded, color: AppColors.headerGreenDark),
                                  title: Text('Developer Menu (Debug Only)', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  leading: const Icon(Icons.swap_horiz_rounded),
                                  title: const Text('Dev Role & Shell Switcher'),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    context.push(AppRoutes.devRole);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.palette_rounded),
                                  title: const Text('Component Gallery'),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    context.push(AppRoutes.devGallery);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.cloud_sync_rounded),
                                  title: const Text('Supabase Connection Debug'),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    context.push(AppRoutes.devConnection);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.collections_rounded),
                                  title: const Text('Dev Assets Screen'),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    context.push(AppRoutes.devAssets);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    : null,
                child: Text(
                  'Version ${bootstrapState.versionString}${kDebugMode ? " (Debug Mode - Long Press for Dev Menu)" : ""}',
                  style: AppTypography.bodySmall(AppColors.textMuted),
                ),
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
