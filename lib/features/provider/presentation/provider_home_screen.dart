import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/config/env.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/compact_language_selector.dart';
import 'package:udyogasethu/core/widgets/user_avatar.dart';
import 'package:udyogasethu/features/provider/domain/nearby_worker.dart';
import 'package:udyogasethu/features/provider/domain/provider_active_booking.dart';
import 'package:udyogasethu/features/provider/domain/provider_job.dart';
import 'package:udyogasethu/features/provider/domain/provider_profile_draft.dart';
import 'package:udyogasethu/features/provider/presentation/provider_jobs_controller.dart';
import 'package:udyogasethu/features/provider/presentation/provider_wizard_controller.dart';
import 'package:udyogasethu/features/provider/presentation/worker_search_controller.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

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

class ProviderHomeScreen extends ConsumerStatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  ConsumerState<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends ConsumerState<ProviderHomeScreen> with TickerProviderStateMixin {
  late TabController _hubTabController;
  late TabController _myJobsTabController;

  @override
  void initState() {
    super.initState();
    _hubTabController = TabController(length: 3, vsync: this);
    _myJobsTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _hubTabController.dispose();
    _myJobsTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(providerHomeProfileProvider);
    final jobsAsync = ref.watch(providerJobsNotifierProvider);
    final activeBookingAsync = ref.watch(providerActiveBookingProvider);
    final verifiedWorkersAsync = ref.watch(verifiedOnDemandWorkersProvider);

    final openJobs = ref.watch(openProviderJobsProvider);
    final filledJobs = ref.watch(filledProviderJobsProvider);
    final completedJobs = ref.watch(completedProviderJobsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Provider Home', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'Cart',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Farm Produce & Goods Cart (Phase 6)')),
              );
            },
          ),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.providerPostNewJob, style: const TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => context.push(AppRoutes.providerJobNew),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(providerHomeProfileProvider);
          ref.invalidate(providerActiveBookingProvider);
          ref.invalidate(verifiedOnDemandWorkersProvider);
          await ref.read(providerJobsNotifierProvider.notifier).refreshJobs();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. CUSTOMER HUB TOP CARD (Green Header)
              _buildCustomerHubHeader(profileAsync.asData?.value, l10n),

              // 2. MAIN CATEGORY TABS: Workers & Services, Farm Produce, Subscriptions
              _buildCategoryTabBar(l10n),

              // Tab View Content
              AnimatedBuilder(
                animation: _hubTabController,
                builder: (context, _) {
                  final hubIndex = _hubTabController.index;
                  if (hubIndex == 1) {
                    return _buildFarmProducePlaceholder(l10n);
                  } else if (hubIndex == 2) {
                    return _buildSubscriptionsPlaceholder(l10n);
                  }

                  // Default: Workers & Services Tab
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Actions (Scan Farm QR, No-Show Help, Milk/Basket, Farmer Chat)
                        _buildQuickActions(context, l10n),

                        const SizedBox(height: 16),

                        // Active Booking Card
                        activeBookingAsync.when(
                          loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
                          error: (err, _) => const SizedBox.shrink(),
                          data: (booking) => booking != null
                              ? _buildActiveBookingCard(context, booking, l10n)
                              : const SizedBox.shrink(),
                        ),

                        const SizedBox(height: 20),

                        // VERIFIED ON-DEMAND LOCAL WORKERS SECTION
                        _buildVerifiedWorkersSection(context, verifiedWorkersAsync, l10n),

                        const SizedBox(height: 20),

                        // Provider Profile Card (for employer addresses & crew size tests)
                        profileAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (err, _) => Text('Error loading provider profile: $err'),
                          data: (draft) => _buildProfileHeader(draft, l10n),
                        ),

                        const SizedBox(height: 20),

                        // MY POSTED JOBS (Tabs: Open, Filled, Completed)
                        _buildMyJobsSection(openJobs, filledJobs, completedJobs, jobsAsync, l10n),

                        const SizedBox(height: 80), // Padding for FAB
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerHubHeader(ProviderProfileDraft? draft, AppLocalizations l10n) {
    final name = draft?.fullName.isNotEmpty == true
        ? draft!.fullName
        : 'Chethan';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.headerGreenDark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.lightGreenAccent, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      l10n.hubTitle.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 14, color: Colors.lightGreenAccent),
                    const SizedBox(width: 4),
                    Text(
                      l10n.hubVerifiedAccount,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.hubGreeting(name),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.hubTagline,
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabBar(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: TabBar(
        controller: _hubTabController,
        indicatorColor: AppColors.headerGreenDark,
        indicatorWeight: 3,
        labelColor: AppColors.headerGreenDark,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: [
          Tab(text: l10n.hubTabWorkers),
          Tab(text: l10n.hubTabProduce),
          Tab(text: l10n.hubTabSubscriptions),
        ],
      ),
    );
  }

  Widget _buildFarmProducePlaceholder(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.agriculture_rounded, size: 54, color: AppColors.headerGreenDark),
              const SizedBox(height: 14),
              Text(
                l10n.hubProduceComingSoon,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.hubProduceComingSoonDesc,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.paleMint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Direct Farmer Marketplace opens in Phase 6', style: TextStyle(color: AppColors.headerGreenDark, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionsPlaceholder(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.local_shipping_rounded, size: 54, color: AppColors.amberOrange),
              const SizedBox(height: 14),
              Text(
                l10n.hubSubscriptionsComingSoon,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.hubSubscriptionsComingSoonDesc,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Recurring Farm Baskets open in Phase 6', style: TextStyle(color: AppColors.amberOrange, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionIcon(
          icon: Icons.qr_code_scanner_rounded,
          label: l10n.hubActionScanFarmQr,
          color: AppColors.headerGreenDark,
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.hubActionScanFarmQr),
                content: const Text('Scan Farm Produce Traceability QR Code.\nFarmer origin and pesticide testing certificate scanner enabled in Phase 6.'),
                actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
              ),
            );
          },
        ),
        _buildActionIcon(
          icon: Icons.support_agent_rounded,
          label: l10n.hubActionNoShowHelp,
          color: Colors.red.shade700,
          onTap: () => _showNoShowHelpModal(context, l10n),
        ),
        _buildActionIcon(
          icon: Icons.shopping_basket_rounded,
          label: l10n.hubActionMilkBasket,
          color: AppColors.amberOrange,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Farm Fresh Milk & Vegetable Basket Subscriptions (Phase 6)')),
            );
          },
        ),
        _buildActionIcon(
          icon: Icons.chat_rounded,
          label: l10n.hubActionFarmerChat,
          color: Colors.blue.shade700,
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('${l10n.hubActionFarmerChat} (P7.1)'),
                content: const Text('Direct messaging with verified local farmers and producers will be available in Phase 7.1.'),
                actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBookingCard(BuildContext context, ProviderActiveBooking booking, AppLocalizations l10n) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.headerGreenDark.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: CONFIRMED BOOKING • CODE | Scheduled Shift
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.paleMint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.hubConfirmedBooking(booking.bookingCode),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.headerGreenDark),
                  ),
                ),
                Text(
                  booking.formattedScheduledTime,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Job Title
            Text(
              booking.jobTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),

            const SizedBox(height: 4),

            // Worker Name & Verification Check
            Row(
              children: [
                Text(
                  'Worker: ${booking.workerName}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
                const SizedBox(width: 4),
                if (booking.workerVerified)
                  const Text('(Aadhaar Verified ✓)', style: TextStyle(fontSize: 11, color: AppColors.headerGreenDark, fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 4),

            // Location & Escrow Wage
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 2),
                Text(booking.addressText, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(width: 8),
                Text('• ${booking.formattedEscrowWage}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark)),
              ],
            ),

            const Divider(height: 20),

            // Action Buttons: Worker Has Not Arrived & Protected Chat
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.warning_amber_rounded, size: 16),
                    label: Text(l10n.hubWorkerNotArrived, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => _showNoShowHelpModal(context, l10n),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.headerGreenDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    label: Text(l10n.hubProtectedChat, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('${l10n.hubProtectedChat} (P7.1)'),
                          content: Text('Chat proxy with ${booking.workerName} for booking ${booking.bookingCode} opens in Step P7.1.'),
                          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedWorkersSection(
    BuildContext context,
    AsyncValue<List<NearbyWorker>> workersAsync,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.hubVerifiedWorkersTitle,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.textDark),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.paleMint,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    l10n.hub100AadhaarVerified,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.providerWorkers),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.headerGreenDark),
              label: Text(l10n.hubViewAllWorkers, style: const TextStyle(color: AppColors.headerGreenDark, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Worker Cards List
        workersAsync.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
          error: (err, _) => Text('Error loading workers: $err'),
          data: (workers) {
            if (workers.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No verified workers nearby right now.'),
                ),
              );
            }

            final displayWorkers = workers.take(3).toList();
            return Column(
              children: displayWorkers.map((w) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    leading: UserAvatar(
                      avatarPath: w.avatarPath,
                      name: w.fullName,
                      radius: 24,
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            w.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (w.isVerifiedBadge)
                          const Icon(Icons.verified_rounded, size: 14, color: AppColors.headerGreenDark),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(w.headline, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: AppColors.amberOrange),
                            const SizedBox(width: 2),
                            Text('${w.ratingAvg.toStringAsFixed(1)} • ${w.formattedDistance}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Text(w.formattedRate, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark)),
                          ],
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.headerGreenDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        ref.read(recentlyViewedWorkersProvider.notifier).addWorker(w);
                        context.push('/provider/workers/${w.userId}');
                      },
                      child: Text(l10n.hubBookWorker, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    onTap: () {
                      ref.read(recentlyViewedWorkersProvider.notifier).addWorker(w);
                      context.push('/provider/workers/${w.userId}');
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMyJobsSection(
    List<ProviderJob> openJobs,
    List<ProviderJob> filledJobs,
    List<ProviderJob> completedJobs,
    AsyncValue<List<ProviderJob>> jobsAsync,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.providerMyJobsTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: 'Refresh Jobs',
              onPressed: () => ref.read(providerJobsNotifierProvider.notifier).refreshJobs(),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TabBar(
            controller: _myJobsTabController,
            indicatorColor: AppColors.headerGreenDark,
            indicatorWeight: 3,
            labelColor: AppColors.headerGreenDark,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: '${l10n.providerTabOpen} (${openJobs.length})'),
              Tab(text: '${l10n.providerTabFilled} (${filledJobs.length})'),
              Tab(text: '${l10n.providerTabCompleted} (${completedJobs.length})'),
            ],
          ),
        ),

        const SizedBox(height: 12),

        jobsAsync.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
          error: (err, _) => Center(child: Text('Error loading jobs: $err')),
          data: (_) {
            return AnimatedBuilder(
              animation: _myJobsTabController,
              builder: (context, _) {
                final tabIndex = _myJobsTabController.index;
                if (tabIndex == 0) {
                  return _buildJobList(openJobs, l10n.providerNoOpenJobsDesc, l10n);
                } else if (tabIndex == 1) {
                  return _buildJobList(filledJobs, l10n.providerNoFilledJobsDesc, l10n);
                } else {
                  return _buildJobList(completedJobs, l10n.providerNoCompletedJobsDesc, l10n);
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildProfileHeader(ProviderProfileDraft draft, AppLocalizations l10n) {
    final hasProfile = draft.fullName.isNotEmpty || draft.orgName.isNotEmpty;
    if (!hasProfile) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.paleMint,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorderGreen),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.headerGreenDark, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Setup Provider Profile', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.headerGreenDark)),
                    SizedBox(height: 2),
                    Text('Add site address to streamline posting jobs.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.headerGreenDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => context.push(AppRoutes.profileSetupProvider),
                child: const Text('Setup'),
              ),
            ],
          ),
        ),
      );
    }

    final isHousehold = draft.providerType == 'household';
    final orgOrName = draft.orgName.isNotEmpty ? draft.orgName : draft.fullName;
    final address = draft.siteAddress.isNotEmpty ? draft.siteAddress : draft.homeAddress;
    final typeLabel = isHousehold ? 'Household Employer' : 'Employer / Contractor';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.paleMint,
                  child: Icon(
                    isHousehold ? Icons.home_rounded : Icons.business_rounded,
                    color: AppColors.headerGreenDark,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orgOrName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.paleMint,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              typeLabel,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                            ),
                          ),
                          if (draft.languages.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              draft.languages.map((l) => l.toUpperCase()).join(', '),
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.headerGreenDark),
                  tooltip: 'Edit Profile',
                  onPressed: () => context.push(AppRoutes.profileSetupProvider),
                ),
              ],
            ),
            if (address.isNotEmpty) ...[
              const Divider(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ],
            if (draft.categoriesHiring.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: draft.categoriesHiring.map((c) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(c, style: const TextStyle(fontSize: 11, color: AppColors.textDark)),
                )).toList(),
              ),
            ],
            if (draft.typicalCrewSize > 0) ...[
              const SizedBox(height: 6),
              Text(
                'Typical Crew Size Needed: ${draft.typicalCrewSize} workers',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJobList(List<ProviderJob> jobs, String emptyDesc, AppLocalizations l10n) {
    if (jobs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.work_outline_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              l10n.providerNoJobsTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            Text(
              emptyDesc,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: jobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final job = jobs[index];
        return _buildJobCard(job, l10n);
      },
    );
  }

  Widget _buildJobCard(ProviderJob job, AppLocalizations l10n) {
    final slotsFilledText = l10n.providerSlotsCounter(job.slotsFilled, job.slotsTotal);
    final slotsOpenText = job.isFilled ? 'Fully Filled' : l10n.providerSlotsOpenCount(job.slotsOpen);

    Color statusColor = AppColors.headerGreenDark;
    String statusBadge = 'Open';
    if (job.isFilled) {
      statusColor = AppColors.amberOrange;
      statusBadge = 'Filled';
    } else if (job.isCompleted) {
      statusColor = Colors.blueGrey;
      statusBadge = 'Completed';
    } else if (job.isPaused) {
      statusColor = Colors.orange;
      statusBadge = 'Paused';
    } else if (job.isCancelled) {
      statusColor = Colors.red;
      statusBadge = 'Cancelled';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category and Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    job.categoryName,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusBadge,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 20),
                      onSelected: (val) => _handleJobAction(job, val, l10n),
                      itemBuilder: (context) => [
                        if (job.isOpen || job.isPaused) ...[
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, size: 18),
                                const SizedBox(width: 8),
                                Text(l10n.providerActionEdit),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: job.isPaused ? 'resume' : 'pause',
                            child: Row(
                              children: [
                                Icon(job.isPaused ? Icons.play_arrow_outlined : Icons.pause_outlined, size: 18),
                                const SizedBox(width: 8),
                                Text(job.isPaused ? l10n.providerActionResume : l10n.providerActionPause),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'cancel',
                            child: Row(
                              children: [
                                const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                                const SizedBox(width: 8),
                                Text(l10n.providerActionCancel, style: const TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Job Title
            Text(
              job.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),

            const SizedBox(height: 6),

            // Wage and Timing
            Row(
              children: [
                Text(
                  job.formattedWage,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.headerGreenDark, fontSize: 13),
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd MMM, hh:mm a').format(job.startAt),
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Slot Progress Indicator
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: job.slotsTotal > 0 ? (job.slotsFilled / job.slotsTotal).clamp(0.0, 1.0) : 0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        job.isFilled ? AppColors.amberOrange : AppColors.headerGreenDark,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Slot Counters Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  slotsFilledText,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                Text(
                  slotsOpenText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: job.isFilled ? AppColors.amberOrange : AppColors.headerGreenDark,
                  ),
                ),
              ],
            ),

            const Divider(height: 20),

            // Actions Row: View Applicants button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.providerApplicantsBadge(job.applicantCount),
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.headerGreenDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: () => context.push('/provider/jobs/${job.id}/applicants'),
                  icon: const Icon(Icons.people_alt_rounded, size: 16),
                  label: Text(l10n.providerViewApplicants, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleJobAction(ProviderJob job, String action, AppLocalizations l10n) async {
    final notifier = ref.read(providerJobsNotifierProvider.notifier);

    if (action == 'edit') {
      context.push('/provider/jobs/${job.id}/edit');
    } else if (action == 'pause') {
      await notifier.updateJobStatus(job.id, 'draft');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.providerJobPausedSuccess)));
      }
    } else if (action == 'resume') {
      await notifier.updateJobStatus(job.id, 'open');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.providerJobResumedSuccess)));
      }
    } else if (action == 'cancel') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final hasHired = job.slotsFilled > 0;
          return AlertDialog(
            title: Text(l10n.providerCancelWarningTitle),
            content: Text(
              hasHired
                  ? l10n.providerCancelWarningHiredDesc(job.slotsFilled)
                  : l10n.providerCancelStandardDesc,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Keep Job'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.providerConfirmCancel),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        await notifier.updateJobStatus(job.id, 'cancelled');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.providerJobCancelledSuccess)));
        }
      }
    }
  }

  void _showNoShowHelpModal(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                const SizedBox(width: 10),
                Text(l10n.noShowHelpTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Text(l10n.noShowHelpDesc, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.report_problem_rounded, size: 18),
                label: Text(l10n.noShowReportButton, style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.noShowReportSuccess)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
