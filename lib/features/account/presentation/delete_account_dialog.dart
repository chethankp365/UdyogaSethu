import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/account/presentation/role_switcher_bottom_sheet.dart';

class DeleteAccountDialog extends ConsumerStatefulWidget {
  const DeleteAccountDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const DeleteAccountDialog(),
    );
  }

  @override
  ConsumerState<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  int _confirmationStep = 1;
  final _otpController = TextEditingController();
  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _executeDeletion() async {
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(accountRepositoryProvider).deleteAccount();
      ref.read(appSessionProvider.notifier).setSessionStatus(AuthSessionStatus.signedOut);

      if (mounted) {
        Navigator.of(context).pop();
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _errorMessage = 'Failed to delete account: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.delete_forever_rounded, color: AppColors.errorRed),
          SizedBox(width: 8),
          Text('Delete My Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.errorRed)),
        ],
      ),
      content: _isDeleting
          ? const SizedBox(
              height: 120,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.errorRed),
                    SizedBox(height: 12),
                    Text('Erasing personal files and account data...'),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_confirmationStep == 1) ...[
                    const Text(
                      'Are you sure you want to delete your account?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This action cannot be undone. All profile photos, documents, addresses, and account details will be permanently erased.',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Legal Retention Notice: Financial ledger entries and payment audit records are retained in anonymized format as required by RBI/GST laws.',
                              style: TextStyle(fontSize: 11, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Final Confirmation (Step 2 of 2)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.errorRed),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please enter your 6-digit verification code or type "DELETE" to confirm permanent account deletion:',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _otpController,
                      decoration: InputDecoration(
                        hintText: 'Enter code or DELETE',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(_errorMessage!, style: const TextStyle(color: AppColors.errorRed, fontSize: 12)),
                  ],
                ],
              ),
            ),
      actions: [
        if (!_isDeleting) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (_confirmationStep == 1)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed, foregroundColor: Colors.white),
              onPressed: () {
                setState(() => _confirmationStep = 2);
              },
              child: const Text('Proceed to Confirm'),
            )
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed, foregroundColor: Colors.white),
              onPressed: _executeDeletion,
              child: const Text('Permanently Delete'),
            ),
        ],
      ],
    );
  }
}
