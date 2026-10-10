import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/services/routing_service.dart';
import 'package:udyogasethu/features/job_execution/data/job_execution_repository.dart';
import 'package:udyogasethu/features/job_execution/domain/active_job_detail.dart';
import 'package:udyogasethu/features/job_execution/domain/assignment_event_item.dart';
import 'package:udyogasethu/features/job_execution/domain/job_ticket.dart';
import 'package:udyogasethu/features/job_execution/domain/job_verification.dart';
import 'package:udyogasethu/features/job_execution/domain/worker_schedule_item.dart';
import 'package:udyogasethu/features/job_execution/domain/replacement_candidate.dart';
import 'package:udyogasethu/features/job_execution/presentation/assignment_timeline_widget.dart';
import 'package:udyogasethu/features/job_execution/presentation/active_job_screen.dart';
import 'package:udyogasethu/features/job_execution/presentation/worker_schedule_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class MockHttpClient extends http.BaseClient {
  final http.Response Function(http.Request request) handler;

  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final httpRequest = request as http.Request;
    final res = handler(httpRequest);
    return http.StreamedResponse(
      Stream.value(utf8.encode(res.body)),
      res.statusCode,
      headers: res.headers,
    );
  }
}

class FakeRoutingService extends RoutingService {
  @override
  Future<RoutingResult> getRoute({required LatLng start, required LatLng destination}) async {
    return const RoutingResult(
      points: [LatLng(12.9279, 77.6271), LatLng(12.9352, 77.6245)],
      distanceMeters: 4200.0,
      durationSeconds: 960.0,
      isStraightLineFallback: false,
    );
  }
}

class FakeJobExecutionRepository implements JobExecutionRepository {
  final List<AssignmentEventItem> events;
  final ActiveJobDetail activeJob;
  final List<WorkerScheduleItem> schedule;

  FakeJobExecutionRepository({
    required this.events,
    required this.activeJob,
    required this.schedule,
  });

  @override
  Future<ActiveJobDetail> fetchActiveJob(String assignmentId) async => activeJob;

  @override
  Future<List<AssignmentEventItem>> fetchAssignmentEvents(String assignmentId) async => events;

  @override
  Stream<List<AssignmentEventItem>> watchAssignmentEvents(String assignmentId) =>
      Stream.value(events);

  @override
  Future<void> advanceStage(String assignmentId, String nextStatus, {Map<String, dynamic>? meta}) async {}

  @override
  Future<List<WorkerScheduleItem>> fetchWorkerSchedule(String workerId, {DateTime? startDate, DateTime? endDate}) async =>
      schedule;

  @override
  Future<JobTicketData> fetchJobTicket(String assignmentId) async {
    return JobTicketData(
      assignmentId: assignmentId,
      bookingCode: 'BOOK-TEST78',
      status: 'ticket_issued',
      jobId: 'job-1',
      jobTitle: 'Electrician Repair',
      categoryName: 'Electrician',
      categoryIcon: 'flash_on',
      startAt: DateTime.now(),
      estDurationMinutes: 120,
      agreedWagePaise: 80000,
      wageType: 'daily',
      paymentMode: 'escrow',
      workerId: 'worker-1',
      workerName: 'Chethan',
      isWorkerVerified: true,
      providerId: 'provider-1',
      providerName: 'Employer',
    );
  }

  @override
  Future<Map<String, dynamic>> refreshTicketQr(String assignmentId) async {
    return {
      'qr_token': 'TEST_TOKEN',
      'expires_in_seconds': 120,
    };
  }

  @override
  Future<AttendanceScanResult> verifyAttendanceScan({required String qrToken, double? lat, double? lng}) async {
    return const AttendanceScanResult(
      valid: true,
      purpose: 'ticket',
      status: 'arrived',
      workerName: 'Chethan',
      isVerifiedBadge: true,
      jobTitle: 'Electrician Repair',
    );
  }

  @override
  Future<JobGeofenceStatus> checkJobGeofence({required String jobId, required double lat, required double lng}) async {
    return const JobGeofenceStatus(
      distanceMeters: 45.0,
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
    if (isMocked) {
      return JobVerificationResult.error(
        code: 'mock_location_rejected',
        message: 'Mock location detected',
        isMockedRejected: true,
      );
    }
    return JobVerificationResult.successStart(
      status: 'in_progress_verified',
      distanceMeters: 45.0,
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
      distanceMeters: 45.0,
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
      elapsedSeconds: 7200,
      paymentEligible: true,
    );
  }

  @override
  Future<String> uploadJobEvidence({
    required String assignmentId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    return 'evidence/test_$fileName';
  }

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
  }) async =>
      JobVerificationResult.success(status: 'in_progress_verified');
}

void main() {
  group('P4.7 RoutingService Tests', () {
    test('Parses OSRM JSON response correctly and returns polyline route', () async {
      final mockClient = MockHttpClient((req) {
        return http.Response(
          jsonEncode({
            'code': 'Ok',
            'routes': [
              {
                'distance': 4200.0,
                'duration': 960.0,
                'geometry': {
                  'coordinates': [
                    [77.6271, 12.9279],
                    [77.6250, 12.9300],
                    [77.6245, 12.9352],
                  ],
                },
              }
            ],
          }),
          200,
        );
      });

      final service = RoutingService(httpClient: mockClient);
      final result = await service.getRoute(
        start: const LatLng(12.9279, 77.6271),
        destination: const LatLng(12.9352, 77.6245),
      );

      expect(result.isStraightLineFallback, isFalse);
      expect(result.distanceMeters, 4200.0);
      expect(result.distanceKm, 4.2);
      expect(result.formattedDistance, '4.2 km');
      expect(result.durationMinutes, 16);
      expect(result.formattedDuration, '16 min');
      expect(result.points.length, 3);
    });

    test('Falls back gracefully to straight-line Haversine computation on HTTP 500 error', () async {
      final mockClient = MockHttpClient((req) => http.Response('Server Error', 500));
      final service = RoutingService(httpClient: mockClient);

      final start = const LatLng(12.9279, 77.6271);
      final dest = const LatLng(12.9352, 77.6245);

      final result = await service.getRoute(start: start, destination: dest);

      expect(result.isStraightLineFallback, isTrue);
      expect(result.points.length, 2);
      expect(result.distanceMeters, greaterThan(500.0));
      expect(result.durationSeconds, greaterThan(30.0));
    });
  });

  group('P4.7 AssignmentStage and Domain Mapping Tests', () {
    test('Maps all 9 canonical stages accurately from various status strings', () {
      expect(AssignmentStage.fromString('requested'), AssignmentStage.requestCreated);
      expect(AssignmentStage.fromString('request_created'), AssignmentStage.requestCreated);
      expect(AssignmentStage.fromString('accepted'), AssignmentStage.accepted);
      expect(AssignmentStage.fromString('ticket_issued'), AssignmentStage.ticketIssued);
      expect(AssignmentStage.fromString('arrived'), AssignmentStage.workerArrived);
      expect(AssignmentStage.fromString('worker_arrived'), AssignmentStage.workerArrived);
      expect(AssignmentStage.fromString('verification_completed'), AssignmentStage.verificationCompleted);
      expect(AssignmentStage.fromString('in_progress_verified'), AssignmentStage.jobInProgress);
      expect(AssignmentStage.fromString('completed'), AssignmentStage.completed);
      expect(AssignmentStage.fromString('payment_released'), AssignmentStage.paymentReleased);
      expect(AssignmentStage.fromString('disputed'), AssignmentStage.disputeRaised);
    });
  });

  group('P4.7 WorkerScheduleItem Travel Warning & Overlap Tests', () {
    test('Detects travel warning when gap between jobs is less than travel time', () {
      final now = DateTime.now();
      final itemWithWarning = WorkerScheduleItem(
        assignmentId: 'assign-1',
        jobId: 'job-1',
        title: 'Office Wiring Repair',
        status: 'accepted',
        bookingCode: 'BOOK-7801',
        agreedWagePaise: 80000,
        startAt: now.add(const Duration(hours: 3)),
        endAt: now.add(const Duration(hours: 5)),
        estDurationMinutes: 120,
        addressText: 'Indiranagar, Bengaluru',
        jobLat: 12.9719,
        jobLng: 77.6412,
        categorySlug: 'electrician',
        categoryIcon: 'flash_on',
        providerName: 'SK Builders',
        gapFromPrevMinutes: 15.0, // Only 15 min gap!
        estimatedTravelMinutes: 35, // Travel takes 35 min!
      );

      expect(itemWithWarning.hasTravelWarning, isTrue);
      expect(itemWithWarning.isOverlap, isFalse);
    });

    test('Detects schedule overlap when gap is negative', () {
      final now = DateTime.now();
      final overlappingItem = WorkerScheduleItem(
        assignmentId: 'assign-2',
        jobId: 'job-2',
        title: 'House Painting',
        status: 'accepted',
        bookingCode: 'BOOK-7802',
        agreedWagePaise: 90000,
        startAt: now.add(const Duration(hours: 1)),
        endAt: now.add(const Duration(hours: 4)),
        estDurationMinutes: 180,
        addressText: 'Koramangala, Bengaluru',
        jobLat: 12.9352,
        jobLng: 77.6245,
        categorySlug: 'painter',
        categoryIcon: 'format_paint',
        providerName: 'Anil Rao',
        gapFromPrevMinutes: -30.0, // Overlapping by 30 mins!
      );

      expect(overlappingItem.isOverlap, isTrue);
      expect(overlappingItem.hasTravelWarning, isTrue);
    });
  });

  group('P4.7 Widget Tests: Timeline, Active Job & Schedule Screens', () {
    testWidgets('AssignmentTimelineWidget renders milestone stages and active state', (tester) async {
      final now = DateTime.now();
      final mockEvents = [
        AssignmentEventItem(
          id: 'evt-1',
          assignmentId: 'assign-test-1',
          rawEventType: 'requested',
          stage: AssignmentStage.requestCreated,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        AssignmentEventItem(
          id: 'evt-2',
          assignmentId: 'assign-test-1',
          rawEventType: 'accepted',
          stage: AssignmentStage.accepted,
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            jobExecutionRepositoryProvider.overrideWithValue(
              FakeJobExecutionRepository(
                events: mockEvents,
                activeJob: ActiveJobDetail(
                  assignmentId: 'assign-test-1',
                  jobId: 'job-1',
                  bookingCode: 'BOOK-101',
                  status: 'accepted',
                  stage: AssignmentStage.accepted,
                  agreedWagePaise: 60000,
                  jobTitle: 'Plumbing Repair',
                  startAt: now,
                  addressText: 'Koramangala',
                  jobLat: 12.9352,
                  jobLng: 77.6245,
                  providerId: 'p-1',
                  providerName: 'Sharma',
                  workerId: 'w-1',
                  workerName: 'Chethan',
                ),
                schedule: [],
              ),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: AssignmentTimelineWidget(
                  assignmentId: 'assign-test-1',
                  currentStatus: 'accepted',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AssignmentTimelineWidget), findsOneWidget);
      expect(find.text('Request Created'), findsOneWidget);
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Ticket Issued'), findsOneWidget);
      expect(find.text('Worker Arrived'), findsOneWidget);
      expect(find.text('Job In Progress'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
    });

    testWidgets('ActiveJobScreen renders status banner, route section and big action', (tester) async {
      final now = DateTime.now();
      final detail = ActiveJobDetail(
        assignmentId: 'assign-test-2',
        jobId: 'job-2',
        bookingCode: 'BOOK-7842',
        status: 'in_progress_verified',
        stage: AssignmentStage.jobInProgress,
        agreedWagePaise: 75000,
        jobTitle: 'Electrical Board Rewiring',
        jobDescription: 'Main breaker replacement',
        startAt: now,
        addressText: 'Indiranagar 100ft Road',
        jobLat: 12.9719,
        jobLng: 77.6412,
        providerId: 'p-2',
        providerName: 'SK Builders',
        workerId: 'w-2',
        workerName: 'Chethan Kumar',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            routingServiceProvider.overrideWithValue(FakeRoutingService()),
            jobExecutionRepositoryProvider.overrideWithValue(
              FakeJobExecutionRepository(
                events: [],
                activeJob: detail,
                schedule: [],
              ),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ActiveJobScreen(assignmentId: 'assign-test-2'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ActiveJobScreen), findsOneWidget);
      expect(find.text('Booking Code: BOOK-7842'), findsOneWidget);
      expect(find.text('₹750'), findsOneWidget);
      expect(find.text('Complete Job'), findsOneWidget);
      expect(find.text('Open in Maps'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('WorkerScheduleScreen renders day view, week view and travel warning chip', (tester) async {
      final now = DateTime.now();
      final sched = [
        WorkerScheduleItem(
          assignmentId: 'assign-s1',
          jobId: 'job-s1',
          title: 'Morning Cleaning',
          status: 'accepted',
          bookingCode: 'BOOK-01',
          agreedWagePaise: 50000,
          startAt: now,
          endAt: now.add(const Duration(hours: 2)),
          estDurationMinutes: 120,
          addressText: 'Koramangala 4th Block',
          jobLat: 12.9352,
          jobLng: 77.6245,
          categorySlug: 'cleaner',
          categoryIcon: 'cleaning_services',
          providerName: 'Priya',
          gapFromPrevMinutes: 15.0, // Gap is only 15 mins!
          estimatedTravelMinutes: 35, // Travel takes 35 mins!
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workerScheduleProvider('w1').overrideWith((ref) async => sched),
            jobExecutionRepositoryProvider.overrideWithValue(
              FakeJobExecutionRepository(
                events: [],
                activeJob: ActiveJobDetail(
                  assignmentId: 'a1',
                  jobId: 'j1',
                  bookingCode: 'B1',
                  status: 'accepted',
                  stage: AssignmentStage.accepted,
                  agreedWagePaise: 50000,
                  jobTitle: 'Clean',
                  startAt: now,
                  addressText: 'Blr',
                  jobLat: 12.9,
                  jobLng: 77.6,
                  providerId: 'p1',
                  providerName: 'P',
                  workerId: 'w1',
                  workerName: 'W',
                ),
                schedule: sched,
              ),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: WorkerScheduleScreen(initialWorkerId: 'w1'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(WorkerScheduleScreen), findsOneWidget);
      expect(find.text('Morning Cleaning'), findsOneWidget);
      expect(find.textContaining('Travel Warning'), findsOneWidget);
    });
  });
}
