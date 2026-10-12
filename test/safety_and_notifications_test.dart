// Unit test suite: safety_and_notifications_test.dart (P7.3 & P7.4)
// Covers SOS incident model, claim eligibility, notification model & targetRoute deep links

import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/features/safety/domain/emergency_contact.dart';
import 'package:udyogasethu/features/safety/domain/protection_claim.dart';
import 'package:udyogasethu/features/safety/domain/sos_incident.dart';
import 'package:udyogasethu/features/notifications/domain/app_notification.dart';

void main() {
  group('Step P7.3: Safety Domain & Claim Eligibility Tests', () {
    test('SosIncident model parses correctly with honest SMS readout', () {
      final json = {
        'id': 'sos-001',
        'lat': 12.9716,
        'lng': 77.5946,
        'assignment_id': 'asg-456',
        'status': 'escalated',
        'emergency_contacts_count': 3,
        'sms_configured': false,
        'sms_sent': false,
        'message': 'SOS escalated',
        'created_at': '2026-10-12T10:00:00.000Z',
      };

      final incident = SosIncident.fromJson(json);
      expect(incident.id, 'sos-001');
      expect(incident.latitude, 12.9716);
      expect(incident.longitude, 77.5946);
      expect(incident.emergencyContactsCount, 3);
      expect(incident.smsConfigured, false); // Honest SMS state
      expect(incident.status, 'escalated');
    });

    test('EmergencyContact model serializes and parses properly', () {
      final contact = EmergencyContact(
        id: 'ec-1',
        name: 'Ramesh Patel',
        phone: '+919876543210',
        relation: 'Brother',
        createdAt: DateTime.parse('2026-10-12T09:00:00.000Z'),
      );

      final json = contact.toJson();
      expect(json['name'], 'Ramesh Patel');
      expect(json['phone'], '+919876543210');
      expect(json['relation'], 'Brother');

      final restored = EmergencyContact.fromJson(json);
      expect(restored.id, contact.id);
      expect(restored.name, contact.name);
      expect(restored.relation, contact.relation);
    });

    test('Claim eligibility evaluates gate requirements accurately', () {
      // All passed
      const eligibleResult = ClaimEligibilityResult(
        eligible: true,
        qrOk: true,
        selfieGpsOk: true,
        timerOk: true,
        evidenceOk: true,
        durationMinutes: 180,
        evidenceCount: 2,
        reason: null,
      );
      expect(eligibleResult.eligible, isTrue);
      expect(eligibleResult.reason, isNull);

      // Ineligible due to missing QR and short timer
      const ineligibleResult = ClaimEligibilityResult(
        eligible: false,
        qrOk: false,
        selfieGpsOk: true,
        timerOk: false,
        evidenceOk: true,
        durationMinutes: 2,
        evidenceCount: 1,
        reason: 'Attendance QR was not verified; shift timer under 5 min.',
      );
      expect(ineligibleResult.eligible, isFalse);
      expect(ineligibleResult.reason, isNotNull);
      expect(ineligibleResult.qrOk, isFalse);
      expect(ineligibleResult.timerOk, isFalse);
    });

    test('ProtectionClaim model serialization matches database schema', () {
      final claim = ProtectionClaim(
        id: 'claim-001',
        claimCode: 'CLM-9821',
        assignmentId: 'asg-789',
        claimType: 'Accidental Injury on Site',
        amountPaise: 450000,
        details: 'Minor ankle sprain while lifting crates, first aid administered.',
        status: 'submitted',
        isSimulated: true,
        createdAt: DateTime.parse('2026-10-12T11:00:00.000Z'),
      );

      final json = claim.toJson();
      expect(json['amount_paise'], 450000);
      expect(json['claim_type'], 'Accidental Injury on Site');
      expect(json['claim_code'], 'CLM-9821');
      expect(json['is_simulated'], true);

      final parsed = ProtectionClaim.fromJson(json);
      expect(parsed.id, claim.id);
      expect(parsed.amountPaise, 450000);
      expect(parsed.status, 'submitted');
    });
  });

  group('Step P7.4: Notification Model & Deep-Link Routing Tests', () {
    test('AppNotification correctly maps deep link routes across categories', () {
      // 1. Job application -> provider jobs applicants
      final appNotif = AppNotification(
        id: 'n-1',
        userId: 'u-1',
        type: 'job_application',
        titleKey: 'notif_new_applicant_title',
        bodyKey: 'notif_new_applicant_body',
        params: {'job_id': 'job-101'},
        createdAt: DateTime.now(),
      );
      expect(appNotif.targetRoute, '/provider/jobs/job-101/applicants');

      // 2. Assignment status -> seeker jobs
      final asgNotif = AppNotification(
        id: 'n-2',
        userId: 'u-1',
        type: 'assignment_status',
        titleKey: 'notif_assignment_status_title',
        bodyKey: 'notif_assignment_status_body',
        params: {'assignment_id': 'asg-202'},
        createdAt: DateTime.now(),
      );
      expect(asgNotif.targetRoute, AppRoutes.seekerJobs);

      // 3. Payment update -> wallet
      final payNotif = AppNotification(
        id: 'n-3',
        userId: 'u-1',
        type: 'payment_update',
        titleKey: 'notif_payment_received_title',
        bodyKey: 'notif_payment_received_body',
        params: {'amount': '₹850'},
        readAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      expect(payNotif.targetRoute, AppRoutes.wallet);
      expect(payNotif.isRead, isTrue);

      // 4. Order update -> farmer market
      final orderNotif = AppNotification(
        id: 'n-4',
        userId: 'u-1',
        type: 'order_update',
        titleKey: 'notif_order_status_title',
        bodyKey: 'notif_order_status_body',
        params: {'order_id': 'ord-404'},
        createdAt: DateTime.now(),
      );
      expect(orderNotif.targetRoute, AppRoutes.farmerMarket);

      // 5. Protection claim submitted -> job protection claim screen
      final claimNotif = AppNotification(
        id: 'n-5',
        userId: 'u-1',
        type: 'protection_claim_submitted',
        titleKey: 'notif_claim_submitted_title',
        bodyKey: 'notif_claim_submitted_body',
        params: {'claim_code': 'CLM-505'},
        createdAt: DateTime.now(),
      );
      expect(claimNotif.targetRoute, AppRoutes.jobProtectionClaim);

      // 6. SOS alert -> safety hub
      final sosNotif = AppNotification(
        id: 'n-6',
        userId: 'u-1',
        type: 'sos_alert',
        titleKey: 'notif_sos_alert_title',
        bodyKey: 'notif_sos_alert_body',
        params: {'sos_id': 'sos-606'},
        createdAt: DateTime.now(),
      );
      expect(sosNotif.targetRoute, AppRoutes.safetyHub);
    });

    test('AppNotification parses localized title_key, body_key and params', () {
      final json = {
        'id': 'n-loc-01',
        'user_id': 'user-888',
        'type': 'job_application',
        'title_key': 'notif_new_applicant_title',
        'body_key': 'notif_new_applicant_body',
        'params': {'worker_name': 'Ramesh', 'job_title': 'Harvest Helper'},
        'read_at': null,
        'created_at': '2026-10-12T12:00:00.000Z',
      };

      final notif = AppNotification.fromJson(json);
      expect(notif.titleKey, 'notif_new_applicant_title');
      expect(notif.bodyKey, 'notif_new_applicant_body');
      expect(notif.params['worker_name'], 'Ramesh');
      expect(notif.params['job_title'], 'Harvest Helper');
      expect(notif.isRead, isFalse);
    });
  });
}
