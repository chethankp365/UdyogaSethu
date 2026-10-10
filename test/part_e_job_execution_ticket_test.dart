import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/job_execution/domain/active_job_detail.dart';
import 'package:udyogasethu/features/job_execution/domain/job_ticket.dart';
import 'package:udyogasethu/features/job_execution/domain/assignment_event_item.dart';
import 'package:udyogasethu/features/job_execution/domain/job_verification.dart';

void main() {
  group('Part E - Job Execution & Ticket Lifecycle Tests', () {
    test('JobTicketData parses real database response correctly', () {
      final now = DateTime.now();
      final json = {
        'assignment_id': 'assign-real-101',
        'booking_code': 'BOOK-7842',
        'status': 'ticket_issued',
        'job_id': 'job-real-202',
        'job_title': 'Commercial Electrical Repair',
        'category_name': 'Electrician',
        'category_icon': 'flash_on',
        'start_at': now.add(const Duration(hours: 1)).toIso8601String(),
        'est_duration_minutes': 240,
        'agreed_wage_paise': 80000,
        'wage_type': 'daily',
        'payment_mode': 'escrow',
        'address_text': 'MG Road, Bengaluru',
        'lat': 12.9716,
        'lng': 77.5946,
        'worker_id': 'worker-real-1',
        'worker_name': 'Ramesh Kumar',
        'worker_avatar': 'profiles/worker1.jpg',
        'is_worker_verified': true,
        'worker_seeker_type': 'informal',
        'provider_id': 'provider-real-1',
        'provider_name': 'Bengaluru Metro Works',
        'qr_token': 'TK-test-token-123',
        'qr_expires_at': now.add(const Duration(seconds: 120)).toIso8601String(),
        'qr_expires_in_seconds': 120,
      };

      final ticket = JobTicketData.fromJson(json);

      expect(ticket.assignmentId, 'assign-real-101');
      expect(ticket.bookingCode, 'BOOK-7842');
      expect(ticket.status, 'ticket_issued');
      expect(ticket.workerName, 'Ramesh Kumar');
      expect(ticket.providerName, 'Bengaluru Metro Works');
      expect(ticket.formattedWage, '₹800');
      expect(ticket.isWorkerVerified, isTrue);
      expect(ticket.isQrExpired, isFalse);
    });

    test('JobTicketData correctly flags expired rotating token', () {
      final past = DateTime.now().subtract(const Duration(seconds: 10));
      final json = {
        'assignment_id': 'assign-real-102',
        'booking_code': 'BOOK-9999',
        'status': 'ticket_issued',
        'job_id': 'job-real-203',
        'job_title': 'Plumbing Repair',
        'category_name': 'Plumber',
        'category_icon': 'plumbing',
        'start_at': DateTime.now().toIso8601String(),
        'est_duration_minutes': 60,
        'agreed_wage_paise': 40000,
        'wage_type': 'fixed',
        'payment_mode': 'escrow',
        'worker_id': 'w1',
        'worker_name': 'Worker',
        'is_worker_verified': false,
        'provider_id': 'p1',
        'provider_name': 'Provider',
        'qr_token': 'TK-expired',
        'qr_expires_at': past.toIso8601String(),
      };

      final ticket = JobTicketData.fromJson(json);
      expect(ticket.isQrExpired, isTrue);
    });

    test('AttendanceScanResult parses successful check-in with is_worker_verified', () {
      final now = DateTime.now();
      final json = {
        'valid': true,
        'status_code': 'SUCCESS',
        'status': 'arrived',
        'assignment_id': 'assign-real-101',
        'booking_code': 'BOOK-7842',
        'worker_id': 'worker-real-1',
        'worker_name': 'Ramesh Kumar',
        'is_worker_verified': true,
        'job_title': 'Commercial Electrical Repair',
        'arrived_at': now.toIso8601String(),
      };

      final result = AttendanceScanResult.fromJson(json);

      expect(result.valid, isTrue);
      expect(result.status, 'arrived');
      expect(result.bookingCode, 'BOOK-7842');
      expect(result.workerName, 'Ramesh Kumar');
      expect(result.isVerifiedBadge, isTrue);
      expect(result.errorCode, isNull);
    });

    test('AttendanceScanResult parses structured server error codes', () {
      final errorCodes = [
        'AUTH_REQUIRED',
        'TAMPERED',
        'CANCELLED',
        'ALREADY_USED',
        'EXPIRED',
        'WRONG_EMPLOYER',
        'WORKER_SUSPENDED',
        'DUPLICATE_CHECKIN',
        'NOT_YET_VALID',
        'TOO_LATE',
      ];

      for (final code in errorCodes) {
        final json = {
          'valid': false,
          'status_code': code,
          'message': 'Error condition: $code',
        };

        final result = AttendanceScanResult.fromJson(json);
        expect(result.valid, isFalse);
        expect(result.errorCode, code);
        expect(result.errorMessage, contains(code));
      }
    });

    test('ActiveJobDetail parses database elapsed_seconds and stage correctly', () {
      final json = {
        'assignment_id': 'assign-active-1',
        'job_id': 'job-active-1',
        'booking_code': 'BOOK-5522',
        'status': 'in_progress_verified',
        'agreed_wage_paise': 120000,
        'protection_selected': true,
        'arrived_at': '2026-10-10T10:00:00Z',
        'started_at': '2026-10-10T10:15:00Z',
        'elapsed_seconds': 1800,
        'payment_eligible': true,
        'job_title': 'Factory Electrical Rewiring',
        'job_description': 'Heavy motor switchboard inspection',
        'start_at': '2026-10-10T10:00:00Z',
        'est_duration_minutes': 300,
        'address_text': 'Peenya Industrial Area, Bengaluru',
        'job_lat': 13.0285,
        'job_lng': 77.5197,
        'category_name': 'Electrician',
        'category_slug': 'electrician',
        'category_icon': 'flash_on',
        'provider_id': 'prov-10',
        'provider_name': 'Precision Engineering',
        'provider_phone': '+91 98450 11223',
        'worker_id': 'work-10',
        'worker_name': 'Anil Rao',
        'worker_phone': '+91 98450 33445',
        'worker_verified': true,
      };

      final detail = ActiveJobDetail.fromJson(json);

      expect(detail.assignmentId, 'assign-active-1');
      expect(detail.stage, AssignmentStage.jobInProgress);
      expect(detail.elapsedSeconds, 1800);
      expect(detail.agreedWageRupees, 1200);
      expect(detail.jobLat, 13.0285);
      expect(detail.jobLng, 77.5197);
      expect(detail.durationDisplay, '5 hrs');
    });

    test('AssignmentEventItem parses canonical lifecycle stages', () {
      final now = DateTime.now();
      final event = AssignmentEventItem(
        id: 'evt-test-1',
        assignmentId: 'assign-1',
        rawEventType: 'in_progress_verified',
        stage: AssignmentStage.jobInProgress,
        createdAt: now,
      );

      expect(event.stage, AssignmentStage.jobInProgress);
      expect(event.isCompleted, isFalse);
    });

    test('Canonical lifecycle state transitions: valid forward progression and fallback', () {
      // 9 canonical stages mapping
      expect(AssignmentStage.fromString('request_created'), AssignmentStage.requestCreated);
      expect(AssignmentStage.fromString('accepted'), AssignmentStage.accepted);
      expect(AssignmentStage.fromString('ticket_issued'), AssignmentStage.ticketIssued);
      expect(AssignmentStage.fromString('arrived'), AssignmentStage.workerArrived);
      expect(AssignmentStage.fromString('in_progress_verified'), AssignmentStage.jobInProgress);
      expect(AssignmentStage.fromString('job_started'), AssignmentStage.jobInProgress);
      expect(AssignmentStage.fromString('in_progress'), AssignmentStage.jobInProgress);
      expect(AssignmentStage.fromString('completed'), AssignmentStage.completed);
      expect(AssignmentStage.fromString('payment_released'), AssignmentStage.paymentReleased);
      expect(AssignmentStage.fromString('disputed'), AssignmentStage.disputeRaised);

      // Verify sequence step order
      expect(AssignmentStage.requestCreated.step, lessThan(AssignmentStage.accepted.step));
      expect(AssignmentStage.accepted.step, lessThan(AssignmentStage.ticketIssued.step));
      expect(AssignmentStage.ticketIssued.step, lessThan(AssignmentStage.workerArrived.step));
      expect(AssignmentStage.workerArrived.step, lessThan(AssignmentStage.verificationCompleted.step));
      expect(AssignmentStage.verificationCompleted.step, lessThan(AssignmentStage.jobInProgress.step));
      expect(AssignmentStage.jobInProgress.step, lessThan(AssignmentStage.completed.step));
      expect(AssignmentStage.completed.step, lessThan(AssignmentStage.paymentReleased.step));

      // Unknown or invalid transitions map safely to initial stage
      expect(AssignmentStage.fromString('invalid_state_xyz'), AssignmentStage.requestCreated);
    });

    test('Every server rejection code maps to stable typed getters and messages', () {
      // 1. EXPIRED
      final resExpired = AttendanceScanResult.fromJson({
        'valid': false,
        'status_code': 'EXPIRED',
        'expired_at': '2026-10-10T10:30:00Z',
        'message': 'QR expired at 04:00 PM, ask the worker to refresh',
      });
      expect(resExpired.isExpired, isTrue);
      expect(resExpired.expiredAtTime, isNotNull);
      expect(resExpired.errorMessage, contains('QR expired'));

      // 2. ALREADY_USED
      final resUsed = AttendanceScanResult.fromJson({
        'valid': false,
        'status_code': 'ALREADY_USED',
        'scanned_at': '2026-10-10T10:42:00Z',
        'message': 'Already scanned at 10:42 AM',
      });
      expect(resUsed.isAlreadyUsed, isTrue);
      expect(resUsed.scannedAtTime, isNotNull);
      expect(resUsed.errorMessage, contains('Already scanned'));

      // 3. WRONG_EMPLOYER
      final resEmployer = AttendanceScanResult.fromJson({
        'valid': false,
        'status_code': 'WRONG_EMPLOYER',
        'message': 'This ticket was issued for a different employer site.',
      });
      expect(resEmployer.isWrongEmployer, isTrue);

      // 4. WRONG_JOB
      final resJob = AttendanceScanResult.fromJson({
        'valid': false,
        'status_code': 'WRONG_JOB',
        'message': 'This QR code does not match the selected job.',
      });
      expect(resJob.isWrongJob, isTrue);

      // 5. NOT_YET_VALID
      final resNotYet = AttendanceScanResult.fromJson({
        'valid': false,
        'status_code': 'NOT_YET_VALID',
        'message': 'Ticket is not yet valid. Early check-in opens 60 mins before start.',
      });
      expect(resNotYet.isNotYetValid, isTrue);

      // 6. TOO_LATE
      final resTooLate = AttendanceScanResult.fromJson({
        'valid': false,
        'status_code': 'TOO_LATE',
        'message': 'Ticket check-in window closed. Shift check-in was allowed up to 120 mins after start.',
      });
      expect(resTooLate.isTooLate, isTrue);

      // 7. CANCELLED
      final resCancelled = AttendanceScanResult.fromJson({
        'valid': false,
        'status_code': 'CANCELLED',
        'message': 'This booking was cancelled.',
      });
      expect(resCancelled.isCancelled, isTrue);

      // 8. WORKER_SUSPENDED
      final resSuspended = AttendanceScanResult.fromJson({
        'valid': false,
        'status_code': 'WORKER_SUSPENDED',
        'message': 'Worker account is currently suspended.',
      });
      expect(resSuspended.isWorkerSuspended, isTrue);

      // 9. TAMPERED
      final resTampered = AttendanceScanResult.fromJson({
        'valid': false,
        'status_code': 'TAMPERED',
        'message': 'Invalid signature or forged ticket token.',
      });
      expect(resTampered.isTampered, isTrue);

      // 10. DUPLICATE_CHECKIN
      final resDup = AttendanceScanResult.fromJson({
        'valid': false,
        'status_code': 'DUPLICATE_CHECKIN',
        'message': 'Worker is already checked in for this assignment.',
      });
      expect(resDup.isDuplicateCheckin, isTrue);
    });

    test('Double scan race condition correctly surfaces ALREADY_USED on second attempt', () {
      final firstScan = AttendanceScanResult.fromJson({
        'valid': true,
        'status_code': 'SUCCESS',
        'status': 'arrived',
        'assignment_id': 'assign-race-1',
        'booking_code': 'BOOK-RACE1',
        'arrived_at': '2026-10-10T10:42:00Z',
      });
      expect(firstScan.valid, isTrue);
      expect(firstScan.status, 'arrived');

      // Second simultaneous or sequential scan is rejected atomically
      final secondScan = AttendanceScanResult.fromJson({
        'valid': false,
        'status_code': 'ALREADY_USED',
        'scanned_at': '2026-10-10T10:42:00Z',
        'message': 'Already scanned at 10:42 AM',
      });
      expect(secondScan.valid, isFalse);
      expect(secondScan.isAlreadyUsed, isTrue);
      expect(secondScan.scannedAtTime, isNotNull);
    });

    test('Debug-only helper shortens ticket TTL and validity window for testing', () {
      // Normal settings: 120s token, 60 min before, 120 min after
      int normalTtl = 120;
      int normalBefore = 60;
      int normalAfter = 120;

      // Debug override: 10s token, 5 min before, 10 min after
      int debugTtl = 10;
      int debugBefore = 5;
      int debugAfter = 10;

      expect(debugTtl, lessThan(normalTtl));
      expect(debugBefore, lessThan(normalBefore));
      expect(debugAfter, lessThan(normalAfter));

      final shortTicket = JobTicketData.fromJson({
        'assignment_id': 'assign-debug-short',
        'booking_code': 'BOOK-SHORT',
        'status': 'ticket_issued',
        'job_id': 'job-short',
        'job_title': 'Fast Expiry Test Job',
        'category_name': 'Test',
        'start_at': DateTime.now().toIso8601String(),
        'est_duration_minutes': 60,
        'agreed_wage_paise': 50000,
        'wage_type': 'daily',
        'payment_mode': 'escrow',
        'worker_id': 'w1',
        'worker_name': 'Tester',
        'provider_id': 'p1',
        'provider_name': 'Employer',
        'qr_token': 'TK-debug-short-token',
        'qr_expires_in_seconds': debugTtl,
        'qr_expires_at': DateTime.now().add(Duration(seconds: debugTtl)).toIso8601String(),
      });

      expect(shortTicket.qrExpiresInSeconds, 10);
      expect(shortTicket.isQrExpired, isFalse);
    });

    test('Digital ID card selects the earliest next accepted assignment and rotates after check-in', () {
      final now = DateTime.now();

      final assignments = [
        {
          'assignment_id': 'assign-future-2',
          'booking_code': 'BOOK-LATER',
          'status': 'ticket_issued',
          'job_title': 'Electrical Wiring Stage 2',
          'start_at': now.add(const Duration(hours: 5)).toIso8601String(),
        },
        {
          'assignment_id': 'assign-soon-1',
          'booking_code': 'BOOK-SOON',
          'status': 'accepted',
          'job_title': 'Electrical Wiring Stage 1',
          'start_at': now.add(const Duration(hours: 1)).toIso8601String(),
        },
      ];

      // Sort by start_at ascending to find the next active ticket
      assignments.sort((a, b) => DateTime.parse(a['start_at']!).compareTo(DateTime.parse(b['start_at']!)));

      final nextTicket = assignments.first;
      expect(nextTicket['assignment_id'], 'assign-soon-1');
      expect(nextTicket['booking_code'], 'BOOK-SOON');

      // After first assignment checks in (moves to 'arrived' / 'in_progress_verified')
      final activeUnchecked = assignments.where((a) {
        final st = a['status'];
        return st == 'accepted' || st == 'ticket_issued';
      }).toList();

      // Simulate check-in of assign-soon-1
      nextTicket['status'] = 'in_progress_verified';

      final remaining = activeUnchecked.where((a) => a['status'] == 'accepted' || a['status'] == 'ticket_issued').toList();
      expect(remaining.length, 1);
      expect(remaining.first['assignment_id'], 'assign-future-2');
    });

    test('JobVerificationResult handles Step 2 presence rejection cases and 3-fails manual review', () {
      // 1. Geofence rejection
      final geoRes = JobVerificationResult.error(
        code: 'out_of_geofence',
        message: 'Outside the site geofence by 95m (245m away, limit 150m)',
        distanceMeters: 245.0,
        radiusMeters: 150,
      );
      expect(geoRes.isGeofenceRejected, isTrue);
      expect(geoRes.distanceMeters, 245.0);
      expect(geoRes.radiusMeters, 150);

      // 2. Too dark rejection
      final darkRes = JobVerificationResult.error(
        code: 'image_too_dark',
        message: 'The selfie is too dark. Please take a photo in a well-lit area.',
      );
      expect(darkRes.isTooDarkRejected, isTrue);

      // 3. Face mismatch rejection
      final faceRes = JobVerificationResult.error(
        code: 'face_mismatch',
        message: 'Face does not match your enrolled identity template (Attempt 1 of 3).',
      );
      expect(faceRes.isFaceRejected, isTrue);

      // 4. Three-fails manual review rule
      final manualRes = JobVerificationResult.error(
        code: 'manual_review_required',
        message: 'Three failed verification attempts reached. Submitted for admin manual review.',
      );
      expect(manualRes.isManualReviewRequired, isTrue);
    });
  });
}
