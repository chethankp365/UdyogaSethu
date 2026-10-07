import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/user_avatar.dart';
import 'package:udyogasethu/features/provider/data/worker_search_repository.dart';
import 'package:udyogasethu/features/provider/domain/worker_detail_profile.dart';
import 'package:udyogasethu/features/provider/presentation/worker_search_controller.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class WorkerProfileScreen extends ConsumerStatefulWidget {
  final String workerId;

  const WorkerProfileScreen({
    super.key,
    required this.workerId,
  });

  @override
  ConsumerState<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends ConsumerState<WorkerProfileScreen> {
  bool? _isFavOverride;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(workerDetailProfileProvider(widget.workerId));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          l10n.workerProfileTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Profile',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Worker profile link copied to clipboard.')),
              );
            },
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Error loading profile: $err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(workerDetailProfileProvider(widget.workerId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (profile) {
          final isFav = _isFavOverride ?? profile.isFavourite;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Card: Avatar, Name, Headline, Chips
                      _buildHeaderCard(profile, isFav, l10n),

                      const SizedBox(height: 16),

                      // Stat Counters (Jobs, Experience, Radius, Rating)
                      _buildStatRow(profile),

                      const SizedBox(height: 16),

                      // Wage Rates Card
                      _buildRateCard(profile, l10n),

                      const SizedBox(height: 16),

                      // Trust & Verification Badges
                      _buildTrustBadges(profile, l10n),

                      const SizedBox(height: 16),

                      // Bio / About Worker
                      _buildBioSection(profile, l10n),

                      const SizedBox(height: 16),

                      // Skills & Languages
                      _buildSkillsAndLanguages(profile, l10n),

                      const SizedBox(height: 16),

                      // Employer Reviews & Ratings
                      _buildReviewsSection(profile, l10n),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

              // Bottom Sticky Action Bar
              _buildBottomActionBar(profile, l10n),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(WorkerDetailProfile profile, bool isFav, AppLocalizations l10n) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(
                  avatarPath: profile.avatarPath,
                  name: profile.fullName,
                  radius: 36,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              profile.fullName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (profile.isVerifiedBadge)
                            const Icon(Icons.verified_rounded, size: 18, color: AppColors.headerGreenDark),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.headline,
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: AppColors.amberOrange),
                          const SizedBox(width: 2),
                          Text(
                            '${profile.ratingAvg.toStringAsFixed(1)} (${profile.ratingCount} reviews)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${profile.formattedDistance}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Recently Viewed and Favourite Chips
            Row(
              children: [
                // Recently Viewed Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        l10n.workerProfileRecentlyViewed,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Favourite Button Chip
                ActionChip(
                  avatar: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 16,
                    color: isFav ? Colors.red : AppColors.textMuted,
                  ),
                  label: Text(
                    l10n.workerProfileFavourite,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isFav ? Colors.red : AppColors.textDark,
                    ),
                  ),
                  backgroundColor: isFav ? Colors.red.shade50 : Colors.white,
                  side: BorderSide(color: isFav ? Colors.red.shade200 : Colors.grey.shade300),
                  onPressed: () async {
                    final nextFav = !isFav;
                    setState(() => _isFavOverride = nextFav);
                    await ref.read(workerSearchRepositoryProvider).toggleFavourite(profile.userId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 2),
                          content: Text(
                            nextFav
                                ? '${l10n.workerProfileFavouriteAdded} (P4.11)'
                                : l10n.workerProfileFavouriteRemoved,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(WorkerDetailProfile profile) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Jobs Done',
            value: '${profile.jobsCompleted}',
            icon: Icons.work_history_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Experience',
            value: '${profile.experienceYears.toStringAsFixed(1)} yrs',
            icon: Icons.timeline_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Radius',
            value: '${profile.serviceRadiusKm.round()} km',
            icon: Icons.radar_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Status',
            value: profile.availability == 'available' ? 'Available' : 'Busy',
            icon: Icons.bolt_rounded,
            valueColor: profile.availability == 'available' ? AppColors.headerGreenDark : AppColors.amberOrange,
          ),
        ),
      ],
    );
  }

  Widget _buildRateCard(WorkerDetailProfile profile, AppLocalizations l10n) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payments_rounded, color: AppColors.headerGreenDark, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.workerProfileRates,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.paleMint,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorderGreen),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Daily Shift Rate (8 hrs)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Text(
                          profile.formattedDailyRate,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hourly Rate', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Text(
                          profile.formattedHourlyRate,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                      ],
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

  Widget _buildTrustBadges(WorkerDetailProfile profile, AppLocalizations l10n) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: AppColors.headerGreenDark, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.workerProfileTrustBadges,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...profile.trustBadges.map((b) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      b.verified ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: b.verified ? AppColors.headerGreenDark : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      b.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: b.verified ? FontWeight.w600 : FontWeight.normal,
                        color: b.verified ? AppColors.textDark : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBioSection(WorkerDetailProfile profile, AppLocalizations l10n) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.workerProfileBio,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              profile.bio,
              style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsAndLanguages(WorkerDetailProfile profile, AppLocalizations l10n) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.workerProfileSkills,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: profile.skills.map((s) {
                return Chip(
                  label: Text(s.name),
                  backgroundColor: AppColors.paleMint,
                  side: const BorderSide(color: AppColors.cardBorderGreen),
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.headerGreenDark),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.workerProfileLanguages,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: profile.languages.map((l) {
                return Chip(
                  avatar: const Icon(Icons.language_rounded, size: 14, color: Colors.blue),
                  label: Text(l.toUpperCase()),
                  backgroundColor: Colors.blue.shade50,
                  side: BorderSide(color: Colors.blue.shade200),
                  labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection(WorkerDetailProfile profile, AppLocalizations l10n) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.workerProfileReviews,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                ),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 18, color: AppColors.amberOrange),
                    const SizedBox(width: 4),
                    Text(
                      profile.ratingAvg.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (profile.reviews.isEmpty)
              const Text('No reviews yet for this worker.', style: TextStyle(color: AppColors.textMuted))
            else
              ...profile.reviews.map((r) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            r.raterName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < r.stars ? Icons.star_rounded : Icons.star_border_rounded,
                                size: 14,
                                color: AppColors.amberOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (r.comment != null && r.comment!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          r.comment!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textDark, height: 1.3),
                        ),
                      ],
                      if (r.createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          r.createdAt!,
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(WorkerDetailProfile profile, AppLocalizations l10n) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.headerGreenDark,
                  side: const BorderSide(color: AppColors.headerGreenDark, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                label: Text(l10n.workerProfileChat, style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('${l10n.workerProfileChat} (P7.1)'),
                      content: Text(
                        'Direct messaging and masked phone proxy with ${profile.fullName} will be fully enabled in Step P7.1.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.headerGreenDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.calendar_month_rounded, size: 20),
                label: Text(l10n.workerProfileBookNow, style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.hubBookWorker),
                      content: Text(
                        'Booking ${profile.fullName} for ${profile.formattedDailyRate}.\n\nDirect booking flow with unverified worker notice and schedule conflict protection will be completed in Step P4.6.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Got it'),
                        ),
                      ],
                    ),
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: valueColor ?? AppColors.textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
