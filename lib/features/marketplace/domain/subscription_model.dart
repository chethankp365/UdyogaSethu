import 'package:flutter/foundation.dart';

enum SubscriptionFrequency {
  daily,
  weekdays,
  weekly;

  String toDb() => name;

  static SubscriptionFrequency fromDb(String? val) {
    switch (val?.toLowerCase()) {
      case 'weekdays':
        return SubscriptionFrequency.weekdays;
      case 'weekly':
        return SubscriptionFrequency.weekly;
      case 'daily':
      default:
        return SubscriptionFrequency.daily;
    }
  }

  String get label {
    switch (this) {
      case SubscriptionFrequency.daily:
        return 'Daily';
      case SubscriptionFrequency.weekdays:
        return 'Weekdays (Mon-Fri)';
      case SubscriptionFrequency.weekly:
        return 'Weekly';
    }
  }
}

enum SubscriptionStatus {
  active,
  paused,
  cancelled;

  String toDb() => name;

  static SubscriptionStatus fromDb(String? val) {
    switch (val?.toLowerCase()) {
      case 'paused':
        return SubscriptionStatus.paused;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      case 'active':
      default:
        return SubscriptionStatus.active;
    }
  }
}

@immutable
class ProduceSubscription {
  final String id;
  final String customerId;
  final String farmerId;
  final String listingId;
  final double quantity;
  final SubscriptionFrequency frequency;
  final SubscriptionStatus status;
  final DateTime? nextDeliveryDate;
  final List<DateTime> skipDates;
  final String deliverySlotTime;
  final String? doorstepAddress;
  final int unitPricePaise;
  final String listingName;
  final String farmerName;
  final DateTime createdAt;

  const ProduceSubscription({
    required this.id,
    required this.customerId,
    required this.farmerId,
    required this.listingId,
    required this.quantity,
    required this.frequency,
    required this.status,
    this.nextDeliveryDate,
    this.skipDates = const [],
    this.deliverySlotTime = '07:00 AM',
    this.doorstepAddress,
    required this.unitPricePaise,
    required this.listingName,
    required this.farmerName,
    required this.createdAt,
  });

  bool isSkipped(DateTime date) {
    final y = date.year;
    final m = date.month;
    final d = date.day;
    return skipDates.any((s) => s.year == y && s.month == m && s.day == d);
  }

  factory ProduceSubscription.fromJson(Map<String, dynamic> json) {
    List<DateTime> parsedSkipDates = [];
    if (json['skip_dates'] is List) {
      for (final item in json['skip_dates'] as List) {
        if (item != null) {
          final dt = DateTime.tryParse(item.toString());
          if (dt != null) parsedSkipDates.add(dt);
        }
      }
    }

    return ProduceSubscription(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      farmerId: json['farmer_id']?.toString() ?? '',
      listingId: json['listing_id']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      frequency: SubscriptionFrequency.fromDb(json['frequency']?.toString()),
      status: SubscriptionStatus.fromDb(json['status']?.toString()),
      nextDeliveryDate: json['next_delivery_date'] != null
          ? DateTime.tryParse(json['next_delivery_date'].toString())
          : null,
      skipDates: parsedSkipDates,
      deliverySlotTime: json['delivery_slot_time']?.toString() ?? '07:00 AM',
      doorstepAddress: json['doorstep_address']?.toString(),
      unitPricePaise: (json['unit_price_paise'] as num?)?.toInt() ?? 0,
      listingName: json['listing_name']?.toString() ?? 'Produce Subscription',
      farmerName: json['farmer_name']?.toString() ?? 'Verified Local Farmer',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'farmer_id': farmerId,
        'listing_id': listingId,
        'quantity': quantity,
        'frequency': frequency.toDb(),
        'status': status.toDb(),
        'next_delivery_date': nextDeliveryDate?.toIso8601String().split('T').first,
        'skip_dates': skipDates.map((d) => d.toIso8601String().split('T').first).toList(),
        'delivery_slot_time': deliverySlotTime,
        'doorstep_address': doorstepAddress,
        'unit_price_paise': unitPricePaise,
        'listing_name': listingName,
        'farmer_name': farmerName,
        'created_at': createdAt.toIso8601String(),
      };
}
