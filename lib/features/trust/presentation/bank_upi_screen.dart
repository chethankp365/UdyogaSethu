import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/trust/data/kyc_repository.dart';
import 'package:udyogasethu/features/trust/domain/kyc_record.dart';

class BankUpiScreen extends ConsumerStatefulWidget {
  const BankUpiScreen({super.key});

  @override
  ConsumerState<BankUpiScreen> createState() => _BankUpiScreenState();
}

class _BankUpiScreenState extends ConsumerState<BankUpiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _upiController = TextEditingController();
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();

  int _selectedTab = 0; // 0 = UPI, 1 = Bank Account
  bool _isProcessing = false;
  String? _statusMessage;

  String _getUserId() {
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client.auth.currentUser?.id ?? 'demo_user_123';
      }
    } catch (_) {}
    return 'demo_user_123';
  }

  @override
  void dispose() {
    _upiController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _getUserId();
    final repo = ref.watch(kycRepositoryProvider);
    final docType = _selectedTab == 0 ? 'upi' : 'bank_account';

    return Scaffold(
      backgroundColor: AppColors.navyBackground,
      appBar: AppBar(
        backgroundColor: AppColors.navyCard,
        title: const Text('Bank & UPI Payout Verification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<KycRecord?>(
        stream: repo.watchKycRecord(userId, docType: docType),
        builder: (context, snapshot) {
          final kycRecord = snapshot.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Honesty Rule Demo Mode Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade900.withAlpha(120),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.currency_rupee_rounded, color: Colors.amber, size: 24),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Demo Mode — Simulated Penny-Drop Verification',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Verification performs a simulated ₹1 deposit to test payout routing until a live payout gateway is configured.',
                              style: TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Method Selector Tabs
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.navyCardSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0 ? AppColors.headerGreenDark : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text('UPI ID (Instant)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1 ? AppColors.headerGreenDark : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text('Bank Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (kycRecord != null && kycRecord.isVerified)
                  _buildVerifiedCard(kycRecord)
                else
                  _buildFormCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.navyBorder),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedTab == 0 ? 'Enter UPI VPA for Payouts' : 'Enter Bank Account & IFSC',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 14),

            if (_selectedTab == 0) ...[
              TextFormField(
                controller: _upiController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'UPI VPA (e.g. mobile@okaxis or name@upi)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: AppColors.navyCardSecondary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'UPI ID is required';
                  if (!val.contains('@')) return 'Enter a valid UPI ID (e.g. user@upi)';
                  return null;
                },
              ),
            ] else ...[
              TextFormField(
                controller: _accountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Bank Account Number',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: AppColors.navyCardSecondary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Account number is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ifscController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'IFSC Code (e.g. SBIN0001234)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: AppColors.navyCardSecondary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'IFSC code is required' : null,
              ),
            ],

            const SizedBox(height: 16),

            if (_isProcessing) ...[
              const Center(child: CircularProgressIndicator(color: AppColors.amberOrange)),
              const SizedBox(height: 10),
            ],

            if (_statusMessage != null) ...[
              Text(_statusMessage!, style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic)),
              const SizedBox(height: 10),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.headerGreenDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isProcessing ? null : _submitPennyDrop,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(
                  _selectedTab == 0 ? 'Verify UPI via Demo Penny-Drop' : 'Verify Bank Account via Demo Penny-Drop',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedCard(KycRecord record) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade500),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
              SizedBox(width: 10),
              Text('Payout Method Verified', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const Divider(color: AppColors.navyBorder, height: 20),
          _buildRow('Type', record.docType.toUpperCase()),
          _buildRow('Masked Details', record.maskedId ?? 'XXXX-XXXX-5678'),
          _buildRow('Status', 'VERIFIED ✓ (Penny-Drop Test Succeeded)'),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _submitPennyDrop() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Initiating ₹1 Penny-Drop verification...';
    });

    try {
      await Future.delayed(const Duration(milliseconds: 1200));

      final repo = ref.read(kycRepositoryProvider);
      final type = _selectedTab == 0 ? 'upi' : 'bank_account';
      final val = _selectedTab == 0 ? _upiController.text.trim() : _accountController.text.trim();

      await repo.submitBankUpi(
        type: type,
        value: val,
        ifsc: _selectedTab == 1 ? _ifscController.text.trim() : null,
      );

      setState(() {
        _isProcessing = false;
        _statusMessage = 'Penny-Drop verified successfully!';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payout destination verified successfully.')),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Verification error: $e';
      });
    }
  }
}
