import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_thumbnail.dart';
import '../../../l10n/app_localizations.dart';
import '../../marketplace/data/orders_repository.dart';
import '../../marketplace/domain/produce_order.dart';

/// Farmer Order Board screen managing incoming orders, acceptance,
/// packaging, dispatch, and PIN-verified delivery completion with escrow settlement.
class FarmerOrderBoardScreen extends ConsumerStatefulWidget {
  const FarmerOrderBoardScreen({super.key});

  @override
  ConsumerState<FarmerOrderBoardScreen> createState() =>
      _FarmerOrderBoardScreenState();
}

class _FarmerOrderBoardScreenState extends ConsumerState<FarmerOrderBoardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus({
    required ProduceOrder order,
    required String targetStatus,
    String? pin,
    String? notes,
  }) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(ordersRepositoryProvider);
      await repo.updateOrderStatus(
        orderId: order.orderId,
        status: targetStatus,
        pin: pin,
        notes: notes,
      );

      // Refresh orders
      ref.invalidate(farmerOrdersStreamProvider(null));

      if (mounted) {
        String msg = 'Order updated to $targetStatus';
        if (targetStatus == 'accepted') {
          msg = 'Order accepted! Stock decremented and customer notified.';
        } else if (targetStatus == 'packed') {
          msg = 'Order marked as packed & weighed.';
        } else if (targetStatus == 'out_for_delivery') {
          msg = 'Order is now out for delivery!';
        } else if (targetStatus == 'delivered') {
          msg = 'Delivery confirmed! ${order.formattedNetEarnings} released to your wallet (minus platform fee).';
        } else if (targetStatus == 'cancelled') {
          msg = 'Order declined and escrow refunded to customer.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: targetStatus == 'cancelled'
                ? const Color(0xFFDC2626)
                : AppColors.headerGreenDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${_errorMessage!}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showVerifyPinModal(ProduceOrder order) {
    final pinController = TextEditingController();
    String? modalError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Row(
                  children: [
                    Icon(Icons.verified_user, color: AppColors.headerGreenDark, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Complete Delivery / Pickup',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Ask customer for their 4-digit verification PIN to confirm handoff and release escrow funds (${order.formattedNetEarnings}).',
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 10,
                    color: AppColors.headerGreenDark,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••',
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.headerGreenDark, width: 2),
                    ),
                  ),
                ),

                if (modalError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    modalError!,
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ],

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.headerGreenDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final enteredPin = pinController.text.trim();
                      if (enteredPin.length != 4) {
                        setModalState(() => modalError = 'Please enter the 4-digit customer PIN.');
                        return;
                      }

                      Navigator.pop(ctx);
                      await _updateStatus(
                        order: order,
                        targetStatus: 'delivered',
                        pin: enteredPin,
                        notes: 'Farmer verified customer PIN $enteredPin',
                      );
                    },
                    child: const Text(
                      'Verify PIN & Release Funds',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Center(
                  child: TextButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _updateStatus(
                        order: order,
                        targetStatus: 'delivered',
                        notes: 'Farmer marked delivered directly without PIN',
                      );
                    },
                    child: const Text(
                      'Direct Delivery Handover (Bypass PIN)',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ordersStream = ref.watch(farmerOrdersStreamProvider(null));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          l10n?.farmerOrderBoardTitle ?? 'Farmer Order Board',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Orders',
            onPressed: () => ref.invalidate(farmerOrdersStreamProvider(null)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: const Color(0xFFF59E0B),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
          tabs: const [
            Tab(text: 'Incoming'),
            Tab(text: 'Packing'),
            Tab(text: 'Dispatch'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: ordersStream.when(
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
                  onPressed: () => ref.invalidate(farmerOrdersStreamProvider(null)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (allOrders) {
          final incoming = allOrders.where((o) => o.isPending).toList();
          final packing = allOrders.where((o) => o.isAccepted || o.isPacked).toList();
          final dispatch = allOrders.where((o) => o.isOutForDelivery).toList();
          final completed = allOrders.where((o) => o.isDelivered || o.isCancelled || o.isDisputed).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersList(incoming, 'incoming', l10n),
              _buildOrdersList(packing, 'packing', l10n),
              _buildOrdersList(dispatch, 'dispatch', l10n),
              _buildOrdersList(completed, 'completed', l10n),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrdersList(
    List<ProduceOrder> orders,
    String stageGroup,
    AppLocalizations? l10n,
  ) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 56, color: Color(0xFF94A3B8)),
              const SizedBox(height: 12),
              Text(
                'No orders in $stageGroup',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'New orders from buyers will appear here in real-time.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: AppSpacing.fabListPadding,
      itemCount: orders.length,
      itemBuilder: (ctx, idx) {
        final order = orders[idx];
        return _buildFarmerOrderCard(order, stageGroup, l10n);
      },
    );
  }

  Widget _buildFarmerOrderCard(
    ProduceOrder order,
    String stageGroup,
    AppLocalizations? l10n,
  ) {
    final dateStr = DateFormat('dd MMM, hh:mm a').format(order.createdAt.toLocal());

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
            // Row 1: Order code and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4EA),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.orderCode,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.headerGreenDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: order.fulfilment == 'pickup'
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        order.fulfilment == 'pickup' ? 'PICKUP' : 'DELIVERY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: order.fulfilment == 'pickup'
                              ? const Color(0xFF92400E)
                              : const Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  dateStr,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Customer details
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${order.customerName ?? 'Direct Customer'} • ${order.customerPhone ?? '+91 91234 56789'}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),

            if (order.addressText != null) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Color(0xFF64748B)),
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

            // Slot info
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Color(0xFF0D6548)),
                const SizedBox(width: 6),
                Text(
                  order.slotDisplayWindow,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0D6548),
                  ),
                ),
              ],
            ),

            const Divider(height: 18),

            // Items list
            if (order.items.isNotEmpty) ...[
              ...order.items.map((it) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            ProduceThumbnail(
                              name: it.name,
                              size: ThumbnailSize.small,
                              width: 26,
                              height: 26,
                              borderRadius: BorderRadius.circular(6),
                              showTitle: false,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${it.name} (${it.quantity} ${it.unit})',
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                        Text(
                          it.formattedSubtotal,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )),
              const Divider(height: 16),
            ],

            // Earnings summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Farmer Net Payout: ${order.formattedNetEarnings}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.headerGreenDark,
                      ),
                    ),
                    Text(
                      'Gross: ${order.formattedTotal} (Platform Fee: ${order.formattedFee})',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Escrow Held',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.headerGreenDark,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ACTIONS BASED ON STAGE
            _buildCardActions(order, stageGroup),
          ],
        ),
      ),
    );
  }

  Widget _buildCardActions(ProduceOrder order, String stageGroup) {
    if (_isProcessing) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.headerGreenDark),
        ),
      );
    }

    // 1. INCOMING (Pending)
    if (order.isPending) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.headerGreenDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Accept Order'),
              onPressed: () => _updateStatus(order: order, targetStatus: 'accepted'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFDC2626)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Decline'),
              onPressed: () => _updateStatus(
                order: order,
                targetStatus: 'cancelled',
                notes: 'Farmer declined order',
              ),
            ),
          ),
        ],
      );
    }

    // 2. PACKING (Accepted or Packed)
    if (order.isAccepted) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E40AF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          icon: const Icon(Icons.inventory_2, size: 18),
          label: const Text('Mark Packed & Weighed'),
          onPressed: () => _updateStatus(order: order, targetStatus: 'packed'),
        ),
      );
    }

    if (order.isPacked) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5B21B6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          icon: Icon(order.fulfilment == 'pickup' ? Icons.storefront : Icons.local_shipping, size: 18),
          label: Text(order.fulfilment == 'pickup'
              ? 'Mark Ready for Farm Pickup'
              : 'Dispatch for Delivery'),
          onPressed: () => _updateStatus(order: order, targetStatus: 'out_for_delivery'),
        ),
      );
    }

    // 3. DISPATCH (Out for Delivery)
    if (order.isOutForDelivery) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.headerGreenDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: const Icon(Icons.pin, size: 18),
          label: const Text(
            'Verify PIN & Complete Delivery',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () => _showVerifyPinModal(order),
        ),
      );
    }

    // 4. COMPLETED
    if (order.isDelivered) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFD1FAE5),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF065F46), size: 16),
            const SizedBox(width: 6),
            Text(
              'Delivered & Funds Released (${order.formattedNetEarnings})',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF065F46),
              ),
            ),
          ],
        ),
      );
    }

    if (order.isCancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Cancelled & Refunded',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF991B1B),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
