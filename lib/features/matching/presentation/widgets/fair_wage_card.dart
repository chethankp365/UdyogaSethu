import 'package:flutter/material.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/matching/domain/wage_suggestion.dart';

/// Reusable Fair Wage Suggestion Card with non-blocking warning and explainer bottom sheet.
class FairWageCard extends StatelessWidget {
  final WageSuggestion suggestion;
  final int offeredWagePaise;
  final VoidCallback? onApplySuggested;

  const FairWageCard({
    super.key,
    required this.suggestion,
    required this.offeredWagePaise,
    this.onApplySuggested,
  });

  void _showExplanationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SafeArea(
          top: false,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.paleMint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.analytics_outlined, color: AppColors.headerGreenDark, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Fair Wage Calculation Explained',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...suggestion.explanationFactors.map((factor) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.primaryTeal, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          factor,
                          style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'Note: Fair-wage calculations are rule-based suggestions to promote dignified livelihoods. You retain full autonomy to set custom compensation.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.35),
                ),
              ),
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
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBelow = suggestion.isBelowSuggested(offeredWagePaise);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fair Wage Range & Explainer Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.paleMint.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorderGreen),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics_rounded, color: AppColors.headerGreenDark, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Suggested Fair Wage: ${suggestion.formattedRange}/${suggestion.unit}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.headerGreenDark,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _showExplanationSheet(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.help_outline_rounded, color: Colors.green.shade800, size: 15),
                          const SizedBox(width: 4),
                          Text(
                            'Why?',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (onApplySuggested != null && isBelow) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: onApplySuggested,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.headerGreenDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Apply Suggested Min (₹${suggestion.suggestedMinRupees})',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Non-blocking warning when below suggested range
        if (isBelow) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Wage is below the suggested fair benchmark (${suggestion.formattedRange}). Posting will not be blocked, but offers meeting fair benchmarks receive higher applicant interest.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
