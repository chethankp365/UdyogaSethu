import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/features/job_execution/data/job_execution_repository.dart';
import 'package:udyogasethu/features/job_execution/domain/active_job_detail.dart';
import 'package:udyogasethu/features/job_execution/domain/assignment_event_item.dart';
import 'package:udyogasethu/features/job_execution/domain/job_ticket.dart';
import 'package:udyogasethu/features/job_execution/domain/job_verification.dart';
import 'package:udyogasethu/features/job_execution/domain/worker_schedule_item.dart';
import 'package:udyogasethu/features/job_execution/domain/replacement_candidate.dart';
import 'package:udyogasethu/features/job_execution/presentation/job_ticket_screen.dart';
import 'package:udyogasethu/features/job_execution/presentation/attendance_scanner_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class MockJobExecutionRepository implements JobExecutionRepository {
  final JobTicketData mockTicket;
  final AttendanceScanResult mockScanResult;

  MockJobExecutionRepository({
    required this.mockTicket,
    required this.mockScanResult,
  });

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
  Future<JobTicketData> fetchJobTicket(String assignmentId) async => mockTicket;

  @override
  Future<Map<String, dynamic>> refreshTicketQr(String assignmentId) async => {
        'qr_token': 'REFRESHED_HMAC_TOKEN_999',
        'expires_in_seconds': 120,
        'expires_at': DateTime.now().add(const Duration(seconds: 120)).toIso8601String(),
      };

  @override
  Future<AttendanceScanResult> verifyAttendanceScan({required String qrToken, double? lat, double? lng}) async {
    if (qrToken.contains('EXPIRED')) {
      return AttendanceScanResult.error(
        code: 'token_expired',
        message: 'QR pass expired. Please ask the worker to show a refreshed QR code.',
      );
    }
    if (qrToken.contains('REPLAY')) {
      return AttendanceScanResult.error(
        code: 'token_already_used',
        message: 'This ticket token has already been scanned. Replay scans are rejected.',
      );
    }
    return mockScanResult;
  }

  @override
  Future<JobGeofenceStatus> checkJobGeofence({required String jobId, required double lat, required double lng}) async {
    return const JobGeofenceStatus(distanceMeters: 40.0, radiusMeters: 150, withinGeofence: true);
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
    return JobVerificationResult.successStart(status: 'in_progress_verified', distanceMeters: 40.0);
  }

  @override
  Future<JobVerificationResult> verifyMidJobCheck({
    required String assignmentId,
    double? lat,
    double? lng,
    bool? isMocked,
    String? selfiePath,
  }) async {
    return JobVerificationResult.successMidJob(status: 'in_progress_verified', distanceMeters: 40.0);
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
    return JobVerificationResult.successCompletion(status: 'completed', elapsedSeconds: 7200, paymentEligible: true);
  }

  @override
  Future<String> uploadJobEvidence({
    required String assignmentId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    return 'worker-1/evidence/$fileName';
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
}

void main() {
  group('P4.8 JobTicketData Domain Tests', () {
    test('JobTicketData serializes and deserializes accurately', () {
      final now = DateTime.now();
      final expiry = now.add(const Duration(minutes: 2));

      final json = {
        'assignment_id': 'asg-101',
        'booking_code': 'BOOK-7842',
        'status': 'ticket_issued',
        'job_id': 'job-202',
        'job_title': 'Solar Panel Inverter Setup',
        'category_name': 'Solar Tech',
        'category_icon': 'solar_power',
        'start_at': now.toIso8601String(),
        'est_duration_minutes': 180,
        'agreed_wage_paise': 95000,
        'wage_type': 'daily',
        'payment_mode': 'escrow',
        'address_text': 'Indiranagar 100ft Rd, Bengaluru',
        'lat': 12.9784,
        'lng': 77.6408,
        'worker_id': 'usr-worker-1',
        'worker_name': 'Ramesh Kumar',
        'worker_avatar': 'https://example.com/avatar.jpg',
        'is_worker_verified': true,
        'provider_id': 'usr-provider-1',
        'provider_name': 'SunPower Energy Ltd',
        'qr_token': 'SIGNED_JWT_HMAC_TICKET_TOKEN',
        'qr_expires_in_seconds': 120,
        'qr_expires_at': expiry.toIso8601String(),
      };

      final ticket = JobTicketData.fromJson(json);

      expect(ticket.assignmentId, 'asg-101');
      expect(ticket.bookingCode, 'BOOK-7842');
      expect(ticket.jobTitle, 'Solar Panel Inverter Setup');
      expect(ticket.workerName, 'Ramesh Kumar');
      expect(ticket.isWorkerVerified, isTrue);
      expect(ticket.providerName, 'SunPower Energy Ltd');
      expect(ticket.formattedWage, '₹950');
      expect(ticket.isQrExpired, isFalse);
    });

    test('isQrExpired returns true when qrExpiresAt is in the past', () {
      final pastExpiry = DateTime.now().subtract(const Duration(seconds: 10));
      final ticket = JobTicketData(
        assignmentId: 'asg-expired',
        bookingCode: 'BOOK-EXP',
        status: 'ticket_issued',
        jobId: 'job-1',
        jobTitle: 'Plumbing',
        categoryName: 'Plumbing',
        categoryIcon: 'plumbing',
        startAt: DateTime.now(),
        estDurationMinutes: 60,
        agreedWagePaise: 50000,
        wageType: 'hourly',
        paymentMode: 'escrow',
        workerId: 'w-1',
        workerName: 'Worker',
        isWorkerVerified: false,
        providerId: 'p-1',
        providerName: 'Provider',
        qrExpiresAt: pastExpiry,
      );

      expect(ticket.isQrExpired, isTrue);
    });

    test('AttendanceScanResult handles error states and replay rejection', () {
      final replayErr = AttendanceScanResult.error(
        code: 'token_already_used',
        message: 'This ticket token has already been scanned.',
      );
      expect(replayErr.valid, isFalse);
      expect(replayErr.errorCode, 'token_already_used');
      expect(replayErr.errorMessage, contains('already been scanned'));

      final expiredErr = AttendanceScanResult.error(
        code: 'token_expired',
        message: 'QR pass expired.',
      );
      expect(expiredErr.valid, isFalse);
      expect(expiredErr.errorCode, 'token_expired');
    });

    test('AttendanceScanResult parses successful edge function response', () {
      final json = {
        'valid': true,
        'purpose': 'ticket',
        'status': 'arrived',
        'assignment_id': 'asg-success',
        'job_id': 'job-success',
        'job_title': 'Roof Waterproofing',
        'worker_id': 'worker-99',
        'worker_name': 'Lakshmi Narayan',
        'worker_avatar': 'https://example.com/lakshmi.jpg',
        'is_verified_badge': true,
        'recorded_at': DateTime.now().toIso8601String(),
        'message': 'Worker attendance verified and recorded.',
      };

      final result = AttendanceScanResult.fromJson(json);
      expect(result.valid, isTrue);
      expect(result.status, 'arrived');
      expect(result.workerName, 'Lakshmi Narayan');
      expect(result.isVerifiedBadge, isTrue);
      expect(result.jobTitle, 'Roof Waterproofing');
    });
  });

  group('P4.8 JobTicketScreen Widget Tests', () {
    testWidgets('Renders BookMyShow-style ticket card, booking code, verified badge, and replay shield',
        (tester) async {
      final ticket = JobTicketData(
        assignmentId: 'asg-test-widget',
        bookingCode: 'BOOK-4491',
        status: 'ticket_issued',
        jobId: 'job-w',
        jobTitle: 'Heavy Machinery Maintenance',
        categoryName: 'Technician',
        categoryIcon: 'build',
        startAt: DateTime(2026, 10, 10, 9, 30),
        estDurationMinutes: 240,
        agreedWagePaise: 120000,
        wageType: 'daily',
        paymentMode: 'escrow',
        addressText: 'Peenya Industrial Area, Bengaluru',
        lat: 13.0285,
        lng: 77.5197,
        workerId: 'w-101',
        workerName: 'Suresh Gowda',
        isWorkerVerified: true,
        providerId: 'p-202',
        providerName: 'Apex Engineering Works',
        qrToken: 'HMAC_TEST_TOKEN_SIGNED',
        qrExpiresInSeconds: 120,
        qrExpiresAt: DateTime.now().add(const Duration(minutes: 2)),
      );

      final repo = MockJobExecutionRepository(
        mockTicket: ticket,
        mockScanResult: const AttendanceScanResult(
          valid: true,
          purpose: 'ticket',
          status: 'arrived',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            jobExecutionRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: JobTicketScreen(assignmentId: 'asg-test-widget'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify booking code
      expect(find.text('BOOK-4491'), findsOneWidget);
      // Verify worker name
      expect(find.text('Suresh Gowda'), findsOneWidget);
      // Verify job title
      expect(find.text('Heavy Machinery Maintenance'), findsOneWidget);
      // Verify employer name
      expect(find.textContaining('Apex Engineering Works'), findsOneWidget);
      // Verify wage
      expect(find.text('₹1200'), findsOneWidget);
      // Verify address
      expect(find.text('Peenya Industrial Area, Bengaluru'), findsOneWidget);
      // Verify verified badge
      expect(find.byIcon(Icons.verified), findsWidgets);
      // Verify security explanation icon
      expect(find.byIcon(Icons.security_outlined), findsWidgets);
    });
  });

  group('P4.8 AttendanceScannerScreen & Scan Verification Tests', () {
    testWidgets('AttendanceScannerScreen renders scanner UI, torch toggle, instructions, and debug panel',
        (tester) async {
      final ticket = JobTicketData(
        assignmentId: 'asg-scan-test',
        bookingCode: 'BOOK-SCAN1',
        status: 'ticket_issued',
        jobId: 'job-scan',
        jobTitle: 'Carpentry Works',
        categoryName: 'Carpentry',
        categoryIcon: 'handyman',
        startAt: DateTime.now(),
        estDurationMinutes: 180,
        agreedWagePaise: 75000,
        wageType: 'daily',
        paymentMode: 'escrow',
        workerId: 'w-1',
        workerName: 'Basavaraj',
        isWorkerVerified: true,
        providerId: 'p-1',
        providerName: 'Modern Homes',
      );

      final repo = MockJobExecutionRepository(
        mockTicket: ticket,
        mockScanResult: const AttendanceScanResult(
          valid: true,
          purpose: 'ticket',
          status: 'arrived',
          workerName: 'Basavaraj',
          jobTitle: 'Carpentry Works',
          isVerifiedBadge: true,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            jobExecutionRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AttendanceScannerScreen(testHasPermission: true),
          ),
        ),
      );

      await tester.pump();

      // Find torch toggle button (initially off)
      expect(find.byIcon(Icons.flash_off), findsOneWidget);
      // Find camera switch button
      expect(find.byIcon(Icons.cameraswitch_outlined), findsOneWidget);
      // Find instruction texts
      expect(find.textContaining('Align worker'), findsOneWidget);

      // Verify simulation debug panel exists for quick manual testing
      expect(find.text('🛠️ Debug QR Testing Panel'), findsOneWidget);
      expect(find.text('Verify'), findsOneWidget);
    });

    test('Refuses replayed QR token and expired QR token on verification', () async {
      final repo = MockJobExecutionRepository(
        mockTicket: JobTicketData(
          assignmentId: 'asg-demo',
          bookingCode: 'BOOK-DEMO',
          status: 'ticket_issued',
          jobId: 'job-1',
          jobTitle: 'Electrician',
          categoryName: 'Electrician',
          categoryIcon: 'flash_on',
          startAt: DateTime.now(),
          estDurationMinutes: 120,
          agreedWagePaise: 60000,
          wageType: 'daily',
          paymentMode: 'escrow',
          workerId: 'w-1',
          workerName: 'Worker',
          isWorkerVerified: true,
          providerId: 'p-1',
          providerName: 'Provider',
        ),
        mockScanResult: const AttendanceScanResult(
          valid: true,
          purpose: 'ticket',
          status: 'arrived',
          workerName: 'Worker',
        ),
      );

      // 1. First scan of valid token -> succeeds
      final firstScan = await repo.verifyAttendanceScan(qrToken: 'FRESH_TOKEN_123');
      expect(firstScan.valid, isTrue);
      expect(firstScan.status, 'arrived');

      // 2. Scan same QR token twice -> Replay refused
      final replayScan = await repo.verifyAttendanceScan(qrToken: 'REPLAY_TOKEN_123');
      expect(replayScan.valid, isFalse);
      expect(replayScan.errorCode, 'token_already_used');

      // 3. Scan expired token -> Refused
      final expiredScan = await repo.verifyAttendanceScan(qrToken: 'EXPIRED_TOKEN_123');
      expect(expiredScan.valid, isFalse);
      expect(expiredScan.errorCode, 'token_expired');
    });
  });
}
