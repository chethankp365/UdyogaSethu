import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

@immutable
class WageSuggestion {
  final int benchmarkMinPaise;
  final int benchmarkMaxPaise;
  final String unit; // 'daily', 'hourly', 'fixed'
  final int yearsOfExperience;
  final bool isUrgent;
  final bool isHighDemand;
  final int suggestedMinPaise;
  final int suggestedMaxPaise;
  final List<String> explanationFactors;

  const WageSuggestion({
    required this.benchmarkMinPaise,
    required this.benchmarkMaxPaise,
    this.unit = 'daily',
    this.yearsOfExperience = 0,
    this.isUrgent = false,
    this.isHighDemand = false,
    required this.suggestedMinPaise,
    required this.suggestedMaxPaise,
    required this.explanationFactors,
  });

  int get suggestedMinRupees => (suggestedMinPaise / 100).round();
  int get suggestedMaxRupees => (suggestedMaxPaise / 100).round();

  String get formattedRange {
    final fmt = NumberFormat('#,##0');
    return '₹${fmt.format(suggestedMinRupees)} – ₹${fmt.format(suggestedMaxRupees)}';
  }

  bool isBelowSuggested(int offeredPaise) => offeredPaise < suggestedMinPaise;
}
