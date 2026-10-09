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
import 'package:udyogasethu/features/dev/presentation/edge_health_screen.dart';
import 'package:udyogasethu/features/account/presentation/linked_accounts_screen.dart';
import 'package:udyogasethu/features/account/presentation/settings_screen.dart';
import 'package:udyogasethu/features/auth/presentation/login_screen.dart';
import 'package:udyogasethu/features/auth/presentation/otp_screen.dart';
import 'package:udyogasethu/features/auth/presentation/suspended_screen.dart';
import 'package:udyogasethu/features/auth/presentation/verify_phone_screen.dart';
import 'package:udyogasethu/features/farmer/domain/farm_resource_model.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_home_screen.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_listings_screen.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_profile_screen.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_wizard_screen.dart';
import 'package:udyogasethu/features/farmer/presentation/farm_resources_map_screen.dart';
import 'package:udyogasethu/features/farmer/presentation/vendor_resources_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/brand_intro_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/intro_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/language_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/role_conflict_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/role_tree_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/splash_screen.dart';
import 'package:udyogasethu/features/privacy/presentation/privacy_centre_screen.dart';
import 'package:udyogasethu/features/privacy/presentation/terms_privacy_screen.dart';
import 'package:udyogasethu/features/profile/presentation/profile_screen.dart';
import 'package:udyogasethu/features/trust/domain/verification_visibility.dart';
import 'package:udyogasethu/features/trust/presentation/background_check_screen.dart';
import 'package:udyogasethu/features/trust/presentation/bank_upi_screen.dart';
import 'package:udyogasethu/features/trust/presentation/digital_id_screen.dart';
import 'package:udyogasethu/features/trust/presentation/driving_licence_screen.dart';
import 'package:udyogasethu/features/trust/presentation/face_enrollment_screen.dart';
import 'package:udyogasethu/features/trust/presentation/kyc_screen.dart';
import 'package:udyogasethu/features/trust/presentation/safety_onboarding_screen.dart';
import 'package:udyogasethu/features/trust/presentation/scan_verify_screen.dart';
import 'package:udyogasethu/features/trust/presentation/student_verification_screen.dart';
import 'package:udyogasethu/features/trust/presentation/trust_governance_rights_screen.dart';
import 'package:udyogasethu/features/trust/presentation/trust_safety_centre_screen.dart';
import 'package:udyogasethu/features/trust/presentation/job_history_screen.dart';
import 'package:udyogasethu/features/trust/presentation/favourites_screen.dart';
import 'package:udyogasethu/features/wallet/presentation/wallet_screen.dart';
import 'package:udyogasethu/features/earnings/presentation/earnings_dashboard_screen.dart';
import 'package:udyogasethu/features/earnings/presentation/savings_goals_screen.dart';
import 'package:udyogasethu/features/payments/presentation/payment_checkout_screen.dart';
import 'package:udyogasethu/features/payments/presentation/payment_status_screen.dart';
import 'package:udyogasethu/features/verification/presentation/face_check_screen.dart';
import 'package:udyogasethu/features/marketplace/domain/produce_marketplace_item.dart';
import 'package:udyogasethu/features/marketplace/domain/produce_order.dart';
import 'package:udyogasethu/features/marketplace/presentation/produce_detail_screen.dart';
import 'package:udyogasethu/features/marketplace/presentation/cart_screen.dart';
import 'package:udyogasethu/features/marketplace/presentation/order_checkout_wizard.dart';
import 'package:udyogasethu/features/marketplace/presentation/order_confirmation_screen.dart';
import 'package:udyogasethu/features/marketplace/presentation/order_tracking_screen.dart';
import 'package:udyogasethu/features/marketplace/presentation/customer_orders_screen.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_order_board_screen.dart';
import 'package:udyogasethu/features/farmer/presentation/delivery_slots_screen.dart';
import 'package:udyogasethu/features/provider/presentation/provider_home_screen.dart';
import 'package:udyogasethu/features/provider/presentation/provider_wizard_screen.dart';
import 'package:udyogasethu/features/provider/presentation/post_job_wizard_screen.dart';
import 'package:udyogasethu/features/provider/presentation/job_applicants_screen.dart';
import 'package:udyogasethu/features/provider/presentation/worker_search_screen.dart';
import 'package:udyogasethu/features/provider/presentation/worker_profile_screen.dart';
import 'package:udyogasethu/features/booking/domain/booking_draft.dart';
import 'package:udyogasethu/features/booking/presentation/guided_booking_screen.dart';
import 'package:udyogasethu/features/booking/presentation/recurring_bookings_screen.dart';
import 'package:udyogasethu/features/seeker/domain/job_recommendation.dart';
import 'package:udyogasethu/features/seeker/presentation/job_detail_screen.dart';
import 'package:udyogasethu/features/seeker/presentation/map/nearby_jobs_map_screen.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_home_screen.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_jobs_screen.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_wizard_screen.dart';
import 'package:udyogasethu/features/job_execution/presentation/active_job_screen.dart';
import 'package:udyogasethu/features/job_execution/presentation/attendance_scanner_screen.dart';
import 'package:udyogasethu/features/job_execution/presentation/job_ticket_screen.dart';
import 'package:udyogasethu/features/job_execution/presentation/worker_schedule_screen.dart';
import 'package:udyogasethu/features/job_execution/presentation/verify_presence_screen.dart';
import 'package:udyogasethu/features/job_execution/presentation/job_completion_screen.dart';

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
        // Face Verification Login Gate for Worker (Seeker) accounts
        final isSeeker = sessionData.activeRole == UserRole.seeker;
        final isFaceGateActive = isSeeker && sessionData.faceRequiredAtLogin && !sessionData.faceLoginPassed;

        if (isFaceGateActive) {
          final targetGate = sessionData.hasEnrolledFace ? AppRoutes.kycFaceCheck : AppRoutes.kycFace;
          if (loc != targetGate) {
            target = targetGate;
            if (kDebugMode) {
              AppLogger.i('[FaceLoginGate] loc="$loc" -> REDIRECT to "$target" (hasEnrolledFace=${sessionData.hasEnrolledFace})');
            }
          }
        }

        // Replay pending deep link if present and not blocked by face gate
        if (target == null && sessionData.deepLinkPending != null) {
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

        // Verification Route Guards based on single source matrix
        if (target == null) {
          final role = sessionData.activeRole;
          final seekerType = sessionData.seekerType;
          final isSeekerTypeLoading = role == UserRole.seeker && !sessionData.seekerTypeLoaded && seekerType == null;

          const guardedRoutes = [
            AppRoutes.kycStudent,
            AppRoutes.kycDl,
            AppRoutes.kycBackground,
            AppRoutes.kycBank,
          ];

          if (guardedRoutes.contains(loc)) {
            VerificationType? vType;
            if (loc == AppRoutes.kycStudent) vType = VerificationType.student;
            if (loc == AppRoutes.kycDl) vType = VerificationType.drivingLicence;
            if (loc == AppRoutes.kycBackground) vType = VerificationType.backgroundCheck;
            if (loc == AppRoutes.kycBank) vType = VerificationType.bankUpi;

            if (vType != null) {
              if (isSeekerTypeLoading) {
                if (kDebugMode) {
                  AppLogger.i('[VerificationGuard] loc="$loc", role="${role.name}", seekerType=null, loading=true -> ALLOWED (Waiting for profile loading)');
                }
              } else {
                final allowed = isVerificationItemVisible(type: vType, role: role, seekerType: seekerType);
                if (!allowed) {
                  target = AppSessionNotifier.getHomeForRole(role);
                  if (kDebugMode) {
                    AppLogger.i('[VerificationGuard] loc="$loc", role="${role.name}", seekerType="$seekerType", loading=${sessionData.seekerTypeLoaded} -> REDIRECT to "$target" (Reason: Verification item ${vType.name} is not allowed for role=${role.name}, seekerType=$seekerType)');
                  }
                } else if (kDebugMode) {
                  AppLogger.i('[VerificationGuard] loc="$loc", role="${role.name}", seekerType="$seekerType", loading=${sessionData.seekerTypeLoaded} -> ALLOWED');
                }
              }
            }
          }

          // D-VISIBILITY Route Guards for Digital ID (Seeker only) and Scan & Verify (Provider only)
          if (loc == AppRoutes.digitalId) {
            final isAllowed = role == UserRole.seeker;
            if (!isAllowed) {
              target = AppSessionNotifier.getHomeForRole(role);
              if (kDebugMode) {
                AppLogger.i('[D-VISIBILITY] Blocked digitalId for role=${role.name} -> Redirect to $target');
              }
            }
          } else if (loc == AppRoutes.scanVerify) {
            final isAllowed = role == UserRole.provider;
            if (!isAllowed) {
              target = AppSessionNotifier.getHomeForRole(role);
              if (kDebugMode) {
                AppLogger.i('[D-VISIBILITY] Blocked scanVerify for role=${role.name} -> Redirect to $target');
              }
            }
          }
        }
      }

      if (kDebugMode && target != null && !loc.startsWith('/kyc')) {
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
                builder: (context, state) => const SeekerJobsScreen(),
              ),
              GoRoute(
                path: AppRoutes.seekerMap,
                builder: (context, state) => const NearbyJobsMapScreen(),
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
                builder: (context, state) => const WorkerSearchScreen(),
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
                builder: (context, state) => const FarmerListingsScreen(),
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
                builder: (context, state) => const FarmerProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: AppRoutes.farmerListings,
        builder: (context, state) => const FarmerListingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.farmerResources,
        builder: (context, state) {
          final cat = state.uri.queryParameters['category'];
          FarmResourceCategoryFilter initialFilter = FarmResourceCategoryFilter.all;
          if (cat == 'tractor') {
            initialFilter = FarmResourceCategoryFilter.tractorsAndImplements;
          } else if (cat == 'drone') {
            initialFilter = FarmResourceCategoryFilter.dronesAndSpraying;
          } else if (cat == 'seeds' || cat == 'fertilizer') {
            initialFilter = FarmResourceCategoryFilter.seedsAndBioFertilizers;
          } else if (cat == 'cold_storage') {
            initialFilter = FarmResourceCategoryFilter.coldStorage;
          }
          return FarmResourcesMapScreen(initialFilter: initialFilter);
        },
      ),
      GoRoute(
        path: AppRoutes.farmerVendorResources,
        builder: (context, state) => const VendorResourcesScreen(),
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
        path: AppRoutes.kycDl,
        builder: (context, state) => const DrivingLicenceScreen(),
      ),
      GoRoute(
        path: AppRoutes.kycStudent,
        builder: (context, state) => const StudentVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.kycBank,
        builder: (context, state) => const BankUpiScreen(),
      ),
      GoRoute(
        path: AppRoutes.kycBackground,
        builder: (context, state) => const BackgroundCheckScreen(),
      ),
      GoRoute(
        path: AppRoutes.kycFace,
        builder: (context, state) => const FaceEnrollmentScreen(),
      ),
      GoRoute(
        path: AppRoutes.kycFaceCheck,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final contextType = extra?['context'] as String? ?? 'login';
          final assignmentId = extra?['assignmentId'] as String?;
          return FaceCheckScreen(
            contextType: contextType,
            assignmentId: assignmentId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.kycSafetyOnboarding,
        builder: (context, state) => const SafetyOnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.digitalId,
        builder: (context, state) => const DigitalIdScreen(),
      ),
      GoRoute(
        path: AppRoutes.scanVerify,
        builder: (context, state) => const ScanVerifyScreen(),
      ),
      GoRoute(
        path: AppRoutes.trustSafetyCentre,
        builder: (context, state) => const TrustSafetyCentreScreen(),
      ),
      GoRoute(
        path: AppRoutes.trustGovernanceRights,
        builder: (context, state) => const TrustGovernanceRightsScreen(),
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
      GoRoute(
        path: AppRoutes.jobDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final preloaded = state.extra as JobRecommendation?;
          return JobDetailScreen(
            jobId: id,
            preloadedJob: preloaded,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.activeJob,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ActiveJobScreen(assignmentId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.workerSchedule,
        builder: (context, state) => const WorkerScheduleScreen(),
      ),
      GoRoute(
        path: AppRoutes.jobTicket,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return JobTicketScreen(assignmentId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.attendanceScan,
        builder: (context, state) {
          final id = state.uri.queryParameters['assignment_id'];
          return AttendanceScannerScreen(initialAssignmentId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.verifyPresence,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return VerifyPresenceScreen(assignmentId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.jobCompletion,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return JobCompletionScreen(assignmentId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.providerJobNew,
        builder: (context, state) => const PostJobWizardScreen(),
      ),
      GoRoute(
        path: AppRoutes.providerJobApplicants,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return JobApplicantsScreen(jobId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.providerJobEdit,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return PostJobWizardScreen(editJobId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.providerWorkerProfile,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return WorkerProfileScreen(workerId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.providerBooking,
        builder: (context, state) {
          final draft = state.extra as BookingDraft?;
          return GuidedBookingScreen(initialDraft: draft);
        },
      ),
      GoRoute(
        path: AppRoutes.recurringBookings,
        builder: (context, state) => const RecurringBookingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.jobHistory,
        builder: (context, state) => const JobHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.favourites,
        builder: (context, state) => const FavouritesScreen(),
      ),
      GoRoute(
        path: AppRoutes.wallet,
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: AppRoutes.earningsDashboard,
        builder: (context, state) => const EarningsDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.savingsGoals,
        builder: (context, state) => const SavingsGoalsScreen(),
      ),
      GoRoute(
        path: AppRoutes.paymentCheckout,
        builder: (context, state) {
          final refType = state.uri.queryParameters['refType'] ?? (state.extra as Map?)?['refType'] ?? 'assignment';
          final refId = state.uri.queryParameters['refId'] ?? (state.extra as Map?)?['refId'] ?? '';
          final protection = state.uri.queryParameters['protection'] != null
              ? state.uri.queryParameters['protection'] == 'true'
              : (state.extra as Map?)?['protection'] as bool?;
          return PaymentCheckoutScreen(
            refType: refType,
            refId: refId,
            protectionOverride: protection,
          );
        },
      ),
      GoRoute(
        path: '${AppRoutes.paymentStatus}/:id',
        builder: (context, state) {
          final paymentId = state.pathParameters['id'] ?? '';
          return PaymentStatusScreen(paymentId: paymentId);
        },
      ),
      GoRoute(
        path: AppRoutes.produceDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final item = state.extra as ProduceMarketplaceItem?;
          return ProduceDetailScreen(
            listingId: id.isNotEmpty ? id : null,
            item: item,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.cart,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: AppRoutes.orderCheckout,
        builder: (context, state) => const OrderCheckoutWizard(),
      ),
      GoRoute(
        path: AppRoutes.orderConfirmation,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final orders = state.extra as List<ProduceOrder>?;
          return OrderConfirmationScreen(
            orderId: id,
            orders: orders,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.orderTracking,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return OrderTrackingScreen(orderId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.customerOrders,
        builder: (context, state) => const CustomerOrdersScreen(),
      ),
      GoRoute(
        path: AppRoutes.farmerOrders,
        builder: (context, state) => const FarmerOrderBoardScreen(),
      ),
      GoRoute(
        path: AppRoutes.farmerDeliverySlots,
        builder: (context, state) => const DeliverySlotsScreen(),
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
        GoRoute(
          path: AppRoutes.devEdgeHealth,
          builder: (context, state) => const EdgeFunctionHealthScreen(),
        ),
      ],
    ],
  );
});
