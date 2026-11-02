import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/core/router/app_router.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/router/routes.dart';
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
    BrandIntroScreen.isCompleted = true;
    SplashScreen.isSplashReadyToNavigate = true;
  });

  group('Voice Navigation Aliases & Redirect Tests', () {
    testWidgets('1. /jobs redirects to /seeker/jobs and preserves category query param', (tester) async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(appSessionProvider.notifier).updateSession(
        status: AuthSessionStatus.ready,
        role: UserRole.seeker,
      );

      await tester.pumpWidget(buildTestApp(container));
      await tester.pump();

      final router = container.read(appRouterProvider);
      router.go('/jobs?category=plumber');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(router.state.uri.path, AppRoutes.seekerJobs);
      expect(router.state.uri.queryParameters['category'], 'plumber');
    });

    testWidgets('2. /jobs without params redirects to /seeker/jobs', (tester) async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(appSessionProvider.notifier).updateSession(
        status: AuthSessionStatus.ready,
        role: UserRole.seeker,
      );

      await tester.pumpWidget(buildTestApp(container));
      await tester.pump();

      final router = container.read(appRouterProvider);
      router.go('/jobs');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(router.state.uri.toString(), AppRoutes.seekerJobs);
    });

    testWidgets('3. /safety/hub redirects to AppRoutes.safetyHub (/safety)', (tester) async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(appSessionProvider.notifier).updateSession(
        status: AuthSessionStatus.ready,
        role: UserRole.seeker,
      );

      await tester.pumpWidget(buildTestApp(container));
      await tester.pump();

      final router = container.read(appRouterProvider);
      router.go('/safety/hub');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(router.state.uri.toString(), AppRoutes.safetyHub);
    });

    testWidgets('4. /marketplace preserves search query and redirects to /farmer/market', (tester) async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(appSessionProvider.notifier).updateSession(
        status: AuthSessionStatus.ready,
        role: UserRole.farmer,
      );

      await tester.pumpWidget(buildTestApp(container));
      await tester.pump();

      final router = container.read(appRouterProvider);
      router.go('/marketplace?search=tomato');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(router.state.uri.path, AppRoutes.farmerMarket);
      expect(router.state.uri.queryParameters['search'], 'tomato');
    });

    testWidgets('5a. /profile redirects to /seeker/profile for seeker', (tester) async {
      final container = createTestContainer();
      addTearDown(container.dispose);
      container.read(appSessionProvider.notifier).updateSession(
        status: AuthSessionStatus.ready,
        role: UserRole.seeker,
      );
      await tester.pumpWidget(buildTestApp(container));
      await tester.pump();

      final router = container.read(appRouterProvider);
      router.go('/profile');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(router.state.uri.toString(), AppRoutes.seekerProfile);
    });

    testWidgets('5b. /profile redirects to /provider/profile for provider', (tester) async {
      final container = createTestContainer();
      addTearDown(container.dispose);
      container.read(appSessionProvider.notifier).updateSession(
        status: AuthSessionStatus.ready,
        role: UserRole.provider,
      );
      await tester.pumpWidget(buildTestApp(container));
      await tester.pump();

      final router = container.read(appRouterProvider);
      router.go('/profile');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(router.state.uri.toString(), AppRoutes.providerProfile);
    });

    testWidgets('5c. /profile redirects to /farmer/profile for farmer', (tester) async {
      final container = createTestContainer();
      addTearDown(container.dispose);
      container.read(appSessionProvider.notifier).updateSession(
        status: AuthSessionStatus.ready,
        role: UserRole.farmer,
      );
      await tester.pumpWidget(buildTestApp(container));
      await tester.pump();

      final router = container.read(appRouterProvider);
      router.go('/profile');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(router.state.uri.toString(), AppRoutes.farmerProfile);
    });
  });
}
