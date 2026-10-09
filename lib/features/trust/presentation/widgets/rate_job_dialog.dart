import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/trust/data/trust_repository.dart';
import 'package:udyogasethu/features/trust/domain/job_review.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

/// Modal bottom sheet or dialog allowing both parties of a completed assignment
/// to rate with stars, select quick tags, write a review, and submit once.
class RateJobDialog extends ConsumerStatefulWidget {
  final String assignmentId;
  final String jobTitle;
  final String counterpartyName;
  final VoidCallback? onReviewSubmitted;

  const RateJobDialog({
    super.key,
    required this.assignmentId,
    required this.jobTitle,
    required this.counterpartyName,
    this.onReviewSubmitted,
  });

  static Future<void> show(
    BuildContext context, {
    required String assignmentId,
    required String jobTitle,
    required String counterpartyName,
    VoidCallback? onReviewSubmitted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: RateJobDialog(
          assignmentId: assignmentId,
          jobTitle: jobTitle,
          counterpartyName: counterpartyName,
          onReviewSubmitted: onReviewSubmitted,
        ),
      ),
    );
  }

  @override
  ConsumerState<RateJobDialog> createState() => _RateJobDialogState();
}

class _RateJobDialogState extends ConsumerState<RateJobDialog> {
  int _stars = 5;
  final Set<String> _selectedTags = {};
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _submitReview() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(trustRepositoryProvider);
      await repo.submitJobReview(
        assignmentId: widget.assignmentId,
        stars: _stars,
        tags: _selectedTags.toList(),
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF0D6548),
            content: Text('Review submitted successfully! Thank you for rating.'),
            duration: Duration(seconds: 3),
          ),
        );
        widget.onReviewSubmitted?.call();
      }
    } catch (e) {
      if (mounted) {
        final errText = e.toString().replaceAll('Exception: ', '');
        setState(() {
          _isSubmitting = false;
          _errorMessage = errText.contains('already')
              ? 'You have already submitted a review for this job. Duplicate reviews are not permitted.'
              : errText;
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
            // Handle bar
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

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.paleMint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.star_rounded, color: AppColors.headerGreenDark, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.rateJobTitle ?? 'Rate & Review Job',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
                      ),
                      Text(
                        '${widget.jobTitle} • ${widget.counterpartyName}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Star Rating Row
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return IconButton(
                        iconSize: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        icon: Icon(
                          starIndex <= _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                        onPressed: () => setState(() => _stars = starIndex),
                      );
                    }),
                  ),
                  Text(
                    _getStarLabel(_stars, l10n),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quick Tags Section
            Text(
              l10n?.quickTagsLabel ?? 'Quick Tags',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ReviewQuickTag.defaultTags.map((tag) {
                final isSelected = _selectedTags.contains(tag.defaultLabel);
                return FilterChip(
                  label: Text('${tag.icon} ${tag.defaultLabel}'),
                  selected: isSelected,
                  selectedColor: AppColors.paleMint,
                  checkmarkColor: AppColors.headerGreenDark,
                  backgroundColor: Colors.grey.shade100,
                  side: BorderSide(
                    color: isSelected ? AppColors.headerGreenDark : Colors.grey.shade300,
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.headerGreenDark : AppColors.textDark,
                  ),
                  onSelected: (_) => _toggleTag(tag.defaultLabel),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            // Written Comment Input
            Text(
              l10n?.reviewCommentLabel ?? 'Feedback & Review (Optional)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: l10n?.reviewCommentHint ?? 'Share your experience to help the community...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.headerGreenDark, width: 1.5),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade900, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.headerGreenDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting ? null : _submitReview,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        l10n?.submitReviewBtn ?? 'Submit Verified Review',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStarLabel(int stars, AppLocalizations? l10n) {
    switch (stars) {
      case 5:
        return '⭐⭐⭐⭐⭐ Excellent (5/5)';
      case 4:
        return '⭐⭐⭐⭐ Very Good (4/5)';
      case 3:
        return '⭐⭐⭐ Average (3/5)';
      case 2:
        return '⭐⭐ Poor (2/5)';
      case 1:
        return '⭐ Terrible (1/5)';
      default:
        return '$stars Stars';
    }
  }
}
