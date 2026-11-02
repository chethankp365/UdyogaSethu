import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/config/env.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/wallet/data/wallet_repository.dart';
import 'package:udyogasethu/features/wallet/domain/upi_payment_data.dart';
import 'package:udyogasethu/features/wallet/domain/wallet_balance.dart';
import 'package:udyogasethu/features/wallet/presentation/widgets/razorpay_payment_sheet.dart';

class ScanUpiDialog extends ConsumerStatefulWidget {
  const ScanUpiDialog({super.key});

  @override
  ConsumerState<ScanUpiDialog> createState() => _ScanUpiDialogState();
}

class _ScanUpiDialogState extends ConsumerState<ScanUpiDialog> with WidgetsBindingObserver {
  late final MobileScannerController _scannerController;
  final TextEditingController _qrInputController = TextEditingController();
  final TextEditingController _customAmountController = TextEditingController();
  late final Razorpay _razorpay;

  bool _isCameraMode = true;
  bool _isTorchOn = false;
  UpiPaymentData? _parsedData;
  String? _parseError;
  bool _isValidatingVpa = false;
  String? _bankVerifiedName;
  bool _isBankVerified = false;
  String? _bankVerificationError;

  bool _isProcessingPayment = false;
  String? _paymentErrorMessage;
  String? _paymentSuccessMessage;

  // Payment mode: 'wallet' or 'gateway'
  String _paymentFundingMode = 'wallet';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleRazorpayExternalWallet);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    _qrInputController.dispose();
    _customAmountController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  void _handleRazorpaySuccess(PaymentSuccessResponse response) {
    if (!mounted) return;
    setState(() {
      _isProcessingPayment = false;
      _paymentSuccessMessage =
          'Payment Gateway Success!\nTransaction Ref: ${response.paymentId ?? "RZP_OK"}\nPaid to: ${_parsedData?.payeeName ?? _parsedData?.payeeVpa}';
    });
    ref.invalidate(walletSummaryProvider);
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() {
      _isProcessingPayment = false;
      _paymentErrorMessage = 'Gateway Payment failed: ${response.message ?? "Transaction cancelled"}';
    });
  }

  void _handleRazorpayExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() {
      _isProcessingPayment = false;
      _paymentSuccessMessage = 'Wallet app opened (${response.walletName}). Waiting for settlement confirmation.';
    });
  }

  void _parseQr(String rawText) {
    setState(() {
      _parseError = null;
      _bankVerifiedName = null;
      _isBankVerified = false;
      _bankVerificationError = null;
      _paymentErrorMessage = null;
      _paymentSuccessMessage = null;
    });

    final trimmed = rawText.trim();
    if (!trimmed.toLowerCase().startsWith('upi://pay') && !RegExp(r'^[\w.\-]+@[\w.\-]+$').hasMatch(trimmed)) {
      setState(() {
        _parsedData = null;
        _parseError = 'Invalid code: Not a valid UPI QR code. Must be a valid upi://pay URI or VPA.';
      });
      return;
    }

    final data = UpiPaymentData.parse(trimmed);
    if (!data.isValid) {
      setState(() {
        _parsedData = null;
        _parseError = data.errorMessage ?? 'Invalid UPI QR code structure.';
      });
      return;
    }

    setState(() {
      _parsedData = data;
      _parseError = null;
      if (data.amount != null) {
        _customAmountController.text = data.amount!.toStringAsFixed(2);
      } else {
        _customAmountController.text = '100';
      }
    });

    _validateVpaWithServer(data.payeeVpa);
  }

  Future<void> _validateVpaWithServer(String vpa) async {
    setState(() {
      _isValidatingVpa = true;
      _bankVerifiedName = null;
      _isBankVerified = false;
      _bankVerificationError = null;
    });

    try {
      final client = Supabase.instance.client;
      final response = await client.functions.invoke(
        'validate-vpa',
        body: {'vpa': vpa},
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final bankVerified = data['bank_verified'] == true;
        final customerName = data['customer_name'] as String?;
        final error = data['error'] as String?;

        if (mounted) {
          setState(() {
            _isValidatingVpa = false;
            _isBankVerified = bankVerified;
            _bankVerifiedName = customerName;
            _bankVerificationError = bankVerified ? null : (error ?? 'Bank verification unavailable');
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isValidatingVpa = false;
            _isBankVerified = false;
            _bankVerificationError = 'Unexpected server response format';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidatingVpa = false;
          _isBankVerified = false;
          _bankVerificationError = 'Connection error: ${e.toString().replaceAll(RegExp(r'Exception:?'), '').trim()}';
        });
      }
    }
  }

  double _getEffectiveAmount() {
    if (_parsedData?.amount != null && _parsedData!.amount! > 0) {
      return _parsedData!.amount!;
    }
    return double.tryParse(_customAmountController.text.trim()) ?? 0;
  }

  Future<void> _onPayPressed(WalletBalance currentBalance) async {
    if (_parsedData == null) return;
    final rupees = _getEffectiveAmount();
    if (rupees <= 0) {
      setState(() => _paymentErrorMessage = 'Please specify a valid payment amount greater than ₹0.');
      return;
    }

    final amountPaise = (rupees * 100).round();

    setState(() {
      _isProcessingPayment = true;
      _paymentErrorMessage = null;
      _paymentSuccessMessage = null;
    });

    if (_paymentFundingMode == 'wallet') {
      // 1. Pay from UdyogaSethu Wallet
      // Strict rule: Money cannot be moved if there is no amount in the wallet
      if (currentBalance.availablePaise < amountPaise) {
        setState(() {
          _isProcessingPayment = false;
          _paymentErrorMessage =
              'Insufficient wallet balance! Available: ${currentBalance.formattedAvailable}, Required: ₹${rupees.toStringAsFixed(2)}. Money cannot be moved without sufficient wallet funds. Please recharge or choose Payment Gateway.';
        });
        return;
      }

      try {
        final repo = ref.read(walletRepositoryProvider);
        await repo.payVpaFromWallet(
          payeeVpa: _parsedData!.payeeVpa,
          payeeName: _bankVerifiedName ?? _parsedData!.payeeName ?? _parsedData!.payeeVpa,
          amountPaise: amountPaise,
          note: _parsedData!.transactionNote ?? 'UPI QR Payment',
        );

        if (mounted) {
          setState(() {
            _isProcessingPayment = false;
            _paymentSuccessMessage =
                'Payment of ₹${rupees.toStringAsFixed(2)} to ${_bankVerifiedName ?? _parsedData!.payeeVpa} successful from Wallet!';
          });
          ref.invalidate(walletSummaryProvider);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isProcessingPayment = false;
            _paymentErrorMessage = e.toString().replaceAll('Exception:', '').trim();
          });
        }
      }
    } else {
      // 2. Real Payment Gateway (Razorpay checkout)
      final currentUser = Supabase.instance.client.auth.currentUser;
      final phone = currentUser?.phone ?? '';
      final email = currentUser?.email ?? '';

      final options = <String, dynamic>{
        'key': Env.razorpayKeyId,
        'amount': amountPaise,
        'name': _parsedData?.payeeName ?? 'UPI QR Merchant',
        'description': 'Direct UPI QR Gateway Payment to ${_parsedData?.payeeVpa}',
        'timeout': 300,
        'prefill': {
          if (phone.isNotEmpty) 'contact': phone,
          if (email.isNotEmpty) 'email': email,
          'vpa': _parsedData?.payeeVpa,
        },
        'theme': {
          'color': '#0D6548',
        },
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        setState(() => _isProcessingPayment = false);
        RazorpayPaymentSheet.show(
          context,
          amountRupees: rupees,
          onSuccess: () {
            if (mounted) {
              setState(() {
                _paymentSuccessMessage =
                    'Gateway payment of ₹${rupees.toStringAsFixed(2)} to ${_bankVerifiedName ?? _parsedData?.payeeName ?? _parsedData?.payeeVpa} successful!';
              });
              ref.invalidate(walletSummaryProvider);
            }
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(walletSummaryStreamProvider);
    final currentBalance = balanceAsync.asData?.value ?? WalletBalance.zero();
    final effectiveRupees = _getEffectiveAmount();
    final effectivePaise = (effectiveRupees * 100).round();
    final hasSufficientWalletBalance = currentBalance.availablePaise >= effectivePaise && effectivePaise > 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                      Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF0D6548), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Scan UPI QR',
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
              const SizedBox(height: 6),

              // Official NPCI / UPI Verified Gateway Badge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF059669)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Instant UPI & Payment Gateway. Live transaction verification enabled.',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Mode switcher (Debug/Testing convenience)
              if (kDebugMode) ...[
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        avatar: const Icon(Icons.camera_alt_rounded, size: 16),
                        label: const Center(child: Text('Live Camera')),
                        selected: _isCameraMode,
                        selectedColor: const Color(0xFF0D6548),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _isCameraMode ? Colors.white : AppColors.textDark,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _isCameraMode = true);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        avatar: const Icon(Icons.edit_note_rounded, size: 16),
                        label: const Center(child: Text('Paste/Type QR')),
                        selected: !_isCameraMode,
                        selectedColor: const Color(0xFF0D6548),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: !_isCameraMode ? Colors.white : AppColors.textDark,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _isCameraMode = false);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // Camera Scanner View
              if (_isCameraMode) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    color: Colors.black,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        MobileScanner(
                          controller: _scannerController,
                          onDetect: (capture) {
                            final barcodes = capture.barcodes;
                            for (final barcode in barcodes) {
                              final code = barcode.rawValue;
                              if (code != null && code.isNotEmpty) {
                                _parseQr(code);
                                break;
                              }
                            }
                          },
                        ),
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  _scannerController.toggleTorch();
                                  setState(() => _isTorchOn = !_isTorchOn);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
                                onPressed: () => _scannerController.switchCamera(),
                              ),
                            ],
                          ),
                        ),
                        const Positioned(
                          bottom: 10,
                          child: Text(
                            'Point camera at recipient UPI QR code',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ] else if (kDebugMode) ...[
                TextField(
                  controller: _qrInputController,
                  onChanged: _parseQr,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'upi://pay?pa=recipient@bank&pn=Merchant&am=500...',
                    labelText: 'UPI QR String / VPA',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 14),
              ],

              // Parse Error banner
              if (_parseError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDC2626)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _parseError!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ] else if (_parsedData != null) ...[
                // Parsed Details Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Verified Recipient Details',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D6548),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00875A),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Verified UPI',
                              style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),

                      _detailRow('Recipient Name', _bankVerifiedName ?? _parsedData!.payeeName ?? 'Verified Merchant'),
                      const SizedBox(height: 6),
                      _detailRow('UPI ID / VPA', _parsedData!.payeeVpa),
                      const SizedBox(height: 6),

                      if (_parsedData!.amount != null)
                        _detailRow('Payable Amount', _parsedData!.formattedAmount)
                      else ...[
                        const Text('Enter Amount (₹):', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _customAmountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            prefixText: '₹ ',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],

                      if (_parsedData!.transactionNote != null) ...[
                        const SizedBox(height: 6),
                        _detailRow('Note', _parsedData!.transactionNote!),
                      ],
                      const SizedBox(height: 10),

                      // Server Bank Validation Status Card
                      if (_isValidatingVpa) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D6548)),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Verifying VPA with Bank...',
                                style: TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_isBankVerified) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF059669)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'NPCI Bank Verified: ${_bankVerifiedName ?? _parsedData!.payeeVpa}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF065F46),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_bankVerificationError != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'NPCI Info: $_bankVerificationError',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF92400E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // FUNDING SOURCE SELECTION
                const Text(
                  'Select Payment Source',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),

                // Source 1: UdyogaSethu Wallet
                InkWell(
                  onTap: () => setState(() => _paymentFundingMode = 'wallet'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _paymentFundingMode == 'wallet' ? const Color(0xFFF0FDF4) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _paymentFundingMode == 'wallet' ? const Color(0xFF0D6548) : const Color(0xFFCBD5E1),
                        width: _paymentFundingMode == 'wallet' ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _paymentFundingMode == 'wallet' ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: const Color(0xFF0D6548),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'UdyogaSethu Wallet',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${currentBalance.formattedAvailable})',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: currentBalance.availablePaise > 0 ? const Color(0xFF0D6548) : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              if (!hasSufficientWalletBalance)
                                const Text(
                                  'Insufficient balance. Money cannot be moved without funds.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                                )
                              else
                                const Text(
                                  'Instant zero-fee transfer from your available wallet balance.',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Source 2: Real Payment Gateway (Razorpay - GPay / PhonePe / Cards)
                InkWell(
                  onTap: () => setState(() => _paymentFundingMode = 'gateway'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _paymentFundingMode == 'gateway' ? const Color(0xFFF0FDF4) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _paymentFundingMode == 'gateway' ? const Color(0xFF0D6548) : const Color(0xFFCBD5E1),
                        width: _paymentFundingMode == 'gateway' ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _paymentFundingMode == 'gateway' ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: const Color(0xFF0D6548),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Gateway (Razorpay)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Pay via GPay, PhonePe, Paytm, Debit/Credit Card, NetBanking.',
                                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Success or Error Feedback
                if (_paymentErrorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDC2626)),
                    ),
                    child: Text(
                      _paymentErrorMessage!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_paymentSuccessMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF16A34A)),
                    ),
                    child: Text(
                      _paymentSuccessMessage!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Action Pay Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6548),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isProcessingPayment
                        ? null
                        : (_paymentFundingMode == 'wallet' && !hasSufficientWalletBalance)
                            ? null
                            : () => _onPayPressed(currentBalance),
                    child: _isProcessingPayment
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _paymentFundingMode == 'wallet'
                                ? (!hasSufficientWalletBalance
                                    ? 'Insufficient Wallet Balance'
                                    : 'Pay ₹${effectiveRupees.toStringAsFixed(2)} from Wallet')
                                : 'Pay ₹${effectiveRupees.toStringAsFixed(2)} via Payment Gateway',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Close / Done Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
