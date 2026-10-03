import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/features/privacy/data/consent_repository.dart';
import 'package:udyogasethu/features/privacy/domain/consent_purpose.dart';
import 'package:udyogasethu/features/privacy/presentation/consent_sheet.dart';
import 'package:udyogasethu/features/privacy/presentation/privacy_centre_screen.dart';
import 'package:udyogasethu/features/privacy/presentation/terms_privacy_screen.dart';
import 'package:udyogasethu/features/profile/presentation/profile_screen.dart';
import 'package:udyogasethu/features/trust/data/kyc_repository.dart';
import 'package:udyogasethu/features/trust/domain/kyc_record.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class FakeConsentRepository implements ConsentRepository {
  final Map<ConsentPurpose, bool> _consents = {};

  @override
  Future<bool> hasValidConsent(ConsentPurpose purpose) async => _consents[purpose] ?? false;

  @override
  Future<ConsentLog?> getLatestConsent(ConsentPurpose purpose) async {
    final granted = _consents[purpose] ?? false;
    return ConsentLog(purpose: purpose.key, granted: granted, timestamp: DateTime.now());
  }

  @override
  Future<Map<ConsentPurpose, ConsentLog?>> getAllConsents() async {
    final map = <ConsentPurpose, ConsentLog?>{};
    for (final p in ConsentPurpose.values) {
      map[p] = await getLatestConsent(p);
    }
    return map;
  }

  @override
  Future<void> recordConsent({
    required ConsentPurpose purpose,
    required bool granted,
    Map<String, dynamic>? metadata,
  }) async {
    _consents[purpose] = granted;
  }

  @override
  Future<void> revokeConsent(ConsentPurpose purpose) async {
    _consents[purpose] = false;
  }

  @override
  Future<void> withdrawFaceConsent() async {
    _consents[ConsentPurpose.face] = false;
  }
}

class FakeKycRepository implements KycRepository {
  @override
  Future<List<KycRecord>> getKycRecords(String userId) async => [];

  @override
  Future<KycRecord?> getLatestKycRecord(String userId, {String docType = 'aadhaar'}) async => null;

  @override
  Stream<KycRecord?> watchKycRecord(String userId, {String docType = 'aadhaar'}) {
    return Stream.value(null);
  }

  @override
  Future<Map<String, dynamic>> startKycSession({required String docType, String? redirectUrl}) async => {};

  @override
  Future<Map<String, dynamic>> simulateCallback({required String providerRef, required String docType}) async => {};

  @override
  Future<KycRecord> submitDrivingLicence({required String dlNumber, required String vehicleClass, required DateTime expiryDate, List<int>? frontBytes, List<int>? backBytes}) async {
    return KycRecord(id: 'dl', userId: 'user', docType: 'driving_licence', provider: 'mock', status: 'pending', createdAt: DateTime.now());
  }

  @override
  Future<KycRecord> submitStudentVerification({required String collegeName, required String courseName, required String regUsn, List<int>? cardBytes}) async {
    return KycRecord(id: 'stu', userId: 'user', docType: 'college_id', provider: 'mock', status: 'pending', createdAt: DateTime.now());
  }

  @override
  Future<KycRecord> submitBankUpi({required String type, required String value, String? ifsc}) async {
    return KycRecord(id: 'bank', userId: 'user', docType: type, provider: 'mock', status: 'verified', createdAt: DateTime.now());
  }

  @override
  Future<KycRecord> requestBackgroundCheck() async {
    return KycRecord(id: 'bgc', userId: 'user', docType: 'background_check', provider: 'mock', status: 'pending', createdAt: DateTime.now());
  }
}

Widget _makeTestableWidget(Widget child, {ConsentRepository? repo, KycRepository? kycRepo}) {
  return ProviderScope(
    overrides: [
      consentRepositoryProvider.overrideWithValue(repo ?? FakeConsentRepository()),
      kycRepositoryProvider.overrideWithValue(kycRepo ?? FakeKycRepository()),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  group('Phase 3.1 Consent & Privacy Unit Tests', () {
    test('ConsentPurpose key and enum conversions work correctly', () {
      expect(ConsentPurpose.kyc.key, 'kyc');
      expect(ConsentPurpose.face.key, 'face');
      expect(ConsentPurpose.gps.key, 'gps');
      expect(ConsentPurpose.notifications.key, 'notifications');
      expect(ConsentPurpose.ads.key, 'ads');

      expect(ConsentPurpose.fromKey('kyc'), ConsentPurpose.kyc);
      expect(ConsentPurpose.fromKey('FACE'), ConsentPurpose.face);
      expect(ConsentPurpose.fromKey('gps'), ConsentPurpose.gps);
      expect(ConsentPurpose.fromKey('unknown'), ConsentPurpose.kyc);
    });

    test('ConsentPurposeDetails provides plain language details for all 5 purposes', () {
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

    test('FakeConsentRepository in-memory works for record, check & revoke', () async {
      final repo = FakeConsentRepository();

      // Initially no consent
      final hasKycBefore = await repo.hasValidConsent(ConsentPurpose.kyc);
      expect(hasKycBefore, isFalse);

      // Record consent
      await repo.recordConsent(purpose: ConsentPurpose.kyc, granted: true);
      final hasKycAfter = await repo.hasValidConsent(ConsentPurpose.kyc);
      expect(hasKycAfter, isTrue);

      // Revoke consent
      await repo.revokeConsent(ConsentPurpose.kyc);
      final hasKycRevoked = await repo.hasValidConsent(ConsentPurpose.kyc);
      expect(hasKycRevoked, isFalse);
    });
  });

  group('Phase 3.1 Widget Tests', () {
    testWidgets('ConsentSheet renders purpose details and handles I Agree tap', (tester) async {
      bool? consentResult;

      await tester.pumpWidget(
        _makeTestableWidget(
          Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    consentResult = await ConsentSheet.show(context, ConsentPurpose.kyc);
                  },
                  child: const Text('Open Sheet'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify sheet header & sections
      expect(find.text('Data Processing Consent'), findsOneWidget);
      expect(find.text('Identity Verification (KYC)'), findsOneWidget);
      expect(find.text('What is collected'), findsOneWidget);
      expect(find.text('Why it is collected'), findsOneWidget);
      expect(find.text('I Agree & Consent'), findsOneWidget);

      // Tap Agree
      await tester.tap(find.text('I Agree & Consent'));
      await tester.pumpAndSettle();

      expect(consentResult, isTrue);
    });

    testWidgets('ProfileScreen renders header and working links for all roles', (tester) async {
      await tester.pumpWidget(
        _makeTestableWidget(const ProfileScreen(role: UserRole.seeker)),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Job Seeker'), findsOneWidget);
      expect(find.text('Privacy Centre'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Terms & Privacy Policy'), findsOneWidget);
    });

    testWidgets('PrivacyCentreScreen renders 5 consent cards and system permissions', (tester) async {
      await tester.pumpWidget(
        _makeTestableWidget(const PrivacyCentreScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Privacy Centre'), findsAtLeastNWidgets(1));
      expect(find.text('Active Data Consents'), findsOneWidget);
      expect(find.text('Identity Verification (KYC)'), findsOneWidget);
      expect(find.text('Face Verification & Liveness'), findsOneWidget);
      expect(find.text('System Permissions'), findsOneWidget);
    });

    testWidgets('TermsPrivacyScreen renders mandatory draft notice banner', (tester) async {
      await tester.pumpWidget(
        _makeTestableWidget(const TermsPrivacyScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Terms & Privacy Policy'), findsOneWidget);
      expect(find.textContaining('Draft'), findsOneWidget);
      expect(find.textContaining('One Account = One Role Policy'), findsOneWidget);
    });
  });
}
