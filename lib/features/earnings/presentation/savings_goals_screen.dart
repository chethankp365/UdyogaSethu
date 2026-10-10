import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:udyogasethu/features/earnings/data/earnings_repository.dart';
import 'package:udyogasethu/features/earnings/domain/savings_goal_model.dart';
import 'package:udyogasethu/features/earnings/presentation/widgets/allocate_savings_dialog.dart';
import 'package:udyogasethu/features/earnings/presentation/widgets/create_savings_goal_dialog.dart';
import 'package:udyogasethu/features/earnings/presentation/widgets/savings_goal_card.dart';

class SavingsGoalsScreen extends ConsumerStatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  ConsumerState<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends ConsumerState<SavingsGoalsScreen> {
  String _selectedFilter = 'all'; // 'all', 'active', 'completed'

  Future<void> _refresh() async {
    await ref.read(savingsGoalsProvider.notifier).refresh();
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

  void _confirmDeleteGoal(SavingsGoal goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Savings Goal?'),
        content: Text('Are you sure you want to remove "${goal.title}"? Your recorded progress will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(savingsGoalsProvider.notifier).deleteGoal(goal.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(savingsGoalsProvider);
    final earningsAsync = ref.watch(earningsDashboardProvider(14));
    final recentAvgDailyPaise = earningsAsync.asData?.value.recentAvgDailyEarningsPaise ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6548),
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Savings Goal Planner',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Goal',
            onPressed: () => _openCreateGoalDialog(recentAvgDailyPaise),
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
        child: goalsAsync.when(
          data: (goals) => _buildGoalsList(goals, recentAvgDailyPaise),
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF0D6548)),
          ),
          error: (err, _) => Center(
            child: Text('Error loading goals: $err'),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsList(List<SavingsGoal> goals, int recentAvgDailyPaise) {
    final filteredGoals = goals.where((g) {
      if (_selectedFilter == 'active') return !g.isEffectivelyCompleted;
      if (_selectedFilter == 'completed') return g.isEffectivelyCompleted;
      return true;
    }).toList();

    int totalTargetPaise = 0;
    int totalSavedPaise = 0;
    for (final g in goals) {
      totalTargetPaise += g.targetPaise;
      totalSavedPaise += g.savedPaise;
    }

    final totalTargetRupees = (totalTargetPaise / 100).round();
    final totalSavedRupees = (totalSavedPaise / 100).round();
    final overallProgress = totalTargetPaise > 0 ? (totalSavedPaise / totalTargetPaise).clamp(0.0, 1.0) : 0.0;
    final overallPercentage = (overallProgress * 100).round();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Virtual Tracker Info Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFF2563EB), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Virtual Goal Trackers',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Goals help you budget and plan towards your dreams. They do not freeze or lock your wallet money.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E3A8A),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Total Overview Summary Box
          if (goals.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
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
                        'OVERALL SAVINGS PROGRESS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '$overallPercentage%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D6548),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: overallProgress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D6548)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saved: ₹${NumberFormat('#,##,##0').format(totalSavedRupees)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D6548),
                        ),
                      ),
                      Text(
                        'Target: ₹${NumberFormat('#,##,##0').format(totalTargetRupees)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Filter Segmented Row
          Row(
            children: [
              _buildFilterChip('All (${goals.length})', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Active (${goals.where((g) => !g.isEffectivelyCompleted).length})',
                'active',
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Completed (${goals.where((g) => g.isEffectivelyCompleted).length})',
                'completed',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Goals List or Empty State
          if (filteredGoals.isEmpty)
            _buildEmptyState(recentAvgDailyPaise)
          else
            ...filteredGoals.map((goal) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: SavingsGoalCard(
                    goal: goal,
                    onDelete: () => _confirmDeleteGoal(goal),
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
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D6548) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D6548) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(int recentAvgDailyPaise) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.savings_rounded, size: 52, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 14),
          const Text(
            'No Goals in this Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Create a savings goal for children\'s school fees, new work equipment, a scooter, seeds, or an emergency safety fund.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _openCreateGoalDialog(recentAvgDailyPaise),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D6548),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Savings Goal', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
