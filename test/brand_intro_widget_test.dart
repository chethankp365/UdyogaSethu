import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udyogasethu/core/router/app_router.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_wizard_controller.dart';
import 'package:udyogasethu/features/onboarding/presentation/brand_intro_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/splash_screen.dart';
import 'package:udyogasethu/features/provider/presentation/provider_wizard_controller.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_wizard_controller.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

import 'farmer_wizard_test.dart';
import 'provider_wizard_test.dart';
import 'seeker_wizard_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp({
    required ProviderContainer container,
    bool disableAnimations = false,
  }) {
    final router = container.read(appRouterProvider);

    return UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
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
    BrandIntroScreen.resetColdStartFlags();
    SplashScreen.isSplashReadyToNavigate = false;
  });

  group('BrandIntroScreen UI & Stability Tests', () {
    testWidgets('BrandIntroScreen initializes once, creates controller once, speaks once, and tap skips to splash', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final container = createTestContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pump();

      // Assert single creation & initialization
      expect(BrandIntroScreen.debugInitStateCount, equals(1));
      expect(BrandIntroScreen.debugControllerCreatedCount, equals(1));

      // Pump 1 second to trigger speech
      await tester.pump(const Duration(milliseconds: 1000));
      expect(BrandIntroScreen.debugSpeakCount, equals(1));

      // Verify UI elements
      expect(find.textContaining('Bridging Work.', findRichText: true), findsOneWidget);
      expect(find.textContaining('Empowering Lives.', findRichText: true), findsOneWidget);

      // Tap to skip gesture
      await tester.tap(find.byType(BrandIntroScreen));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(BrandIntroScreen.isCompleted, isTrue);
    });

    testWidgets('Parent rebuilds do not recreate BrandIntroScreen or restart TTS', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final container = createTestContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Trigger session updates simulating background bootstrap
      container.read(appSessionProvider.notifier).setSessionStatus(AuthSessionStatus.needsOnboarding);
      await tester.pump();

      container.read(appSessionProvider.notifier).setSessionStatus(AuthSessionStatus.signedOut);
      await tester.pump();

      // Assert that initState, controller, and speak counts REMAIN 1
      expect(BrandIntroScreen.debugInitStateCount, equals(1));
      expect(BrandIntroScreen.debugControllerCreatedCount, equals(1));
      expect(BrandIntroScreen.debugSpeakCount, equals(1));
    });

    testWidgets('BrandIntroScreen respects reduced motion setting', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final container = createTestContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestApp(
          container: container,
          disableAnimations: true,
        ),
      );

      await tester.pumpAndSettle();
      expect(BrandIntroScreen.isCompleted, isTrue);
    });
  });
}
