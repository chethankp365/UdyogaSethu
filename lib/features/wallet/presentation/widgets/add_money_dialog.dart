import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/wallet/data/wallet_repository.dart';
import 'package:udyogasethu/features/wallet/domain/wallet_balance.dart';
import 'package:udyogasethu/features/wallet/presentation/widgets/razorpay_payment_sheet.dart';

class AddMoneyDialog extends ConsumerStatefulWidget {
  final WalletBalance walletBalance;
  final VoidCallback? onSuccess;

  const AddMoneyDialog({
    super.key,
    required this.walletBalance,
    this.onSuccess,
  });

  @override
  ConsumerState<AddMoneyDialog> createState() => _AddMoneyDialogState();
}

class _AddMoneyDialogState extends ConsumerState<AddMoneyDialog> {
  final TextEditingController _amountController = TextEditingController(text: '500');
  late final Razorpay _razorpay;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final paymentId = response.paymentId ?? 'PAY_${DateTime.now().millisecondsSinceEpoch}';
    final rupees = double.tryParse(_amountController.text.trim()) ?? 0;
    final amountPaise = (rupees * 100).round();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(walletRepositoryProvider);
      await repo.topupWallet(
        amountPaise: amountPaise,
        paymentRef: paymentId,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _successMessage =
              'Wallet recharged successfully with ₹${rupees.toStringAsFixed(0)}!\nRef: $paymentId';
        });
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Topup credit failed: ${e.toString().replaceAll("Exception:", "").trim()}';
        });
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = 'Payment failed or cancelled: ${response.message ?? "User closed payment window"}';
    });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = 'External wallet selected (${response.walletName}). Please complete payment.';
    });
  }

  void _startRazorpayTopup() {
    final text = _amountController.text.trim();
    final rupees = double.tryParse(text);

    if (rupees == null || rupees < 1) {
      setState(() => _errorMessage = 'Please enter a valid amount (minimum ₹1).');
      return;
    }
    if (rupees > 100000) {
      setState(() => _errorMessage = 'Maximum recharge limit is ₹1,00,000 per transaction.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    // Launch authentic, interactive Razorpay & UPI Payment Gateway Sheet
    RazorpayPaymentSheet.show(
      context,
      amountRupees: rupees,
      onSuccess: () {
        if (mounted) {
          setState(() {
            _successMessage = 'Recharge of ₹${rupees.toStringAsFixed(0)} completed successfully!';
          });
          widget.onSuccess?.call();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  const Row(
                    children: [
                      Icon(Icons.add_card_rounded, color: Color(0xFF0D6548), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Add Money to Wallet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Current Balance Pill
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Current Balance:',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                    Text(
                      widget.walletBalance.formattedAvailable,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D6548),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Quick Amount Chips
              const Text(
                'Select Amount (₹)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [100, 200, 500, 1000, 2000].map((amt) {
                  final isSelected = _amountController.text == amt.toString();
                  return ChoiceChip(
                    label: Text('₹$amt'),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0D6548),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _amountController.text = amt.toString();
                          _errorMessage = null;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Custom Input Field
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                decoration: InputDecoration(
                  labelText: 'Amount to Add',
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0D6548), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Gateway Info Banner
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.security_rounded, size: 18, color: Color(0xFF16A34A)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Secured Payment Gateway via Razorpay.\nSupports UPI (GPay/PhonePe), Cards, NetBanking.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF166534), height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Error or Success Feedback
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDC2626)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (_successMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF16A34A)),
                  ),
                  child: Text(
                    _successMessage!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Pay via Gateway Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6548),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isLoading ? null : _startRazorpayTopup,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Proceed to Payment Gateway',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
