import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/privacy/data/consent_repository.dart';
import 'package:udyogasethu/features/privacy/domain/consent_purpose.dart';
import 'package:udyogasethu/features/seeker/domain/job_recommendation.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_profile_draft.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_home_controller.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_home_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class MockConsentRepository implements ConsentRepository {
  final List<ConsentPurpose> recordedConsents = [];

  @override
  Future<bool> hasValidConsent(ConsentPurpose purpose) async => true;

  @override
  Future<ConsentLog?> getLatestConsent(ConsentPurpose purpose) async => null;

  @override
  Future<Map<ConsentPurpose, ConsentLog?>> getAllConsents() async => {};

  @override
  Future<void> recordConsent({
    required ConsentPurpose purpose,
    required bool granted,
    Map<String, dynamic>? metadata,
  }) async {
    if (granted) {
      recordedConsents.add(purpose);
    }
  }

  @override
  Future<void> revokeConsent(ConsentPurpose purpose) async {}

  @override
  Future<void> withdrawFaceConsent() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Part C: Seeker Home Real GPS and Location Tests', () {
    test('Default initial location is Select Location without hardcoded fallback', () {
      final mockConsentRepo = MockConsentRepository();
      final container = ProviderContainer(
        overrides: [
          consentRepositoryProvider.overrideWithValue(mockConsentRepo),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(seekerLocationProvider);
      expect(state.displayName, equals('Select Location'));
      expect(state.lat, equals(0.0));
      expect(state.lng, equals(0.0));
      expect(state.isGps, isFalse);
    });

    test('Setting manual area updates location state accurately', () {
      final mockConsentRepo = MockConsentRepository();
      final container = ProviderContainer(
        overrides: [
          consentRepositoryProvider.overrideWithValue(mockConsentRepo),
        ],
      );
      addTearDown(container.dispose);

      container.read(seekerLocationProvider.notifier).setManualArea(
            'Indiranagar, Bengaluru',
            12.9784,
            77.6408,
          );

      final updatedState = container.read(seekerLocationProvider);
      expect(updatedState.displayName, equals('Indiranagar, Bengaluru'));
      expect(updatedState.lat, equals(12.9784));
      expect(updatedState.lng, equals(77.6408));
      expect(updatedState.isGps, isFalse);
    });

    testWidgets('Location sheet renders GPS trigger and manual area options', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockConsentRepo = MockConsentRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            consentRepositoryProvider.overrideWithValue(mockConsentRepo),
            seekerHomeProfileProvider.overrideWith((ref) async => const SeekerProfileDraft(
              userId: 'user-part-c',
              fullName: 'Test User',
              seekerType: 'informal',
              dailyRatePaise: 150000,
              onboardingComplete: true,
            )),
            seekerRecommendedJobsProvider.overrideWith((ref) async => <JobRecommendation>[]),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            home: Scaffold(
              body: SeekerHomeScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the location selector chip in the header
      final locationChip = find.text('Select Location');
      expect(locationChip, findsOneWidget);
      await tester.tap(locationChip);
      await tester.pumpAndSettle();

      // Bottom sheet should display "Choose Location", GPS action button, and manual options
      expect(find.text('Choose Location'), findsOneWidget);
      expect(find.byKey(const Key('use_gps_location_button')), findsOneWidget);
      expect(find.text('Use Current GPS Location'), findsOneWidget);
      expect(find.text('OR SELECT AREA MANUALLY'), findsOneWidget);
      expect(find.text('Indiranagar, Bengaluru'), findsOneWidget);

      // Tap a manual area
      await tester.tap(find.text('Indiranagar, Bengaluru'));
      await tester.pumpAndSettle();

      // Location header should now reflect selected area
      expect(find.text('Indiranagar, Bengaluru'), findsOneWidget);
    });
  });
}
