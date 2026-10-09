import 'package:flutter/foundation.dart';

@immutable
class ReplacementCandidate {
  final String workerId;
  final String fullName;
  final String? avatarUrl;
  final double rating;
  final double distanceMeters;
  final int jobsCompleted;
  final bool isVerified;
  final List<String> skills;

  const ReplacementCandidate({
    required this.workerId,
    required this.fullName,
    this.avatarUrl,
    required this.rating,
    required this.distanceMeters,
    required this.jobsCompleted,
    required this.isVerified,
    required this.skills,
  });

  String get distanceKmDisplay =>
      '${(distanceMeters / 1000).toStringAsFixed(1)} km away';

  factory ReplacementCandidate.fromJson(Map<String, dynamic> json) {
    return ReplacementCandidate(
      workerId: json['worker_id'] as String? ?? json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Verified Worker',
      avatarUrl: json['avatar_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 1000.0,
      jobsCompleted: (json['jobs_completed'] as num?)?.toInt() ?? 12,
      isVerified: json['is_verified'] as bool? ?? false,
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'worker_id': workerId,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'rating': rating,
        'distance_meters': distanceMeters,
        'jobs_completed': jobsCompleted,
        'is_verified': isVerified,
        'skills': skills,
      };
}
