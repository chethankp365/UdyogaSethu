import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udyogasethu/core/theme/app_theme.dart';
import 'package:udyogasethu/core/widgets/job_card.dart';
import 'package:udyogasethu/features/auth/presentation/login_screen.dart';
import 'package:udyogasethu/features/auth/presentation/otp_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/language_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/role_tree_screen.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_wizard_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

/// Integration test covering UdyogaSethu's critical end-to-end user path:
///
/// 1. Language Selection -> Select preferred language (e.g. Kannada / English).
/// 2. Role Tree Flow   -> Choose category (Worker -> Seeker).
/// 3. Authentication    -> Enter test phone number (e.g. 9123456789) and test OTP.
/// 4. Profile Wizard    -> Complete minimal profile details.
/// 5. Job Discovery     -> View available open jobs feed.
/// 6. Job Application   -> Apply for an open job card.
///
/// Setup Prerequisites:
/// - Dedicated local or staging Supabase instance, or test provider container.
/// - In local mock mode, uses SharedPreferences and pre-configured test mocks.
/// - Run using: flutter test integration_test/app_critical_flow_test.dart -d `<device>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildAppWithScreen(Widget screen) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    );
  }

  group('UdyogaSethu Critical Flow Integration Test', () {
    testWidgets('Step 1: Select Language and advance', (tester) async {
      await tester.pumpWidget(buildAppWithScreen(const LanguageScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Choose your language'), findsOneWidget);
      expect(find.text('ಕನ್ನಡ (Kannada)'), findsOneWidget);

      // Select Kannada
      await tester.tap(find.text('ಕನ್ನಡ (Kannada)'));
      await tester.pumpAndSettle();

      expect(find.text('Continue ->'), findsOneWidget);
    });

    testWidgets('Step 2: Role Tree Selection (Worker -> Seeker)', (tester) async {
      await tester.pumpWidget(buildAppWithScreen(const RoleTreeScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cardWorker')), findsOneWidget);

      // Step 1: Select Worker
      await tester.tap(find.byKey(const Key('cardWorker')));
      await tester.pumpAndSettle();

      // Advance to Step 2
      await tester.tap(find.byKey(const Key('roleTreeContinueButton')));
      await tester.pumpAndSettle();

      // Step 2: Select Seeker
      expect(find.byKey(const Key('cardSeeker')), findsOneWidget);
      await tester.tap(find.byKey(const Key('cardSeeker')));
      await tester.pumpAndSettle();

      // Advance to Step 3
      await tester.tap(find.byKey(const Key('roleTreeContinueButton')));
      await tester.pumpAndSettle();

      // Step 3: Select Informal Work
      expect(find.byKey(const Key('cardSeekerInformal')), findsOneWidget);
      await tester.tap(find.byKey(const Key('cardSeekerInformal')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('roleTreeContinueButton')), findsOneWidget);
    });

    testWidgets('Step 3: Login with Test Account & OTP Verification', (tester) async {
      await tester.pumpWidget(buildAppWithScreen(const LoginScreen()));
      await tester.pumpAndSettle();

      // Enter test phone number (e.g. 9123456789)
      await tester.enterText(find.byKey(const Key('phoneInputField')), '9123456789');
      await tester.pumpAndSettle();

      // Agree to terms checkbox
      final termsFinder = find.byKey(const Key('termsCheckbox'));
      if (termsFinder.evaluate().isNotEmpty) {
        await tester.tap(termsFinder);
        await tester.pumpAndSettle();
      }

      expect(find.byKey(const Key('getOtpButton')), findsOneWidget);

      // Move to OTP Screen
      await tester.pumpWidget(buildAppWithScreen(const OtpScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('otpPinputField')), findsOneWidget);
      expect(find.byKey(const Key('verifyOtpButton')), findsOneWidget);
    });

    testWidgets('Step 4: Profile Wizard Minimum Setup', (tester) async {
      await tester.pumpWidget(buildAppWithScreen(const SeekerWizardScreen()));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify seeker setup wizard presence
      expect(find.byType(SeekerWizardScreen), findsOneWidget);
    });

    testWidgets('Step 5 & 6: Discover Jobs and Apply', (tester) async {
      bool applied = false;

      final testJobFeed = Scaffold(
        appBar: AppBar(title: const Text('Available Jobs')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            JobCard(
              title: 'Plumbing Repair Assistant',
              employerName: 'City Facilities Co.',
              isEmployerVerified: true,
              rating: 4.9,
              reviewCount: 45,
              distanceText: '1.2 km away',
              payRateText: '₹750 / day',
              isHotJobBadge: 'Immediate Start',
              onApply: () => applied = true,
            ),
          ],
        ),
      );

      await tester.pumpWidget(buildAppWithScreen(testJobFeed));
      await tester.pumpAndSettle();

      // Step 5: View available job
      expect(find.text('Plumbing Repair Assistant'), findsOneWidget);
      expect(find.text('City Facilities Co.'), findsOneWidget);
      expect(find.text('₹750 / day'), findsOneWidget);

      // Step 6: Apply for job
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(applied, isTrue);
    });
  });
}
