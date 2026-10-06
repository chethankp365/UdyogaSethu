import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/core/router/app_router.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/features/onboarding/presentation/brand_intro_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/splash_screen.dart';
import 'package:udyogasethu/features/privacy/data/consent_repository.dart';
import 'package:udyogasethu/features/privacy/domain/consent_purpose.dart';
import 'package:udyogasethu/features/profile/presentation/profile_screen.dart';
import 'package:udyogasethu/features/trust/data/kyc_repository.dart';
import 'package:udyogasethu/features/trust/domain/kyc_record.dart';
import 'package:udyogasethu/features/trust/domain/verification_visibility.dart';
import 'package:udyogasethu/features/trust/presentation/background_check_screen.dart';
import 'package:udyogasethu/features/trust/presentation/bank_upi_screen.dart';
import 'package:udyogasethu/features/trust/presentation/driving_licence_screen.dart';
import 'package:udyogasethu/features/trust/presentation/student_verification_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class FakeConsentRepository implements ConsentRepository {
  @override
  Future<bool> hasValidConsent(ConsentPurpose purpose) async => true;

  @override
  Future<ConsentLog?> getLatestConsent(ConsentPurpose purpose) async => null;

  @override
  Future<Map<ConsentPurpose, ConsentLog?>> getAllConsents() async => {};

  @override
  Future<void> recordConsent({required ConsentPurpose purpose, required bool granted, Map<String, dynamic>? metadata}) async {}

  @override
  Future<void> revokeConsent(ConsentPurpose purpose) async {}

  @override
  Future<void> withdrawFaceConsent() async {}
}

class FakeKycRepository implements KycRepository {
  @override
  Future<List<KycRecord>> getKycRecords(String userId) async => [];

  @override
  Future<KycRecord?> getLatestKycRecord(String userId, {String docType = 'aadhaar'}) async => null;

  @override
  Stream<KycRecord?> watchKycRecord(String userId, {String docType = 'aadhaar'}) async* {
    yield null;
  }

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
  }) async => throw UnimplementedError();

  @override
  Future<KycRecord> submitStudentVerification({
    required String collegeName,
    required String courseName,
    required String regUsn,
    List<int>? cardBytes,
  }) async => throw UnimplementedError();

  @override
  Future<KycRecord> submitBankUpi({
    required String type,
    required String value,
    String? ifsc,
  }) async => throw UnimplementedError();

  @override
  Future<KycRecord> requestBackgroundCheck() async => throw UnimplementedError();

  @override
  Future<KycRecord> enrollFace({
    required List<double> embedding,
    required bool livenessPassed,
    required List<String> challenges,
    List<int>? photoBytes,
  }) async => throw UnimplementedError();
}

class FakeAppSessionNotifier extends AppSessionNotifier {
  final UserRole initialRole;
  final String? initialSeekerType;

  FakeAppSessionNotifier(this.initialRole, this.initialSeekerType);

  @override
  AppSessionData build() {
    return AppSessionData(
      status: AuthSessionStatus.ready,
      activeRole: initialRole,
      seekerType: initialSeekerType,
    );
  }
}

Widget _makeTestableProfile(UserRole role, String? seekerType) {
  return ProviderScope(
    overrides: [
      consentRepositoryProvider.overrideWithValue(FakeConsentRepository()),
      kycRepositoryProvider.overrideWithValue(FakeKycRepository()),
      appSessionProvider.overrideWith(() => FakeAppSessionNotifier(role, seekerType)),
    ],
    child: MaterialApp(
      home: ProfileScreen(role: role),
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
  group('Verification Visibility Matrix Unit Tests', () {
    test('1. Seeker - Informal: Aadhaar, DL, Bank/UPI, Background, Face (5 items, NO Student)', () {
      final items = verificationItemsFor(UserRole.seeker, 'informal');
      final types = items.map((e) => e.type).toList();

      expect(types, equals([
        VerificationType.aadhaar,
        VerificationType.drivingLicence,
        VerificationType.bankUpi,
        VerificationType.backgroundCheck,
        VerificationType.face,
      ]));
      expect(types.contains(VerificationType.student), isFalse);
    });

    test('2. Seeker - Student: Aadhaar, DL, Student, Bank/UPI, Background, Face (6 items)', () {
      final items = verificationItemsFor(UserRole.seeker, 'student');
      final types = items.map((e) => e.type).toList();

      expect(types, equals([
        VerificationType.aadhaar,
        VerificationType.drivingLicence,
        VerificationType.student,
        VerificationType.bankUpi,
        VerificationType.backgroundCheck,
        VerificationType.face,
      ]));
      expect(types.contains(VerificationType.student), isTrue);
    });

    test('3. Seeker - Part-Time: Aadhaar, DL, Bank/UPI, Background, Face (5 items, NO Student)', () {
      final items = verificationItemsFor(UserRole.seeker, 'part_time');
      final types = items.map((e) => e.type).toList();

      expect(types, equals([
        VerificationType.aadhaar,
        VerificationType.drivingLicence,
        VerificationType.bankUpi,
        VerificationType.backgroundCheck,
        VerificationType.face,
      ]));
      expect(types.contains(VerificationType.student), isFalse);
    });

    test('4. Job Provider: Aadhaar, Background, Face (3 items, NO DL, NO Student, NO Bank/UPI)', () {
      final items = verificationItemsFor(UserRole.provider, null);
      final types = items.map((e) => e.type).toList();

      expect(types, equals([
        VerificationType.aadhaar,
        VerificationType.backgroundCheck,
        VerificationType.face,
      ]));
      expect(types.contains(VerificationType.drivingLicence), isFalse);
      expect(types.contains(VerificationType.student), isFalse);
      expect(types.contains(VerificationType.bankUpi), isFalse);
    });

    test('5. Farmer: Aadhaar, Bank/UPI, Face (3 items, NO DL, NO Student, NO Background)', () {
      final items = verificationItemsFor(UserRole.farmer, null);
      final types = items.map((e) => e.type).toList();

      expect(types, equals([
        VerificationType.aadhaar,
        VerificationType.bankUpi,
        VerificationType.face,
      ]));
      expect(types.contains(VerificationType.drivingLicence), isFalse);
      expect(types.contains(VerificationType.student), isFalse);
      expect(types.contains(VerificationType.backgroundCheck), isFalse);
    });

    test('Seeker Type Change Visibility Persistence (switching away hides, switching back shows)', () {
      var items = verificationItemsFor(UserRole.seeker, 'student');
      expect(items.any((i) => i.type == VerificationType.student), isTrue);

      // Change type away to informal
      items = verificationItemsFor(UserRole.seeker, 'informal');
      expect(items.any((i) => i.type == VerificationType.student), isFalse);

      // Change back to student
      items = verificationItemsFor(UserRole.seeker, 'student');
      expect(items.any((i) => i.type == VerificationType.student), isTrue);
    });
  });

  group('Profile Screen Visibility Matrix Widget Tests', () {
    testWidgets('ProfileScreen for Seeker (Student) renders Student Verification item', (tester) async {
      await tester.pumpWidget(_makeTestableProfile(UserRole.seeker, 'student'));
      await tester.pumpAndSettle();

      expect(find.text('Student Verification'), findsOneWidget);
      expect(find.text('Driving Licence'), findsOneWidget);
      expect(find.text('Aadhaar eKYC Verification'), findsOneWidget);
      expect(find.text('Bank / UPI Account'), findsOneWidget);
      expect(find.text('Background Verification'), findsOneWidget);
      expect(find.text('Face Enrolment & Liveness'), findsOneWidget);
    });

    testWidgets('ProfileScreen for Seeker (Informal) hides Student Verification item', (tester) async {
      await tester.pumpWidget(_makeTestableProfile(UserRole.seeker, 'informal'));
      await tester.pumpAndSettle();

      expect(find.text('Student Verification'), findsNothing);
      expect(find.text('Driving Licence'), findsOneWidget);
      expect(find.text('Aadhaar eKYC Verification'), findsOneWidget);
    });

    testWidgets('ProfileScreen for Provider hides DL, Student, and Bank/UPI items', (tester) async {
      await tester.pumpWidget(_makeTestableProfile(UserRole.provider, null));
      await tester.pumpAndSettle();

      expect(find.text('Student Verification'), findsNothing);
      expect(find.text('Driving Licence'), findsNothing);
      expect(find.text('Bank / UPI Account'), findsNothing);
      expect(find.text('Aadhaar eKYC Verification'), findsOneWidget);
      expect(find.text('Background Verification'), findsOneWidget);
      expect(find.text('Face Enrolment & Liveness'), findsOneWidget);
    });

    testWidgets('ProfileScreen for Farmer hides DL, Student, and Background items', (tester) async {
      await tester.pumpWidget(_makeTestableProfile(UserRole.farmer, null));
      await tester.pumpAndSettle();

      expect(find.text('Student Verification'), findsNothing);
      expect(find.text('Driving Licence'), findsNothing);
      expect(find.text('Background Verification'), findsNothing);
      expect(find.text('Aadhaar eKYC Verification'), findsOneWidget);
      expect(find.text('Bank / UPI Account'), findsOneWidget);
      expect(find.text('Face Enrolment & Liveness'), findsOneWidget);
    });

    testWidgets('ProfileScreen for Seeker renders My Digital ID, hides Scan & Verify', (tester) async {
      await tester.pumpWidget(_makeTestableProfile(UserRole.seeker, 'informal'));
      await tester.pumpAndSettle();

      expect(find.text('My Digital ID'), findsOneWidget);
      expect(find.text('Scan & Verify'), findsNothing);
    });

    testWidgets('ProfileScreen for Provider renders Scan & Verify, hides My Digital ID', (tester) async {
      await tester.pumpWidget(_makeTestableProfile(UserRole.provider, null));
      await tester.pumpAndSettle();

      expect(find.text('Scan & Verify'), findsOneWidget);
      expect(find.text('My Digital ID'), findsNothing);
    });

    testWidgets('ProfileScreen for Farmer hides both My Digital ID and Scan & Verify', (tester) async {
      await tester.pumpWidget(_makeTestableProfile(UserRole.farmer, null));
      await tester.pumpAndSettle();

      expect(find.text('My Digital ID'), findsNothing);
      expect(find.text('Scan & Verify'), findsNothing);
    });

    testWidgets('Header phone formatting and role chip displaying seeker type', (tester) async {
      expect(formatIndianPhone('+919108914544'), equals('+91 91089 14544'));
      expect(formatIndianPhone('9108914544'), equals('+91 91089 14544'));
      expect(getInitials('Ramesh Sharma'), equals('RS'));

      await tester.pumpWidget(_makeTestableProfile(UserRole.seeker, 'student'));
      await tester.pumpAndSettle();

      expect(find.text('Job Seeker · Student'), findsOneWidget);
    });
  });

  group('Real GoRouter Verification Route Guard Integration Tests', () {
    setUp(() {
      BrandIntroScreen.isCompleted = true;
      SplashScreen.isSplashReadyToNavigate = true;
    });

    Widget buildTestApp(ProviderContainer container) {
      final router = container.read(appRouterProvider);
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
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

    ProviderContainer createTestContainer({
      required UserRole role,
      required String? seekerType,
      required bool seekerTypeLoaded,
    }) {
      final container = ProviderContainer(
        overrides: [
          consentRepositoryProvider.overrideWithValue(FakeConsentRepository()),
          kycRepositoryProvider.overrideWithValue(FakeKycRepository()),
        ],
      );

      container.read(appSessionProvider.notifier).updateSession(
            status: AuthSessionStatus.ready,
            role: role,
            seekerType: seekerType,
            seekerTypeLoaded: seekerTypeLoaded,
          );

      return container;
    }

    testWidgets('Student seeker can navigate to /kyc/student and see Student Verification Screen', (tester) async {
      final container = createTestContainer(role: UserRole.seeker, seekerType: 'student', seekerTypeLoaded: true);
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestApp(container));
      await tester.pump();

      final router = container.read(appRouterProvider);
      router.go('/kyc/student');
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), equals('/kyc/student'));
      expect(find.byType(StudentVerificationScreen), findsOneWidget);
      expect(find.text('Student Verification'), findsWidgets);
      expect(find.text('Strict Student Data Privacy'), findsOneWidget);
      expect(find.text('Not verified (tap to start)'), findsOneWidget);
    });

    testWidgets('Student seeker can open /kyc/student even when seekerType is still loading', (tester) async {
      final container = createTestContainer(role: UserRole.seeker, seekerType: null, seekerTypeLoaded: false);
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestApp(container));
      await tester.pump();

      final router = container.read(appRouterProvider);
      router.go('/kyc/student');
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), equals('/kyc/student'));
      expect(find.byType(StudentVerificationScreen), findsOneWidget);
    });

    testWidgets('Informal seeker navigating to /kyc/student is redirected away to home', (tester) async {
      final container = createTestContainer(role: UserRole.seeker, seekerType: 'informal', seekerTypeLoaded: true);
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestApp(container));
      await tester.pump();

      final router = container.read(appRouterProvider);
      router.go('/kyc/student');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(router.state.uri.toString(), equals('/seeker/home'));
      expect(find.byType(StudentVerificationScreen), findsNothing);
    });

    testWidgets('Farmer navigating to /kyc/student, /kyc/dl, /kyc/background is redirected away', (tester) async {
      final container = createTestContainer(role: UserRole.farmer, seekerType: null, seekerTypeLoaded: true);
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestApp(container));
      await tester.pump();

      final router = container.read(appRouterProvider);

      router.go('/kyc/student');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(router.state.uri.toString(), equals('/farmer/home'));
      expect(find.byType(StudentVerificationScreen), findsNothing);

      router.go('/kyc/dl');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(router.state.uri.toString(), equals('/farmer/home'));
      expect(find.byType(DrivingLicenceScreen), findsNothing);

      router.go('/kyc/background');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(router.state.uri.toString(), equals('/farmer/home'));
      expect(find.byType(BackgroundCheckScreen), findsNothing);
    });

    testWidgets('Provider navigating to /kyc/student, /kyc/dl, /kyc/bank is redirected away', (tester) async {
      final container = createTestContainer(role: UserRole.provider, seekerType: null, seekerTypeLoaded: true);
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestApp(container));
      await tester.pump();

      final router = container.read(appRouterProvider);

      router.go('/kyc/student');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(router.state.uri.toString(), equals('/provider/home'));
      expect(find.byType(StudentVerificationScreen), findsNothing);

      router.go('/kyc/dl');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(router.state.uri.toString(), equals('/provider/home'));
      expect(find.byType(DrivingLicenceScreen), findsNothing);

      router.go('/kyc/bank');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(router.state.uri.toString(), equals('/provider/home'));
      expect(find.byType(BankUpiScreen), findsNothing);
    });

    testWidgets('Farmer navigating to /trust/digital-id or /trust/scan-verify is redirected away', (tester) async {
      final container = createTestContainer(role: UserRole.farmer, seekerType: null, seekerTypeLoaded: true);
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestApp(container));
      await tester.pump();

      final router = container.read(appRouterProvider);

      router.go('/trust/digital-id');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(router.state.uri.toString(), equals('/farmer/home'));

      router.go('/trust/scan-verify');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(router.state.uri.toString(), equals('/farmer/home'));
    });

    testWidgets('Seeker navigating to /trust/scan-verify is redirected away to seeker home', (tester) async {
      final container = createTestContainer(role: UserRole.seeker, seekerType: 'informal', seekerTypeLoaded: true);
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestApp(container));
      await tester.pump();

      final router = container.read(appRouterProvider);
      router.go('/trust/scan-verify');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(router.state.uri.toString(), equals('/seeker/home'));
    });

    testWidgets('Provider navigating to /trust/digital-id is redirected away to provider home', (tester) async {
      final container = createTestContainer(role: UserRole.provider, seekerType: null, seekerTypeLoaded: true);
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestApp(container));
      await tester.pump();

      final router = container.read(appRouterProvider);
      router.go('/trust/digital-id');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(router.state.uri.toString(), equals('/provider/home'));
    });
  });
}
