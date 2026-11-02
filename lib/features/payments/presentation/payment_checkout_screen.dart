import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/features/payments/data/payment_repository.dart';
import 'package:udyogasethu/features/payments/domain/payment_bill_summary.dart';
import 'package:udyogasethu/features/payments/domain/payment_models.dart';
import 'package:udyogasethu/features/payments/presentation/widgets/bill_summary_card.dart';
import 'package:udyogasethu/features/payments/presentation/widgets/payment_method_tile.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

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
  String _upiFlow = 'intent'; // 'intent' | 'qr' | 'collect'
  final TextEditingController _vpaController = TextEditingController();
  String? _vpaError;

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
    _vpaController.dispose();
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
    final l10n = AppLocalizations.of(context);
    // Double-tap guard
    if (_isLoading) return;

    if (_selectedMethod == PaymentMethod.upi && _upiFlow == 'collect') {
      final vpa = _vpaController.text.trim();
      final repo = ref.read(paymentRepositoryProvider);
      final isValid = await repo.validateVpa(vpa);
      if (!isValid) {
        setState(() {
          _vpaError = l10n?.paymentUpiVpaInvalid ?? 'Please enter a valid UPI ID (e.g. name@bank)';
        });
        return;
      } else {
        setState(() => _vpaError = null);
      }
    }

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
        upiFlow: _selectedMethod == PaymentMethod.upi ? _upiFlow : null,
        upiVpa: (_selectedMethod == PaymentMethod.upi && _upiFlow == 'collect')
            ? _vpaController.text.trim()
            : null,
      );

      _activePaymentId = result.paymentId;

      if (_selectedMethod == PaymentMethod.cash || _selectedMethod == PaymentMethod.wallet) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        context.pushReplacement('${AppRoutes.paymentStatus}/${result.paymentId}');
        return;
      }

      // If user chose Dynamic QR flow, display QR Code dialog/sheet
      if (_selectedMethod == PaymentMethod.upi && _upiFlow == 'qr') {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showDynamicQrModal(result, bill);
        return;
      }

      // UPI (intent/collect) or Card via Razorpay SDK
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
          if (_selectedMethod == PaymentMethod.upi && _upiFlow == 'collect')
            'vpa': _vpaController.text.trim(),
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

  void _showDynamicQrModal(PaymentOrderResult result, PaymentBillSummary bill) {
    final upiPayload = result.upiString ??
        'upi://pay?pa=razorpay@icici&pn=UdyogaSethu&am=${(bill.totalPaise / 100).toStringAsFixed(2)}&cu=INR&tn=${result.receiptNo}&tr=${result.paymentId}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _DynamicQrSheet(
          paymentId: result.paymentId,
          receiptNo: result.receiptNo,
          totalPaise: bill.totalPaise,
          upiString: upiPayload,
          onStatusCheck: () {
            Navigator.pop(ctx);
            context.pushReplacement('${AppRoutes.paymentStatus}/${result.paymentId}');
          },
        );
      },
    );
  }

  Widget _buildUpiOptionTile({
    required String id,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _upiFlow == id;
    return InkWell(
      onTap: () => setState(() => _upiFlow = id),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE6F4EA) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D6548) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: isSelected ? const Color(0xFF0D6548) : Colors.grey,
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 18, color: isSelected ? const Color(0xFF0D6548) : Colors.grey[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                  color: isSelected ? const Color(0xFF0D6548) : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

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
        title: Text(l10n?.paymentTitle ?? 'Payment & Escrow Protection'),
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
                  child: Text(l10n?.paymentTryAgain ?? 'Retry'),
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
                  l10n?.paymentChooseMethod ?? 'Choose Payment Method',
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

                // Sub-options for UPI
                if (_selectedMethod == PaymentMethod.upi) ...[
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF0D6548).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUpiOptionTile(
                          id: 'intent',
                          title: l10n?.paymentUpiApps ?? 'UPI Apps (GPay, PhonePe, Paytm)',
                          icon: Icons.apps,
                        ),
                        _buildUpiOptionTile(
                          id: 'qr',
                          title: l10n?.paymentUpiQr ?? 'Dynamic UPI QR Code',
                          icon: Icons.qr_code,
                        ),
                        _buildUpiOptionTile(
                          id: 'collect',
                          title: l10n?.paymentUpiCollect ?? 'Enter UPI ID / VPA',
                          icon: Icons.alternate_email,
                        ),
                        // VPA Input Field if collect flow is selected
                        if (_upiFlow == 'collect') ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _vpaController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: l10n?.paymentUpiVpaHint ?? 'e.g. mobile@upi or username@bank',
                              errorText: _vpaError,
                              prefixIcon: const Icon(Icons.alternate_email, size: 18),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

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
                                ? (l10n?.paymentConfirmCash ?? 'Confirm Cash Booking')
                                : (_selectedMethod == PaymentMethod.upi && _upiFlow == 'qr')
                                    ? (l10n?.paymentUpiQr ?? 'Generate Dynamic UPI QR')
                                    : (l10n?.paymentPaySecurely(
                                            PaymentRecord.formatIndianCurrency(bill.totalPaise)) ??
                                        'Pay ${PaymentRecord.formatIndianCurrency(bill.totalPaise)} Securely'),
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

class _DynamicQrSheet extends StatefulWidget {
  final String paymentId;
  final String receiptNo;
  final int totalPaise;
  final String upiString;
  final VoidCallback onStatusCheck;

  const _DynamicQrSheet({
    required this.paymentId,
    required this.receiptNo,
    required this.totalPaise,
    required this.upiString,
    required this.onStatusCheck,
  });

  @override
  State<_DynamicQrSheet> createState() => _DynamicQrSheetState();
}

class _DynamicQrSheetState extends State<_DynamicQrSheet> {
  int _secondsLeft = 300; // 5 minute standard UPI QR timer
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    final formattedTimer = '$minutes:$seconds';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.paymentUpiQr ?? 'Dynamic UPI QR Code',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n?.paymentUpiQrScanPrompt ?? 'Scan this QR code using any UPI app to pay',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Vector Dynamic QR Frame
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: widget.upiString,
                version: QrVersions.auto,
                size: 200.0,
                gapless: true,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF0D6548),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Amount and Timer
            Text(
              PaymentRecord.formatIndianCurrency(widget.totalPaise),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0D6548),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  l10n?.paymentUpiQrExpiresIn(formattedTimer) ?? 'Expires in $formattedTimer',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _secondsLeft < 60 ? Colors.red : Colors.grey[700],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Copy UPI Link Button
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.upiString));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('UPI payment string copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy, size: 16, color: Color(0xFF0D6548)),
              label: const Text(
                'Copy UPI Intent Link',
                style: TextStyle(color: Color(0xFF0D6548), fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),

            const SizedBox(height: 8),

            // Check Payment Status Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: widget.onStatusCheck,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6548),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  l10n?.paymentRefreshStatus ?? 'Check Bank Status',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
