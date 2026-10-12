import 'package:flutter/foundation.dart';

@immutable
class GroupPriceTier {
  final double minQty;
  final int pricePaise;

  const GroupPriceTier({
    required this.minQty,
    required this.pricePaise,
  });

  factory GroupPriceTier.fromJson(Map<String, dynamic> json) {
    return GroupPriceTier(
      minQty: (json['min_qty'] as num?)?.toDouble() ?? 0.0,
      pricePaise: (json['price_paise'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'min_qty': minQty,
        'price_paise': pricePaise,
      };
}

enum GroupOrderStatus {
  open,
  targetMet,
  closed,
  cancelled;

  String toDb() {
    switch (this) {
      case GroupOrderStatus.targetMet:
        return 'target_met';
      case GroupOrderStatus.open:
        return 'open';
      case GroupOrderStatus.closed:
        return 'closed';
      case GroupOrderStatus.cancelled:
        return 'cancelled';
    }
  }

  static GroupOrderStatus fromDb(String? val) {
    switch (val?.toLowerCase()) {
      case 'target_met':
        return GroupOrderStatus.targetMet;
      case 'closed':
        return GroupOrderStatus.closed;
      case 'cancelled':
        return GroupOrderStatus.cancelled;
      case 'open':
      default:
        return GroupOrderStatus.open;
    }
  }
}

@immutable
class GroupOrder {
  final String id;
  final String organizerId;
  final String organizerName;
  final String listingId;
  final String listingName;
  final String produceCategory;
  final String communityName;
  final double targetQty;
  final double currentQty;
  final List<GroupPriceTier> priceTiers;
  final DateTime deadline;
  final GroupOrderStatus status;
  final int effectivePricePaise;
  final int memberCount;
  final bool hasJoined;
  final double userQty;
  final bool paid;
  final DateTime createdAt;

  const GroupOrder({
    required this.id,
    required this.organizerId,
    required this.organizerName,
    required this.listingId,
    required this.listingName,
    required this.produceCategory,
    required this.communityName,
    required this.targetQty,
    required this.currentQty,
    required this.priceTiers,
    required this.deadline,
    required this.status,
    required this.effectivePricePaise,
    required this.memberCount,
    required this.hasJoined,
    required this.userQty,
    required this.paid,
    required this.createdAt,
  });

  double get progressPercentage {
    if (targetQty <= 0) return 1.0;
    return (currentQty / targetQty).clamp(0.0, 1.0);
  }

  bool get isTargetReached => currentQty >= targetQty;

  bool get isExpired => DateTime.now().isAfter(deadline);

  GroupPriceTier? get nextTier {
    for (final tier in priceTiers) {
      if (tier.minQty > currentQty) {
        return tier;
      }
    }
    return null;
  }

  factory GroupOrder.fromJson(Map<String, dynamic> json) {
    List<GroupPriceTier> parsedTiers = [];
    if (json['price_tiers'] is List) {
      for (final item in json['price_tiers'] as List) {
        if (item is Map<String, dynamic>) {
          parsedTiers.add(GroupPriceTier.fromJson(item));
        }
      }
    }
    parsedTiers.sort((a, b) => a.minQty.compareTo(b.minQty));

    return GroupOrder(
      id: json['id']?.toString() ?? '',
      organizerId: json['organizer_id']?.toString() ?? '',
      organizerName: json['organizer_name']?.toString() ?? 'Community Organiser',
      listingId: json['listing_id']?.toString() ?? '',
      listingName: json['listing_name']?.toString() ?? 'Fresh Farm Produce',
      produceCategory: json['produce_category']?.toString() ?? 'organic',
      communityName: json['community_name']?.toString() ?? 'Apartment Community',
      targetQty: (json['target_qty'] as num?)?.toDouble() ?? 10.0,
      currentQty: (json['current_qty'] as num?)?.toDouble() ?? 0.0,
      priceTiers: parsedTiers,
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'].toString()) ?? DateTime.now().add(const Duration(days: 2))
          : DateTime.now().add(const Duration(days: 2)),
      status: GroupOrderStatus.fromDb(json['status']?.toString()),
      effectivePricePaise: (json['effective_price_paise'] as num?)?.toInt() ?? 0,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      hasJoined: json['has_joined'] == true,
      userQty: (json['user_qty'] as num?)?.toDouble() ?? 0.0,
      paid: json['paid'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
