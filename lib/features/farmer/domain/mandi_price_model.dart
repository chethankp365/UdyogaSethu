import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum CropCategoryTab {
  allCrops,
  vegetables,
  fruits,
  grainsAndPulses,
  spices,
  flowers;

  String get label {
    switch (this) {
      case CropCategoryTab.allCrops:
        return 'All Crops';
      case CropCategoryTab.vegetables:
        return 'Vegetables';
      case CropCategoryTab.fruits:
        return 'Fruits';
      case CropCategoryTab.grainsAndPulses:
        return 'Grains & Pulses';
      case CropCategoryTab.spices:
        return 'Spices';
      case CropCategoryTab.flowers:
        return 'Flowers';
    }
  }

  String get emoji {
    switch (this) {
      case CropCategoryTab.allCrops:
        return '🧺';
      case CropCategoryTab.vegetables:
        return '🥦';
      case CropCategoryTab.fruits:
        return '🍎';
      case CropCategoryTab.grainsAndPulses:
        return '🌾';
      case CropCategoryTab.spices:
        return '🌶️';
      case CropCategoryTab.flowers:
        return '🌸';
    }
  }
}

@immutable
class MandiPrice {
  final String id;
  final String state;
  final String district;
  final String market;
  final String commodity;
  final String variety;
  final DateTime arrivalDate;
  final double minPrice;
  final double maxPrice;
  final double modalPrice;
  final double pricePerKg;
  final double changePercent;
  final String demandTag;
  final String trendDirection; // 'up', 'down', 'stable'
  final DateTime updatedAt;

  const MandiPrice({
    required this.id,
    required this.state,
    required this.district,
    required this.market,
    required this.commodity,
    required this.variety,
    required this.arrivalDate,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
    required this.pricePerKg,
    required this.changePercent,
    required this.demandTag,
    required this.trendDirection,
    required this.updatedAt,
  });

  String get formattedModalPricePerQtl => '₹${NumberFormat('#,##,##0').format(modalPrice.round())}/qtl';
  String get formattedPricePerKg => '₹${NumberFormat('#,##,##0').format(pricePerKg.round())}/kg';

  String get formattedChange {
    if (changePercent > 0) return '+${changePercent.toStringAsFixed(0)}%';
    if (changePercent < 0) return '${changePercent.toStringAsFixed(0)}%';
    return '0%';
  }

  bool get isStale {
    final now = DateTime.now();
    final diffDays = now.difference(arrivalDate).inDays;
    return diffDays > 1;
  }

  String get formattedArrivalDate => DateFormat('d MMM yyyy').format(arrivalDate);

  CropCategoryTab get category {
    final lower = commodity.toLowerCase();
    // Flowers
    if (lower.contains('marigold') ||
        lower.contains('rose') ||
        lower.contains('jasmine') ||
        lower.contains('flower')) {
      return CropCategoryTab.flowers;
    }
    // Spices
    if (lower.contains('turmeric') ||
        lower.contains('ginger') ||
        lower.contains('garlic') ||
        lower.contains('cardamom') ||
        lower.contains('pepper') ||
        lower.contains('areca')) {
      return CropCategoryTab.spices;
    }
    // Fruits
    if (lower.contains('banana') ||
        lower.contains('mango') ||
        lower.contains('grapes') ||
        lower.contains('pomegranate') ||
        lower.contains('papaya') ||
        lower.contains('lemon') ||
        lower.contains('coconut') ||
        lower.contains('apple') ||
        lower.contains('orange') ||
        lower.contains('guava')) {
      return CropCategoryTab.fruits;
    }
    // Grains & Pulses
    if (lower.contains('rice') ||
        lower.contains('paddy') ||
        lower.contains('ragi') ||
        lower.contains('maize') ||
        lower.contains('wheat') ||
        lower.contains('jowar') ||
        lower.contains('bajra') ||
        lower.contains('dal') ||
        lower.contains('gram') ||
        lower.contains('groundnut') ||
        lower.contains('sunflower') ||
        lower.contains('sugarcane') ||
        lower.contains('cotton') ||
        lower.contains('coffee') ||
        lower.contains('soybean') ||
        lower.contains('pulse')) {
      return CropCategoryTab.grainsAndPulses;
    }
    // Vegetables
    return CropCategoryTab.vegetables;
  }

  Color get demandTagColor {
    switch (demandTag.toLowerCase()) {
      case 'high demand':
        return const Color(0xFF00875A); // Teal / Green
      case 'stable':
        return const Color(0xFF2563EB); // Blue
      case 'frp guaranteed':
      case 'msp protected':
        return const Color(0xFF7C3AED); // Purple
      case 'oversupply':
        return const Color(0xFFDC2626); // Red
      default:
        return const Color(0xFFD97706); // Amber
    }
  }

  factory MandiPrice.fromJson(Map<String, dynamic> json) {
    final modal = (json['modal_price'] as num?)?.toDouble() ??
        ((json['modal_paise'] as num?)?.toDouble() ?? 0) / 100.0;
    final minP = (json['min_price'] as num?)?.toDouble() ??
        ((json['min_paise'] as num?)?.toDouble() ?? modal) / 100.0;
    final maxP = (json['max_price'] as num?)?.toDouble() ??
        ((json['max_paise'] as num?)?.toDouble() ?? modal) / 100.0;

    final perKg = (json['price_per_kg'] as num?)?.toDouble() ?? (modal / 100.0);
    final change = (json['change_percent'] as num?)?.toDouble() ?? 0.0;
    final demand = json['demand_tag']?.toString() ?? 'Moderate';
    final trend = json['trend_direction']?.toString() ?? (change > 0 ? 'up' : change < 0 ? 'down' : 'stable');

    final dateStr = json['arrival_date']?.toString() ?? json['price_date']?.toString() ?? '';
    final arrDate = DateTime.tryParse(dateStr) ?? DateTime.now();

    final commodityName = json['commodity']?.toString() ?? json['crop']?.toString() ?? 'Produce';

    return MandiPrice(
      id: json['id']?.toString() ?? '',
      state: json['state']?.toString() ?? 'Karnataka',
      district: json['district']?.toString() ?? 'General',
      market: json['market']?.toString() ?? 'APMC Market',
      commodity: commodityName,
      variety: json['variety']?.toString() ?? 'Common',
      arrivalDate: arrDate,
      minPrice: minP,
      maxPrice: maxP,
      modalPrice: modal,
      pricePerKg: perKg,
      changePercent: change,
      demandTag: demand,
      trendDirection: trend,
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'state': state,
        'district': district,
        'market': market,
        'commodity': commodity,
        'variety': variety,
        'arrival_date': DateFormat('yyyy-MM-dd').format(arrivalDate),
        'min_price': minPrice,
        'max_price': maxPrice,
        'modal_price': modalPrice,
        'price_per_kg': pricePerKg,
        'change_percent': changePercent,
        'demand_tag': demandTag,
        'trend_direction': trendDirection,
        'updated_at': updatedAt.toIso8601String(),
      };
}
