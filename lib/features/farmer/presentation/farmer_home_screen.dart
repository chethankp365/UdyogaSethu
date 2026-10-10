import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/config/env.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/compact_language_selector.dart';
import 'package:udyogasethu/features/account/presentation/role_switcher_bottom_sheet.dart';
import 'package:udyogasethu/features/farmer/data/farm_resources_repository.dart';
import 'package:udyogasethu/features/farmer/data/farmer_home_repository.dart';
import 'package:udyogasethu/features/farmer/domain/farm_resource_model.dart';
import 'package:udyogasethu/features/farmer/domain/farmer_profile_draft.dart';
import 'package:udyogasethu/features/farmer/presentation/widgets/book_resource_modal.dart';
import 'package:udyogasethu/features/farmer/presentation/widgets/equipment_rental_section.dart';
import 'package:udyogasethu/features/farmer/presentation/widgets/essential_suite_grid.dart';
import 'package:udyogasethu/features/farmer/presentation/widgets/farmer_header_card.dart';
import 'package:udyogasethu/features/farmer/presentation/widgets/mandi_prices_section.dart';
import 'package:udyogasethu/features/farmer/presentation/widgets/weather_advisory_card.dart';
import 'package:udyogasethu/features/provider/data/provider_jobs_repository.dart';
import 'package:udyogasethu/features/provider/domain/job_post_draft.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

final nearbyEquipmentProvider = FutureProvider<List<FarmResource>>((ref) async {
  final repo = ref.watch(farmResourcesRepositoryProvider);
  return repo.getNearbyResources(limit: 6);
});

class FarmerHomeScreen extends ConsumerStatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  ConsumerState<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends ConsumerState<FarmerHomeScreen> {
  Future<void> _refresh() async {
    ref.invalidate(farmerHomeProfileProvider);
    ref.invalidate(farmerStatsProvider);
    ref.invalidate(mandiPricesProvider);
    ref.invalidate(farmerWeatherAdvisoryProvider);
    ref.invalidate(nearbyEquipmentProvider);
  }

  void _handleHireWorkers(BuildContext context) {
    final session = ref.read(appSessionProvider);
    final assignedRoles = session.assignedRoles;
    final l10n = AppLocalizations.of(context);

    if (assignedRoles.contains(UserRole.provider)) {
      _showPostHarvestShiftSheet(context);
    } else {
      _showProviderRoleRequiredDialog(context, l10n);
    }
  }

  void _showProviderRoleRequiredDialog(
    BuildContext context,
    AppLocalizations? l10n,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_alt_rounded,
                  color: Color(0xFF2563EB), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Job Provider Role Required',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hiring farm labour and posting harvest shifts requires the Job Provider / Employer role.',
              style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF475569)),
            ),
            SizedBox(height: 12),
            Text(
              'You can easily add or switch to the Job Provider role without losing your farm profile.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.headerGreenDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              RoleSwitcherBottomSheet.show(context);
            },
            child: const Text('Switch / Add Provider Role'),
          ),
        ],
      ),
    );
  }

  void _showPostHarvestShiftSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    int slots = 5;
    int wagePerDay = 650;
    bool isPosting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.people_alt_rounded,
                        color: Color(0xFF2563EB), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Post Farm Harvest Shift Job',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Category: Agri Labour (Benchmarked ₹550-₹750/day)',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Helpers needed stepper
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Harvest Helpers Needed',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('Slots available for local seekers',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        color: AppColors.headerGreenDark,
                        onPressed: slots > 1
                            ? () => setSheetState(() => slots -= 1)
                            : null,
                      ),
                      Text(
                        '$slots Workers',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        color: AppColors.headerGreenDark,
                        onPressed: () => setSheetState(() => slots += 1),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Wage per day
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily Wage Per Helper',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('Standard 8-hour field shift',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        color: AppColors.headerGreenDark,
                        onPressed: wagePerDay > 400
                            ? () => setSheetState(() => wagePerDay -= 50)
                            : null,
                      ),
                      Text(
                        '₹$wagePerDay/day',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF0D6548),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        color: AppColors.headerGreenDark,
                        onPressed: () => setSheetState(() => wagePerDay += 50),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Escrow protection banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_rounded,
                        color: Color(0xFF0D6548), size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Total ₹${3250} wage is escrow-protected. Will appear live on Seeker Map & job recommendations.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF064E3B)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action buttons
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6548),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isPosting
                      ? null
                      : () async {
                          setSheetState(() => isPosting = true);
                          try {
                            final draft = JobPostDraft(
                              title: 'Crop Harvesting & Threshing Shift',
                              categoryId: 'b2222222-2222-4222-8222-222222222222',
                              categoryName: 'Agri Labour',
                              description:
                                  'Urgent farm harvesting helper shift for ready crops. Lunch and water provided on field.',
                              wageType: 'daily',
                              wagePaise: wagePerDay * 100,
                              slotsTotal: slots,
                              startAt: DateTime.now().add(const Duration(hours: 14)),
                              addressText: 'Mandya Farm Cluster, Field Sector 4',
                              latitude: 12.5244,
                              longitude: 76.8951,
                              paymentMode: 'escrow',
                              studentsOk: true,
                            );

                            final repo = ref.read(providerJobsRepositoryProvider);
                            await repo.postJob(draft);

                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              showDialog(
                                context: context,
                                builder: (dialogCtx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18)),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_rounded,
                                          color: Color(0xFF0D6548), size: 48),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Harvest Shift Posted!',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF0D6548),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '$slots worker slots opened at ₹$wagePerDay/day. This job is now live on the Seeker Map.',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 12, color: AppColors.textMuted),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.headerGreenDark,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () => Navigator.pop(dialogCtx),
                                        child: Text(l10n?.farmerUnderstood ?? 'Understood'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          } catch (err) {
                            if (ctx.mounted) {
                              setSheetState(() => isPosting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to post job: $err')),
                              );
                            }
                          }
                        },
                  child: isPosting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Post Harvest Shift ($slots Workers)'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/provider/jobs/new?category=agri_labour');
                  },
                  child: const Text(
                    'Open Full Job Posting Wizard →',
                    style: TextStyle(fontSize: 12, color: AppColors.headerGreenDark),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(farmerHomeProfileProvider);
    final statsAsync = ref.watch(farmerStatsProvider);
    final mandiAsync = ref.watch(mandiPricesProvider);
    final weatherAsync = ref.watch(farmerWeatherAdvisoryProvider);
    final equipmentAsync = ref.watch(nearbyEquipmentProvider);
    final isRainSimulated = ref.watch(simulatedRainForecastProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.agriculture_rounded, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l10n?.farmerHomeTitle ?? 'Farmer Home',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Options',
            onSelected: (val) {
              if (val == 'simulate_rain') {
                ref.read(simulatedRainForecastProvider.notifier).toggle();
                ref.invalidate(farmerWeatherAdvisoryProvider);
              } else if (val == 'farmer_orders') {
                context.push(AppRoutes.farmerOrders);
              } else if (val == 'delivery_slots') {
                context.push(AppRoutes.farmerDeliverySlots);
              } else if (val == 'vendor_hub') {
                context.push(AppRoutes.farmerVendorResources);
              } else if (val == 'resources_map') {
                context.push(AppRoutes.farmerResources);
              } else if (val == 'role_switch') {
                RoleSwitcherBottomSheet.show(context);
              } else if (val == 'logout') {
                Supabase.instance.client.auth.signOut();
                context.go('/login');
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'simulate_rain',
                child: Row(
                  children: [
                    Icon(
                      isRainSimulated ? Icons.water_drop : Icons.water_drop_outlined,
                      size: 20,
                      color: const Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isRainSimulated ? 'Disable Rain Sim' : 'Simulate Rain Alert',
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'farmer_orders',
                child: Row(
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 20, color: Color(0xFF0D6548)),
                    SizedBox(width: 8),
                    Text('Incoming Customer Orders'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delivery_slots',
                child: Row(
                  children: [
                    Icon(Icons.access_time_filled_rounded, size: 20, color: Color(0xFF0D6548)),
                    SizedBox(width: 8),
                    Text('Delivery & Pickup Slots'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'resources_map',
                child: Row(
                  children: [
                    Icon(Icons.map_rounded, size: 20, color: Color(0xFF0D6548)),
                    SizedBox(width: 8),
                    Text('Farm Machinery Map'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'vendor_hub',
                child: Row(
                  children: [
                    Icon(Icons.handyman_rounded, size: 20, color: Color(0xFFD97706)),
                    SizedBox(width: 8),
                    Text('Equipment Vendor Hub'),
                  ],
                ),
              ),
              if (kAllowMultiRole)
                const PopupMenuItem(
                  value: 'role_switch',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Switch Role'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Color(0xFFDC2626))),
                  ],
                ),
              ),
            ],
          ),
          const CompactLanguageSelector(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.headerGreenDark,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP HEADER HERO CARD (Screen 22 layout)
              profileAsync.when(
                data: (profile) => FarmerHeaderCard(
                  profile: profile,
                  stats: statsAsync.value ?? const FarmerHomeStats(),
                ),
                loading: () => _buildHeaderSkeleton(),
                error: (err, _) => const FarmerHeaderCard(
                  profile: FarmerProfileDraft(userId: ''),
                  stats: FarmerHomeStats(),
                ),
              ),
              const SizedBox(height: 18),

              // 2. WEATHER ADVISORY RADAR CARD (Screen 26 layout)
              weatherAsync.when(
                data: (advisory) => WeatherAdvisoryCard(
                  advisory: advisory,
                  onBookHelpers: () => _handleHireWorkers(context),
                ),
                loading: () => _buildCardSkeleton(height: 140),
                error: (err, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // 3. LIVE MANDI PRICES & DEMAND SECTION (Screen 22 layout)
              mandiAsync.when(
                data: (prices) => MandiPricesSection(
                  prices: prices,
                  onRefresh: _refresh,
                ),
                loading: () => _buildCardSkeleton(height: 240),
                error: (err, _) => _buildErrorCard(
                  l10n?.farmerFailedLoadMandi ?? 'Failed to load Mandi prices',
                  err.toString(),
                  _refresh,
                ),
              ),
              const SizedBox(height: 24),

              // 4. FARMER ESSENTIAL SUITE (Screen 26 layout)
              EssentialSuiteGrid(
                onItemTap: (item) {
                  if (item.type == EssentialSuiteType.rentTractor) {
                    context.push('/farmer/resources?category=tractor');
                  } else if (item.type == EssentialSuiteType.agriDrone) {
                    context.push('/farmer/resources?category=drone');
                  } else if (item.type == EssentialSuiteType.sellProduce) {
                    context.push(AppRoutes.farmerListings);
                  } else if (item.type == EssentialSuiteType.hireWorkers) {
                    _handleHireWorkers(context);
                  } else {
                    EssentialSuiteGrid.showItemModal(context, item);
                  }
                },
              ),
              const SizedBox(height: 24),

              // 5. NEARBY EQUIPMENT & DRONE RENTALS SECTION (Screen 26 layout)
              equipmentAsync.when(
                data: (items) => EquipmentRentalSection(
                  resources: items,
                  onViewAll: () => context.push(AppRoutes.farmerResources),
                  onBookItem: (res) => BookResourceModal.show(
                    context,
                    resource: res,
                    onBookingConfirmed: (b) {
                      ref.invalidate(nearbyEquipmentProvider);
                    },
                  ),
                ),
                loading: () => _buildCardSkeleton(height: 180),
                error: (err, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.headerGreenDark.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: Colors.white),
    );
  }

  Widget _buildCardSkeleton({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: Color(0xFF0D6548)),
    );
  }

  Widget _buildErrorCard(String title, String message, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 36, color: Color(0xFFDC2626)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D6548),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
