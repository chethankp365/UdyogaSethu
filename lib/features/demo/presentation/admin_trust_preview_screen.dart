import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';
import 'package:udyogasethu/core/widgets/app_button.dart';

/// Screen demonstrating seeded review/dispute state for Scenario 5 (P10.1).
/// Explains that Admin Console actions occur in the separate Admin project.
class AdminTrustPreviewScreen extends ConsumerWidget {
  const AdminTrustPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Admin Trust Review State'),
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade400,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'DEMO MODE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Mandatory Architectural Boundary Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.shade400, width: 1.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.admin_panel_settings_rounded, color: Colors.amber.shade900, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Separate Admin Console Notice',
                          style: AppTypography.titleSmall(Colors.amber.shade900).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'In UdyogaSethu architecture, the Admin Console is built in a separate web/desktop project. This mobile application displays read-only status. All admin dispute mediation, document verification, and refund resolutions execute exclusively in the separate Admin workspace.',
                          style: TextStyle(fontSize: 12, color: Colors.amber.shade900, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Seeded Dispute Case Item
            Text(
              'SEEDED DISPUTE RECORD (FROZEN ESCROW)',
              style: AppTypography.label(AppColors.textMuted).copyWith(
                fontSize: 11,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Text(
                          'CASE #DSP-2026-004',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_clock_rounded, size: 14, color: Colors.orange.shade800),
                            const SizedBox(width: 4),
                            Text(
                              'ESCROW FROZEN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Arrival Time Window & Scope Dispute',
                    style: AppTypography.titleMedium(AppColors.textDark).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Employer (Suresh Sai) reported worker arrival delayed by 50 mins; Worker (Ramesh Kumar) uploaded GPS selfie proof of arrival within building security zone.',
                    style: AppTypography.bodySmall(AppColors.textMuted).copyWith(height: 1.4),
                  ),
                  const Divider(height: 24),
                  const Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _DisputePill(label: 'Held Escrow', value: '₹850.00'),
                      _DisputePill(label: 'Reported', value: '2 hours ago'),
                      _DisputePill(label: 'Audit Status', value: 'Pending Admin Review'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 20, color: Color(0xFF475569)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Automatic Protection: Neither party can withdraw funds until the external safety board completes evidence review.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Seeded Unverified Micro-Credential
            Text(
              'SEEDED EXTERNAL CREDENTIAL AUDIT',
              style: AppTypography.label(AppColors.textMuted).copyWith(
                fontSize: 11,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.card_membership_rounded, color: AppColors.primaryTeal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ITI Electrical Wireman License',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.amber.shade300),
                              ),
                              child: Text(
                                'Pending Admin Review',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Uploaded by Ramesh Kumar · Issued by Directorate of Vocational Training Karnataka. Displays unverified badge until verified in external Admin Console.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 4. Return to Scenarios CTA
            AppButton(
              label: 'Return to Demo Scenarios',
              icon: Icons.check_circle_outline,
              onPressed: () => context.pop(),
              variant: AppButtonVariant.primary,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _DisputePill extends StatelessWidget {
  final String label;
  final String value;

  const _DisputePill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }
}
