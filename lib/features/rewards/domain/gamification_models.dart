import 'package:flutter/foundation.dart';

@immutable
class UserLevel {
  final int levelNumber;
  final String name;
  final int minXp;
  final Map<String, dynamic> perks;

  const UserLevel({
    required this.levelNumber,
    required this.name,
    required this.minXp,
    this.perks = const {},
  });

  int get commissionBps => (perks['commission_bps'] as num?)?.toInt() ?? 500;
  double get commissionPercent => commissionBps / 100.0;
  double get searchBoost => (perks['search_boost'] as num?)?.toDouble() ?? 1.0;
  bool get hasPrioritySupport => perks['priority_support'] == true;
  bool get hasPremiumJobs => perks['premium_jobs'] == true;
  String get badgeTitle => (perks['badge_title'] as String?) ?? name;

  factory UserLevel.fromJson(Map<String, dynamic> json) {
    return UserLevel(
      levelNumber: (json['level_number'] as num?)?.toInt() ?? 1,
      name: (json['name'] as String?) ?? 'Starter',
      minXp: (json['min_xp'] as num?)?.toInt() ?? 0,
      perks: (json['perks'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'level_number': levelNumber,
        'name': name,
        'min_xp': minXp,
        'perks': perks,
      };
}

@immutable
class BadgeItem {
  final String id;
  final String slug;
  final Map<String, dynamic> names;
  final Map<String, dynamic> criteria;
  final bool isEarned;
  final DateTime? awardedAt;

  const BadgeItem({
    required this.id,
    required this.slug,
    required this.names,
    this.criteria = const {},
    this.isEarned = false,
    this.awardedAt,
  });

  String getName(String localeCode) {
    if (names.containsKey(localeCode)) {
      return names[localeCode].toString();
    }
    return names['en']?.toString() ?? slug;
  }

  String get criteriaDescription {
    return criteria['description']?.toString() ?? '';
  }

  factory BadgeItem.fromJson(Map<String, dynamic> json) {
    return BadgeItem(
      id: (json['id'] as String?) ?? '',
      slug: (json['slug'] as String?) ?? '',
      names: (json['names'] as Map<String, dynamic>?) ?? {},
      criteria: (json['criteria'] as Map<String, dynamic>?) ?? {},
      isEarned: (json['is_earned'] as bool?) ?? false,
      awardedAt: json['awarded_at'] != null
          ? DateTime.tryParse(json['awarded_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'names': names,
        'criteria': criteria,
        'is_earned': isEarned,
        'awarded_at': awardedAt?.toIso8601String(),
      };
}

@immutable
class StreakItem {
  final String? id;
  final String kind;
  final int current;
  final int best;
  final DateTime? lastDate;
  final bool isAtRisk;

  const StreakItem({
    this.id,
    required this.kind,
    required this.current,
    required this.best,
    this.lastDate,
    this.isAtRisk = false,
  });

  factory StreakItem.fromJson(Map<String, dynamic> json) {
    return StreakItem(
      id: json['id'] as String?,
      kind: (json['kind'] as String?) ?? 'daily_activity',
      current: (json['current'] as num?)?.toInt() ?? 0,
      best: (json['best'] as num?)?.toInt() ?? 0,
      lastDate: json['last_date'] != null
          ? DateTime.tryParse(json['last_date'].toString())
          : null,
      isAtRisk: (json['at_risk'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'current': current,
        'best': best,
        'last_date': lastDate?.toIso8601String(),
        'at_risk': isAtRisk,
      };
}

@immutable
class UserGamificationProfile {
  final String userId;
  final int totalXp;
  final int spentPoints;
  final int availablePoints;
  final UserLevel currentLevel;
  final UserLevel? nextLevel;
  final double progressPercent;
  final List<BadgeItem> badges;
  final List<StreakItem> streaks;
  final String? referralCode;
  final int successfulReferrals;

  const UserGamificationProfile({
    required this.userId,
    required this.totalXp,
    required this.spentPoints,
    required this.availablePoints,
    required this.currentLevel,
    this.nextLevel,
    required this.progressPercent,
    required this.badges,
    required this.streaks,
    this.referralCode,
    required this.successfulReferrals,
  });

  factory UserGamificationProfile.fromJson(Map<String, dynamic> json) {
    final badgesList = (json['badges'] as List<dynamic>?)
            ?.map((b) => BadgeItem.fromJson(b as Map<String, dynamic>))
            .toList() ??
        [];
    final streaksList = (json['streaks'] as List<dynamic>?)
            ?.map((s) => StreakItem.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];

    return UserGamificationProfile(
      userId: (json['user_id'] as String?) ?? '',
      totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
      spentPoints: (json['spent_points'] as num?)?.toInt() ?? 0,
      availablePoints: (json['available_points'] as num?)?.toInt() ?? 0,
      currentLevel: json['current_level'] != null
          ? UserLevel.fromJson(json['current_level'] as Map<String, dynamic>)
          : const UserLevel(levelNumber: 1, name: 'Starter', minXp: 0),
      nextLevel: json['next_level'] != null
          ? UserLevel.fromJson(json['next_level'] as Map<String, dynamic>)
          : null,
      progressPercent:
          (json['progress_percent'] as num?)?.toDouble() ?? 0.0,
      badges: badgesList,
      streaks: streaksList,
      referralCode: json['referral_code'] as String?,
      successfulReferrals:
          (json['successful_referrals'] as num?)?.toInt() ?? 0,
    );
  }

  factory UserGamificationProfile.initial() {
    return const UserGamificationProfile(
      userId: '',
      totalXp: 0,
      spentPoints: 0,
      availablePoints: 0,
      currentLevel: UserLevel(levelNumber: 1, name: 'Starter', minXp: 0),
      nextLevel: UserLevel(levelNumber: 2, name: 'Reliable', minXp: 200),
      progressPercent: 0.0,
      badges: [],
      streaks: [],
      referralCode: null,
      successfulReferrals: 0,
    );
  }
}

enum RewardItemState { available, locked, outOfStock }

@immutable
class RewardStoreItem {
  final String id;
  final Map<String, dynamic> names;
  final int pointsCost;
  final int minLevel;
  final String? requiredBadgeId;
  final int stock;
  final String? image;
  final bool active;

  const RewardStoreItem({
    required this.id,
    required this.names,
    required this.pointsCost,
    required this.minLevel,
    this.requiredBadgeId,
    required this.stock,
    this.image,
    this.active = true,
  });

  String getName(String localeCode) {
    if (names.containsKey(localeCode)) {
      return names[localeCode].toString();
    }
    return names['en']?.toString() ?? 'Reward Item';
  }

  RewardItemState getState({
    required int userPoints,
    required int userLevel,
    required bool hasRequiredBadge,
  }) {
    if (stock <= 0) return RewardItemState.outOfStock;
    if (userLevel < minLevel || (requiredBadgeId != null && !hasRequiredBadge)) {
      return RewardItemState.locked;
    }
    return RewardItemState.available;
  }

  factory RewardStoreItem.fromJson(Map<String, dynamic> json) {
    return RewardStoreItem(
      id: (json['id'] as String?) ?? '',
      names: (json['names'] as Map<String, dynamic>?) ?? {},
      pointsCost: (json['points_cost'] as num?)?.toInt() ?? 0,
      minLevel: (json['min_level'] as num?)?.toInt() ?? 1,
      requiredBadgeId: json['required_badge_id'] as String?,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      image: json['image'] as String?,
      active: (json['active'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'names': names,
        'points_cost': pointsCost,
        'min_level': minLevel,
        'required_badge_id': requiredBadgeId,
        'stock': stock,
        'image': image,
        'active': active,
      };
}

@immutable
class RewardRedemption {
  final String id;
  final String userId;
  final String itemId;
  final int pointsSpent;
  final String status; // 'requested', 'approved', 'shipped', 'delivered', 'cancelled'
  final Map<String, dynamic> shippingAddress;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final RewardStoreItem? item;

  const RewardRedemption({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.pointsSpent,
    required this.status,
    required this.shippingAddress,
    required this.createdAt,
    this.updatedAt,
    this.item,
  });

  factory RewardRedemption.fromJson(Map<String, dynamic> json) {
    return RewardRedemption(
      id: (json['id'] as String?) ?? '',
      userId: (json['user_id'] as String?) ?? '',
      itemId: (json['item_id'] as String?) ?? '',
      pointsSpent: (json['points_spent'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? 'requested',
      shippingAddress:
          (json['shipping_address'] as Map<String, dynamic>?) ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      item: json['reward_items'] != null
          ? RewardStoreItem.fromJson(
              json['reward_items'] as Map<String, dynamic>)
          : null,
    );
  }
}
