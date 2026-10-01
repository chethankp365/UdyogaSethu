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
import 'package:udyogasethu/core/widgets/not_found_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final sessionData = ref.watch(appSessionProvider);

  return GoRouter(
    initialLocation: AppRoutes.seekerHome,
    errorBuilder: (context, state) => NotFoundScreen(state: state),
    redirect: (context, state) {
      final loc = state.uri.toString();

      // Allow all /dev/ routes without session redirects in debug mode
      if (kDebugMode && loc.startsWith('/dev/')) {
        return null;
      }

      // If session is ready and on root '/', redirect to active role home
      if (loc == '/') {
        return AppSessionNotifier.getHomeForRole(sessionData.activeRole);
      }

      return null;
    },
    routes: [
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
      ],
    ],
  );
});
