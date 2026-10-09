import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/orders_repository.dart';
import '../domain/produce_order.dart';
import 'widgets/rate_produce_order_dialog.dart';

/// Screen listing customer produce order history with real-time status updates,
/// 1-tap reordering, and direct navigation to live order tracking.
class CustomerOrdersScreen extends ConsumerStatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  ConsumerState<CustomerOrdersScreen> createState() =>
      _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends ConsumerState<CustomerOrdersScreen> {
  String _filter = 'all'; // all, active, delivered, cancelled

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ordersStream = ref.watch(customerOrdersStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          l10n?.myFarmOrdersTitle ?? 'My Farm Produce Orders',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip('all', l10n?.allOrdersFilter ?? 'All Orders'),
                const SizedBox(width: 8),
                _buildFilterChip('active', l10n?.activeFilter ?? 'Active'),
                const SizedBox(width: 8),
                _buildFilterChip('delivered', l10n?.completedFilter ?? 'Delivered'),
                const SizedBox(width: 8),
                _buildFilterChip('cancelled', l10n?.cancelledFilter ?? 'Cancelled'),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ordersStream.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.headerGreenDark),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Error loading orders: $err'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(customerOrdersStreamProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (orders) {
                final filtered = orders.where((o) {
                  if (_filter == 'active') {
                    return o.status == 'pending' ||
                        o.status == 'accepted' ||
                        o.status == 'packed' ||
                        o.status == 'out_for_delivery';
                  } else if (_filter == 'delivered') {
                    return o.status == 'delivered';
                  } else if (_filter == 'cancelled') {
                    return o.status == 'cancelled' || o.status == 'disputed';
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState(l10n);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) {
                    final order = filtered[idx];
                    return _buildOrderCard(order, l10n);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filter == key;
    return GestureDetector(
      onTap: () => setState(() => _filter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.headerGreenDark : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(ProduceOrder order, AppLocalizations? l10n) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt.toLocal());

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
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
            // Top row: Order code and status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderCode,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              dateStr,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            ),
            const Divider(height: 18),

            // Middle row: Farmer & Total
            Row(
              children: [
                const Icon(Icons.agriculture, color: Color(0xFF0D6548), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.farmerName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${order.itemsCount} produce items • ${order.fulfilment == 'pickup' ? 'Farm Pickup' : 'Delivery'}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Text(
                  order.formattedTotal,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.headerGreenDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Actions row: Track Order, Reorder, Rate
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.headerGreenDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      context.push(AppRoutes.orderTrackingWithId(order.orderId));
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.track_changes, size: 16),
                        const SizedBox(width: 6),
                        Text(l10n?.trackOrderButton ?? 'Track Order'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Reorder action
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0D6548),
                    side: const BorderSide(color: Color(0xFF0D6548)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onPressed: () {
                    ref.read(cartNotifierProvider.notifier).addOrderItems(
                          order.items,
                          farmerId: order.farmerId,
                        );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Items added to cart!'),
                        backgroundColor: AppColors.headerGreenDark,
                      ),
                    );
                    context.push(AppRoutes.cart);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.repeat, size: 16),
                      const SizedBox(width: 4),
                      Text(l10n?.reorderButton ?? 'Reorder'),
                    ],
                  ),
                ),

                if (order.isDelivered) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.star_outline, color: Color(0xFFD97706)),
                    tooltip: 'Rate Produce',
                    onPressed: () {
                      RateProduceOrderDialog.show(
                        context,
                        orderId: order.orderId,
                        farmerId: order.farmerId,
                        farmerName: order.farmerName,
                      );
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label = status.toUpperCase();

    switch (status) {
      case 'pending':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        label = 'PENDING';
        break;
      case 'accepted':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1E40AF);
        label = 'ACCEPTED';
        break;
      case 'packed':
        bg = const Color(0xFFE0E7FF);
        fg = const Color(0xFF3730A3);
        label = 'PACKED';
        break;
      case 'out_for_delivery':
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF5B21B6);
        label = 'DISPATCHED';
        break;
      case 'delivered':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        label = 'DELIVERED';
        break;
      case 'cancelled':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        label = 'CANCELLED';
        break;
      case 'disputed':
        bg = const Color(0xFFFFEDD5);
        fg = const Color(0xFF9A3412);
        label = 'DISPUTED';
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations? l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined,
                size: 64, color: Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            Text(
              l10n?.noOrdersFoundTitle ?? 'No Farm Orders Found',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n?.noOrdersFoundSub ??
                  'You have not placed any produce orders in this view yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.headerGreenDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => context.go(AppRoutes.providerHome),
              child: Text(l10n?.exploreProduceButton ?? 'Explore Farm Produce'),
            ),
          ],
        ),
      ),
    );
  }
}
