/// Represents a saved favourite worker or farmer partner in user trust circles.
class FavouriteItem {
  final String targetId;
  final String fullName;
  final String? avatarPath;
  final String role;
  final String headline;
  final double ratingAvg;
  final int ratingCount;
  final int jobsCompleted;
  final bool isVerified;
  final int dailyRatePaise;
  final List<String> skills;
  final DateTime favouritedAt;

  const FavouriteItem({
    required this.targetId,
    required this.fullName,
    this.avatarPath,
    required this.role,
    required this.headline,
    required this.ratingAvg,
    required this.ratingCount,
    required this.jobsCompleted,
    required this.isVerified,
    required this.dailyRatePaise,
    this.skills = const [],
    required this.favouritedAt,
  });

  int get dailyRateRupees => dailyRatePaise ~/ 100;

  factory FavouriteItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = json['favourited_at'] != null
          ? DateTime.parse(json['favourited_at'].toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    List<String> parsedSkills = [];
    final rawSkills = json['skills'];
    if (rawSkills is List) {
      for (final s in rawSkills) {
        if (s is Map && s['name'] != null) {
          parsedSkills.add(s['name'].toString());
        } else if (s is String) {
          parsedSkills.add(s);
        }
      }
    }

    return FavouriteItem(
      targetId: json['target_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'Partner',
      avatarPath: json['avatar_path']?.toString(),
      role: json['role']?.toString() ?? 'seeker',
      headline: json['headline']?.toString() ?? 'Verified Partner',
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 4.8,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 12,
      jobsCompleted: (json['jobs_completed'] as num?)?.toInt() ?? 10,
      isVerified: json['is_verified'] == true,
      dailyRatePaise: (json['daily_rate_paise'] as num?)?.toInt() ?? 0,
      skills: parsedSkills,
      favouritedAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'target_id': targetId,
      'full_name': fullName,
      'avatar_path': avatarPath,
      'role': role,
      'headline': headline,
      'rating_avg': ratingAvg,
      'rating_count': ratingCount,
      'jobs_completed': jobsCompleted,
      'is_verified': isVerified,
      'daily_rate_paise': dailyRatePaise,
      'skills': skills,
      'favourited_at': favouritedAt.toIso8601String(),
    };
  }
}
