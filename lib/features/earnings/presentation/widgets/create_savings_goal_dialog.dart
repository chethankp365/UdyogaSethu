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

  ({int perWeekRupees, int perJobRupees}) _computeLiveSuggestedSavings() {
    final targetRupees = int.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    if (targetRupees <= 0) return (perWeekRupees: 0, perJobRupees: 0);

    final targetPaise = targetRupees * 100;
    final tempGoal = SavingsGoal(
      id: '',
      userId: '',
      category: _selectedCategory,
      title: '',
      targetPaise: targetPaise,
      savedPaise: 0,
      deadline: _selectedDeadline,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final suggested = tempGoal.computeSuggestedSavings(widget.recentAvgDailyEarningsPaise);
    return (
      perWeekRupees: (suggested.perWeekPaise / 100).round(),
      perJobRupees: (suggested.perJobPaise / 100).round(),
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    final rupees = int.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a goal title')),
      );
      return;
    }

    if (rupees <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid target amount')),
      );
      return;
    }

    final draft = SavingsGoalDraft(
      category: _selectedCategory,
      title: title,
      targetPaise: rupees * 100,
      deadline: _selectedDeadline,
    );

    widget.onCreateGoal(draft);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final suggested = _computeLiveSuggestedSavings();
    final avgDailyRupees = (widget.recentAvgDailyEarningsPaise / 100).round();

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
              const SizedBox(height: 18),

              // Live Suggested Saving Calculator Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: Color(0xFF0D6548), size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Suggested Savings Plan',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Per Week',
                                style: TextStyle(fontSize: 11, color: Color(0xFF047857)),
                              ),
                              Text(
                                '₹${NumberFormat('#,##,##0').format(suggested.perWeekRupees)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 28, color: const Color(0xFFA7F3D0)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Per Completed Job',
                                style: TextStyle(fontSize: 11, color: Color(0xFF047857)),
                              ),
                              Text(
                                '₹${NumberFormat('#,##,##0').format(suggested.perJobRupees)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      avgDailyRupees > 0
                          ? 'Computed from your recent daily average earnings of ₹$avgDailyRupees/day.'
                          : 'Based on standard savings benchmark to help you reach your target comfortably.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF047857),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
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
