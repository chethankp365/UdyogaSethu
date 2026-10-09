import 'package:udyogasethu/features/trust/domain/dispute.dart';
import 'package:udyogasethu/features/trust/domain/job_review.dart';

/// Represents a past job booking in Job History & Ratings (Screen 37).
class JobHistoryItem {
  final String assignmentId;
  final String jobId;
  final String title;
  final String? description;
  final int wagePaise;
  final int agreedWagePaise;
  final String status;
  final DateTime? startTime;
  final DateTime? completedAt;
  final DateTime createdAt;
  final String categorySlug;
  final String categoryName;
  final String area;

  // Counterparty
  final String counterpartyId;
  final String counterpartyName;
  final String? counterpartyAvatar;
  final String counterpartyRole;
  final bool counterpartyVerified;

  // State flags
  final bool isFavourite;
  final JobReview? userReview;
  final JobReview? counterpartyReview;
  final DisputeRecord? dispute;

  final bool canReview;
  final bool canDispute;
  final bool canRebook;

  const JobHistoryItem({
    required this.assignmentId,
    required this.jobId,
    required this.title,
    this.description,
    required this.wagePaise,
    required this.agreedWagePaise,
    required this.status,
    this.startTime,
    this.completedAt,
    required this.createdAt,
    required this.categorySlug,
    required this.categoryName,
    required this.area,
    required this.counterpartyId,
    required this.counterpartyName,
    this.counterpartyAvatar,
    required this.counterpartyRole,
    required this.counterpartyVerified,
    required this.isFavourite,
    this.userReview,
    this.counterpartyReview,
    this.dispute,
    required this.canReview,
    required this.canDispute,
    required this.canRebook,
  });

  int get amountRupees {
    final paise = agreedWagePaise > 0 ? agreedWagePaise : wagePaise;
    return paise ~/ 100;
  }

  /// Calculates human-readable time ago string (e.g., '2d ago', '1w ago').
  String get timeAgo {
    final refDate = completedAt ?? startTime ?? createdAt;
    final diff = DateTime.now().difference(refDate);

    if (diff.inDays >= 30) {
      final months = (diff.inDays / 30).floor();
      return '$months${months == 1 ? 'm' : 'mo'} ago';
    } else if (diff.inDays >= 7) {
      final weeks = (diff.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (diff.inDays >= 1) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m ago';
    }
    return 'Just now';
  }

  /// Stars for display (user's review stars or counterparty rating or default).
  int get displayStars {
    if (userReview != null) return userReview!.stars;
    if (counterpartyReview != null) return counterpartyReview!.stars;
    return 5;
  }

  bool get isDisputed => status == 'disputed' || dispute != null;
  bool get isCompleted => status == 'completed' || status == 'payment_released';

  factory JobHistoryItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    JobReview? uRev;
    if (json['user_review'] is Map<String, dynamic>) {
      uRev = JobReview.fromJson(json['user_review'] as Map<String, dynamic>);
    }

    JobReview? cpRev;
    if (json['counterparty_review'] is Map<String, dynamic>) {
      cpRev = JobReview.fromJson(json['counterparty_review'] as Map<String, dynamic>);
    }

    DisputeRecord? disp;
    if (json['dispute'] is Map<String, dynamic>) {
      disp = DisputeRecord.fromJson(json['dispute'] as Map<String, dynamic>);
    }

    return JobHistoryItem(
      assignmentId: json['assignment_id']?.toString() ?? '',
      jobId: json['job_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Job',
      description: json['description']?.toString(),
      wagePaise: (json['wage_paise'] as num?)?.toInt() ?? 60000,
      agreedWagePaise: (json['agreed_wage_paise'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'completed',
      startTime: parseDate(json['start_time']),
      completedAt: parseDate(json['completed_at']),
      createdAt: parseDate(json['created_at']) ?? DateTime.now(),
      categorySlug: json['category_slug']?.toString() ?? 'general',
      categoryName: json['category_name']?.toString() ?? 'General',
      area: json['area']?.toString() ?? 'Bengaluru',
      counterpartyId: json['counterparty_id']?.toString() ?? '',
      counterpartyName: json['counterparty_name']?.toString() ?? 'Partner',
      counterpartyAvatar: json['counterparty_avatar']?.toString(),
      counterpartyRole: json['counterparty_role']?.toString() ?? 'worker',
      counterpartyVerified: json['counterparty_verified'] == true,
      isFavourite: json['is_favourite'] == true,
      userReview: uRev,
      counterpartyReview: cpRev,
      dispute: disp,
      canReview: json['can_review'] == true,
      canDispute: json['can_dispute'] == true,
      canRebook: json['can_rebook'] == true,
    );
  }
}
