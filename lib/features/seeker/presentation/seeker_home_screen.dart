import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/config/env.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/compact_language_selector.dart';
import 'package:udyogasethu/core/widgets/user_avatar.dart';
import 'package:udyogasethu/features/seeker/data/seeker_home_repository.dart';
import 'package:udyogasethu/features/seeker/domain/job_recommendation.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_profile_draft.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_home_controller.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_wizard_controller.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

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

class SeekerHomeScreen extends ConsumerStatefulWidget {
  const SeekerHomeScreen({super.key});

  @override
  ConsumerState<SeekerHomeScreen> createState() => _SeekerHomeScreenState();
}

class _SeekerHomeScreenState extends ConsumerState<SeekerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getTimeGreeting(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return l10n?.goodMorning ?? 'Good Morning';
    } else if (hour < 17) {
      return l10n?.goodAfternoon ?? 'Good Afternoon';
    } else {
      return l10n?.goodEvening ?? 'Good Evening';
    }
  }

  void _showManualLocationPicker() {
    final l10n = AppLocalizations.of(context);
    final areas = [
      {'name': 'Koramangala, Bengaluru', 'lat': 12.9352, 'lng': 77.6101},
      {'name': 'Indiranagar, Bengaluru', 'lat': 12.9784, 'lng': 77.6408},
      {'name': 'HSR Layout, Bengaluru', 'lat': 12.9121, 'lng': 77.6446},
      {'name': 'Whitefield, Bengaluru', 'lat': 12.9698, 'lng': 77.7500},
      {'name': 'Richmond Town, Bengaluru', 'lat': 12.9650, 'lng': 77.5900},
      {'name': 'Electronic City, Bengaluru', 'lat': 12.8452, 'lng': 77.6602},
      {'name': 'Malleshwaram, Bengaluru', 'lat': 13.0031, 'lng': 77.5643},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppColors.headerGreenDark),
                      const SizedBox(width: 8),
                      Text(
                        l10n?.selectLocationArea ?? 'Select Location Area',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: areas.length,
                    itemBuilder: (context, index) {
                      final area = areas[index];
                      return ListTile(
                        leading: const Icon(Icons.near_me_rounded, color: AppColors.headerGreenDark, size: 20),
                        title: Text(area['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                        onTap: () {
                          ref.read(seekerLocationProvider.notifier).setManualArea(
                                area['name'] as String,
                                area['lat'] as double,
                                area['lng'] as double,
                              );
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSosDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.shield_rounded, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('Emergency SOS', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'SOS emergency dispatch is activated in Phase 7.3. For immediate real-world assistance, dial 112 (National Emergency Helpline).',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.trustSafetyCentre);
              },
              child: const Text('Safety Hub'),
            ),
          ],
        );
      },
    );
  }

  void _showWhySeeingAdDialog(SponsoredAdBanner ad) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.headerGreenDark),
                    const SizedBox(width: 8),
                    const Text('Why am I seeing this?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  ad.whyText ??
                      'You are seeing this sponsored suggestion because you have consented to personalized partner offers in Privacy Settings. UdyogaSethu only partners with verified Indian manufacturers.',
                  style: const TextStyle(fontSize: 14, color: AppColors.textDark, height: 1.4),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push(AppRoutes.privacyCentre);
                    },
                    child: const Text('Manage Ad Consents in Privacy Centre'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(seekerHomeProfileProvider);
    final summaryAsync = ref.watch(seekerHomeSummaryProvider);
    final recommendationsAsync = ref.watch(seekerRecommendedJobsProvider);
    final adBannerAsync = ref.watch(seekerAdBannerProvider);
    final isAdDismissed = ref.watch(seekerAdDismissedProvider);
    final hasGpsConsentAsync = ref.watch(seekerHasGpsConsentProvider);
    final locationState = ref.watch(seekerLocationProvider);
    final appliedJobIds = ref.watch(seekerAppliedJobsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(seekerHomeProfileProvider);
          ref.invalidate(seekerHomeSummaryProvider);
          ref.invalidate(seekerRecommendedJobsProvider);
          ref.invalidate(seekerAdBannerProvider);
          ref.invalidate(seekerHasGpsConsentProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. GRADIENT HEADER (Screen 6 in UI_REFERENCE.md)
              _buildGradientHeader(context, profileAsync, locationState),

              // 2. SEARCH BAR WITH MIC ICON
              _buildSearchBar(context),

              // 3. DASHBOARD CARD: TODAY'S GOAL RING + WALLET BALANCE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildDashboardCard(context, summaryAsync),
              ),

              const SizedBox(height: 12),

              // 4. SAFETY MONITORING BANNER (Gated on GPS Consent)
              hasGpsConsentAsync.when(
                data: (hasConsent) => hasConsent
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildSafetyMonitoringBanner(context),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),

              // 5. QUICK ACTIONS 4-COLUMN GRID
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildQuickActionsGrid(context),
              ),

              const SizedBox(height: 16),

              // 6. SPONSORED CARD (From ad_banners, Gated on Ads Consent, Dismissible)
              if (!isAdDismissed)
                adBannerAsync.when(
                  data: (ad) => ad != null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _buildSponsoredCard(context, ad),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) => const SizedBox.shrink(),
                ),

              const SizedBox(height: 16),

              // 7. COMPACT WORKER PROFILE & BADGE OVERVIEW (Maintains backward compatibility with tests)
              profileAsync.when(
                data: (draft) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildWorkerStatusCard(context, draft),
                ),
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 20),

              // 8. RECOMMENDED FOR YOU (JobCard List with Skeleton / Empty / Error)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildRecommendationsSection(
                  context,
                  recommendationsAsync,
                  appliedJobIds,
                  profileAsync.value?.seekerType ?? 'informal',
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientHeader(
    BuildContext context,
    AsyncValue<SeekerProfileDraft> profileAsync,
    SeekerLocationState locationState,
  ) {
    final l10n = AppLocalizations.of(context);
    final userName = profileAsync.value?.fullName.trim().isNotEmpty == true
        ? profileAsync.value!.fullName
        : 'Job Seeker';

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.headerGreenDark, Color(0xFF064E3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Brand Logo / Role Switcher + SOS pill + Bell + Profile Avatar
          Row(
            children: [
              // Logo & App Name
              const Icon(Icons.handshake_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                l10n?.seekerHomeTitle ?? 'Seeker Home',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),

              // SOS Pill Button
              InkWell(
                onTap: _showSosDialog,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Multi-Role Dev Switcher (if enabled)
              if (kAllowMultiRole)
                IconButton(
                  icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 20),
                  tooltip: 'Switch Role',
                  onPressed: () => context.push(AppRoutes.devRole),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),

              // Language Selector
              const CompactLanguageSelector(),

              const SizedBox(width: 4),

              // Notification Bell with Unread Dot
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => context.push(AppRoutes.kycSafetyOnboarding),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 10),

              // Profile Avatar
              InkWell(
                onTap: () => context.push(AppRoutes.digitalId),
                borderRadius: BorderRadius.circular(20),
                child: UserAvatar(
                  avatarPath: profileAsync.value?.avatarUrl,
                  name: userName,
                  radius: 17,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Greeting Line
          Text(
            '${_getTimeGreeting(context)} • Welcome back, $userName! 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          // Location Chip with Reverse Text & Area Switcher
          InkWell(
            onTap: _showManualLocationPicker,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    locationState.isGps ? Icons.my_location_rounded : Icons.location_on_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    locationState.displayName,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  ref.read(seekerSearchQueryProvider.notifier).set(val);
                },
                decoration: InputDecoration(
                  hintText: l10n?.searchJobsPlaceholder ?? 'Search jobs, services...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.mic_rounded, color: AppColors.headerGreenDark, size: 22),
              tooltip: 'Voice Search (Arriving in P8.1)',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Multilingual AI Voice Assistant arriving in Phase 8.1')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, AsyncValue<SeekerHomeSummary> summaryAsync) {
    final summary = summaryAsync.value ?? const SeekerHomeSummary();
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.headerGreenDark,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.headerGreenDark.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Today's Goal Donut Ring
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: summary.goalProgress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
                Text(
                  '${summary.goalPercentage}%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Goal & Balance Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.todaysGoal ?? "Today's Goal",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  '₹${summary.todayEarningsRupees.toStringAsFixed(0)} / ₹${summary.dailyGoalRupees.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),

                // Inner Wallet Sub-Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.walletBalance ?? 'Wallet Balance',
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                          Text(
                            '₹${summary.walletBalanceRupees.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Escrow Protected Wallet arrives in Phase 5.1')),
                          );
                        },
                        child: Text(
                          l10n?.viewWallet ?? 'View Wallet >',
                          style: const TextStyle(color: Color(0xFFA7F3D0), fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyMonitoringBanner(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.paleMint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorderGreen),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, color: AppColors.headerGreenDark, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n?.locationSharingActive ?? 'Location sharing active for safety monitoring',
              style: const TextStyle(fontSize: 12, color: AppColors.headerGreenDark, fontWeight: FontWeight.w500),
            ),
          ),
          InkWell(
            onTap: () => context.push(AppRoutes.privacyCentre),
            child: Text(
              l10n?.changeLocation ?? 'Change >',
              style: const TextStyle(fontSize: 12, color: AppColors.headerGreenDark, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final actions = [
      {
        'label': l10n?.actionNearbyJobs ?? 'Nearby Jobs',
        'icon': Icons.near_me_rounded,
        'onTap': () => context.push(AppRoutes.seekerJobs),
      },
      {
        'label': l10n?.actionAiAssistant ?? 'AI Assistant',
        'icon': Icons.auto_awesome_rounded,
        'onTap': () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI Voice Assistant arriving in Phase 8.1')),
          );
        },
      },
      {
        'label': l10n?.actionWallet ?? 'Wallet',
        'icon': Icons.account_balance_wallet_rounded,
        'onTap': () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wallet Ledger arrives in Phase 5.1')),
          );
        },
      },
      {
        'label': l10n?.actionSafetyHub ?? 'Safety Hub',
        'icon': Icons.health_and_safety_rounded,
        'onTap': () => context.push(AppRoutes.trustSafetyCentre),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.quickActionsHeader ?? 'QUICK ACTIONS',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        Row(
          children: actions.map((a) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: InkWell(
                  onTap: a['onTap'] as VoidCallback,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.paleMint,
                          child: Icon(a['icon'] as IconData, color: AppColors.headerGreenDark, size: 18),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          a['label'] as String,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSponsoredCard(BuildContext context, SponsoredAdBanner ad) {
    final l10n = AppLocalizations.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top tag row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n?.tagSponsored ?? 'SPONSORED',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  ad.sponsorName ?? 'Kirloskar Brothers Ltd',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _showWhySeeingAdDialog(ad),
                  child: Text(
                    l10n?.whyAmISeeingThis ?? 'Why am I seeing this?',
                    style: TextStyle(fontSize: 10, color: Colors.amber.shade900, decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    ref.read(seekerAdDismissedProvider.notifier).dismiss();
                  },
                  child: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ad.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            if (ad.body != null) ...[
              const SizedBox(height: 4),
              Text(
                ad.body!,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.headerGreenDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size(double.infinity, 36),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Opening offer: ${ad.title}')),
                );
              },
              child: Text(ad.ctaLabel ?? 'Explore Offer', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerStatusCard(BuildContext context, SeekerProfileDraft draft) {
    final seekerTypeDisplay = draft.seekerType == 'student'
        ? 'Student Seeker'
        : draft.seekerType == 'part_time'
            ? 'Part-Time Seeker'
            : 'Informal Seeker';

    final dailyRatePaise = draft.dailyRatePaise ?? 65000;
    final dailyRateText = '₹${(dailyRatePaise / 100).round()} / day';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.paleMint,
                  child: Icon(Icons.verified_user_rounded, color: AppColors.headerGreenDark, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Safety Onboarding & Verified Badge',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                      ),
                      Row(
                        children: [
                          Text(
                            seekerTypeDisplay,
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          const Text(' • ', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          Text(
                            dailyRateText,
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.headerGreenDark),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: () => context.push(AppRoutes.seekerJobs),
                  child: const Text('Find Jobs', style: TextStyle(color: AppColors.headerGreenDark, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                Container(width: 1, height: 14, color: Colors.grey.shade300),
                InkWell(
                  onTap: () => context.push(AppRoutes.kycSafetyOnboarding),
                  child: const Text('Complete Profile', style: TextStyle(color: AppColors.headerGreenDark, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection(
    BuildContext context,
    AsyncValue<List<JobRecommendation>> recommendationsAsync,
    Set<String> appliedJobIds,
    String seekerType,
  ) {
    final l10n = AppLocalizations.of(context);
    final searchQuery = ref.watch(seekerSearchQueryProvider).trim().toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              seekerType == 'student'
                  ? 'STUDENT & FLEXIBLE GIGS'
                  : (seekerType == 'part_time'
                      ? 'PART-TIME & FLEXIBLE SHIFTS'
                      : (l10n?.recommendedForYou ?? 'RECOMMENDED FOR YOU')),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
            ),
            const Spacer(),
            if (seekerType == 'student')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Text(
                  '🎓 Students Priority',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              )
            else if (seekerType == 'part_time')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: const Text(
                  '⏰ Flexible Shifts',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        recommendationsAsync.when(
          loading: () => _buildSkeletonLoaders(),
          error: (err, stack) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              children: [
                Text('Error loading recommendations: $err', style: const TextStyle(color: Colors.red, fontSize: 12)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.invalidate(seekerRecommendedJobsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (jobs) {
            final filtered = searchQuery.isEmpty
                ? jobs
                : jobs.where((j) => j.title.toLowerCase().contains(searchQuery)).toList();

            if (filtered.isEmpty) {
              return _buildEmptyState(context);
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final job = filtered[index];
                final isApplied = appliedJobIds.contains(job.id);
                return _buildJobCard(context, job, isApplied, seekerType);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildJobCard(BuildContext context, JobRecommendation job, bool isApplied, String seekerType) {
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Employer row
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.paleMint,
                  child: Icon(_getCategoryIcon(job.categoryIcon), color: AppColors.headerGreenDark, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              job.employerName,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (job.employerVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 14),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text('${job.employerRating.toStringAsFixed(1)} • ', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                          Text(job.formattedDistance, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Wage pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.paleMint,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorderGreen),
                  ),
                  child: Text(
                    job.formattedWage,
                    style: const TextStyle(color: AppColors.headerGreenDark, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Job Title
            Text(
              job.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),

            if (job.description != null) ...[
              const SizedBox(height: 4),
              Text(
                job.description!,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 10),

            // Explainer Reasons Chips (Strictly filter Students chips for non-student seekers)
            if (job.reasons.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: job.reasons
                    .where((r) => !r.contains('Students') || seekerType == 'student' || seekerType == 'part_time')
                    .take(3)
                    .map((r) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      r,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textDark),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 12),

            // Action row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isApplied ? Colors.grey.shade300 : AppColors.headerGreenDark,
                      foregroundColor: isApplied ? AppColors.textDark : Colors.white,
                      elevation: isApplied ? 0 : 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(double.infinity, 38),
                    ),
                    onPressed: isApplied
                        ? null
                        : () async {
                            final uid = Supabase.instance.client.auth.currentUser?.id;
                            if (uid != null) {
                              await ref.read(seekerHomeRepositoryProvider).applyToJob(
                                    jobId: job.id,
                                    workerId: uid,
                                  );
                            }
                            ref.read(seekerAppliedJobsProvider.notifier).add(job.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Applied to ${job.title}! ✓')),
                              );
                            }
                          },
                    child: Text(
                      isApplied ? (l10n?.applied ?? 'Applied ✓') : (l10n?.applyNow ?? 'Apply Now'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.work_off_outlined, color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(
            l10n?.noJobsNearYou ?? 'No jobs near you yet',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try widening your search area or selecting another neighbourhood.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            icon: const Icon(Icons.radar_rounded, size: 18),
            label: Text(l10n?.widenRadiusAction ?? 'Widen Search Radius (50 km)'),
            onPressed: () {
              ref.read(seekerSearchRadiusProvider.notifier).set(100000.0);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoaders() {
    return Column(
      children: List.generate(3, (index) {
        return Card(
          elevation: 0.5,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 18, backgroundColor: Colors.grey.shade200),
                    const SizedBox(width: 10),
                    Container(width: 120, height: 14, color: Colors.grey.shade200),
                    const Spacer(),
                    Container(width: 60, height: 20, color: Colors.grey.shade200),
                  ],
                ),
                const SizedBox(height: 14),
                Container(width: 180, height: 16, color: Colors.grey.shade200),
                const SizedBox(height: 8),
                Container(width: double.infinity, height: 12, color: Colors.grey.shade100),
                const SizedBox(height: 14),
                Container(width: double.infinity, height: 32, color: Colors.grey.shade200),
              ],
            ),
          ),
        );
      }),
    );
  }

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'plumbing':
        return Icons.plumbing_rounded;
      case 'format_paint':
      case 'painting':
        return Icons.format_paint_rounded;
      case 'local_shipping':
      case 'delivery':
        return Icons.local_shipping_rounded;
      case 'construction':
        return Icons.construction_rounded;
      case 'electrical_services':
      case 'electrician':
        return Icons.electrical_services_rounded;
      case 'carpenter':
        return Icons.carpenter_rounded;
      default:
        return Icons.work_rounded;
    }
  }
}
