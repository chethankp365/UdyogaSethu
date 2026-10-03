import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/core/router/app_router.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_wizard_controller.dart';
import 'package:udyogasethu/features/onboarding/presentation/brand_intro_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/language_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/splash_screen.dart';
import 'package:udyogasethu/features/provider/presentation/provider_wizard_controller.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_wizard_controller.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

import 'farmer_wizard_test.dart';
import 'provider_wizard_test.dart';
import 'seeker_wizard_test.dart';

void main() {
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

  group('Router Integration Tests for Session Lifecycle States', () {
    testWidgets('Cold start initial location is brandIntro', (WidgetTester tester) async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestApp(container));
      await tester.pump();

      final router = container.read(appRouterProvider);
      expect(router.state.uri.toString(), AppRoutes.brandIntro);
      expect(find.textContaining('Bridging Work.', findRichText: true), findsOneWidget);
    });

    testWidgets('Flow 1: Signed Out First Launch (needsOnboarding) goes BrandIntro -> Splash -> Intro', (WidgetTester tester) async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(appSessionProvider.notifier).setSessionStatus(AuthSessionStatus.needsOnboarding);

      await tester.pumpWidget(buildTestApp(container));
      await tester.pump();

      BrandIntroScreen.isCompleted = true;
      SplashScreen.isSplashReadyToNavigate = true;

      final router = container.read(appRouterProvider);
      router.go(AppRoutes.splash);
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), AppRoutes.intro);
      expect(find.text('Built for India. For Every Worker.'), findsOneWidget);
    });

    testWidgets('Flow 2: Signed Out Returning Launch (signedOut) goes BrandIntro -> Splash -> Language', (WidgetTester tester) async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(appSessionProvider.notifier).setSessionStatus(AuthSessionStatus.signedOut);

      await tester.pumpWidget(buildTestApp(container));
      await tester.pump();

      BrandIntroScreen.isCompleted = true;
      SplashScreen.isSplashReadyToNavigate = true;

      final router = container.read(appRouterProvider);
      router.go(AppRoutes.splash);
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), AppRoutes.language);
      expect(find.byType(LanguageScreen), findsOneWidget);
    });

    testWidgets('Flow 3: Signed In User (needsProfile) skips Intro and Language screens', (WidgetTester tester) async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(appSessionProvider.notifier).updateSession(
        status: AuthSessionStatus.needsProfile,
        role: UserRole.provider,
      );

      await tester.pumpWidget(buildTestApp(container));
      await tester.pump();

      BrandIntroScreen.isCompleted = true;
      SplashScreen.isSplashReadyToNavigate = true;

      final router = container.read(appRouterProvider);
      router.go(AppRoutes.splash);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(router.state.uri.toString(), AppRoutes.profileSetupProvider);
    });

    testWidgets('Signed Out state protects private routes and redirects to login', (WidgetTester tester) async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(appSessionProvider.notifier).setSessionStatus(AuthSessionStatus.signedOut);

      await tester.pumpWidget(buildTestApp(container));
      await tester.pump();

      BrandIntroScreen.isCompleted = true;
      SplashScreen.isSplashReadyToNavigate = true;

      final router = container.read(appRouterProvider);
      router.go('/seeker');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(router.state.uri.toString(), AppRoutes.login);
    });

    testWidgets('NeedsRole state redirects to role tree', (WidgetTester tester) async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(appSessionProvider.notifier).setSessionStatus(AuthSessionStatus.needsRole);

      await tester.pumpWidget(buildTestApp(container));
      await tester.pump();

      BrandIntroScreen.isCompleted = true;
      SplashScreen.isSplashReadyToNavigate = true;

      final router = container.read(appRouterProvider);
      router.go(AppRoutes.splash);
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), AppRoutes.roleTree);
      expect(find.byKey(const Key('cardWorker')), findsOneWidget);
    });

    testWidgets('Ready state redirects to active role home shell', (WidgetTester tester) async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(appSessionProvider.notifier).updateSession(
        status: AuthSessionStatus.ready,
        role: UserRole.farmer,
      );

      await tester.pumpWidget(buildTestApp(container));
      await tester.pump();

      BrandIntroScreen.isCompleted = true;
      SplashScreen.isSplashReadyToNavigate = true;

      final router = container.read(appRouterProvider);
      router.go(AppRoutes.splash);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(router.state.uri.toString(), AppRoutes.farmerHome);
    });

    testWidgets('Suspended state redirects to suspended screen', (WidgetTester tester) async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(appSessionProvider.notifier).setSessionStatus(AuthSessionStatus.suspended);

      await tester.pumpWidget(buildTestApp(container));
      await tester.pump();

      BrandIntroScreen.isCompleted = true;
      SplashScreen.isSplashReadyToNavigate = true;

      final router = container.read(appRouterProvider);
      router.go(AppRoutes.splash);
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), AppRoutes.suspended);
      expect(find.text('Account Suspended'), findsOneWidget);
    });
  });
}
