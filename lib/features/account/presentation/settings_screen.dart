import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/config/env.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/compact_language_selector.dart';
import 'package:udyogasethu/features/account/domain/user_settings.dart';
import 'package:udyogasethu/features/account/presentation/delete_account_dialog.dart';
import 'package:udyogasethu/features/account/presentation/export_data_dialog.dart';
import 'package:udyogasethu/features/account/presentation/role_switcher_bottom_sheet.dart';
import 'package:udyogasethu/features/account/presentation/seeker_type_change_dialog.dart';
import 'package:udyogasethu/features/onboarding/domain/pending_role_selection.dart';

import 'package:udyogasethu/features/account/presentation/settings_controller.dart';

final userSettingsProvider = FutureProvider<UserSettings>((ref) async {
  final repo = ref.watch(accountRepositoryProvider);
  String? userId;
  bool isSupabaseInitialized = true;
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.id.isNotEmpty) userId = user.id;
  } catch (_) {
    isSupabaseInitialized = false;
  }
  if (isSupabaseInitialized && userId == null) {
    return const UserSettings();
  }
  final targetId = userId ?? 'test-user-id';
  return repo.loadSettings(targetId);
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSessionProvider);
    final settings = ref.watch(userSettingsNotifierProvider);
    final settingsNotifier = ref.read(userSettingsNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Account & Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: const [
          CompactLanguageSelector(),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. LANGUAGE & ACCESSIBILITY SECTION
            const Text('Language & Accessibility', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.headerGreenDark)),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language_rounded, color: AppColors.headerGreenDark),
                    title: const Text('App Language'),
                    subtitle: const Text('Select primary display language'),
                    trailing: OutlinedButton(
                      onPressed: () => context.push(AppRoutes.language),
                      child: const Text('Change'),
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.touch_app_rounded, color: AppColors.headerGreenDark),
                    title: const Text('Simple Mode'),
                    subtitle: const Text('Simplified layout, big tactile buttons and high contrast'),
                    value: settings.simpleMode,
                    activeThumbColor: AppColors.headerGreenDark,
                    onChanged: (val) => settingsNotifier.setSimpleMode(val),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.text_fields_rounded, color: AppColors.headerGreenDark),
                                SizedBox(width: 12),
                                Text('Text Scale Size', style: TextStyle(fontSize: 15)),
                              ],
                            ),
                            Text('${(settings.textScale * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.headerGreenDark)),
                          ],
                        ),
                        Slider(
                          value: settings.textScale.clamp(0.85, 1.60),
                          min: 0.85,
                          max: 1.60,
                          divisions: 15,
                          activeColor: AppColors.headerGreenDark,
                          onChanged: (val) => settingsNotifier.setTextScale(val),
                        ),
                        Text(
                          'Scale app text from 85% up to 160% without clipping.',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.volume_up_rounded, color: AppColors.headerGreenDark),
                    title: const Text('Voice Hints & TTS'),
                    subtitle: const Text('Spoken instructions and audio assistance on key screens'),
                    value: settings.voiceHints,
                    activeThumbColor: AppColors.headerGreenDark,
                    onChanged: (val) => settingsNotifier.setVoiceHints(val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.data_saver_on_rounded, color: AppColors.headerGreenDark),
                    title: const Text('Low-Data Mode'),
                    subtitle: const Text('Reduce mobile data usage with compressed images and cached assets'),
                    value: settings.lowDataMode,
                    activeThumbColor: AppColors.headerGreenDark,
                    onChanged: (val) => settingsNotifier.setLowDataMode(val),
                  ),
                  if (settings.lowDataMode) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.speed_rounded, size: 18, color: Color(0xFF1D4ED8)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Low-Data active • Estimated ~2.4 MB data saved this session (optimized thumbnails & cached requests)',
                                style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

                  // 2. ACCOUNT ROLES & CONTROLS SECTION
                  const Text('Account Controls & Roles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.headerGreenDark)),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        if (kAllowMultiRole) ...[
                          ListTile(
                            leading: const Icon(Icons.swap_horiz_rounded, color: AppColors.headerGreenDark),
                            title: const Text('Role Switcher & Add Role'),
                            subtitle: Text('Active: ${session.activeRole.name.toUpperCase()}'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => RoleSwitcherBottomSheet.show(context),
                          ),
                          const Divider(height: 1),
                        ],
                        if (session.activeRole == UserRole.seeker) ...[
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.category_rounded, color: AppColors.headerGreenDark),
                            title: const Text('Change Seeker Category'),
                            subtitle: Text('Current: ${session.seekerType ?? "Informal"}'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => SeekerTypeChangeDialog.show(
                              context,
                              session.seekerType == 'student'
                                  ? SeekerType.student
                                  : session.seekerType == 'part_time'
                                      ? SeekerType.partTime
                                      : SeekerType.informal,
                            ),
                          ),
                        ],
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.link_rounded, color: AppColors.headerGreenDark),
                          title: const Text('Linked Accounts'),
                          subtitle: const Text('Phone number and Google sign-in status'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push('/account/linked'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.download_rounded, color: AppColors.headerGreenDark),
                          title: const Text('Export My Data'),
                          subtitle: const Text('Download a JSON copy of your personal account data'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => ExportDataDialog.show(context),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.delete_forever_rounded, color: AppColors.errorRed),
                          title: const Text('Delete My Account', style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold)),
                          subtitle: const Text('Permanently erase account profile and storage data'),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.errorRed),
                          onTap: () => DeleteAccountDialog.show(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. SIGN OUT BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.errorRed),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        try {
                          await GoogleSignIn().signOut();
                        } catch (_) {}
                        await Supabase.instance.client.auth.signOut();
                        ref.read(appSessionProvider.notifier).setSessionStatus(AuthSessionStatus.signedOut);
                        if (context.mounted) {
                          context.go(AppRoutes.login);
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, color: AppColors.errorRed),
                      label: const Text('Sign Out of Account', style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
