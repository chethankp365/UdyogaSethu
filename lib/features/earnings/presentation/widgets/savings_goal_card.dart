import 'package:flutter/material.dart';
import 'package:udyogasethu/features/earnings/domain/savings_goal_model.dart';

class SavingsGoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback onAddSavings;
  final VoidCallback? onDelete;

  const SavingsGoalCard({
    super.key,
    required this.goal,
    required this.onAddSavings,
    this.onDelete,
  });

  String _getSupportiveMessage(double progress) {
    if (goal.isEffectivelyCompleted) {
      return 'Goal achieved! 🏆 Congratulations on reaching your target!';
    } else if (progress >= 0.75) {
      return 'Almost there! Just a final push to achieve your dream.';
    } else if (progress >= 0.50) {
      return 'Halfway there! Keep your momentum going strong.';
    } else if (progress >= 0.25) {
      return 'Great progress! Consistent savings build your future.';
    } else {
      return 'Every small step counts towards your dream!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = goal.category.color;
    final progress = goal.progressRatio;
    final percent = goal.progressPercentage;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: goal.isEffectivelyCompleted
              ? const Color(0xFF10B981)
              : const Color(0xFFE2E8F0),
          width: goal.isEffectivelyCompleted ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Category icon, title, completion badge or more menu
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  goal.category.icon,
                  color: categoryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          goal.category.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: categoryColor,
                          ),
                        ),
                        if (goal.deadline != null) ...[
                          const SizedBox(width: 6),
                          const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                          const SizedBox(width: 6),
                          Text(
                            goal.isOverdue
                                ? 'Overdue (${goal.formattedDeadline})'
                                : 'Due: ${goal.formattedDeadline}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: goal.isOverdue
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8)),
                  onSelected: (val) {
                    if (val == 'delete' && onDelete != null) {
                      onDelete!();
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 18),
                          SizedBox(width: 8),
                          Text('Delete Goal', style: TextStyle(color: Color(0xFFDC2626))),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Middle Row: Saved vs Target & Progress Ring
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        goal.formattedSaved,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D6548),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'of ${goal.formattedTarget}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    goal.isEffectivelyCompleted
                        ? 'Target achieved!'
                        : '₹${(goal.remainingRupees).round()} remaining',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: goal.isEffectivelyCompleted
                          ? const Color(0xFF10B981)
                          : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              // Circular Progress Ring
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        goal.isEffectivelyCompleted
                            ? const Color(0xFF10B981)
                            : categoryColor,
                      ),
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Supportive Message Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: goal.isEffectivelyCompleted
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: goal.isEffectivelyCompleted
                    ? const Color(0xFFA7F3D0)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  goal.isEffectivelyCompleted
                      ? Icons.celebration_rounded
                      : Icons.lightbulb_outline_rounded,
                  size: 16,
                  color: goal.isEffectivelyCompleted
                      ? const Color(0xFF059669)
                      : const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getSupportiveMessage(progress),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: goal.isEffectivelyCompleted
                          ? const Color(0xFF065F46)
                          : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Button: Add virtual savings
          if (!goal.isEffectivelyCompleted)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddSavings,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0D6548),
                  side: const BorderSide(color: Color(0xFF0D6548)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'Record Savings Progress',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Goal Completed 🎉',
                    style: TextStyle(
                      color: Color(0xFF065F46),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
