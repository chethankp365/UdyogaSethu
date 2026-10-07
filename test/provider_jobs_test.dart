import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/provider/data/provider_jobs_repository.dart';
import 'package:udyogasethu/features/provider/domain/job_applicant.dart';
import 'package:udyogasethu/features/provider/domain/job_post_draft.dart';
import 'package:udyogasethu/features/provider/domain/provider_job.dart';
import 'package:udyogasethu/features/provider/presentation/job_applicants_screen.dart';
import 'package:udyogasethu/features/provider/presentation/post_job_wizard_screen.dart';
import 'package:udyogasethu/features/provider/presentation/provider_home_screen.dart';
import 'package:udyogasethu/features/provider/presentation/provider_jobs_controller.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_profile_draft.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class FakeProviderJobsRepository implements ProviderJobsRepository {
  List<ProviderJob> jobs;
  List<JobApplicant> applicants;
  WageBandResult? wageBand;
  List<ServiceCategoryItem> categories;
  JobPostDraft? lastPostedDraft;
  String? lastUpdatedStatus;

  FakeProviderJobsRepository({
    List<ProviderJob>? initialJobs,
    List<JobApplicant>? initialApplicants,
    this.wageBand,
    List<ServiceCategoryItem>? initialCategories,
  })  : jobs = initialJobs ?? _sampleJobs(),
        applicants = initialApplicants ?? _sampleApplicants(),
        categories = initialCategories ?? _sampleCategories();

  static List<ProviderJob> _sampleJobs() {
    return [
      ProviderJob(
        id: 'job-1',
        providerId: 'prov-1',
        title: 'Construction Helper',
        categoryName: 'Construction',
        wagePaise: 70000,
        wageType: 'daily',
        slotsTotal: 3,
        slotsFilled: 1,
        paymentMode: 'escrow',
        status: 'open',
        startAt: DateTime(2026, 10, 15, 9, 0),
        createdAt: DateTime(2026, 10, 7),
        applicantCount: 2,
      ),
      ProviderJob(
        id: 'job-2',
        providerId: 'prov-1',
        title: 'Senior Electrician',
        categoryName: 'Electrician',
        wagePaise: 95000,
        wageType: 'daily',
        slotsTotal: 1,
        slotsFilled: 1,
        paymentMode: 'escrow',
        status: 'filled',
        startAt: DateTime(2026, 10, 16, 9, 0),
        createdAt: DateTime(2026, 10, 6),
        applicantCount: 1,
      ),
      ProviderJob(
        id: 'job-3',
        providerId: 'prov-1',
        title: 'Plumbing Repair',
        categoryName: 'Plumbing',
        wagePaise: 80000,
        wageType: 'fixed',
        slotsTotal: 2,
        slotsFilled: 2,
        paymentMode: 'upi',
        status: 'closed',
        startAt: DateTime(2026, 10, 1, 9, 0),
        createdAt: DateTime(2026, 9, 30),
      ),
    ];
  }

  static List<JobApplicant> _sampleApplicants() {
    return [
      JobApplicant(
        applicationId: 'app-1',
        jobId: 'job-1',
        workerId: 'worker-101',
        status: 'applied',
        message: 'Available immediately. 5 years experience.',
        createdAt: DateTime(2026, 10, 7, 10, 0),
        workerName: 'Ramesh Kumar',
        isVerified: true,
        rating: 4.9,
        reviewCount: 14,
        jobsCompletedCount: 18,
        distanceM: 1200,
        languages: const ['kn', 'hi'],
        skills: const ['Masonry', 'Concrete Mixing'],
      ),
      JobApplicant(
        applicationId: 'app-2',
        jobId: 'job-1',
        workerId: 'worker-102',
        status: 'applied',
        message: 'Experienced helper.',
        createdAt: DateTime(2026, 10, 7, 11, 0),
        workerName: 'Suresh Patil',
        isVerified: false,
        rating: 4.6,
        reviewCount: 5,
        jobsCompletedCount: 4,
        distanceM: 850,
        languages: const ['kn'],
        skills: const ['Material Handling'],
      ),
    ];
  }

  static List<ServiceCategoryItem> _sampleCategories() {
    return const [
      ServiceCategoryItem(
        id: 'cat-1',
        slug: 'construction',
        names: {'en': 'Construction Helper', 'kn': 'ಕಟ್ಟಡ ಸಹಾಯಕ'},
        icon: 'construction',
      ),
      ServiceCategoryItem(
        id: 'cat-2',
        slug: 'electrician',
        names: {'en': 'Electrician', 'kn': 'ಎಲೆಕ್ಟ್ರಿಷಿಯನ್'},
        icon: 'electrical_services',
      ),
    ];
  }

  @override
  Future<List<ProviderJob>> fetchProviderJobs({String? providerId}) async => jobs;

  @override
  Future<List<JobApplicant>> fetchJobApplicants(String jobId) async {
    return applicants.where((a) => a.jobId == jobId).toList();
  }

  @override
  Future<String> postJob(JobPostDraft draft) async {
    lastPostedDraft = draft;
    final newJob = ProviderJob(
      id: 'new-job-999',
      providerId: 'prov-1',
      title: draft.title,
      categoryName: draft.categoryName ?? 'General',
      wagePaise: draft.wagePaise,
      wageType: draft.wageType,
      slotsTotal: draft.slotsTotal,
      slotsFilled: 0,
      paymentMode: draft.paymentMode,
      startAt: draft.startAt,
      createdAt: DateTime.now(),
    );
    jobs.add(newJob);
    return newJob.id;
  }

  @override
  Future<bool> updateJob(JobPostDraft draft) async {
    lastPostedDraft = draft;
    return true;
  }

  @override
  Future<Map<String, dynamic>> updateJobStatus(String jobId, String status) async {
    lastUpdatedStatus = status;
    return {'success': true, 'affected_assignments': 0, 'had_hired_workers': false};
  }

  @override
  Future<String?> respondToApplicant({required String applicationId, required String status}) async {
    final idx = applicants.indexWhere((a) => a.applicationId == applicationId);
    if (idx != -1) {
      applicants[idx] = applicants[idx].copyWith(status: status);
      if (status == 'hired') {
        final jobIdx = jobs.indexWhere((j) => j.id == applicants[idx].jobId);
        if (jobIdx != -1) {
          final cur = jobs[jobIdx];
          jobs[jobIdx] = ProviderJob(
            id: cur.id,
            providerId: cur.providerId,
            categoryName: cur.categoryName,
            title: cur.title,
            wagePaise: cur.wagePaise,
            startAt: cur.startAt,
            createdAt: cur.createdAt,
            slotsTotal: cur.slotsTotal,
            slotsFilled: cur.slotsFilled + 1,
            status: cur.slotsFilled + 1 >= cur.slotsTotal ? 'filled' : cur.status,
          );
        }
      }
    }
    return 'assignment-uuid-1';
  }

  @override
  Future<WageBandResult?> fetchWageBand({required String categoryId, String? area}) async {
    return wageBand ??
        const WageBandResult(
          minPaise: 65000,
          maxPaise: 90000,
          unit: 'day',
        );
  }

  @override
  Future<List<ServiceCategoryItem>> fetchCategories() async => categories;
}

Widget createTestApp(Widget child, FakeProviderJobsRepository fakeRepo) {
  return ProviderScope(
    overrides: [
      providerJobsRepositoryProvider.overrideWithValue(fakeRepo),
      serviceCategoriesListProvider.overrideWith((ref) => fakeRepo.fetchCategories()),
      providerJobsNotifierProvider.overrideWith(() => _TestJobsNotifier(fakeRepo)),
      jobApplicantsFutureProvider.overrideWith((ref, jobId) => fakeRepo.fetchJobApplicants(jobId)),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    ),
  );
}

class _TestJobsNotifier extends ProviderJobsNotifier {
  final FakeProviderJobsRepository _fakeRepo;
  _TestJobsNotifier(this._fakeRepo);

  @override
  Future<List<ProviderJob>> build() async {
    return _fakeRepo.jobs;
  }
}

void main() {
  group('P4.4 Domain Models & Wage Band Logic', () {
    test('JobPostDraft correctly identifies below and within fair wage band', () {
      final draft = JobPostDraft(
        title: 'Helper',
        wagePaise: 50000, // ₹500
        minWagePaiseHint: 65000, // ₹650
        maxWagePaiseHint: 90000, // ₹900
        startAt: DateTime.now(),
      );

      expect(draft.isBelowFairWage, isTrue);
      expect(draft.isAboveFairWage, isFalse);

      final fairDraft = draft.copyWith(wagePaise: 75000); // ₹750
      expect(fairDraft.isBelowFairWage, isFalse);
      expect(fairDraft.isAboveFairWage, isFalse);

      final highDraft = draft.copyWith(wagePaise: 100000); // ₹1000
      expect(highDraft.isBelowFairWage, isFalse);
      expect(highDraft.isAboveFairWage, isTrue);
    });

    test('ProviderJob calculates open slots and status properties properly', () {
      final jobOpen = ProviderJob(
        id: 'j1',
        providerId: 'p1',
        categoryName: 'General',
        title: 'Helper',
        wagePaise: 70000,
        startAt: DateTime.now(),
        createdAt: DateTime.now(),
        slotsTotal: 3,
        slotsFilled: 1,
        status: 'open',
      );

      expect(jobOpen.slotsOpen, 2);
      expect(jobOpen.isOpen, isTrue);
      expect(jobOpen.isFilled, isFalse);
      expect(jobOpen.formattedWage, '₹700/day');

      final jobFilled = ProviderJob(
        id: 'j2',
        providerId: 'p1',
        categoryName: 'General',
        title: 'Helper',
        wagePaise: 70000,
        startAt: DateTime.now(),
        createdAt: DateTime.now(),
        slotsTotal: 2,
        slotsFilled: 2,
        status: 'filled',
      );

      expect(jobFilled.slotsOpen, 0);
      expect(jobFilled.isFilled, isTrue);
      expect(jobFilled.isOpen, isFalse);
    });

    test('JobApplicant computes formatted distance and status badges', () {
      final appNear = JobApplicant(
        applicationId: 'a1',
        jobId: 'j1',
        workerId: 'w1',
        status: 'applied',
        createdAt: DateTime.now(),
        workerName: 'Ramesh',
        distanceM: 750,
      );

      expect(appNear.formattedDistance, '750 m away');
      expect(appNear.isPending, isTrue);
      expect(appNear.isHired, isFalse);

      final appFar = JobApplicant(
        applicationId: 'a2',
        jobId: 'j1',
        workerId: 'w2',
        status: 'hired',
        createdAt: DateTime.now(),
        workerName: 'Suresh',
        distanceM: 2400,
      );

      expect(appFar.formattedDistance, '2.4 km away');
      expect(appFar.isHired, isTrue);
    });
  });

  group('P4.4 Provider Home Screen & Segments', () {
    testWidgets('Renders My Jobs with Open, Filled, and Completed tabs and slot counters', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeProviderJobsRepository();
      await tester.pumpWidget(createTestApp(const ProviderHomeScreen(), fakeRepo));
      await tester.pumpAndSettle();

      // Check My Jobs title and tabs
      expect(find.text('My Jobs'), findsOneWidget);
      expect(find.text('Open (1)'), findsOneWidget);
      expect(find.text('Filled (1)'), findsOneWidget);
      expect(find.text('Completed (1)'), findsOneWidget);

      // Open tab job card
      expect(find.text('Construction Helper'), findsOneWidget);
      expect(find.text('1 / 3 Slots Filled'), findsOneWidget);
      expect(find.text('2 Open'), findsOneWidget);
      expect(find.text('View Applicants'), findsOneWidget);

      // Tap on Filled tab
      await tester.ensureVisible(find.text('Filled (1)'));
      await tester.tap(find.text('Filled (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Senior Electrician'), findsOneWidget);
      expect(find.text('1 / 1 Slots Filled'), findsOneWidget);
      expect(find.text('Fully Filled'), findsOneWidget);

      // Tap on Completed tab
      await tester.ensureVisible(find.text('Completed (1)'));
      await tester.tap(find.text('Completed (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Plumbing Repair'), findsOneWidget);
    });
  });

  group('P4.4 Applicants Screen & Hiring Flow', () {
    testWidgets('Renders worker card details and allows hiring applicant with slot decrement', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeProviderJobsRepository();
      await tester.pumpWidget(createTestApp(const JobApplicantsScreen(jobId: 'job-1'), fakeRepo));
      await tester.pumpAndSettle();

      // Check header slot counter
      expect(find.text('1 / 3 Slots Filled'), findsOneWidget);
      expect(find.text('2 Open'), findsOneWidget);

      // Worker card details
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('Suresh Patil'), findsOneWidget);
      expect(find.text('Masonry'), findsOneWidget);
      expect(find.text('Concrete Mixing'), findsOneWidget);
      expect(find.text('1.2 km away'), findsOneWidget);

      // Find Hire buttons (should be 2 for 2 applied workers)
      final hireButtons = find.widgetWithText(ElevatedButton, 'Hire');
      expect(hireButtons, findsNWidgets(2));

      // Tap Hire on first applicant
      await tester.tap(hireButtons.first);
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Hire Worker?'), findsOneWidget);
      expect(find.text('Hiring Ramesh Kumar will assign them 1 slot on this job. They will receive a booking notification.'), findsOneWidget);

      // Confirm Hire
      final confirmBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Hire'),
      );
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verified status updated to Hired in fake repo
      expect(fakeRepo.applicants.first.status, 'hired');
      // Job slots filled incremented from 1 to 2
      expect(fakeRepo.jobs.first.slotsFilled, 2);
    });
  });

  group('P4.4 Post Job Wizard & Fair Wage Band Hint', () {
    testWidgets('Wizard steps forward, shows fair wage band, warns without blocking when below band', (tester) async {
      final fakeRepo = FakeProviderJobsRepository();
      await tester.pumpWidget(createTestApp(const PostJobWizardScreen(), fakeRepo));
      await tester.pumpAndSettle();

      // Step 1: Category & Title
      expect(find.text('Category & Title'), findsWidgets);
      expect(find.text('Select Work Category'), findsOneWidget);
      expect(find.text('Construction Helper'), findsOneWidget);

      // Select Category
      await tester.tap(find.text('Construction Helper'));
      await tester.pumpAndSettle();

      // Enter Title
      await tester.enterText(find.byType(TextField).first, 'Site Helper Needed');
      await tester.pumpAndSettle();

      // Advance to Step 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 2: Wages & Schedule
      expect(find.text('Wages & Schedule'), findsWidgets);
      expect(find.text('Wage Type'), findsOneWidget);
      expect(find.text('Fair Wage Band: ₹650 - ₹900 / day'), findsOneWidget);

      // Enter a below-band wage (e.g. ₹500)
      final wageField = find.widgetWithText(TextField, '700');
      await tester.enterText(wageField, '500');
      await tester.pumpAndSettle();

      // Amber warning alert MUST be visible
      expect(find.textContaining('Wage is below the recommended fair wage band (₹650 - ₹900)'), findsOneWidget);

      // CRITICAL REQUIREMENT: "warn, never block, when below the band"
      // User must be able to tap Next and proceed to Step 3 even with wage below band!
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Successfully reached Step 3: Slots & Payment!
      expect(find.text('Slots & Payment'), findsWidgets);
      expect(find.text('Number of Workers Needed (Slots)'), findsOneWidget);
      expect(find.text('Protected Escrow (Recommended)'), findsOneWidget);

      // Increment slots
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('2 Workers'), findsOneWidget);

      // Step 4: Requirements & Location
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Requirements & Location'), findsWidgets);
      expect(find.text('Worker Requirements'), findsOneWidget);
      expect(find.text('Background & Identity Verified Only'), findsOneWidget);
      expect(find.text('Geofence Check-in Radius'), findsOneWidget);

      // Step 5: Preview & Publish
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Preview & Publish'), findsWidgets);
      expect(find.text('Publish Job Posting'), findsOneWidget);
      expect(find.text('Site Helper Needed'), findsOneWidget);
      expect(find.text('2 Slots'), findsOneWidget);
    });
  });
}
