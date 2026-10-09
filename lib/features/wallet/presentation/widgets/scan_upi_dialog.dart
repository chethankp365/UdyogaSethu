import 'package:flutter/material.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/wallet/domain/upi_payment_data.dart';

class ScanUpiDialog extends StatefulWidget {
  const ScanUpiDialog({super.key});

  @override
  State<ScanUpiDialog> createState() => _ScanUpiDialogState();
}

class _ScanUpiDialogState extends State<ScanUpiDialog> {
  final TextEditingController _qrInputController = TextEditingController();
  UpiPaymentData? _parsedData;
  String? _parseError;

  @override
  void initState() {
    super.initState();
    // Default sample for immediate interactive test
    _loadSampleUri('upi://pay?pa=farmer.suresh@upi&pn=Suresh%20Agri%20Produce&am=450.00&cu=INR&tn=Fresh%20Tomatoes');
  }

  @override
  void dispose() {
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
    });

    final data = UpiPaymentData.parse(rawText);
    if (!data.isValid) {
      setState(() {
        _parsedData = null;
        _parseError = 'Invalid UPI QR code. Must be a valid upi://pay URI with payee address (pa).';
      });
    } else {
      setState(() {
        _parsedData = data;
        _parseError = null;
      });
    }
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
              const SizedBox(height: 16),

              // QR Code / Text Input
              const Text(
                'UPI QR Payload / String',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _qrInputController,
                onChanged: _parseQr,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'upi://pay?pa=recipient@bank&pn=Name&am=...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 10),

              // Quick Sample Buttons
              const Text(
                'Tap sample QR code:',
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
              const SizedBox(height: 16),

              // Error or Parsed Card
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
                const SizedBox(height: 16),
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
                            'Parsed UPI Payment Target',
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
                              'Verified URI',
                              style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 18),
                      _detailRow('Recipient Name', _parsedData!.payeeName ?? 'Not specified'),
                      const SizedBox(height: 6),
                      _detailRow('UPI ID (VPA)', _parsedData!.payeeVpa),
                      const SizedBox(height: 6),
                      _detailRow('Amount', _parsedData!.formattedAmount),
                      if (_parsedData!.transactionNote != null) ...[
                        const SizedBox(height: 6),
                        _detailRow('Purpose / Note', _parsedData!.transactionNote!),
                      ],
                      const SizedBox(height: 6),
                      _detailRow('Currency', _parsedData!.currency),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Close / Done Button
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
                    'Close UPI Scanner Preview',
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
