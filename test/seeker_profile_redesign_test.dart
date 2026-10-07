import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/core/l10n/locale_controller.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/features/profile/presentation/profile_screen.dart';
import 'package:udyogasethu/features/seeker/domain/job_recommendation.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_profile_draft.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_home_controller.dart';
import 'package:udyogasethu/features/trust/data/kyc_repository.dart';
import 'package:udyogasethu/features/trust/domain/kyc_record.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class MockKycRepository implements KycRepository {
  @override
  Stream<KycRecord?> watchKycRecord(String userId, {String docType = 'aadhaar'}) {
    return Stream.value(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAppSessionNotifier extends AppSessionNotifier {
  final UserRole initialRole;
  final String? initialSeekerType;

  FakeAppSessionNotifier({
    this.initialRole = UserRole.seeker,
    this.initialSeekerType = 'informal',
  });

  @override
  AppSessionData build() {
    return AppSessionData(
      status: AuthSessionStatus.ready,
      activeRole: initialRole,
      seekerType: initialSeekerType,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget({
    required UserRole role,
    required SeekerProfileDraft draft,
    SeekerHomeSummary summary = const SeekerHomeSummary(
      walletBalancePaise: 1245000,
      todayEarningsPaise: 80000,
    ),
  }) {
    return ProviderScope(
      overrides: [
        seekerHomeProfileProvider.overrideWith((ref) async => draft),
        seekerHomeSummaryProvider.overrideWith((ref) async => summary),
        appSessionProvider.overrideWith(() => FakeAppSessionNotifier(
          initialRole: role,
          initialSeekerType: draft.seekerType,
        )),
        kycRepositoryProvider.overrideWithValue(MockKycRepository()),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final locale = ref.watch(localeProvider);
          return MaterialApp(
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ProfileScreen(role: UserRole.seeker),
          );
        },
      ),
    );
  }

  group('Seeker Profile Redesign Tests', () {
    testWidgets('Renders header with name, phone, verified badge, category, and 3 live stats', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          role: UserRole.seeker,
          draft: const SeekerProfileDraft(
            userId: 'user-1',
            fullName: 'Chethan Kumar',
            seekerType: 'informal',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Header Details
      expect(find.text('Chethan Kumar'), findsOneWidget);
      expect(find.text('+91 98765 43210'), findsOneWidget);
      expect(find.text('Category: Informal / Skilled Worker'), findsOneWidget);

      // Check 3 Live Stats
      expect(find.text('Verified Jobs'), findsOneWidget);
      expect(find.text('Rating'), findsOneWidget);
      expect(find.text('Total Earnings'), findsOneWidget);
      expect(find.text('₹12450'), findsOneWidget);

      // Check 3 Tabs
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Work Showcase'), findsOneWidget);
      expect(find.text('Safety Status'), findsOneWidget);
    });

    testWidgets('D-VISIBILITY: Student verification chip strictly hidden for informal seeker', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          role: UserRole.seeker,
          draft: const SeekerProfileDraft(
            userId: 'user-2',
            fullName: 'Ramesh Plumber',
            seekerType: 'informal',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ROLE CREDENTIALS & CATEGORY BADGES'), findsOneWidget);
      expect(find.text('Driving Licence'), findsOneWidget);
      expect(find.text('Bank / UPI Account'), findsOneWidget);
      expect(find.text('Background Verification'), findsOneWidget);

      // Must NOT show Student Verification
      expect(find.text('Student Verification'), findsNothing);
    });

    testWidgets('D-VISIBILITY: Student verification chip visible for student seeker', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          role: UserRole.seeker,
          draft: const SeekerProfileDraft(
            userId: 'user-3',
            fullName: 'Ananya Student',
            seekerType: 'student',
            collegeName: 'National Institute of Technology',
            courseName: 'B.Tech IT',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Category: Student Gig Worker'), findsOneWidget);
      expect(find.text('Student Verification'), findsOneWidget);
      expect(find.textContaining('National Institute of Technology'), findsOneWidget);
    });

    testWidgets('Tapping language chip updates locale live', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          role: UserRole.seeker,
          draft: const SeekerProfileDraft(
            userId: 'user-4',
            fullName: 'Chethan Kumar',
            seekerType: 'informal',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Drag to scroll header up so Language card is in viewport
      await tester.drag(find.byType(NestedScrollView), const Offset(0, -350));
      await tester.pumpAndSettle();

      expect(find.text('LANGUAGE & ACCESSIBILITY'), findsOneWidget);
      expect(find.text('ಕನ್ನಡ'), findsOneWidget);
      expect(find.text('हिंदी'), findsOneWidget);

      // Tap Kannada chip
      await tester.tap(find.text('ಕನ್ನಡ'));
      await tester.pumpAndSettle();

      // Check that UI translated to Kannada
      expect(find.text('ಅವಲೋಕನ'), findsOneWidget);
      expect(find.text('ಕೆಲಸದ ಪ್ರದರ್ಶನ'), findsOneWidget);
      expect(find.text('ಸುರಕ್ಷತಾ ಸ್ಥಿತಿ'), findsOneWidget);
    });

    testWidgets('Opening Change Category dialog presents the 3 seeker types', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          role: UserRole.seeker,
          draft: const SeekerProfileDraft(
            userId: 'user-5',
            fullName: 'Chethan Kumar',
            seekerType: 'informal',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final changeBtn = find.text('Change Category');
      expect(changeBtn, findsOneWidget);
      await tester.tap(changeBtn);
      await tester.pumpAndSettle();

      // Dialog should be open
      expect(find.text('Change Worker Category'), findsOneWidget);
      expect(find.text('Informal / Skilled Worker'), findsWidgets);
      expect(find.text('Student Gig Worker'), findsOneWidget);
      expect(find.text('Part-Time Worker'), findsOneWidget);

      // Select Student Gig Worker
      await tester.tap(find.text('Student Gig Worker'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Change Worker Category'), findsNothing);
    });

    testWidgets('Opening Skills picker allows selecting and adding new skills', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          role: UserRole.seeker,
          draft: const SeekerProfileDraft(
            userId: 'user-6',
            fullName: 'Chethan Kumar',
            seekerType: 'informal',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Drag to scroll header up moderately so Skills card is nicely centered
      await tester.drag(find.byType(NestedScrollView), const Offset(0, -350));
      await tester.pumpAndSettle();

      final addSkillBtn = find.text('+ Add Skill');
      expect(addSkillBtn, findsOneWidget);
      await tester.tap(addSkillBtn);
      await tester.pumpAndSettle();

      // Skills picker dialog open
      expect(find.text('Select a Skill'), findsOneWidget);
      expect(find.text('Electrical Wiring & Repair'), findsOneWidget);

      // Select a skill
      await tester.tap(find.text('Electrical Wiring & Repair'));
      await tester.pumpAndSettle();

      // Save skills
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Select a Skill'), findsNothing);
      expect(find.text('Electrical Wiring & Repair'), findsOneWidget);
    });

    testWidgets('Work Showcase tab renders clean empty state and Browse Jobs button', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          role: UserRole.seeker,
          draft: const SeekerProfileDraft(
            userId: 'user-7',
            fullName: 'Chethan Kumar',
            seekerType: 'informal',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Work Showcase tab
      await tester.tap(find.text('Work Showcase'));
      await tester.pumpAndSettle();

      expect(find.text('Your completed jobs, photos and ratings will appear here'), findsOneWidget);
      expect(find.text('Browse Jobs'), findsOneWidget);
    });

    testWidgets('Safety Status tab renders safety onboarding lifecycle card', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          role: UserRole.seeker,
          draft: const SeekerProfileDraft(
            userId: 'user-8',
            fullName: 'Chethan Kumar',
            seekerType: 'informal',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Safety Status tab
      await tester.tap(find.text('Safety Status'));
      await tester.pumpAndSettle();

      expect(find.text('Safety Onboarding & Badges'), findsOneWidget);
      expect(find.text('Continue Safety Verification ->'), findsOneWidget);
    });
  });
}
