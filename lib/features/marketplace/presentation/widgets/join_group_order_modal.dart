import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/marketplace/domain/group_order_model.dart';
import 'package:udyogasethu/features/marketplace/presentation/subscriptions_controller.dart';

class JoinGroupOrderModal extends ConsumerStatefulWidget {
  final GroupOrder groupOrder;

  const JoinGroupOrderModal({super.key, required this.groupOrder});

  static Future<void> show(BuildContext context, GroupOrder groupOrder) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => JoinGroupOrderModal(groupOrder: groupOrder),
    );
  }

  @override
  ConsumerState<JoinGroupOrderModal> createState() => _JoinGroupOrderModalState();
}

class _JoinGroupOrderModalState extends ConsumerState<JoinGroupOrderModal> {
  double _quantity = 2.0;
  bool _isJoining = false;

  Future<void> _handleJoin() async {
    setState(() => _isJoining = true);
    try {
      await ref
          .read(subscriptionsControllerProvider.notifier)
          .joinGroupOrder(widget.groupOrder.id, _quantity);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Joined ${widget.groupOrder.communityName} bulk order for ${_quantity.toInt()} units! Tiered discount applied.',
            ),
            backgroundColor: const Color(0xFF00875A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining group order: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectivePrice = (widget.groupOrder.effectivePricePaise / 100).toStringAsFixed(0);
    final totalAmount = ((widget.groupOrder.effectivePricePaise * _quantity) / 100).toStringAsFixed(0);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Join Apartment Bulk Order',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.groupOrder.communityName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          Text(
            'Item: ${widget.groupOrder.listingName} (Current tier: ₹$effectivePrice/unit)',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),

          // Quantity selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'How many units do you want?',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: _quantity > 1.0 ? () => setState(() => _quantity -= 1.0) : null,
                      icon: const Icon(Icons.remove, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _quantity.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      onPressed: () => setState(() => _quantity += 1.0),
                      icon: const Icon(Icons.add, size: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Price Summary Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text('Pledged Share Amount:', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                ),
                const SizedBox(width: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '₹$totalAmount',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Note: When more neighbors join and reach higher tiers, everyone gets the discounted bulk price automatically. If the deadline passes without meeting the threshold, your wallet is refunded instantly.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
          ),
          const SizedBox(height: 20),

          // Join Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isJoining ? null : _handleJoin,
              child: _isJoining
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text(
                      'Confirm & Join Group Order',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
