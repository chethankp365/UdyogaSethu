import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/features/job_execution/data/job_execution_repository.dart';
import 'package:udyogasethu/features/job_execution/domain/active_job_detail.dart';
import 'package:udyogasethu/features/job_execution/domain/assignment_event_item.dart';
import 'package:udyogasethu/features/job_execution/domain/job_ticket.dart';
import 'package:udyogasethu/features/job_execution/domain/job_verification.dart';
import 'package:udyogasethu/features/job_execution/domain/replacement_candidate.dart';
import 'package:udyogasethu/features/job_execution/domain/worker_schedule_item.dart';
import 'package:udyogasethu/features/job_execution/presentation/widgets/worker_not_arrived_sheet.dart';
import 'package:udyogasethu/features/job_execution/presentation/widgets/running_late_dialog.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class MockNoShowJobExecutionRepository implements JobExecutionRepository {
  bool extendWaitCalled = false;
  int? extendWaitMinutes;
  bool reportRunningLateCalled = false;
  int? reportedEtaMinutes;
  bool findReplacementsCalled = false;
  bool confirmReplacementCalled = false;
  String? confirmedReplacementWorkerId;

  final List<ReplacementCandidate> mockCandidates;

  MockNoShowJobExecutionRepository({required this.mockCandidates});

  @override
  Future<ActiveJobDetail> fetchActiveJob(String assignmentId) async =>
      throw UnimplementedError();

  @override
  Future<List<AssignmentEventItem>> fetchAssignmentEvents(String assignmentId) async =>
      [];

  @override
  Stream<List<AssignmentEventItem>> watchAssignmentEvents(String assignmentId) =>
      Stream.value([]);

  @override
  Future<void> advanceStage(String assignmentId, String nextStatus, {Map<String, dynamic>? meta}) async {}

  @override
  Future<List<WorkerScheduleItem>> fetchWorkerSchedule(String workerId, {DateTime? startDate, DateTime? endDate}) async =>
      [];

  @override
  Future<JobTicketData> fetchJobTicket(String assignmentId) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> refreshTicketQr(String assignmentId) async => {};

  @override
  Future<AttendanceScanResult> verifyAttendanceScan({required String qrToken, double? lat, double? lng}) async =>
      throw UnimplementedError();

  @override
  Future<JobGeofenceStatus> checkJobGeofence({required String jobId, required double lat, required double lng}) async =>
      const JobGeofenceStatus(distanceMeters: 40.0, radiusMeters: 150, withinGeofence: true);

  @override
  Future<JobVerificationResult> verifyJobStart({
    required String assignmentId,
    required double lat,
    required double lng,
    required bool isMocked,
    List<double>? embedding,
    String? selfiePath,
  }) async =>
      JobVerificationResult.successStart(status: 'in_progress_verified', distanceMeters: 40.0);

  @override
  Future<JobVerificationResult> verifyMidJobCheck({
    required String assignmentId,
    double? lat,
    double? lng,
    bool? isMocked,
    String? selfiePath,
  }) async =>
      JobVerificationResult.successMidJob(status: 'in_progress_verified', distanceMeters: 40.0);

  @override
  Future<JobVerificationResult> completeJob({
    required String assignmentId,
    double? lat,
    double? lng,
    bool? isMocked,
    String? selfiePath,
    List<String>? workPhotos,
    bool isCustomerConfirmed = false,
  }) async =>
      JobVerificationResult.successCompletion(status: 'completed', elapsedSeconds: 3600, paymentEligible: true);

  @override
  Future<String> uploadJobEvidence({
    required String assignmentId,
    required List<int> fileBytes,
    required String fileName,
  }) async =>
      'worker/evidence/$fileName';

  @override
  Future<int> checkNoShowAssignments() async => 1;

  @override
  Future<void> extendWait(String assignmentId, {int minutes = 10}) async {
    extendWaitCalled = true;
    extendWaitMinutes = minutes;
  }

  @override
  Future<void> reportRunningLate(String assignmentId, {required int etaMinutes}) async {
    reportRunningLateCalled = true;
    reportedEtaMinutes = etaMinutes;
  }

  @override
  Future<List<ReplacementCandidate>> findReplacementCandidates(String assignmentId) async {
    findReplacementsCalled = true;
    return mockCandidates;
  }

  @override
  Future<Map<String, dynamic>> confirmReplacement({
    required String assignmentId,
    required String replacementWorkerId,
  }) async {
    confirmReplacementCalled = true;
    confirmedReplacementWorkerId = replacementWorkerId;
    return {
      'success': true,
      'original_assignment_id': assignmentId,
      'new_assignment_id': 'new-assignment-999',
      'new_booking_code': 'REP-9999ABCD',
    };
  }
}

void main() {
  group('P4.10 Smart No-Show Recovery Domain Tests', () {
    test('ReplacementCandidate serializes and deserializes correctly', () {
      const candidate = ReplacementCandidate(
        workerId: 'worker-42',
        fullName: 'Manjunath Gowda',
        avatarUrl: 'https://example.com/avatar.jpg',
        rating: 4.9,
        distanceMeters: 1400.0,
        jobsCompleted: 35,
        isVerified: true,
        skills: ['Carpentry', 'Furniture Repair'],
      );

      final json = candidate.toJson();
      expect(json['worker_id'], 'worker-42');
      expect(json['full_name'], 'Manjunath Gowda');
      expect(json['rating'], 4.9);
      expect(json['distance_meters'], 1400.0);
      expect(json['jobs_completed'], 35);
      expect(json['is_verified'], true);
      expect(candidate.distanceKmDisplay, '1.4 km away');

      final parsed = ReplacementCandidate.fromJson(json);
      expect(parsed.workerId, candidate.workerId);
      expect(parsed.fullName, candidate.fullName);
      expect(parsed.skills, contains('Carpentry'));
      expect(parsed.isVerified, true);
    });

    test('ActiveJobDetail evaluates isLate and minutesPastScheduledArrival accurately', () {
      final pastStart = DateTime.now().subtract(const Duration(minutes: 25));
      final lateJob = ActiveJobDetail(
        assignmentId: 'assign-late',
        jobId: 'job-1',
        bookingCode: 'BOOK-LATE',
        status: 'ticket_issued',
        stage: AssignmentStage.ticketIssued,
        agreedWagePaise: 80000,
        jobTitle: 'Plumbing Emergency',
        startAt: pastStart,
        addressText: 'Indiranagar, Bengaluru',
        jobLat: 12.9716,
        jobLng: 77.6412,
        providerId: 'prov-1',
        providerName: 'Employer A',
        workerId: 'work-1',
        workerName: 'Late Worker',
        extendedGraceMinutes: 0,
      );

      // Default grace is 15 min. Past start was 25 min ago -> isLate should be true!
      expect(lateJob.isLate, isTrue);
      expect(lateJob.minutesPastScheduledArrival, greaterThanOrEqualTo(24));

      // With +15 min extended grace, effective grace is 30 min -> isLate should be false!
      final extendedJob = lateJob.copyWith(extendedGraceMinutes: 15);
      expect(extendedJob.isLate, isFalse);

      // If arrivedAt is set, isLate is false regardless of time
      final arrivedJob = lateJob.copyWith(arrivedAt: DateTime.now());
      expect(arrivedJob.isLate, isFalse);
    });
  });

  group('P4.10 UI Widget Tests', () {
    late MockNoShowJobExecutionRepository mockRepo;
    late ActiveJobDetail lateJob;
    late List<ReplacementCandidate> testCandidates;

    setUp(() {
      testCandidates = [
        const ReplacementCandidate(
          workerId: 'worker-rep-1',
          fullName: 'Ramesh Babu',
          rating: 4.9,
          distanceMeters: 800.0,
          jobsCompleted: 42,
          isVerified: true,
          skills: ['Plumbing', 'Pipe Repair'],
        ),
        const ReplacementCandidate(
          workerId: 'worker-rep-2',
          fullName: 'Kiran Kumar',
          rating: 4.7,
          distanceMeters: 1800.0,
          jobsCompleted: 19,
          isVerified: false,
          skills: ['Plumbing'],
        ),
      ];

      mockRepo = MockNoShowJobExecutionRepository(mockCandidates: testCandidates);

      lateJob = ActiveJobDetail(
        assignmentId: 'assign-123',
        jobId: 'job-100',
        bookingCode: 'BOOK-100',
        status: 'ticket_issued',
        stage: AssignmentStage.ticketIssued,
        agreedWagePaise: 75000,
        jobTitle: 'Water Leakage Repair',
        startAt: DateTime.now().subtract(const Duration(minutes: 20)),
        addressText: 'HSR Layout Sector 2',
        jobLat: 12.9121,
        jobLng: 77.6446,
        providerId: 'prov-1',
        providerName: 'Sunil Rao',
        workerId: 'late-worker-1',
        workerName: 'Suresh Kumar',
      );
    });

    Widget createTestApp(Widget child) {
      return ProviderScope(
        overrides: [
          jobExecutionRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('WorkerNotArrivedSheet renders and handles Wait 10 Minutes', (tester) async {
      bool actionCompleted = false;

      await tester.pumpWidget(
        createTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                WorkerNotArrivedSheet.show(
                  context,
                  jobDetail: lateJob,
                  onActionCompleted: () => actionCompleted = true,
                );
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap open sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify Alert Headers
      expect(find.text('Worker Has Not Arrived'), findsOneWidget);
      expect(find.text('Wait 10 Minutes'), findsOneWidget);
      expect(find.text('📞 Call Worker Directly'), findsOneWidget);
      expect(find.text('⚡ Find Smart Replacement Worker'), findsOneWidget);

      // Tap Wait 10 Minutes
      await tester.tap(find.text('Wait 10 Minutes'));
      await tester.pumpAndSettle();

      expect(mockRepo.extendWaitCalled, isTrue);
      expect(mockRepo.extendWaitMinutes, 10);
      expect(actionCompleted, isTrue);
    });

    testWidgets('WorkerNotArrivedSheet finds candidates and confirms replacement 1-tap', (tester) async {
      bool actionCompleted = false;

      await tester.pumpWidget(
        createTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                WorkerNotArrivedSheet.show(
                  context,
                  jobDetail: lateJob,
                  onActionCompleted: () => actionCompleted = true,
                );
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap open sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Tap Find Smart Replacement Worker
      await tester.tap(find.text('⚡ Find Smart Replacement Worker'));
      await tester.pumpAndSettle();

      expect(mockRepo.findReplacementsCalled, isTrue);
      expect(find.text('RANKED NEARBY WORKERS'), findsOneWidget);
      expect(find.text('Ramesh Babu'), findsOneWidget);
      expect(find.text('Kiran Kumar'), findsOneWidget);
      expect(find.text('Request Replacement (1-Tap)'), findsNWidgets(2));

      // Tap first candidate 1-tap request
      final requestBtn = find.text('Request Replacement (1-Tap)').first;
      await tester.ensureVisible(requestBtn);
      await tester.pumpAndSettle();
      await tester.tap(requestBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.confirmReplacementCalled, isTrue);
      expect(mockRepo.confirmedReplacementWorkerId, 'worker-rep-1');
      expect(actionCompleted, isTrue);
    });

    testWidgets('RunningLateDialog selects ETA and submits', (tester) async {
      bool reported = false;

      await tester.pumpWidget(
        createTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                RunningLateDialog.show(
                  context,
                  assignmentId: 'assign-123',
                  onReported: () => reported = true,
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Running Late?'), findsOneWidget);
      expect(find.text('+10 min'), findsOneWidget);
      expect(find.text('+30 min'), findsOneWidget);

      // Select +30 min chip
      await tester.tap(find.text('+30 min'));
      await tester.pumpAndSettle();

      // Tap Send ETA
      await tester.tap(find.text('Send ETA'));
      await tester.pumpAndSettle();

      expect(mockRepo.reportRunningLateCalled, isTrue);
      expect(mockRepo.reportedEtaMinutes, 30);
      expect(reported, isTrue);
    });
  });
}
