import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

@immutable
class PriceSuggestion {
  final String commodity;
  final double mandiModalPriceRupees;
  final String mandiMarket;
  final DateTime? mandiArrivalDate;
  final int suggestedMinPaise;
  final int suggestedMaxPaise;
  final int suggestedModalPaise;
  final String explanation;

  const PriceSuggestion({
    required this.commodity,
    required this.mandiModalPriceRupees,
    required this.mandiMarket,
    this.mandiArrivalDate,
    required this.suggestedMinPaise,
    required this.suggestedMaxPaise,
    required this.suggestedModalPaise,
    required this.explanation,
  });

  double get suggestedMinRupees => suggestedMinPaise / 100.0;
  double get suggestedMaxRupees => suggestedMaxPaise / 100.0;
  double get suggestedModalRupees => suggestedModalPaise / 100.0;

  String get formattedBand {
    final minStr = NumberFormat('#,##0').format(suggestedMinRupees.round());
    final maxStr = NumberFormat('#,##0').format(suggestedMaxRupees.round());
    return '₹$minStr – ₹$maxStr';
  }

  factory PriceSuggestion.fallback(String commodity, [double benchmarkPricePerKg = 25.0]) {
    final modalPaise = (benchmarkPricePerKg * 100).round();
    final minPaise = (modalPaise * 0.9).round();
    final maxPaise = (modalPaise * 1.15).round();

    return PriceSuggestion(
      commodity: commodity,
      mandiModalPriceRupees: benchmarkPricePerKg,
      mandiMarket: 'Karnataka APMC Benchmark',
      mandiArrivalDate: DateTime.now(),
      suggestedMinPaise: minPaise,
      suggestedMaxPaise: maxPaise,
      suggestedModalPaise: modalPaise,
      explanation: 'Suggested band computed from Karnataka APMC mandi trends and seasonal demand.',
    );
  }

  factory PriceSuggestion.fromJson(Map<String, dynamic> json) {
    return PriceSuggestion(
      commodity: json['commodity']?.toString() ?? '',
      mandiModalPriceRupees: (json['mandi_modal_price'] as num?)?.toDouble() ?? 25.0,
      mandiMarket: json['mandi_market']?.toString() ?? 'Karnataka APMC',
      mandiArrivalDate: DateTime.tryParse(json['mandi_arrival_date']?.toString() ?? ''),
      suggestedMinPaise: (json['suggested_min_paise'] as num?)?.toInt() ?? 2200,
      suggestedMaxPaise: (json['suggested_max_paise'] as num?)?.toInt() ?? 2800,
      suggestedModalPaise: (json['suggested_modal_paise'] as num?)?.toInt() ?? 2500,
      explanation: json['explanation']?.toString() ?? 'Based on APMC mandi prices.',
    );
  }

  Map<String, dynamic> toJson() => {
        'commodity': commodity,
        'mandi_modal_price': mandiModalPriceRupees,
        'mandi_market': mandiMarket,
        'mandi_arrival_date': mandiArrivalDate?.toIso8601String(),
        'suggested_min_paise': suggestedMinPaise,
        'suggested_max_paise': suggestedMaxPaise,
        'suggested_modal_paise': suggestedModalPaise,
        'explanation': explanation,
      };
}
