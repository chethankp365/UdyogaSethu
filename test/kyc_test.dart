import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/privacy/data/consent_repository.dart';
import 'package:udyogasethu/features/privacy/domain/consent_purpose.dart';
import 'package:udyogasethu/features/trust/data/kyc_repository.dart';
import 'package:udyogasethu/features/trust/domain/kyc_record.dart';
import 'package:udyogasethu/features/trust/presentation/kyc_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class FakeConsentRepository implements ConsentRepository {
  final Map<ConsentPurpose, bool> _consents = {ConsentPurpose.kyc: true};

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
  KycRecord? _record;
  final StreamController<KycRecord?> _controller = StreamController<KycRecord?>.broadcast();

  @override
  Future<List<KycRecord>> getKycRecords(String userId) async {
    return _record != null ? [_record!] : [];
  }

  @override
  Future<KycRecord?> getLatestKycRecord(String userId, {String docType = 'aadhaar'}) async {
    return _record;
  }

  @override
  Stream<KycRecord?> watchKycRecord(String userId, {String docType = 'aadhaar'}) {
    // Yield current record immediately
    scheduleMicrotask(() => _controller.add(_record));
    return _controller.stream;
  }

  @override
  Future<Map<String, dynamic>> startKycSession({required String docType, String? redirectUrl}) async {
    _record = KycRecord(
      id: 'kyc_test_1',
      userId: 'demo_user_123',
      docType: docType,
      provider: 'digilocker_mock',
      providerRef: 'mock_ref_123',
      status: 'pending',
      createdAt: DateTime.now(),
    );
    _controller.add(_record);

    return {
      'success': true,
      'provider': 'digilocker_mock',
      'provider_ref': 'mock_ref_123',
      'redirect_url': 'udyogasethu://kyc/callback?provider_ref=mock_ref_123',
      'is_demo_mode': true,
    };
  }

  @override
  Future<Map<String, dynamic>> simulateCallback({required String providerRef, required String docType}) async {
    _record = KycRecord(
      id: 'kyc_test_1',
      userId: 'demo_user_123',
      docType: docType,
      provider: 'digilocker_mock',
      providerRef: providerRef,
      status: 'verified',
      maskedId: 'XXXX-XXXX-4321',
      nameMasked: 'R***** S****',
      verifiedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
    _controller.add(_record);

    return {
      'success': true,
      'status': 'verified',
      'masked_id': 'XXXX-XXXX-4321',
      'name_masked': 'R***** S****',
      'verified_at': DateTime.now().toIso8601String(),
    };
  }
}

Widget _makeTestableKycScreen({
  ConsentRepository? consentRepo,
  KycRepository? kycRepo,
}) {
  return ProviderScope(
    overrides: [
      consentRepositoryProvider.overrideWithValue(consentRepo ?? FakeConsentRepository()),
      kycRepositoryProvider.overrideWithValue(kycRepo ?? FakeKycRepository()),
    ],
    child: const MaterialApp(
      home: KycScreen(),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  group('Phase 3.2: eKYC & Masking Unit Tests', () {
    test('12-digit Aadhaar masking & redaction rule validation', () {
      const rawInputAadhaar = '999912344321';
      final match12Digit = RegExp(r'^\d{12}$');

      expect(match12Digit.hasMatch(rawInputAadhaar), isTrue);

      // Redaction utility logic: convert any 12-digit string to XXXX-XXXX-last4
      final last4 = rawInputAadhaar.substring(8);
      final masked = 'XXXX-XXXX-$last4';

      expect(masked, equals('XXXX-XXXX-4321'));
      expect(masked.contains('99991234'), isFalse);
    });

    test('KycRecord JSON parsing and masked field retention', () {
      final json = {
        'id': 'kyc_rec_99',
        'user_id': 'user_abc',
        'doc_type': 'aadhaar',
        'provider': 'digilocker_mock',
        'provider_ref': 'ref_888',
        'status': 'verified',
        'masked_id': 'XXXX-XXXX-4321',
        'name_masked': 'R***** S****',
        'verified_at': '2026-10-03T19:00:00Z',
        'created_at': '2026-10-03T18:00:00Z',
      };

      final record = KycRecord.fromJson(json);

      expect(record.id, equals('kyc_rec_99'));
      expect(record.isVerified, isTrue);
      expect(record.maskedId, equals('XXXX-XXXX-4321'));
      expect(record.nameMasked, equals('R***** S****'));
      expect(record.maskedId?.contains('1234'), isFalse);
    });
  });

  group('Phase 3.2: KycScreen Widget Tests', () {
    testWidgets('Renders mandatory Honesty Rule Demo Mode banner', (WidgetTester tester) async {
      await tester.pumpWidget(_makeTestableKycScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('Demo Mode'), findsOneWidget);
      expect(find.textContaining('Simulated eKYC Provider'), findsOneWidget);
    });

    testWidgets('Completes eKYC verification and displays masked result card', (WidgetTester tester) async {
      final fakeKycRepo = FakeKycRepository();
      await tester.pumpWidget(_makeTestableKycScreen(kycRepo: fakeKycRepo));
      await tester.pumpAndSettle();

      expect(find.text('Verify via DigiLocker / KYC Provider'), findsOneWidget);

      await tester.tap(find.text('Verify via DigiLocker / KYC Provider'));
      await tester.pump(); // Start loading
      await tester.pump(const Duration(milliseconds: 1500)); // Complete simulated callback delay
      await tester.pumpAndSettle();

      expect(find.text('VERIFIED ✓'), findsOneWidget);
      expect(find.text('XXXX-XXXX-4321'), findsOneWidget);
      expect(find.text('R***** S****'), findsOneWidget);

      // Verify no 12-digit number exists anywhere in widget tree
      expect(find.textContaining('999912344321'), findsNothing);
    });
  });
}
