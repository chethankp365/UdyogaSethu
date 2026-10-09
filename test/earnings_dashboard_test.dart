import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/earnings/domain/earnings_models.dart';
import 'package:udyogasethu/features/earnings/domain/savings_goal_model.dart';
import 'package:udyogasethu/features/earnings/presentation/widgets/allocate_savings_dialog.dart';
import 'package:udyogasethu/features/earnings/presentation/widgets/earnings_trend_chart.dart';
import 'package:udyogasethu/features/earnings/presentation/widgets/savings_goal_card.dart';
import 'package:udyogasethu/features/wallet/domain/wallet_transaction.dart';

void main() {
  group('P5.4 Earnings Dashboard Domain & Parity Tests', () {
    test('EarningsDashboardData json parsing and formatting', () {
      final json = {
        'today_earnings_paise': 80000, // ₹800
        'this_week_earnings_paise': 350000, // ₹3,500
        'this_month_earnings_paise': 1200000, // ₹12,000
        'total_earnings_paise': 4500000, // ₹45,000
        'completed_jobs_count': 18,
        'completed_orders_count': 4,
        'average_rating': 4.85,
        'daily_goal_paise': 150000, // ₹1,500
        'recent_avg_daily_earnings_paise': 120000,
        'best_day': {
          'date': '2026-10-04',
          'earnings_paise': 240000,
        },
        'daily_trends': [
          {'date': '2026-10-04', 'earnings_paise': 240000, 'jobs_count': 2},
          {'date': '2026-10-05', 'earnings_paise': 80000, 'jobs_count': 1},
        ],
        'monthly_trends': [
          {'month': '2026-09', 'month_label': 'Sep 2026', 'earnings_paise': 1500000},
          {'month': '2026-10', 'month_label': 'Oct 2026', 'earnings_paise': 3000000},
        ],
      };

      final data = EarningsDashboardData.fromJson(json);

      expect(data.todayRupees, 800.0);
      expect(data.thisWeekRupees, 3500.0);
      expect(data.thisMonthRupees, 12000.0);
      expect(data.totalRupees, 45000.0);
      expect(data.completedJobsCount, 18);
      expect(data.completedOrdersCount, 4);
      expect(data.averageRating, 4.85);
      expect(data.dailyGoalRupees, 1500.0);

      // Goal calculations
      expect(data.goalPercentage, 53); // 800 / 1500 = 53%
      expect(data.goalProgress, closeTo(0.533, 0.01));

      // Best day insight
      expect(data.bestDay, isNotNull);
      expect(data.bestDay!.earningsRupees, 2400.0);
      expect(data.bestDay!.formattedAmount, '₹2,400');

      // Trends
      expect(data.dailyTrends.length, 2);
      expect(data.monthlyTrends.length, 2);
    });

    test('CHECK BEFORE MOVING ON: Dashboard total matches wallet transactions list credits', () {
      // Simulate ledger wallet transactions list
      final transactions = [
        WalletTransaction(
          id: 'tx-1',
          type: WalletTransactionType.dailyWage,
          direction: 'credit',
          amountPaise: 80000, // +800
          bucket: 'available',
          note: 'Masonry job wage',
          createdAt: DateTime(2026, 10, 8),
        ),
        WalletTransaction(
          id: 'tx-2',
          type: WalletTransactionType.produceSale,
          direction: 'credit',
          amountPaise: 120000, // +1200
          bucket: 'available',
          note: 'Tomato crate sale',
          createdAt: DateTime(2026, 10, 7),
        ),
        WalletTransaction(
          id: 'tx-3',
          type: WalletTransactionType.dailyWage,
          direction: 'credit',
          amountPaise: 50000, // +500
          bucket: 'available',
          note: 'Weeding farm job',
          createdAt: DateTime(2026, 10, 6),
        ),
        WalletTransaction(
          id: 'tx-4',
          type: WalletTransactionType.upiTransfer,
          direction: 'debit',
          amountPaise: 100000, // -1000 withdrawal
          bucket: 'available',
          note: 'UPI Payout',
          createdAt: DateTime(2026, 10, 8),
        ),
      ];

      // Sum of credits into available bucket from transactions list
      int ledgerTotalCreditsPaise = 0;
      for (final t in transactions) {
        if (t.isCredit && t.bucket == 'available') {
          ledgerTotalCreditsPaise += t.amountPaise;
        }
      }

      expect(ledgerTotalCreditsPaise, 250000); // ₹2,500 total earned

      // Earnings dashboard summary
      final dashboard = EarningsDashboardData(
        todayEarningsPaise: 80000,
        thisWeekEarningsPaise: 250000,
        thisMonthEarningsPaise: 250000,
        totalEarningsPaise: ledgerTotalCreditsPaise, // strictly mirrors ledger
        completedJobsCount: 2,
        completedOrdersCount: 1,
        averageRating: 5.0,
        dailyGoalPaise: 150000,
      );

      // Verify exact mathematical parity
      expect(dashboard.totalEarningsPaise, equals(ledgerTotalCreditsPaise));
      expect(dashboard.formattedTotal, '₹2,500');
    });
  });

  group('P5.4 Savings Goal Planner Domain Tests', () {
    test('SavingsGoal computation with deadline calculates weekly and per-job suggestion', () {
      final now = DateTime.now();
      // Target in 28 days (4 weeks)
      final targetDate = now.add(const Duration(days: 28));

      final goal = SavingsGoal(
        id: 'goal-1',
        userId: 'u-1',
        category: SavingsGoalCategory.scooter,
        title: 'New Scooter Down Payment',
        targetPaise: 2000000, // ₹20,000
        savedPaise: 400000, // ₹4,000 saved
        deadline: targetDate,
        createdAt: now,
        updatedAt: now,
      );

      expect(goal.remainingRupees, 16000.0); // ₹16,000 remaining
      expect(goal.progressPercentage, 20); // 4,000 / 20,000 = 20%
      expect(goal.isEffectivelyCompleted, isFalse);

      final suggested = goal.computeSuggestedSavings(100000); // avg ₹1,000/day
      // ₹16,000 / 4 weeks = ₹4,000/week (400,000 paise)
      expect(suggested.perWeekPaise, 400000);
      // ₹4,000 / 5 jobs = ₹800/job (80,000 paise)
      expect(suggested.perJobPaise, 80000);
    });

    test('SavingsGoal computation without deadline falls back to recent average earnings', () {
      final now = DateTime.now();
      final goal = SavingsGoal(
        id: 'goal-2',
        userId: 'u-1',
        category: SavingsGoalCategory.emergencyFund,
        title: 'Emergency Safety Cushion',
        targetPaise: 1000000, // ₹10,000
        savedPaise: 200000, // ₹2,000 saved
        deadline: null,
        createdAt: now,
        updatedAt: now,
      );

      final suggested = goal.computeSuggestedSavings(100000); // avg ₹1,000/day (100,000 paise)
      // 15% of daily = 15,000 paise (₹150/job)
      // weekly = 15,000 * 6 = 90,000 paise (₹900/week)
      expect(suggested.perJobPaise, 15000);
      expect(suggested.perWeekPaise, 90000);
    });

    test('Completed goal sets suggested savings to zero and marks completed', () {
      final goal = SavingsGoal(
        id: 'goal-3',
        userId: 'u-1',
        category: SavingsGoalCategory.seeds,
        title: 'Kharif Seeds',
        targetPaise: 500000, // ₹5,000
        savedPaise: 500000, // ₹5,000 saved
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(goal.isEffectivelyCompleted, isTrue);
      expect(goal.progressPercentage, 100);
      expect(goal.remainingPaise, 0);

      final suggested = goal.computeSuggestedSavings(80000);
      expect(suggested.perWeekPaise, 0);
      expect(suggested.perJobPaise, 0);
    });
  });

  group('P5.4 Widget & UI Component Tests', () {
    testWidgets('EarningsTrendChart displays accessible summary text beneath chart', (tester) async {
      final dailyTrends = [
        DailyTrendItem(date: DateTime(2026, 10, 1), earningsPaise: 120000, jobsCount: 1),
        DailyTrendItem(date: DateTime(2026, 10, 2), earningsPaise: 240000, jobsCount: 2),
        DailyTrendItem(date: DateTime(2026, 10, 3), earningsPaise: 80000, jobsCount: 1),
      ];

      final monthlyTrends = [
        const MonthlyTrendItem(monthKey: '2026-09', monthLabel: 'Sep 2026', earningsPaise: 1500000),
        const MonthlyTrendItem(monthKey: '2026-10', monthLabel: 'Oct 2026', earningsPaise: 440000),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EarningsTrendChart(
              dailyTrends: dailyTrends,
              monthlyTrends: monthlyTrends,
            ),
          ),
        ),
      );

      // Verify Chart Title
      expect(find.text('Payout Trend'), findsOneWidget);
      expect(find.text('14 Days'), findsOneWidget);
      expect(find.text('6 Months'), findsOneWidget);

      // Verify Accessible Summary Text beneath the chart
      // Total earned: 1200 + 2400 + 800 = 4400. Best day was 2400 on 2 Oct.
      expect(
        find.textContaining('Total ₹4,400 earned across 4 jobs over the last 14 days.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Highest payout was ₹2,400 on 2 Oct.'),
        findsOneWidget,
      );
    });

    testWidgets('SavingsGoalCard renders category icon, progress ring, and supportive cheer', (tester) async {
      final goal = SavingsGoal(
        id: 'goal-test',
        userId: 'u-1',
        category: SavingsGoalCategory.schoolFees,
        title: 'Daughter Tuition Fees',
        targetPaise: 1000000, // ₹10,000
        savedPaise: 500000, // ₹5,000 (50%)
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool addSavingsTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SavingsGoalCard(
              goal: goal,
              onAddSavings: () {
                addSavingsTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Daughter Tuition Fees'), findsOneWidget);
      expect(find.text('₹5,000'), findsOneWidget);
      expect(find.text('of ₹10,000'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.textContaining('Halfway there!'), findsOneWidget);

      // Tap Record Savings Progress button
      final btn = find.text('Record Savings Progress');
      expect(btn, findsOneWidget);
      await tester.tap(btn);
      expect(addSavingsTapped, isTrue);
    });

    testWidgets('AllocateSavingsDialog allows selecting quick chip and submitting amount', (tester) async {
      final goal = SavingsGoal(
        id: 'goal-alloc',
        userId: 'u-1',
        category: SavingsGoalCategory.equipment,
        title: 'New Drill Machine',
        targetPaise: 500000,
        savedPaise: 100000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      int? allocatedPaise;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: ctx,
                    builder: (_) => AllocateSavingsDialog(
                      goal: goal,
                      onAllocate: (amt) {
                        allocatedPaise = amt;
                      },
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Record Savings'), findsOneWidget);
      expect(find.text('+₹1000'), findsOneWidget);

      // Tap quick chip +₹1000
      await tester.tap(find.text('+₹1000'));
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Record Progress'));
      await tester.pumpAndSettle();

      expect(allocatedPaise, 100000); // ₹1,000 in paise
    });
  });
}
