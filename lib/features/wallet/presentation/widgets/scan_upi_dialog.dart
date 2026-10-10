import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
  bool _isValidating = false;
  String? _validationStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    // Pre-populate with a sample URI for immediate verification and interactive preview
    _loadSampleUri(
      'upi://pay?pa=farmer.suresh@upi&pn=Suresh%20Agri%20Produce&am=450.00&cu=INR&tn=Fresh%20Tomatoes',
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    _qrInputController.dispose();
    super.dispose();
  }

  void _loadSampleUri(String uri) {
    _qrInputController.text = uri;
    _parseQr(uri);
  }

  void _parseQr(String rawText) {
    setState(() {
      _parseError = null;
      _validationStatus = null;
    });

    final data = UpiPaymentData.parse(rawText);
    if (!data.isValid) {
      setState(() {
        _parsedData = null;
        _parseError = 'Invalid UPI QR code. Must be a valid upi://pay URI or valid VPA (name@bank).';
      });
    } else {
      setState(() {
        _parsedData = data;
        _parseError = null;
        _validationStatus = 'VPA Syntax Verified (${data.payeeVpa})';
      });
    }
  }

  Future<void> _simulateValidateVpa() async {
    if (_parsedData == null) return;
    setState(() {
      _isValidating = true;
      _validationStatus = null;
    });

    // Simulated NPCI UPI verification roundtrip
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() {
      _isValidating = false;
      _validationStatus = 'NPCI Routing Verified • Account Active (${_parsedData!.payeeVpa})';
    });
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

              // Mandatory Demo Mode Banner per AGENTS.md
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFB45309)),
                        SizedBox(width: 6),
                        Text(
                          'Demo mode: Simulated UPI Scanner',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'No real money will be transferred. Payment rails connect in Phase 5.2.',
                      style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Mode Switcher: Camera Scanner vs Manual/Sample Input
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
                      label: const Center(child: Text('Manual / Sample')),
                      selected: !_isCameraMode,
                      selectedColor: const Color(0xFF0D6548),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: !_isCameraMode ? Colors.white : AppColors.textDark,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() => _isCameraMode = false);
                          _parseQr(_qrInputController.text);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Scanner or Input Body
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
              ] else ...[
                // Manual text field and sample buttons
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
                const SizedBox(height: 10),
                const Text(
                  'Quick test presets:',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.agriculture_outlined, size: 14),
                      label: const Text('Farm Produce (₹450)'),
                      onPressed: () => _loadSampleUri(
                        'upi://pay?pa=farmer.suresh@upi&pn=Suresh%20Agri%20Produce&am=450.00&cu=INR&tn=Fresh%20Tomatoes',
                      ),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.handyman_outlined, size: 14),
                      label: const Text('Worker Wage (₹750)'),
                      onPressed: () => _loadSampleUri(
                        'upi://pay?pa=electrician.ramesh@okaxis&pn=Ramesh%20Kumar&am=750.00&cu=INR&tn=Electrical%20Repair%20Wage',
                      ),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.shield_outlined, size: 14),
                      label: const Text('Job Escrow (₹1,200)'),
                      onPressed: () => _loadSampleUri(
                        'upi://pay?pa=udyoga.escrow@icici&pn=UdyogaSethu%20Escrow&am=1200.00&cu=INR&tn=Job%20Booking%20Escrow',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // Parse Error or Parsed Card
              if (_parseError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDC2626)),
                  ),
                  child: Text(
                    _parseError!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                  ),
                ),
                const SizedBox(height: 14),
              ] else if (_parsedData != null) ...[
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
                            'Parsed UPI Target',
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
                              'Verified Format',
                              style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      _detailRow('Recipient Name', _parsedData!.payeeName ?? 'Not specified'),
                      const SizedBox(height: 5),
                      _detailRow('UPI ID (VPA)', _parsedData!.payeeVpa),
                      const SizedBox(height: 5),
                      _detailRow('Amount', _parsedData!.formattedAmount),
                      if (_parsedData!.transactionNote != null) ...[
                        const SizedBox(height: 5),
                        _detailRow('Note', _parsedData!.transactionNote!),
                      ],
                      const SizedBox(height: 10),
                      if (_validationStatus != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF00875A)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _validationStatus!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF00875A),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            side: const BorderSide(color: Color(0xFF0D6548)),
                          ),
                          icon: _isValidating
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D6548)),
                                )
                              : const Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF0D6548)),
                          label: Text(
                            _isValidating ? 'Validating VPA...' : 'Validate VPA with NPCI Gateway',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D6548)),
                          ),
                          onPressed: _isValidating ? null : _simulateValidateVpa,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Close Button
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
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
