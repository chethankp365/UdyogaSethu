import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/rewards/data/rewards_repository.dart';
import 'package:udyogasethu/features/rewards/domain/gamification_models.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class RewardsStoreScreen extends ConsumerStatefulWidget {
  const RewardsStoreScreen({super.key});

  @override
  ConsumerState<RewardsStoreScreen> createState() => _RewardsStoreScreenState();
}

class _RewardsStoreScreenState extends ConsumerState<RewardsStoreScreen>
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

  void _showRedeemDialog(
    BuildContext context,
    RewardStoreItem item,
    UserGamificationProfile profile,
    AppLocalizations l10n,
    String locale,
  ) {
    final streetController = TextEditingController();
    final pincodeController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isRedeeming = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.rewardsRedemptionDialogTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.mintBackground,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        border: Border.fromBorderSide(BorderSide(color: AppColors.cardBorderGreen)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined,
                              color: AppColors.headerGreenDark),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.getName(locale),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  l10n.rewardsStoreCost(item.pointsCost),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.headerGreenDark,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Balance: ${profile.availablePoints}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: streetController,
                      decoration: InputDecoration(
                        labelText: l10n.rewardsShippingStreet,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.home_outlined),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: pincodeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.rewardsShippingPincode,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.pin_drop_outlined),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().length < 6)
                                    ? 'Valid 6 digits'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: l10n.rewardsShippingPhone,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.phone_outlined),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().length < 10)
                                    ? 'Valid phone'
                                    : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.headerGreenDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isRedeeming
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => isRedeeming = true);
                                try {
                                  await ref
                                      .read(rewardsRepositoryProvider)
                                      .redeemRewardItem(
                                        itemId: item.id,
                                        shippingAddress: {
                                          'street':
                                              streetController.text.trim(),
                                          'pincode':
                                              pincodeController.text.trim(),
                                          'phone':
                                              phoneController.text.trim(),
                                        },
                                      );
                                  if (context.mounted) {
                                    Navigator.of(ctx).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text(l10n.rewardsRedeemSuccess),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                    ref.invalidate(gamificationProfileProvider);
                                    ref.invalidate(rewardItemsProvider);
                                    ref.invalidate(rewardRedemptionsProvider);
                                  }
                                } catch (e) {
                                  setModalState(() => isRedeeming = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(e
                                            .toString()
                                            .replaceAll('Exception: ', '')),
                                        backgroundColor: AppColors.errorRed,
                                      ),
                                    );
                                  }
                                }
                              },
                        child: isRedeeming
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(l10n.rewardsStoreRedeemAction),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final profileAsync = ref.watch(gamificationProfileProvider);
    final itemsAsync = ref.watch(rewardItemsProvider);
    final redemptionsAsync = ref.watch(rewardRedemptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.rewardsStoreTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentOrange,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            const Tab(text: 'Catalog'),
            Tab(text: l10n.rewardsRedemptionsHistoryTitle),
          ],
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.headerGreenDark),
        ),
        error: (err, stack) => Center(
          child: Text(err.toString(), style: const TextStyle(color: AppColors.textMuted)),
        ),
        data: (profile) {
          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Catalog
              _buildCatalogTab(context, profile, itemsAsync, l10n, locale),

              // Tab 2: History
              _buildHistoryTab(context, redemptionsAsync, l10n, locale),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCatalogTab(
    BuildContext context,
    UserGamificationProfile profile,
    AsyncValue<List<RewardStoreItem>> itemsAsync,
    AppLocalizations l10n,
    String locale,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Points Summary Strip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.mintBackground,
              borderRadius: BorderRadius.all(Radius.circular(12)),
              border: Border.fromBorderSide(BorderSide(color: AppColors.cardBorderGreen)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.rewardsAvailablePoints(profile.availablePoints),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.headerGreenDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Level ${profile.currentLevel.levelNumber} (${profile.currentLevel.name})',
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => ref.invalidate(rewardItemsProvider),
                    child: const Text('Refresh'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          itemsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(
                    color: AppColors.headerGreenDark),
              ),
            ),
            error: (err, stack) => Center(
              child: Text(err.toString(),
                  style: const TextStyle(color: AppColors.textMuted)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No reward items available currently.'),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (ctx, index) {
                  final item = items[index];
                  final hasBadge = item.requiredBadgeId == null ||
                      profile.badges.any((b) =>
                          b.id == item.requiredBadgeId && b.isEarned);
                  final itemState = item.getState(
                    userPoints: profile.availablePoints,
                    userLevel: profile.currentLevel.levelNumber,
                    hasRequiredBadge: hasBadge,
                  );
                  final canRedeem = itemState == RewardItemState.available &&
                      profile.availablePoints >= item.pointsCost;

                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.card_giftcard,
                              size: 32,
                              color: AppColors.headerGreenDark,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.getName(locale),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 2,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      l10n.rewardsStoreCost(item.pointsCost),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.headerGreenDark,
                                      ),
                                    ),
                                    Text(
                                      '· ${l10n.rewardsStoreStock(item.stock)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                _buildItemStateBadge(
                                    itemState, item, l10n, canRedeem),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canRedeem
                                    ? AppColors.headerGreenDark
                                    : Colors.grey.shade300,
                                foregroundColor: canRedeem
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: canRedeem
                                  ? () => _showRedeemDialog(
                                      context, item, profile, l10n, locale)
                                  : null,
                              child: Text(
                                l10n.rewardsStoreRedeemAction,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemStateBadge(RewardItemState state, RewardStoreItem item,
      AppLocalizations l10n, bool canRedeem) {
    if (state == RewardItemState.outOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.dangerBackground,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          l10n.rewardsStoreOutOfStock,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.errorRed,
          ),
        ),
      );
    }

    if (state == RewardItemState.locked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          item.minLevel > 1
              ? l10n.rewardsStoreLockedLevel(item.minLevel)
              : l10n.rewardsStoreLockedBadge,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.amber.shade900,
          ),
        ),
      );
    }

    if (!canRedeem) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'More points needed',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.mintBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Available',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.headerGreenDark,
        ),
      ),
    );
  }

  Widget _buildHistoryTab(
    BuildContext context,
    AsyncValue<List<RewardRedemption>> redemptionsAsync,
    AppLocalizations l10n,
    String locale,
  ) {
    return redemptionsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.headerGreenDark),
      ),
      error: (err, stack) => Center(
        child: Text(err.toString(), style: const TextStyle(color: AppColors.textMuted)),
      ),
      data: (redemptions) {
        if (redemptions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'No redemptions yet. Redeem items with your earned points!',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: redemptions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (ctx, index) {
            final red = redemptions[index];
            final itemName = red.item?.getName(locale) ?? 'Reward Merchandise';

            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            itemName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        _buildStatusChip(red.status, l10n),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${red.pointsSpent} Points · Requested on ${red.createdAt.toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    if (red.shippingAddress['street'] != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Deliver to: ${red.shippingAddress['street']}, ${red.shippingAddress['pincode'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(String status, AppLocalizations l10n) {
    Color bg = Colors.blue.shade50;
    Color fg = Colors.blue.shade800;
    String label = l10n.rewardsStatusRequested;

    switch (status.toLowerCase()) {
      case 'approved':
        bg = Colors.purple.shade50;
        fg = Colors.purple.shade800;
        label = l10n.rewardsStatusApproved;
        break;
      case 'shipped':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        label = l10n.rewardsStatusShipped;
        break;
      case 'delivered':
        bg = AppColors.mintBackground;
        fg = AppColors.headerGreenDark;
        label = l10n.rewardsStatusDelivered;
        break;
      case 'requested':
      default:
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
