import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/privacy/data/consent_repository.dart';
import 'package:udyogasethu/features/privacy/domain/consent_purpose.dart';
import 'package:udyogasethu/features/privacy/presentation/privacy_centre_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class MockTestConsentRepository implements ConsentRepository {
  final Map<ConsentPurpose, ConsentLog?> consents = {};

  MockTestConsentRepository({Map<ConsentPurpose, ConsentLog?>? initial}) {
    if (initial != null) {
      consents.addAll(initial);
    }
  }

  @override
  Future<bool> hasValidConsent(ConsentPurpose purpose) async {
    return consents[purpose]?.granted ?? false;
  }

  @override
  Future<ConsentLog?> getLatestConsent(ConsentPurpose purpose) async {
    return consents[purpose];
  }

  @override
  Future<Map<ConsentPurpose, ConsentLog?>> getAllConsents() async {
    final res = <ConsentPurpose, ConsentLog?>{};
    for (final p in ConsentPurpose.values) {
      res[p] = consents[p];
    }
    return res;
  }

  @override
  Future<void> recordConsent({
    required ConsentPurpose purpose,
    required bool granted,
    Map<String, dynamic>? metadata,
  }) async {
    consents[purpose] = ConsentLog(
      id: 'mock-${purpose.key}',
      userId: 'mock-user-1',
      purpose: purpose.key,
      granted: granted,
      timestamp: DateTime.now(),
      version: '1.0',
      metadata: metadata,
    );
  }

  @override
  Future<void> revokeConsent(ConsentPurpose purpose) async {
    consents[purpose] = ConsentLog(
      id: 'mock-${purpose.key}-revoked',
      userId: 'mock-user-1',
      purpose: purpose.key,
      granted: false,
      timestamp: DateTime.now(),
      version: '1.0',
    );
  }

  @override
  Future<void> withdrawFaceConsent() async {
    consents[ConsentPurpose.face] = ConsentLog(
      id: 'mock-face-withdrawn',
      userId: 'mock-user-1',
      purpose: ConsentPurpose.face.key,
      granted: false,
      timestamp: DateTime.now(),
      version: '1.0',
    );
  }
}

void main() {
  group('ConsentLog Model Tests', () {
    test('Parses real Supabase consent_logs schema row properly', () {
      final json = {
        'id': 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'user_id': 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
        'purpose': 'face',
        'granted': true,
        'version': '1.0',
        'created_at': '2026-10-06T12:00:00.000Z',
      };

      final log = ConsentLog.fromJson(json);
      expect(log.id, equals('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'));
      expect(log.userId, equals('b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22'));
      expect(log.purpose, equals('face'));
      expect(log.granted, isTrue);
      expect(log.version, equals('1.0'));
      expect(log.timestamp.year, equals(2026));

      final outputJson = log.toJson();
      expect(outputJson['purpose'], equals('face'));
      expect(outputJson['granted'], isTrue);
      expect(outputJson['version'], equals('1.0'));
      expect(outputJson['created_at'], isNotNull);
    });

    test('Backward compatible with legacy format (consent_type, granted_at)', () {
      final legacyJson = {
        'consent_type': 'gps',
        'granted': false,
        'granted_at': '2026-09-01T10:00:00.000Z',
      };

      final log = ConsentLog.fromJson(legacyJson);
      expect(log.purpose, equals('gps'));
      expect(log.granted, isFalse);
      expect(log.timestamp.month, equals(9));
    });
  });

  group('SupabaseConsentRepository In-Memory Fallback Tests', () {
    test('Records, reads, and revokes consent in standalone mode', () async {
      final repo = SupabaseConsentRepository(client: null);

      await repo.recordConsent(purpose: ConsentPurpose.kyc, granted: true);
      final hasKyc = await repo.hasValidConsent(ConsentPurpose.kyc);
      expect(hasKyc, isTrue);

      final latest = await repo.getLatestConsent(ConsentPurpose.kyc);
      expect(latest?.granted, isTrue);
      expect(latest?.purpose, equals('kyc'));

      await repo.revokeConsent(ConsentPurpose.kyc);
      final hasKycAfterRevoke = await repo.hasValidConsent(ConsentPurpose.kyc);
      expect(hasKycAfterRevoke, isFalse);

      await repo.recordConsent(purpose: ConsentPurpose.face, granted: true);
      await repo.withdrawFaceConsent();
      final hasFace = await repo.hasValidConsent(ConsentPurpose.face);
      expect(hasFace, isFalse);
    });
  });

  group('PrivacyCentreScreen Widget Tests', () {
    testWidgets('Renders all active consents and live system permission cards', (tester) async {
      final mockRepo = MockTestConsentRepository(initial: {
        ConsentPurpose.kyc: ConsentLog(
          purpose: 'kyc',
          granted: true,
          timestamp: DateTime(2026, 10, 1),
        ),
        ConsentPurpose.face: ConsentLog(
          purpose: 'face',
          granted: true,
          timestamp: DateTime(2026, 10, 1),
        ),
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            consentRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PrivacyCentreScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Check Privacy Centre Header
      expect(find.text('Privacy Centre'), findsWidgets);

      // Check Active Consents Section
      expect(find.text('Active Data Consents'), findsOneWidget);
      expect(find.text('Identity Verification (KYC)'), findsOneWidget);
      expect(find.text('Face Verification & Liveness'), findsOneWidget);
      expect(find.text('GPS Location Services'), findsOneWidget);

      // Check System Permissions Section
      expect(find.text('System Permissions'), findsOneWidget);
      expect(find.text('Camera Access'), findsOneWidget);
      expect(find.text('Device Location (GPS)'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Open App Settings'), findsOneWidget);
    });

    testWidgets('Shows withdrawal dialog and withdraws face consent', (tester) async {
      final mockRepo = MockTestConsentRepository(initial: {
        ConsentPurpose.face: ConsentLog(
          purpose: 'face',
          granted: true,
          timestamp: DateTime(2026, 10, 1),
        ),
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            consentRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PrivacyCentreScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Find "Withdraw Consent" button for face
      final withdrawButtons = find.widgetWithText(OutlinedButton, 'Withdraw Consent');
      expect(withdrawButtons, findsOneWidget);

      await tester.tap(withdrawButtons.first);
      await tester.pumpAndSettle();

      // Check Dialog
      expect(find.text('Withdraw Face Verification Consent?'), findsOneWidget);
      expect(find.text('Withdraw & Erase Data'), findsOneWidget);

      // Tap confirm button
      await tester.tap(find.text('Withdraw & Erase Data'));
      await tester.pumpAndSettle();

      // Consent should now be withdrawn in repository
      final faceConsent = await mockRepo.hasValidConsent(ConsentPurpose.face);
      expect(faceConsent, isFalse);
    });
  });
}
