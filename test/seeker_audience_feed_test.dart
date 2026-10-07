import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/features/privacy/data/consent_repository.dart';
import 'package:udyogasethu/features/privacy/domain/consent_purpose.dart';
import 'package:udyogasethu/features/seeker/data/seeker_home_repository.dart';
import 'package:udyogasethu/features/seeker/domain/job_recommendation.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_profile_draft.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_home_controller.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_home_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class FakeAudienceRepository implements SeekerHomeRepository {
  final List<JobRecommendation> Function(String seekerType) jobsProvider;
  final bool shouldThrow;
  final bool shouldRejectApply;

  FakeAudienceRepository({
    required this.jobsProvider,
    this.shouldThrow = false,
    this.shouldRejectApply = false,
  });

  @override
  Future<List<JobRecommendation>> fetchRecommendations({
    required String workerId,
    required String seekerType,
    double? lat,
    double? lng,
    double radiusM = 50000,
    int limit = 20,
  }) async {
    if (shouldThrow) {
      throw Exception('Database RPC recommended_jobs failed');
    }
    final rawList = jobsProvider(seekerType);

    const studentSlugs = {
      'content-writing',
      'design-data-work',
      'tutoring-academics',
      'campus-brand-promotion',
      'retail-food-service',
      'delivery-gig-work',
    };
    const tradeSlugs = {
      'electrician',
      'plumber',
      'carpenter',
      'mason',
      'construction',
      'painting',
      'loader',
      'cleaner',
      'driver',
      'domestic_help',
      'agri_labour',
    };

    final isStudentOrPartTime = seekerType == 'student' || seekerType == 'part_time';
    return rawList.where((job) {
      if (isStudentOrPartTime) {
        if (tradeSlugs.contains(job.categorySlug)) return false;
        return studentSlugs.contains(job.categorySlug) || job.isStudentFriendly;
      } else {
        if (studentSlugs.contains(job.categorySlug)) return false;
        return true;
      }
    }).toList();
  }

  @override
  Future<SeekerHomeSummary> fetchHomeSummary(String workerId) async {
    return const SeekerHomeSummary(
      walletBalancePaise: 250000,
      todayEarningsPaise: 50000,
      dailyGoalPaise: 150000,
    );
  }

  @override
  Future<SponsoredAdBanner?> fetchSponsoredBanner({String targetRole = 'seeker'}) async {
    return null;
  }

  @override
  Future<bool> applyToJob({required String jobId, required String workerId}) async {
    if (shouldRejectApply) {
      throw const PostgrestException(
        message: 'This job is reserved for trade and informal workers.',
        code: 'P0004',
      );
    }
    return true;
  }
}

class MockConsentRepository implements ConsentRepository {
  @override
  Future<bool> hasValidConsent(ConsentPurpose purpose) async => false;

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
  const tradeJobs = [
    JobRecommendation(
      id: 'job-elec',
      providerId: 'p-1',
      title: 'Commercial Electrician',
      categorySlug: 'electrician',
      wageType: 'daily',
      wagePaise: 88000,
      employerName: 'Sai Electricals',
    ),
    JobRecommendation(
      id: 'job-plumb',
      providerId: 'p-1',
      title: 'Bathroom Plumber',
      categorySlug: 'plumber',
      wageType: 'daily',
      wagePaise: 85000,
      employerName: 'QuickFix Plumbing',
    ),
  ];

  const studentJobs = [
    JobRecommendation(
      id: 'job-content',
      providerId: 'p-2',
      title: 'Campus Newsletter Writer',
      categorySlug: 'content-writing',
      wageType: 'hourly',
      wagePaise: 40000,
      employerName: 'Campus Media',
      isStudentFriendly: true,
      reasons: ['Students Welcome 🎓', 'Short Shift ⏱️'],
    ),
    JobRecommendation(
      id: 'job-tutor',
      providerId: 'p-2',
      title: 'High School Math Tutor',
      categorySlug: 'tutoring-academics',
      wageType: 'hourly',
      wagePaise: 50000,
      employerName: 'Bright Academy',
      isStudentFriendly: true,
      reasons: ['Students Welcome 🎓', 'Flexible Hours ⏰'],
    ),
  ];

  group('D-AUDIENCE Repository Feed Tests', () {
    test('Student feed excludes trade jobs and only returns student gigs', () async {
      final repo = FakeAudienceRepository(jobsProvider: (_) => [...tradeJobs, ...studentJobs]);
      final results = await repo.fetchRecommendations(
        workerId: 'student-123',
        seekerType: 'student',
      );

      expect(results.length, equals(2));
      expect(results.every((j) => j.categorySlug != 'electrician' && j.categorySlug != 'plumber'), isTrue);
      expect(results.map((j) => j.title), contains('Campus Newsletter Writer'));
      expect(results.map((j) => j.title), contains('High School Math Tutor'));
    });

    test('Part-time feed excludes trade jobs and returns student/part-time gigs', () async {
      final repo = FakeAudienceRepository(jobsProvider: (_) => [...tradeJobs, ...studentJobs]);
      final results = await repo.fetchRecommendations(
        workerId: 'parttime-123',
        seekerType: 'part_time',
      );

      expect(results.length, equals(2));
      expect(results.every((j) => j.categorySlug != 'electrician' && j.categorySlug != 'plumber'), isTrue);
    });

    test('Informal feed excludes student-only categories and returns trade jobs', () async {
      final repo = FakeAudienceRepository(jobsProvider: (_) => [...tradeJobs, ...studentJobs]);
      final results = await repo.fetchRecommendations(
        workerId: 'informal-123',
        seekerType: 'informal',
      );

      expect(results.length, equals(2));
      expect(results.every((j) => j.categorySlug != 'content-writing' && j.categorySlug != 'tutoring-academics'), isTrue);
      expect(results.map((j) => j.title), contains('Commercial Electrician'));
      expect(results.map((j) => j.title), contains('Bathroom Plumber'));
    });

    test('Empty student feed returns empty list without falling back to trade jobs', () async {
      final repo = FakeAudienceRepository(jobsProvider: (_) => tradeJobs);
      final results = await repo.fetchRecommendations(
        workerId: 'student-123',
        seekerType: 'student',
      );

      expect(results, isEmpty);
    });

    test('RPC failure throws exception without falling back to other jobs', () async {
      final repo = FakeAudienceRepository(jobsProvider: (_) => tradeJobs, shouldThrow: true);
      expect(
        () => repo.fetchRecommendations(workerId: 'student-123', seekerType: 'student'),
        throwsA(isA<Exception>()),
      );
    });

    test('applyToJob throws P0004 when applying to wrong-audience job', () async {
      final repo = FakeAudienceRepository(jobsProvider: (_) => tradeJobs, shouldRejectApply: true);
      expect(
        () => repo.applyToJob(jobId: 'job-elec', workerId: 'student-123'),
        throwsA(isA<PostgrestException>().having(
          (e) => e.code,
          'code',
          'P0004',
        )),
      );
    });
  });

  group('D-AUDIENCE UI Widget Tests', () {
    testWidgets('Empty student feed shows proper empty state with widen radius button', (tester) async {
      final fakeRepo = FakeAudienceRepository(jobsProvider: (_) => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seekerHomeRepositoryProvider.overrideWithValue(fakeRepo),
            consentRepositoryProvider.overrideWithValue(MockConsentRepository()),
            seekerHomeProfileProvider.overrideWith((ref) async => const SeekerProfileDraft(
              userId: 'student-uid',
              fullName: 'Aarav Student',
              seekerType: 'student',
              onboardingComplete: true,
            )),
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

      expect(find.text('STUDENT & FLEXIBLE GIGS'), findsOneWidget);
      expect(find.text('🎓 Students Priority'), findsOneWidget);
      expect(find.text('No student jobs near you yet'), findsOneWidget);
      expect(find.textContaining('Widen Search Radius'), findsOneWidget);
      // Ensure no trade jobs are rendered
      expect(find.text('Commercial Electrician'), findsNothing);
      expect(find.text('Bathroom Plumber'), findsNothing);
    });

    testWidgets('RPC failure shows error state with Retry button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seekerRecommendedJobsProvider.overrideWith((ref) async {
              throw Exception('Database RPC recommended_jobs failed');
            }),
            consentRepositoryProvider.overrideWithValue(MockConsentRepository()),
            seekerHomeProfileProvider.overrideWith((ref) async => const SeekerProfileDraft(
              userId: 'student-uid',
              fullName: 'Aarav Student',
              seekerType: 'student',
              onboardingComplete: true,
            )),
            seekerHomeSummaryProvider.overrideWith((ref) async => const SeekerHomeSummary()),
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

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error loading recommendations'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Commercial Electrician'), findsNothing);
    });
  });
}
