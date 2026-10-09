import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

@immutable
class DailyTrendItem {
  final DateTime date;
  final int earningsPaise;
  final int jobsCount;

  const DailyTrendItem({
    required this.date,
    required this.earningsPaise,
    required this.jobsCount,
  });

  double get earningsRupees => earningsPaise / 100.0;

  factory DailyTrendItem.fromJson(Map<String, dynamic> json) {
    return DailyTrendItem(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      earningsPaise: (json['earnings_paise'] as num?)?.toInt() ?? 0,
      jobsCount: (json['jobs_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': DateFormat('yyyy-MM-dd').format(date),
        'earnings_paise': earningsPaise,
        'jobs_count': jobsCount,
      };
}

@immutable
class MonthlyTrendItem {
  final String monthKey; // e.g. "2026-10"
  final String monthLabel; // e.g. "Oct 2026"
  final int earningsPaise;

  const MonthlyTrendItem({
    required this.monthKey,
    required this.monthLabel,
    required this.earningsPaise,
  });

  double get earningsRupees => earningsPaise / 100.0;

  factory MonthlyTrendItem.fromJson(Map<String, dynamic> json) {
    return MonthlyTrendItem(
      monthKey: json['month']?.toString() ?? '',
      monthLabel: json['month_label']?.toString() ?? '',
      earningsPaise: (json['earnings_paise'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'month': monthKey,
        'month_label': monthLabel,
        'earnings_paise': earningsPaise,
      };
}

@immutable
class BestDayInsight {
  final DateTime date;
  final int earningsPaise;

  const BestDayInsight({
    required this.date,
    required this.earningsPaise,
  });

  double get earningsRupees => earningsPaise / 100.0;

  String get formattedAmount => '₹${NumberFormat('#,##,##0').format(earningsRupees.round())}';
  String get formattedDate => DateFormat('d MMM yyyy').format(date);

  factory BestDayInsight.fromJson(Map<String, dynamic> json) {
    return BestDayInsight(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      earningsPaise: (json['earnings_paise'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': DateFormat('yyyy-MM-dd').format(date),
        'earnings_paise': earningsPaise,
      };
}

@immutable
class EarningsDashboardData {
  final int todayEarningsPaise;
  final int thisWeekEarningsPaise;
  final int thisMonthEarningsPaise;
  final int totalEarningsPaise;
  final int completedJobsCount;
  final int completedOrdersCount;
  final double averageRating;
  final int dailyGoalPaise;
  final BestDayInsight? bestDay;
  final List<DailyTrendItem> dailyTrends;
  final List<MonthlyTrendItem> monthlyTrends;
  final int recentAvgDailyEarningsPaise;

  const EarningsDashboardData({
    required this.todayEarningsPaise,
    required this.thisWeekEarningsPaise,
    required this.thisMonthEarningsPaise,
    required this.totalEarningsPaise,
    required this.completedJobsCount,
    required this.completedOrdersCount,
    required this.averageRating,
    required this.dailyGoalPaise,
    this.bestDay,
    this.dailyTrends = const [],
    this.monthlyTrends = const [],
    this.recentAvgDailyEarningsPaise = 0,
  });

  double get todayRupees => todayEarningsPaise / 100.0;
  double get thisWeekRupees => thisWeekEarningsPaise / 100.0;
  double get thisMonthRupees => thisMonthEarningsPaise / 100.0;
  double get totalRupees => totalEarningsPaise / 100.0;
  double get dailyGoalRupees => dailyGoalPaise / 100.0;
  double get recentAvgDailyRupees => recentAvgDailyEarningsPaise / 100.0;

  double get goalProgress {
    if (dailyGoalPaise <= 0) return 0.0;
    return (todayEarningsPaise / dailyGoalPaise).clamp(0.0, 1.0);
  }

  int get goalPercentage {
    if (dailyGoalPaise <= 0) return 0;
    return ((todayEarningsPaise / dailyGoalPaise) * 100).round();
  }

  String get formattedToday => '₹${NumberFormat('#,##,##0').format(todayRupees.round())}';
  String get formattedThisWeek => '₹${NumberFormat('#,##,##0').format(thisWeekRupees.round())}';
  String get formattedThisMonth => '₹${NumberFormat('#,##,##0').format(thisMonthRupees.round())}';
  String get formattedTotal => '₹${NumberFormat('#,##,##0').format(totalRupees.round())}';
  String get formattedDailyGoal => '₹${NumberFormat('#,##,##0').format(dailyGoalRupees.round())}';

  factory EarningsDashboardData.fromJson(Map<String, dynamic> json) {
    return EarningsDashboardData(
      todayEarningsPaise: (json['today_earnings_paise'] as num?)?.toInt() ?? 0,
      thisWeekEarningsPaise: (json['this_week_earnings_paise'] as num?)?.toInt() ?? 0,
      thisMonthEarningsPaise: (json['this_month_earnings_paise'] as num?)?.toInt() ?? 0,
      totalEarningsPaise: (json['total_earnings_paise'] as num?)?.toInt() ?? 0,
      completedJobsCount: (json['completed_jobs_count'] as num?)?.toInt() ?? 0,
      completedOrdersCount: (json['completed_orders_count'] as num?)?.toInt() ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 5.0,
      dailyGoalPaise: (json['daily_goal_paise'] as num?)?.toInt() ?? 150000,
      bestDay: json['best_day'] != null && json['best_day'] is Map<String, dynamic>
          ? BestDayInsight.fromJson(json['best_day'] as Map<String, dynamic>)
          : null,
      dailyTrends: (json['daily_trends'] as List<dynamic>?)
              ?.map((e) => DailyTrendItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      monthlyTrends: (json['monthly_trends'] as List<dynamic>?)
              ?.map((e) => MonthlyTrendItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      recentAvgDailyEarningsPaise:
          (json['recent_avg_daily_earnings_paise'] as num?)?.toInt() ?? 0,
    );
  }

  factory EarningsDashboardData.empty() {
    return const EarningsDashboardData(
      todayEarningsPaise: 0,
      thisWeekEarningsPaise: 0,
      thisMonthEarningsPaise: 0,
      totalEarningsPaise: 0,
      completedJobsCount: 0,
      completedOrdersCount: 0,
      averageRating: 5.0,
      dailyGoalPaise: 150000,
      dailyTrends: [],
      monthlyTrends: [],
      recentAvgDailyEarningsPaise: 0,
    );
  }
}
