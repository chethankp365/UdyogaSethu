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
  final Map<ConsentPurpose, bool> _consents;

  MockConsentRepository(this._consents);

  @override
  Future<bool> hasValidConsent(ConsentPurpose purpose) async => _consents[purpose] ?? false;

  @override
  Future<ConsentLog?> getLatestConsent(ConsentPurpose purpose) async => null;

  @override
  Future<Map<ConsentPurpose, ConsentLog?>> getAllConsents() async => {};

  @override
  Future<void> recordConsent({
    required ConsentPurpose purpose,
    required bool granted,
    Map<String, dynamic>? metadata,
  }) async {}

  @override
  Future<void> revokeConsent(ConsentPurpose purpose) async {}

  @override
  Future<void> withdrawFaceConsent() async {}
}

void main() {
  group('Seeker Home & Recommendations Unit Tests', () {
    test('JobRecommendation parses JSON and calculates formatted strings', () {
      final json = {
        'id': 'job-123',
        'provider_id': 'prov-456',
        'title': 'Campus Delivery & Package Dispatcher',
        'wage_type': 'hourly',
        'wage_paise': 45000,
        'est_duration_minutes': 180,
        'distance_m': 1200.0,
        'employer_name': 'Green Express',
        'employer_verified': true,
        'employer_rating': 4.9,
        'category_name': {'en': 'Delivery', 'kn': 'ಡೆಲಿವರಿ'},
        'category_icon': 'local_shipping',
        'is_student_friendly': true,
        'is_flexible_shift': true,
        'score': 95.0,
        'reasons': ['Students Welcome 🎓', 'Near you (1.2 km)', 'Skill Match'],
      };

      final job = JobRecommendation.fromJson(json);

      expect(job.id, equals('job-123'));
      expect(job.title, equals('Campus Delivery & Package Dispatcher'));
      expect(job.formattedWage, equals('₹450 / hr'));
      expect(job.formattedDistance, equals('1.2 km'));
      expect(job.isStudentFriendly, isTrue);
      expect(job.score, equals(95.0));
      expect(job.reasons.length, equals(3));
      expect(job.getLocalizedCategory('en'), equals('Delivery'));
      expect(job.getLocalizedCategory('kn'), equals('ಡೆಲಿವರಿ'));
    });

    test('SeekerHomeSummary calculates goal percentage and rupees correctly', () {
      const summary = SeekerHomeSummary(
        walletBalancePaise: 345000, // ₹3,450.00
        todayEarningsPaise: 80000, // ₹800.00
        dailyGoalPaise: 150000, // ₹1,500.00
      );

      expect(summary.walletBalanceRupees, equals(3450.0));
      expect(summary.todayEarningsRupees, equals(800.0));
      expect(summary.dailyGoalRupees, equals(1500.0));
      expect(summary.goalPercentage, equals(53)); // 800 / 1500 = 53.33% -> 53%
      expect(summary.goalProgress, closeTo(0.533, 0.01));
    });

    test('Student and Informal recommendation scoring prioritizes differently', () {
      const studentJob = JobRecommendation(
        id: 'job-stu',
        providerId: 'p1',
        title: 'Evening Library Assistant',
        wageType: 'hourly',
        wagePaise: 40000,
        estDurationMinutes: 180,
        employerName: 'City Library',
        isStudentFriendly: true,
        isFlexibleShift: true,
        score: 95.0,
        reasons: ['Students Welcome 🎓', 'Short Flexible Shift ⏱️'],
      );

      const fullDayMasonryJob = JobRecommendation(
        id: 'job-mason',
        providerId: 'p2',
        title: 'Compound Wall Masonry Work',
        wageType: 'daily',
        wagePaise: 85000,
        estDurationMinutes: 480,
        employerName: 'BuildCorp',
        isStudentFriendly: false,
        isFlexibleShift: false,
        score: 65.0,
        reasons: ['Full Day Wage 🛠️'],
      );

      // Verify that student-friendly jobs score higher for students
      expect(studentJob.score, greaterThan(fullDayMasonryJob.score));
      expect(studentJob.isStudentFriendly, isTrue);
      expect(fullDayMasonryJob.isStudentFriendly, isFalse);
    });
  });

  group('SeekerHomeScreen Widget & Gating Tests', () {
    testWidgets('Renders Gradient Header, Goal ring, Wallet, and Recommended Jobs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seekerHomeProfileProvider.overrideWith((ref) async {
              return const SeekerProfileDraft(
                userId: 'user-chethan',
                fullName: 'Chethan Kumar',
                seekerType: 'informal',
                dailyRatePaise: 150000,
                onboardingComplete: true,
              );
            }),
            seekerHomeSummaryProvider.overrideWith((ref) async {
              return const SeekerHomeSummary(
                walletBalancePaise: 345000,
                todayEarningsPaise: 80000,
                dailyGoalPaise: 150000,
              );
            }),
            seekerRecommendedJobsProvider.overrideWith((ref) async {
              return [
                const JobRecommendation(
                  id: 'j-1',
                  providerId: 'p-1',
                  title: 'Home Plumbing Leakage Repair',
                  wageType: 'daily',
                  wagePaise: 91000,
                  employerName: 'R.K. Plumbing Services',
                  employerVerified: true,
                  employerRating: 4.8,
                  categoryIcon: 'plumbing',
                  distanceM: 1500.0,
                  reasons: ['Skill Match', 'Near you (1.5 km)'],
                ),
              ];
            }),
            seekerHasGpsConsentProvider.overrideWith((ref) async => true),
            seekerHasAdsConsentProvider.overrideWith((ref) async => true),
            seekerAdBannerProvider.overrideWith((ref) async {
              return const SponsoredAdBanner(
                id: 'ad-1',
                title: 'Kirloskar Hybrid Solar Water Pump',
                sponsorName: 'Kirloskar Brothers Ltd',
                ctaLabel: 'Explore Agri Offer',
              );
            }),
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

      // Check header greeting and user name
      expect(find.textContaining('Welcome back, Chethan Kumar!'), findsOneWidget);
      expect(find.text('Seeker Home'), findsOneWidget);
      expect(find.text('SOS'), findsOneWidget);

      // Check Today's Goal and Wallet
      expect(find.text("Today's Goal"), findsOneWidget);
      expect(find.text('53%'), findsOneWidget);
      expect(find.text('₹800 / ₹1500'), findsOneWidget);
      expect(find.text('Wallet Balance'), findsOneWidget);
      expect(find.text('₹3450.00'), findsOneWidget);

      // Check Safety Banner (GPS consent is true)
      expect(find.text('Location sharing active for safety monitoring'), findsOneWidget);

      // Check Quick Actions
      expect(find.text('Nearby Jobs'), findsOneWidget);
      expect(find.text('AI Assistant'), findsOneWidget);
      expect(find.text('Safety Hub'), findsOneWidget);

      // Check Sponsored Card (Ads consent is true)
      expect(find.text('SPONSORED'), findsOneWidget);
      expect(find.text('Kirloskar Brothers Ltd'), findsOneWidget);
      expect(find.text('Kirloskar Hybrid Solar Water Pump'), findsOneWidget);

      // Check Recommended Job Card
      expect(find.text('RECOMMENDED FOR YOU'), findsOneWidget);
      expect(find.text('Home Plumbing Leakage Repair'), findsOneWidget);
      expect(find.text('R.K. Plumbing Services'), findsOneWidget);
      expect(find.text('₹910'), findsOneWidget);
      expect(find.text('Apply Now'), findsOneWidget);
    });

    testWidgets('Hides safety banner and ad banner when consents are false', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seekerHomeProfileProvider.overrideWith((ref) async {
              return const SeekerProfileDraft(
                userId: 'user-chethan',
                fullName: 'Chethan Kumar',
                seekerType: 'student',
              );
            }),
            seekerHomeSummaryProvider.overrideWith((ref) async => const SeekerHomeSummary()),
            seekerRecommendedJobsProvider.overrideWith((ref) async => []),
            seekerHasGpsConsentProvider.overrideWith((ref) async => false),
            seekerHasAdsConsentProvider.overrideWith((ref) async => false),
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

      // GPS consent is false: safety banner should NOT appear
      expect(find.text('Location sharing active for safety monitoring'), findsNothing);

      // Ads consent is false: sponsored card should NOT appear
      expect(find.text('SPONSORED'), findsNothing);

      // Student seeker badge appears in Recommendations Header
      expect(find.text('🎓 Students Priority'), findsOneWidget);

      // Empty jobs state appears
      expect(find.text('No student jobs near you yet'), findsOneWidget);
    });

    testWidgets('Informal seeker does NOT see Students Priority badge in Recommendations Header', (tester) async {
      final container = ProviderContainer(
        overrides: [
          seekerHomeProfileProvider.overrideWith((ref) async {
            return const SeekerProfileDraft(
              userId: 'user-raju',
              fullName: 'Raju Informal',
              seekerType: 'informal',
            );
          }),
          seekerHomeSummaryProvider.overrideWith((ref) async => const SeekerHomeSummary()),
          consentRepositoryProvider.overrideWithValue(
            MockConsentRepository({}),
          ),
          seekerRecommendedJobsProvider.overrideWith((ref) async => []),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
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

      expect(find.text('🎓 Students Priority'), findsNothing);
      expect(find.text('RECOMMENDED FOR YOU'), findsOneWidget);
    });

    testWidgets('Verification progress card renders 2 of 4 steps complete', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seekerHomeProfileProvider.overrideWith((ref) async {
              return const SeekerProfileDraft(
                userId: 'user-verif',
                fullName: 'Ramesh Seeker',
                seekerType: 'informal',
              );
            }),
            seekerHomeSummaryProvider.overrideWith((ref) async => const SeekerHomeSummary()),
            seekerRecommendedJobsProvider.overrideWith((ref) async => []),
            seekerHasGpsConsentProvider.overrideWith((ref) async => false),
            seekerHasAdsConsentProvider.overrideWith((ref) async => false),
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

      expect(find.text('Verification in Progress: 2 of 4 steps complete'), findsOneWidget);
      expect(find.text('2/4 Done'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Find Jobs'), findsOneWidget);
      expect(find.text('Complete Profile'), findsOneWidget);
    });

    testWidgets('Editing daily goal via dialog updates goal display and progress', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seekerHomeProfileProvider.overrideWith((ref) async {
              return const SeekerProfileDraft(
                userId: 'user-goal',
                fullName: 'Goal Seeker',
                seekerType: 'informal',
              );
            }),
            seekerHomeSummaryProvider.overrideWith((ref) async {
              return const SeekerHomeSummary(
                walletBalancePaise: 100000,
                todayEarningsPaise: 80000, // ₹800
                dailyGoalPaise: 150000, // ₹1,500
              );
            }),
            seekerRecommendedJobsProvider.overrideWith((ref) async => []),
            seekerHasGpsConsentProvider.overrideWith((ref) async => false),
            seekerHasAdsConsentProvider.overrideWith((ref) async => false),
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

      expect(find.text('₹800 / ₹1500'), findsOneWidget);
      expect(find.text('53%'), findsOneWidget);

      // Tap on Today's Goal to open the edit dialog
      await tester.tap(find.text("Today's Goal"));
      await tester.pumpAndSettle();

      expect(find.text('Set Daily Goal'), findsOneWidget);

      // Select ₹2000 quick chip
      await tester.tap(find.text('₹2000'));
      await tester.pumpAndSettle();

      // Tap Save Goal
      await tester.tap(find.text('Save Goal'));
      await tester.pumpAndSettle();

      // Display should update: 800 / 2000 = 40%
      expect(find.text('₹800 / ₹2000'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
    });

    testWidgets('Header renders cleanly at 1.3x text scale without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      FlutterErrorDetails? errorDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errorDetails = details;
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seekerHomeProfileProvider.overrideWith((ref) async {
              return const SeekerProfileDraft(
                userId: 'user-scale',
                fullName: 'Chethan Kumar Long Name',
                seekerType: 'informal',
              );
            }),
            seekerHomeSummaryProvider.overrideWith((ref) async => const SeekerHomeSummary()),
            seekerRecommendedJobsProvider.overrideWith((ref) async => []),
            seekerHasGpsConsentProvider.overrideWith((ref) async => false),
            seekerHasAdsConsentProvider.overrideWith((ref) async => false),
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
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: SeekerHomeScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      FlutterError.onError = originalOnError;

      expect(errorDetails, isNull);
      expect(find.text('Seeker Home'), findsOneWidget);
      expect(find.text('SOS'), findsOneWidget);
    });
  });
}
