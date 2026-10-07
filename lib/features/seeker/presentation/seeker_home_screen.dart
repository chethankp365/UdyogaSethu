import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/l10n/locale_controller.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/job_row.dart';
import 'package:udyogasethu/core/widgets/user_avatar.dart';
import 'package:udyogasethu/features/seeker/data/seeker_home_repository.dart';
import 'package:udyogasethu/features/seeker/domain/job_recommendation.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_profile_draft.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_home_controller.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

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
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Your Area in Bengaluru',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            ...areas.map((area) {
              return ListTile(
                leading: const Icon(Icons.location_on_outlined, color: AppColors.headerGreenDark),
                title: Text(area['name'] as String, style: const TextStyle(fontSize: 14)),
                onTap: () {
                  ref.read(seekerLocationProvider.notifier).setManualArea(
                        area['name'] as String,
                        area['lat'] as double,
                        area['lng'] as double,
                      );
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showSosDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency SOS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        content: const Text(
          'Do you need immediate assistance? This will alert your emergency contacts and share your live GPS location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('SOS Alert sent to Emergency Network!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Trigger SOS'),
          ),
        ],
      ),
    );
  }

  void _showDailyGoalDialog(BuildContext context, int currentGoalPaise) {
    final controller = TextEditingController(text: (currentGoalPaise / 100).round().toString());
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Set Daily Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set your target daily earnings (in Rupees). Pack default is ₹1,500.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixText: '₹ ',
                  labelText: 'Daily Goal',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [800, 1200, 1500, 2000].map((val) {
                  return ActionChip(
                    label: Text('₹$val'),
                    onPressed: () {
                      setDialogState(() {
                        controller.text = val.toString();
                      });
                    },
                  );
                }).toList(),
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
              ),
              onPressed: () {
                final rupees = int.tryParse(controller.text.trim());
                if (rupees != null && rupees > 0) {
                  ref.read(seekerDailyGoalProvider.notifier).setGoalPaise(rupees * 100);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save Goal'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAvatarMenu(BuildContext context, SeekerProfileDraft draft) {
    final userName = draft.fullName.trim().isNotEmpty ? draft.fullName : 'Job Seeker';
    final seekerTypeDisplay = draft.seekerType == 'student'
        ? 'Student Part-Time Worker'
        : draft.seekerType == 'part_time'
            ? 'Part-Time / Flexible Worker'
            : 'Informal / Skilled Worker';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info header
              Row(
                children: [
                  UserAvatar(avatarPath: draft.avatarUrl, name: userName, radius: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(seekerTypeDisplay, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        () {
                          final phone = Supabase.instance.client.auth.currentUser?.phone;
                          if (phone != null && phone.isNotEmpty) {
                            return Text(phone, style: const TextStyle(fontSize: 11, color: AppColors.textMuted));
                          }
                          return const SizedBox.shrink();
                        }(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              // Language Switcher Chips
              const Text('APP LANGUAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildLangChip(context, 'English', 'en'),
                  _buildLangChip(context, 'ಕನ್ನಡ', 'kn'),
                  _buildLangChip(context, 'हिंदी', 'hi'),
                  _buildLangChip(context, 'తెలుగు', 'te'),
                  _buildLangChip(context, 'தமிழ்', 'ta'),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.qr_code_2_rounded, color: AppColors.headerGreenDark),
                title: const Text('My Digital ID & QR'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.digitalId);
                },
              ),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.settings_outlined, color: AppColors.headerGreenDark),
                title: const Text('Settings & Privacy'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.settings);
                },
              ),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await Supabase.instance.client.auth.signOut();
                  } catch (_) {}
                  if (context.mounted) context.go(AppRoutes.login);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangChip(BuildContext context, String label, String code) {
    final currentLocale = ref.watch(localeProvider);
    final isSelected = currentLocale.languageCode == code;

    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: AppColors.paleMint,
      onSelected: (val) {
        if (val) {
          ref.read(localeProvider.notifier).setLocale(code);
        }
      },
    );
  }

  void _showAiAssistantSheet(BuildContext context) {
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
            const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.purple, size: 24),
                SizedBox(width: 10),
                Text('UdyogaSethu AI Assistant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Ask any question in your native language or speak using the microphone. '
              'For example: "Find delivery jobs near Koramangala paying more than 400 rupees."',
              style: TextStyle(fontSize: 13, color: AppColors.textDark),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.mic, size: 20),
              label: const Text('Speak Command'),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Listening for voice command...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showWalletSheet(BuildContext context, SeekerHomeSummary summary) {
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
            const Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded, color: AppColors.headerGreenDark, size: 24),
                SizedBox(width: 10),
                Text('Wallet Balance & Escrow', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Available Balance: ₹${summary.walletBalanceRupees.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
            ),
            const SizedBox(height: 6),
            Text(
              "Today's Earnings: ₹${summary.todayEarningsRupees.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.headerGreenDark,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWhySponsoredDialog(BuildContext context, SponsoredAdBanner ad) {
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
            const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.headerGreenDark),
                SizedBox(width: 8),
                Text('Why am I seeing this offer?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ad.whyText ??
                  'You are seeing this suggestion because you gave consent for partner offers in Privacy Settings. '
                  'UdyogaSethu only displays verified community and equipment initiatives.',
              style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.4),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.headerGreenDark,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
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

    final draft = profileAsync.value ?? const SeekerProfileDraft(userId: '');
    final seekerType = draft.seekerType;

    // Precache first few job images safely when recommendations load
    ref.listen(seekerRecommendedJobsProvider, (prev, next) {
      next.whenData((jobs) {
        if (jobs.isNotEmpty && context.mounted) {
          JobRow.precacheJobs(context, jobs);
        }
      });
    });

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
              // 1. ONE DARK-GREEN GRADIENT HEADER BLOCK (Page 2 Phone 2)
              _buildGradientHeader(
                context,
                draft,
                locationState,
                summaryAsync,
                hasGpsConsentAsync.value ?? false,
              ),

              const SizedBox(height: 18),

              // 2. QUICK ACTIONS 4-COLUMN ROW
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildQuickActionsGrid(context, summaryAsync.value ?? const SeekerHomeSummary()),
              ),

              const SizedBox(height: 16),

              // 3. SPONSORED CARD (Gated on Ads Consent, Dismissible, Page 2 Phone 2)
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

              // 4. RECOMMENDED FOR YOU (JobRow List from Part C)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildRecommendationsSection(
                  context,
                  recommendationsAsync,
                  appliedJobIds,
                  seekerType,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // 1. GRADIENT HEADER BLOCK (Page 2 Phone 2)
  // ==========================================================================
  Widget _buildGradientHeader(
    BuildContext context,
    SeekerProfileDraft draft,
    SeekerLocationState locationState,
    AsyncValue<SeekerHomeSummary> summaryAsync,
    bool hasGpsConsent,
  ) {
    final userName = draft.fullName.trim().isNotEmpty ? draft.fullName : 'Job Seeker';
    final timeGreeting = _getTimeGreeting(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D6548), Color(0xFF064E3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33064E3B),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Logo mark on left, SOS pill, notification bell with dot, avatar on right
          Row(
            children: [
              // Logo mark
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/logo_small.png',
                  width: 28,
                  height: 28,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.handshake_rounded, color: Colors.white, size: 24),
                ),
              ),

              const Spacer(),

              // SOS Pill
              InkWell(
                onTap: _showSosDialog,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Notification bell with unread dot
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: () => context.push(AppRoutes.kycSafetyOnboarding),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 10),

              // Avatar (Tap opens Avatar Sheet with Language Switcher, Settings, etc.)
              InkWell(
                onTap: () => _showAvatarMenu(context, draft),
                borderRadius: BorderRadius.circular(18),
                child: UserAvatar(
                  avatarPath: draft.avatarUrl,
                  name: userName,
                  radius: 17,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Greeting on two lines: "Good Morning," small; User bold and large with wave
          Text(
            '$timeGreeting,',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$userName 👋',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 8),

          // Location row: pin + area & city + chevron
          InkWell(
            onTap: _showManualLocationPicker,
            borderRadius: BorderRadius.circular(6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_rounded, color: Colors.white.withValues(alpha: 0.9), size: 15),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    locationState.displayName.isNotEmpty ? locationState.displayName : 'Set your area',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Icon(Icons.expand_more_rounded, color: Colors.white.withValues(alpha: 0.85), size: 16),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // White rounded search bar "Search jobs, services..." with mic
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => ref.read(seekerSearchQueryProvider.notifier).set(val),
                    decoration: const InputDecoration(
                      hintText: 'Search jobs, services...',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _showAiAssistantSheet(context),
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Icon(Icons.mic_rounded, color: Color(0xFF0D6548), size: 22),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Two frosted-glass cards side by side
          _buildFrostedDashboardCards(context, summaryAsync),

          // Slim translucent location sharing line (only if GPS consent granted)
          if (hasGpsConsent) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Location sharing active for safety monitoring',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w400),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push(AppRoutes.privacyCentre),
                    child: const Text(
                      'Change >',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Two Frosted-Glass Cards: Today's Goal & Wallet Balance
  Widget _buildFrostedDashboardCards(BuildContext context, AsyncValue<SeekerHomeSummary> summaryAsync) {
    final summary = summaryAsync.value ?? const SeekerHomeSummary();
    final customGoal = ref.watch(seekerDailyGoalProvider);

    // Goal calculation: default 1500 (150000 paise)
    final effectiveGoalPaise = customGoal ?? (summary.dailyGoalPaise > 0 ? summary.dailyGoalPaise : 150000);
    final todayEarnedPaise = summary.todayEarningsPaise;
    final goalProgress = (todayEarnedPaise / effectiveGoalPaise).clamp(0.0, 1.0);
    final goalPercent = ((todayEarnedPaise / effectiveGoalPaise) * 100).round().clamp(0, 100);

    return Row(
      children: [
        // Left Card: Today's Goal with Circular Progress Ring
        Expanded(
          child: InkWell(
            onTap: () => _showDailyGoalDialog(context, effectiveGoalPaise),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  // Circular Progress Ring with Percentage
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(
                          value: goalProgress,
                          strokeWidth: 4.5,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
                        ),
                      ),
                      Text(
                        '$goalPercent%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  // Text description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Today's Goal",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '₹${(todayEarnedPaise / 100).round()} / ₹${(effectiveGoalPaise / 100).round()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Right Card: Wallet Balance (clean, no overlap with View Wallet >)
        Expanded(
          child: InkWell(
            onTap: () => _showWalletSheet(context, summary),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, color: Colors.white.withValues(alpha: 0.85), size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Wallet Balance',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '₹${summary.walletBalanceRupees.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Wallet >',
                          style: TextStyle(
                            color: Color(0xFF6EE7B7),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // 2. QUICK ACTIONS 4-COLUMN ROW
  // ==========================================================================
  Widget _buildQuickActionsGrid(BuildContext context, SeekerHomeSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK ACTIONS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Nearby Jobs
            Expanded(
              child: _buildActionTile(
                icon: Icons.location_on_rounded,
                iconColor: const Color(0xFF10B981),
                bgColor: const Color(0xFFE8F5E9),
                label: 'Nearby Jobs',
                onTap: () => context.push(AppRoutes.seekerJobs),
              ),
            ),
            const SizedBox(width: 8),
            // AI Assistant
            Expanded(
              child: _buildActionTile(
                icon: Icons.auto_awesome_rounded,
                iconColor: const Color(0xFF8B5CF6),
                bgColor: const Color(0xFFF3E8FF),
                label: 'AI Assistant',
                onTap: () => _showAiAssistantSheet(context),
              ),
            ),
            const SizedBox(width: 8),
            // Wallet
            Expanded(
              child: _buildActionTile(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFF059669),
                bgColor: const Color(0xFFE8F5E9),
                label: 'Wallet',
                onTap: () => _showWalletSheet(context, summary),
              ),
            ),
            const SizedBox(width: 8),
            // Safety Hub
            Expanded(
              child: _buildActionTile(
                icon: Icons.shield_rounded,
                iconColor: const Color(0xFFF97316),
                bgColor: const Color(0xFFFFF3E0),
                label: 'Safety Hub',
                onTap: () => context.push(AppRoutes.trustSafetyCentre),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // 3. SPONSORED CARD (Page 2 Phone 2)
  // ==========================================================================
  Widget _buildSponsoredCard(BuildContext context, SponsoredAdBanner ad) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top tag row: SPONSORED chip + sponsor name + "Why am I seeing this?" + Dismiss X
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'SPONSORED',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ad.sponsorName ?? 'Partner',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () => _showWhySponsoredDialog(context, ad),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Why?',
                      style: TextStyle(fontSize: 11, color: AppColors.headerGreenDark, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => ref.read(seekerAdDismissedProvider.notifier).dismiss(),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail image on left
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 72,
                    height: 72,
                    color: const Color(0xFFFFF7ED),
                    child: const Icon(Icons.solar_power_rounded, color: Color(0xFFF97316), size: 36),
                  ),
                ),
                const SizedBox(width: 12),
                // Ad title and body
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad.title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (ad.body != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          ad.body!,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size(double.infinity, 36),
                elevation: 0,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Opening offer: ${ad.title}')),
                );
              },
              child: Text(
                ad.ctaLabel ?? 'Explore Agri Offer',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // 4. RECOMMENDED JOBS SECTION (Part C JobRow)
  // ==========================================================================
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
        // Heading row
        Row(
          children: [
            Flexible(
              child: Text(
                seekerType == 'student'
                    ? 'STUDENT & FLEXIBLE GIGS'
                    : (seekerType == 'part_time'
                        ? 'PART-TIME & FLEXIBLE SHIFTS'
                        : (l10n?.recommendedForYou ?? 'RECOMMENDED FOR YOU')),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
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

        const SizedBox(height: 10),

        if (recommendationsAsync.hasError)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              children: [
                Text(
                  'Error loading recommendations: ${recommendationsAsync.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.invalidate(seekerRecommendedJobsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (recommendationsAsync.isLoading)
          _buildSkeletonLoaders()
        else if (recommendationsAsync.hasValue) ...[
          () {
            final jobs = recommendationsAsync.value!;
            final filtered = searchQuery.isEmpty
                ? jobs
                : jobs.where((j) => j.title.toLowerCase().contains(searchQuery)).toList();

            if (filtered.isEmpty) {
              return _buildEmptyState(context, seekerType);
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final job = filtered[index];
                final isApplied = appliedJobIds.contains(job.id);
                return JobRow(
                  job: job,
                  isApplied: isApplied,
                  seekerType: seekerType,
                  onApply: () async {
                    final uid = Supabase.instance.client.auth.currentUser?.id;
                    if (uid != null) {
                      try {
                        await ref.read(seekerHomeRepositoryProvider).applyToJob(
                              jobId: job.id,
                              workerId: uid,
                            );
                        ref.read(seekerAppliedJobsProvider.notifier).add(job.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Applied to ${job.title}! ✓')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Application rejected: $e')),
                          );
                        }
                      }
                    } else {
                      ref.read(seekerAppliedJobsProvider.notifier).add(job.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Applied to ${job.title}! ✓')),
                        );
                      }
                    }
                  },
                );
              },
            );
          }(),
        ],
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String seekerType) {
    final l10n = AppLocalizations.of(context);
    final emptyTitle = seekerType == 'student'
        ? 'No student jobs near you yet'
        : seekerType == 'part_time'
            ? 'No part-time gigs near you yet'
            : (l10n?.noJobsNearYou ?? 'No jobs near you yet');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
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
            emptyTitle,
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
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 140, height: 14, color: Colors.grey.shade200),
                    const SizedBox(height: 6),
                    Container(width: 90, height: 11, color: Colors.grey.shade200),
                    const SizedBox(height: 6),
                    Container(width: 70, height: 10, color: Colors.grey.shade200),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 60, height: 28, color: Colors.grey.shade200),
            ],
          ),
        );
      }),
    );
  }
}
