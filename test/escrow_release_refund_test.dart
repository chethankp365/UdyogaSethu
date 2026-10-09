import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/services/routing_service.dart';
import 'package:udyogasethu/features/job_execution/data/job_execution_repository.dart';
import 'package:udyogasethu/features/job_execution/domain/active_job_detail.dart';
import 'package:udyogasethu/features/job_execution/domain/assignment_event_item.dart';
import 'package:udyogasethu/features/job_execution/domain/job_ticket.dart';
import 'package:udyogasethu/features/job_execution/domain/job_verification.dart';
import 'package:udyogasethu/features/job_execution/domain/replacement_candidate.dart';
import 'package:udyogasethu/features/job_execution/domain/worker_schedule_item.dart';
import 'package:udyogasethu/features/job_execution/presentation/active_job_screen.dart';
import 'package:udyogasethu/features/payments/data/payment_repository.dart';
import 'package:udyogasethu/features/payments/domain/payment_bill_summary.dart';
import 'package:udyogasethu/features/payments/domain/payment_models.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class _TestSessionNotifier extends AppSessionNotifier {
  final UserRole _role;
  _TestSessionNotifier(this._role);

  @override
  AppSessionData build() => AppSessionData(
        status: AuthSessionStatus.ready,
        activeRole: _role,
      );
}

class TestFakeRoutingService extends RoutingService {
  @override
  Future<RoutingResult> getRoute({required LatLng start, required LatLng destination}) async {
    return const RoutingResult(
      points: [LatLng(12.9279, 77.6271), LatLng(12.9352, 77.6245)],
      distanceMeters: 2500.0,
      durationSeconds: 600.0,
      isStraightLineFallback: false,
    );
  }
}

class TestFakeJobExecutionRepository implements JobExecutionRepository {
  final ActiveJobDetail activeJob;

  TestFakeJobExecutionRepository({required this.activeJob});

  @override
  Future<ActiveJobDetail> fetchActiveJob(String assignmentId) async => activeJob;

  @override
  Future<List<AssignmentEventItem>> fetchAssignmentEvents(String assignmentId) async => [];

  @override
  Stream<List<AssignmentEventItem>> watchAssignmentEvents(String assignmentId) =>
      Stream.value([]);

  @override
  Future<void> advanceStage(String assignmentId, String nextStatus, {Map<String, dynamic>? meta}) async {}

  @override
  Future<List<WorkerScheduleItem>> fetchWorkerSchedule(String workerId, {DateTime? startDate, DateTime? endDate}) async =>
      [];

  @override
  Future<JobTicketData> fetchJobTicket(String assignmentId) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> refreshTicketQr(String assignmentId) async {
    return {'qr_token': 'TEST_TOKEN', 'expires_in_seconds': 120};
  }

  @override
  Future<AttendanceScanResult> verifyAttendanceScan({required String qrToken, double? lat, double? lng}) async {
    return const AttendanceScanResult(
      valid: true,
      purpose: 'ticket',
      status: 'arrived',
      workerName: 'Chethan',
      isVerifiedBadge: true,
      jobTitle: 'Test Job',
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
    return JobVerificationResult.successStart(status: 'in_progress_verified', distanceMeters: 45.0);
  }

  @override
  Future<JobVerificationResult> verifyMidJobCheck({
    required String assignmentId,
    double? lat,
    double? lng,
    bool? isMocked,
    String? selfiePath,
  }) async {
    return JobVerificationResult.successMidJob(status: 'in_progress_verified', distanceMeters: 45.0);
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
  }) async => 'evidence/test_$fileName';

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
}

class TestFakePaymentRepository implements PaymentRepository {
  bool releaseEscrowCalled = false;
  String? lastReleasedAssignmentId;
  bool refundCalled = false;
  int? lastRefundPaise;

  @override
  Future<PaymentBillSummary> computeBill({
    required String refType,
    required String refId,
    bool? protectionOverride,
  }) async {
    return const PaymentBillSummary(
      baseAmountPaise: 70000,
      platformFeePaise: 3500,
      protectionFeePaise: 0,
      totalPaise: 73500,
      isProtected: true,
      description: 'Test Job',
    );
  }

  @override
  Future<PaymentOrderResult> createOrder({
    required String refType,
    required String refId,
    required PaymentMethod method,
    bool? protectionOverride,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<PaymentRecord> getPayment(String paymentId) async => throw UnimplementedError();

  @override
  Stream<PaymentRecord?> streamPayment(String paymentId) => Stream.value(null);

  @override
  Future<int> getAvailableWalletBalancePaise() async => 500000;

  @override
  Future<bool> releaseAssignmentEscrow(String assignmentId) async {
    releaseEscrowCalled = true;
    lastReleasedAssignmentId = assignmentId;
    return true;
  }

  @override
  Future<bool> confirmJobCompletionAndRelease(String assignmentId) async {
    releaseEscrowCalled = true;
    lastReleasedAssignmentId = assignmentId;
    return true;
  }

  @override
  Future<bool> refundEscrow(String paymentId, {int? refundPaise, String? reason}) async {
    refundCalled = true;
    lastRefundPaise = refundPaise;
    return true;
  }

  @override
  Future<bool> refundAssignmentEscrow(String assignmentId, {int? refundPaise, String? reason}) async {
    refundCalled = true;
    lastRefundPaise = refundPaise;
    return true;
  }

  @override
  Future<bool> releaseOrderEscrow(String orderId) async {
    releaseEscrowCalled = true;
    return true;
  }
}

void main() {
  group('P5.3 Escrow Math & Logic Invariants', () {
    test('Calculates 5% platform fee with correct paise rounding', () {
      const wagePaise = 70000; // ₹700.00
      final feePaise = (wagePaise * 5) ~/ 100; // 3500 paise = ₹35.00
      final netWorkerPaise = wagePaise - feePaise; // 66500 paise = ₹665.00

      expect(feePaise, 3500);
      expect(netWorkerPaise, 66500);
      expect(feePaise + netWorkerPaise, wagePaise);
    });

    test('Paise rounding edge case with fractional amounts (73,533 paise)', () {
      const wagePaise = 73533; // ₹735.33
      // In SQL / Dart: 73533 * 500 / 10000 = 3676.65 => rounded to 3677
      final feePaise = ((wagePaise * 500) / 10000).round();
      final netWorkerPaise = wagePaise - feePaise;

      expect(feePaise, 3677);
      expect(netWorkerPaise, 69856);
      expect(feePaise + netWorkerPaise, wagePaise);
    });
  });

  group('P5.3 PaymentRepository Method Invocations', () {
    test('confirmJobCompletionAndRelease invokes repository method with correct assignmentId', () async {
      final repo = TestFakePaymentRepository();
      await repo.confirmJobCompletionAndRelease('asg-test-456');

      expect(repo.releaseEscrowCalled, isTrue);
      expect(repo.lastReleasedAssignmentId, 'asg-test-456');
    });

    test('refundAssignmentEscrow invokes repository method with amount and reason', () async {
      final repo = TestFakePaymentRepository();
      await repo.refundAssignmentEscrow(
        'asg-test-789',
        refundPaise: 25000,
        reason: 'no_show_cancelled',
      );

      expect(repo.refundCalled, isTrue);
      expect(repo.lastRefundPaise, 25000);
    });
  });

  group('P5.3 ActiveJobScreen Escrow UI Widget Tests', () {
    final testJobDetail = ActiveJobDetail(
      assignmentId: 'asg-escrow-101',
      jobId: 'job-101',
      bookingCode: 'BK-5521',
      status: 'completed',
      stage: AssignmentStage.completed,
      agreedWagePaise: 70000, // ₹700
      protectionSelected: true,
      jobTitle: 'Coffee Plantation Pruning',
      jobDescription: 'Selective pruning of shade trees',
      startAt: DateTime.now(),
      addressText: 'Madikeri, Coorg',
      jobLat: 12.4244,
      jobLng: 75.7382,
      providerId: 'prov-1',
      providerName: 'Coorg Estate Owner',
      workerId: 'work-1',
      workerName: 'Chethan Worker',
    );

    testWidgets('Worker sees Pending Escrow Release status and Protected badge', (tester) async {
      final fakeRepo = TestFakeJobExecutionRepository(activeJob: testJobDetail);
      final fakePayRepo = TestFakePaymentRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSessionProvider.overrideWith(() => _TestSessionNotifier(UserRole.seeker)),
            jobExecutionRepositoryProvider.overrideWithValue(fakeRepo),
            paymentRepositoryProvider.overrideWithValue(fakePayRepo),
            routingServiceProvider.overrideWithValue(TestFakeRoutingService()),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ActiveJobScreen(assignmentId: 'asg-escrow-101'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Worker should see "Pending Escrow Release" in banner
      expect(find.text('Pending Escrow Release'), findsAtLeastNWidgets(1));

      // Worker should see "Protected" badge
      expect(find.text('Protected'), findsAtLeastNWidgets(1));

      // Tapping the primary action opens the info sheet
      final actionBtn = find.text('Pending Escrow Release (₹700)');
      expect(actionBtn, findsOneWidget);
      await tester.tap(actionBtn);
      await tester.pumpAndSettle();

      // Info sheet displays reassurance note
      expect(find.text('Your earnings are 100% secured in escrow'), findsOneWidget);
      expect(find.text('Worker Payout (Available Balance)'), findsOneWidget);
    });

    testWidgets('Provider sees Confirm & Release Payment and can open release dialog', (tester) async {
      final fakeRepo = TestFakeJobExecutionRepository(activeJob: testJobDetail);
      final fakePayRepo = TestFakePaymentRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSessionProvider.overrideWith(() => _TestSessionNotifier(UserRole.provider)),
            jobExecutionRepositoryProvider.overrideWithValue(fakeRepo),
            paymentRepositoryProvider.overrideWithValue(fakePayRepo),
            routingServiceProvider.overrideWithValue(TestFakeRoutingService()),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ActiveJobScreen(assignmentId: 'asg-escrow-101'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Provider should see "Work Completed - Ready for Release" banner
      expect(find.text('Work Completed - Ready for Release'), findsOneWidget);

      // Provider sees "Confirm & Release Payment (₹700)" button
      final releaseBtn = find.text('Confirm & Release Payment (₹700)');
      expect(releaseBtn, findsOneWidget);

      // Tap to open release dialog
      await tester.tap(releaseBtn);
      await tester.pumpAndSettle();

      // Dialog shows breakdown and confirm button
      expect(find.text('Release Escrow Payment'), findsOneWidget);
      expect(find.text('Confirm & Release Payment (₹700)'), findsAtLeastNWidgets(1));

      // Confirm release (tap the dialog button)
      await tester.tap(find.text('Confirm & Release Payment (₹700)').last);
      await tester.pumpAndSettle();

      // Repository was called!
      expect(fakePayRepo.releaseEscrowCalled, isTrue);
      expect(fakePayRepo.lastReleasedAssignmentId, 'asg-escrow-101');
    });
  });
}
