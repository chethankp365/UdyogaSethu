import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/trust/data/kyc_repository.dart';
import 'package:udyogasethu/features/trust/domain/kyc_record.dart';

class BackgroundCheckScreen extends ConsumerStatefulWidget {
  const BackgroundCheckScreen({super.key});

  @override
  ConsumerState<BackgroundCheckScreen> createState() => _BackgroundCheckScreenState();
}

class _BackgroundCheckScreenState extends ConsumerState<BackgroundCheckScreen> {
  bool _isRequesting = false;
  String? _errorMessage;

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
      backgroundColor: AppColors.navyBackground,
      appBar: AppBar(
        backgroundColor: AppColors.navyCard,
        title: const Text('Background Verification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<KycRecord?>(
        stream: repo.watchKycRecord(userId, docType: 'background_check'),
        builder: (context, snapshot) {
          final kycRecord = snapshot.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.navyCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.navyBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_rounded, color: AppColors.emerald, size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Background Verification (Sensitive Roles)',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Verified background check unlocks high-trust home-service and elderly-care jobs flagged as verified_only.',
                              style: TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Live Status Card
                _buildStatusCard(kycRecord),
                const SizedBox(height: 16),

                // Request or Re-request button
                if (kycRecord == null || kycRecord.isNotRequested || kycRecord.isRejected)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.navyCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.navyBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Request Agency Background Check',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Agency review includes police record verification and criminal history check.',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        if (_isRequesting) ...[
                          const LinearProgressIndicator(color: AppColors.amberOrange, backgroundColor: AppColors.navyCardSecondary),
                          const SizedBox(height: 10),
                        ],
                        if (_errorMessage != null) ...[
                          Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
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
                            onPressed: _isRequesting ? null : _requestCheck,
                            icon: const Icon(Icons.security_rounded, size: 18),
                            label: const Text('Request Background Check', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(KycRecord? record) {
    String status = 'Not Requested';
    Color color = Colors.grey;
    IconData icon = Icons.shield_outlined;
    String desc = 'Background check has not been initiated.';

    if (record != null) {
      final s = record.status.toLowerCase();
      if (s == 'verified') {
        status = 'Verified ✓';
        color = AppColors.emerald;
        icon = Icons.check_circle_rounded;
        desc = 'Worker identity & background check verified successfully.';
      } else if (s == 'pending') {
        status = 'Pending Agency Review';
        color = AppColors.amberOrange;
        icon = Icons.hourglass_top_rounded;
        desc = 'Background check request submitted. Review in progress.';
      } else if (s == 'review_required') {
        status = 'Review Required';
        color = Colors.orangeAccent;
        icon = Icons.rate_review_rounded;
        desc = 'Additional documentation required by review team.';
      } else if (s == 'failed' || s == 'rejected') {
        status = 'Failed';
        color = AppColors.errorRed;
        icon = Icons.cancel_rounded;
        desc = record.rejectionReason ?? 'Background check did not clear review requirements.';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(180)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(width: 10),
              Text(
                'Status: $status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }

  Future<void> _requestCheck() async {
    setState(() {
      _isRequesting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(kycRepositoryProvider);
      await repo.requestBackgroundCheck();

      setState(() => _isRequesting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Background check request submitted successfully.')),
        );
      }
    } catch (e) {
      setState(() {
        _isRequesting = false;
        _errorMessage = 'Request failed: $e';
      });
    }
  }
}
