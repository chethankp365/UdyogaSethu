import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/wallet/data/wallet_repository.dart';
import 'package:udyogasethu/features/wallet/domain/wallet_balance.dart';
import 'package:udyogasethu/features/wallet/domain/withdrawal_result.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class WithdrawDialog extends ConsumerStatefulWidget {
  final WalletBalance walletBalance;
  final VoidCallback? onWithdrawalSuccess;

  const WithdrawDialog({
    super.key,
    required this.walletBalance,
    this.onWithdrawalSuccess,
  });

  @override
  ConsumerState<WithdrawDialog> createState() => _WithdrawDialogState();
}

class _WithdrawDialogState extends ConsumerState<WithdrawDialog> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _upiController = TextEditingController(text: 'user@okhdfcbank');
  bool _isLoading = false;
  String? _errorMessage;
  WithdrawalResult? _result;

  @override
  void dispose() {
    _amountController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _setAmount(double rupees) {
    setState(() {
      _amountController.text = rupees.toStringAsFixed(0);
      _errorMessage = null;
    });
  }

  Future<void> _handleWithdraw() async {
    final text = _amountController.text.trim();
    final rupees = double.tryParse(text);

    if (rupees == null || rupees <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid withdrawal amount.';
      });
      return;
    }

    if (rupees > widget.walletBalance.availableRupees) {
      setState(() {
        _errorMessage = 'Withdrawal amount exceeds available wallet balance (₹${widget.walletBalance.availableRupees.toStringAsFixed(0)}).';
      });
      return;
    }

    final amountPaise = (rupees * 100).round();
    final upi = _upiController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ref.read(walletRepositoryProvider).requestWithdrawal(
            amountPaise: amountPaise,
            method: 'upi',
            payoutRef: upi.isNotEmpty ? upi : 'UPI-PAYOUT',
          );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _result = res;
        });
        widget.onWithdrawalSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Capture and display database error (e.g. Insufficient available balance)
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final availableRupees = widget.walletBalance.availableRupees;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Withdraw Earnings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Unobtrusive honesty note
              Center(
                child: Text(
                  l10n?.demoWithdrawNote ?? 'Demo mode: Simulated payout ledger debit until banking partner exists.',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),

              if (_result != null) ...[
                // Success View
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Color(0xFF00875A), size: 40),
                      const SizedBox(height: 10),
                      const Text(
                        'Payout Completed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF065F46),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${_result!.amountRupees.toStringAsFixed(0)} debited from available balance.',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF047857)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reference: ${_result!.payoutRef}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6548),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ),
              ] else ...[
                // Available Balance Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available for Withdrawal:',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                    Text(
                      widget.walletBalance.formattedAvailable,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00875A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Amount Field
                const Text(
                  'Amount (₹)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.currency_rupee, size: 20),
                    hintText: 'e.g. 500',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),

                // Quick Amount Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('₹100'),
                      onPressed: () => _setAmount(100),
                    ),
                    ActionChip(
                      label: const Text('₹500'),
                      onPressed: () => _setAmount(500),
                    ),
                    ActionChip(
                      label: const Text('₹1,000'),
                      onPressed: () => _setAmount(1000),
                    ),
                    if (availableRupees > 0)
                      ActionChip(
                        label: const Text('All Balance'),
                        onPressed: () => _setAmount(availableRupees),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // UPI Address Field
                const Text(
                  'Transfer To (UPI VPA / Bank)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _upiController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.qr_code_2_outlined, size: 20),
                    hintText: 'e.g. yourname@okhdfcbank',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),

                // Error Message Banner
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDC2626)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6548),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isLoading ? null : _handleWithdraw,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Confirm Payout Withdrawal',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
