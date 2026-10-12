import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/services/offline_cache_service.dart';
import 'package:udyogasethu/features/onboarding/data/role_tree_service.dart';
import 'package:udyogasethu/features/onboarding/domain/pending_role_selection.dart';
import 'package:udyogasethu/features/payments/domain/payment_bill_summary.dart';
import 'package:udyogasethu/features/privacy/domain/consent_purpose.dart';
import 'package:udyogasethu/features/privacy/presentation/consent_sheet.dart';
import 'package:udyogasethu/features/voice/domain/voice_intent.dart';
import 'package:udyogasethu/features/voice/intent/intent_engine.dart';
import 'package:udyogasethu/features/wallet/domain/wallet_balance.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // =========================================================================
  // 1. ROLE-TREE STATE MACHINE & ROUTE GUARDS
  // =========================================================================
  group('P10.4 Unit - Role-Tree State Machine & Transitions', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('Initial state begins at Step 1 and cannot continue', () {
      final state = container.read(roleTreeProvider);
      expect(state.currentStep, 1);
      expect(state.selectedCategory, isNull);
      expect(state.selectedRole, isNull);
      expect(state.canContinue, isFalse);
    });

    test('Path: Selecting Farmer finishes at Step 1 immediately', () {
      final notifier = container.read(roleTreeProvider.notifier);
      notifier.selectCategory('farmer');

      final state = container.read(roleTreeProvider);
      expect(state.currentStep, 1);
      expect(state.selectedCategory, 'farmer');
      expect(state.selectedRole, UserRole.farmer);
      expect(state.canContinue, isTrue);
      expect(state.completedSelection?.role, UserRole.farmer);
    });

    test('Path: Worker -> Provider finishes selection at Step 2', () {
      final notifier = container.read(roleTreeProvider.notifier);
      notifier.selectCategory('worker');
      notifier.confirmStep1();

      var state = container.read(roleTreeProvider);
      expect(state.currentStep, 2);
      expect(state.canContinue, isFalse);

      notifier.selectRole(UserRole.provider);
      state = container.read(roleTreeProvider);
      expect(state.selectedRole, UserRole.provider);
      expect(state.canContinue, isTrue);
      expect(state.completedSelection?.role, UserRole.provider);
    });

    test('Path: Worker -> Seeker -> Informal Subtype finishes at Step 3', () {
      final notifier = container.read(roleTreeProvider.notifier);
      notifier.selectCategory('worker');
      notifier.confirmStep1();
      notifier.selectRole(UserRole.seeker);
      notifier.confirmStep2();

      var state = container.read(roleTreeProvider);
      expect(state.currentStep, 3);
      expect(state.canContinue, isFalse);

      notifier.selectSeekerType(SeekerType.informal);
      state = container.read(roleTreeProvider);
      expect(state.selectedSeekerType, SeekerType.informal);
      expect(state.canContinue, isTrue);
      expect(state.completedSelection?.role, UserRole.seeker);
      expect(state.completedSelection?.seekerType, SeekerType.informal);
    });

    test('Back navigation resets downstream choices cleanly', () {
      final notifier = container.read(roleTreeProvider.notifier);
      notifier.selectCategory('worker');
      notifier.confirmStep1();
      notifier.selectRole(UserRole.seeker);
      notifier.confirmStep2();
      notifier.selectSeekerType(SeekerType.student);

      expect(container.read(roleTreeProvider).currentStep, 3);

      notifier.goBack();
      var state = container.read(roleTreeProvider);
      expect(state.currentStep, 2);
      expect(state.selectedSeekerType, isNull);

      notifier.goBack();
      state = container.read(roleTreeProvider);
      expect(state.currentStep, 1);
      expect(state.selectedRole, isNull);
    });
  });

  group('P10.4 Unit - Session States & Guards', () {
    test('AppSessionData defaults and state immutability', () {
      const session = AppSessionData(
        status: AuthSessionStatus.signedOut,
        activeRole: UserRole.seeker,
      );

      expect(session.status, AuthSessionStatus.signedOut);
      expect(session.activeRole, UserRole.seeker);
      expect(session.activeRole == UserRole.farmer, isFalse);
      expect(session.activeRole == UserRole.provider, isFalse);
      expect(session.activeRole == UserRole.seeker, isTrue);
    });

    test('AppSessionData role helpers work correctly for all roles', () {
      const farmerSession = AppSessionData(
        status: AuthSessionStatus.ready,
        activeRole: UserRole.farmer,
      );
      expect(farmerSession.activeRole, UserRole.farmer);

      const providerSession = AppSessionData(
        status: AuthSessionStatus.ready,
        activeRole: UserRole.provider,
      );
      expect(providerSession.activeRole, UserRole.provider);
    });

    test('AppSessionData copyWith updates properties accurately', () {
      const initial = AppSessionData(
        status: AuthSessionStatus.booting,
        activeRole: UserRole.seeker,
      );
      final updated = initial.copyWith(
        status: AuthSessionStatus.ready,
        activeRole: UserRole.farmer,
      );

      expect(updated.status, AuthSessionStatus.ready);
      expect(updated.activeRole, UserRole.farmer);
    });
  });

  // =========================================================================
  // 2. VOICE INTENT-ENGINE PHRASES FOR ALL 5 INDIC LANGUAGES
  // =========================================================================
  group('P10.4 Unit - Voice Intent-Engine 5 Languages', () {
    test('English: intent parsing and routing', () {
      final resJobs = IntentEngine.parse('find plumber jobs near me', language: 'en');
      expect(resJobs.type, VoiceIntentType.findJobs);
      expect(resJobs.targetRoute, contains('/jobs?category=plumber'));

      final resWorkers = IntentEngine.parse('hire nearby electrician worker', language: 'en');
      expect(resWorkers.type, VoiceIntentType.findWorkers);
      expect(resWorkers.targetRoute, contains('/provider/workers'));

      final resEarnings = IntentEngine.parse('show my today earnings', language: 'en');
      expect(resEarnings.type, VoiceIntentType.checkEarnings);
      expect(resEarnings.targetRoute, '/wallet');

      final resSafety = IntentEngine.parse('emergency sos safety hub', language: 'en');
      expect(resSafety.type, VoiceIntentType.openSafety);
      expect(resSafety.targetRoute, '/safety/hub');

      final resSettings = IntentEngine.parse('Open app settings', language: 'en');
      expect(resSettings.type, VoiceIntentType.openSettings);
      expect(resSettings.targetRoute, '/settings');
    });

    test('Kannada (kn): intent parsing and routing', () {
      final resJobs = IntentEngine.parse('ಪ್ಲಂಬರ್ ಕೆಲಸ ಬೇಕು', language: 'kn');
      expect(resJobs.type, VoiceIntentType.findJobs);
      expect(resJobs.targetRoute, contains('/jobs?category=plumber'));

      final resWorkers = IntentEngine.parse('ಸಮೀಪದ ಕೆಲಸಗಾರರನ್ನು ಹುಡುಕಿ', language: 'kn');
      expect(resWorkers.type, VoiceIntentType.findWorkers);
      expect(resWorkers.targetRoute, contains('/provider/workers'));

      final resProduce = IntentEngine.parse('ಟೊಮೆಟೊ ಮಾರುವ ರೈತರು', language: 'kn');
      expect(resProduce.type, VoiceIntentType.searchProduce);
      expect(resProduce.parameters.produce, 'tomato');

      final resWallet = IntentEngine.parse('ವಾಲೆಟ್ ಬ್ಯಾಲೆನ್ಸ್ ತೆರೆಯಿರಿ', language: 'kn');
      expect(resWallet.type, VoiceIntentType.openWallet);
      expect(resWallet.targetRoute, '/wallet');

      final resSafety = IntentEngine.parse('ತುರ್ತು ಸುರಕ್ಷತೆ ಸಹಾಯ', language: 'kn');
      expect(resSafety.type, VoiceIntentType.openSafety);
      expect(resSafety.targetRoute, '/safety/hub');
    });

    test('Hindi (hi): intent parsing and routing', () {
      final resJobs = IntentEngine.parse('मुझे प्लंबर का काम चाहिए', language: 'hi');
      expect(resJobs.type, VoiceIntentType.findJobs);
      expect(resJobs.targetRoute, contains('/jobs?category=plumber'));

      final resWorkers = IntentEngine.parse('मजदूर ढूंढो', language: 'hi');
      expect(resWorkers.type, VoiceIntentType.findWorkers);
      expect(resWorkers.targetRoute, contains('/provider/workers'));

      final resEarnings = IntentEngine.parse('आज की कमाई दिखाओ', language: 'hi');
      expect(resEarnings.type, VoiceIntentType.checkEarnings);
      expect(resEarnings.targetRoute, '/wallet');

      final resSafety = IntentEngine.parse('सुरक्षा सहायता केंद्र', language: 'hi');
      expect(resSafety.type, VoiceIntentType.openSafety);
      expect(resSafety.targetRoute, '/safety/hub');
    });

    test('Telugu (te): intent parsing and routing', () {
      final resJobs = IntentEngine.parse('ప్లంబర్ పని కావాలి', language: 'te');
      expect(resJobs.type, VoiceIntentType.findJobs);
      expect(resJobs.targetRoute, contains('/jobs?category=plumber'));

      final resWorkers = IntentEngine.parse('కూలీలను వెతకండి', language: 'te');
      expect(resWorkers.type, VoiceIntentType.findWorkers);
      expect(resWorkers.targetRoute, contains('/provider/workers'));

      final resProduce = IntentEngine.parse('టమోటా రైతులు', language: 'te');
      expect(resProduce.type, VoiceIntentType.searchProduce);
      expect(resProduce.parameters.produce, 'tomato');

      final resEarnings = IntentEngine.parse('ఈ రోజు సంపాదన చూపించు', language: 'te');
      expect(resEarnings.type, VoiceIntentType.checkEarnings);
      expect(resEarnings.targetRoute, '/wallet');
    });

    test('Tamil (ta): intent parsing and routing', () {
      final resJobs = IntentEngine.parse('பிளம்பர் வேலை வேண்டும்', language: 'ta');
      expect(resJobs.type, VoiceIntentType.findJobs);
      expect(resJobs.targetRoute, contains('/jobs?category=plumber'));

      final resWorkers = IntentEngine.parse('வேலையாட்களை தேடுங்கள்', language: 'ta');
      expect(resWorkers.type, VoiceIntentType.findWorkers);
      expect(resWorkers.targetRoute, contains('/provider/workers'));

      final resProduce = IntentEngine.parse('தக்காளி விற்கும் விவசாயிகள்', language: 'ta');
      expect(resProduce.type, VoiceIntentType.searchProduce);
      expect(resProduce.parameters.produce, 'tomato');

      final resEarnings = IntentEngine.parse('இன்றைய வருமானம் காட்டு', language: 'ta');
      expect(resEarnings.type, VoiceIntentType.checkEarnings);
      expect(resEarnings.targetRoute, '/wallet');
    });
  });

  // =========================================================================
  // 3. PRICE & PLATFORM-FEE CALCULATIONS
  // =========================================================================
  group('P10.4 Unit - Price & Platform-Fee Calculations', () {
    test('PaymentBillSummary converts paise to rupees with precision', () {
      const summary = PaymentBillSummary(
        baseAmountPaise: 50000,
        platformFeePaise: 2500,
        protectionFeePaise: 500,
        totalPaise: 53000,
        isProtected: true,
        description: 'Tractor Booking 1 Day',
      );

      expect(summary.baseAmountRupees, 500.0);
      expect(summary.platformFeeRupees, 25.0);
      expect(summary.protectionFeeRupees, 5.0);
      expect(summary.totalRupees, 530.0);
      expect(summary.isProtected, isTrue);
    });

    test('Serialization and deserialization of PaymentBillSummary maintains exact paise', () {
      final json = {
        'base_amount_paise': 125050,
        'platform_fee_paise': 6252,
        'protection_fee_paise': 0,
        'total_paise': 131302,
        'is_protected': false,
        'description': 'Produce Order Wholesale',
      };

      final parsed = PaymentBillSummary.fromJson(json);
      expect(parsed.baseAmountPaise, 125050);
      expect(parsed.platformFeePaise, 6252);
      expect(parsed.totalPaise, 131302);
      expect(parsed.toJson(), json);
    });

    test('Indian number grouping format behaves according to lakhs and crores standard', () {
      expect(WalletBalance.formatIndianCurrency(0), '₹0');
      expect(WalletBalance.formatIndianCurrency(50000), '₹500');
      expect(WalletBalance.formatIndianCurrency(1525000), '₹15,250');
      expect(WalletBalance.formatIndianCurrency(15000000), '₹1,50,000');
      expect(WalletBalance.formatIndianCurrency(123456789), '₹12,34,567');
      expect(WalletBalance.formatIndianCurrency(123456789, showDecimals: true), '₹12,34,567.89');
      expect(WalletBalance.formatIndianCurrency(-50000), '-₹500');
      expect(WalletBalance.formatIndianCurrency(100000, includeSymbol: false), '1,000');
    });
  });

  // =========================================================================
  // 4. OFFLINE QUEUE RULES & PROHIBITED ACTIONS
  // =========================================================================
  group('P10.4 Unit - Offline Queue Strict Prohibitions', () {
    late OfflineCacheService offlineService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      offlineService = OfflineCacheService();
    });

    test('Prohibited offline actions list contains all critical financial & verification operations', () {
      const expectedProhibited = [
        'payment',
        'escrow_release',
        'upi_checkout',
        'verify_qr',
        'scan_ticket',
        'attendance_selfie',
        'ekyc_verify',
        'payout_withdrawal',
      ];

      for (final action in expectedProhibited) {
        expect(
          OfflineCacheService.prohibitedOfflineActions.contains(action),
          isTrue,
          reason: 'Expected $action to be prohibited offline',
        );
      }
    });

    test('Attempting to queue payment offline throws BlockedOfflineActionException', () async {
      expect(
        () => offlineService.enqueueAction(
          actionType: 'payment',
          payload: {'amount_paise': 50000},
        ),
        throwsA(isA<BlockedOfflineActionException>()),
      );
    });

    test('Attempting to queue escrow_release offline throws BlockedOfflineActionException', () async {
      expect(
        () => offlineService.enqueueAction(
          actionType: 'escrow_release',
          payload: {'job_id': 'job-123'},
        ),
        throwsA(isA<BlockedOfflineActionException>()),
      );
    });

    test('Attempting to queue upi_checkout or payout_withdrawal offline throws BlockedOfflineActionException', () async {
      expect(
        () => offlineService.enqueueAction(
          actionType: 'upi_checkout',
          payload: {'vpa': 'farmer@upi'},
        ),
        throwsA(isA<BlockedOfflineActionException>()),
      );

      expect(
        () => offlineService.enqueueAction(
          actionType: 'payout_withdrawal',
          payload: {'amount_paise': 10000},
        ),
        throwsA(isA<BlockedOfflineActionException>()),
      );
    });

    test('Attempting to queue QR ticket verification or ekyc offline throws BlockedOfflineActionException', () async {
      expect(
        () => offlineService.enqueueAction(
          actionType: 'verify_qr',
          payload: {'ticket_code': 'TKT-99'},
        ),
        throwsA(isA<BlockedOfflineActionException>()),
      );

      expect(
        () => offlineService.enqueueAction(
          actionType: 'ekyc_verify',
          payload: {'aadhaar_hash': 'abc123hash'},
        ),
        throwsA(isA<BlockedOfflineActionException>()),
      );
    });

    test('Safe non-financial actions queue successfully', () async {
      await offlineService.enqueueAction(
        actionType: 'save_draft_profile',
        payload: {'name': 'Ramesh Kumar', 'target_id': 'profile-draft-1'},
      );

      final queue = await offlineService.getQueuedActions();
      expect(queue.length, 1);
      expect(queue.first.actionType, 'save_draft_profile');
      expect(queue.first.payload['name'], 'Ramesh Kumar');
    });
  });

  // =========================================================================
  // 5. CONSENT HELPER BEHAVIOUR & RIGHTS
  // =========================================================================
  group('P10.4 Unit - Consent Helper Behaviour', () {
    test('ConsentPurpose details exist for all purposes', () {
      for (final purpose in ConsentPurpose.values) {
        final details = ConsentPurposeDetails.getDetails(purpose);
        expect(details.title, isNotEmpty);
        expect(details.what, isNotEmpty);
        expect(details.why, isNotEmpty);
        expect(details.howLong, isNotEmpty);
        expect(details.whoCanSee, isNotEmpty);
        expect(details.howToWithdraw, isNotEmpty);
      }
    });

    test('ConsentPurpose key serialization and lookup roundtrip', () {
      for (final purpose in ConsentPurpose.values) {
        expect(ConsentPurpose.fromKey(purpose.key), equals(purpose));
      }
      expect(ConsentPurpose.fromKey('unknown_purpose'), equals(ConsentPurpose.kyc));
    });

    test('Face and KYC biometrics require explicit retention disclosures', () {
      final faceDetails = ConsentPurposeDetails.getDetails(ConsentPurpose.face);
      expect(faceDetails.title.toLowerCase(), contains('face'));
      expect(faceDetails.howToWithdraw, isNotEmpty);

      final kycDetails = ConsentPurposeDetails.getDetails(ConsentPurpose.kyc);
      expect(kycDetails.title.toUpperCase(), contains('KYC'));
      expect(kycDetails.howLong, contains('Retained'));
    });
  });
}
