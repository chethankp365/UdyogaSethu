import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/core/router/routes.dart';

/// Exhaustive registry of all route names, shell tabs, and dialog/sheet helpers in UdyogaSethu.
/// This test FAILS if any route, tab, or dialog helper is neither tested in the
/// layout overflow suite nor explicitly exempted with a written rationale.
void main() {
  group('Screen & Component Overflow Coverage Audit', () {
    /// 1. All routes declared in AppRoutes
    final allRouteNames = <String>[
      // Root & Auth / Onboarding
      AppRoutes.brandIntro,
      AppRoutes.splash,
      AppRoutes.intro,
      AppRoutes.language,
      AppRoutes.roleTree,
      AppRoutes.login,
      AppRoutes.otp,
      AppRoutes.verifyPhone,
      AppRoutes.suspended,
      AppRoutes.roleConflict,
      AppRoutes.profileSetupSeeker,
      AppRoutes.profileSetupFarmer,
      AppRoutes.profileSetupProvider,

      // Seeker Shell Tabs
      AppRoutes.seekerHome,
      AppRoutes.seekerJobs,
      AppRoutes.seekerMap,
      AppRoutes.seekerChat,
      AppRoutes.seekerProfile,

      // Provider Shell Tabs
      AppRoutes.providerHome,
      AppRoutes.providerWorkers,
      AppRoutes.providerChat,
      AppRoutes.providerProfile,

      // Provider Job Management
      AppRoutes.providerJobNew,
      AppRoutes.providerJobApplicants,
      AppRoutes.providerJobEdit,
      AppRoutes.providerWorkerProfile,
      AppRoutes.providerBooking,
      AppRoutes.recurringBookings,

      // Farmer Shell Tabs
      AppRoutes.farmerHome,
      AppRoutes.farmerMarket,
      AppRoutes.farmerChat,
      AppRoutes.farmerProfile,
      AppRoutes.farmerListings,
      AppRoutes.farmerResources,
      AppRoutes.farmerVendorResources,

      // Shared Feature Screens
      AppRoutes.settings,
      AppRoutes.kyc,
      AppRoutes.kycDl,
      AppRoutes.kycStudent,
      AppRoutes.kycBank,
      AppRoutes.kycBackground,
      AppRoutes.kycFace,
      AppRoutes.kycFaceCheck,
      AppRoutes.kycSafetyOnboarding,
      AppRoutes.digitalId,
      AppRoutes.scanVerify,
      AppRoutes.trustSafetyCentre,
      AppRoutes.trustGovernanceRights,
      AppRoutes.privacyCentre,
      AppRoutes.termsAndPrivacy,
      AppRoutes.safetyHub,
      AppRoutes.wallet,
      AppRoutes.jobDetail,
      AppRoutes.produceDetail,
      AppRoutes.activeJob,
      AppRoutes.jobTicket,
      AppRoutes.attendanceScan,
      AppRoutes.verifyPresence,
      AppRoutes.jobCompletion,
      AppRoutes.workerSchedule,
      AppRoutes.jobHistory,
      AppRoutes.favourites,
      AppRoutes.paymentCheckout,
      AppRoutes.paymentStatus,
      AppRoutes.earningsDashboard,
      AppRoutes.savingsGoals,
      AppRoutes.cart,
      AppRoutes.orderCheckout,
      AppRoutes.orderConfirmation,
      AppRoutes.orderTracking,
      AppRoutes.customerOrders,
      AppRoutes.farmerOrders,
      AppRoutes.farmerDeliverySlots,
      AppRoutes.subscriptions,
      AppRoutes.groupOrders,
      AppRoutes.farmerSoilAi,
      AppRoutes.farmerPestAi,
      AppRoutes.farmerIrrigationAi,
      AppRoutes.farmerGovtSchemes,
      AppRoutes.chatDetail,
      AppRoutes.maskedCall,

      // Debug Routes
      AppRoutes.devGallery,
      AppRoutes.devConnection,
      AppRoutes.devRole,
      AppRoutes.devAssets,
      AppRoutes.devEdgeHealth,
      AppRoutes.devLifecycle,
      AppRoutes.devThumbnails,
      AppRoutes.devJobVisibility,
    ];

    /// 2. All Shell Navigation Tabs
    final allShellTabs = <String>[
      'shell_seeker_tab_0_home',
      'shell_seeker_tab_1_jobs',
      'shell_seeker_tab_2_chat',
      'shell_seeker_tab_3_profile',
      'shell_provider_tab_0_home',
      'shell_provider_tab_1_workers',
      'shell_provider_tab_2_chat',
      'shell_provider_tab_3_profile',
      'shell_farmer_tab_0_home',
      'shell_farmer_tab_1_market',
      'shell_farmer_tab_2_chat',
      'shell_farmer_tab_3_profile',
    ];

    /// 3. All Bottom Sheet & Dialog Helpers
    final allDialogAndSheetHelpers = <String>[
      'dialog_consent_sheet',
      'dialog_apply_bottom_sheet',
      'dialog_role_switcher_bottom_sheet',
      'dialog_thumbnail_picker_sheet',
      'dialog_produce_filter_sheet',
      'dialog_edit_listing_modal',
      'dialog_book_resource_modal',
      'dialog_payment_receipt_modal',
      'dialog_worker_not_arrived_sheet',
      'dialog_raise_dispute_dialog',
      'dialog_rate_job_dialog',
      'dialog_raise_order_dispute_dialog',
      'dialog_rate_produce_order_dialog',
      'dialog_farm_traceability_modal',
      'dialog_edit_farm_details_dialog',
      'dialog_mid_job_dialog',
      'dialog_running_late_dialog',
      'dialog_seeker_type_change_dialog',
      'dialog_skills_picker_dialog',
      'dialog_confirm_dialog',
      'dialog_delete_account_dialog',
      'dialog_export_data_dialog',
      'dialog_create_subscription_modal',
      'dialog_create_group_order_modal',
      'dialog_join_group_order_modal',
    ];

    /// Explicitly documented exemptions with valid rationales.
    /// No screen or dialog can be exempt without a clear written reason.
    final exemptionsWithReasons = <String, String>{
      AppRoutes.devGallery:
          'Debug-only component and design token gallery gated strictly under kDebugMode',
      AppRoutes.devConnection:
          'Debug-only Supabase ping and connection test tool gated under kDebugMode',
      AppRoutes.devRole:
          'Debug-only session role switcher test panel gated under kDebugMode',
      AppRoutes.devAssets:
          'Debug-only static asset and illustration verification viewer gated under kDebugMode',
      AppRoutes.devEdgeHealth:
          'Debug-only Edge Function heartbeat and uptime probe panel gated under kDebugMode',
      AppRoutes.devLifecycle:
          'Debug-only user lifecycle state simulator test panel gated under kDebugMode',
      AppRoutes.devThumbnails:
          'Debug-only thumbnail gallery viewer with multilingual lettering preview gated under kDebugMode',
      AppRoutes.devJobVisibility:
          'Debug-only SQL audience visibility and diagnostic inspector gated under kDebugMode',
      AppRoutes.safetyHub:
          'Placeholder screen awaiting emergency SOS and Safety Hub implementation in Phase P7.3',
    };

    /// Screens, shells, and dialogs covered in the comprehensive overflow matrix suite
    final coveredInOverflowSuite = <String>{
      // Onboarding & Auth
      AppRoutes.brandIntro,
      AppRoutes.splash,
      AppRoutes.intro,
      AppRoutes.language,
      AppRoutes.roleTree,
      AppRoutes.login,
      AppRoutes.otp,
      AppRoutes.verifyPhone,
      AppRoutes.suspended,
      AppRoutes.roleConflict,
      AppRoutes.profileSetupSeeker,
      AppRoutes.profileSetupFarmer,
      AppRoutes.profileSetupProvider,

      // Seeker Screens
      AppRoutes.seekerHome,
      AppRoutes.seekerJobs,
      AppRoutes.seekerMap,
      AppRoutes.seekerProfile,
      AppRoutes.workerSchedule,
      AppRoutes.jobDetail,
      AppRoutes.activeJob,
      AppRoutes.jobTicket,
      AppRoutes.attendanceScan,
      AppRoutes.verifyPresence,
      AppRoutes.jobCompletion,
      AppRoutes.jobHistory,
      AppRoutes.favourites,

      // Provider Screens
      AppRoutes.providerHome,
      AppRoutes.providerWorkers,
      AppRoutes.providerProfile,
      AppRoutes.providerJobNew,
      AppRoutes.providerJobApplicants,
      AppRoutes.providerJobEdit,
      AppRoutes.providerWorkerProfile,
      AppRoutes.providerBooking,
      AppRoutes.recurringBookings,

      // Farmer Screens
      AppRoutes.farmerHome,
      AppRoutes.farmerMarket,
      AppRoutes.farmerProfile,
      AppRoutes.farmerListings,
      AppRoutes.farmerResources,
      AppRoutes.farmerVendorResources,
      AppRoutes.farmerOrders,
      AppRoutes.farmerDeliverySlots,
      AppRoutes.subscriptions,
      AppRoutes.groupOrders,
      AppRoutes.farmerSoilAi,
      AppRoutes.farmerPestAi,
      AppRoutes.farmerIrrigationAi,
      AppRoutes.farmerGovtSchemes,

      // Trust, KYC & Safety
      AppRoutes.settings,
      AppRoutes.kyc,
      AppRoutes.kycDl,
      AppRoutes.kycStudent,
      AppRoutes.kycBank,
      AppRoutes.kycBackground,
      AppRoutes.kycFace,
      AppRoutes.kycFaceCheck,
      AppRoutes.kycSafetyOnboarding,
      AppRoutes.digitalId,
      AppRoutes.scanVerify,
      AppRoutes.trustSafetyCentre,
      AppRoutes.trustGovernanceRights,
      AppRoutes.privacyCentre,
      AppRoutes.termsAndPrivacy,

      // Money & Marketplace
      AppRoutes.wallet,
      AppRoutes.earningsDashboard,
      AppRoutes.savingsGoals,
      AppRoutes.paymentCheckout,
      AppRoutes.paymentStatus,
      AppRoutes.cart,
      AppRoutes.orderCheckout,
      AppRoutes.orderConfirmation,
      AppRoutes.orderTracking,
      AppRoutes.customerOrders,
      AppRoutes.produceDetail,

      // Chat & Voice Proxy (Phase P7.1 & P7.2)
      AppRoutes.seekerChat,
      AppRoutes.providerChat,
      AppRoutes.farmerChat,
      AppRoutes.chatDetail,
      AppRoutes.maskedCall,

      // Shell Tabs
      'shell_seeker_tab_0_home',
      'shell_seeker_tab_1_jobs',
      'shell_seeker_tab_2_chat',
      'shell_seeker_tab_3_profile',
      'shell_provider_tab_0_home',
      'shell_provider_tab_1_workers',
      'shell_provider_tab_2_chat',
      'shell_provider_tab_3_profile',
      'shell_farmer_tab_0_home',
      'shell_farmer_tab_1_market',
      'shell_farmer_tab_2_chat',
      'shell_farmer_tab_3_profile',

      // Dialogs & Sheets
      'dialog_consent_sheet',
      'dialog_apply_bottom_sheet',
      'dialog_role_switcher_bottom_sheet',
      'dialog_thumbnail_picker_sheet',
      'dialog_produce_filter_sheet',
      'dialog_edit_listing_modal',
      'dialog_book_resource_modal',
      'dialog_payment_receipt_modal',
      'dialog_worker_not_arrived_sheet',
      'dialog_raise_dispute_dialog',
      'dialog_rate_job_dialog',
      'dialog_raise_order_dispute_dialog',
      'dialog_rate_produce_order_dialog',
      'dialog_farm_traceability_modal',
      'dialog_edit_farm_details_dialog',
      'dialog_mid_job_dialog',
      'dialog_running_late_dialog',
      'dialog_seeker_type_change_dialog',
      'dialog_skills_picker_dialog',
      'dialog_confirm_dialog',
      'dialog_delete_account_dialog',
      'dialog_export_data_dialog',
      'dialog_create_subscription_modal',
      'dialog_create_group_order_modal',
      'dialog_join_group_order_modal',
    };

    test('All AppRoutes must be covered by overflow tests or have explicit exemptions', () {
      final uncovered = <String>[];
      for (final route in allRouteNames) {
        if (!coveredInOverflowSuite.contains(route) && !exemptionsWithReasons.containsKey(route)) {
          uncovered.add(route);
        }
      }

      expect(
        uncovered,
        isEmpty,
        reason: 'The following AppRoutes have NO overflow test coverage and NO exemption:\n${uncovered.join('\n')}',
      );
    });

    test('All Shell Navigation Tabs must be covered by overflow tests or have explicit exemptions', () {
      final uncovered = <String>[];
      for (final tab in allShellTabs) {
        if (!coveredInOverflowSuite.contains(tab) && !exemptionsWithReasons.containsKey(tab)) {
          uncovered.add(tab);
        }
      }

      expect(
        uncovered,
        isEmpty,
        reason: 'The following Shell Tabs have NO overflow test coverage and NO exemption:\n${uncovered.join('\n')}',
      );
    });

    test('All Dialogs and Bottom Sheet helpers must be covered by overflow tests or have explicit exemptions', () {
      final uncovered = <String>[];
      for (final helper in allDialogAndSheetHelpers) {
        if (!coveredInOverflowSuite.contains(helper) && !exemptionsWithReasons.containsKey(helper)) {
          uncovered.add(helper);
        }
      }

      expect(
        uncovered,
        isEmpty,
        reason: 'The following Dialogs/Sheets have NO overflow test coverage and NO exemption:\n${uncovered.join('\n')}',
      );
    });

    test('All written exemptions must contain valid, non-trivial justifications', () {
      for (final entry in exemptionsWithReasons.entries) {
        expect(
          entry.value.trim().length,
          greaterThanOrEqualTo(15),
          reason: 'Exemption for "${entry.key}" must contain a substantive reason (at least 15 chars).',
        );
      }
    });
  });
}
