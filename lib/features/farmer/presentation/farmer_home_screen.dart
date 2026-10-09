import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/config/env.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/compact_language_selector.dart';
import 'package:udyogasethu/core/widgets/mic_fab.dart';
import 'package:udyogasethu/features/farmer/data/farmer_home_repository.dart';
import 'package:udyogasethu/features/farmer/domain/farmer_profile_draft.dart';
import 'package:udyogasethu/features/farmer/presentation/widgets/essential_suite_grid.dart';
import 'package:udyogasethu/features/farmer/presentation/widgets/farmer_header_card.dart';
import 'package:udyogasethu/features/farmer/presentation/widgets/mandi_prices_section.dart';
import 'package:udyogasethu/features/farmer/presentation/widgets/weather_advisory_card.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

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
  }

  void _showHireWorkersPlaceholder(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.people_alt_rounded, color: Color(0xFF2563EB), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.farmerHireWorkers ?? 'Hire Workers',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        l10n?.farmerComingInPhase('P6.3') ?? 'Coming in P6.3',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.farmerHireWorkersDesc ??
                  'Farmers will be able to post agricultural labour requests, specify shifts, and hire verified nearby workers directly from their farmer account with escrow protection.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6548),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  l10n?.farmerGotIt ?? 'Got it',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
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
            Text(
              l10n?.farmerHomeTitle ?? 'Farmer Home',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        actions: [
          // Dev Menu / Rain Simulation Toggle
          PopupMenuButton<String>(
            icon: Icon(
              isRainSimulated ? Icons.thunderstorm_rounded : Icons.more_vert_rounded,
              color: isRainSimulated ? const Color(0xFFF59E0B) : Colors.white,
            ),
            tooltip: 'Options',
            onSelected: (val) {
              if (val == 'simulate_rain') {
                ref.read(simulatedRainForecastProvider.notifier).toggle();
              } else if (val == 'switch_role') {
                context.push(AppRoutes.devRole);
              } else if (val == 'logout') {
                Supabase.instance.client.auth.signOut();
                context.go(AppRoutes.login);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'simulate_rain',
                child: Row(
                  children: [
                    Icon(
                      isRainSimulated ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      color: const Color(0xFFE65100),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(l10n?.farmerSimulateRainDev ?? 'Simulate Rain Forecast (Dev)'),
                  ],
                ),
              ),
              if (kAllowMultiRole)
                const PopupMenuItem(
                  value: 'switch_role',
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
      floatingActionButton: MicFab(onTap: () {}),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
                  onBookHelpers: () => _showHireWorkersPlaceholder(context),
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
                  if (item.type == EssentialSuiteType.hireWorkers) {
                    _showHireWorkersPlaceholder(context);
                  } else {
                    EssentialSuiteGrid.showItemModal(context, item);
                  }
                },
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
          ElevatedButton.icon(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6548)),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
