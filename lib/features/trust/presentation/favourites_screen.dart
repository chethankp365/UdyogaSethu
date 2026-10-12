import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/user_avatar.dart';
import 'package:udyogasethu/features/booking/domain/booking_draft.dart';
import 'package:udyogasethu/features/trust/data/trust_repository.dart';
import 'package:udyogasethu/features/trust/domain/favourite_item.dart';
import 'package:udyogasethu/features/trust/domain/repeat_client.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

/// Screen displaying user's saved Favourites & Trust Circles.
/// Enables 1-tap repeat bookings, repeat-customer visibility, and fair marketplace browsing.
class FavouritesScreen extends ConsumerStatefulWidget {
  const FavouritesScreen({super.key});

  @override
  ConsumerState<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends ConsumerState<FavouritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _callPhone(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentOrange,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Saved Favourites'),
            Tab(text: 'Repeat Clients'),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // Marketplace Fairness Banner
              _buildFairnessBanner(),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFavouritesTab(l10n),
                    _buildRepeatClientsTab(l10n),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFairnessBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEFF6FF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Row(
        children: [
          Icon(Icons.balance_rounded, size: 16, color: Color(0xFF1D4ED8)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Trust Circles prioritize familiar connections for convenience without hiding other eligible workers in search.',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF1E40AF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavouritesTab(AppLocalizations? l10n) {
    final favouritesAsync = ref.watch(favouritesListProvider);

    return RefreshIndicator(
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
            return _buildEmptyFavouritesState(context, l10n);
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (ctx, index) {
              return _buildFavouriteCard(ctx, items[index], l10n);
            },
          );
        },
      ),
    );
  }

  Widget _buildFavouriteCard(
    BuildContext context,
    FavouriteItem item,
    AppLocalizations? l10n,
  ) {
    final isFarmer = item.role.toLowerCase() == 'farmer';

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
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: isFarmer ? const Color(0xFFFEF3C7) : const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isFarmer ? 'Farmer' : 'Worker',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isFarmer ? const Color(0xFF92400E) : AppColors.headerGreenDark,
                              ),
                            ),
                          ),
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
                // Remove Favourite Heart
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
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
                Text(
                  '${item.jobsCompleted} jobs completed',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
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
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
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

  Widget _buildRepeatClientsTab(AppLocalizations? l10n) {
    final clientsAsync = ref.watch(repeatClientsProvider(null));

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(repeatClientsProvider(null)),
      child: clientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Could not load repeat clients: $err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(repeatClientsProvider(null)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (clients) {
          if (clients.isEmpty) {
            return _buildEmptyRepeatState(context);
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: clients.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (ctx, index) {
              return _buildRepeatClientCard(ctx, clients[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildRepeatClientCard(BuildContext context, RepeatClientItem client) {
    final dateStr = DateFormat('dd MMM yyyy').format(client.lastJobDate);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            UserAvatar(
              avatarPath: client.avatarPath,
              name: client.clientName,
              radius: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.clientName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${client.completedJobsCount} repeat jobs',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                        ),
                      ),
                      Text(
                        'Last: $dateStr',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.call_rounded, color: AppColors.headerGreenDark),
              tooltip: 'Call Client',
              onPressed: () => _callPhone(client.clientPhone),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFavouritesState(BuildContext context, AppLocalizations? l10n) {
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
              'Tap the heart icon on worker and farmer profiles to add them to your trust circles.',
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

  Widget _buildEmptyRepeatState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline_rounded, size: 48, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Repeat Customers Yet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Clients who book you for multiple jobs will appear here automatically for easy reconnection.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
