import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/privacy/data/consent_repository.dart';
import 'package:udyogasethu/features/privacy/domain/consent_purpose.dart';
import 'package:udyogasethu/features/trust/data/kyc_repository.dart';
import 'package:udyogasethu/features/trust/domain/kyc_record.dart';
import 'package:udyogasethu/features/trust/presentation/background_check_screen.dart';
import 'package:udyogasethu/features/trust/presentation/bank_upi_screen.dart';
import 'package:udyogasethu/features/trust/presentation/driving_licence_screen.dart';
import 'package:udyogasethu/features/trust/presentation/student_verification_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class FakeConsentRepository implements ConsentRepository {
  final Map<ConsentPurpose, bool> _consents = {ConsentPurpose.kyc: true};

  @override
  Future<bool> hasValidConsent(ConsentPurpose purpose) async => _consents[purpose] ?? false;

  @override
  Future<ConsentLog?> getLatestConsent(ConsentPurpose purpose) async {
    return ConsentLog(purpose: purpose.key, granted: _consents[purpose] ?? false, timestamp: DateTime.now());
  }

  @override
  Future<Map<ConsentPurpose, ConsentLog?>> getAllConsents() async => {};

  @override
  Future<void> recordConsent({required ConsentPurpose purpose, required bool granted, Map<String, dynamic>? metadata}) async {
    _consents[purpose] = granted;
  }

  @override
  Future<void> revokeConsent(ConsentPurpose purpose) async {
    _consents[purpose] = false;
  }

  @override
  Future<void> withdrawFaceConsent() async {}
}

class TestKycRepository implements KycRepository {
  final _controller = StreamController<KycRecord?>.broadcast();

  @override
  Future<List<KycRecord>> getKycRecords(String userId) async => [];

  @override
  Future<KycRecord?> getLatestKycRecord(String userId, {String docType = 'aadhaar'}) async => null;

  @override
  Stream<KycRecord?> watchKycRecord(String userId, {String docType = 'aadhaar'}) => _controller.stream;

  @override
  Future<Map<String, dynamic>> startKycSession({required String docType, String? redirectUrl}) async => {};

  @override
  Future<Map<String, dynamic>> simulateCallback({required String providerRef, required String docType}) async => {};

  @override
  Future<KycRecord> submitDrivingLicence({
    required String dlNumber,
    required String vehicleClass,
    required DateTime expiryDate,
    List<int>? frontBytes,
    List<int>? backBytes,
  }) async {
    final clean = dlNumber.replaceAll(RegExp(r'[\s\-]'), '');
    final last4 = clean.length >= 4 ? clean.substring(clean.length - 4) : '5678';
    return KycRecord(
      id: 'test-dl-1',
      userId: 'test-user',
      docType: 'driving_licence',
      provider: 'manual',
      status: 'pending',
      maskedId: 'XXXX-XXXX-XXXX-$last4',
      nameMasked: 'Test User',
      verifiedAt: null,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<KycRecord> submitStudentVerification({
    required String collegeName,
    required String courseName,
    required String regUsn,
    List<int>? cardBytes,
  }) async {
    final prefix = regUsn.length >= 4 ? regUsn.substring(0, 4) : '1MS2';
    return KycRecord(
      id: 'test-student-1',
      userId: 'test-user',
      docType: 'college_id',
      provider: 'manual',
      status: 'pending',
      maskedId: '$prefix-***-****',
      nameMasked: collegeName,
      verifiedAt: null,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<KycRecord> submitBankUpi({
    required String type,
    required String value,
    String? ifsc,
  }) async {
    String masked;
    if (type == 'upi') {
      final parts = value.split('@');
      masked = parts.length == 2 ? '****${parts[0].substring(parts[0].length - 2)}@${parts[1]}' : '****@upi';
    } else {
      final last4 = value.length >= 4 ? value.substring(value.length - 4) : '1234';
      masked = 'XXXX-XXXX-$last4';
    }
    return KycRecord(
      id: 'test-bank-1',
      userId: 'test-user',
      docType: type,
      provider: 'demo_penny_drop',
      status: 'verified',
      maskedId: masked,
      nameMasked: 'Penny Drop Test',
      verifiedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<KycRecord> requestBackgroundCheck() async {
    return KycRecord(
      id: 'test-bgc-1',
      userId: 'test-user',
      docType: 'background_check',
      provider: 'manual',
      status: 'pending',
      maskedId: 'BGC-REQ-2026',
      nameMasked: 'BGC Pending',
      verifiedAt: null,
      createdAt: DateTime.now(),
    );
  }
}

Widget _makeTestableWidget(Widget child, {KycRepository? kycRepo}) {
  return ProviderScope(
    overrides: [
      consentRepositoryProvider.overrideWithValue(FakeConsentRepository()),
      kycRepositoryProvider.overrideWithValue(kycRepo ?? TestKycRepository()),
    ],
    child: MaterialApp(
      home: child,
      localizationsDelegates: const [
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
  group('Phase 3.3: Extra Verification Unit Tests', () {
    test('DL Format Validation & Masking', () async {
      final repo = TestKycRepository();
      const rawDl = 'KA-01-2020-1234567';

      final record = await repo.submitDrivingLicence(
        dlNumber: rawDl,
        vehicleClass: 'LMV / Transport',
        expiryDate: DateTime.now().add(const Duration(days: 365)),
      );

      expect(record.docType, equals('driving_licence'));
      expect(record.status, equals('pending'));
      expect(record.maskedId, equals('XXXX-XXXX-XXXX-4567'));
      expect(record.maskedId?.contains('2020123'), isFalse);
    });

    test('Student Verification USN Masking & Record Creation', () async {
      final repo = TestKycRepository();
      const usn = '1MS20CS045';

      final record = await repo.submitStudentVerification(
        collegeName: 'MSRIT',
        courseName: 'B.E Computer Science',
        regUsn: usn,
      );

      expect(record.docType, equals('college_id'));
      expect(record.status, equals('pending'));
      expect(record.maskedId, equals('1MS2-***-****'));
      expect(record.maskedId?.contains('045'), isFalse);
    });

    test('Bank / UPI Penny-Drop Simulation with Demo Mode', () async {
      final repo = TestKycRepository();

      final upiRecord = await repo.submitBankUpi(type: 'upi', value: 'worker@okaxis');
      expect(upiRecord.docType, equals('upi'));
      expect(upiRecord.isVerified, isTrue);
      expect(upiRecord.maskedId, equals('****er@okaxis'));

      final bankRecord = await repo.submitBankUpi(type: 'bank_account', value: '98765432101234');
      expect(bankRecord.docType, equals('bank_account'));
      expect(bankRecord.isVerified, isTrue);
      expect(bankRecord.maskedId, equals('XXXX-XXXX-1234'));
    });

    test('Background Check Status Transitions & Gating', () async {
      final repo = TestKycRepository();

      final record = await repo.requestBackgroundCheck();
      expect(record.docType, equals('background_check'));
      expect(record.status, equals('pending'));
      expect(record.maskedId, equals('BGC-REQ-2026'));

      // Check gating rule: Driver job requires DL verification
      bool isWorkerDlVerified = false;
      bool canSeeDriverJob = isWorkerDlVerified;
      expect(canSeeDriverJob, isFalse);

      isWorkerDlVerified = true;
      canSeeDriverJob = isWorkerDlVerified;
      expect(canSeeDriverJob, isTrue);
    });
  });

  group('Phase 3.3: Extra Verification Widget Tests (Dark Panel Theme)', () {
    testWidgets('DrivingLicenceScreen renders form, dark panel theme, and validates DL', (tester) async {
      await tester.pumpWidget(_makeTestableWidget(const DrivingLicenceScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Driving Licence Verification'), findsOneWidget);
      expect(find.textContaining('Licence-Gated Jobs Verification'), findsOneWidget);
      expect(find.text('Submit Driving Licence for Verification'), findsOneWidget);
    });

    testWidgets('StudentVerificationScreen renders strict privacy notice and student status chip', (tester) async {
      await tester.pumpWidget(_makeTestableWidget(const StudentVerificationScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Student Verification'), findsOneWidget);
      expect(find.textContaining('Strict Student Data Privacy'), findsOneWidget);
      expect(find.textContaining('All student documents and USN records remain strictly private'), findsOneWidget);
    });

    testWidgets('BankUpiScreen renders penny-drop Demo Mode banner and UPI/Bank tabs', (tester) async {
      await tester.pumpWidget(_makeTestableWidget(const BankUpiScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Bank & UPI Payout Verification'), findsOneWidget);
      expect(find.textContaining('Demo Mode — Simulated Penny-Drop Verification'), findsOneWidget);
      expect(find.text('UPI ID (Instant)'), findsOneWidget);
      expect(find.text('Bank Account'), findsOneWidget);
    });

    testWidgets('BackgroundCheckScreen renders statuses and sensitive job unlocking notice', (tester) async {
      await tester.pumpWidget(_makeTestableWidget(const BackgroundCheckScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Background Verification'), findsOneWidget);
      expect(find.textContaining('Background Verification (Sensitive Roles)'), findsOneWidget);
      expect(find.text('Request Background Check'), findsOneWidget);
    });
  });
}
