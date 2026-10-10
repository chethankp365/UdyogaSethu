import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/features/earnings/domain/savings_goal_model.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/features/earnings/data/earnings_repository.dart';
import 'package:udyogasethu/features/earnings/domain/earnings_models.dart';
import 'package:udyogasethu/features/earnings/presentation/widgets/allocate_savings_dialog.dart';
import 'package:udyogasethu/features/earnings/presentation/widgets/create_savings_goal_dialog.dart';
import 'package:udyogasethu/features/earnings/presentation/widgets/earnings_trend_chart.dart';
import 'package:udyogasethu/features/earnings/presentation/widgets/savings_goal_card.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_home_controller.dart';

class EarningsDashboardScreen extends ConsumerStatefulWidget {
  const EarningsDashboardScreen({super.key});

  @override
  ConsumerState<EarningsDashboardScreen> createState() => _EarningsDashboardScreenState();
}

class _EarningsDashboardScreenState extends ConsumerState<EarningsDashboardScreen> {
  final int _selectedTrendDays = 14;

  Future<void> _refresh() async {
    ref.invalidate(earningsDashboardProvider(_selectedTrendDays));
    await ref.read(savingsGoalsProvider.notifier).refresh();
  }

  void _showDailyGoalDialog(BuildContext context, int currentGoalPaise) {
    final controller = TextEditingController(text: (currentGoalPaise / 100).round().toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Set Daily Goal', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set your target daily earnings. This updates your progress ring on Home and Dashboard.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D6548)),
                labelText: 'Daily Goal Amount',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [500, 1000, 1500, 2000].map((rupees) {
                return ActionChip(
                  label: Text('₹$rupees'),
                  onPressed: () {
                    controller.text = rupees.toString();
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D6548),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final rupees = int.tryParse(controller.text) ?? 1500;
              if (rupees > 0) {
                final newGoalPaise = rupees * 100;
                Navigator.pop(ctx);
                try {
                  await ref.read(earningsRepositoryProvider).updateDailyEarningsGoal(newGoalPaise);
                  ref.read(seekerDailyGoalProvider.notifier).setGoalPaise(newGoalPaise);
                  ref.invalidate(earningsDashboardProvider(_selectedTrendDays));
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update goal: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save Goal'),
          ),
        ],
      ),
    );
  }

  void _openCreateGoalDialog(int recentAvgDailyPaise) {
    showDialog(
      context: context,
      builder: (ctx) => CreateSavingsGoalDialog(
        recentAvgDailyEarningsPaise: recentAvgDailyPaise,
        onCreateGoal: (draft) {
          ref.read(savingsGoalsProvider.notifier).createGoal(draft);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final earningsAsync = ref.watch(earningsDashboardProvider(_selectedTrendDays));
    final savingsGoalsAsync = ref.watch(savingsGoalsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6548),
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Earnings & Performance',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'View Wallet',
            onPressed: () => context.push(AppRoutes.wallet),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF0D6548),
        child: earningsAsync.when(
          data: (data) => data.hasHistory
              ? _buildDashboardContent(data, savingsGoalsAsync)
              : _buildEmptyHistoryView(data, savingsGoalsAsync),
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF0D6548)),
          ),
          error: (err, _) => _buildErrorState(err.toString()),
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryView(
    EarningsDashboardData data,
    AsyncValue<List<SavingsGoal>> savingsGoalsAsync,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroEarningsCards(data),
          const SizedBox(height: 16),

          // Empty History Educational Card (Prompt D5: Empty state when there is no history)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.insights_rounded, color: Color(0xFF64748B), size: 30),
                ),
                const SizedBox(height: 14),
                const Text(
                  'No Ledger Earnings Yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your wallet balance and escrow are backed directly by the immutable ledger (currently ₹0 for this account). Once you complete verified shifts or produce sales, 6-month analytics, trends, and category splits will appear automatically.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.push(AppRoutes.seekerHome),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6548),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: const Text('Browse Shifts', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openCreateGoalDialog(data.recentAvgDailyEarningsPaise),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0D6548),
                        side: const BorderSide(color: Color(0xFF0D6548)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      icon: const Icon(Icons.flag_rounded, size: 18),
                      label: const Text('Set Savings Goal', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Savings Goal Section (allows planning ahead)
          _buildSavingsGoalsSection(data, savingsGoalsAsync),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(
    EarningsDashboardData data,
    AsyncValue<List<SavingsGoal>> savingsGoalsAsync,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP HERO: Total & Period Earnings Cards
          _buildHeroEarningsCards(data),
          const SizedBox(height: 16),

          // 2. 6-MONTH ANALYTICS & TREND CARD (Prompt D5: Average, Best Month, Trend vs Last Month)
          _buildMonthlyAnalyticsCard(data),
          const SizedBox(height: 16),

          // 3. PERFORMANCE STATS (Completed Jobs, Orders, Rating)
          _buildPerformanceStatsRow(data),
          const SizedBox(height: 16),

          // 4. TODAY'S DAILY GOAL RING CARD
          _buildDailyGoalCard(data),
          const SizedBox(height: 20),

          // 5. PAYOUT TREND CHART (6-Month Bar Chart & 14-Day Line Chart)
          EarningsTrendChart(
            dailyTrends: data.dailyTrends,
            monthlyTrends: data.monthlyTrends,
          ),
          const SizedBox(height: 20),

          // 6. CATEGORY BREAKDOWN (Prompt D5: Split by category)
          if (data.categorySplit.isNotEmpty) ...[
            _buildCategorySplitCard(data.categorySplit),
            const SizedBox(height: 20),
          ],

          // 7. BEST DAY INSIGHT CARD
          if (data.bestDay != null && data.bestDay!.earningsPaise > 0) ...[
            _buildBestDayCard(data.bestDay!),
            const SizedBox(height: 20),
          ],

          // 8. SAVINGS GOAL PLANNER PREVIEW
          _buildSavingsGoalsSection(data, savingsGoalsAsync),
        ],
      ),
    );
  }

  Widget _buildHeroEarningsCards(EarningsDashboardData data) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D6548), Color(0xFF14532D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D6548).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL LIFETIME EARNINGS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Color(0xFFD1FAE5),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Ledger Verified',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Total Earnings Amount (Matches wallet transaction credits)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.formattedTotal,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Row with Today, Week, Month breakdown
          Row(
            children: [
              Expanded(
                child: _buildPeriodSubCard('TODAY', data.formattedToday, const Color(0xFF34D399)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPeriodSubCard('THIS WEEK', data.formattedThisWeek, Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPeriodSubCard('THIS MONTH', data.formattedThisMonth, const Color(0xFFFDE68A)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSubCard(String label, String amount, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: Color(0xFFD1FAE5),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyAnalyticsCard(EarningsDashboardData data) {
    final isPositiveTrend = data.trendVsLastMonthPct >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '6-MONTH ANALYTICS & TREND',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.9,
                  color: Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPositiveTrend ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositiveTrend ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 14,
                      color: isPositiveTrend ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${data.formattedTrend} vs last mo',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isPositiveTrend ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Average',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.formattedMonthlyAverage,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D6548),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Best Month',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.bestMonth != null
                          ? '₹${(data.bestMonth!.earningsRupees).round()} (${data.bestMonth!.monthLabel})'
                          : '₹0',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySplitCard(List<CategorySplitItem> split) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded, color: Color(0xFF0D6548), size: 18),
              SizedBox(width: 8),
              Text(
                'Earnings by Category',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...split.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.category,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                      Text(
                        '${item.formattedAmount} (${item.percentage.toStringAsFixed(1)}%)',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D6548)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (item.percentage / 100.0).clamp(0.02, 1.0),
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D6548)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPerformanceStatsRow(EarningsDashboardData data) {
    return Row(
      children: [
        // Completed Jobs
        Expanded(
          child: _buildStatBox(
            icon: Icons.work_outline_rounded,
            iconColor: const Color(0xFF2563EB),
            label: 'Completed Jobs',
            value: data.completedJobsCount.toString(),
          ),
        ),
        const SizedBox(width: 12),
        // Completed Orders (Phase 6 / produce sales)
        Expanded(
          child: _buildStatBox(
            icon: Icons.local_shipping_outlined,
            iconColor: const Color(0xFF059669),
            label: 'Farm Orders',
            value: data.completedOrdersCount.toString(),
          ),
        ),
        const SizedBox(width: 12),
        // Rating
        Expanded(
          child: _buildStatBox(
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFF59E0B),
            label: 'Avg Rating',
            value: '${data.averageRating.toStringAsFixed(1)} ★',
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalCard(EarningsDashboardData data) {
    final progress = data.goalProgress;
    final percent = data.goalPercentage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Progress Ring
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percent >= 100 ? const Color(0xFF10B981) : const Color(0xFF0D6548),
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Details & Edit Button
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Today's Goal Progress",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    InkWell(
                      onTap: () => _showDailyGoalDialog(context, data.dailyGoalPaise),
                      child: const Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 14, color: Color(0xFF0D6548)),
                          SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D6548),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${data.formattedToday} of ${data.formattedDailyGoal}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D6548),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  percent >= 100
                      ? 'Daily target achieved! Great work today! 🎉'
                      : 'Earn ₹${((data.dailyGoalPaise - data.todayEarningsPaise) / 100).clamp(0, 9999999).round()} more to hit today\'s goal.',
                  style: TextStyle(
                    fontSize: 12,
                    color: percent >= 100 ? const Color(0xFF059669) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestDayCard(BestDayInsight bestDay) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFF59E0B),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Best Earning Day 🌟',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You earned ${bestDay.formattedAmount} on ${bestDay.formattedDate}!',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsGoalsSection(
    EarningsDashboardData data,
    AsyncValue<List<SavingsGoal>> savingsGoalsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.savings_outlined, color: Color(0xFF0D6548), size: 20),
                SizedBox(width: 8),
                Text(
                  'Savings Goals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.savingsGoals),
              child: const Row(
                children: [
                  Text(
                    'Plan Goals',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D6548),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF0D6548)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        savingsGoalsAsync.when(
          data: (goals) {
            if (goals.isEmpty) {
              return _buildEmptyGoalsCard(data.recentAvgDailyEarningsPaise);
            }

            final activeGoals = goals.where((g) => !g.isEffectivelyCompleted).toList();
            final displayGoals = activeGoals.isNotEmpty ? activeGoals.take(2).toList() : goals.take(2).toList();

            return Column(
              children: [
                ...displayGoals.map((goal) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SavingsGoalCard(
                        goal: goal,
                        onAddSavings: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AllocateSavingsDialog(
                              goal: goal,
                              onAllocate: (amtPaise) {
                                ref.read(savingsGoalsProvider.notifier).allocate(
                                      goalId: goal.id,
                                      amountPaise: amtPaise,
                                    );
                              },
                            ),
                          );
                        },
                      ),
                    )),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openCreateGoalDialog(data.recentAvgDailyEarningsPaise),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0D6548),
                      side: const BorderSide(color: Color(0xFF0D6548)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'Create New Savings Goal',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Color(0xFF0D6548)),
            ),
          ),
          error: (err, _) => _buildEmptyGoalsCard(data.recentAvgDailyEarningsPaise),
        ),
      ],
    );
  }

  Widget _buildEmptyGoalsCard(int recentAvgDailyPaise) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.flag_outlined, size: 40, color: Color(0xFF94A3B8)),
          const SizedBox(height: 10),
          const Text(
            'Plan Your Next Big Milestone',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Set virtual savings targets for school fees, equipment, or emergency funds. Goals do not lock your money.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _openCreateGoalDialog(recentAvgDailyPaise),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D6548),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create First Goal', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)),
            const SizedBox(height: 12),
            const Text(
              'Could not load earnings dashboard',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refresh,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6548)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
