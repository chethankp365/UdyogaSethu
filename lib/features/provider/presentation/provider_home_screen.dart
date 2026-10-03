import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/config/env.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/compact_language_selector.dart';
import 'package:udyogasethu/features/provider/domain/provider_profile_draft.dart';
import 'package:udyogasethu/features/provider/presentation/provider_wizard_controller.dart';

final providerHomeProfileProvider = FutureProvider<ProviderProfileDraft>((ref) async {
  final repo = ref.watch(providerProfileRepositoryProvider);
  String? userId;
  bool isSupabaseInitialized = true;
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.id.isNotEmpty) userId = user.id;
  } catch (_) {
    isSupabaseInitialized = false;
  }
  if (isSupabaseInitialized && userId == null) {
    return const ProviderProfileDraft(userId: '');
  }
  final targetId = userId ?? 'test-user-id';
  return repo.loadDraft(targetId);
});

class ProviderHomeScreen extends ConsumerWidget {
  const ProviderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(providerHomeProfileProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Provider Home', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
        onRefresh: () async => ref.refresh(providerHomeProfileProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading provider data: $err')),
            data: (draft) {
              final hasProfile = draft.fullName.isNotEmpty || draft.orgName.isNotEmpty;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Text(
                    'Welcome back, ${draft.fullName.isNotEmpty ? draft.fullName : "Provider"}! 💼',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    draft.isHousehold
                        ? 'Manage doorstep delivery addresses, post daily tasks, and hire verified local workers.'
                        : 'Manage organisation site addresses, post bulk crew requirements, and track applicants.',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),

                  if (!hasProfile) ...[
                    // EMPTY PROFILE CARD CTA
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.paleMint,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorderGreen),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              draft.isHousehold ? Icons.home_rounded : Icons.business_rounded,
                              size: 48,
                              color: AppColors.headerGreenDark,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              draft.isHousehold ? 'Set Up Household Delivery Address' : 'Set Up Organisation & Site Profile',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Complete your profile setup to start hiring verified workers and managing sites.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.headerGreenDark,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => context.go(AppRoutes.profileSetupProvider),
                              icon: const Icon(Icons.edit_rounded, size: 18),
                              label: const Text('Complete Provider Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // ACTIVE PROVIDER PROFILE CARD
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
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor: AppColors.headerGreenDark.withValues(alpha: 0.15),
                                  backgroundImage: draft.avatarUrl != null ? NetworkImage(draft.avatarUrl!) : null,
                                  child: draft.avatarUrl == null
                                      ? Icon(
                                          draft.isHousehold ? Icons.home_rounded : Icons.business_rounded,
                                          size: 36,
                                          color: AppColors.headerGreenDark,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        draft.isEmployer && draft.orgName.isNotEmpty
                                            ? draft.orgName
                                            : draft.fullName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                      const SizedBox(height: 2),
                                      Chip(
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        labelStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                        backgroundColor: draft.isHousehold ? AppColors.amberOrange : AppColors.headerGreenDark,
                                        label: Text(draft.isHousehold ? 'Household Provider' : 'Employer / Contractor'),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded, color: AppColors.headerGreenDark),
                                  tooltip: 'Edit Provider Profile',
                                  onPressed: () => context.go(AppRoutes.profileSetupProvider),
                                ),
                              ],
                            ),
                            const Divider(height: 24),

                          // ADDRESS DETAILS
                          if (draft.isHousehold) ...[
                            const Text('Default Doorstep Delivery Address:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                            const SizedBox(height: 4),
                            Text(
                              draft.addressLine1.isNotEmpty
                                  ? '${draft.addressLine1}, ${draft.landmark}'
                                  : 'No doorstep address added',
                              style: const TextStyle(fontSize: 14, color: AppColors.headerGreenDark, fontWeight: FontWeight.w600),
                            ),
                            Text('${draft.city} - ${draft.pincode}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            if (draft.latitude != null && draft.longitude != null)
                              Text('GPS Pin: ${draft.latitude!.toStringAsFixed(4)}, ${draft.longitude!.toStringAsFixed(4)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            const SizedBox(height: 12),
                            const Text('Delivery Instructions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(draft.deliveryDropoffInstruction, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                          ] else ...[
                            const Text('Primary Site Address:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                            const SizedBox(height: 4),
                            Text(
                              draft.siteAddressLine1.isNotEmpty
                                  ? '${draft.siteAddressLine1}, ${draft.siteLandmark}'
                                  : 'No primary site address added',
                              style: const TextStyle(fontSize: 14, color: AppColors.headerGreenDark, fontWeight: FontWeight.w600),
                            ),
                            Text('${draft.siteCity} - ${draft.sitePincode}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            if (draft.siteLatitude != null && draft.siteLongitude != null)
                              Text('GPS Pin: ${draft.siteLatitude!.toStringAsFixed(4)}, ${draft.siteLongitude!.toStringAsFixed(4)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            const SizedBox(height: 12),
                            const Text('Categories Hired For:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: draft.categoriesHiring.map((cat) {
                                return Chip(
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: AppColors.headerGreenDark.withValues(alpha: 0.1),
                                  label: Text(cat, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark)),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 10),
                            Text('Typical Crew Size Needed: ${draft.typicalCrewSize} workers', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                  // Quick Actions
                  const Text('Job Provider Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.post_add_rounded, color: AppColors.headerGreenDark),
                          label: const Text('Post a Job', style: TextStyle(color: AppColors.headerGreenDark)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.person_search_rounded, color: AppColors.amberOrange),
                          label: const Text('Hire Workers', style: TextStyle(color: AppColors.amberOrange)),
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
}
