import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/l10n/locale_controller.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/mic_fab.dart';
import 'package:udyogasethu/features/booking/domain/booking_draft.dart';
import 'package:udyogasethu/features/trust/data/trust_repository.dart';
import 'package:udyogasethu/features/trust/domain/job_history_item.dart';
import 'package:udyogasethu/features/trust/presentation/widgets/dispute_details_sheet.dart';
import 'package:udyogasethu/features/trust/presentation/widgets/raise_dispute_dialog.dart';
import 'package:udyogasethu/features/trust/presentation/widgets/rate_job_dialog.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

/// Screen 37: Job History and Ratings
/// Displays past job bookings, localized language banner, 5-star rating matrix,
/// one-tap rebooking, dispute reporting, favourites, and settings navigation.
class JobHistoryScreen extends ConsumerStatefulWidget {
  const JobHistoryScreen({super.key});

  @override
  ConsumerState<JobHistoryScreen> createState() => _JobHistoryScreenState();
}

class _JobHistoryScreenState extends ConsumerState<JobHistoryScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider);
    final historyAsync = ref.watch(jobHistoryProvider(_selectedFilter));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          l10n?.jobHistoryTitle ?? 'Job History & Ratings',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_rounded, color: Colors.white),
            tooltip: 'Favourites & Trust Circles',
            onPressed: () => context.push(AppRoutes.favourites),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: MicFab(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI Multilingual Voice Assistant arrives in P8.1.')),
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(jobHistoryProvider(_selectedFilter));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Language Preference Top Card (Screen 37 visual reference)
              _buildLanguageHeaderCard(context, currentLocale, l10n),

              const SizedBox(height: 18),

              // 2. Section Header: Job History
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n?.jobHistoryHeader ?? 'Job History',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      letterSpacing: 0.2,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppColors.headerGreenDark),
                    icon: const Icon(Icons.favorite_border_rounded, size: 16),
                    label: const Text('Favourites', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () => context.push(AppRoutes.favourites),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Filter Chips Row
              _buildFilterChips(l10n),

              const SizedBox(height: 14),

              // 3. Past Jobs List
              historyAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Could not load history: $err')),
                      TextButton(
                        onPressed: () => ref.refresh(jobHistoryProvider(_selectedFilter)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return _buildEmptyState(l10n);
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (ctx, index) {
                      return _buildJobCard(ctx, items[index], l10n);
                    },
                  );
                },
              ),

              const SizedBox(height: 28),

              // 4. Section Header: Settings (Screen 37 visual reference)
              Text(
                l10n?.settingsSectionHeader ?? 'Settings',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 12),

              // Settings Navigation Rows Card
              _buildSettingsCard(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // TOP LANGUAGE HEADER CARD (Screen 37: Language | English | Change)
  // ==========================================================================
  Widget _buildLanguageHeaderCard(
    BuildContext context,
    Locale currentLocale,
    AppLocalizations? l10n,
  ) {
    final languageName = _getLanguageDisplayName(currentLocale.languageCode);

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.paleMint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.translate_rounded, color: AppColors.headerGreenDark, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Language',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    languageName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.headerGreenDark,
                side: const BorderSide(color: AppColors.cardBorderGreen),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: const Size(0, 32),
              ),
              onPressed: () => context.push(AppRoutes.language),
              child: const Text('Change', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  String _getLanguageDisplayName(String code) {
    switch (code) {
      case 'kn':
        return '🇮🇳 ಕನ್ನಡ (Kannada)';
      case 'hi':
        return '🇮🇳 हिंदी (Hindi)';
      case 'te':
        return '🇮🇳 తెలుగు (Telugu)';
      case 'ta':
        return '🇮🇳 தமிழ் (Tamil)';
      case 'mr':
        return '🇮🇳 मराठी (Marathi)';
      case 'bn':
        return '🇮🇳 বাংলা (Bengali)';
      case 'or':
        return '🇮🇳 ଓଡ଼ିଆ (Odia)';
      default:
        return '🇬🇧 English';
    }
  }

  // ==========================================================================
  // STATUS FILTER CHIPS
  // ==========================================================================
  Widget _buildFilterChips(AppLocalizations? l10n) {
    final filters = [
      {'id': 'all', 'label': l10n?.filterAll ?? 'All'},
      {'id': 'completed', 'label': l10n?.filterCompleted ?? 'Completed'},
      {'id': 'disputed', 'label': l10n?.filterDisputed ?? 'Disputed'},
      {'id': 'in_progress', 'label': l10n?.filterInProgress ?? 'In Progress'},
      {'id': 'cancelled', 'label': l10n?.filterCancelled ?? 'Cancelled'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f['label']!),
              selected: isSelected,
              selectedColor: AppColors.headerGreenDark,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.headerGreenDark : Colors.grey.shade300,
              ),
              onSelected: (val) {
                if (val) {
                  setState(() => _selectedFilter = f['id']!);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================================================
  // PAST JOB CARD (Screen 37 Style: Icon, Title, Location • Time, Wage, Stars)
  // ==========================================================================
  Widget _buildJobCard(BuildContext context, JobHistoryItem item, AppLocalizations? l10n) {
    final hasUserReviewed = item.userReview != null;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category Icon, Job Title, Wage Badge, Favourite Heart
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.paleMint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(item.categorySlug),
                    color: AppColors.headerGreenDark,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (item.isDisputed)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFCA5A5)),
                              ),
                              child: const Text(
                                'Disputed',
                                style: TextStyle(color: Color(0xFFDC2626), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${item.area} • ${item.timeAgo}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${item.amountRupees}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.headerGreenDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Rating Stars
                    Row(
                      children: List.generate(5, (starIdx) {
                        return Icon(
                          starIdx < item.displayStars ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 14,
                          color: const Color(0xFFF59E0B),
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Counterparty info & favourite heart
            Row(
              children: [
                Text(
                  '${item.counterpartyRole == 'employer' ? 'Employer' : 'Worker'}: ${item.counterpartyName}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w600),
                ),
                if (item.counterpartyVerified) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified_rounded, size: 14, color: AppColors.headerGreenDark),
                ],
                const Spacer(),
                // Heart Favourite Icon Button
                IconButton(
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    item.isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: item.isFavourite ? Colors.red : AppColors.textMuted,
                  ),
                  tooltip: item.isFavourite ? 'Remove Favourite' : 'Save to Favourites',
                  onPressed: () async {
                    try {
                      final isNowFav = await ref.read(trustRepositoryProvider).toggleFavourite(item.counterpartyId);
                      ref.invalidate(jobHistoryProvider(_selectedFilter));
                      ref.invalidate(favouritesListProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isNowFav ? 'Added to Favourites' : 'Removed from Favourites'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (_) {}
                  },
                ),
              ],
            ),

            // User Review Comment Snippet if available
            if (hasUserReviewed && item.userReview!.comment != null && item.userReview!.comment!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  'Your review: "${item.userReview!.comment}"',
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Actions Row: Rate / Review, Dispute, Rebook
            Row(
              children: [
                // 1. Rate Button
                if (item.canReview) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD97706),
                      side: const BorderSide(color: Color(0xFFFCD34D)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                    ),
                    icon: const Icon(Icons.star_outline_rounded, size: 15),
                    label: const Text('Rate Job', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    onPressed: () {
                      RateJobDialog.show(
                        context,
                        assignmentId: item.assignmentId,
                        jobTitle: item.title,
                        counterpartyName: item.counterpartyName,
                        onReviewSubmitted: () => ref.invalidate(jobHistoryProvider(_selectedFilter)),
                      );
                    },
                  ),
                ] else if (hasUserReviewed) ...[
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You have already submitted a review for this job.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, size: 14, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Reviewed (${item.userReview!.stars}★)',
                            style: TextStyle(color: Colors.green.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(width: 8),

                // 2. Dispute Action / Dispute Info
                if (item.isDisputed && item.dispute != null) ...[
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 32),
                    ),
                    icon: const Icon(Icons.info_outline_rounded, size: 15),
                    label: const Text('Dispute Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    onPressed: () {
                      DisputeDetailsSheet.show(
                        context,
                        dispute: item.dispute!,
                        jobTitle: item.title,
                      );
                    },
                  ),
                ] else if (item.canDispute) ...[
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 32),
                    ),
                    icon: const Icon(Icons.warning_amber_rounded, size: 15),
                    label: const Text('Dispute', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
                    onPressed: () {
                      RaiseDisputeDialog.show(
                        context,
                        assignmentId: item.assignmentId,
                        jobTitle: item.title,
                        counterpartyName: item.counterpartyName,
                        onDisputeRaised: () => ref.invalidate(jobHistoryProvider(_selectedFilter)),
                      );
                    },
                  ),
                ],

                const Spacer(),

                // 3. Rebook / Reorder Button (One-tap prefilled into P4.6 booking flow)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.headerGreenDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 32),
                  ),
                  icon: const Icon(Icons.replay_rounded, size: 15),
                  label: const Text('Rebook', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  onPressed: () => _handleRebook(context, item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleRebook(BuildContext context, JobHistoryItem item) {
    final draft = BookingDraft(
      workerId: item.counterpartyRole == 'worker' ? item.counterpartyId : 'rebook_partner',
      workerName: item.counterpartyRole == 'worker' ? item.counterpartyName : 'Partner',
      categoryName: item.categoryName,
      title: item.title,
      notes: item.description ?? '',
      dailyRatePaise: item.wagePaise > 0 ? item.wagePaise : 60000,
      wagePaise: item.wagePaise > 0 ? item.wagePaise : 60000,
      selectedDate: DateTime.now().add(const Duration(days: 1)),
      manualAddressText: item.area,
      currentStep: 1,
    );

    context.push(AppRoutes.providerBooking, extra: draft);
  }

  IconData _getCategoryIcon(String slug) {
    switch (slug.toLowerCase()) {
      case 'construction':
        return Icons.construction_rounded;
      case 'delivery':
        return Icons.delivery_dining_rounded;
      case 'electrician':
        return Icons.electrical_services_rounded;
      case 'plumber':
        return Icons.plumbing_rounded;
      case 'housekeeping':
        return Icons.cleaning_services_rounded;
      case 'carpenter':
        return Icons.handyman_rounded;
      case 'agriculture':
      case 'farming':
        return Icons.agriculture_rounded;
      default:
        return Icons.work_rounded;
    }
  }

  // ==========================================================================
  // SETTINGS CARD (Screen 37: My Bookings >, Privacy >, Help & Support >)
  // ==========================================================================
  Widget _buildSettingsCard(BuildContext context, AppLocalizations? l10n) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildSettingRow(
            icon: Icons.calendar_month_rounded,
            title: 'My Bookings',
            subtitle: 'Active shifts and upcoming schedules',
            onTap: () => context.push(AppRoutes.workerSchedule),
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingRow(
            icon: Icons.lock_outline_rounded,
            title: 'Privacy',
            subtitle: 'Consent center and permissions',
            onTap: () => context.push(AppRoutes.privacyCentre),
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingRow(
            icon: Icons.headset_mic_rounded,
            title: 'Help & Support',
            subtitle: 'Trust & Safety Centre, rights and disputes',
            onTap: () => context.push(AppRoutes.trustSafetyCentre),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.headerGreenDark, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      onTap: onTap,
    );
  }

  Widget _buildEmptyState(AppLocalizations? l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.paleMint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded, size: 36, color: AppColors.headerGreenDark),
          ),
          const SizedBox(height: 14),
          const Text(
            'No Job History Found',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          const Text(
            'Completed and disputed jobs will appear here with reviews and ratings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
