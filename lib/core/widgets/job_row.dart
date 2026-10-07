import 'package:flutter/material.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/seeker/domain/job_recommendation.dart';

class JobRow extends StatelessWidget {
  final JobRecommendation job;
  final bool isApplied;
  final VoidCallback? onApply;
  final VoidCallback? onTap;
  final String? seekerType;

  const JobRow({
    super.key,
    required this.job,
    this.isApplied = false,
    this.onApply,
    this.onTap,
    this.seekerType,
  });

  static const Set<String> _knownSlugs = {
    'agri_labour',
    'campus-brand-promotion',
    'carpenter',
    'cleaner',
    'construction',
    'content-writing',
    'delivery',
    'delivery-gig-work',
    'design-data-work',
    'domestic_help',
    'driver',
    'electrician',
    'loader',
    'mason',
    'painting',
    'plumbing',
    'retail-food-service',
    'tutoring-academics',
    'general',
  };

  static String getCategoryAsset(String slug, String jobId) {
    final effectiveSlug = _knownSlugs.contains(slug) ? slug : 'general';
    final variant = (jobId.hashCode.abs() % 2) + 1;
    return 'assets/images/jobs/$effectiveSlug-$variant.webp';
  }

  static void precacheJobs(BuildContext context, List<JobRecommendation> jobs, {int count = 5}) {
    for (int i = 0; i < jobs.length && i < count; i++) {
      final path = getCategoryAsset(jobs[i].categorySlug, jobs[i].id);
      try {
        precacheImage(
          AssetImage(path),
          context,
          onError: (error, stackTrace) {
            // Silently ignore asset pre-caching errors in tests or missing asset fallbacks
          },
        );
      } catch (_) {}
    }
  }

  static IconData getCategoryIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'plumbing':
        return Icons.plumbing_rounded;
      case 'electrician':
        return Icons.electrical_services_rounded;
      case 'carpenter':
        return Icons.carpenter_rounded;
      case 'construction':
      case 'mason':
        return Icons.handyman_rounded;
      case 'cleaning':
      case 'cleaner':
        return Icons.cleaning_services_rounded;
      case 'loader':
        return Icons.inventory_2_rounded;
      case 'painting':
        return Icons.format_paint_rounded;
      case 'driver':
        return Icons.drive_eta_rounded;
      case 'agri':
      case 'agri_labour':
        return Icons.agriculture_rounded;
      case 'domestic_help':
        return Icons.home_repair_service_rounded;
      case 'edit_note':
      case 'content-writing':
        return Icons.edit_note_rounded;
      case 'computer':
      case 'design-data-work':
        return Icons.computer_rounded;
      case 'school':
      case 'tutoring-academics':
        return Icons.school_rounded;
      case 'campaign':
      case 'campus-brand-promotion':
        return Icons.campaign_rounded;
      case 'storefront':
      case 'retail-food-service':
        return Icons.storefront_rounded;
      case 'two_wheeler':
      case 'delivery':
      case 'delivery-gig-work':
        return Icons.two_wheeler_rounded;
      default:
        return Icons.work_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = getCategoryAsset(job.categorySlug, job.id);

    return InkWell(
      onTap: onTap ??
          () {
            // Placeholder dialog for Job Detail until P4.3
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (ctx) => Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            assetPath,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildFallbackThumbnail(),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                job.employerName,
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      job.description ?? 'Job details and requirements will appear here in Phase 4.3.',
                      style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          job.formattedWage,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.headerGreenDark,
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isApplied ? Colors.grey.shade400 : AppColors.headerGreenDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: isApplied
                              ? null
                              : () {
                                  Navigator.pop(ctx);
                                  onApply?.call();
                                },
                          child: Text(isApplied ? 'Applied ✓' : 'Apply Now'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Square Rounded Thumbnail Photo (56px)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                assetPath,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallbackThumbnail(),
              ),
            ),

            const SizedBox(width: 12),

            // 2. Middle Column: Title, Employer, Rating + Distance, Tags line
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    job.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 3),

                  // Employer with green verified tick
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          job.employerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      if (job.employerVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 13,
                          color: Color(0xFF10B981),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 3),

                  // Rating and Distance line
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        job.employerRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      Flexible(
                        child: Text(
                          job.formattedDistance,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Extra info line (second small line for tags/reasons)
                  if (job.reasons.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      job.reasons.first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // 3. Right Column: Wage in bold green + "Apply Now" green pill
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  job.formattedWage,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D6548),
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: isApplied ? null : onApply,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isApplied ? Colors.grey.shade200 : const Color(0xFF0D6548),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      isApplied ? 'Applied ✓' : 'Apply Now',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isApplied ? AppColors.textMuted : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackThumbnail() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        getCategoryIcon(job.categoryIcon),
        color: AppColors.headerGreenDark,
        size: 26,
      ),
    );
  }
}
