import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/router/app_shells.dart';
import 'package:udyogasethu/core/router/placeholder_screen.dart';
import 'package:udyogasethu/core/router/role_switcher_debug_screen.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/widgets/component_gallery_screen.dart';
import 'package:udyogasethu/core/widgets/connection_debug_screen.dart';
import 'package:udyogasethu/core/widgets/dev_assets_screen.dart';
import 'package:udyogasethu/core/widgets/not_found_screen.dart';
import 'package:udyogasethu/features/auth/presentation/login_screen.dart';
import 'package:udyogasethu/features/auth/presentation/otp_screen.dart';
import 'package:udyogasethu/features/auth/presentation/suspended_screen.dart';
import 'package:udyogasethu/features/auth/presentation/verify_phone_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/intro_screen.dart';

import 'package:udyogasethu/features/onboarding/presentation/language_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/role_tree_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/splash_screen.dart';
import 'package:udyogasethu/features/account/presentation/linked_accounts_screen.dart';
import 'package:udyogasethu/features/account/presentation/settings_screen.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_home_screen.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_wizard_screen.dart';
import 'package:udyogasethu/features/provider/presentation/provider_home_screen.dart';
import 'package:udyogasethu/features/provider/presentation/provider_wizard_screen.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_wizard_screen.dart';


final appRouterProvider = Provider<GoRouter>((ref) {
  final sessionData = ref.watch(appSessionProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    errorBuilder: (context, state) => NotFoundScreen(state: state),
    redirect: (context, state) {
      final loc = state.uri.toString();

      // Allow all /dev/ routes without session redirects in debug mode
      if (kDebugMode && loc.startsWith('/dev/')) {
        return null;
      }

      final status = sessionData.status;

      // 1. Booting state stays on splash
      if (status == AuthSessionStatus.booting) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // 2. Suspended state
      if (status == AuthSessionStatus.suspended) {
        return loc == AppRoutes.suspended ? null : AppRoutes.suspended;
      }

      // 3. Signed out state
      if (status == AuthSessionStatus.signedOut) {
        const allowedUnauth = [
          AppRoutes.splash,
          AppRoutes.intro,
          AppRoutes.language,
          AppRoutes.roleTree,
          AppRoutes.login,
          AppRoutes.otp,
          AppRoutes.verifyPhone,
        ];
        if (!allowedUnauth.contains(loc) && !loc.startsWith('/dev/')) {
          // Capture deep link for replay after login
          ref.read(appSessionProvider.notifier).setDeepLinkPending(loc);
          return AppRoutes.login;
        }
        return null;
      }

      // 4. Needs Onboarding (intro)
      if (status == AuthSessionStatus.needsOnboarding) {
        if (loc == AppRoutes.splash || loc == AppRoutes.intro || loc == AppRoutes.language) {
          return null;
        }
        return AppRoutes.intro;
      }

      // 5. Needs Role Assignment
      if (status == AuthSessionStatus.needsRole) {
        if (loc == AppRoutes.roleTree || loc == AppRoutes.language) {
          return null;
        }
        return AppRoutes.roleTree;
      }

      // 6. Needs Profile Wizard
      if (status == AuthSessionStatus.needsProfile) {
        final profilePath = '/profile-setup/${sessionData.activeRole.name}';
        if (loc == profilePath || loc == AppRoutes.language) {
          return null;
        }
        return profilePath;
      }

      // 7. Ready state (Signed in & Onboarded)
      if (status == AuthSessionStatus.ready) {
        // Replay pending deep link if present
        if (sessionData.deepLinkPending != null) {
          final target = sessionData.deepLinkPending!;
          ref.read(appSessionProvider.notifier).setDeepLinkPending(null);
          if (target != loc && target != AppRoutes.login && target != AppRoutes.splash) {
            return target;
          }
        }

        // Redirect from root or onboarding/login screens to role home
        const onboardingOrLogin = [
          '/',
          AppRoutes.splash,
          AppRoutes.intro,
          AppRoutes.roleTree,
          AppRoutes.login,
          AppRoutes.otp,
          AppRoutes.verifyPhone,
        ];
        if (onboardingOrLogin.contains(loc)) {
          return AppSessionNotifier.getHomeForRole(sessionData.activeRole);
        }
      }

      return null;
    },
    routes: [
      // 0. Onboarding & Auth Standalone Routes
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.intro,
        builder: (context, state) => const IntroScreen(),
      ),
      GoRoute(
        path: AppRoutes.language,
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: AppRoutes.roleTree,
        builder: (context, state) => const RoleTreeScreen(),
      ),

      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyPhone,
        builder: (context, state) => const VerifyPhoneScreen(),
      ),
      GoRoute(
        path: AppRoutes.suspended,
        builder: (context, state) => const SuspendedScreen(),
      ),

      GoRoute(
        path: AppRoutes.profileSetupSeeker,
        builder: (context, state) => const SeekerWizardScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSetupProvider,
        builder: (context, state) => const ProviderWizardScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSetupFarmer,
        builder: (context, state) => const FarmerWizardScreen(),
      ),

      // 1. Job Seeker Shell (StatefulShellRoute with 4 tabs)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return SeekerShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.seekerHome,
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Home Feed & Recommendations',
                  roleName: 'Job Seeker',
                  icon: Icons.home_rounded,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.seekerJobs,
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Nearby Jobs & Map',
                  roleName: 'Job Seeker',
                  icon: Icons.work_rounded,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.seekerChat,
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Protected Inbox & Chat',
                  roleName: 'Job Seeker',
                  icon: Icons.chat_bubble_rounded,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.seekerProfile,
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Seeker Profile & Trust Kit',
                  roleName: 'Job Seeker',
                  icon: Icons.person_rounded,
                ),
              ),
            ],
          ),
        ],
      ),

      // 2. Job Provider Shell (StatefulShellRoute with 4 tabs)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ProviderShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.providerHome,
                builder: (context, state) => const ProviderHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.providerWorkers,
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Worker Search & Hires',
                  roleName: 'Job Provider',
                  icon: Icons.people_alt_rounded,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.providerChat,
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Worker Messages & Calls',
                  roleName: 'Job Provider',
                  icon: Icons.chat_bubble_rounded,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.providerProfile,
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Employer Profile & Billing',
                  roleName: 'Job Provider',
                  icon: Icons.person_rounded,
                ),
              ),
            ],
          ),
        ],
      ),

      // 3. Farmer Shell (StatefulShellRoute with 4 tabs)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return FarmerShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.farmerHome,
                builder: (context, state) => const FarmerHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.farmerMarket,
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Produce Marketplace & Labour Hiring',
                  roleName: 'Farmer',
                  icon: Icons.storefront_rounded,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.farmerChat,
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Buyer & Worker Chat',
                  roleName: 'Farmer',
                  icon: Icons.chat_bubble_rounded,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.farmerProfile,
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Farm Profile & Certificates',
                  roleName: 'Farmer',
                  icon: Icons.person_rounded,
                ),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/account/linked',
        builder: (context, state) => const LinkedAccountsScreen(),
      ),

      // Debug Routes
      if (kDebugMode) ...[
        GoRoute(
          path: AppRoutes.devGallery,
          builder: (context, state) => const ComponentGalleryScreen(),
        ),
        GoRoute(
          path: AppRoutes.devConnection,
          builder: (context, state) => const ConnectionDebugScreen(),
        ),
        GoRoute(
          path: AppRoutes.devRole,
          builder: (context, state) => const RoleSwitcherDebugScreen(),
        ),
        GoRoute(
          path: AppRoutes.devAssets,
          builder: (context, state) => const DevAssetsScreen(),
        ),
      ],
    ],
  );
});
