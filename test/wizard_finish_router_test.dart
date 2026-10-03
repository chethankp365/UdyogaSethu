import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udyogasethu/core/router/app_router.dart';
import 'package:udyogasethu/core/router/app_session.dart';

import 'farmer_wizard_test.dart';
import 'provider_wizard_test.dart';
import 'seeker_wizard_test.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_wizard_controller.dart';
import 'package:udyogasethu/features/provider/presentation/provider_wizard_controller.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_profile_draft.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_wizard_controller.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp({required ProviderContainer container}) {
    final router = container.read(appRouterProvider);

    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
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

  ProviderContainer createTestContainer() {
    return ProviderContainer(
      overrides: [
        seekerProfileRepositoryProvider.overrideWithValue(FakeSeekerProfileRepository()),
        farmerProfileRepositoryProvider.overrideWithValue(FakeFarmerProfileRepository()),
        providerProfileRepositoryProvider.overrideWithValue(FakeProviderProfileRepository()),
      ],
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Wizard Finish & Router Navigation Tests', () {
    testWidgets('Router renders app without crash', (tester) async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Finishing Seeker Wizard updates AppSession to ready and lands on Seeker Home', (tester) async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      // Set AppSession status to needsProfile
      container.read(appSessionProvider.notifier).updateSession(
        status: AuthSessionStatus.needsProfile,
        role: UserRole.seeker,
        seekerType: 'informal',
      );

      final notifier = container.read(seekerWizardProvider.notifier);
      await tester.pump();
      await notifier.goToStep(7);

      final success = await notifier.saveAndNext();
      expect(success, isTrue);

      final session = container.read(appSessionProvider);
      expect(session.status, equals(AuthSessionStatus.ready));
      expect(session.activeRole, equals(UserRole.seeker));
    });

    testWidgets('Finishing Farmer Wizard updates AppSession to ready and lands on Farmer Home', (tester) async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(appSessionProvider.notifier).updateSession(
        status: AuthSessionStatus.needsProfile,
        role: UserRole.farmer,
      );

      final notifier = container.read(farmerWizardProvider.notifier);
      await tester.pump();
      notifier.setStep(5);

      final success = await notifier.nextStep();
      expect(success, isTrue);

      final session = container.read(appSessionProvider);
      expect(session.status, equals(AuthSessionStatus.ready));
      expect(session.activeRole, equals(UserRole.farmer));
    });

    testWidgets('Finishing Provider Wizard updates AppSession to ready and lands on Provider Home', (tester) async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(appSessionProvider.notifier).updateSession(
        status: AuthSessionStatus.needsProfile,
        role: UserRole.provider,
      );

      final notifier = container.read(providerWizardProvider.notifier);
      await tester.pump();
      notifier.setStep(5);

      final success = await notifier.nextStep();
      expect(success, isTrue);

      final session = container.read(appSessionProvider);
      expect(session.status, equals(AuthSessionStatus.ready));
      expect(session.activeRole, equals(UserRole.provider));
    });

    testWidgets('ServiceCategoryItem matchesSeekerType logic works for Student, Part-time, and Informal', (tester) async {
      const studentCat = ServiceCategoryItem(
        id: '1',
        slug: 'content-writing',
        names: {'en': 'Content & Writing'},
        audience: ['student', 'part_time'],
      );

      const informalCat = ServiceCategoryItem(
        id: '2',
        slug: 'masonry',
        names: {'en': 'Masonry'},
        audience: ['informal'],
      );

      expect(studentCat.matchesSeekerType('student'), isTrue);
      expect(studentCat.matchesSeekerType('part_time'), isTrue);
      expect(studentCat.matchesSeekerType('informal'), isFalse);

      expect(informalCat.matchesSeekerType('informal'), isTrue);
      expect(informalCat.matchesSeekerType('student'), isFalse);
    });
  });
}
