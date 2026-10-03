import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final UserRole role;

  const ProfileScreen({super.key, required this.role});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _fullName = 'UdyogaSethu User';
  String? _avatarPath;
  String? _phone;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      if (!Supabase.instance.isInitialized) return;
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        _phone = user.phone;
        try {
          final data = await client
              .from('profiles')
              .select('full_name, avatar_path')
              .eq('id', user.id)
              .maybeSingle();

          if (data != null && mounted) {
            setState(() {
              _fullName = (data['full_name'] as String?)?.isNotEmpty == true
                  ? data['full_name']
                  : (user.email ?? 'UdyogaSethu User');
              _avatarPath = data['avatar_path'] as String?;
            });
          }
        } catch (_) {
          // Fallback to default
        }
      }
    } catch (_) {
      // Fallback to default
    }
  }

  String _getRoleDisplayName() {
    switch (widget.role) {
      case UserRole.seeker:
        return 'Job Seeker';
      case UserRole.provider:
        return 'Job Provider';
      case UserRole.farmer:
        return 'Farmer';
    }
  }

  Color _getRoleColor() {
    switch (widget.role) {
      case UserRole.seeker:
        return AppColors.headerGreenDark;
      case UserRole.provider:
        return AppColors.amberOrange;
      case UserRole.farmer:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.profileTitle ?? 'My Profile', style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: _getRoleColor().withAlpha(38),
                    backgroundImage: (_avatarPath != null && _avatarPath!.isNotEmpty)
                        ? NetworkImage(_avatarPath!)
                        : null,
                    child: (_avatarPath == null || _avatarPath!.isEmpty)
                        ? Text(
                            _fullName.isNotEmpty ? _fullName[0].toUpperCase() : 'U',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _getRoleColor(),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _fullName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  if (_phone != null && _phone!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _phone!,
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRoleColor().withAlpha(30),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _getRoleColor().withAlpha(75)),
                    ),
                    child: Text(
                      _getRoleDisplayName(),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getRoleColor()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Navigation Links Group
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_rounded, color: Colors.blue, size: 20),
                      ),
                      title: Text(
                        l10n?.privacyCentreTitle ?? 'Privacy Centre',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: const Text('Consents, data rights, and permissions', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(AppRoutes.privacyCentre),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.headerGreenDark.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.settings_rounded, color: AppColors.headerGreenDark, size: 20),
                      ),
                      title: Text(
                        l10n?.settingsTitle ?? 'Settings',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: const Text('Language, accessibility, export & delete account', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(AppRoutes.settings),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.description_rounded, color: Colors.purple, size: 20),
                      ),
                      title: Text(
                        l10n?.termsAndPrivacyTitle ?? 'Terms & Privacy Policy',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: const Text('Terms of service and legal draft notice', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(AppRoutes.termsAndPrivacy),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Footer Notice
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'UdyogaSethu v1.0.0 • Verified Trust Network',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
