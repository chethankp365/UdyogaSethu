import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/compact_language_selector.dart';
import 'package:udyogasethu/features/account/domain/linked_accounts_state.dart';
import 'package:udyogasethu/features/account/presentation/role_switcher_bottom_sheet.dart';

final linkedAccountsProvider = FutureProvider<LinkedAccountsState>((ref) async {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.getLinkedAccounts();
});

class LinkedAccountsScreen extends ConsumerWidget {
  const LinkedAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(linkedAccountsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Linked Sign-in Accounts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: const [
          CompactLanguageSelector(),
          SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(linkedAccountsProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: stateAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading account status: $err')),
            data: (state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage Authentication Methods',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'You can use any linked method to log into your UdyogaSethu account.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 20),

                  // 1. MOBILE PHONE NUMBER TILE
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: AppColors.paleMint,
                                child: Icon(Icons.phone_android_rounded, color: AppColors.headerGreenDark),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Mobile Phone Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text(
                                      state.phone != null && state.phone!.isNotEmpty
                                          ? state.phone!
                                          : 'No phone linked',
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              if (state.isPhoneVerified)
                                const Chip(
                                  avatar: Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                                  label: Text('Verified'),
                                  backgroundColor: AppColors.headerGreenDark,
                                  labelStyle: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Worker and farmer accounts require a verified phone number for identity trust.',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. GOOGLE ACCOUNT TILE
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Colors.redAccent,
                                child: Icon(Icons.g_mobiledata_rounded, color: Colors.white, size: 30),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Google Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text(
                                      state.isGoogleLinked && state.googleEmail != null
                                          ? state.googleEmail!
                                          : 'Not linked',
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              if (state.isGoogleLinked)
                                const Chip(
                                  avatar: Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                                  label: Text('Linked'),
                                  backgroundColor: AppColors.headerGreenDark,
                                  labelStyle: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (!state.isGoogleLinked) ...[
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.headerGreenDark),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Google Account linking initiated.')),
                                );
                              },
                              icon: const Icon(Icons.add_rounded, color: AppColors.headerGreenDark),
                              label: const Text('Link Google Account', style: TextStyle(color: AppColors.headerGreenDark)),
                            ),
                          ] else ...[
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.errorRed),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: state.canUnlinkGoogle
                                  ? () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Unlinking Google Account...')),
                                      );
                                    }
                                  : null,
                              icon: const Icon(Icons.link_off_rounded, color: AppColors.errorRed),
                              label: const Text('Unlink Google Account', style: TextStyle(color: AppColors.errorRed)),
                            ),
                            if (!state.canUnlinkGoogle) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Safeguard: Cannot unlink Google account because it is your only verified sign-in method.',
                                style: TextStyle(fontSize: 11, color: AppColors.errorRed, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
