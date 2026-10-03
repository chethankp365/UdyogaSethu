import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/privacy/data/consent_repository.dart';
import 'package:udyogasethu/features/privacy/domain/consent_purpose.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class ConsentPurposeDetails {
  final String title;
  final IconData icon;
  final String what;
  final String why;
  final String howLong;
  final String whoCanSee;
  final String howToWithdraw;

  const ConsentPurposeDetails({
    required this.title,
    required this.icon,
    required this.what,
    required this.why,
    required this.howLong,
    required this.whoCanSee,
    required this.howToWithdraw,
  });

  static ConsentPurposeDetails getDetails(ConsentPurpose purpose) {
    switch (purpose) {
      case ConsentPurpose.kyc:
        return const ConsentPurposeDetails(
          title: 'Identity Verification (KYC)',
          icon: Icons.verified_user_rounded,
          what: 'Government ID details (Aadhaar / Driving Licence / Voter ID) and verification status.',
          why: 'To verify worker/provider authenticity and issue the UdyogaSethu Verified Badge for safe hiring.',
          howLong: 'Retained securely during active account tenure for legal compliance.',
          whoCanSee: 'Masked status (Verified / Unverified) is visible to employers. Raw ID numbers are encrypted and never shown publicly.',
          howToWithdraw: 'You can withdraw KYC consent from Privacy Centre or by closing your account.',
        );
      case ConsentPurpose.face:
        return const ConsentPurposeDetails(
          title: 'Face Verification & Liveness',
          icon: Icons.face_rounded,
          what: 'On-device camera photo and facial template vector representation.',
          why: 'To enable passwordless face-verified login and prevent impersonation during job check-in.',
          howLong: 'Facial reference vector is kept until you withdraw consent or delete your account.',
          whoCanSee: 'Strictly encrypted and processed locally/in secure enclave. Photos are never shared with employers.',
          howToWithdraw: 'You can tap "Withdraw Consent" in Privacy Centre anytime to permanently erase your face reference vector.',
        );
      case ConsentPurpose.gps:
        return const ConsentPurposeDetails(
          title: 'GPS Location Services',
          icon: Icons.location_on_rounded,
          what: 'Real-time or approximate device GPS coordinates.',
          why: 'To show nearby job matches, site delivery addresses, and route ETAs.',
          howLong: 'Location coordinates are used transiently during active sessions and not tracked in background when app is closed.',
          whoCanSee: 'Approximate distance (e.g. 2.5 km away) is visible to job parties. Exact address is only shared upon confirmed booking.',
          howToWithdraw: 'Toggle off location access in Privacy Centre or in device System Settings.',
        );
      case ConsentPurpose.notifications:
        return const ConsentPurposeDetails(
          title: 'Push Notifications',
          icon: Icons.notifications_active_rounded,
          what: 'Device notification token and message alert preferences.',
          why: 'To alert you instantly about job applications, worker arrivals, payment updates, and safety alerts.',
          howLong: 'Active token is stored while logged in.',
          whoCanSee: 'Only sent directly to your registered device.',
          howToWithdraw: 'Turn off notification alerts in Privacy Centre or System Settings anytime.',
        );
      case ConsentPurpose.ads:
        return const ConsentPurposeDetails(
          title: 'Relevant Banners & Schemes',
          icon: Icons.campaign_rounded,
          what: 'General role classification and district location.',
          why: 'To show relevant government welfare schemes, skill training opportunities, and sponsored banners.',
          howLong: 'Stored as part of active profile preferences.',
          whoCanSee: 'Aggregated non-personal statistics only.',
          howToWithdraw: 'Opt out of personalized promotional content in Privacy Centre.',
        );
    }
  }
}

/// Helper function that enforces just-in-time consent before starting sensitive flows.
Future<bool> requireConsent(
  BuildContext context,
  WidgetRef ref,
  ConsentPurpose purpose,
) async {
  final repo = ref.read(consentRepositoryProvider);
  final hasConsent = await repo.hasValidConsent(purpose);
  if (hasConsent) return true;

  if (!context.mounted) return false;
  final result = await ConsentSheet.show(context, purpose);
  return result ?? false;
}

class ConsentSheet extends ConsumerStatefulWidget {
  final ConsentPurpose purpose;

  const ConsentSheet({super.key, required this.purpose});

  static Future<bool?> show(BuildContext context, ConsentPurpose purpose) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ConsentSheet(purpose: purpose),
    );
  }

  @override
  ConsumerState<ConsentSheet> createState() => _ConsentSheetState();
}

class _ConsentSheetState extends ConsumerState<ConsentSheet> {
  bool _isSaving = false;

  Future<void> _handleAgree() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(consentRepositoryProvider).recordConsent(
        purpose: widget.purpose,
        granted: true,
        metadata: {
          'granted_at': DateTime.now().toIso8601String(),
          'version': '1.0',
          'source': 'JIT_ConsentSheet',
        },
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pop(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final details = ConsentPurposeDetails.getDetails(widget.purpose);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.headerGreenDark.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(details.icon, color: AppColors.headerGreenDark, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.consentSheetTitle ?? 'Data Processing Consent',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        details.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),

            _buildSection(
              title: l10n?.consentWhatCollected ?? 'What is collected',
              content: details.what,
              icon: Icons.checklist_rounded,
            ),
            _buildSection(
              title: l10n?.consentWhyCollected ?? 'Why it is collected',
              content: details.why,
              icon: Icons.help_outline_rounded,
            ),
            _buildSection(
              title: l10n?.consentHowLongKept ?? 'How long it is kept',
              content: details.howLong,
              icon: Icons.access_time_rounded,
            ),
            _buildSection(
              title: l10n?.consentWhoCanSee ?? 'Who can see it',
              content: details.whoCanSee,
              icon: Icons.visibility_outlined,
            ),
            _buildSection(
              title: l10n?.consentHowToWithdraw ?? 'How to withdraw',
              content: details.howToWithdraw,
              icon: Icons.assignment_return_outlined,
            ),

            const SizedBox(height: 16),
            if (_isSaving)
              const Center(child: CircularProgressIndicator(color: AppColors.headerGreenDark))
            else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.headerGreenDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _handleAgree,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    l10n?.consentAgreeButton ?? 'I Agree & Consent',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    l10n?.consentNotNowButton ?? 'Not Now',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.headerGreenDark),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
