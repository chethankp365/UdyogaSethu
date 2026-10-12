import 'package:flutter/foundation.dart';

@immutable
class JobApplicant {
  final String applicationId;
  final String jobId;
  final String workerId;
  final String status; // 'applied', 'shortlisted', 'hired', 'rejected'
  final String? message;
  final DateTime createdAt;
  final String workerName;
  final String? workerAvatar;
  final String seekerType;
  final String badgeName;
  final int levelNumber;
  final bool isVerified;
  final double rating;
  final int reviewCount;
  final int jobsCompletedCount;
  final double distanceM;
  final String? assignmentId;
  final List<String> languages;
  final List<String> skills;

  const JobApplicant({
    required this.applicationId,
    required this.jobId,
    required this.workerId,
    required this.status,
    this.message,
    required this.createdAt,
    required this.workerName,
    this.workerAvatar,
    this.seekerType = 'informal',
    this.badgeName = 'Registered Worker',
    this.levelNumber = 1,
    this.isVerified = false,
    this.rating = 4.8,
    this.reviewCount = 0,
    this.jobsCompletedCount = 0,
    this.distanceM = 800.0,
    this.assignmentId,
    this.languages = const ['kn'],
    this.skills = const [],
  });

  bool get isHired =>
      status == 'hired' ||
      status == 'accepted' ||
      status == 'ticket_issued' ||
      status == 'arrived' ||
      status == 'in_progress_verified' ||
      status == 'completed' ||
      (assignmentId != null && assignmentId!.isNotEmpty);

  bool get isShortlisted => status == 'shortlisted';
  bool get isRejected => status == 'rejected' || status == 'declined';
  bool get isPending => !isHired && !isShortlisted && !isRejected;

  String get formattedDistance {
    if (distanceM < 1000) {
      return '${distanceM.round()} m away';
    }
    return '${(distanceM / 1000).toStringAsFixed(1)} km away';
  }

  factory JobApplicant.fromJson(Map<String, dynamic> json) {
    return JobApplicant(
      applicationId: json['application_id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      workerId: json['worker_id'] as String? ?? '',
      status: json['status'] as String? ?? 'applied',
      message: json['message'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      workerName: (json['worker_name'] as String?)?.trim().isNotEmpty == true
          ? (json['worker_name'] as String).trim()
          : 'Name not set',
      workerAvatar: json['worker_avatar'] as String?,
      seekerType: json['seeker_type'] as String? ?? 'informal',
      badgeName: json['badge_name'] as String? ?? 'Registered Worker',
      levelNumber: (json['level_number'] as num?)?.toInt() ?? 1,
      isVerified: json['is_verified'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      jobsCompletedCount: (json['jobs_completed_count'] as num?)?.toInt() ?? 0,
      distanceM: (json['distance_m'] as num?)?.toDouble() ?? 800.0,
      assignmentId: json['assignment_id']?.toString(),
      languages: json['languages'] is List
          ? (json['languages'] as List).map((e) => e.toString()).toList()
          : const ['kn'],
      skills: json['skills'] is List
          ? (json['skills'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'application_id': applicationId,
      'job_id': jobId,
      'worker_id': workerId,
      'status': status,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'worker_name': workerName,
      'worker_avatar': workerAvatar,
      'seeker_type': seekerType,
      'badge_name': badgeName,
      'level_number': levelNumber,
      'is_verified': isVerified,
      'rating': rating,
      'review_count': reviewCount,
      'jobs_completed_count': jobsCompletedCount,
      'distance_m': distanceM,
      'assignment_id': assignmentId,
      'languages': languages,
      'skills': skills,
    };
  }

  JobApplicant copyWith({
    String? status,
    String? assignmentId,
  }) {
    return JobApplicant(
      applicationId: applicationId,
      jobId: jobId,
      workerId: workerId,
      status: status ?? this.status,
      message: message,
      createdAt: createdAt,
      workerName: workerName,
      workerAvatar: workerAvatar,
      seekerType: seekerType,
      badgeName: badgeName,
      levelNumber: levelNumber,
      isVerified: isVerified,
      rating: rating,
      reviewCount: reviewCount,
      jobsCompletedCount: jobsCompletedCount,
      distanceM: distanceM,
      assignmentId: assignmentId ?? this.assignmentId,
      languages: languages,
      skills: skills,
    );
  }
}
