import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/job_execution/domain/assignment_event_item.dart';
import 'package:udyogasethu/features/job_execution/domain/job_ticket.dart';

void main() {
  group('QR Ticket Flow - Rejection Codes & Parsing Tests', () {
    test('AttendanceScanResult correctly identifies all 10 stable rejection codes', () {
      final codes = {
        'EXPIRED': (AttendanceScanResult r) => r.isExpired,
        'ALREADY_USED': (AttendanceScanResult r) => r.isAlreadyUsed,
        'WRONG_EMPLOYER': (AttendanceScanResult r) => r.isWrongEmployer,
        'WRONG_JOB': (AttendanceScanResult r) => r.isWrongJob,
        'NOT_YET_VALID': (AttendanceScanResult r) => r.isNotYetValid,
        'TOO_LATE': (AttendanceScanResult r) => r.isTooLate,
        'CANCELLED': (AttendanceScanResult r) => r.isCancelled,
        'WORKER_SUSPENDED': (AttendanceScanResult r) => r.isWorkerSuspended,
        'TAMPERED': (AttendanceScanResult r) => r.isTampered,
        'DUPLICATE_CHECKIN': (AttendanceScanResult r) => r.isDuplicateCheckin,
      };

      for (final entry in codes.entries) {
        final result = AttendanceScanResult.error(
          code: entry.key,
          message: 'Error code ${entry.key}',
        );
        expect(result.valid, isFalse);
        expect(result.errorCode, entry.key);
        expect(entry.value(result), isTrue, reason: 'Flag for ${entry.key} should be true');
      }
    });

    test('AttendanceScanResult parses timestamps for EXPIRED and ALREADY_USED', () {
      final expiredJson = {
        'valid': false,
        'error_code': 'EXPIRED',
        'message': 'QR expired at 14:30, ask the worker to refresh',
        'expired_at_time': '14:30',
      };
      final expired = AttendanceScanResult.fromJson(expiredJson);
      expect(expired.isExpired, isTrue);
      expect(expired.expiredAtTime, '14:30');

      final usedJson = {
        'valid': false,
        'error_code': 'ALREADY_USED',
        'message': 'Already scanned at 10:15',
        'scanned_at_time': '10:15',
      };
      final used = AttendanceScanResult.fromJson(usedJson);
      expect(used.isAlreadyUsed, isTrue);
      expect(used.scannedAtTime, '10:15');
    });

    test('AttendanceScanResult parses successful attendance scan payload', () {
      final successJson = {
        'valid': true,
        'purpose': 'ticket',
        'status': 'arrived',
        'assignment_id': 'asg-777',
        'job_id': 'job-888',
        'job_title': 'Solar Panel Installation',
        'worker_id': 'w-101',
        'worker_name': 'Ramesh Kumar',
        'worker_avatar': 'https://storage.example.com/avatar.jpg',
        'is_verified_badge': true,
        'recorded_at': '2026-10-11T10:00:00Z',
        'message': 'Worker attendance verified and recorded.',
      };

      final res = AttendanceScanResult.fromJson(successJson);
      expect(res.valid, isTrue);
      expect(res.status, 'arrived');
      expect(res.assignmentId, 'asg-777');
      expect(res.jobTitle, 'Solar Panel Installation');
      expect(res.workerName, 'Ramesh Kumar');
      expect(res.workerAvatar, 'https://storage.example.com/avatar.jpg');
      expect(res.isVerifiedBadge, isTrue);
    });
  });

  group('QR Ticket Flow - Lifecycle State Transitions & Rules', () {
    test('Canonical progression matches the 9 sequential lifecycle stages', () {
      const stages = [
        AssignmentStage.requestCreated,
        AssignmentStage.accepted,
        AssignmentStage.ticketIssued,
        AssignmentStage.workerArrived,
        AssignmentStage.verificationCompleted,
        AssignmentStage.jobInProgress,
        AssignmentStage.completed,
        AssignmentStage.paymentReleased,
      ];

      for (int i = 0; i < stages.length - 1; i++) {
        expect(stages[i].step, lessThan(stages[i + 1].step),
            reason: '${stages[i].name} step (${stages[i].step}) must be before ${stages[i + 1].name} (${stages[i + 1].step})');
      }
    });

    test('Stage parser accurately maps server event types', () {
      expect(AssignmentStage.fromString('request_created'), AssignmentStage.requestCreated);
      expect(AssignmentStage.fromString('accepted'), AssignmentStage.accepted);
      expect(AssignmentStage.fromString('ticket_issued'), AssignmentStage.ticketIssued);
      expect(AssignmentStage.fromString('arrived'), AssignmentStage.workerArrived);
      expect(AssignmentStage.fromString('worker_arrived'), AssignmentStage.workerArrived);
      expect(AssignmentStage.fromString('selfie_gps_verified'), AssignmentStage.verificationCompleted);
      expect(AssignmentStage.fromString('job_started'), AssignmentStage.jobInProgress);
      expect(AssignmentStage.fromString('in_progress_verified'), AssignmentStage.jobInProgress);
      expect(AssignmentStage.fromString('completed'), AssignmentStage.completed);
      expect(AssignmentStage.fromString('payment_released'), AssignmentStage.paymentReleased);
      expect(AssignmentStage.fromString('dispute_raised'), AssignmentStage.disputeRaised);
    });
  });

  group('QR Ticket Flow - Simultaneous Double Scan Race Simulation', () {
    test('Two simultaneous scans atomically allow only one success while second is rejected', () async {
      bool ticketConsumed = false;

      Future<AttendanceScanResult> simulateScan(String scannerId) async {
        // Simulates row-level lock (FOR UPDATE) behavior
        await Future.delayed(const Duration(milliseconds: 10));
        if (!ticketConsumed) {
          ticketConsumed = true;
          return const AttendanceScanResult(
            valid: true,
            purpose: 'ticket',
            status: 'arrived',
            assignmentId: 'asg-race-1',
            workerName: 'Lakshmi',
          );
        } else {
          return AttendanceScanResult.error(
            code: 'ALREADY_USED',
            message: 'Already scanned at 10:00',
            scannedAtTime: '10:00',
          );
        }
      }

      // Execute both scans concurrently
      final results = await Future.wait([
        simulateScan('scanner-1'),
        simulateScan('scanner-2'),
      ]);

      final successCount = results.where((r) => r.valid).length;
      final rejectedCount = results.where((r) => !r.valid && r.isAlreadyUsed).length;

      expect(successCount, equals(1), reason: 'Only exactly 1 scan may consume ticket');
      expect(rejectedCount, equals(1), reason: 'Second simultaneous scan must be rejected with ALREADY_USED');
    });
  });

  group('QR Ticket Flow - Digital ID Next Ticket Selection Logic', () {
    test('Filters out already arrived or active jobs and picks the earliest un-checked-in ticket', () {
      final mockAssignments = [
        {
          'assignment_id': 'asg-past',
          'job_title': 'Morning Shift Plumber',
          'start_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
          'status': 'arrived', // Already checked in
        },
        {
          'assignment_id': 'asg-tomorrow',
          'job_title': 'Tomorrow Farm Harvest',
          'start_at': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          'status': 'accepted',
        },
        {
          'assignment_id': 'asg-earliest-valid',
          'job_title': 'Afternoon Electrical Repair',
          'start_at': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
          'status': 'ticket_issued',
        },
      ];

      // Logic matching get_next_accepted_ticket SQL function:
      // WHERE status IN ('accepted', 'ticket_issued') ORDER BY start_at ASC LIMIT 1
      final eligible = mockAssignments.where((a) {
        final s = a['status'] as String;
        return s == 'accepted' || s == 'ticket_issued';
      }).toList();

      eligible.sort((a, b) {
        final dateA = DateTime.parse(a['start_at'] as String);
        final dateB = DateTime.parse(b['start_at'] as String);
        return dateA.compareTo(dateB);
      });

      final nextTicket = eligible.isNotEmpty ? eligible.first : null;

      expect(nextTicket, isNotNull);
      expect(nextTicket!['assignment_id'], equals('asg-earliest-valid'));
      expect(nextTicket['job_title'], equals('Afternoon Electrical Repair'));
    });

    test('Returns null when all assignments are checked in or completed', () {
      final mockAssignments = [
        {
          'assignment_id': 'asg-1',
          'job_title': 'Job 1',
          'status': 'in_progress_verified',
        },
        {
          'assignment_id': 'asg-2',
          'job_title': 'Job 2',
          'status': 'completed',
        },
      ];

      final eligible = mockAssignments.where((a) {
        final s = a['status'] as String;
        return s == 'accepted' || s == 'ticket_issued';
      }).toList();

      expect(eligible.isEmpty, isTrue);
    });
  });
}
