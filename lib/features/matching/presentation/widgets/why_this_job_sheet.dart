import 'package:flutter/material.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/seeker/domain/job_recommendation.dart';

/// Modal bottom sheet explaining "Why this job was recommended for you"
class WhyThisJobSheet extends StatelessWidget {
  final JobRecommendation job;

  const WhyThisJobSheet({super.key, required this.job});

  static Future<void> show(BuildContext context, JobRecommendation job) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => WhyThisJobSheet(job: job),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reasons = job.reasons.isNotEmpty
        ? job.reasons
        : ['Skill match', 'Nearby location', 'Fair wage benchmark', 'Flexible hours'];

    return Padding(
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
                  child: const Icon(Icons.psychology_alt_rounded, color: AppColors.headerGreenDark, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Why this job was recommended',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                      ),
                      Text(
                        job.title,
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Recommendation reasons list
            ...reasons.map((reason) {
              IconData icon = Icons.check_circle_outline_rounded;
              Color iconColor = AppColors.primaryTeal;

              final lower = reason.toLowerCase();
              if (lower.contains('skill')) {
                icon = Icons.handyman_rounded;
              } else if (lower.contains('near') || lower.contains('km') || lower.contains('dist')) {
                icon = Icons.near_me_rounded;
              } else if (lower.contains('wage') || lower.contains('pay') || lower.contains('earn')) {
                icon = Icons.currency_rupee_rounded;
              } else if (lower.contains('hour') || lower.contains('time') || lower.contains('shift')) {
                icon = Icons.schedule_rounded;
              } else if (lower.contains('employ') || lower.contains('rate')) {
                icon = Icons.verified_rounded;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: iconColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        reason,
                        style: const TextStyle(fontSize: 13.5, color: AppColors.textDark, height: 1.3),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),

            // Transparency note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rule-based suggestion: Job suggestions prioritize verified skill profiles, travel proximity, and regional wage benchmarks without automated lock-in.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF475569), height: 1.35),
                    ),
                  ),
                ],
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
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
