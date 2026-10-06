// TODO(P4.1): Replace interim SeekerHomeScreen with full recommendation feed in Phase 4.1

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/config/env.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/compact_language_selector.dart';
import 'package:udyogasethu/core/widgets/user_avatar.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_profile_draft.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_wizard_controller.dart';

final seekerHomeProfileProvider = FutureProvider<SeekerProfileDraft>((ref) async {
  final repo = ref.watch(seekerProfileRepositoryProvider);
  String? userId;
  bool isSupabaseInitialized = true;
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.id.isNotEmpty) userId = user.id;
  } catch (_) {
    isSupabaseInitialized = false;
  }
  if (isSupabaseInitialized && userId == null) {
    return const SeekerProfileDraft(userId: '');
  }
  final targetId = userId ?? 'test-user-id';
  return repo.loadDraft(targetId);
});

final seekerSkillsListProvider = FutureProvider<List<SkillItem>>((ref) async {
  final repo = ref.watch(seekerProfileRepositoryProvider);
  return repo.fetchSkills();
});

class SeekerHomeScreen extends ConsumerWidget {
  const SeekerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(seekerHomeProfileProvider);
    final skillsAsync = ref.watch(seekerSkillsListProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Seeker Home', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          if (kAllowMultiRole)
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: 'Switch Role',
              onPressed: () => context.push(AppRoutes.devRole),
            ),
          const CompactLanguageSelector(),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(seekerHomeProfileProvider);
          ref.invalidate(seekerSkillsListProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading profile: $err')),
            data: (draft) {
              final hasName = draft.fullName.trim().isNotEmpty;
              final seekerTypeDisplay = draft.seekerType == 'student'
                  ? 'Student Seeker'
                  : draft.seekerType == 'part_time'
                      ? 'Part-Time Seeker'
                      : 'Informal Seeker';

              final List<SkillItem> allSkills = skillsAsync.value ?? [];
              final selectedSkillNames = draft.selectedSkillIds.map((id) {
                final match = allSkills.firstWhere(
                  (s) => s.id == id,
                  orElse: () => SkillItem(id: id, categoryId: '', names: {'en': 'Skill'}),
                );
                return match.getLocalizedName('en');
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. GREETING
                  Text(
                    'Welcome back, ${hasName ? draft.fullName : "Job Seeker"}! 👋',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Find daily jobs, manage your worker profile, and track local work requests.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),

                  // 2. IDENTITY VERIFICATION BANNER
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      onTap: () => context.push(AppRoutes.kycSafetyOnboarding),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.paleMint,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorderGreen),
                        ),
                        child: const Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.headerGreenDark,
                              foregroundColor: Colors.white,
                              radius: 20,
                              child: Icon(Icons.verified_user_rounded, size: 24),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Safety Onboarding & Verified Badge',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Complete KYC, liveness and 1-day training to earn gold badge +100 XP.',
                                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: AppColors.headerGreenDark),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. PROFILE SUMMARY CARD
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Colors.white, AppColors.headerGreenDark.withValues(alpha: 0.04)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              UserAvatar(
                                avatarPath: draft.avatarPath,
                                name: hasName ? draft.fullName : 'Unnamed Worker',
                                radius: 32,
                                backgroundColor: AppColors.headerGreenDark.withValues(alpha: 0.15),
                                textColor: AppColors.headerGreenDark,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hasName ? draft.fullName : 'Unnamed Worker',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                    const SizedBox(height: 4),
                                    Chip(
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor: AppColors.headerGreenDark,
                                      labelStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                      label: Text(seekerTypeDisplay),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, color: AppColors.headerGreenDark),
                                tooltip: 'Edit Profile',
                                onPressed: () => context.go(AppRoutes.profileSetupSeeker),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          // Skills Section
                          const Text('Skills:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                          const SizedBox(height: 6),
                          if (selectedSkillNames.isEmpty)
                            const Text('No skills selected', style: TextStyle(fontSize: 12, color: AppColors.textMuted))
                          else
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: selectedSkillNames.map((skill) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.headerGreenDark.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.headerGreenDark.withValues(alpha: 0.2)),
                                  ),
                                  child: Text(skill, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark)),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 14),

                          // Details Grid (Rate, Availability, Working Days, Radius)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildInfoCol(
                                      'Daily Rate',
                                      draft.dailyRatePaise != null && draft.dailyRatePaise! > 0
                                          ? '₹${(draft.dailyRatePaise! / 100).round()} / day'
                                          : 'Not specified',
                                    ),
                                    _buildInfoCol(
                                      'Availability',
                                      draft.availabilityStatus.toUpperCase(),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildInfoCol(
                                      'Working Days',
                                      draft.workingDays.isNotEmpty ? draft.workingDays.join(', ') : 'Not specified',
                                    ),
                                    _buildInfoCol(
                                      'Service Radius',
                                      '${draft.serviceRadiusKm.toInt()} km',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. SEEKER ACTIONS
                  const Text('Seeker Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Find Jobs feed coming soon (P4.1)'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.search_rounded, color: AppColors.headerGreenDark),
                          label: const Text('Find Jobs', style: TextStyle(color: AppColors.headerGreenDark, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.go(AppRoutes.profileSetupSeeker),
                          icon: const Icon(Icons.person_outline_rounded, color: AppColors.amberOrange),
                          label: const Text('Complete Profile', style: TextStyle(color: AppColors.amberOrange, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCol(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
      ],
    );
  }
}
