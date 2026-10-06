import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';

class TrustGovernanceRightsScreen extends StatelessWidget {
  const TrustGovernanceRightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trust, Governance & Rights', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blueGrey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.gavel_rounded, color: Colors.blueGrey.shade800, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Governance Framework & Rights Charter',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueGrey.shade900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'UdyogaSethu operates with strict adherence to the Digital Personal Data Protection Act (DPDP), statutory Aadhaar guidelines, and worker protection standards.',
                    style: TextStyle(fontSize: 12, color: AppColors.textDark, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 1. Biometric Consent
            _buildArticle(
              title: '1. Voluntary Biometric & Face Consent',
              content:
                  'Face enrollment is voluntary and strictly used to verify that the person undertaking the shift matches the registered credential. The app processes images locally to produce a 128-float32 mathematical vector. Raw face photos are immediately erased. Users hold the absolute right to revoke biometric consent at any time via Privacy Centre, which permanently deletes their reference vector from our servers.',
            ),
            const SizedBox(height: 14),

            // 2. Privacy & Data Minimization
            _buildArticle(
              title: '2. Privacy & Data Minimization Principles',
              content:
                  'We practice radical data minimization. When an employer or customer scans your Digital ID QR code, they receive only your name initial (e.g. "C."), public ID (e.g. "UDY2026xxxx"), verified badge status, skill level, and verification timestamps. Your mobile phone number, residential address, family details, and real government ID numbers are never accessible to scanners.',
            ),
            const SizedBox(height: 14),

            // 3. KYC Limits & Aadhaar/DigiLocker Rules
            _buildArticle(
              title: '3. KYC Limits & Statutory Aadhaar Safeguards',
              content:
                  'Aadhaar eKYC is conducted exclusively via MeitY-approved DigiLocker endpoints. In compliance with the Aadhaar Act and Supreme Court rulings:\n'
                  '• We never store, display, or transmit your 12-digit Aadhaar number.\n'
                  '• Only masked strings (e.g. XXXX-XXXX-4321) and a provider transaction reference are kept.\n'
                  '• Aadhaar details are never shared with prospective employers or job providers.',
            ),
            const SizedBox(height: 14),

            // 4. How to Report Fraud & Abuse
            _buildArticle(
              title: '4. How to Report Issues & Platform Abuse',
              content:
                  'If you experience unsafe work conditions, wage withholding, verbal misconduct, or fraudulent job listings:\n'
                  '• Tap "Dispute" on any active or completed job screen.\n'
                  '• Tap the emergency SOS button on the header for imminent physical danger.\n'
                  '• Email support directly or call the regional grievance coordinator.',
            ),
            const SizedBox(height: 14),

            // 5. Grievance Support Contact
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.support_agent_rounded, color: AppColors.amberOrange, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        '5. Grievance Redressal Officer Contact',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber.shade900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Designated Grievance Officer: Mr. R. Narayana Swamy\n'
                    'Official Email: grievance@udyogasethu.in\n'
                    'Toll-Free Helpline: 1800-425-UDYOGA (1800-425-8396)\n'
                    'National Cyber Fraud Helpline: 1930\n'
                    'Women Safety Helpline: 181\n'
                    'Response Time: Acknowledgement within 24 hours; resolution within 15 days.',
                    style: TextStyle(fontSize: 12, height: 1.45, color: AppColors.textDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 6. Suspension Rules & Criteria
            _buildArticle(
              title: '6. Suspension Rules & Zero-Tolerance Violations',
              content:
                  'To protect the community, account privileges may be suspended under the following conditions:\n'
                  '• Repeated Face Verification Failures (3 consecutive mismatches trigger automated fraud flags).\n'
                  '• Substance abuse or harassment reported on job sites.\n'
                  '• Unilateral abandonment of accepted work shifts without notice.\n'
                  '• Off-platform payment coercion or fee skimming.',
            ),
            const SizedBox(height: 14),

            // 7. User Rights & Appeals Process
            _buildArticle(
              title: '7. Worker Rights, Data Erasure & Appeal Process',
              content:
                  'Every worker has the right to a fair hearing. If your account is flagged or suspended:\n'
                  '1. You will receive an on-screen notice explaining the flagged rule.\n'
                  '2. You can request a "Manual Human Review" directly from the verification screen.\n'
                  '3. You may submit an appeal statement with supporting evidence.\n'
                  '4. Under Platform Decision D11, you may delete your profile and account at any time. Financial and legal dispute audit records are retained exclusively for the statutory retention duration before cryptographic anonymization.',
            ),
            const SizedBox(height: 24),

            // Quick navigation to Privacy Centre
            Center(
              child: TextButton.icon(
                onPressed: () => context.push(AppRoutes.privacyCentre),
                icon: const Icon(Icons.shield_outlined),
                label: const Text('Visit Privacy Centre & Consent Controls'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildArticle({required String title, required String content}) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              content,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
