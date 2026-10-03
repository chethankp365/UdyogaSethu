import 'package:flutter/material.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.termsAndPrivacyTitle ?? 'Terms & Privacy Policy',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mandatory Draft Warning Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade400),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n?.termsDraftNotice ?? 'Draft - Have this reviewed before real launch',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              '1. Introduction & Acceptance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            const Text(
              'UdyogaSethu provides a verified, AI-assisted work and produce marketplace connecting job seekers, job providers, and farmers across India. By creating an account or using our platform, you agree to these Terms of Service.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 16),

            const Text(
              '2. One Account = One Role Policy',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            const Text(
              'A registered phone number or Google account is bound to a single active role (Job Seeker, Job Provider, or Farmer). To switch to a different primary role, you must delete your active account in Settings and re-register under the new role.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 16),

            const Text(
              '3. Digital Personal Data Protection (DPDP) Compliance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            const Text(
              'We collect personal data (identity records, photos, location coordinates) strictly on a just-in-time consent basis. You have the right to inspect, manage, and withdraw your consent anytime via the Privacy Centre.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 16),

            const Text(
              '4. Financial Audit & Legal Data Retention',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            const Text(
              'Account deletion erases your profile photos, address records, and personal identifiers. To comply with Indian tax and financial audit laws (RBI/GST regulations), payment transactions and ledger audit logs are retained in anonymized format.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
