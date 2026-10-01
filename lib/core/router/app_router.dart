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
import 'package:udyogasethu/features/onboarding/presentation/intro_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/language_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/splash_screen.dart';

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

      // Booting state stays on splash
      if (status == AuthSessionStatus.booting && loc != AppRoutes.splash) {
        return AppRoutes.splash;
      }

      // If user is on root '/' or '/splash' after bootstrap complete
      if (loc == '/' || (loc == AppRoutes.splash && status != AuthSessionStatus.booting)) {
        switch (status) {
          case AuthSessionStatus.needsOnboarding:
            return AppRoutes.intro;
          case AuthSessionStatus.signedOut:
            return AppRoutes.login;
          case AuthSessionStatus.needsProfile:
            return '/profile-setup/${sessionData.activeRole.name}';
          case AuthSessionStatus.ready:
            return AppSessionNotifier.getHomeForRole(sessionData.activeRole);
          case AuthSessionStatus.booting:
            return AppRoutes.splash;
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
        path: AppRoutes.login,
        builder: (context, state) => const PlaceholderScreen(
          title: 'Phone OTP & Social Login',
          roleName: 'Authentication',
          icon: Icons.lock_rounded,
        ),
      ),
      GoRoute(
        path: AppRoutes.profileSetupSeeker,
        builder: (context, state) => const PlaceholderScreen(
          title: 'Job Seeker Profile Wizard',
          roleName: 'Profile Setup',
          icon: Icons.person_add_rounded,
        ),
      ),
      GoRoute(
        path: AppRoutes.profileSetupProvider,
        builder: (context, state) => const PlaceholderScreen(
          title: 'Job Provider Profile Wizard',
          roleName: 'Profile Setup',
          icon: Icons.business_center_rounded,
        ),
      ),
      GoRoute(
        path: AppRoutes.profileSetupFarmer,
        builder: (context, state) => const PlaceholderScreen(
          title: 'Farmer Profile Wizard',
          roleName: 'Profile Setup',
          icon: Icons.agriculture_rounded,
        ),
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
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Employer Dashboard & Active Jobs',
                  roleName: 'Job Provider',
                  icon: Icons.home_rounded,
                ),
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
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Farmer Dashboard & Mandi Prices',
                  roleName: 'Farmer',
                  icon: Icons.home_rounded,
                ),
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
