import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/dev/presentation/lifecycle_test_panel_screen.dart';
import 'package:udyogasethu/features/job_execution/data/job_execution_repository.dart';
import 'package:udyogasethu/features/job_execution/domain/active_job_detail.dart';
import 'package:udyogasethu/features/job_execution/domain/assignment_event_item.dart';
import 'package:udyogasethu/features/job_execution/domain/job_ticket.dart';
import 'package:udyogasethu/features/job_execution/domain/job_verification.dart';
import 'package:udyogasethu/features/job_execution/domain/replacement_candidate.dart';
import 'package:udyogasethu/features/job_execution/domain/worker_schedule_item.dart';

class MockLifecycleRepo implements JobExecutionRepository {
  bool advanceCalled = false;
  String? advancedStage;

  @override
  Future<Map<String, dynamic>> getRotatingTicketToken(String assignmentId, {bool debugShortTtl = false}) async {
    return {
      'qr_token': 'PANEL_TEST_TOKEN_123',
      'expires_in_seconds': debugShortTtl ? 15 : 120,
      'expires_at': DateTime.now().add(Duration(seconds: debugShortTtl ? 15 : 120)).toIso8601String(),
    };
  }

  @override
  Stream<List<AssignmentEventItem>> watchAssignmentEvents(String assignmentId) {
    return Stream.value([
      AssignmentEventItem(
        id: 'evt-1',
        assignmentId: assignmentId,
        rawEventType: 'ticket_issued',
        stage: AssignmentStage.ticketIssued,
        createdAt: DateTime(2026, 10, 11, 10, 0),
      ),
      AssignmentEventItem(
        id: 'evt-2',
        assignmentId: assignmentId,
        rawEventType: 'arrived',
        stage: AssignmentStage.workerArrived,
        createdAt: DateTime(2026, 10, 11, 10, 15),
      ),
    ]);
  }

  @override
  Future<void> advanceStage(String assignmentId, String nextStatus, {Map<String, dynamic>? meta}) async {
    advanceCalled = true;
    advancedStage = nextStatus;
  }

  @override
  Future<ActiveJobDetail> fetchActiveJob(String assignmentId) async => throw UnimplementedError();

  @override
  Future<List<AssignmentEventItem>> fetchAssignmentEvents(String assignmentId) async => [];

  @override
  Stream<String> watchAssignmentStatus(String assignmentId) => const Stream.empty();

  @override
  Future<List<WorkerScheduleItem>> fetchWorkerSchedule(String workerId, {DateTime? startDate, DateTime? endDate}) async => [];

  @override
  Future<JobTicketData> fetchJobTicket(String assignmentId) async => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> refreshTicketQr(String assignmentId) async => {};

  @override
  Future<AttendanceScanResult> verifyAttendanceScan({required String qrToken, double? lat, double? lng, String? jobId}) async => throw UnimplementedError();

  @override
  Future<JobGeofenceStatus> checkJobGeofence({required String jobId, required double lat, required double lng}) async => throw UnimplementedError();

  @override
  Future<JobVerificationResult> verifyJobStart({
    required String assignmentId,
    required double lat,
    required double lng,
    required bool isMocked,
    List<double>? embedding,
    String? selfiePath,
  }) async => throw UnimplementedError();

  @override
  Future<JobVerificationResult> verifyMidJobCheck({
    required String assignmentId,
    double? lat,
    double? lng,
    bool? isMocked,
    String? selfiePath,
  }) async => throw UnimplementedError();

  @override
  Future<JobVerificationResult> completeJob({
    required String assignmentId,
    double? lat,
    double? lng,
    bool? isMocked,
    String? selfiePath,
    List<String>? workPhotos,
    bool isCustomerConfirmed = false,
  }) async => throw UnimplementedError();

  @override
  Future<String> uploadJobEvidence({
    required String assignmentId,
    required List<int> fileBytes,
    required String fileName,
  }) async => 'evidence/$fileName';

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
  Future<Map<String, dynamic>?> getNextAcceptedTicket() async => null;

  @override
  Future<JobVerificationResult> recordStep2Verification({
    required String assignmentId,
    required String selfiePath,
    required double lat,
    required double lng,
    double? faceScore,
  }) async => JobVerificationResult.success(status: 'in_progress_verified');
}

void main() {
  group('LifecycleTestPanelScreen Tests', () {
    testWidgets('Renders health checks, active assignment, token state, and event streams', (tester) async {
      final repo = MockLifecycleRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            jobExecutionRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: LifecycleTestPanelScreen(initialAssignmentId: 'asg-lifecycle-test'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header & title
      expect(find.text('Lifecycle Test Panel'), findsOneWidget);

      // Verify health check functions
      expect(find.text('qr-issue'), findsOneWidget);
      expect(find.text('qr-verify'), findsOneWidget);
      expect(find.text('face-verify'), findsOneWidget);

      // Verify token state
      expect(find.textContaining('PANEL_TEST_TOKEN'), findsOneWidget);
      expect(find.textContaining('Short TTL (15s)'), findsOneWidget);

      // Verify events stream
      expect(find.text('ticket_issued'), findsOneWidget);
      expect(find.text('arrived'), findsOneWidget);

      // Verify advance stage chips
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Arrived'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      // Tap advance to 'Arrived'
      final arrivedChip = find.widgetWithText(ActionChip, 'Arrived');
      await tester.ensureVisible(arrivedChip);
      await tester.tap(arrivedChip);
      await tester.pumpAndSettle();
      expect(repo.advanceCalled, isTrue);
      expect(repo.advancedStage, 'arrived');

      // Unmount to cancel timers
      await tester.pumpWidget(const SizedBox());
    });
  });
}
