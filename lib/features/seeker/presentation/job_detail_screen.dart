import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/user_avatar.dart';
import 'package:udyogasethu/features/provider/data/provider_jobs_repository.dart';
import 'package:udyogasethu/features/provider/domain/job_applicant.dart';
import 'package:udyogasethu/features/provider/presentation/provider_jobs_controller.dart';
import 'package:udyogasethu/features/seeker/domain/job_detail.dart';
import 'package:udyogasethu/features/seeker/domain/job_recommendation.dart';
import 'package:udyogasethu/features/seeker/presentation/apply_bottom_sheet.dart';
import 'package:udyogasethu/core/services/job_thumbnail_service.dart';
import 'package:udyogasethu/features/seeker/presentation/job_detail_controller.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;
  final JobRecommendation? preloadedJob;

  const JobDetailScreen({
    super.key,
    required this.jobId,
    this.preloadedJob,
  });

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  bool _isCurrentUserProvider(String providerId) {
    try {
      return Supabase.instance.client.auth.currentUser?.id == providerId;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(jobDetailFutureProvider(widget.jobId));
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: detailAsync.when(
        data: (data) => _buildDetailContent(context, data.detail, data.isOffline, l10n),
        loading: () {
          // If we have preloadedJob from navigation, display immediately with shimmer
          if (widget.preloadedJob != null) {
            final fallback = _convertPreloaded(widget.preloadedJob!);
            return _buildDetailContent(context, fallback, false, l10n, isLoading: true);
          }
          return const Center(child: CircularProgressIndicator(color: AppColors.headerGreenDark));
        },
        error: (err, _) {
          if (widget.preloadedJob != null) {
            final fallback = _convertPreloaded(widget.preloadedJob!);
            return _buildDetailContent(context, fallback, true, l10n);
          }
          return Scaffold(
            appBar: AppBar(title: const Text('Job Details')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Failed to load job: $err'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(jobDetailFutureProvider(widget.jobId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  JobDetail _convertPreloaded(JobRecommendation job) {
    return JobDetail(
      id: job.id,
      providerId: 'provider-${job.id}',
      providerName: job.employerName,
      providerVerified: job.employerVerified,
      providerRating: job.employerRating,
      title: job.title,
      description: job.description ?? 'Reliable, verified work opportunity through UdyogaSethu. Apply to connect with the employer.',
      categorySlug: job.categorySlug,
      categoryIcon: job.categoryIcon,
      wagePaise: job.wagePaise,
      wageType: job.wageType,
      estDurationMinutes: job.estDurationMinutes ?? 480,
      startAt: job.startAt ?? DateTime.now().add(const Duration(hours: 12)),
      materialsProvided: true,
      paymentMode: 'escrow',
      slotsTotal: job.slotsTotal,
      slotsFilled: job.slotsFilled,
      distanceKm: job.distanceM / 1000.0,
      walkingMinutes: ((job.distanceM / 1000.0) * 12).toInt().clamp(5, 60),
    );
  }

  Widget _buildDetailContent(
    BuildContext context,
    JobDetail job,
    bool isOffline,
    AppLocalizations? l10n, {
    bool isLoading = false,
  }) {
    final thumb = JobThumbnailService().selectThumbnail(
      sitePhotoUrl: job.sitePhotoUrl,
      categorySlug: job.categorySlug,
      jobId: job.id,
      title: job.title,
      description: job.description,
    );
    final categoryIcon = thumb.categoryIcon;

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              // 1. HERO IMAGE HEADER (Matching Prototype Screen 34)
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: AppColors.headerGreenDark,
                leading: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.35),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.35),
                    child: IconButton(
                      icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text: 'Check out this job opportunity: ${job.title} at ${job.providerName} for ₹${job.wageRupees}/day on UdyogaSethu!',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Job details copied to clipboard')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (thumb.isNetwork)
                        Image.network(
                          thumb.uri,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Image.asset(
                            JobThumbnailService().selectThumbnail(categorySlug: job.categorySlug, jobId: job.id, title: job.title, description: job.description).uri,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: AppColors.headerGreenDark,
                              child: Icon(categoryIcon, color: Colors.white, size: 64),
                            ),
                          ),
                        )
                      else
                        Image.asset(
                          thumb.uri,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.headerGreenDark,
                            child: Icon(categoryIcon, color: Colors.white, size: 64),
                          ),
                        ),
                      // Dark gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.2),
                              const Color(0xFF0F172A).withValues(alpha: 0.85),
                            ],
                          ),
                        ),
                      ),
                      // Category overlay badge
                      Positioned(
                        bottom: 16,
                        left: 20,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(categoryIcon, color: AppColors.headerGreenDark, size: 28),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. OFFLINE BANNER (IF OFFLINE)
              if (isOffline)
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.amber.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const Row(
                      children: [
                        Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Offline Mode • Showing cached job details. Reconnect to apply.',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 3. JOB INFORMATION & DETAILS
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Job Title
                      Text(
                        job.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Provider Name with Verified Tick
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              job.providerName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (job.providerVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 18),
                          ],
                        ],
                      ),

                      if (job.studentsOk) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFF59E0B)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.school, size: 14, color: Color(0xFFD97706)),
                              const SizedBox(width: 6),
                              Text(
                                l10n?.studentsWelcomeChip ?? 'Students Welcome',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      if (_isCurrentUserProvider(job.providerId))
                        _buildProviderApplicantsSection(context, job),

                      // SPECS BAR (Rate, Distance, Walking Time)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSpecItem(Icons.work_outline_rounded, '₹${job.wageRupees}/day', 'Wage Rate'),
                            Container(width: 1, height: 28, color: Colors.grey.shade200),
                            _buildSpecItem(Icons.location_on_outlined, '${job.distanceKm.toStringAsFixed(1)} km away', 'Distance'),
                            Container(width: 1, height: 28, color: Colors.grey.shade200),
                            _buildSpecItem(Icons.directions_walk_rounded, '${job.walkingMinutes} min walk', 'Estimated Walk'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // RATING & VERIFIED EMPLOYER BADGE CARD
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.paleMint.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorderGreen),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.shield_rounded, color: AppColors.headerGreenDark, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${job.providerRating.toStringAsFixed(1)} (${job.providerReviewsCount} reviews)',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Verified Employer • Background verified & Escrow backed',
                                    style: TextStyle(fontSize: 12, color: AppColors.headerGreenDark, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // JOB DETAILS TABLE (Duration, Start Time, Materials, Payment, Slots)
                      const Text(
                        'Job Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildDetailTableRow('Duration', job.durationDisplay, Icons.timer_outlined),
                            const Divider(height: 1),
                            _buildDetailTableRow(
                              'Start Time',
                              _formatTime(job.startAt),
                              Icons.access_time_rounded,
                            ),
                            const Divider(height: 1),
                            _buildDetailTableRow(
                              'Materials',
                              job.materialsProvided ? 'Provided by site' : 'Bring own tools',
                              Icons.handyman_outlined,
                            ),
                            const Divider(height: 1),
                            _buildDetailTableRow(
                              'Payment',
                              job.paymentModeDisplay,
                              Icons.account_balance_wallet_outlined,
                            ),
                            const Divider(height: 1),
                            _buildDetailTableRow(
                              'Slots Open',
                              '${job.slotsOpen} open (${job.slotsTotal} total)',
                              Icons.group_outlined,
                            ),
                            const Divider(height: 1),
                            _buildDetailTableRow(
                              'Target Workers',
                              job.suitableFor.map((s) {
                                if (s == 'informal') return l10n?.postJobAudienceInformal ?? 'Informal';
                                if (s == 'student') return l10n?.postJobAudienceStudent ?? 'Student';
                                if (s == 'part_time') return l10n?.postJobAudiencePartTime ?? 'Part-Time';
                                return s;
                              }).join(', '),
                              Icons.groups_rounded,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // DESCRIPTION SECTION
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        job.description.isNotEmpty
                            ? job.description
                            : 'No specific description provided. Standard daily wages and guidelines apply.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF334155),
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // SITE PHOTO PREVIEW BOX
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          height: 130,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              JobThumbnailWidget(
                                sitePhotoUrl: job.sitePhotoUrl,
                                categorySlug: job.categorySlug,
                                jobId: job.id,
                                title: job.title,
                                description: job.description,
                                width: double.infinity,
                                height: 130,
                              ),
                              Container(
                                color: Colors.black.withValues(alpha: 0.3),
                                padding: const EdgeInsets.all(12),
                                alignment: Alignment.bottomLeft,
                                child: Row(
                                  children: [
                                    const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Verified Work Site: ${job.addressText}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 4. BOTTOM ACTION BAR (Chat Button + Apply Now Button)
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Chat Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.headerGreenDark,
                  side: const BorderSide(color: AppColors.headerGreenDark),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chat thread opens after applying or receiving booking invitation (wired in P7.1).'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                label: const Text('Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),

              const SizedBox(width: 12),

              // Apply Now or Manage Applicants Button
              Expanded(
                child: _isCurrentUserProvider(job.providerId)
                    ? ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.headerGreenDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => context.push(AppRoutes.providerJobApplicants.replaceAll(':id', job.id)),
                        icon: const Icon(Icons.group_rounded, size: 20),
                        label: const Text(
                          'Manage Applicants',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      )
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOffline ? Colors.grey.shade400 : AppColors.headerGreenDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: isOffline ? 0 : 2,
                        ),
                        onPressed: isOffline
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cannot apply while offline. Please connect to the internet to submit your application.'),
                                    backgroundColor: Colors.amber,
                                  ),
                                );
                              }
                            : () => ApplyBottomSheet.show(context, job),
                        icon: Icon(isOffline ? Icons.cloud_off_rounded : Icons.send_rounded, size: 18),
                        label: Text(
                          isOffline ? 'Offline - Reconnect to Apply' : 'Apply Now (Quick & Easy ✨)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecItem(IconData icon, String text, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.headerGreenDark, size: 20),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTableRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final min = time.minute.toString().padLeft(2, '0');
    return '$hour:$min $period';
  }

  Widget _buildProviderApplicantsSection(BuildContext context, JobDetail job) {
    final applicantsAsync = ref.watch(jobApplicantsFutureProvider(job.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_alt_rounded, color: AppColors.headerGreenDark, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    applicantsAsync.maybeWhen(
                      data: (list) => 'Applicants (${list.length})',
                      orElse: () => 'Applicants',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: job.slotsFilled >= job.slotsTotal ? Colors.blue.shade50 : AppColors.paleMint,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: job.slotsFilled >= job.slotsTotal ? Colors.blue.shade200 : AppColors.cardBorderGreen,
                  ),
                ),
                child: Text(
                  '${job.slotsFilled}/${job.slotsTotal} Slots Filled',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: job.slotsFilled >= job.slotsTotal ? Colors.blue.shade900 : AppColors.headerGreenDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          applicantsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: AppColors.headerGreenDark)),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Error loading applicants: $err', style: const TextStyle(fontSize: 12, color: Colors.red)),
            ),
            data: (applicants) {
              if (applicants.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.person_search_rounded, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      const Text(
                        'No applicants yet',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Workers in your area will appear here as soon as they apply.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: applicants.map((applicant) => _buildApplicantCard(context, applicant, job)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildApplicantCard(BuildContext context, JobApplicant applicant, JobDetail job) {
    final isFull = job.slotsFilled >= job.slotsTotal;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(avatarPath: applicant.workerAvatar, name: applicant.workerName, radius: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            applicant.workerName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                          ),
                        ),
                        if (applicant.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: AppColors.headerGreenDark, size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: applicant.seekerType == 'student'
                                ? Colors.purple.shade50
                                : applicant.seekerType == 'part_time'
                                    ? Colors.blue.shade50
                                    : Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            applicant.seekerType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: applicant.seekerType == 'student'
                                  ? Colors.purple.shade900
                                  : applicant.seekerType == 'part_time'
                                      ? Colors.blue.shade900
                                      : Colors.amber.shade900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Lv.${applicant.levelNumber} • ${applicant.badgeName}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.amberOrange, size: 15),
                        const SizedBox(width: 2),
                        Text(applicant.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 2),
                        Text(applicant.formattedDistance, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildApplicantStatusChip(applicant.status),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM, h:mm a').format(applicant.createdAt),
                    style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          if (applicant.skills.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: applicant.skills.take(3).map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.paleMint.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(s, style: const TextStyle(fontSize: 10, color: AppColors.headerGreenDark, fontWeight: FontWeight.bold)),
              )).toList(),
            ),
          ],
          if (applicant.message != null && applicant.message!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                '"${applicant.message!.trim()}"',
                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textDark),
              ),
            ),
          ],
          if (applicant.status == 'applied' || applicant.status == 'shortlisted') ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () async {
                    await ref.read(providerJobsRepositoryProvider).respondToApplicant(
                          applicationId: applicant.applicationId,
                          status: 'rejected',
                        );
                    ref.invalidate(jobApplicantsFutureProvider(job.id));
                  },
                  child: const Text('Decline', style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 8),
                if (applicant.status == 'applied') ...[
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.amberOrange,
                      side: BorderSide(color: Colors.amber.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () async {
                      await ref.read(providerJobsRepositoryProvider).respondToApplicant(
                            applicationId: applicant.applicationId,
                            status: 'shortlisted',
                          );
                      ref.invalidate(jobApplicantsFutureProvider(job.id));
                    },
                    child: const Text('Shortlist', style: TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFull ? Colors.grey.shade400 : AppColors.headerGreenDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: isFull
                      ? null
                      : () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Accept Worker'),
                              content: Text('Accept ${applicant.workerName} for "${job.title}"? This will confirm the booking.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.headerGreenDark, foregroundColor: Colors.white),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Confirm'),
                                ),
                              ],
                            ),
                          );

                          if (ok == true && context.mounted) {
                            try {
                              await ref.read(providerJobsRepositoryProvider).respondToApplicant(
                                    applicationId: applicant.applicationId,
                                    status: 'hired',
                                  );
                              ref.invalidate(jobApplicantsFutureProvider(job.id));
                              ref.invalidate(jobDetailFutureProvider(job.id));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${applicant.workerName} accepted! Booking confirmed.'),
                                    backgroundColor: AppColors.headerGreenDark,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          }
                        },
                  child: const Text('Accept', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApplicantStatusChip(String status) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade800;
    String label = status;

    if (status == 'hired') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
      label = 'Accepted ✓';
    } else if (status == 'shortlisted') {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade900;
      label = 'Shortlisted';
    } else if (status == 'rejected') {
      bg = Colors.red.shade50;
      fg = Colors.red.shade800;
      label = 'Declined';
    } else {
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade800;
      label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
