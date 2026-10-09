/// Represents a rating and review submitted for a completed job assignment.
class JobReview {
  final String id;
  final String? refType;
  final String? refId;
  final String? raterId;
  final String? targetId;
  final int stars;
  final List<String> tags;
  final String? comment;
  final DateTime createdAt;
  final String? raterName;
  final String? raterAvatar;
  final String? raterRole;
  final String? jobTitle;

  const JobReview({
    required this.id,
    this.refType,
    this.refId,
    this.raterId,
    this.targetId,
    required this.stars,
    this.tags = const [],
    this.comment,
    required this.createdAt,
    this.raterName,
    this.raterAvatar,
    this.raterRole,
    this.jobTitle,
  });

  factory JobReview.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    List<String> parsedTags = [];
    final rawTags = json['tags'];
    if (rawTags is List) {
      parsedTags = rawTags.map((e) => e.toString()).toList();
    }

    return JobReview(
      id: json['id']?.toString() ?? '',
      refType: json['ref_type']?.toString(),
      refId: json['ref_id']?.toString(),
      raterId: json['rater_id']?.toString(),
      targetId: json['target_id']?.toString(),
      stars: (json['stars'] as num?)?.toInt() ?? 5,
      tags: parsedTags,
      comment: json['comment']?.toString(),
      createdAt: parsedDate,
      raterName: json['rater_name']?.toString(),
      raterAvatar: json['rater_avatar']?.toString(),
      raterRole: json['rater_role']?.toString(),
      jobTitle: json['job_title']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ref_type': refType,
      'ref_id': refId,
      'rater_id': raterId,
      'target_id': targetId,
      'stars': stars,
      'tags': tags,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'rater_name': raterName,
      'rater_avatar': raterAvatar,
      'rater_role': raterRole,
      'job_title': jobTitle,
    };
  }
}

/// Standard quick tags available for post-completion review.
class ReviewQuickTag {
  final String id;
  final String defaultLabel;
  final String icon;

  const ReviewQuickTag({
    required this.id,
    required this.defaultLabel,
    required this.icon,
  });

  static const List<ReviewQuickTag> defaultTags = [
    ReviewQuickTag(id: 'on_time', defaultLabel: 'On Time', icon: '⏱️'),
    ReviewQuickTag(id: 'professional', defaultLabel: 'Professional', icon: '💼'),
    ReviewQuickTag(id: 'good_quality', defaultLabel: 'Good Quality', icon: '⭐'),
    ReviewQuickTag(id: 'fresh_produce', defaultLabel: 'Fresh Produce', icon: '🌾'),
    ReviewQuickTag(id: 'safe_polite', defaultLabel: 'Safe & Polite', icon: '🛡️'),
    ReviewQuickTag(id: 'skilled_quick', defaultLabel: 'Skilled & Quick', icon: '⚡'),
    ReviewQuickTag(id: 'fair_price', defaultLabel: 'Fair Price', icon: '💰'),
    ReviewQuickTag(id: 'recommended', defaultLabel: 'Highly Recommended', icon: '👍'),
  ];
}
