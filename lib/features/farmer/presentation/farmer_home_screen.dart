import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/compact_language_selector.dart';
import 'package:udyogasethu/features/farmer/domain/farmer_profile_draft.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_wizard_controller.dart';

final farmerHomeProfileProvider = FutureProvider<FarmerProfileDraft>((ref) async {
  final repo = ref.watch(farmerProfileRepositoryProvider);
  String userId = 'demo-user-id';
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      userId = user.id;
    }
  } catch (_) {}
  return repo.loadDraft(userId);
});

class FarmerHomeScreen extends ConsumerWidget {
  const FarmerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(farmerHomeProfileProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Farmer Home', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
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
        onRefresh: () async => ref.refresh(farmerHomeProfileProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading farm data: $err')),
            data: (draft) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Text(
                    'Welcome back, ${draft.fullName.isNotEmpty ? draft.fullName : "Farmer"}! 🌾',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 4),
                  const Text('Manage your farm profile, produce listings, and mandi prices.', style: TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: 16),

                  // ACTIVE FARM CARD
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
                                    ? const Icon(Icons.agriculture_rounded, size: 36, color: AppColors.headerGreenDark)
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      draft.farmName.isNotEmpty ? draft.farmName : 'My Farm',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                    Text(
                                      '${draft.clusterVillage.isNotEmpty ? draft.clusterVillage : "Village"} • ${draft.acres.toStringAsFixed(1)} Acres',
                                      style: const TextStyle(color: AppColors.headerGreenDark, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    if (draft.farmLatitude != null && draft.farmLongitude != null)
                                      Text(
                                        'GPS: ${draft.farmLatitude!.toStringAsFixed(4)}, ${draft.farmLongitude!.toStringAsFixed(4)}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, color: AppColors.headerGreenDark),
                                tooltip: 'Edit Farm Profile',
                                onPressed: () => context.go(AppRoutes.profileSetupFarmer),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          // Badges Row
                          const Text('Farm Badges:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              Chip(
                                avatar: const Icon(Icons.eco_rounded, size: 14, color: Colors.white),
                                label: Text(draft.farmingMethod.toUpperCase()),
                                backgroundColor: AppColors.headerGreenDark,
                                labelStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              if (draft.hasApmcBadge)
                                const Chip(
                                  avatar: Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                                  label: Text('APMC REGISTERED'),
                                  backgroundColor: AppColors.headerGreenDark,
                                  labelStyle: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              if (draft.hasKccBadge)
                                Chip(
                                  avatar: const Icon(Icons.credit_card_rounded, size: 14, color: Colors.white),
                                  label: Text('KCC ${draft.kccStatus.toUpperCase()}'),
                                  backgroundColor: AppColors.headerGreenDark,
                                  labelStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              if (draft.hasOrganicBadge)
                                const Chip(
                                  avatar: Icon(Icons.stars_rounded, size: 14, color: Colors.white),
                                  label: Text('ORGANIC CERT (PENDING)'),
                                  backgroundColor: AppColors.amberOrange,
                                  labelStyle: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Primary Crops
                          const Text('Primary Crops:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: draft.primaryCrops.map((crop) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.amberOrange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.amberOrange.withValues(alpha: 0.3)),
                                ),
                                child: Text(crop, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.amberOrange)),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),

                          // Delivery & Selling Info
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildInfoCol('Delivery', draft.deliveryAvailable ? '${draft.deliveryRadiusKm.toInt()} km' : 'No'),
                                _buildInfoCol('Pickup', draft.pickupAvailable ? 'Yes' : 'No'),
                                _buildInfoCol('Lead Time', draft.leadTime),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick Actions
                  const Text('Farmer Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.headerGreenDark),
                          label: const Text('Add Produce', style: TextStyle(color: AppColors.headerGreenDark)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.trending_up_rounded, color: AppColors.amberOrange),
                          label: const Text('Mandi Prices', style: TextStyle(color: AppColors.amberOrange)),
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
