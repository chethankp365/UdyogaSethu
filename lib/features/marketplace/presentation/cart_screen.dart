import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../data/orders_repository.dart';
import '../domain/cart_item.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cartState = ref.watch(cartNotifierProvider);
    final cartNotifier = ref.read(cartNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          cartState.isEmpty
              ? (l10n?.cartTitle ?? 'Shopping Cart')
              : '${l10n?.cartTitle ?? 'Shopping Cart'} (${cartState.totalQuantity})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (cartState.isNotEmpty)
            TextButton.icon(
              onPressed: () => _confirmClearCart(context, ref),
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red, size: 20),
              label: Text(
                l10n?.cartClear ?? 'Clear',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: cartState.isEmpty
          ? _buildEmptyState(context, l10n)
          : SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Multi-Farmer Split Banner
                  if (cartState.farmerGroups.length > 1)
                    _buildMultiFarmerSplitBanner(context, cartState.farmerGroups.length, l10n),

                  // Farmer Groups
                  ...cartState.farmerGroups.asMap().entries.map((entry) {
                    final index = entry.key;
                    final group = entry.value;
                    return _buildFarmerGroupCard(
                      context: context,
                      group: group,
                      groupIndex: index + 1,
                      totalGroups: cartState.farmerGroups.length,
                      cartNotifier: cartNotifier,
                      l10n: l10n,
                    );
                  }),

                  const SizedBox(height: 12),

                  // Reward Credits Mock Function Card
                  _buildRewardCreditsCard(context, cartState, cartNotifier, l10n),

                  const SizedBox(height: 16),

                  // Bill Summary Card
                  _buildBillSummaryCard(context, cartState, l10n),
                ],
              ),
            ),
      bottomNavigationBar: cartState.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.totalPayable ?? 'Total Payable',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cartState.formattedTotal,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D6548),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        context.push(AppRoutes.orderCheckout);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00875A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n?.proceedToCheckout ?? 'Checkout',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations? l10n) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F4EA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_basket_outlined,
                size: 46,
                color: Color(0xFF0D6548),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n?.cartEmptyTitle ?? 'Your Cart is Empty',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.cartEmptySubtitle ??
                  'Explore fresh organic vegetables, fruits, and dairy directly from local verified farmers.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.pop();
              },
              icon: const Icon(Icons.storefront, size: 20),
              label: Text(l10n?.exploreProduce ?? 'Explore Farm Produce'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6548),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiFarmerSplitBanner(
      BuildContext context, int farmerCount, AppLocalizations? l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFB45309), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n?.multiFarmerSplitNotice ??
                  'Items from $farmerCount farmers will be placed as separate direct orders for fresh dispatch.',
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF92400E),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerGroupCard({
    required BuildContext context,
    required FarmerCartGroup group,
    required int groupIndex,
    required int totalGroups,
    required CartNotifier cartNotifier,
    required AppLocalizations? l10n,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Farmer Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    totalGroups > 1
                        ? 'Order $groupIndex of $totalGroups'
                        : (l10n?.farmerOrderHeader ?? 'Direct Farm Order'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D6548),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.farmerName,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.verified, color: Color(0xFF00875A), size: 16),
              ],
            ),
            const Divider(height: 20),

            // Item rows
            ...group.items.map((item) {
              return _buildCartItemRow(context, item, cartNotifier, l10n);
            }),

            const Divider(height: 16),
            // Group Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${l10n?.subtotalLabel ?? 'Farm Order Subtotal'} (${group.items.length} items)',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  group.formattedSubtotal,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemRow(
    BuildContext context,
    CartItem item,
    CartNotifier cartNotifier,
    AppLocalizations? l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Emoji / Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              item.produceItem.categoryIcon,
              color: const Color(0xFF0D6548),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Name and Unit Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.produceItem.formattedPrice} • Max: ${item.maxStock.toInt()} ${item.unit}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // Quantity Stepper
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    cartNotifier.updateQuantity(item.listingId, item.quantity - 1.0);
                  },
                  icon: const Icon(Icons.remove, size: 16),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  splashRadius: 18,
                ),
                Text(
                  '${item.quantity.toInt()} ${item.unit}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: item.canIncrease
                      ? () {
                          cartNotifier.updateQuantity(item.listingId, item.quantity + 1.0);
                        }
                      : null,
                  icon: Icon(
                    Icons.add,
                    size: 16,
                    color: item.canIncrease ? Colors.black87 : Colors.grey[400],
                  ),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  splashRadius: 18,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Item Subtotal
          SizedBox(
            width: 55,
            child: Text(
              item.formattedSubtotal,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCreditsCard(
    BuildContext context,
    CartState cartState,
    CartNotifier cartNotifier,
    AppLocalizations? l10n,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.stars, color: Color(0xFFD97706), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.redeemRewardCredits ?? 'Reward Credits (Demo mode)',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n?.rewardDiscountDesc ?? 'Apply 5% loyalty discount (up to ₹50)',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: cartState.useRewardCredits,
              activeTrackColor: const Color(0xFF00875A),
              activeThumbColor: Colors.white,
              onChanged: (_) => cartNotifier.toggleRewardCredits(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillSummaryCard(
    BuildContext context,
    CartState cartState,
    AppLocalizations? l10n,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.billSummary ?? 'Bill Summary',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${l10n?.itemTotal ?? 'Items Total'} (${cartState.totalQuantity} items)',
                    style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  cartState.formattedSubtotal,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (cartState.discountPaise > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n?.rewardCreditsDiscount ?? 'Reward Discount',
                      style: const TextStyle(fontSize: 13.5, color: Color(0xFF00875A)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '-${cartState.formattedDiscount}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00875A),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n?.escrowProtectionBadge ?? 'Escrow Protection Guarantee',
                    style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n?.includedLabel ?? 'Included',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00875A),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n?.totalPayable ?? 'Total Amount',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  cartState.formattedTotal,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D6548),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearCart(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.clearCartConfirmTitle ?? 'Clear Cart?'),
        content: Text(
          l10n?.clearCartConfirmBody ?? 'Are you sure you want to remove all items from your cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(cartNotifierProvider.notifier).clear();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n?.cartClear ?? 'Clear'),
          ),
        ],
      ),
    );
  }
}
