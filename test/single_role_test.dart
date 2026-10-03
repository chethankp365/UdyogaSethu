import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udyogasethu/core/config/env.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/features/onboarding/presentation/role_conflict_screen.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_home_screen.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_profile_draft.dart';

Widget createTestApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('en'),
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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ONE ACCOUNT = ONE ROLE Policy Tests', () {
    test('kAllowMultiRole feature flag is false by default', () {
      expect(kAllowMultiRole, isFalse);
    });

    testWidgets('RoleConflictScreen renders error message and action buttons correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const RoleConflictScreen(
            existingRole: UserRole.seeker,
            chosenRole: UserRole.farmer,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Account Role Conflict'), findsNWidgets(2));
      expect(find.textContaining('already registered as Job Seeker'), findsOneWidget);
      expect(find.textContaining('cannot use it as Farmer'), findsOneWidget);
      expect(find.text('Log in as Job Seeker'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('RoleConflictScreen Back button navigates without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          const RoleConflictScreen(
            existingRole: UserRole.provider,
            chosenRole: UserRole.seeker,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('already registered as Job Provider'), findsOneWidget);
      expect(find.text('Log in as Job Provider'), findsOneWidget);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
    });

    testWidgets('SeekerHomeScreen renders profile card and coming soon actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seekerHomeProfileProvider.overrideWith((ref) async {
              return const SeekerProfileDraft(
                userId: 'test-user',
                fullName: 'Chethan Kumar',
                seekerType: 'informal',
                dailyRatePaise: 65000,
                availabilityStatus: 'available',
                workingDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
                serviceRadiusKm: 15.0,
                onboardingComplete: true,
              );
            }),
            seekerSkillsListProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: SeekerHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Seeker Home'), findsOneWidget);
      expect(find.textContaining('Welcome back, Chethan Kumar!'), findsOneWidget);
      expect(find.text('Identity Verification'), findsOneWidget);
      expect(find.text('Informal Seeker'), findsOneWidget);
      expect(find.text('₹650 / day'), findsOneWidget);
      expect(find.text('Find Jobs'), findsOneWidget);
      expect(find.text('Complete Profile'), findsOneWidget);
    });
  });
}
