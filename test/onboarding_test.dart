import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/features/onboarding/data/bootstrap_service.dart';
import 'package:udyogasethu/features/onboarding/presentation/intro_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/splash_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Splash & Intro Screen UI Tests', () {
    testWidgets('SplashScreen renders all required branding, progress, chips and footer elements', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bootstrapProvider.overrideWith(BootstrapNotifier.new),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: SplashScreen(),
          ),
        ),
      );

      // Verify rich text tagline
      expect(find.textContaining('Bridging Work.', findRichText: true), findsOneWidget);
      expect(find.textContaining('Empowering Lives.', findRichText: true), findsOneWidget);
      expect(find.text('Initializing UdyogaSethu...'), findsOneWidget);

      // Verify static feature chips
      expect(find.text('AI Matching'), findsOneWidget);
      expect(find.text('Secure'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
    });

    testWidgets('IntroScreen renders headline, subtitle, 3 feature tiles, skip and next buttons', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: IntroScreen(),
          ),
        ),
      );

      // Verify headline & subtitle
      expect(find.text('Built for India. For Every Worker.'), findsOneWidget);
      expect(find.text('Find jobs, grow skills, earn better and live with dignity.'), findsOneWidget);

      // Verify 3 feature tiles
      expect(find.text('Find Jobs\nNear You'), findsOneWidget);
      expect(find.text('Secure\nPayments'), findsOneWidget);
      expect(find.text('AI Voice\nAssistant'), findsOneWidget);

      // Verify actions
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next ->'), findsOneWidget);
    });
  });

  group('Session Routing Decision Logic Tests', () {
    test('Signed out and never onboarded resolves to AuthSessionStatus.needsOnboarding', () {
      final container = ProviderContainer();
      final notifier = container.read(appSessionProvider.notifier);
      notifier.setSessionStatus(AuthSessionStatus.needsOnboarding);
      expect(container.read(appSessionProvider).status, equals(AuthSessionStatus.needsOnboarding));
    });

    test('Signed out and onboarded resolves to AuthSessionStatus.signedOut', () {
      final container = ProviderContainer();
      final notifier = container.read(appSessionProvider.notifier);
      notifier.setSessionStatus(AuthSessionStatus.signedOut);
      expect(container.read(appSessionProvider).status, equals(AuthSessionStatus.signedOut));
    });

    test('Signed in without completed profile resolves to AuthSessionStatus.needsProfile', () {
      final container = ProviderContainer();
      final notifier = container.read(appSessionProvider.notifier);
      notifier.setSessionStatus(AuthSessionStatus.needsProfile);
      expect(container.read(appSessionProvider).status, equals(AuthSessionStatus.needsProfile));
    });

    test('Signed in with completed profile resolves to AuthSessionStatus.ready', () {
      final container = ProviderContainer();
      final notifier = container.read(appSessionProvider.notifier);
      notifier.setSessionStatus(AuthSessionStatus.ready);
      notifier.setRole(UserRole.seeker);
      expect(container.read(appSessionProvider).status, equals(AuthSessionStatus.ready));
      expect(AppSessionNotifier.getHomeForRole(container.read(appSessionProvider).activeRole), equals('/seeker/home'));
    });
  });
}
