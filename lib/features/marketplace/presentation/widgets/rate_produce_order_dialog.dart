import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/orders_repository.dart';

/// Rating and review modal for completed farm produce orders,
/// reusing P4.11 visual standard with produce-specific tags.
class RateProduceOrderDialog extends ConsumerStatefulWidget {
  final String orderId;
  final String farmerId;
  final String farmerName;
  final VoidCallback? onReviewSubmitted;

  const RateProduceOrderDialog({
    super.key,
    required this.orderId,
    required this.farmerId,
    required this.farmerName,
    this.onReviewSubmitted,
  });

  static Future<void> show(
    BuildContext context, {
    required String orderId,
    required String farmerId,
    required String farmerName,
    VoidCallback? onReviewSubmitted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: RateProduceOrderDialog(
          orderId: orderId,
          farmerId: farmerId,
          farmerName: farmerName,
          onReviewSubmitted: onReviewSubmitted,
        ),
      ),
    );
  }

  @override
  ConsumerState<RateProduceOrderDialog> createState() =>
      _RateProduceOrderDialogState();
}

class _RateProduceOrderDialogState
    extends ConsumerState<RateProduceOrderDialog> {
  int _stars = 5;
  final Set<String> _selectedTags = {'Fresh Produce', 'Good Quality'};
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  static const List<String> _produceTags = [
    'Fresh Produce',
    'Good Quality',
    'Farm Fresh',
    'Accurate Weight',
    'Fast Dispatch',
    'Well Packed',
    'Organic Taste',
    'Polite Farmer',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(ordersRepositoryProvider);
      await repo.submitOrderReview(
        orderId: widget.orderId,
        targetId: widget.farmerId,
        stars: _stars,
        tags: _selectedTags.toList(),
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onReviewSubmitted?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Your produce review has been published.'),
            backgroundColor: AppColors.headerGreenDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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

            // Title & Subtitle
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFFF59E0B), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.rateOrderTitle ?? 'Rate Fresh Produce',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${widget.farmerName} • Farm Direct Order',
                        style: const TextStyle(
                            fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Star Rating Row
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  return IconButton(
                    iconSize: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    icon: Icon(
                      starNum <= _stars
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                    onPressed: () => setState(() => _stars = starNum),
                  );
                }),
              ),
            ),

            Center(
              child: Text(
                _getRatingLabel(_stars),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.headerGreenDark,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Produce Quality Tags
            Text(
              l10n?.selectProduceTags ?? 'Produce Quality Highlights:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _produceTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  selectedColor: const Color(0xFFE6F4EA),
                  checkmarkColor: AppColors.headerGreenDark,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? AppColors.headerGreenDark
                        : const Color(0xFF475569),
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.headerGreenDark
                        : Colors.grey.shade300,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Comment textfield
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n?.orderReviewHint ??
                    'Tell us about the freshness, taste, and packaging...',
                hintStyle:
                    const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.headerGreenDark, width: 1.5),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],

            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.headerGreenDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting ? null : _submitReview,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        l10n?.submitReviewButton ?? 'Submit Produce Review',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingLabel(int stars) {
    switch (stars) {
      case 5:
        return 'Excellent Freshness & Quality ★★★★★';
      case 4:
        return 'Good & Fresh ★★★★☆';
      case 3:
        return 'Average Quality ★★★☆☆';
      case 2:
        return 'Below Expectations ★★☆☆☆';
      case 1:
        return 'Poor Quality ★☆☆☆☆';
      default:
        return '';
    }
  }
}
