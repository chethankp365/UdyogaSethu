import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/community/data/community_repository.dart';
import 'package:udyogasethu/features/community/domain/community_models.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class CommunityHubScreen extends ConsumerStatefulWidget {
  const CommunityHubScreen({super.key});

  @override
  ConsumerState<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends ConsumerState<CommunityHubScreen> {
  String? _selectedKind;
  final Set<String> _registeringEventIds = {};

  Future<void> _handleRegisterEvent(
      BuildContext context, TrainingEvent event, AppLocalizations l10n) async {
    setState(() => _registeringEventIds.add(event.id));
    try {
      await ref
          .read(communityRepositoryProvider)
          .registerForTrainingEvent(event.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${event.title} - ${l10n.communityEventRegistered}'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(trainingEventsProvider);
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
      if (mounted) setState(() => _registeringEventIds.remove(event.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trustAsync = ref.watch(localityTrustProvider);
    final postsAsync = ref.watch(communityPostsProvider(_selectedKind));
    final eventsAsync = ref.watch(trainingEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.communityHubTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.school_outlined),
            tooltip: l10n.learningHubTitle,
            onPressed: () => context.push(AppRoutes.learning),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.headerGreenDark,
        onRefresh: () async {
          ref.invalidate(localityTrustProvider);
          ref.invalidate(communityPostsProvider(_selectedKind));
          ref.invalidate(trainingEventsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Locality Trust Index Card
              trustAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: AppColors.headerGreenDark),
                  ),
                ),
                error: (_, _) => const SizedBox.shrink(),
                data: (trust) => _buildLocalityTrustCard(context, trust, l10n),
              ),
              const SizedBox(height: 16),

              // 2. Learning Hub Banner Shortcut
              _buildLearningShortcut(context, l10n),
              const SizedBox(height: 20),

              // 3. Upcoming Training Events & Camps
              _buildEventsSection(context, eventsAsync, l10n),
              const SizedBox(height: 24),

              // 4. Community Wall Filters & Posts
              _buildCommunityWallSection(context, postsAsync, l10n),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocalityTrustCard(
      BuildContext context, LocalityTrustIndex trust, AppLocalizations l10n) {
    Color badgeBg;
    Color badgeFg;
    String badgeText;

    switch (trust.level) {
      case TrustLevel.high:
        badgeBg = AppColors.mintBackground;
        badgeFg = AppColors.headerGreenDark;
        badgeText = l10n.communityTrustHigh;
        break;
      case TrustLevel.needsImprovement:
        badgeBg = AppColors.dangerBackground;
        badgeFg = AppColors.errorRed;
        badgeText = l10n.communityTrustNeedsImprovement;
        break;
      case TrustLevel.medium:
        badgeBg = Colors.amber.shade50;
        badgeFg = Colors.amber.shade900;
        badgeText = l10n.communityTrustMedium;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined,
                        color: AppColors.headerGreenDark, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.communityLocalityTrustTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeFg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            trust.localityName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.communityTrustStats(
              trust.disputeFreePercent.toStringAsFixed(1),
              trust.completedJobsCount,
            ),
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningShortcut(BuildContext context, AppLocalizations l10n) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.mintBackground,
        borderRadius: BorderRadius.all(Radius.circular(14)),
        border: Border.fromBorderSide(BorderSide(color: AppColors.cardBorderGreen)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.headerGreenDark,
            child: Icon(Icons.school, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.learningHubTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  l10n.learningHubSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.headerGreenDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => context.push(AppRoutes.learning),
              child: Text(l10n.learningModuleStart),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsSection(
      BuildContext context, AsyncValue<List<TrainingEvent>> eventsAsync, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.event_available_outlined,
                color: AppColors.headerGreenDark, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.communityUpcomingEvents,
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
        eventsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(color: AppColors.headerGreenDark),
            ),
          ),
          error: (err, _) => Text(err.toString(), style: const TextStyle(color: AppColors.textMuted)),
          data: (events) {
            if (events.isEmpty) {
              return const Text(
                'No upcoming events scheduled right now.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, index) {
                final ev = events[index];
                final isRegistering = _registeringEventIds.contains(ev.id);

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              ev.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ev.kind.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (ev.description != null && ev.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          ev.description!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ev.venue,
                              style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            ev.startsAt.toLocal().toString().split('.')[0],
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: SizedBox(
                          width: double.infinity,
                          child: ev.isRegistered
                              ? OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.headerGreenDark,
                                    side: const BorderSide(color: AppColors.headerGreenDark),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: null,
                                  icon: const Icon(Icons.check, size: 16),
                                  label: Text(l10n.communityEventRegistered),
                                )
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.headerGreenDark,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: isRegistering
                                      ? null
                                      : () => _handleRegisterEvent(context, ev, l10n),
                                  child: isRegistering
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(l10n.communityRegisterEvent),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommunityWallSection(
      BuildContext context, AsyncValue<List<CommunityPost>> postsAsync, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.forum_outlined, color: AppColors.headerGreenDark, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.communityHeroSpotlights,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All', null),
              const SizedBox(width: 8),
              _buildFilterChip('Heroes', 'hero'),
              const SizedBox(width: 8),
              _buildFilterChip('Stories', 'story'),
              const SizedBox(width: 8),
              _buildFilterChip('Tips', 'tip'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        postsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(color: AppColors.headerGreenDark),
            ),
          ),
          error: (err, _) => Text(err.toString(), style: const TextStyle(color: AppColors.textMuted)),
          data: (posts) {
            if (posts.isEmpty) {
              return const Text(
                'No community posts yet in this category.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: posts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) {
                final post = posts[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.mintBackground,
                            child: Icon(Icons.person,
                                color: AppColors.headerGreenDark, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.authorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  '${post.authorRole} · ${post.locality ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: post.kind == 'hero'
                                  ? Colors.amber.shade50
                                  : AppColors.mintBackground,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              post.kind.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: post.kind == 'hero'
                                    ? Colors.amber.shade900
                                    : AppColors.headerGreenDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        post.body,
                        style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String? kind) {
    final isSelected = _selectedKind == kind;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedKind = kind);
        ref.invalidate(communityPostsProvider(kind));
      },
      selectedColor: AppColors.headerGreenDark,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textDark,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
