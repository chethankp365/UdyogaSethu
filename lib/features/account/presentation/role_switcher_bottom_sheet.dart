import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/account/data/account_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return SupabaseAccountRepository();
});

class RoleSwitcherBottomSheet extends ConsumerWidget {
  const RoleSwitcherBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const RoleSwitcherBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSessionProvider);
    final activeRole = session.activeRole;
    final assignedRoles = session.assignedRoles;

    final allRoles = [UserRole.seeker, UserRole.provider, UserRole.farmer];
    final unassignedRoles = allRoles.where((r) => !assignedRoles.contains(r)).toList();

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
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
              const Text(
                'Switch Role Shell',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.headerGreenDark),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select an active role to switch UI dashboard seamlessly.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),

              // Assigned Roles List
              ...assignedRoles.map((role) {
                final isSelected = role == activeRole;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.headerGreenDark.withValues(alpha: 0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.headerGreenDark : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected ? AppColors.headerGreenDark : Colors.grey.shade200,
                        foregroundColor: isSelected ? Colors.white : AppColors.headerGreenDark,
                        child: Icon(_getRoleIcon(role)),
                      ),
                      title: Text(
                        _getRoleTitle(role),
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? AppColors.headerGreenDark : Colors.black87,
                        ),
                      ),
                      subtitle: Text(_getRoleSubtitle(role), style: const TextStyle(fontSize: 12)),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.headerGreenDark)
                          : null,
                      onTap: () async {
                        final user = Supabase.instance.client.auth.currentUser;
                        if (user == null || user.id.isEmpty) return;

                        await ref.read(accountRepositoryProvider).switchActiveRole(userId: user.id, role: role);
                        ref.read(appSessionProvider.notifier).setRole(role);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          context.go(AppSessionNotifier.getHomeForRole(role));
                        }
                      },
                    ),
                  ),
                );
              }),

          const SizedBox(height: 12),

          // Add a Role Section
          if (unassignedRoles.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Add a Role to your Account',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: unassignedRoles.map((role) {
                return OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.headerGreenDark),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final user = Supabase.instance.client.auth.currentUser;
                    if (user == null || user.id.isEmpty) return;

                    await ref.read(accountRepositoryProvider).addRole(userId: user.id, role: role);
                    final newAssigned = [...assignedRoles, role];
                    ref.read(appSessionProvider.notifier).updateSession(
                          role: role,
                          assignedRoles: newAssigned,
                          status: AuthSessionStatus.needsProfile,
                        );

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      if (role == UserRole.provider) {
                        context.go(AppRoutes.profileSetupProvider);
                      } else if (role == UserRole.farmer) {
                        context.go(AppRoutes.profileSetupFarmer);
                      } else {
                        context.go(AppRoutes.profileSetupSeeker);
                      }
                    }
                  },
                  icon: Icon(_getRoleIcon(role), size: 18, color: AppColors.headerGreenDark),
                  label: Text('Add ${_getRoleTitle(role)}', style: const TextStyle(color: AppColors.headerGreenDark)),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.seeker:
        return Icons.person_search_rounded;
      case UserRole.provider:
        return Icons.business_center_rounded;
      case UserRole.farmer:
        return Icons.agriculture_rounded;
    }
  }

  String _getRoleTitle(UserRole role) {
    switch (role) {
      case UserRole.seeker:
        return 'Job Seeker';
      case UserRole.provider:
        return 'Job Provider';
      case UserRole.farmer:
        return 'Farmer';
    }
  }

  String _getRoleSubtitle(UserRole role) {
    switch (role) {
      case UserRole.seeker:
        return 'Find daily-wage and part-time jobs';
      case UserRole.provider:
        return 'Post jobs and hire verified workers';
      case UserRole.farmer:
        return 'Sell produce and hire farm labour';
    }
  }
}
