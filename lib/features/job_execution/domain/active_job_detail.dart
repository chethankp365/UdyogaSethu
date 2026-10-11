import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:udyogasethu/features/job_execution/domain/assignment_event_item.dart';

@immutable
class ActiveJobDetail {
  final String assignmentId;
  final String jobId;
  final String bookingCode;
  final String status;
  final AssignmentStage stage;
  final int agreedWagePaise;
  final bool protectionSelected;
  final DateTime? arrivedAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? elapsedSeconds;
  final String jobTitle;
  final String? jobDescription;
  final DateTime startAt;
  final int estDurationMinutes;
  final String addressText;
  final double jobLat;
  final double jobLng;
  final String categoryName;
  final String categorySlug;
  final String categoryIcon;
  final String providerId;
  final String providerName;
  final String? providerPhone;
  final String? providerAvatar;
  final bool providerVerified;
  final String workerId;
  final String workerName;
  final String? workerPhone;
  final String? workerAvatar;
  final bool workerVerified;
  final double? workerLat;
  final double? workerLng;
  final DateTime? midjobVerifiedAt;
  final bool paymentEligible;
  final int extendedGraceMinutes;
  final DateTime? lateNotifiedAt;
  final int? runningLateEtaMinutes;
  final DateTime? runningLateReportedAt;
  final bool noShowTimerPaused;
  final String? replacedBy;

  const ActiveJobDetail({
    required this.assignmentId,
    required this.jobId,
    required this.bookingCode,
    required this.status,
    required this.stage,
    required this.agreedWagePaise,
    this.protectionSelected = false,
    this.arrivedAt,
    this.startedAt,
    this.endedAt,
    this.elapsedSeconds,
    this.midjobVerifiedAt,
    this.paymentEligible = false,
    this.extendedGraceMinutes = 0,
    this.lateNotifiedAt,
    this.runningLateEtaMinutes,
    this.runningLateReportedAt,
    this.noShowTimerPaused = false,
    this.replacedBy,
    required this.jobTitle,
    this.jobDescription,
    required this.startAt,
    this.estDurationMinutes = 480,
    required this.addressText,
    required this.jobLat,
    required this.jobLng,
    this.categoryName = 'General Work',
    this.categorySlug = 'general',
    this.categoryIcon = 'handyman',
    required this.providerId,
    required this.providerName,
    this.providerPhone,
    this.providerAvatar,
    this.providerVerified = true,
    required this.workerId,
    required this.workerName,
    this.workerPhone,
    this.workerAvatar,
    this.workerVerified = true,
    this.workerLat,
    this.workerLng,
  });

  int get agreedWageRupees => agreedWagePaise ~/ 100;

  bool get hasValidJobCoordinates =>
      jobLat != 0.0 &&
      jobLng != 0.0 &&
      jobLat.abs() <= 90.0 &&
      jobLng.abs() <= 180.0;

  LatLng get jobLocation => LatLng(jobLat, jobLng);

  LatLng? get validJobLocation => hasValidJobCoordinates ? LatLng(jobLat, jobLng) : null;

  LatLng? get workerLocation =>
      (workerLat != null && workerLng != null && workerLat != 0.0 && workerLng != 0.0)
          ? LatLng(workerLat!, workerLng!)
          : null;

  String get durationDisplay {
    final hours = estDurationMinutes ~/ 60;
    final mins = estDurationMinutes % 60;
    if (mins == 0) return '$hours hrs';
    if (hours == 0) return '$mins mins';
    return '$hours h $mins m';
  }

  bool get isLate {
    if (status != 'ticket_issued' || arrivedAt != null) return false;
    final effectiveGrace = 15 + extendedGraceMinutes + (runningLateEtaMinutes ?? 0);
    final deadline = startAt.add(Duration(minutes: effectiveGrace));
    return DateTime.now().isAfter(deadline);
  }

  int get minutesPastScheduledArrival {
    final diff = DateTime.now().difference(startAt).inMinutes;
    return diff > 0 ? diff : 0;
  }

  factory ActiveJobDetail.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'requested';
    final id = json['assignment_id'] as String? ?? json['id'] as String? ?? '';
    final code = json['booking_code'] as String?;
    final resolvedCode = (code != null && code.isNotEmpty)
        ? code
        : (id.length >= 6 ? 'BOOK-${id.substring(0, 6).toUpperCase()}' : 'BOOK-PENDING');

    return ActiveJobDetail(
      assignmentId: id,
      jobId: json['job_id'] as String? ?? '',
      bookingCode: resolvedCode,
      status: statusStr,
      stage: AssignmentStage.fromString(statusStr),
      agreedWagePaise: (json['agreed_wage_paise'] as num?)?.toInt() ??
          (json['wage_amount_paise'] as num?)?.toInt() ??
          0,
      protectionSelected: json['protection_selected'] as bool? ?? false,
      arrivedAt: json['arrived_at'] != null ? DateTime.tryParse(json['arrived_at'].toString()) : null,
      startedAt: json['started_at'] != null ? DateTime.tryParse(json['started_at'].toString()) : null,
      endedAt: json['ended_at'] != null ? DateTime.tryParse(json['ended_at'].toString()) : null,
      elapsedSeconds: (json['elapsed_seconds'] as num?)?.toInt(),
      midjobVerifiedAt: json['midjob_verified_at'] != null
          ? DateTime.tryParse(json['midjob_verified_at'].toString())
          : null,
      paymentEligible: json['payment_eligible'] as bool? ?? false,
      extendedGraceMinutes: (json['extended_grace_minutes'] as num?)?.toInt() ?? 0,
      lateNotifiedAt: json['late_notified_at'] != null
          ? DateTime.tryParse(json['late_notified_at'].toString())
          : null,
      runningLateEtaMinutes: (json['running_late_eta_minutes'] as num?)?.toInt(),
      runningLateReportedAt: json['running_late_reported_at'] != null
          ? DateTime.tryParse(json['running_late_reported_at'].toString())
          : null,
      noShowTimerPaused: json['no_show_timer_paused'] as bool? ?? false,
      replacedBy: json['replaced_by'] as String?,
      jobTitle: json['job_title'] as String? ?? json['title'] as String? ?? '',
      jobDescription: json['job_description'] as String? ?? json['description'] as String?,
      startAt: json['start_at'] != null
          ? DateTime.tryParse(json['start_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      estDurationMinutes: (json['est_duration_minutes'] as num?)?.toInt() ?? 240,
      addressText: json['address_text'] as String? ?? '',
      jobLat: (json['job_lat'] as num?)?.toDouble() ?? (json['lat'] as num?)?.toDouble() ?? 0.0,
      jobLng: (json['job_lng'] as num?)?.toDouble() ?? (json['lng'] as num?)?.toDouble() ?? 0.0,
      categoryName: json['category_name'] as String? ?? '',
      categorySlug: json['category_slug'] as String? ?? '',
      categoryIcon: json['category_icon'] as String? ?? 'work',
      providerId: json['provider_id'] as String? ?? '',
      providerName: json['provider_name'] as String? ?? '',
      providerPhone: json['provider_phone'] as String?,
      providerAvatar: json['provider_avatar'] as String?,
      providerVerified: json['provider_verified'] as bool? ?? false,
      workerId: json['worker_id'] as String? ?? '',
      workerName: json['worker_name'] as String? ?? '',
      workerPhone: json['worker_phone'] as String?,
      workerAvatar: json['worker_avatar'] as String?,
      workerVerified: json['worker_verified'] as bool? ?? false,
      workerLat: (json['worker_lat'] as num?)?.toDouble(),
      workerLng: (json['worker_lng'] as num?)?.toDouble(),
    );
  }

  ActiveJobDetail copyWith({
    String? status,
    AssignmentStage? stage,
    DateTime? arrivedAt,
    DateTime? startedAt,
    DateTime? endedAt,
    int? elapsedSeconds,
    DateTime? midjobVerifiedAt,
    bool? paymentEligible,
    int? extendedGraceMinutes,
    DateTime? lateNotifiedAt,
    int? runningLateEtaMinutes,
    DateTime? runningLateReportedAt,
    bool? noShowTimerPaused,
    String? replacedBy,
  }) {
    final newStatus = status ?? this.status;
    return ActiveJobDetail(
      assignmentId: assignmentId,
      jobId: jobId,
      bookingCode: bookingCode,
      status: newStatus,
      stage: stage ?? AssignmentStage.fromString(newStatus),
      agreedWagePaise: agreedWagePaise,
      protectionSelected: protectionSelected,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      midjobVerifiedAt: midjobVerifiedAt ?? this.midjobVerifiedAt,
      paymentEligible: paymentEligible ?? this.paymentEligible,
      extendedGraceMinutes: extendedGraceMinutes ?? this.extendedGraceMinutes,
      lateNotifiedAt: lateNotifiedAt ?? this.lateNotifiedAt,
      runningLateEtaMinutes: runningLateEtaMinutes ?? this.runningLateEtaMinutes,
      runningLateReportedAt: runningLateReportedAt ?? this.runningLateReportedAt,
      noShowTimerPaused: noShowTimerPaused ?? this.noShowTimerPaused,
      replacedBy: replacedBy ?? this.replacedBy,
      jobTitle: jobTitle,
      jobDescription: jobDescription,
      startAt: startAt,
      estDurationMinutes: estDurationMinutes,
      addressText: addressText,
      jobLat: jobLat,
      jobLng: jobLng,
      categoryName: categoryName,
      categorySlug: categorySlug,
      categoryIcon: categoryIcon,
      providerId: providerId,
      providerName: providerName,
      providerPhone: providerPhone,
      providerAvatar: providerAvatar,
      providerVerified: providerVerified,
      workerId: workerId,
      workerName: workerName,
      workerPhone: workerPhone,
      workerAvatar: workerAvatar,
      workerVerified: workerVerified,
      workerLat: workerLat,
      workerLng: workerLng,
    );
  }
}
