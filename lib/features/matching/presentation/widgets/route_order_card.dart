import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/matching/domain/route_order_plan.dart';

/// Card displaying optimized daily route order for multi-job workers.
class RouteOrderCard extends StatelessWidget {
  final RouteOrderPlan plan;
  final VoidCallback? onOpenMap;

  const RouteOrderCard({
    super.key,
    required this.plan,
    this.onOpenMap,
  });

  @override
  Widget build(BuildContext context) {
    if (plan.stops.length < 2) {
      return const SizedBox.shrink();
    }

    final timeFmt = DateFormat('hh:mm a');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderGreen, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Time Saved highlight
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.paleMint,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.alt_route_rounded, color: AppColors.headerGreenDark, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Suggested Route Order (Rule-Based)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.headerGreenDark,
                        ),
                      ),
                      if (plan.timeSavedMinutes > 0)
                        Text(
                          '✨ Saves ~${plan.timeSavedMinutes} mins & ${(plan.originalDistanceKm - plan.totalDistanceKm).toStringAsFixed(1)} km today',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade900,
                          ),
                        ),
                    ],
                  ),
                ),
                if (onOpenMap != null)
                  IconButton(
                    onPressed: onOpenMap,
                    icon: const Icon(Icons.map_rounded, color: AppColors.headerGreenDark, size: 20),
                    tooltip: 'Inspect Route Map',
                  ),
              ],
            ),
          ),

          // Route sequence stops list
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                ...plan.stops.map((stop) {
                  final item = stop.item;
                  final isLast = stop.sequence == plan.stops.length;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sequence number pill + vertical dotted line
                      Column(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: AppColors.headerGreenDark,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${stop.sequence}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 32,
                              color: Colors.grey.shade300,
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Stop details
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    timeFmt.format(item.startAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.addressText,
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (!isLast && stop.distanceToNextKm > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '↳ ${stop.distanceToNextKm} km to next stop (~${stop.travelMinutesToNext} mins)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
