import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/rewards/data/rewards_repository.dart';
import 'package:udyogasethu/features/rewards/domain/gamification_models.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class RewardsHubScreen extends ConsumerStatefulWidget {
  const RewardsHubScreen({super.key});

  @override
  ConsumerState<RewardsHubScreen> createState() => _RewardsHubScreenState();
}

class _RewardsHubScreenState extends ConsumerState<RewardsHubScreen> {
  final TextEditingController _referralInputController = TextEditingController();
  bool _isSubmittingReferral = false;

  @override
  void dispose() {
    _referralInputController.dispose();
    super.dispose();
  }

  void _showReferralDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.rewardsApplyReferral),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.rewardsReferralDesc,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _referralInputController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: l10n.rewardsApplyReferralPrompt,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.confirmation_number_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.headerGreenDark,
              foregroundColor: Colors.white,
            ),
            onPressed: _isSubmittingReferral
                ? null
                : () async {
                    final code = _referralInputController.text.trim();
                    if (code.isEmpty) return;
                    setState(() => _isSubmittingReferral = true);
                    try {
                      await ref
                          .read(rewardsRepositoryProvider)
                          .applyReferralCode(code);
                      if (context.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.rewardsApplyReferralSuccess),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        ref.invalidate(gamificationProfileProvider);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString().replaceAll('Exception: ', '')),
                            backgroundColor: AppColors.errorRed,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isSubmittingReferral = false);
                    }
                  },
            child: _isSubmittingReferral
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
  }

  void _showBadgeDetails(BuildContext context, BadgeItem badge, String locale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: badge.isEarned
                      ? AppColors.cardBorderGreen
                      : Colors.grey.shade200,
                  child: Icon(
                    badge.isEarned ? Icons.verified : Icons.lock_outline,
                    color: badge.isEarned
                        ? AppColors.headerGreenDark
                        : Colors.grey.shade600,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        badge.getName(locale),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        badge.isEarned ? 'Unlocked' : 'Locked',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: badge.isEarned ? AppColors.success : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'How to Earn:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              badge.criteriaDescription.isNotEmpty
                  ? badge.criteriaDescription
                  : 'Complete relevant verified tasks and maintain exemplary performance.',
              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
            ),
            if (badge.awardedAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Awarded on: ${badge.awardedAt!.toLocal().toString().split(' ')[0]}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.headerGreenDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final profileAsync = ref.watch(gamificationProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.rewardsHubTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined),
            tooltip: l10n.rewardsStoreTitle,
            onPressed: () => context.push(AppRoutes.rewardsStore),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.headerGreenDark),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.errorRed),
                const SizedBox(height: 12),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(gamificationProfileProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.headerGreenDark,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (profile) {
          return RefreshIndicator(
            color: AppColors.headerGreenDark,
            onRefresh: () async {
              ref.invalidate(gamificationProfileProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Level & XP Hero Card
                  _buildLevelHeroCard(context, profile, l10n),
                  const SizedBox(height: 16),

                  // 2. Active Level Perks
                  _buildLevelPerksCard(context, profile, l10n),
                  const SizedBox(height: 16),

                  // 3. Rewards Store Direct CTA
                  _buildStoreBanner(context, profile, l10n),
                  const SizedBox(height: 20),

                  // 4. Active Streaks
                  _buildStreaksSection(context, profile, l10n, locale),
                  const SizedBox(height: 20),

                  // 5. Achievement Badges Grid
                  _buildBadgesSection(context, profile, l10n, locale),
                  const SizedBox(height: 20),

                  // 6. Referral Card
                  _buildReferralCard(context, profile, l10n),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLevelHeroCard(
      BuildContext context, UserGamificationProfile profile, AppLocalizations l10n) {
    final curr = profile.currentLevel;
    final next = profile.nextLevel;
    final progress = (profile.progressPercent / 100.0).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.headerGreenDark, Color(0xFF044833)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Level ${curr.levelNumber}: ${curr.name}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.rewardsAvailablePoints(profile.availablePoints),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            l10n.rewardsTotalXp(profile.totalXp),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${curr.minXp} XP',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              Flexible(
                child: Text(
                  next != null
                      ? l10n.rewardsNextLevelIn(next.minXp - profile.totalXp, next.name)
                      : l10n.rewardsMaxLevel,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelPerksCard(
      BuildContext context, UserGamificationProfile profile, AppLocalizations l10n) {
    final curr = profile.currentLevel;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_outlined,
                    color: AppColors.headerGreenDark, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.rewardsLevelPerksTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPerkRow(
              icon: Icons.savings_outlined,
              title: l10n.rewardsPerkCommission(curr.commissionPercent.toStringAsFixed(1)),
              active: true,
            ),
            const SizedBox(height: 8),
            _buildPerkRow(
              icon: Icons.trending_up,
              title: l10n.rewardsPerkSearchBoost(curr.searchBoost.toStringAsFixed(2)),
              active: true,
            ),
            if (curr.hasPrioritySupport) ...[
              const SizedBox(height: 8),
              _buildPerkRow(
                icon: Icons.support_agent_outlined,
                title: l10n.rewardsPerkPrioritySupport,
                active: true,
              ),
            ],
            if (curr.hasPremiumJobs) ...[
              const SizedBox(height: 8),
              _buildPerkRow(
                icon: Icons.workspace_premium_outlined,
                title: l10n.rewardsPerkPremiumJobs,
                active: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPerkRow({
    required IconData icon,
    required String title,
    required bool active,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: active ? AppColors.headerGreenDark : AppColors.textMuted,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: active ? AppColors.textDark : AppColors.textMuted,
            ),
          ),
        ),
        const Icon(Icons.check_circle, size: 16, color: AppColors.success),
      ],
    );
  }

  Widget _buildStoreBanner(
      BuildContext context, UserGamificationProfile profile, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.mintBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorderGreen),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.headerGreenDark,
            child: Icon(Icons.redeem, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.rewardsStoreTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  l10n.rewardsAvailablePoints(profile.availablePoints),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.headerGreenDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => context.push(AppRoutes.rewardsStore),
              child: Text(l10n.rewardsStoreRedeemAction),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreaksSection(BuildContext context,
      UserGamificationProfile profile, AppLocalizations l10n, String locale) {
    final streaks = profile.streaks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_fire_department,
                color: AppColors.accentOrange, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.rewardsStreaksTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (streaks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Text(
              'Complete your first on-time verified job to ignite your streak!',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: streaks.map((s) {
              return Container(
                width: 160,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: s.isAtRisk
                        ? AppColors.errorRed.withValues(alpha: 0.5)
                        : AppColors.cardBorderGreen,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: s.isAtRisk ? AppColors.errorRed : AppColors.accentOrange,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${s.current}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: s.isAtRisk ? AppColors.errorRed : AppColors.textDark,
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            'Best ${s.best}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.kind == 'on_time_jobs'
                          ? l10n.rewardsStreakJobs(s.current)
                          : l10n.rewardsStreakDays(s.current),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (s.isAtRisk) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.rewardsStreakRisk,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.errorRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildBadgesSection(BuildContext context,
      UserGamificationProfile profile, AppLocalizations l10n, String locale) {
    final badges = profile.badges;
    final earnedCount = badges.where((b) => b.isEarned).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.military_tech_outlined,
                      color: AppColors.headerGreenDark, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.rewardsBadgesTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.rewardsBadgesEarned(earnedCount, badges.length),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: badges.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
          ),
          itemBuilder: (ctx, index) {
            final badge = badges[index];
            return InkWell(
              onTap: () => _showBadgeDetails(context, badge, locale),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: badge.isEarned ? AppColors.mintBackground : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: badge.isEarned
                        ? AppColors.cardBorderGreen
                        : Colors.grey.shade200,
                    width: badge.isEarned ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: badge.isEarned
                          ? AppColors.cardBorderGreen
                          : Colors.grey.shade100,
                      child: Icon(
                        badge.isEarned ? Icons.verified : Icons.lock_outline,
                        color: badge.isEarned
                            ? AppColors.headerGreenDark
                            : Colors.grey.shade400,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            badge.getName(locale),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: badge.isEarned
                                  ? AppColors.textDark
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReferralCard(
      BuildContext context, UserGamificationProfile profile, AppLocalizations l10n) {
    final code = profile.referralCode ?? 'SETU8822';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.share_outlined,
                      color: AppColors.headerGreenDark, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.rewardsReferralsTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.mintBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.rewardsReferralSuccessful(profile.successfulReferrals),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.headerGreenDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.rewardsReferralDesc,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 2,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.headerGreenDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.rewardsReferralCopied),
                        backgroundColor: AppColors.headerGreenDark,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text(l10n.rewardsReferralCopy),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _showReferralDialog(context, l10n),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.rewardsApplyReferral,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.headerGreenDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
