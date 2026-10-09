import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:udyogasethu/features/earnings/domain/savings_goal_model.dart';

class AllocateSavingsDialog extends StatefulWidget {
  final SavingsGoal goal;
  final ValueChanged<int> onAllocate;

  const AllocateSavingsDialog({
    super.key,
    required this.goal,
    required this.onAllocate,
  });

  @override
  State<AllocateSavingsDialog> createState() => _AllocateSavingsDialogState();
}

class _AllocateSavingsDialogState extends State<AllocateSavingsDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Default suggestion: either ₹500 or the remaining amount if less
    final remainingRupees = (widget.goal.remainingRupees).round();
    final defaultAmount = remainingRupees > 0 && remainingRupees < 500 ? remainingRupees : 500;
    _controller = TextEditingController(text: defaultAmount.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final rupees = int.tryParse(_controller.text.replaceAll(',', '')) ?? 0;
    if (rupees <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount greater than ₹0')),
      );
      return;
    }

    widget.onAllocate(rupees * 100);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(widget.goal.category.icon, color: widget.goal.category.color, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Record Savings',
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
            Text(
              'Add progress toward "${widget.goal.title}". This is a virtual progress tracker and does not lock wallet money.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
            ),
            const SizedBox(height: 16),

            // Current progress
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Remaining Target:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  Text(
                    '₹${NumberFormat('#,##,##0').format((widget.goal.remainingRupees).round())}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D6548),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Amount Saved (₹)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              autofocus: true,
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
            const SizedBox(height: 12),

            // Quick chip suggestions
            Wrap(
              spacing: 8,
              children: [100, 250, 500, 1000].map((amt) {
                return ActionChip(
                  label: Text('+₹$amt'),
                  backgroundColor: const Color(0xFFF1F5F9),
                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0D6548)),
                  onPressed: () {
                    setState(() {
                      _controller.text = amt.toString();
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

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
                  'Record Progress',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
