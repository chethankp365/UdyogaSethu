import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/user_avatar.dart';
import 'package:udyogasethu/features/booking/domain/booking_draft.dart';
import 'package:udyogasethu/features/trust/data/trust_repository.dart';
import 'package:udyogasethu/features/trust/domain/favourite_item.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

/// Screen displaying the user's saved Favourites & Trust Circles.
/// Enables 1-tap repeat bookings and quick access to trusted connections.
class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final favouritesAsync = ref.watch(favouritesListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          l10n?.favouritesTitle ?? 'Favourites & Trust Circles',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(favouritesListProvider),
        child: favouritesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Failed to load favourites: $err', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(favouritesListProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return _buildEmptyState(context, l10n);
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) {
                return _buildFavouriteCard(ctx, ref, items[index], l10n);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFavouriteCard(
    BuildContext context,
    WidgetRef ref,
    FavouriteItem item,
    AppLocalizations? l10n,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  avatarPath: item.avatarPath,
                  name: item.fullName,
                  radius: 26,
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
                              item.fullName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (item.isVerified)
                            const Icon(Icons.verified_rounded, size: 16, color: AppColors.headerGreenDark),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.headline,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Favourite Heart Button
                IconButton(
                  icon: const Icon(Icons.favorite_rounded, color: Colors.red),
                  tooltip: 'Remove from Favourites',
                  onPressed: () async {
                    try {
                      await ref.read(trustRepositoryProvider).toggleFavourite(item.targetId);
                      ref.invalidate(favouritesListProvider);
                      ref.invalidate(jobHistoryProvider(null));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.fullName} removed from favourites.'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (_) {}
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Rating & Stats Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                      const SizedBox(width: 3),
                      Text(
                        '${item.ratingAvg.toStringAsFixed(1)} (${item.ratingCount})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${item.jobsCompleted} jobs completed',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const Spacer(),
                if (item.dailyRateRupees > 0)
                  Text(
                    '₹${item.dailyRateRupees}/day',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.headerGreenDark),
                  ),
              ],
            ),

            // Skills Chips
            if (item.skills.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: item.skills.take(3).map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      skill,
                      style: const TextStyle(fontSize: 11, color: AppColors.textDark),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.headerGreenDark,
                    side: const BorderSide(color: AppColors.cardBorderGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 32),
                  ),
                  onPressed: () {
                    context.push('/provider/workers/${item.targetId}');
                  },
                  child: const Text('View Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.headerGreenDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: const Size(0, 32),
                  ),
                  icon: const Icon(Icons.flash_on_rounded, size: 14),
                  label: const Text('Book Again', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () {
                    final draft = BookingDraft(
                      workerId: item.targetId,
                      workerName: item.fullName,
                      categoryName: item.skills.isNotEmpty ? item.skills.first : 'General Work',
                      title: 'Work Booking with ${item.fullName}',
                      dailyRatePaise: item.dailyRatePaise > 0 ? item.dailyRatePaise : 60000,
                      wagePaise: item.dailyRatePaise > 0 ? item.dailyRatePaise : 60000,
                      selectedDate: DateTime.now().add(const Duration(days: 1)),
                      currentStep: 1,
                    );
                    context.push(AppRoutes.providerBooking, extra: draft);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations? l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_border_rounded, size: 48, color: Colors.red),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Favourites Yet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the heart icon on worker and farmer profiles or in your job history to save them to your trusted repeat connections.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.headerGreenDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Find Workers & Services', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => context.go(AppRoutes.providerWorkers),
            ),
          ],
        ),
      ),
    );
  }
}
