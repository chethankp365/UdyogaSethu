import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/widgets/user_avatar.dart';
import 'package:udyogasethu/features/provider/data/provider_jobs_repository.dart';
import 'package:udyogasethu/features/provider/domain/job_applicant.dart';
import 'package:udyogasethu/features/provider/domain/provider_job.dart';
import 'package:udyogasethu/features/provider/presentation/provider_jobs_controller.dart';
import 'package:udyogasethu/core/widgets/app_thumbnail.dart';
import 'package:udyogasethu/features/chat/data/chat_repository.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class JobApplicantsScreen extends ConsumerWidget {
  final String jobId;

  const JobApplicantsScreen({
    super.key,
    required this.jobId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final applicantsAsync = ref.watch(jobApplicantsFutureProvider(jobId));
    final jobsList = ref.watch(providerJobsNotifierProvider).asData?.value ?? [];
    final currentJob = jobsList.where((j) => j.id == jobId).firstOrNull;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        title: Text(
          currentJob != null ? currentJob.title : 'Job Applicants',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.refresh(jobApplicantsFutureProvider(jobId)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Job Slots Header Card
          if (currentJob != null) _buildJobSummaryHeader(currentJob, l10n),
          // Applicants List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.refresh(jobApplicantsFutureProvider(jobId)),
              child: applicantsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => _buildErrorCard(context, ref, err, jobId),
                data: (applicants) {
                  if (applicants.isEmpty) {
                    return _buildEmptyApplicants(l10n);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: applicants.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final applicant = applicants[index];
                      return ApplicantCard(
                        applicant: applicant,
                        job: currentJob,
                        onHire: () => _handleHire(context, ref, applicant, currentJob, l10n),
                        onShortlist: () => _handleShortlist(context, ref, applicant, l10n),
                        onReject: () => _handleReject(context, ref, applicant, l10n),
                        onViewProfile: () => _showWorkerProfileDialog(context, applicant),
                        onChat: () => _handleChat(context, ref, applicant),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobSummaryHeader(ProviderJob job, AppLocalizations l10n) {
    final progress = job.slotsTotal > 0 ? (job.slotsFilled / job.slotsTotal).clamp(0.0, 1.0) : 0.0;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              JobThumbnail.fromProviderJob(
                job,
                size: ThumbnailSize.small,
                width: 52,
                height: 52,
                borderRadius: BorderRadius.circular(10),
                showTitle: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.providerSlotsCounter(job.slotsFilled, job.slotsTotal),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.headerGreenDark),
                    ),
                  ],
                ),
              ),
              Chip(
                visualDensity: VisualDensity.compact,
                backgroundColor: job.isFilled ? Colors.blue.shade100 : AppColors.paleMint,
                label: Text(
                  job.isFilled ? 'Filled' : l10n.providerSlotsOpenCount(job.slotsOpen),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: job.isFilled ? Colors.blue.shade900 : AppColors.headerGreenDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: job.isFilled ? Colors.blue : AppColors.headerGreenDark,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, WidgetRef ref, Object err, String jobId) {
    final friendly = AppException.userFriendlyMessage(err);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to Load Applicants',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              friendly,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Text(
                err.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.red, fontFamily: 'monospace'),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.headerGreenDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => ref.invalidate(jobApplicantsFutureProvider(jobId)),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyApplicants(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.paleMint.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.headerGreenDark),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.applicantsNoApplicantsTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.applicantsNoApplicantsDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleHire(
    BuildContext context,
    WidgetRef ref,
    JobApplicant applicant,
    ProviderJob? job,
    AppLocalizations l10n,
  ) async {
    if (job != null && job.slotsFilled >= job.slotsTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.applicantJobFullNotice), backgroundColor: Colors.orange),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.applicantHireConfirmTitle),
        content: Text(l10n.applicantHireConfirmDesc(applicant.workerName)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.headerGreenDark, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.applicantActionHire),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repo = ref.read(providerJobsRepositoryProvider);
        await repo.respondToApplicant(
          applicationId: applicant.applicationId,
          status: 'hired',
        );
        ref.invalidate(jobApplicantsFutureProvider(jobId));
        await ref.read(providerJobsNotifierProvider.notifier).refreshJobs();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.applicantHiredSuccess),
              backgroundColor: AppColors.headerGreenDark,
              action: SnackBarAction(
                label: 'Chat',
                textColor: Colors.amberAccent,
                onPressed: () async {
                  try {
                    final chatRepo = ref.read(chatRepositoryProvider);
                    final threadId = await chatRepo.getOrCreateThread(
                      contextType: 'job',
                      contextId: jobId,
                      recipientId: applicant.workerId,
                    );
                    if (context.mounted && threadId.isNotEmpty && threadId != 'offline_thread') {
                      context.push('${AppRoutes.chatDetail}/$threadId');
                    }
                  } catch (_) {}
                },
              ),
            ),
          );
        }
      } catch (e, stack) {
        AppLogger.e('Error hiring applicant', e, stack);
        if (context.mounted) {
          final msg = AppException.userFriendlyMessage(e);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $msg'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleShortlist(BuildContext context, WidgetRef ref, JobApplicant applicant, AppLocalizations l10n) async {
    try {
      final repo = ref.read(providerJobsRepositoryProvider);
      await repo.respondToApplicant(applicationId: applicant.applicationId, status: 'shortlisted');
      ref.invalidate(jobApplicantsFutureProvider(jobId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${applicant.workerName} shortlisted'),
            backgroundColor: AppColors.headerGreenDark,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to shortlist: ${AppException.userFriendlyMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(BuildContext context, WidgetRef ref, JobApplicant applicant, AppLocalizations l10n) async {
    try {
      final repo = ref.read(providerJobsRepositoryProvider);
      await repo.respondToApplicant(applicationId: applicant.applicationId, status: 'rejected');
      ref.invalidate(jobApplicantsFutureProvider(jobId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${applicant.workerName} application declined'),
            backgroundColor: Colors.grey.shade800,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline: ${AppException.userFriendlyMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleChat(BuildContext context, WidgetRef ref, JobApplicant applicant) async {
    final repo = ref.read(chatRepositoryProvider);
    final idSnippet = applicant.applicationId.length >= 6
        ? applicant.applicationId.substring(0, 6).toUpperCase()
        : applicant.applicationId;
    final threadId = await repo.getOrCreateThread(
      contextType: 'application',
      contextId: applicant.applicationId,
      recipientId: applicant.workerId,
      subject: applicant.workerName,
      bookingCode: 'APP-$idSnippet',
      categoryTag: 'worker',
    );
    if (context.mounted) {
      context.push('${AppRoutes.chatDetail}/$threadId');
    }
  }

  void _showWorkerProfileDialog(BuildContext context, JobApplicant applicant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                UserAvatar(avatarPath: applicant.workerAvatar, name: applicant.workerName, radius: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(applicant.workerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                          if (applicant.isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: AppColors.headerGreenDark, size: 20),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.amberOrange, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${applicant.rating.toStringAsFixed(1)} (${applicant.reviewCount} reviews)',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${applicant.jobsCompletedCount} jobs completed', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text('Distance: ${applicant.formattedDistance}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Text('Languages: ${applicant.languages.join(", ")}', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            const Text('Skills:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: applicant.skills.map((s) => Chip(label: Text(s, style: const TextStyle(fontSize: 11)))).toList(),
            ),
            if (applicant.message != null && applicant.message!.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('Applicant Message:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text(applicant.message!, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class ApplicantCard extends StatelessWidget {
  final JobApplicant applicant;
  final ProviderJob? job;
  final VoidCallback onHire;
  final VoidCallback onShortlist;
  final VoidCallback onReject;
  final VoidCallback onViewProfile;
  final VoidCallback onChat;

  const ApplicantCard({
    super.key,
    required this.applicant,
    required this.job,
    required this.onHire,
    required this.onShortlist,
    required this.onReject,
    required this.onViewProfile,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isJobFull = job != null && job!.slotsFilled >= job!.slotsTotal;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar, Worker Name + Verification, and Status Chip
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                UserAvatar(avatarPath: applicant.workerAvatar, name: applicant.workerName, radius: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          applicant.workerName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (applicant.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: AppColors.headerGreenDark, size: 16),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(applicant, l10n),
              ],
            ),

            const SizedBox(height: 6),

            // Subtitle Row: Seeker Type & Level Badge
            Row(
              children: [
                // Seeker Type Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: applicant.seekerType == 'student'
                        ? Colors.purple.shade50
                        : applicant.seekerType == 'part_time'
                            ? Colors.blue.shade50
                            : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: applicant.seekerType == 'student'
                          ? Colors.purple.shade200
                          : applicant.seekerType == 'part_time'
                              ? Colors.blue.shade200
                              : Colors.amber.shade200,
                    ),
                  ),
                  child: Text(
                    applicant.seekerType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
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
                // Badge / Level
                Flexible(
                  child: Text(
                    'Lv.${applicant.levelNumber} • ${applicant.badgeName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Metrics row: Rating, Jobs Done, Distance and Applied Date
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.amberOrange, size: 15),
                    const SizedBox(width: 2),
                    Text(applicant.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(
                  '• ${l10n.applicantCardJobsDone(applicant.jobsCompletedCount)}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 2),
                    Text(applicant.formattedDistance, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
                Text(
                  '• ${DateFormat('dd MMM, h:mm a').format(applicant.createdAt)}',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),

            // Languages & Skills Chips
            if (applicant.skills.isNotEmpty || applicant.languages.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ...applicant.languages.take(2).map((lang) => Chip(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.grey.shade100,
                        label: Text(lang.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                      )),
                  ...applicant.skills.take(3).map((skill) => Chip(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        backgroundColor: AppColors.paleMint.withValues(alpha: 0.6),
                        label: Text(skill, style: const TextStyle(fontSize: 10, color: AppColors.headerGreenDark, fontWeight: FontWeight.w600)),
                      )),
                ],
              ),
            ],

            if (applicant.message != null && applicant.message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text('"${applicant.message}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              ),
            ],

            const Divider(height: 20),

            // Actions row: View Profile, Chat, Reject, Shortlist, Hire (Icon + Text)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: onViewProfile,
                  icon: const Icon(Icons.person_outline, size: 16),
                  label: Text(l10n.applicantActionProfile, style: const TextStyle(fontSize: 12)),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: onChat,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: Text(l10n.applicantActionChat, style: const TextStyle(fontSize: 12)),
                ),
                if (applicant.isPending || applicant.isShortlisted) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: Text(l10n.applicantActionReject, style: const TextStyle(fontSize: 12)),
                  ),
                  if (applicant.isPending)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: onShortlist,
                      icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                      label: Text(l10n.applicantActionShortlist, style: const TextStyle(fontSize: 12)),
                    ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isJobFull ? Colors.grey : AppColors.headerGreenDark,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: isJobFull ? null : onHire,
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(l10n.applicantActionHire, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ] else if (applicant.isHired) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Text(l10n.applicantStatusHired, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(JobApplicant applicant, AppLocalizations l10n) {
    Color bg;
    Color fg;
    String label;
    if (applicant.isHired) {
      bg = Colors.green.shade100;
      fg = Colors.green.shade900;
      label = l10n.applicantStatusHired;
    } else if (applicant.isShortlisted) {
      bg = Colors.blue.shade100;
      fg = Colors.blue.shade900;
      label = l10n.applicantStatusShortlisted;
    } else if (applicant.isRejected) {
      bg = Colors.grey.shade200;
      fg = Colors.grey.shade700;
      label = l10n.applicantStatusRejected;
    } else if (applicant.status == 'withdrawn') {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade900;
      label = 'Withdrawn';
    } else {
      bg = AppColors.paleMint;
      fg = AppColors.headerGreenDark;
      label = l10n.applicantStatusApplied;
    }
    return Container(
      constraints: const BoxConstraints(maxWidth: 90),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
        ),
      ),
    );
  }
}
