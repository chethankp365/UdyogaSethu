import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/features/payments/data/payment_repository.dart';
import 'package:udyogasethu/features/payments/domain/payment_bill_summary.dart';
import 'package:udyogasethu/features/payments/domain/payment_models.dart';
import 'package:udyogasethu/features/payments/presentation/widgets/bill_summary_card.dart';
import 'package:udyogasethu/features/payments/presentation/widgets/payment_method_tile.dart';

class PaymentCheckoutScreen extends ConsumerStatefulWidget {
  final String refType;
  final String refId;
  final bool? protectionOverride;

  const PaymentCheckoutScreen({
    super.key,
    required this.refType,
    required this.refId,
    this.protectionOverride,
  });

  @override
  ConsumerState<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends ConsumerState<PaymentCheckoutScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.upi;
  bool _isLoading = false;
  String? _errorMessage;
  late final Razorpay _razorpay;
  String? _activePaymentId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleRazorpayExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handleRazorpaySuccess(PaymentSuccessResponse response) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (_activePaymentId != null) {
      context.pushReplacement('${AppRoutes.paymentStatus}/$_activePaymentId');
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = 'Payment cancelled or failed: ${response.message ?? "Unknown error"}';
    });
  }

  void _handleRazorpayExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (_activePaymentId != null) {
      context.pushReplacement('${AppRoutes.paymentStatus}/$_activePaymentId');
    }
  }

  Future<void> _processPayment(PaymentBillSummary bill) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(paymentRepositoryProvider);
      final result = await repo.createOrder(
        refType: widget.refType,
        refId: widget.refId,
        method: _selectedMethod,
        protectionOverride: widget.protectionOverride,
      );

      _activePaymentId = result.paymentId;

      if (_selectedMethod == PaymentMethod.cash || _selectedMethod == PaymentMethod.wallet) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        context.pushReplacement('${AppRoutes.paymentStatus}/${result.paymentId}');
        return;
      }

      // UPI or Card via Razorpay SDK
      final currentUser = Supabase.instance.client.auth.currentUser;
      final phone = currentUser?.phone ?? '';
      final email = currentUser?.email ?? '';

      final options = <String, dynamic>{
        'key': result.keyId,
        'amount': result.amountPaise,
        'name': 'UdyogaSethu',
        'description': bill.description,
        'order_id': result.orderId,
        'timeout': 300,
        'prefill': {
          if (phone.isNotEmpty) 'contact': phone,
          if (email.isNotEmpty) 'email': email,
        },
        'theme': {
          'color': '#0D6548',
        },
      };

      _razorpay.open(options);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final billAsync = ref.watch(
      paymentBillProvider((
        refType: widget.refType,
        refId: widget.refId,
        protection: widget.protectionOverride,
      )),
    );

    final walletBalanceAsync = ref.watch(availableWalletBalanceProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Payment & Escrow Protection'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      body: billAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF0D6548)),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load bill details',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(
                    paymentBillProvider((
                      refType: widget.refType,
                      refId: widget.refId,
                      protection: widget.protectionOverride,
                    )),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (bill) {
          final walletPaise = walletBalanceAsync.asData?.value ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bill Summary Card
                BillSummaryCard(bill: bill),

                const SizedBox(height: 24),

                Text(
                  'Choose Payment Method',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Method 1: UPI
                PaymentMethodTile(
                  method: PaymentMethod.upi,
                  isSelected: _selectedMethod == PaymentMethod.upi,
                  requiredAmountPaise: bill.totalPaise,
                  onTap: () => setState(() => _selectedMethod = PaymentMethod.upi),
                ),
                const SizedBox(height: 10),

                // Method 2: Card
                PaymentMethodTile(
                  method: PaymentMethod.card,
                  isSelected: _selectedMethod == PaymentMethod.card,
                  requiredAmountPaise: bill.totalPaise,
                  onTap: () => setState(() => _selectedMethod = PaymentMethod.card),
                ),
                const SizedBox(height: 10),

                // Method 3: Wallet
                PaymentMethodTile(
                  method: PaymentMethod.wallet,
                  isSelected: _selectedMethod == PaymentMethod.wallet,
                  walletBalancePaise: walletPaise,
                  requiredAmountPaise: bill.totalPaise,
                  onTap: () => setState(() => _selectedMethod = PaymentMethod.wallet),
                ),
                const SizedBox(height: 10),

                // Method 4: Cash
                PaymentMethodTile(
                  method: PaymentMethod.cash,
                  isSelected: _selectedMethod == PaymentMethod.cash,
                  requiredAmountPaise: bill.totalPaise,
                  onTap: () => setState(() => _selectedMethod = PaymentMethod.cash),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[900], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _processPayment(bill),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6548),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _selectedMethod == PaymentMethod.cash
                                ? 'Confirm Cash Booking'
                                : 'Pay ${PaymentRecord.formatIndianCurrency(bill.totalPaise)} Securely',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
