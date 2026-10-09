import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum SavingsGoalCategory {
  schoolFees,
  equipment,
  scooter,
  seeds,
  emergencyFund,
  homeImprovement,
  custom;

  String get dbValue {
    switch (this) {
      case SavingsGoalCategory.schoolFees:
        return 'school_fees';
      case SavingsGoalCategory.equipment:
        return 'equipment';
      case SavingsGoalCategory.scooter:
        return 'scooter';
      case SavingsGoalCategory.seeds:
        return 'seeds';
      case SavingsGoalCategory.emergencyFund:
        return 'emergency_fund';
      case SavingsGoalCategory.homeImprovement:
        return 'home_improvement';
      case SavingsGoalCategory.custom:
        return 'custom';
    }
  }

  static SavingsGoalCategory fromString(String? value) {
    switch (value) {
      case 'school_fees':
        return SavingsGoalCategory.schoolFees;
      case 'equipment':
        return SavingsGoalCategory.equipment;
      case 'scooter':
        return SavingsGoalCategory.scooter;
      case 'seeds':
        return SavingsGoalCategory.seeds;
      case 'emergency_fund':
        return SavingsGoalCategory.emergencyFund;
      case 'home_improvement':
        return SavingsGoalCategory.homeImprovement;
      default:
        return SavingsGoalCategory.custom;
    }
  }

  IconData get icon {
    switch (this) {
      case SavingsGoalCategory.schoolFees:
        return Icons.school_rounded;
      case SavingsGoalCategory.equipment:
        return Icons.build_rounded;
      case SavingsGoalCategory.scooter:
        return Icons.two_wheeler_rounded;
      case SavingsGoalCategory.seeds:
        return Icons.eco_rounded;
      case SavingsGoalCategory.emergencyFund:
        return Icons.health_and_safety_rounded;
      case SavingsGoalCategory.homeImprovement:
        return Icons.home_rounded;
      case SavingsGoalCategory.custom:
        return Icons.stars_rounded;
    }
  }

  Color get color {
    switch (this) {
      case SavingsGoalCategory.schoolFees:
        return const Color(0xFF2563EB); // Blue
      case SavingsGoalCategory.equipment:
        return const Color(0xFFD97706); // Amber
      case SavingsGoalCategory.scooter:
        return const Color(0xFF7C3AED); // Purple
      case SavingsGoalCategory.seeds:
        return const Color(0xFF059669); // Emerald
      case SavingsGoalCategory.emergencyFund:
        return const Color(0xFFDC2626); // Red
      case SavingsGoalCategory.homeImprovement:
        return const Color(0xFF0891B2); // Cyan
      case SavingsGoalCategory.custom:
        return const Color(0xFF0D6548); // Forest Green
    }
  }
}

@immutable
class SavingsGoal {
  final String id;
  final String userId;
  final SavingsGoalCategory category;
  final String title;
  final int targetPaise;
  final int savedPaise;
  final DateTime? deadline;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavingsGoal({
    required this.id,
    required this.userId,
    required this.category,
    required this.title,
    required this.targetPaise,
    required this.savedPaise,
    this.deadline,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  double get targetRupees => targetPaise / 100.0;
  double get savedRupees => savedPaise / 100.0;
  int get remainingPaise => (targetPaise - savedPaise).clamp(0, targetPaise);
  double get remainingRupees => remainingPaise / 100.0;

  double get progressRatio {
    if (targetPaise <= 0) return 0.0;
    return (savedPaise / targetPaise).clamp(0.0, 1.0);
  }

  int get progressPercentage {
    if (targetPaise <= 0) return 0;
    return ((savedPaise / targetPaise) * 100).round();
  }

  bool get isEffectivelyCompleted => isCompleted || savedPaise >= targetPaise;

  int? get daysRemaining {
    if (deadline == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline!.year, deadline!.month, deadline!.day);
    return deadlineDay.difference(today).inDays;
  }

  bool get isOverdue {
    final days = daysRemaining;
    return days != null && days < 0 && !isEffectivelyCompleted;
  }

  String get formattedTarget => '₹${NumberFormat('#,##,##0').format(targetRupees.round())}';
  String get formattedSaved => '₹${NumberFormat('#,##,##0').format(savedRupees.round())}';
  String get formattedRemaining => '₹${NumberFormat('#,##,##0').format(remainingRupees.round())}';

  String get formattedDeadline {
    if (deadline == null) return 'No deadline';
    return DateFormat('d MMM yyyy').format(deadline!);
  }

  /// Calculates suggested saving per week and per job based on recent average daily earnings.
  ({int perWeekPaise, int perJobPaise}) computeSuggestedSavings(int recentAvgDailyEarningsPaise) {
    if (isEffectivelyCompleted) {
      return (perWeekPaise: 0, perJobPaise: 0);
    }

    final days = daysRemaining;
    if (days != null && days > 0) {
      final weeks = (days / 7.0).ceil().clamp(1, 1000);
      final perWeek = (remainingPaise / weeks).round();
      // Estimated 5 working days/jobs per week
      final perJob = (perWeek / 5.0).round().clamp(1000, remainingPaise);
      return (perWeekPaise: perWeek, perJobPaise: perJob);
    }

    // If no deadline, use recent earnings as baseline (recommend ~15% savings rate)
    if (recentAvgDailyEarningsPaise > 0) {
      final dailySavingsPaise = (recentAvgDailyEarningsPaise * 0.15).round();
      final perWeek = dailySavingsPaise * 6;
      final perJob = dailySavingsPaise;
      return (
        perWeekPaise: perWeek.clamp(10000, remainingPaise),
        perJobPaise: perJob.clamp(2000, remainingPaise),
      );
    }

    // Default fallbacks when no history exists
    final defaultWeek = (remainingPaise * 0.1).round().clamp(50000, remainingPaise);
    final defaultJob = (defaultWeek / 5.0).round().clamp(10000, remainingPaise);
    return (perWeekPaise: defaultWeek, perJobPaise: defaultJob);
  }

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      category: SavingsGoalCategory.fromString(json['category']?.toString()),
      title: json['title']?.toString() ?? '',
      targetPaise: (json['target_paise'] as num?)?.toInt() ?? 0,
      savedPaise: (json['saved_paise'] as num?)?.toInt() ?? 0,
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'].toString())
          : null,
      isCompleted: json['is_completed'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'category': category.dbValue,
        'title': title,
        'target_paise': targetPaise,
        'saved_paise': savedPaise,
        'deadline': deadline != null ? DateFormat('yyyy-MM-dd').format(deadline!) : null,
        'is_completed': isCompleted,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

@immutable
class SavingsGoalDraft {
  final SavingsGoalCategory category;
  final String title;
  final int targetPaise;
  final DateTime? deadline;

  const SavingsGoalDraft({
    required this.category,
    required this.title,
    required this.targetPaise,
    this.deadline,
  });

  Map<String, dynamic> toInsertJson(String userId) => {
        'user_id': userId,
        'category': category.dbValue,
        'title': title,
        'target_paise': targetPaise,
        'saved_paise': 0,
        'deadline': deadline != null ? DateFormat('yyyy-MM-dd').format(deadline!) : null,
        'is_completed': false,
      };
}
