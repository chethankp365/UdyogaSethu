import 'package:flutter/foundation.dart';

@immutable
class WorkerSkillItem {
  final String id;
  final String name;
  final String? categoryId;
  final String? categoryName;

  const WorkerSkillItem({
    required this.id,
    required this.name,
    this.categoryId,
    this.categoryName,
  });

  factory WorkerSkillItem.fromJson(Map<String, dynamic> json) {
    return WorkerSkillItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'General Skill',
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category_id': categoryId,
    'category_name': categoryName,
  };
}

@immutable
class NearbyWorker {
  final String userId;
  final String fullName;
  final String? avatarPath;
  final String headline;
  final String bio;
  final String seekerType;
  final int? hourlyRatePaise;
  final int? dailyRatePaise;
  final double ratingAvg;
  final int ratingCount;
  final int jobsCompleted;
  final bool isVerifiedBadge;
  final double? distanceM;
  final double? lat;
  final double? lng;
  final List<String> languages;
  final List<WorkerSkillItem> skills;
  final String availability;
  final String? gender;
  final double experienceYears;

  const NearbyWorker({
    required this.userId,
    required this.fullName,
    this.avatarPath,
    required this.headline,
    this.bio = '',
    this.seekerType = 'informal',
    this.hourlyRatePaise,
    this.dailyRatePaise,
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
    this.jobsCompleted = 0,
    this.isVerifiedBadge = false,
    this.distanceM,
    this.lat,
    this.lng,
    this.languages = const [],
    this.skills = const [],
    this.availability = 'available',
    this.gender,
    this.experienceYears = 0.0,
  });

  factory NearbyWorker.fromJson(Map<String, dynamic> json) {
    final rawSkills = json['skills'];
    final parsedSkills = <WorkerSkillItem>[];
    if (rawSkills is List) {
      for (final s in rawSkills) {
        if (s is Map<String, dynamic>) {
          parsedSkills.add(WorkerSkillItem.fromJson(s));
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

    return NearbyWorker(
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Worker',
      avatarPath: json['avatar_path'] as String?,
      headline: json['headline'] as String? ?? 'Skilled Worker',
      bio: json['bio'] as String? ?? '',
      seekerType: json['seeker_type'] as String? ?? 'informal',
      hourlyRatePaise: (json['hourly_rate_paise'] as num?)?.toInt(),
      dailyRatePaise: (json['daily_rate_paise'] as num?)?.toInt(),
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      jobsCompleted: (json['jobs_completed'] as num?)?.toInt() ?? 0,
      isVerifiedBadge: json['is_verified_badge'] == true,
      distanceM: (json['distance_m'] as num?)?.toDouble(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      languages: parsedLangs,
      skills: parsedSkills,
      availability: json['availability'] as String? ?? 'available',
      gender: json['gender'] as String?,
      experienceYears: (json['experience_years'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'full_name': fullName,
    'avatar_path': avatarPath,
    'headline': headline,
    'bio': bio,
    'seeker_type': seekerType,
    'hourly_rate_paise': hourlyRatePaise,
    'daily_rate_paise': dailyRatePaise,
    'rating_avg': ratingAvg,
    'rating_count': ratingCount,
    'jobs_completed': jobsCompleted,
    'is_verified_badge': isVerifiedBadge,
    'distance_m': distanceM,
    'lat': lat,
    'lng': lng,
    'languages': languages,
    'skills': skills.map((s) => s.toJson()).toList(),
    'availability': availability,
    'gender': gender,
    'experience_years': experienceYears,
  };

  String get formattedRate {
    if (dailyRatePaise != null && dailyRatePaise! > 0) {
      final rupees = (dailyRatePaise! / 100).round();
      return '₹$rupees/day';
    }
    if (hourlyRatePaise != null && hourlyRatePaise! > 0) {
      final rupees = (hourlyRatePaise! / 100).round();
      return '₹$rupees/hr';
    }
    return '₹750/day';
  }

  String get formattedDistance {
    if (distanceM == null) return 'Nearby';
    if (distanceM! < 1000) {
      return '${distanceM!.round()} m away';
    }
    final km = (distanceM! / 1000).toStringAsFixed(1);
    return '$km km away';
  }

  bool get isAvailable => availability != 'busy' && availability != 'offline';

  bool speaksLanguage(String lang) {
    if (lang.isEmpty || lang.toLowerCase() == 'all') return true;
    return languages.any((l) => l.toLowerCase() == lang.toLowerCase());
  }
}
