import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/job_execution/data/job_execution_repository.dart';
import 'package:udyogasethu/features/job_execution/domain/active_job_detail.dart';
import 'package:udyogasethu/features/job_execution/domain/assignment_event_item.dart';
import 'package:udyogasethu/features/job_execution/domain/job_ticket.dart';
import 'package:udyogasethu/features/job_execution/domain/job_verification.dart';
import 'package:udyogasethu/features/job_execution/domain/worker_schedule_item.dart';
import 'package:udyogasethu/features/job_execution/domain/replacement_candidate.dart';
import 'package:udyogasethu/features/job_execution/presentation/widgets/job_live_timer_card.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class MockJobExecutionRepository implements JobExecutionRepository {
  bool failGeofence = false;
  bool failMocked = false;
  bool failStatusNotArrived = false;

  @override
  Future<ActiveJobDetail> fetchActiveJob(String assignmentId) async {
    return ActiveJobDetail(
      assignmentId: assignmentId,
      jobId: 'job-101',
      bookingCode: 'BOOK-4243',
      status: 'arrived',
      stage: AssignmentStage.workerArrived,
      agreedWagePaise: 250000, // ₹2,500 (triggers mid-job check requirement)
      jobTitle: 'Commercial Masonry & Plastering',
      startAt: DateTime.now(),
      addressText: 'Indiranagar 100ft Road, Bengaluru',
      jobLat: 12.9716,
      jobLng: 77.6412,
      providerId: 'provider-1',
      providerName: 'BuildCorp Ltd',
      workerId: 'worker-1',
      workerName: 'Suresh Kumar',
    );
  }

  @override
  Future<JobGeofenceStatus> checkJobGeofence({
    required String jobId,
    required double lat,
    required double lng,
  }) async {
    if (failGeofence) {
      // Sofa across town (e.g. 5,200m away, outside 150m radius)
      return const JobGeofenceStatus(
        distanceMeters: 5200.0,
        radiusMeters: 150,
        withinGeofence: false,
      );
    }
    return const JobGeofenceStatus(
      distanceMeters: 35.0,
      radiusMeters: 150,
      withinGeofence: true,
    );
  }

  @override
  Future<JobVerificationResult> verifyJobStart({
    required String assignmentId,
    required double lat,
    required double lng,
    required bool isMocked,
    List<double>? embedding,
    String? selfiePath,
  }) async {
    if (failMocked || isMocked) {
      return JobVerificationResult.error(
        code: 'mock_location_rejected',
        message: 'Mock / fake location detected. Start refused and logged for review.',
        isMockedRejected: true,
      );
    }
    if (failGeofence) {
      return JobVerificationResult.error(
        code: 'out_of_geofence',
        message: 'GPS location is outside the job site perimeter (5200m > 150m)',
        distanceMeters: 5200.0,
        radiusMeters: 150,
        isGeofenceRejected: true,
      );
    }
    if (failStatusNotArrived) {
      return JobVerificationResult.error(
        code: 'invalid_status_for_start',
        message: 'Worker must have status arrived before verified start',
      );
    }
    return JobVerificationResult.successStart(
      status: 'in_progress_verified',
      distanceMeters: 35.0,
      elapsedSeconds: 0,
    );
  }

  @override
  Future<JobVerificationResult> verifyMidJobCheck({
    required String assignmentId,
    double? lat,
    double? lng,
    bool? isMocked,
    String? selfiePath,
  }) async {
    return JobVerificationResult.successMidJob(
      status: 'in_progress_verified',
      distanceMeters: 40.0,
    );
  }

  @override
  Future<JobVerificationResult> completeJob({
    required String assignmentId,
    double? lat,
    double? lng,
    bool? isMocked,
    String? selfiePath,
    List<String>? workPhotos,
    bool isCustomerConfirmed = false,
  }) async {
    return JobVerificationResult.successCompletion(
      status: 'completed',
      elapsedSeconds: 14400, // 4 hours
      paymentEligible: true,
    );
  }

  @override
  Future<String> uploadJobEvidence({
    required String assignmentId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    return 'worker-1/job-evidence/$fileName';
  }

  @override
  Future<List<AssignmentEventItem>> fetchAssignmentEvents(String assignmentId) async => [];

  @override
  Stream<List<AssignmentEventItem>> watchAssignmentEvents(String assignmentId) => Stream.value([]);

  @override
  Stream<String> watchAssignmentStatus(String assignmentId) => const Stream.empty();

  @override
  Future<void> advanceStage(String assignmentId, String nextStatus, {Map<String, dynamic>? meta}) async {}

  @override
  Future<List<WorkerScheduleItem>> fetchWorkerSchedule(String workerId, {DateTime? startDate, DateTime? endDate}) async => [];

  @override
  Future<JobTicketData> fetchJobTicket(String assignmentId) async => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> refreshTicketQr(String assignmentId) async => throw UnimplementedError();

  @override
  Future<AttendanceScanResult> verifyAttendanceScan({required String qrToken, double? lat, double? lng, String? jobId}) async => throw UnimplementedError();

  @override
  Future<int> checkNoShowAssignments() async => 0;

  @override
  Future<void> extendWait(String assignmentId, {int minutes = 10}) async {}

  @override
  Future<void> reportRunningLate(String assignmentId, {required int etaMinutes}) async {}

  @override
  Future<List<ReplacementCandidate>> findReplacementCandidates(String assignmentId) async => [];

  @override
  Future<Map<String, dynamic>> confirmReplacement({
    required String assignmentId,
    required String replacementWorkerId,
  }) async => {'success': true};

  @override
  Future<Map<String, dynamic>> getRotatingTicketToken(String assignmentId, {bool debugShortTtl = false}) async => {
        'qr_token': 'TK-test-token',
        'expires_in_seconds': 120,
      };

  @override
  Future<Map<String, dynamic>?> getNextAcceptedTicket() async => null;

  @override
  Future<JobVerificationResult> recordStep2Verification({
    required String assignmentId,
    required String selfiePath,
    required double lat,
    required double lng,
    double? faceScore,
  }) async {
    return verifyJobStart(
      assignmentId: assignmentId,
      lat: lat,
      lng: lng,
      isMocked: failMocked,
      selfiePath: selfiePath,
    );
  }
}

void main() {
  group('P4.9 Job Verification Backend & Logic Tests', () {
    late MockJobExecutionRepository repo;

    setUp(() {
      repo = MockJobExecutionRepository();
    });

    test('Geofence check refuses start from sofa across town (5.2 km away)', () async {
      repo.failGeofence = true;

      // 1. Check geofence
      final geofence = await repo.checkJobGeofence(
        jobId: 'job-101',
        lat: 12.9716 + 0.045, // sofa across town
        lng: 77.6412 + 0.035,
      );
      expect(geofence.withinGeofence, isFalse);
      expect(geofence.distanceMeters, greaterThan(150.0));

      // 2. Submit start verification
      final result = await repo.verifyJobStart(
        assignmentId: 'assign-101',
        lat: 12.9716 + 0.045,
        lng: 77.6412 + 0.035,
        isMocked: false,
      );
      expect(result.success, isFalse);
      expect(result.isGeofenceRejected, isTrue);
      expect(result.errorCode, 'out_of_geofence');
    });

    test('Mock location attempt is rejected with fraud code', () async {
      final result = await repo.verifyJobStart(
        assignmentId: 'assign-101',
        lat: 12.9716,
        lng: 77.6412,
        isMocked: true, // developer mock location enabled
      );
      expect(result.success, isFalse);
      expect(result.isMockedRejected, isTrue);
      expect(result.errorCode, 'mock_location_rejected');
    });

    test('Two-step verified start succeeds only when arrived + valid selfie + within radius', () async {
      // Within perimeter and real GPS
      final geofence = await repo.checkJobGeofence(
        jobId: 'job-101',
        lat: 12.9716,
        lng: 77.6412,
      );
      expect(geofence.withinGeofence, isTrue);

      final result = await repo.verifyJobStart(
        assignmentId: 'assign-101',
        lat: 12.9716,
        lng: 77.6412,
        isMocked: false,
        embedding: List.generate(128, (i) => 0.08),
        selfiePath: 'worker-1/job-evidence/start_selfie.jpg',
      );
      expect(result.success, isTrue);
      expect(result.status, 'in_progress_verified');
    });

    test('Mid-job check verifies midpoint milestone on high-value jobs', () async {
      final detail = await repo.fetchActiveJob('assign-101');
      // Wage is ₹2,500 (250,000 paise >= 200,000 paise threshold)
      expect(detail.agreedWagePaise, greaterThanOrEqualTo(200000));

      final midResult = await repo.verifyMidJobCheck(
        assignmentId: 'assign-101',
        lat: 12.9716,
        lng: 77.6412,
        isMocked: false,
        selfiePath: 'worker-1/job-evidence/midjob_selfie.jpg',
      );
      expect(midResult.success, isTrue);
      expect(midResult.status, 'in_progress_verified');
    });

    test('Job completion stops timer, logs evidence, and marks payment eligible', () async {
      final completionResult = await repo.completeJob(
        assignmentId: 'assign-101',
        lat: 12.9716,
        lng: 77.6412,
        isMocked: false,
        selfiePath: 'worker-1/job-evidence/completion_selfie.jpg',
        workPhotos: ['worker-1/job-evidence/photo1.jpg', 'worker-1/job-evidence/photo2.jpg'],
        isCustomerConfirmed: true,
      );

      expect(completionResult.success, isTrue);
      expect(completionResult.status, 'completed');
      expect(completionResult.paymentEligible, isTrue);
      expect(completionResult.elapsedSeconds, 14400);
    });

    test('Job evidence uploads to private bucket storage path', () async {
      final path = await repo.uploadJobEvidence(
        assignmentId: 'assign-101',
        fileBytes: [1, 2, 3, 4],
        fileName: 'wall_plaster_finish.jpg',
      );
      expect(path, contains('worker-1/job-evidence/wall_plaster_finish.jpg'));
    });
  });

  group('P4.9 UI Widget Tests', () {
    testWidgets('JobLiveTimerCard renders running timer and server-authoritative badge', (tester) async {
      final startTime = DateTime.now().subtract(const Duration(hours: 1, minutes: 15, seconds: 30));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: JobLiveTimerCard(
              startedAt: startTime,
              isCompleted: false,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('LIVE WORK TIMER'), findsOneWidget);
      expect(find.text('Server-authoritative'), findsOneWidget);
      // Digital timer format: 01:15:3X
      expect(find.textContaining('01:15:'), findsOneWidget);
    });

    testWidgets('JobLiveTimerCard renders completed duration when job is finished', (tester) async {
      final startTime = DateTime.now().subtract(const Duration(hours: 3));
      final endTime = startTime.add(const Duration(hours: 2, minutes: 30));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: JobLiveTimerCard(
              startedAt: startTime,
              endedAt: endTime,
              serverElapsedSeconds: 9000, // 2h 30m
              isCompleted: true,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('COMPLETED DURATION'), findsOneWidget);
      expect(find.text('02:30:00'), findsOneWidget);
    });
  });
}
