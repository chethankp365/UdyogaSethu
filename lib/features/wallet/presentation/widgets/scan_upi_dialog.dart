import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/wallet/domain/upi_payment_data.dart';

class ScanUpiDialog extends StatefulWidget {
  const ScanUpiDialog({super.key});

  @override
  State<ScanUpiDialog> createState() => _ScanUpiDialogState();
}

class _ScanUpiDialogState extends State<ScanUpiDialog> with WidgetsBindingObserver {
  late final MobileScannerController _scannerController;
  final TextEditingController _qrInputController = TextEditingController();

  bool _isCameraMode = true;
  bool _isTorchOn = false;
  UpiPaymentData? _parsedData;
  String? _parseError;
  bool _isValidatingVpa = false;
  String? _bankVerifiedName;
  bool _isBankVerified = false;
  String? _bankVerificationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    _qrInputController.dispose();
    super.dispose();
  }

  void _parseQr(String rawText) {
    setState(() {
      _parseError = null;
      _bankVerifiedName = null;
      _isBankVerified = false;
      _bankVerificationError = null;
    });

    final trimmed = rawText.trim();
    if (!trimmed.toLowerCase().startsWith('upi://pay') && !RegExp(r'^[\w.\-]+@[\w.\-]+$').hasMatch(trimmed)) {
      setState(() {
        _parsedData = null;
        _parseError = 'Invalid code: Not a valid UPI QR code. Must be a valid upi://pay URI.';
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
    });

    // Automatically trigger server-side bank verification via Edge Function
    _validateVpaWithServer(data.payeeVpa);
  }

  /// Server-side VPA check calling Edge Function validate-vpa (Prompt D6)
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

  void _onPayPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test mode: no money is moved. Payment simulation verified.'),
        backgroundColor: Color(0xFF0D6548),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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

              // Test Mode Banner (Prompt D6)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFB45309)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Test mode: no money is moved. Scans and parses real UPI QR codes safely.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Debug Manual Switcher (Allowed only in Debug/Test mode; hidden in normal builds)
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
                        label: const Center(child: Text('Manual Input')),
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

              // Camera Scanner View (Default on real screen)
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
                        // Scanner Reticle Overlay
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        // Top Controls (Torch & Camera Flip)
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
                            'Point camera at UPI QR code',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ] else if (kDebugMode) ...[
                // Manual input field in debug mode
                TextField(
                  controller: _qrInputController,
                  onChanged: _parseQr,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'upi://pay?pa=recipient@bank&pn=Name&am=...',
                    labelText: 'UPI QR Payload',
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
                // Parsed Details Card (Prompt D6)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF00875A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Payment Target',
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
                              'Valid UPI QR',
                              style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),

                      // Payee name from QR (labelled "name from QR")
                      _detailRow('Name from QR', _parsedData!.payeeName ?? 'Not specified in QR'),
                      const SizedBox(height: 6),

                      // UPI ID
                      _detailRow('UPI ID', _parsedData!.payeeVpa),
                      const SizedBox(height: 6),

                      // Amount
                      _detailRow('Amount', _parsedData!.formattedAmount),

                      // Note (if present)
                      if (_parsedData!.transactionNote != null) ...[
                        const SizedBox(height: 6),
                        _detailRow('Note', _parsedData!.transactionNote!),
                      ],
                      const SizedBox(height: 12),

                      // Server Bank Validation Status Card (Prompt D6)
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
                                  'Bank Verified: ${_bankVerifiedName ?? _parsedData!.payeeVpa}',
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
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFD97706)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Not verified by bank',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                    if (_bankVerificationError != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        _bankVerificationError!,
                                        style: const TextStyle(fontSize: 10, color: Color(0xFFB45309)),
                                      ),
                                    ],
                                  ],
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

                // Pay Button (Prompt D6: "Test mode: no money is moved")
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6548),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _onPayPressed,
                    child: const Text(
                      'Test mode: no money is moved',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                    'Cancel',
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
          width: 100,
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
