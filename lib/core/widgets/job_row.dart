import 'package:flutter/material.dart';
import 'package:udyogasethu/core/services/job_thumbnail_service.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/job_action_button.dart';
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

  static String getCategoryAsset(String slug, String jobId, {String? title, String? description, String? sitePhotoUrl}) {
    return JobThumbnailService().selectThumbnail(
      sitePhotoUrl: sitePhotoUrl,
      categorySlug: slug,
      jobId: jobId,
      title: title,
      description: description,
    ).uri;
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
                        JobThumbnailWidget(
                          sitePhotoUrl: job.sitePhotoUrl,
                          categorySlug: job.categorySlug,
                          jobId: job.id,
                          title: job.title,
                          description: job.description,
                          width: 60,
                          height: 60,
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
                        JobActionButton(
                          jobId: job.id,
                          jobTitle: job.title,
                          isCompact: false,
                          onApplyCustom: () {
                            Navigator.pop(ctx);
                            onApply?.call();
                          },
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
            JobThumbnailWidget(
              sitePhotoUrl: job.sitePhotoUrl,
              categorySlug: job.categorySlug,
              jobId: job.id,
              title: job.title,
              description: job.description,
              width: 56,
              height: 56,
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
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 3,
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                      Text(
                        job.employerRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const Text(
                        '•',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      Text(
                        job.formattedDistance,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),

                  // Extra info line (second small line for tags/reasons)
                  if (job.studentsOk || job.reasons.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (job.studentsOk)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFF59E0B), width: 0.8),
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.school, size: 10, color: Color(0xFFD97706)),
                                  SizedBox(width: 3),
                                  Text(
                                    'Students Welcome',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (job.reasons.isNotEmpty)
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
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // 3. Right Column: Wage in bold green + "Apply Now" green pill
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      job.formattedWage,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D6548),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  JobActionButton(
                    jobId: job.id,
                    jobTitle: job.title,
                    isCompact: true,
                    onApplyCustom: onApply,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
