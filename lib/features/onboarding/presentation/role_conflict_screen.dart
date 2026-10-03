import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/onboarding/data/bootstrap_service.dart';
import 'package:udyogasethu/features/onboarding/data/role_tree_service.dart';

/// Screen displayed when a user attempts to log into an existing account using a different role
/// while [kAllowMultiRole] is false (ONE ACCOUNT = ONE ROLE policy).
class RoleConflictScreen extends ConsumerWidget {
  final UserRole existingRole;
  final UserRole chosenRole;

  const RoleConflictScreen({
    super.key,
    required this.existingRole,
    required this.chosenRole,
  });

  String _getRoleDisplayName(BuildContext context, UserRole role) {
    final l10n = AppLocalizations.of(context);
    if (l10n != null) {
      switch (role) {
        case UserRole.seeker:
          return l10n.roleSeeker;
        case UserRole.provider:
          return l10n.roleProvider;
        case UserRole.farmer:
          return l10n.roleFarmer;
      }
    }
    switch (role) {
      case UserRole.seeker:
        return 'Job Seeker';
      case UserRole.provider:
        return 'Job Provider';
      case UserRole.farmer:
        return 'Farmer';
    }
  }

  Future<void> _handleLogInAsExisting(BuildContext context, WidgetRef ref) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(kPendingRolePrefsKey);
      await ref.read(roleTreeProvider.notifier).reset();

      // Apply RPC for existing role
      final client = Supabase.instance.client;
      if (client.auth.currentUser != null) {
        await client.rpc('apply_role_selection', params: {
          'p_role': existingRole.name,
        });
      }

      // Re-run bootstrap to navigate to existing role's home or wizard
      await ref.read(bootstrapProvider.notifier).runBootstrap();
    } catch (_) {
      // Fallback update
      ref.read(appSessionProvider.notifier).updateSession(
        status: AuthSessionStatus.ready,
        role: existingRole,
        assignedRoles: [existingRole],
      );
    }
  }

  Future<void> _handleBack(BuildContext context, WidgetRef ref) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(kPendingRolePrefsKey);
      await ref.read(roleTreeProvider.notifier).reset();
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}

    ref.read(appSessionProvider.notifier).updateSession(
      status: AuthSessionStatus.needsRole,
      role: UserRole.seeker,
      assignedRoles: [],
    );

    if (context.mounted) {
      try {
        context.go(AppRoutes.roleTree);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final existingRoleName = _getRoleDisplayName(context, existingRole);
    final chosenRoleName = _getRoleDisplayName(context, chosenRole);

    final title = l10n?.roleConflictTitle ?? 'Account Role Conflict';
    final rawMessage = l10n?.roleConflictMessage(chosenRoleName, existingRoleName) ??
        'This number is already registered as $existingRoleName. You cannot use it as $chosenRoleName. To use a different role, log in as $existingRoleName, go to Profile > Settings > Delete account, and then create a new account.';
    final loginAsLabel = l10n?.roleConflictLoginAs(existingRoleName) ?? 'Log in as $existingRoleName';
    final backLabel = l10n?.roleConflictBack ?? 'Back';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.amberOrange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.report_problem_rounded,
                  color: AppColors.amberOrange,
                  size: 44,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    rawMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.headerGreenDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: () => _handleLogInAsExisting(context, ref),
                child: Text(
                  loginAsLabel,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.headerGreenDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.headerGreenDark, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _handleBack(context, ref),
                child: Text(
                  backLabel,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
