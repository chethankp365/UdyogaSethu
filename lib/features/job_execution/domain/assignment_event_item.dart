import 'package:flutter/material.dart';

/// The 9 canonical lifecycle stages of a job assignment in UdyogaSethu.
enum AssignmentStage {
  requestCreated(1, 'Request Created', Icons.assignment_outlined),
  accepted(2, 'Accepted', Icons.check_circle_outline_rounded),
  ticketIssued(3, 'Ticket Issued', Icons.confirmation_number_outlined),
  workerArrived(4, 'Worker Arrived', Icons.pin_drop_outlined),
  verificationCompleted(5, 'Verification Completed', Icons.verified_user_outlined),
  jobInProgress(6, 'Job In Progress', Icons.construction_rounded),
  completed(7, 'Completed', Icons.task_alt_rounded),
  paymentReleased(8, 'Payment Released', Icons.payments_outlined),
  disputeRaised(9, 'Dispute Raised', Icons.warning_amber_rounded);

  final int step;
  final String title;
  final IconData icon;

  const AssignmentStage(this.step, this.title, this.icon);

  /// Maps any database status or event string to the canonical stage.
  static AssignmentStage fromString(String val) {
    final lower = val.toLowerCase().trim();
    switch (lower) {
      case 'requested':
      case 'request_created':
      case 'created':
      case 'direct_booking':
        return AssignmentStage.requestCreated;
      case 'accepted':
        return AssignmentStage.accepted;
      case 'ticket_issued':
      case 'ticket_generated':
        return AssignmentStage.ticketIssued;
      case 'arrived':
      case 'worker_arrived':
        return AssignmentStage.workerArrived;
      case 'verification_completed':
      case 'verified_start':
      case 'face_verified':
      case 'qr_scanned':
      case 'selfie_gps_verified':
        return AssignmentStage.verificationCompleted;
      case 'job_started':
      case 'in_progress':
      case 'in_progress_verified':
      case 'job_in_progress':
        return AssignmentStage.jobInProgress;
      case 'completed':
      case 'done':
        return AssignmentStage.completed;
      case 'payment_released':
      case 'paid':
      case 'escrow_released':
        return AssignmentStage.paymentReleased;
      case 'disputed':
      case 'dispute_raised':
        return AssignmentStage.disputeRaised;
      default:
        return AssignmentStage.requestCreated;
    }
  }
}

/// An immutable event in the job assignment timeline.
class AssignmentEventItem {
  final String id;
  final String assignmentId;
  final String rawEventType;
  final AssignmentStage stage;
  final String? actorId;
  final String? actorRole; // 'worker' or 'provider' or 'admin'
  final Map<String, dynamic> meta;
  final DateTime createdAt;

  const AssignmentEventItem({
    required this.id,
    required this.assignmentId,
    required this.rawEventType,
    required this.stage,
    this.actorId,
    this.actorRole,
    this.meta = const {},
    required this.createdAt,
  });

  bool get isCompleted => stage == AssignmentStage.completed || stage == AssignmentStage.paymentReleased;

  factory AssignmentEventItem.fromJson(Map<String, dynamic> json) {
    final eventType = json['event_type'] as String? ?? 'requested';
    final metaData = json['meta'] is Map ? (json['meta'] as Map<String, dynamic>) : <String, dynamic>{};
    return AssignmentEventItem(
      id: json['id'] as String? ?? '',
      assignmentId: json['assignment_id'] as String? ?? '',
      rawEventType: eventType,
      stage: AssignmentStage.fromString(eventType),
      actorId: json['actor_id'] as String?,
      actorRole: metaData['actor_role'] as String?,
      meta: metaData,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'assignment_id': assignmentId,
        'event_type': rawEventType,
        'actor_id': actorId,
        'meta': meta,
        'created_at': createdAt.toIso8601String(),
      };
}
