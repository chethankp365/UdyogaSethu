import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/job_execution/domain/active_job_detail.dart';
import 'package:udyogasethu/features/job_execution/domain/job_ticket.dart';
import 'package:udyogasethu/features/job_execution/domain/assignment_event_item.dart';

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
  });
}
