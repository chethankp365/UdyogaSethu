import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/orders_repository.dart';
import '../../domain/order_timeline_event.dart';

/// Reusable order timeline widget showing real-time stage progression,
/// timestamps, live status dot, and dispute/cancellation banners.
class OrderTimelineWidget extends ConsumerWidget {
  final String orderId;
  final String currentStatus;
  final String fulfilment; // 'delivery' or 'pickup'

  const OrderTimelineWidget({
    super.key,
    required this.orderId,
    required this.currentStatus,
    this.fulfilment = 'delivery',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(orderEventsStreamProvider(orderId));
    final l10n = AppLocalizations.of(context);

    return eventsAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.headerGreenDark),
        ),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF64748B)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Live timeline: ${currentStatus.toUpperCase()}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
      ),
      data: (events) => _buildTimelineCard(context, events, l10n),
    );
  }

  Widget _buildTimelineCard(
    BuildContext context,
    List<OrderTimelineEvent> events,
    AppLocalizations? l10n,
  ) {
    final Map<OrderStage, OrderTimelineEvent> stageEvents = {};
    for (final e in events) {
      stageEvents[e.stage] = e;
    }

    final currentStage = OrderStage.fromString(currentStatus);
    final isCancelled = currentStage == OrderStage.cancelled ||
        stageEvents.containsKey(OrderStage.cancelled);
    final isDisputed = currentStage == OrderStage.disputed ||
        stageEvents.containsKey(OrderStage.disputed);

    const stages = [
      OrderStage.pending,
      OrderStage.accepted,
      OrderStage.packed,
      OrderStage.outForDelivery,
      OrderStage.delivered,
    ];

    final currentIdx = stages.indexOf(currentStage);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Live dot and title
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 340;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildPulsingDot(),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n?.liveOrderTimeline ?? 'LIVE ORDER TIMELINE',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: AppColors.headerGreenDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildStatusPill(currentStage, l10n),
                  ],
                );
              }
              return Row(
                children: [
                  _buildPulsingDot(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n?.liveOrderTimeline ?? 'LIVE ORDER TIMELINE',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.headerGreenDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusPill(currentStage, l10n),
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          // Cancelled Banner
          if (isCancelled) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel, color: Color(0xFFDC2626), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n?.orderCancelledRefundedNotice ??
                          'Order cancelled. Escrow payment has been refunded to your wallet.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Disputed Banner
          if (isDisputed) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n?.orderDisputeNotice ??
                          'Dispute open. Escrow release is frozen pending resolution.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Stage items
          ...stages.asMap().entries.map((entry) {
            final idx = entry.key;
            final stage = entry.value;
            final isLast = idx == stages.length - 1;

            final isCompleted = !isCancelled &&
                (currentIdx > idx ||
                    (currentIdx == idx && currentStage == OrderStage.delivered));
            final isCurrent = !isCancelled && currentIdx == idx && currentStage != OrderStage.delivered;

            final event = stageEvents[stage];
            final timestampStr = event != null
                ? DateFormat('hh:mm a').format(event.createdAt.toLocal())
                : null;

            return _buildStageRow(
              stage: stage,
              isCompleted: isCompleted,
              isCurrent: isCurrent,
              isLast: isLast,
              timestamp: timestampStr,
              l10n: l10n,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPulsingDot() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(OrderStage stage, AppLocalizations? l10n) {
    Color bg;
    Color fg;
    String label;

    switch (stage) {
      case OrderStage.pending:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        label = l10n?.statusPending ?? 'Pending';
        break;
      case OrderStage.accepted:
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1E40AF);
        label = l10n?.statusAccepted ?? 'Accepted';
        break;
      case OrderStage.packed:
        bg = const Color(0xFFE0E7FF);
        fg = const Color(0xFF3730A3);
        label = l10n?.statusPacked ?? 'Packed';
        break;
      case OrderStage.outForDelivery:
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF5B21B6);
        label = fulfilment == 'pickup'
            ? (l10n?.statusReadyForPickup ?? 'Ready for Pickup')
            : (l10n?.statusOutForDelivery ?? 'Out for Delivery');
        break;
      case OrderStage.delivered:
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        label = l10n?.statusDelivered ?? 'Delivered';
        break;
      case OrderStage.cancelled:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        label = l10n?.statusCancelled ?? 'Cancelled';
        break;
      case OrderStage.disputed:
        bg = const Color(0xFFFFEDD5);
        fg = const Color(0xFF9A3412);
        label = l10n?.statusDisputed ?? 'Disputed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildStageRow({
    required OrderStage stage,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
    String? timestamp,
    AppLocalizations? l10n,
  }) {
    String title;
    String subtitle;
    IconData icon;

    switch (stage) {
      case OrderStage.pending:
        title = l10n?.orderStagePlaced ?? 'Order Placed';
        subtitle = l10n?.orderStagePlacedSub ?? 'Escrow funds held safely';
        icon = Icons.receipt_long;
        break;
      case OrderStage.accepted:
        title = l10n?.orderStageAccepted ?? 'Accepted by Farmer';
        subtitle = l10n?.orderStageAcceptedSub ?? 'Harvesting & sorting produce';
        icon = Icons.agriculture;
        break;
      case OrderStage.packed:
        title = l10n?.orderStagePacked ?? 'Packed & Weighed';
        subtitle = l10n?.orderStagePackedSub ?? 'Quality checked & prepared for dispatch';
        icon = Icons.inventory_2;
        break;
      case OrderStage.outForDelivery:
        title = fulfilment == 'pickup'
            ? (l10n?.orderStageReadyPickup ?? 'Ready for Farm Pickup')
            : (l10n?.orderStageOutForDelivery ?? 'Out for Delivery');
        subtitle = fulfilment == 'pickup'
            ? (l10n?.orderStageReadyPickupSub ?? 'Visit farm with your pickup code')
            : (l10n?.orderStageOutForDeliverySub ?? 'On the way to your delivery address');
        icon = fulfilment == 'pickup' ? Icons.storefront : Icons.local_shipping;
        break;
      case OrderStage.delivered:
        title = fulfilment == 'pickup'
            ? (l10n?.orderStagePickedUp ?? 'Picked Up & Verified')
            : (l10n?.orderStageDelivered ?? 'Delivered & Verified');
        subtitle = l10n?.orderStageDeliveredSub ?? 'Escrow released to farmer wallet';
        icon = Icons.check_circle;
        break;
      default:
        title = stage.name;
        subtitle = '';
        icon = Icons.circle;
        break;
    }

    final circleColor = isCompleted
        ? const Color(0xFF0D6548)
        : isCurrent
            ? const Color(0xFF00875A)
            : const Color(0xFFCBD5E1);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator column with line
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF0D6548)
                      : isCurrent
                          ? const Color(0xFFE6F4EA)
                          : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: circleColor,
                    width: isCurrent ? 2 : 1.5,
                  ),
                ),
                child: Icon(
                  isCompleted ? Icons.check : icon,
                  size: 15,
                  color: isCompleted
                      ? Colors.white
                      : isCurrent
                          ? const Color(0xFF0D6548)
                          : const Color(0xFF94A3B8),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted
                        ? const Color(0xFF0D6548)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 14),

          // Text content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isCurrent || isCompleted
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isCurrent || isCompleted
                                ? const Color(0xFF0F172A)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      if (timestamp != null)
                        Text(
                          timestamp,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isCurrent || isCompleted
                          ? const Color(0xFF64748B)
                          : const Color(0xFFA0AEC0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
