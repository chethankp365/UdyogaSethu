import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/router/app_shells.dart';
import 'package:udyogasethu/core/router/placeholder_screen.dart';
import 'package:udyogasethu/core/router/role_switcher_debug_screen.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/widgets/component_gallery_screen.dart';
import 'package:udyogasethu/core/widgets/connection_debug_screen.dart';
import 'package:udyogasethu/core/widgets/dev_assets_screen.dart';
import 'package:udyogasethu/core/widgets/not_found_screen.dart';
import 'package:udyogasethu/features/account/presentation/linked_accounts_screen.dart';
import 'package:udyogasethu/features/account/presentation/settings_screen.dart';
import 'package:udyogasethu/features/auth/presentation/login_screen.dart';
import 'package:udyogasethu/features/auth/presentation/otp_screen.dart';
import 'package:udyogasethu/features/auth/presentation/suspended_screen.dart';
import 'package:udyogasethu/features/auth/presentation/verify_phone_screen.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_home_screen.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_wizard_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/brand_intro_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/intro_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/language_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/role_conflict_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/role_tree_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/splash_screen.dart';
import 'package:udyogasethu/features/privacy/presentation/privacy_centre_screen.dart';
import 'package:udyogasethu/features/privacy/presentation/terms_privacy_screen.dart';
import 'package:udyogasethu/features/profile/presentation/profile_screen.dart';
import 'package:udyogasethu/features/trust/presentation/kyc_screen.dart';
import 'package:udyogasethu/features/provider/presentation/provider_home_screen.dart';
import 'package:udyogasethu/features/provider/presentation/provider_wizard_screen.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_home_screen.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_wizard_screen.dart';

/// RouterNotifier notifies [GoRouter] when session state changes without recreating the router.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AppSessionData>(
      appSessionProvider,
      (previous, next) => notifyListeners(),
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.brandIntro,
    refreshListenable: notifier,
    errorBuilder: (context, state) => NotFoundScreen(state: state),
    redirect: (context, state) {
      final loc = state.uri.toString();

      // Allow all /dev/ routes without session redirects in debug mode ONLY
      if (kDebugMode && loc.startsWith('/dev/')) {
        return null;
      }
      if (!kDebugMode && loc.startsWith('/dev/')) {
        return AppRoutes.splash;
      }

      // 1. Allow BrandIntro screen to play uninterrupted
      if (loc == AppRoutes.brandIntro) {
        if (!BrandIntroScreen.isCompleted) {
          return null;
        }
      }

      // 2. Allow Splash screen to show for its minimum display time
      if (loc == AppRoutes.splash) {
        if (!SplashScreen.isSplashReadyToNavigate) {
          return null;
        }
      }

      final sessionData = ref.read(appSessionProvider);
      final status = sessionData.status;

      String? target;

      // 1. Booting state stays on splash
      if (status == AuthSessionStatus.booting) {
        target = (loc == AppRoutes.splash || loc == AppRoutes.brandIntro) ? null : AppRoutes.splash;
      }
      // 2. Suspended state
      else if (status == AuthSessionStatus.suspended) {
        target = loc == AppRoutes.suspended ? null : AppRoutes.suspended;
      }
      // 2b. Role Conflict state
      else if (status == AuthSessionStatus.roleConflict) {
        target = loc == AppRoutes.roleConflict ? null : AppRoutes.roleConflict;
      }
      // 3. Needs Onboarding (First launch for signed-out user)
      else if (status == AuthSessionStatus.needsOnboarding) {
        const allowedOnboarding = [
          AppRoutes.intro,
          AppRoutes.language,
        ];
        if (!allowedOnboarding.contains(loc)) {
          target = AppRoutes.intro;
        }
      }
      // 4. Signed out state (Intro seen, returning user)
      else if (status == AuthSessionStatus.signedOut) {
        const allowedUnauth = [
          AppRoutes.language,
          AppRoutes.roleTree,
          AppRoutes.login,
          AppRoutes.otp,
          AppRoutes.verifyPhone,
        ];
        if (!allowedUnauth.contains(loc)) {
          if (loc == AppRoutes.splash || loc == '/') {
            target = AppRoutes.language;
          } else {
            target = AppRoutes.login;
          }
        }
      }
      // 5. Needs Role Assignment (Signed in, no role selected yet)
      else if (status == AuthSessionStatus.needsRole) {
        const allowedRoleSetup = [
          AppRoutes.roleTree,
          AppRoutes.language,
        ];
        if (!allowedRoleSetup.contains(loc)) {
          target = AppRoutes.roleTree;
        }
      }
      // 6. Needs Profile Wizard (Signed in, role chosen, wizard incomplete)
      else if (status == AuthSessionStatus.needsProfile) {
        final profilePath = '/profile-setup/${sessionData.activeRole.name}';
        if (loc != profilePath && loc != AppRoutes.language) {
          target = profilePath;
        }
      }
      // 7. Ready state (Signed in & Onboarded)
      else if (status == AuthSessionStatus.ready) {
        // Replay pending deep link if present
        if (sessionData.deepLinkPending != null) {
          final pending = sessionData.deepLinkPending!;
          ref.read(appSessionProvider.notifier).setDeepLinkPending(null);
          if (pending != loc && pending != AppRoutes.login && pending != AppRoutes.splash) {
            target = pending;
          }
        }

        if (target == null) {
          // Redirect from onboarding/login screens to active role home
          const onboardingOrLogin = [
            '/',
            AppRoutes.brandIntro,
            AppRoutes.splash,
            AppRoutes.intro,
            AppRoutes.roleTree,
            AppRoutes.login,
            AppRoutes.otp,
            AppRoutes.verifyPhone,
          ];
          if (onboardingOrLogin.contains(loc)) {
            target = AppSessionNotifier.getHomeForRole(sessionData.activeRole);
          }
        }
      }

      if (kDebugMode && target != null) {
        AppLogger.i('Router redirect: loc="$loc" -> target="$target" (status=${status.name}, role=${sessionData.activeRole.name})');
      }

      return target;
    },
    routes: [
      // 0. Onboarding & Auth Standalone Routes
      GoRoute(
        path: AppRoutes.brandIntro,
        pageBuilder: (context, state) => const MaterialPage(
          key: ValueKey('brand_intro_page'),
          child: BrandIntroScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => const MaterialPage(
          key: ValueKey('splash_page'),
          child: SplashScreen(),
        ),
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
        path: AppRoutes.roleConflict,
        builder: (context, state) {
          final session = ref.read(appSessionProvider);
          return RoleConflictScreen(
            existingRole: session.existingRole ?? UserRole.seeker,
            chosenRole: session.chosenRole ?? UserRole.farmer,
          );
        },
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
                builder: (context, state) => const SeekerHomeScreen(),
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
                builder: (context, state) => const ProfileScreen(role: UserRole.seeker),
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
                builder: (context, state) => const ProfileScreen(role: UserRole.provider),
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
                builder: (context, state) => const ProfileScreen(role: UserRole.farmer),
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
        path: AppRoutes.kyc,
        builder: (context, state) => const KycScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacyCentre,
        builder: (context, state) => const PrivacyCentreScreen(),
      ),
      GoRoute(
        path: AppRoutes.termsAndPrivacy,
        builder: (context, state) => const TermsPrivacyScreen(),
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
