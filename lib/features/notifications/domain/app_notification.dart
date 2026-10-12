// Domain entity: AppNotification (Step P7.4)

import 'package:flutter/material.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String titleKey;
  final String bodyKey;
  final Map<String, dynamic> params;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.titleKey,
    required this.bodyKey,
    this.params = const {},
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      titleKey: json['title_key'] as String? ?? 'notif_general_title',
      bodyKey: json['body_key'] as String? ?? 'notif_general_body',
      params: (json['params'] as Map<String, dynamic>?) ?? {},
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String getDisplayTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      switch (titleKey) {
        case 'notif_new_applicant_title':
          return 'New Job Applicant';
        case 'notif_application_status_title':
          return 'Application Update';
        case 'notif_assignment_status_title':
          return 'Booking Status Update';
        case 'notif_new_order_title':
          return 'New Farm Produce Order';
        case 'notif_order_status_title':
          return 'Produce Order Update';
        case 'notif_payment_received_title':
          return 'Payment Received';
        case 'notif_sos_alert_title':
          return 'EMERGENCY SOS ALERT';
        case 'notif_claim_submitted_title':
          return 'Job Protection Claim';
        default:
          return 'Notification';
      }
    }
    switch (titleKey) {
      case 'notif_new_applicant_title':
        return l10n.notifNewApplicantTitle;
      case 'notif_application_status_title':
        return l10n.notifApplicationStatusTitle;
      case 'notif_assignment_status_title':
        return l10n.notifAssignmentStatusTitle;
      case 'notif_new_order_title':
        return l10n.notifNewOrderTitle;
      case 'notif_order_status_title':
        return l10n.notifOrderStatusTitle;
      case 'notif_payment_received_title':
        return l10n.notifPaymentReceivedTitle;
      case 'notif_sos_alert_title':
        return l10n.notifSosAlertTitle;
      case 'notif_claim_submitted_title':
        return l10n.notifClaimSubmittedTitle;
      default:
        return l10n.notifGeneralTitle;
    }
  }

  String getDisplayBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final worker = (params['worker_name'] ?? 'A worker').toString();
    final job = (params['job_title'] ?? 'your job').toString();
    final status = (params['status'] ?? 'updated').toString();
    final code = (params['booking_code'] ?? params['order_code'] ?? 'Booking').toString();
    final amount = (params['amount'] ?? '').toString();
    final type = (params['claim_type'] ?? 'Accident cover').toString();

    if (l10n == null) {
      switch (bodyKey) {
        case 'notif_new_applicant_body':
          return '$worker applied for $job';
        case 'notif_application_status_body':
          return 'Your application for $job was updated to $status';
        case 'notif_assignment_status_body':
          return '$code is now $status';
        case 'notif_new_order_body':
          return 'New farm produce order $code received';
        case 'notif_order_status_body':
          return '$code status updated to $status';
        case 'notif_payment_received_body':
          return 'Payment received: $amount';
        case 'notif_sos_alert_body':
          return 'Emergency SOS incident registered. Safety team alerted.';
        case 'notif_claim_submitted_body':
          return 'Your claim for $type was registered for review.';
        default:
          return 'You have a new update in UdyogaSethu.';
      }
    }

    switch (bodyKey) {
      case 'notif_new_applicant_body':
        return l10n.notifNewApplicantBody(worker, job);
      case 'notif_application_status_body':
        return l10n.notifApplicationStatusBody(job, status);
      case 'notif_assignment_status_body':
        return l10n.notifAssignmentStatusBody(code, status);
      case 'notif_new_order_body':
        return l10n.notifNewOrderBody(code);
      case 'notif_order_status_body':
        return l10n.notifOrderStatusBody(code, status);
      case 'notif_payment_received_body':
        return l10n.notifPaymentReceivedBody(amount);
      case 'notif_sos_alert_body':
        return l10n.notifSosAlertBody;
      case 'notif_claim_submitted_body':
        return l10n.notifClaimSubmittedBody(type);
      default:
        return l10n.notifGeneralBody;
    }
  }

  String? get targetRoute {
    switch (type) {
      case 'job_application':
        final jobId = params['job_id'];
        return jobId != null ? '/provider/jobs/$jobId/applicants' : AppRoutes.providerHome;
      case 'application_update':
        return AppRoutes.seekerJobs;
      case 'assignment_status':
        return AppRoutes.seekerJobs;
      case 'order_update':
        return AppRoutes.farmerMarket;
      case 'payment_update':
        return AppRoutes.wallet;
      case 'sos_alert':
        return AppRoutes.safetyHub;
      case 'protection_claim_submitted':
        return AppRoutes.jobProtectionClaim;
      default:
        return null;
    }
  }
}
