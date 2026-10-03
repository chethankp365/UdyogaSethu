import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/privacy/data/consent_repository.dart';
import 'package:udyogasethu/features/privacy/domain/consent_purpose.dart';
import 'package:udyogasethu/features/privacy/presentation/consent_sheet.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class PrivacyCentreScreen extends ConsumerStatefulWidget {
  const PrivacyCentreScreen({super.key});

  @override
  ConsumerState<PrivacyCentreScreen> createState() => _PrivacyCentreScreenState();
}

class _PrivacyCentreScreenState extends ConsumerState<PrivacyCentreScreen> {
  bool _isLoading = true;
  Map<ConsentPurpose, ConsentLog?> _consents = {};

  @override
  void initState() {
    super.initState();
    _loadConsents();
  }

  Future<void> _loadConsents() async {
    setState(() => _isLoading = true);
    final data = await ref.read(consentRepositoryProvider).getAllConsents();
    if (mounted) {
      setState(() {
        _consents = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleWithdraw(ConsentPurpose purpose) async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(consentRepositoryProvider);

    if (purpose == ConsentPurpose.face) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            l10n?.withdrawFaceConsentTitle ?? 'Withdraw Face Verification Consent?',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Text(
            l10n?.withdrawFaceConsentMessage ??
                'Withdrawing face consent will permanently erase your face reference vector and matcher records.',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n?.cancelButton ?? 'Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n?.confirmWithdrawButton ?? 'Withdraw & Erase Data'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await repo.withdrawFaceConsent();
        await _loadConsents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Face verification reference data erased.')),
          );
        }
      }
    } else {
      await repo.revokeConsent(purpose);
      await _loadConsents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Consent for ${purpose.name.toUpperCase()} revoked.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.privacyCentreTitle ?? 'Privacy Centre', style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.headerGreenDark))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.headerGreenDark.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.headerGreenDark.withAlpha(50)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.privacy_tip_rounded, color: AppColors.headerGreenDark, size: 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.privacyCentreTitle ?? 'Privacy Centre',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n?.privacyCentreSubtitle ??
                                    'Manage your data consents, privacy rights, and system permissions in accordance with DPDP rules.',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Active Data Consents',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 12),

                  ...ConsentPurpose.values.map((purpose) {
                    final log = _consents[purpose];
                    final isGranted = log?.granted ?? false;
                    final details = ConsentPurposeDetails.getDetails(purpose);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(details.icon, color: isGranted ? AppColors.headerGreenDark : AppColors.textMuted),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    details.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isGranted ? Colors.green.shade50 : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isGranted ? Colors.green.shade300 : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    isGranted
                                        ? (l10n?.consentGrantedStatus ?? 'Granted')
                                        : (l10n?.consentRevokedStatus ?? 'Not Granted'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isGranted ? Colors.green.shade800 : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              details.why,
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            if (log?.timestamp != null && isGranted) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Granted on: ${log!.timestamp.toLocal().toString().split('.').first}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () async {
                                    final res = await ConsentSheet.show(context, purpose);
                                    if (res == true) {
                                      await _loadConsents();
                                    }
                                  },
                                  icon: const Icon(Icons.info_outline_rounded, size: 16),
                                  label: const Text('View Terms', style: TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                if (isGranted)
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.errorRed,
                                      side: const BorderSide(color: AppColors.errorRed),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                    onPressed: () => _handleWithdraw(purpose),
                                    icon: const Icon(Icons.block_rounded, size: 16),
                                    label: Text(
                                      l10n?.withdrawConsentButton ?? 'Withdraw Consent',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),
                  Text(
                    l10n?.systemPermissionsTitle ?? 'System Permissions',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.tune_rounded, color: AppColors.headerGreenDark),
                      title: Text(l10n?.openSystemSettings ?? 'Open App Settings'),
                      subtitle: const Text('Manage camera, location, and notification OS toggles.', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening system settings preview...')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
