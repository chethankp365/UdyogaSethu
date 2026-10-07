import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/seeker/data/job_detail_repository.dart';
import 'package:udyogasethu/features/seeker/data/seeker_jobs_repository.dart';
import 'package:udyogasethu/features/seeker/domain/job_detail.dart';
import 'package:udyogasethu/features/seeker/domain/job_eligibility.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_job_item.dart';
import 'package:udyogasethu/features/seeker/presentation/job_detail_screen.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_jobs_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class FakeJobDetailRepository implements JobDetailRepository {
  JobDetail sampleDetail;
  bool isOffline;
  JobEligibility sampleEligibility;
  bool applyShouldSucceed;
  String? lastAppliedMessage;

  FakeJobDetailRepository({
    JobDetail? detail,
    this.isOffline = false,
    JobEligibility? eligibility,
    this.applyShouldSucceed = true,
  })  : sampleDetail = detail ?? _createSampleDetail(),
        sampleEligibility = eligibility ?? const JobEligibility(isEligible: true);

  static JobDetail _createSampleDetail() {
    return JobDetail(
      id: 'job-101',
      providerId: 'prov-202',
      providerName: 'Sharma Builders',
      providerVerified: true,
      providerRating: 4.9,
      title: 'Commercial Electrician Helper',
      description: 'Assist master electrician with conduit installation and wire pulling on commercial site.',
      categorySlug: 'electrician',
      categoryIcon: 'electrical_services',
      wagePaise: 85000,
      wageType: 'daily',
      estDurationMinutes: 480,
      startAt: DateTime(2026, 10, 15, 9, 0),
      materialsProvided: true,
      paymentMode: 'escrow',
      slotsTotal: 4,
      slotsFilled: 1,
      distanceKm: 2.4,
      walkingMinutes: 28,
    );
  }

  @override
  Future<({JobDetail detail, bool isOffline})> fetchJobDetail(String jobId) async {
    return (detail: sampleDetail, isOffline: isOffline);
  }

  @override
  Future<JobEligibility> checkEligibility(String jobId) async {
    return sampleEligibility;
  }

  @override
  Future<String> applyToJob({required String jobId, String? message}) async {
    lastAppliedMessage = message;
    if (!applyShouldSucceed) {
      throw Exception('Eligibility check failed');
    }
    return 'app-uuid-999';
  }
}

class FakeSeekerJobsRepository implements SeekerJobsRepository {
  Map<SeekerJobSegment, List<SeekerJobItem>> jobs;
  Set<String> acceptedIds = {};
  bool travelWarningNext = false;
  double? gapMinutesNext;
  bool failOverlapping = true;

  FakeSeekerJobsRepository({
    Map<SeekerJobSegment, List<SeekerJobItem>>? initialJobs,
  }) : jobs = initialJobs ?? _defaultJobs();

  static Map<SeekerJobSegment, List<SeekerJobItem>> _defaultJobs() {
    return {
      SeekerJobSegment.applied: [
        SeekerJobItem(
          id: 'app-1',
          jobId: 'job-101',
          title: 'Plumbing Assistant',
          providerName: 'Apex Plumbing',
          providerVerified: true,
          wagePaise: 75000,
          startAt: DateTime(2026, 10, 16, 9, 0),
          estDurationMinutes: 480,
          status: 'applied',
          segment: SeekerJobSegment.applied,
          categorySlug: 'plumbing',
          categoryIcon: 'plumbing',
          addressText: 'Indiranagar, Bengaluru',
        ),
      ],
      SeekerJobSegment.accepted: [],
      SeekerJobSegment.active: [],
      SeekerJobSegment.completed: [],
      SeekerJobSegment.requests: [
        SeekerJobItem(
          id: 'asg-req-1',
          jobId: 'job-slot-a',
          title: 'Morning Electrician Slot',
          providerName: 'Sai Electricals',
          providerVerified: true,
          wagePaise: 90000,
          startAt: DateTime(2026, 10, 15, 10, 0),
          estDurationMinutes: 240, // 10 AM to 2 PM
          status: 'invited',
          segment: SeekerJobSegment.requests,
          categorySlug: 'electrician',
          categoryIcon: 'electrical_services',
          addressText: 'Koramangala 4th Block, Bengaluru',
        ),
        SeekerJobItem(
          id: 'asg-req-2',
          jobId: 'job-slot-b',
          title: 'Afternoon Electrical Overlap Slot',
          providerName: 'Sharma Builders',
          providerVerified: true,
          wagePaise: 85000,
          startAt: DateTime(2026, 10, 15, 13, 0),
          estDurationMinutes: 240, // 1 PM to 5 PM (Overlaps with Slot A!)
          status: 'invited',
          segment: SeekerJobSegment.requests,
          categorySlug: 'electrician',
          categoryIcon: 'electrical_services',
          addressText: 'HSR Layout, Bengaluru',
        ),
      ],
    };
  }

  @override
  Future<Map<SeekerJobSegment, List<SeekerJobItem>>> fetchSeekerJobs() async {
    return Map.from(jobs);
  }

  @override
  Stream<Map<SeekerJobSegment, List<SeekerJobItem>>> watchSeekerJobs() async* {
    yield jobs;
  }

  @override
  Future<({bool travelWarning, double? gapMinutes})> acceptAssignment(String assignmentId) async {
    // Check overlap: if we already accepted an assignment on Oct 15 and this one overlaps
    if (failOverlapping && acceptedIds.isNotEmpty) {
      throw Exception('Worker has an overlapping job assignment at this time.');
    }

    acceptedIds.add(assignmentId);

    // Move from requests to accepted
    final reqs = List<SeekerJobItem>.from(jobs[SeekerJobSegment.requests] ?? []);
    final item = reqs.firstWhere((x) => x.id == assignmentId);
    reqs.removeWhere((x) => x.id == assignmentId);
    jobs[SeekerJobSegment.requests] = reqs;

    final acceptedList = List<SeekerJobItem>.from(jobs[SeekerJobSegment.accepted] ?? []);
    acceptedList.add(item.copyWith(status: 'accepted', segment: SeekerJobSegment.accepted));
    jobs[SeekerJobSegment.accepted] = acceptedList;

    return (
      travelWarning: travelWarningNext,
      gapMinutes: gapMinutesNext,
    );
  }

  @override
  Future<bool> declineAssignment(String assignmentId) async {
    final reqs = List<SeekerJobItem>.from(jobs[SeekerJobSegment.requests] ?? []);
    reqs.removeWhere((x) => x.id == assignmentId);
    jobs[SeekerJobSegment.requests] = reqs;
    return true;
  }

  @override
  Future<void> debugSeedOverlappingRequests() async {
    jobs = _defaultJobs();
    acceptedIds.clear();
  }
}

Widget createTestApp({
  required Widget child,
  FakeJobDetailRepository? detailRepo,
  FakeSeekerJobsRepository? seekerJobsRepo,
}) {
  return ProviderScope(
    overrides: [
      if (detailRepo != null) jobDetailRepositoryProvider.overrideWithValue(detailRepo),
      if (seekerJobsRepo != null) seekerJobsRepositoryProvider.overrideWithValue(seekerJobsRepo),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('kn')],
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P4.3 Job Detail Screen Tests', () {
    testWidgets('Renders all job details, chips, employer info, and specs table', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = FakeJobDetailRepository();
      await tester.pumpWidget(createTestApp(
        child: const JobDetailScreen(jobId: 'job-101'),
        detailRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      // Check title and employer
      expect(find.text('Commercial Electrician Helper'), findsWidgets);
      expect(find.text('Sharma Builders'), findsWidgets);
      expect(find.textContaining('Verified Employer'), findsWidgets);
      expect(find.textContaining('Background verified'), findsOneWidget);

      // Check specs chips
      expect(find.text('₹850/day'), findsWidgets);
      expect(find.text('2.4 km away'), findsOneWidget);
      expect(find.text('28 min walk'), findsOneWidget);

      // Check specs table (Screen 34 match)
      expect(find.text('8 hours'), findsOneWidget);
      expect(find.text('Provided by site'), findsOneWidget);
      expect(find.text('Daily Cash / Escrow'), findsOneWidget);
      expect(find.text('3 open (4 total)'), findsOneWidget);

      // Check action buttons
      expect(find.textContaining('Chat'), findsOneWidget);
      expect(find.textContaining('Apply Now'), findsOneWidget);
    });

    testWidgets('Offline banner is shown when cached offline and applying is disabled', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = FakeJobDetailRepository(isOffline: true);
      await tester.pumpWidget(createTestApp(
        child: const JobDetailScreen(jobId: 'job-101'),
        detailRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      // Check offline banner
      expect(find.textContaining('Offline Mode'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

      // Apply button should display offline state
      expect(find.textContaining('Offline - Reconnect to Apply'), findsOneWidget);
    });
  });

  group('P4.3 Pre-Application Eligibility & Apply Sheet Tests', () {
    testWidgets('Displays eligibility check and submits application successfully', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = FakeJobDetailRepository(
        eligibility: const JobEligibility(
          isEligible: true,
          licenceNeeded: true,
          hasLicence: true,
          verifiedNeeded: true,
          isVerified: true,
          scheduleOverlap: false,
          studentGated: false,
        ),
      );

      await tester.pumpWidget(createTestApp(
        child: const JobDetailScreen(jobId: 'job-101'),
        detailRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      // Tap Apply Now to open sheet
      await tester.tap(find.textContaining('Apply Now'));
      await tester.pumpAndSettle();

      // Eligibility bottom sheet should appear
      expect(find.textContaining('Apply for Commercial Electrician Helper'), findsOneWidget);
      expect(find.text('ELIGIBILITY & COMPATIBILITY CHECK'), findsOneWidget);
      expect(find.text('Driving Licence'), findsOneWidget);
      expect(find.text('Schedule Availability'), findsOneWidget);

      // Type an optional message
      final msgField = find.byType(TextField);
      expect(msgField, findsOneWidget);
      await tester.enterText(msgField, 'I have 2 years wiring experience.');
      await tester.pumpAndSettle();

      // Tap Confirm Application
      await tester.tap(find.text('Confirm Application ✈️'));
      await tester.pumpAndSettle();

      // Success screen
      expect(find.textContaining('Application Submitted!'), findsOneWidget);
      expect(fakeRepo.lastAppliedMessage, 'I have 2 years wiring experience.');
    });
  });

  group('P4.3 Seeker Jobs Segments & Double-Booking Prevention Tests', () {
    testWidgets('Renders all 5 segments and lists invitations in Requests segment', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = FakeSeekerJobsRepository();
      await tester.pumpWidget(createTestApp(
        child: const SeekerJobsScreen(),
        seekerJobsRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      // Verify all 5 segments exist
      expect(find.text('Applied'), findsWidgets);
      expect(find.text('Accepted'), findsWidgets);
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('Requests'), findsWidgets);

      // Switch to Requests segment
      await tester.tap(find.text('Requests').first);
      await tester.pumpAndSettle();

      // Two invitation cards should be present
      expect(find.text('Morning Electrician Slot'), findsOneWidget);
      expect(find.text('Afternoon Electrical Overlap Slot'), findsOneWidget);
      expect(find.text('Accept'), findsNWidgets(2));
      expect(find.text('Decline'), findsNWidgets(2));
      expect(find.text('Request More Details'), findsNWidgets(2));
    });

    testWidgets('Double-booking: Accepting second overlapping assignment is refused with clear reason', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = FakeSeekerJobsRepository();
      await tester.pumpWidget(createTestApp(
        child: const SeekerJobsScreen(),
        seekerJobsRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      // Go to Requests
      await tester.tap(find.text('Requests').first);
      await tester.pumpAndSettle();

      // Accept first invitation (Morning Electrician Slot)
      final acceptButtons = find.text('Accept');
      expect(acceptButtons, findsNWidgets(2));

      await tester.tap(acceptButtons.first);
      await tester.pumpAndSettle();

      // Morning slot is accepted and removed from Requests
      expect(fakeRepo.acceptedIds.contains('asg-req-1'), isTrue);
      expect(find.text('Morning Electrician Slot'), findsNothing);

      // Now attempt to accept the overlapping second invitation (Afternoon Electrical Overlap Slot)
      final remainingAccept = find.text('Accept');
      expect(remainingAccept, findsOneWidget);

      await tester.tap(remainingAccept);
      await tester.pumpAndSettle();

      // Clear refusal dialog should be displayed explaining schedule conflict
      expect(find.text('Schedule Conflict'), findsOneWidget);
      expect(find.textContaining('overlapping active or accepted job assignment'), findsOneWidget);
    });

    testWidgets('Travel time warning is displayed when gap is under 60 minutes', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = FakeSeekerJobsRepository();
      fakeRepo.failOverlapping = false;
      fakeRepo.travelWarningNext = true;
      fakeRepo.gapMinutesNext = 35.0;

      await tester.pumpWidget(createTestApp(
        child: const SeekerJobsScreen(),
        seekerJobsRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      // Go to Requests
      await tester.tap(find.text('Requests').first);
      await tester.pumpAndSettle();

      // Accept invitation
      await tester.tap(find.text('Accept').first);
      await tester.pumpAndSettle();

      // Travel Time Warning dialog should appear
      expect(find.text('Travel Time Warning'), findsOneWidget);
      expect(find.textContaining('35 min gap'), findsOneWidget);
    });
  });
}
