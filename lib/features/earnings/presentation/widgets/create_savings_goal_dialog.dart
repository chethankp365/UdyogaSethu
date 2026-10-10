import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:udyogasethu/features/earnings/domain/savings_goal_model.dart';

class CreateSavingsGoalDialog extends StatefulWidget {
  final int recentAvgDailyEarningsPaise;
  final ValueChanged<SavingsGoalDraft> onCreateGoal;

  const CreateSavingsGoalDialog({
    super.key,
    required this.recentAvgDailyEarningsPaise,
    required this.onCreateGoal,
  });

  @override
  State<CreateSavingsGoalDialog> createState() => _CreateSavingsGoalDialogState();
}

class _CreateSavingsGoalDialogState extends State<CreateSavingsGoalDialog> {
  SavingsGoalCategory _selectedCategory = SavingsGoalCategory.emergencyFund;
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  DateTime? _selectedDeadline;
  String _targetMode = 'target_amount'; // 'target_amount' or 'monthly_percentage'
  double _monthlyPercentage = 15.0; // 15% default

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: _getDefaultTitleForCategory(_selectedCategory));
    _amountController = TextEditingController(text: '10000');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _getDefaultTitleForCategory(SavingsGoalCategory cat) {
    switch (cat) {
      case SavingsGoalCategory.schoolFees:
        return 'Children School Fees';
      case SavingsGoalCategory.equipment:
        return 'Work Tools & Equipment';
      case SavingsGoalCategory.scooter:
        return 'Two-Wheeler Scooter';
      case SavingsGoalCategory.seeds:
        return 'Seeds & Fertilizer';
      case SavingsGoalCategory.emergencyFund:
        return 'Family Emergency Fund';
      case SavingsGoalCategory.homeImprovement:
        return 'Home Renovation';
      case SavingsGoalCategory.custom:
        return 'My Dream Goal';
    }
  }

  void _onCategorySelected(SavingsGoalCategory cat) {
    setState(() {
      _selectedCategory = cat;
      if (_titleController.text.isEmpty ||
          _titleController.text == _getDefaultTitleForCategory(_selectedCategory)) {
        _titleController.text = _getDefaultTitleForCategory(cat);
      }
    });
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? now.add(const Duration(days: 90)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D6548),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  ({
    int monthlySavingNeededRupees,
    int projectedBalanceRupees,
    int targetRupees,
    double progressRingValue,
  }) _computePlannerCalculations() {
    final avgMonthlyRupees = ((widget.recentAvgDailyEarningsPaise * 30) / 100).round();
    final baselineMonthly = avgMonthlyRupees > 0 ? avgMonthlyRupees : 25000;

    if (_targetMode == 'monthly_percentage') {
      final monthlyNeeded = (baselineMonthly * (_monthlyPercentage / 100.0)).round();
      // Projected balance in 6 months
      final projected6m = monthlyNeeded * 6;
      return (
        monthlySavingNeededRupees: monthlyNeeded,
        projectedBalanceRupees: projected6m,
        targetRupees: projected6m,
        progressRingValue: (_monthlyPercentage / 100.0).clamp(0.05, 1.0),
      );
    } else {
      final target = int.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
      final days = _selectedDeadline != null
          ? _selectedDeadline!.difference(DateTime.now()).inDays.clamp(1, 1825)
          : 90;
      final months = (days / 30.0).clamp(0.5, 60.0);
      final monthlyNeeded = target > 0 ? (target / months).round() : 0;
      final projected = monthlyNeeded * (months.ceil());
      return (
        monthlySavingNeededRupees: monthlyNeeded,
        projectedBalanceRupees: projected,
        targetRupees: target,
        progressRingValue: target > 0 ? (monthlyNeeded / target).clamp(0.05, 1.0) : 0.2,
      );
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a goal title')),
      );
      return;
    }

    final calcs = _computePlannerCalculations();
    if (calcs.targetRupees <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid target amount')),
      );
      return;
    }

    final draft = SavingsGoalDraft(
      category: _selectedCategory,
      title: title,
      targetPaise: calcs.targetRupees * 100,
      deadline: _selectedDeadline,
      monthlyPercentage: _targetMode == 'monthly_percentage' ? _monthlyPercentage : null,
      targetType: _targetMode,
      monthlySavingNeededPaise: calcs.monthlySavingNeededRupees * 100,
      projectedBalancePaise: calcs.projectedBalanceRupees * 100,
    );

    widget.onCreateGoal(draft);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.flag_rounded, color: Color(0xFF0D6548), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'New Savings Goal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Goals are virtual trackers to plan your dreams. They do not lock your money.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),

              // Category Selector
              const Text(
                'Category',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SavingsGoalCategory.values.map((cat) {
                  final isSelected = cat == _selectedCategory;
                  return ChoiceChip(
                    avatar: Icon(
                      cat.icon,
                      size: 16,
                      color: isSelected ? Colors.white : cat.color,
                    ),
                    label: Text(_getCategoryLabel(cat)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0D6548),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                    ),
                    onSelected: (val) {
                      if (val) _onCategorySelected(cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Title Field
              const Text(
                'Goal Title',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'e.g. Scooter purchase fund',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Target Mode Selector (Prompt D5: Target amount & date OR monthly percentage of average earnings)
              const Text(
                'Planner Mode',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _targetMode = 'target_amount'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _targetMode == 'target_amount' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _targetMode == 'target_amount'
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                : null,
                          ),
                          child: Text(
                            'Target Amount & Date',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _targetMode == 'target_amount' ? FontWeight.bold : FontWeight.w500,
                              color: _targetMode == 'target_amount' ? const Color(0xFF0D6548) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _targetMode = 'monthly_percentage'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _targetMode == 'monthly_percentage' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _targetMode == 'monthly_percentage'
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                : null,
                          ),
                          child: Text(
                            'Monthly % of Earnings',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _targetMode == 'monthly_percentage' ? FontWeight.bold : FontWeight.w500,
                              color: _targetMode == 'monthly_percentage' ? const Color(0xFF0D6548) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_targetMode == 'target_amount') ...[
                // Target Amount
                const Text(
                  'Target Amount (₹)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D6548),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // Target Deadline
                const Text(
                  'Target Deadline (Optional)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDeadline,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDeadline != null
                              ? DateFormat('d MMMM yyyy').format(_selectedDeadline!)
                              : 'Select deadline date',
                          style: TextStyle(
                            fontSize: 14,
                            color: _selectedDeadline != null
                                ? const Color(0xFF1E293B)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        const Icon(Icons.calendar_month_rounded, color: Color(0xFF0D6548), size: 20),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Monthly Percentage Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Monthly Savings Rate',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                    Text(
                      '${_monthlyPercentage.round()}% of income',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D6548),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _monthlyPercentage,
                  min: 5,
                  max: 50,
                  divisions: 9,
                  activeColor: const Color(0xFF0D6548),
                  label: '${_monthlyPercentage.round()}%',
                  onChanged: (val) => setState(() => _monthlyPercentage = val),
                ),
              ],
              const SizedBox(height: 18),

              // Live Planner Card with Progress Ring & Projections (Prompt D5)
              Builder(builder: (ctx) {
                final calcs = _computePlannerCalculations();
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      // Progress Ring
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 52,
                            height: 52,
                            child: CircularProgressIndicator(
                              value: calcs.progressRingValue,
                              strokeWidth: 5,
                              backgroundColor: const Color(0xFFD1FAE5),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D6548)),
                            ),
                          ),
                          Text(
                            '${(calcs.progressRingValue * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D6548),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Monthly Saving Needed:',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF047857)),
                                ),
                                Text(
                                  '₹${NumberFormat('#,##,##0').format(calcs.monthlySavingNeededRupees)}/mo',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Projected Balance:',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF047857)),
                                ),
                                Text(
                                  '₹${NumberFormat('#,##,##0').format(calcs.projectedBalanceRupees)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6548),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Create Savings Goal',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryLabel(SavingsGoalCategory cat) {
    switch (cat) {
      case SavingsGoalCategory.schoolFees:
        return 'School Fees';
      case SavingsGoalCategory.equipment:
        return 'Equipment';
      case SavingsGoalCategory.scooter:
        return 'Scooter';
      case SavingsGoalCategory.seeds:
        return 'Seeds';
      case SavingsGoalCategory.emergencyFund:
        return 'Emergency';
      case SavingsGoalCategory.homeImprovement:
        return 'Home';
      case SavingsGoalCategory.custom:
        return 'Custom';
    }
  }
}
