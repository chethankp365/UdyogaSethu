import 'package:flutter/foundation.dart';
import 'package:udyogasethu/features/provider/domain/nearby_worker.dart';

@immutable
class TrustBadgeItem {
  final String code;
  final String title;
  final bool verified;
  final String? issuedAt;

  const TrustBadgeItem({
    required this.code,
    required this.title,
    required this.verified,
    this.issuedAt,
  });

  factory TrustBadgeItem.fromJson(Map<String, dynamic> json) {
    return TrustBadgeItem(
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? 'Trust Badge',
      verified: json['verified'] == true,
      issuedAt: json['issued_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'title': title,
    'verified': verified,
    'issued_at': issuedAt,
  };
}

@immutable
class WorkerReviewItem {
  final String id;
  final String raterName;
  final int stars;
  final String? comment;
  final String? createdAt;

  const WorkerReviewItem({
    required this.id,
    required this.raterName,
    required this.stars,
    this.comment,
    this.createdAt,
  });

  factory WorkerReviewItem.fromJson(Map<String, dynamic> json) {
    return WorkerReviewItem(
      id: json['id'] as String? ?? '',
      raterName: json['rater_name'] as String? ?? 'Verified Employer',
      stars: (json['stars'] as num?)?.toInt() ?? 5,
      comment: json['comment'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'rater_name': raterName,
    'stars': stars,
    'comment': comment,
    'created_at': createdAt,
  };
}

@immutable
class WorkerDetailProfile {
  final String userId;
  final String fullName;
  final String? phone;
  final String? avatarPath;
  final String headline;
  final String bio;
  final double experienceYears;
  final int? hourlyRatePaise;
  final int? dailyRatePaise;
  final List<String> languages;
  final double serviceRadiusKm;
  final String availability;
  final double ratingAvg;
  final int ratingCount;
  final int jobsCompleted;
  final bool isVerifiedBadge;
  final String? gender;
  final double? distanceM;
  final double? lat;
  final double? lng;
  final List<WorkerSkillItem> skills;
  final List<TrustBadgeItem> trustBadges;
  final List<WorkerReviewItem> reviews;
  final bool isFavourite;

  const WorkerDetailProfile({
    required this.userId,
    required this.fullName,
    this.phone,
    this.avatarPath,
    required this.headline,
    this.bio = '',
    this.experienceYears = 0.0,
    this.hourlyRatePaise,
    this.dailyRatePaise,
    this.languages = const [],
    this.serviceRadiusKm = 10.0,
    this.availability = 'available',
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
    this.jobsCompleted = 0,
    this.isVerifiedBadge = false,
    this.gender,
    this.distanceM,
    this.lat,
    this.lng,
    this.skills = const [],
    this.trustBadges = const [],
    this.reviews = const [],
    this.isFavourite = false,
  });

  factory WorkerDetailProfile.fromJson(Map<String, dynamic> json) {
    final rawSkills = json['skills'];
    final parsedSkills = <WorkerSkillItem>[];
    if (rawSkills is List) {
      for (final s in rawSkills) {
        if (s is Map<String, dynamic>) {
          parsedSkills.add(WorkerSkillItem.fromJson(s));
        }
      }
    }

    final rawBadges = json['trust_badges'];
    final parsedBadges = <TrustBadgeItem>[];
    if (rawBadges is List) {
      for (final b in rawBadges) {
        if (b is Map<String, dynamic>) {
          parsedBadges.add(TrustBadgeItem.fromJson(b));
        }
      }
    }

    final rawReviews = json['reviews'];
    final parsedReviews = <WorkerReviewItem>[];
    if (rawReviews is List) {
      for (final r in rawReviews) {
        if (r is Map<String, dynamic>) {
          parsedReviews.add(WorkerReviewItem.fromJson(r));
        }
      }
    }

    final rawLangs = json['languages'];
    final parsedLangs = <String>[];
    if (rawLangs is List) {
      for (final l in rawLangs) {
        if (l != null) parsedLangs.add(l.toString());
      }
    }

    return WorkerDetailProfile(
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Worker',
      phone: json['phone'] as String?,
      avatarPath: json['avatar_path'] as String?,
      headline: json['headline'] as String? ?? 'Skilled Worker',
      bio: json['bio'] as String? ?? '',
      experienceYears: (json['experience_years'] as num?)?.toDouble() ?? 0.0,
      hourlyRatePaise: (json['hourly_rate_paise'] as num?)?.toInt(),
      dailyRatePaise: (json['daily_rate_paise'] as num?)?.toInt(),
      languages: parsedLangs,
      serviceRadiusKm: (json['service_radius_km'] as num?)?.toDouble() ?? 10.0,
      availability: json['availability'] as String? ?? 'available',
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      jobsCompleted: (json['jobs_completed'] as num?)?.toInt() ?? 0,
      isVerifiedBadge: json['is_verified_badge'] == true,
      gender: json['gender'] as String?,
      distanceM: (json['distance_m'] as num?)?.toDouble(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      skills: parsedSkills,
      trustBadges: parsedBadges,
      reviews: parsedReviews,
      isFavourite: json['is_favourite'] == true,
    );
  }

  String get formattedDailyRate {
    if (dailyRatePaise != null && dailyRatePaise! > 0) {
      final rupees = (dailyRatePaise! / 100).round();
      return '₹$rupees/day';
    }
    return '₹880/day';
  }

  String get formattedHourlyRate {
    if (hourlyRatePaise != null && hourlyRatePaise! > 0) {
      final rupees = (hourlyRatePaise! / 100).round();
      return '₹$rupees/hr';
    }
    return '₹120/hr';
  }

  String get formattedDistance {
    if (distanceM == null) return 'Nearby';
    if (distanceM! < 1000) {
      return '${distanceM!.round()} m away';
    }
    final km = (distanceM! / 1000).toStringAsFixed(1);
    return '$km km away';
  }

  WorkerDetailProfile copyWith({
    bool? isFavourite,
  }) {
    return WorkerDetailProfile(
      userId: userId,
      fullName: fullName,
      phone: phone,
      avatarPath: avatarPath,
      headline: headline,
      bio: bio,
      experienceYears: experienceYears,
      hourlyRatePaise: hourlyRatePaise,
      dailyRatePaise: dailyRatePaise,
      languages: languages,
      serviceRadiusKm: serviceRadiusKm,
      availability: availability,
      ratingAvg: ratingAvg,
      ratingCount: ratingCount,
      jobsCompleted: jobsCompleted,
      isVerifiedBadge: isVerifiedBadge,
      gender: gender,
      distanceM: distanceM,
      lat: lat,
      lng: lng,
      skills: skills,
      trustBadges: trustBadges,
      reviews: reviews,
      isFavourite: isFavourite ?? this.isFavourite,
    );
  }
}
