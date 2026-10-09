import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/orders_repository.dart';

/// Modal dialog for reporting produce order disputes,
/// freezing escrow release and notifying mediation.
class RaiseOrderDisputeDialog extends ConsumerStatefulWidget {
  final String orderId;
  final String orderCode;
  final String farmerId;
  final VoidCallback? onDisputeSubmitted;

  const RaiseOrderDisputeDialog({
    super.key,
    required this.orderId,
    required this.orderCode,
    required this.farmerId,
    this.onDisputeSubmitted,
  });

  static Future<void> show(
    BuildContext context, {
    required String orderId,
    required String orderCode,
    required String farmerId,
    VoidCallback? onDisputeSubmitted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: RaiseOrderDisputeDialog(
          orderId: orderId,
          orderCode: orderCode,
          farmerId: farmerId,
          onDisputeSubmitted: onDisputeSubmitted,
        ),
      ),
    );
  }

  @override
  ConsumerState<RaiseOrderDisputeDialog> createState() =>
      _RaiseOrderDisputeDialogState();
}

class _RaiseOrderDisputeDialogState
    extends ConsumerState<RaiseOrderDisputeDialog> {
  String _selectedIssue = 'damaged';
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  final Map<String, String> _issueTypes = {
    'damaged': 'Damaged or Bruised Produce',
    'spoiled': 'Spoiled / Not Fresh',
    'wrong_item': 'Wrong Produce Item Delivered',
    'weight_mismatch': 'Quantity or Weight Discrepancy',
    'non_delivery': 'Items Not Delivered',
  };

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitDispute() async {
    final details = _detailsController.text.trim();
    if (details.isEmpty) {
      setState(() => _errorMessage = 'Please explain the issue details.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(ordersRepositoryProvider);
      await repo.createOrderDispute(
        orderId: widget.orderId,
        againstId: widget.farmerId,
        issueType: _selectedIssue,
        details: '${_issueTypes[_selectedIssue]}: $details',
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onDisputeSubmitted?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Dispute logged. Escrow funds have been frozen pending resolution.',
            ),
            backgroundColor: Color(0xFFD97706),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                const Icon(Icons.report_problem_rounded,
                    color: Color(0xFFDC2626), size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.reportOrderIssue ?? 'Report Order Issue / Dispute',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Order ${widget.orderCode}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Escrow freeze notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock, color: Color(0xFFD97706), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n?.disputeEscrowFreezeNotice ??
                          'Escrow fund release will be frozen until our support team verifies the produce quality issue.',
                      style: const TextStyle(
                          fontSize: 11.5, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Text(
              l10n?.selectIssueType ?? 'Select Issue Category:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),

            // Issue type radio options
            ..._issueTypes.entries.map((entry) {
              final isSelected = _selectedIssue == entry.key;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFEF2F2) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: InkWell(
                  onTap: () => setState(() => _selectedIssue = entry.key),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w500,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),

            // Details text field
            Text(
              l10n?.describeIssueDetails ?? 'Describe what happened:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),

            TextField(
              controller: _detailsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n?.disputeDetailsPlaceholder ??
                    'e.g. 2 kg tomatoes arrived crushed and leaking...',
                hintStyle:
                    const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],

            const SizedBox(height: 18),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting ? null : _submitDispute,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        l10n?.submitDisputeCTA ?? 'Freeze Escrow & Open Dispute',
                        style: const TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
