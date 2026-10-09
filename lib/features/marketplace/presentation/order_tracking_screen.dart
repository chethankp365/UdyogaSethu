import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/orders_repository.dart';
import '../domain/produce_order.dart';
import 'widgets/order_timeline_widget.dart';
import 'widgets/raise_order_dispute_dialog.dart';
import 'widgets/rate_produce_order_dialog.dart';

/// Screen displaying real-time produce order tracking, ETA, slot information,
/// pickup/delivery PIN, timeline widget, and customer actions (confirm, cancel, dispute, reorder).
class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  bool _isProcessing = false;
  String? _actionError;

  Future<void> _confirmDelivery(ProduceOrder order) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.confirmDeliveryTitle ?? 'Confirm Delivery Receipt?'),
        content: Text(
          l10n?.confirmDeliveryPrompt ??
              'Have you received your complete produce order in good condition? This will release the escrow payment to the farmer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n?.cancelButton ?? 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.headerGreenDark,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n?.confirmReceivedButton ?? 'Yes, I Received It'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _actionError = null;
    });

    try {
      final repo = ref.read(ordersRepositoryProvider);
      await repo.updateOrderStatus(
        orderId: order.orderId,
        status: 'delivered',
        notes: 'Customer confirmed delivery receipt in app',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Delivery confirmed! Payment released to farmer wallet.',
            ),
            backgroundColor: AppColors.headerGreenDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _actionError = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _cancelOrder(ProduceOrder order) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.cancelOrderTitle ?? 'Cancel Produce Order?'),
        content: Text(
          l10n?.cancelOrderPrompt ??
              'Are you sure you want to cancel this order? Any reserved stock will be released and held escrow will be refunded to your wallet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n?.noKeepOrder ?? 'No, Keep Order'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n?.yesCancelOrder ?? 'Yes, Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _actionError = null;
    });

    try {
      final repo = ref.read(ordersRepositoryProvider);
      await repo.updateOrderStatus(
        orderId: order.orderId,
        status: 'cancelled',
        notes: 'Cancelled by customer',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled. Escrow payment has been refunded.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _actionError = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handleReorder(ProduceOrder order) {
    ref.read(cartNotifierProvider.notifier).addOrderItems(
          order.items,
          farmerId: order.farmerId,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Items added to cart! Proceeding to checkout...'),
        backgroundColor: AppColors.headerGreenDark,
      ),
    );
    context.push(AppRoutes.cart);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final orderStream = ref.watch(orderDetailsStreamProvider(widget.orderId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.orderTrackingTitle ?? 'Order Tracking',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'ID: ${widget.orderId.substring(0, widget.orderId.length > 8 ? 8 : widget.orderId.length)}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.invalidate(orderDetailsStreamProvider(widget.orderId)),
          ),
        ],
      ),
      body: orderStream.when(
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
                Text('Failed to load order: $err'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref
                      .invalidate(orderDetailsStreamProvider(widget.orderId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (order) {
          if (order == null) {
            return Center(
              child: Text(l10n?.orderNotFound ?? 'Order not found.'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_actionError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _actionError!,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 1. ORDER SUMMARY & CODE BANNER
                _buildOrderHeaderCard(order, l10n),
                const SizedBox(height: 14),

                // 2. PIN / PICKUP CODE CARD
                _buildHandoffPinCard(order, l10n),
                const SizedBox(height: 14),

                // 3. ETA & DELIVERY SLOT CARD
                _buildEtaSlotCard(order, l10n),
                const SizedBox(height: 16),

                // 4. LIVE TIMELINE WIDGET
                OrderTimelineWidget(
                  orderId: order.orderId,
                  currentStatus: order.status,
                  fulfilment: order.fulfilment,
                ),
                const SizedBox(height: 16),

                // 5. ORDER ITEMS & PRICING
                _buildItemsSummaryCard(order, l10n),
                const SizedBox(height: 20),

                // 6. ACTION BUTTONS
                _buildActionButtons(order, l10n),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card 1: Order Header
  // ---------------------------------------------------------------------------
  Widget _buildOrderHeaderCard(ProduceOrder order, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt,
                          size: 14, color: AppColors.headerGreenDark),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          order.orderCode,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.headerGreenDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18, color: Color(0xFF64748B)),
                tooltip: 'Copy Order Code',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: order.orderCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order code copied to clipboard'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.farmerName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          if (order.farmerPhone != null) ...[
            const SizedBox(height: 2),
            Text(
              'Farmer Contact: ${order.farmerPhone}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card 2: Handoff PIN / Pickup Code
  // ---------------------------------------------------------------------------
  Widget _buildHandoffPinCard(ProduceOrder order, AppLocalizations? l10n) {
    final pin = order.deliveryPin ?? '4819';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.vpn_key_rounded,
                  color: Color(0xFF0D6548), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.fulfilment == 'pickup'
                      ? (l10n?.farmPickupCodeHeader ?? 'Farm Pickup Verification Code')
                      : (l10n?.deliveryPinHeader ?? 'Delivery Handover PIN'),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D6548),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00875A), width: 1.5),
                ),
                child: Text(
                  pin,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                    color: Color(0xFF0D6548),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  order.fulfilment == 'pickup'
                      ? (l10n?.showPickupCodeFarmerNote ??
                          'Show this 4-digit code to the farmer when picking up your crate.')
                      : (l10n?.showDeliveryPinDriverNote ??
                          'Share this code with the driver upon delivery to verify handoff.'),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF065F46),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card 3: ETA & Slot Card
  // ---------------------------------------------------------------------------
  Widget _buildEtaSlotCard(ProduceOrder order, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_filled,
                  color: Color(0xFF00875A), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n?.estimatedArrivalHeader ?? 'Estimated Arrival & Window',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.fulfilment == 'pickup' ? 'Farm Pickup' : 'Doorstep Slot',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.slotDisplayWindow,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          if (order.addressText != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.addressText!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card 4: Order Items & Pricing
  // ---------------------------------------------------------------------------
  Widget _buildItemsSummaryCard(ProduceOrder order, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n?.orderItemsHeader ?? 'Order Items',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${order.items.length} items',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const Divider(height: 20),

          if (order.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${order.itemsCount} Farm Produce items in order',
                style: const TextStyle(color: Color(0xFF475569)),
              ),
            )
          else
            ...order.items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.name} (${item.quantity} ${item.unit})',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      item.formattedSubtotal,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              );
            }),

          const Divider(height: 20),

          // Total and protection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n?.totalAmount ?? 'Total Amount Paid:',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
          if (order.protected) ...[
            const SizedBox(height: 6),
            const Row(
              children: [
                Icon(Icons.shield_outlined, size: 14, color: Color(0xFF00875A)),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '100% Escrow Protected by UdyogaSethu',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00875A),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card 5: Action Buttons
  // ---------------------------------------------------------------------------
  Widget _buildActionButtons(ProduceOrder order, AppLocalizations? l10n) {
    if (_isProcessing) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.headerGreenDark),
      );
    }

    // 1. Pending State: Customer can cancel
    if (order.isPending) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFDC2626),
          side: const BorderSide(color: Color(0xFFDC2626)),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.cancel_outlined),
        label: Text(l10n?.cancelOrderButton ?? 'Cancel Order & Refund Escrow'),
        onPressed: () => _cancelOrder(order),
      );
    }

    // 2. Active in-transit or packed: Customer can confirm delivery
    if (order.isOutForDelivery || order.isPacked || order.isAccepted) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.headerGreenDark,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: Text(
              l10n?.confirmDeliveryReceivedButton ??
                  'Confirm Order Received & Release Funds',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => _confirmDelivery(order),
          ),
          const SizedBox(height: 10),
          Text(
            l10n?.releaseFundsNotice ??
                'Tapping confirm immediately releases funds from escrow to the farmer.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
        ],
      );
    }

    // 3. Delivered State: Rate, Reorder, or Report Dispute
    if (order.isDelivered) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.headerGreenDark,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.repeat),
            label: Text(
              l10n?.reorderItemsButton ?? 'Reorder All Items',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => _handleReorder(order),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD97706),
                    side: const BorderSide(color: Color(0xFFD97706)),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.star_outline),
                  label: Text(l10n?.rateProduceButton ?? 'Rate Produce'),
                  onPressed: () {
                    RateProduceOrderDialog.show(
                      context,
                      orderId: order.orderId,
                      farmerId: order.farmerId,
                      farmerName: order.farmerName,
                      onReviewSubmitted: () => ref.invalidate(
                          orderDetailsStreamProvider(widget.orderId)),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.report_problem_outlined),
                  label: Text(l10n?.disputeButton ?? 'Report Issue'),
                  onPressed: () {
                    RaiseOrderDisputeDialog.show(
                      context,
                      orderId: order.orderId,
                      orderCode: order.orderCode,
                      farmerId: order.farmerId,
                      onDisputeSubmitted: () => ref.invalidate(
                          orderDetailsStreamProvider(widget.orderId)),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      );
    }

    // 4. Cancelled or Disputed
    return const SizedBox.shrink();
  }
}
