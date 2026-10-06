import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/privacy/domain/consent_purpose.dart';
import 'package:udyogasethu/features/privacy/presentation/consent_sheet.dart';
import 'package:udyogasethu/features/trust/data/kyc_repository.dart';
import 'package:udyogasethu/features/trust/domain/kyc_record.dart';

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  String _selectedDocType = 'aadhaar';
  bool _isLoading = false;
  String? _statusMessage;
  String? _currentProviderRef;

  String _getUserId() {
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client.auth.currentUser?.id ?? 'demo_user_123';
      }
    } catch (_) {}
    return 'demo_user_123';
  }

  @override
  Widget build(BuildContext context) {
    final userId = _getUserId();

    final repo = ref.watch(kycRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Identity (eKYC)', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: StreamBuilder<KycRecord?>(
        stream: repo.watchKycRecord(userId, docType: _selectedDocType),
        builder: (context, snapshot) {
          final kycRecord = snapshot.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mandatory Honesty Rule Demo Mode Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.bug_report_rounded, color: Colors.amber, size: 24),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Demo Mode — Simulated eKYC Provider',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Verification runs in simulated sandbox mode. No live government servers are contacted.',
                              style: TextStyle(fontSize: 11, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Document Selection Card
                Card(
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Document Type',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedDocType,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'aadhaar', child: Text('Aadhaar Card (DigiLocker eKYC)')),
                            DropdownMenuItem(value: 'pan', child: Text('PAN Card')),
                            DropdownMenuItem(value: 'driving_licence', child: Text('Driving Licence')),
                            DropdownMenuItem(value: 'voter_id', child: Text('Voter ID Card')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedDocType = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Verification Result Card or Initiate Button
                if (kycRecord != null && kycRecord.isVerified)
                  _buildVerifiedResultCard(kycRecord)
                else ...[
                  Card(
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.headerGreenDark.withAlpha(25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.verified_user_rounded, color: AppColors.headerGreenDark),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Instant eKYC Verification',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Verify using DigiLocker to earn the UdyogaSethu Verified Badge.',
                                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(color: AppColors.headerGreenDark),
                              ),
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.headerGreenDark,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => _startKycFlow(context),
                                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                                label: const Text(
                                  'Verify via DigiLocker / KYC Provider',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          if (_statusMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _statusMessage!,
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                const Text(
                  'Privacy & Masking Guarantee',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your 12-digit Aadhaar number is never stored, displayed, or logged. Only a masked reference (e.g. XXXX-XXXX-4321) and verified badge status are retained on our servers.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.push(AppRoutes.trustSafetyCentre),
                    icon: const Icon(Icons.shield_outlined, size: 16),
                    label: const Text('Learn more in Trust & Safety Centre', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

  Widget _buildVerifiedResultCard(KycRecord record) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.green, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Verification Complete',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: const Text(
                    'VERIFIED ✓',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildResultRow('Document Type', record.docType.toUpperCase()),
            _buildResultRow('Masked ID', record.maskedId ?? 'XXXX-XXXX-4321'),
            _buildResultRow('Name on Record', record.nameMasked ?? 'R***** S****'),
            _buildResultRow(
              'Verified On',
              record.verifiedAt != null
                  ? record.verifiedAt!.toLocal().toString().split(' ').first
                  : DateTime.now().toString().split(' ').first,
            ),
            _buildResultRow('Provider', record.provider.toUpperCase()),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        ],
      ),
    );
  }

  Future<void> _startKycFlow(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    // 1. Enforce Just-In-Time Consent
    final hasConsent = await requireConsent(context, ref, ConsentPurpose.kyc);
    if (!mounted) return;

    if (!hasConsent) {
      messenger.showSnackBar(
        const SnackBar(content: Text('KYC verification consent is required to proceed.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Connecting to KYC Provider...';
    });

    try {
      final repo = ref.read(kycRepositoryProvider);
      final session = await repo.startKycSession(
        docType: _selectedDocType,
        redirectUrl: 'udyogasethu://kyc/callback',
      );

      _currentProviderRef = session['provider_ref'] as String?;

      if (mounted) {
        setState(() {
          _statusMessage = 'Redirecting to DigiLocker verification window...';
        });
      }

      // 2. Simulate browser redirect & callback completion
      await Future.delayed(const Duration(milliseconds: 1200));
      if (_currentProviderRef != null) {
        await repo.simulateCallback(
          providerRef: _currentProviderRef!,
          docType: _selectedDocType,
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Identity verification completed successfully!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Verification error: $e';
        });
      }
    }
  }
}
