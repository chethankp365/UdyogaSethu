import 'package:flutter/material.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/marketplace/domain/group_order_model.dart';

class GroupOrderCard extends StatelessWidget {
  final GroupOrder groupOrder;
  final VoidCallback onJoinTap;

  const GroupOrderCard({
    super.key,
    required this.groupOrder,
    required this.onJoinTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = groupOrder.progressPercentage;
    final isTargetMet = groupOrder.isTargetReached;
    final currentTierPrice = (groupOrder.effectivePricePaise / 100).toStringAsFixed(0);
    final hoursRemaining = groupOrder.deadline.difference(DateTime.now()).inHours;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isTargetMet ? const Color(0xFF00875A).withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Community Name, Organizer, Status Pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.apartment_rounded, color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupOrder.communityName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Organized by ${groupOrder.organizerName}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 85),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isTargetMet
                          ? const Color(0xFF00875A).withValues(alpha: 0.15)
                          : Colors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isTargetMet ? 'Target Reached!' : 'Open Group',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isTargetMet ? const Color(0xFF00875A) : Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Item Name & Category
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.eco_rounded, size: 16, color: AppColors.headerGreenDark),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      groupOrder.listingName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 90),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '₹$currentTierPrice/unit',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.headerGreenDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Progress Bar and Target Counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Community Progress: ${groupOrder.currentQty.toStringAsFixed(0)} / ${groupOrder.targetQty.toStringAsFixed(0)} units',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isTargetMet ? const Color(0xFF00875A) : Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isTargetMet ? const Color(0xFF00875A) : const Color(0xFF2563EB),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tiered Bulk Pricing Thresholds
            const Text(
              'Bulk Discount Tiers (Unlocks with neighbors):',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: groupOrder.priceTiers.map((tier) {
                final isReached = groupOrder.currentQty >= tier.minQty;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isReached ? const Color(0xFF00875A).withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isReached ? const Color(0xFF00875A) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(
                            isReached ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            size: 12,
                            color: isReached ? const Color(0xFF00875A) : const Color(0xFF94A3B8),
                          ),
                        ),
                        const WidgetSpan(child: SizedBox(width: 4)),
                        TextSpan(
                          text: '≥${tier.minQty.toInt()} units: ₹${(tier.pricePaise / 100).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isReached ? FontWeight.bold : FontWeight.normal,
                            color: isReached ? const Color(0xFF00875A) : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Footer: Deadline / Participants + Join Button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Icon(Icons.timer_outlined, size: 14, color: hoursRemaining <= 12 ? Colors.red : const Color(0xFF64748B)),
                            ),
                            const WidgetSpan(child: SizedBox(width: 4)),
                            TextSpan(
                              text: hoursRemaining > 0 ? '$hoursRemaining hrs left' : 'Deadline met',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: hoursRemaining <= 12 ? Colors.red : const Color(0xFF64748B),
                              ),
                            ),
                            TextSpan(
                              text: ' • ${groupOrder.memberCount} joined',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      if (groupOrder.hasJoined) ...[
                        const SizedBox(height: 2),
                        Text(
                          'You pledged: ${groupOrder.userQty.toStringAsFixed(0)} units',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00875A)),
                        ),
                      ],
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: groupOrder.hasJoined ? const Color(0xFF0D6548) : const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: const Size(0, 36),
                  ),
                  icon: Icon(groupOrder.hasJoined ? Icons.add_rounded : Icons.group_add_rounded, size: 16),
                  label: Text(
                    groupOrder.hasJoined ? 'Add More' : 'Join Order',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: onJoinTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
