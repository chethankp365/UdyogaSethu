import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/services/job_thumbnail_service.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_job_item.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_jobs_controller.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class SeekerJobsScreen extends ConsumerStatefulWidget {
  const SeekerJobsScreen({super.key});

  @override
  ConsumerState<SeekerJobsScreen> createState() => _SeekerJobsScreenState();
}

class _SeekerJobsScreenState extends ConsumerState<SeekerJobsScreen> {
  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(seekerJobsControllerProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          l10n?.navJobs ?? 'My Jobs & Applications',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Schedule & Travel',
            onPressed: () => context.push(AppRoutes.workerSchedule),
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'GPS Map',
            onPressed: () => context.push(AppRoutes.seekerMap),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.read(seekerJobsControllerProvider.notifier).loadJobs(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Horizontal Segment Picker Bar (5 Segments)
          _buildSegmentBar(jobsState),

          // 2. Segment Content
          Expanded(
            child: jobsState.isLoading && jobsState.currentList.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.headerGreenDark))
                : RefreshIndicator(
                    color: AppColors.headerGreenDark,
                    onRefresh: () => ref.read(seekerJobsControllerProvider.notifier).loadJobs(),
                    child: _buildSegmentList(context, jobsState),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentBar(SeekerJobsState state) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildSegmentPill(
              segment: SeekerJobSegment.applied,
              label: 'Applied',
              count: state.segments[SeekerJobSegment.applied]?.length ?? 0,
              isSelected: state.selectedSegment == SeekerJobSegment.applied,
            ),
            const SizedBox(width: 8),
            _buildSegmentPill(
              segment: SeekerJobSegment.requests,
              label: 'Requests',
              count: state.segments[SeekerJobSegment.requests]?.length ?? 0,
              isSelected: state.selectedSegment == SeekerJobSegment.requests,
              isHighlight: (state.segments[SeekerJobSegment.requests]?.length ?? 0) > 0,
            ),
            const SizedBox(width: 8),
            _buildSegmentPill(
              segment: SeekerJobSegment.accepted,
              label: 'Accepted',
              count: state.segments[SeekerJobSegment.accepted]?.length ?? 0,
              isSelected: state.selectedSegment == SeekerJobSegment.accepted,
            ),
            const SizedBox(width: 8),
            _buildSegmentPill(
              segment: SeekerJobSegment.active,
              label: 'Active',
              count: state.segments[SeekerJobSegment.active]?.length ?? 0,
              isSelected: state.selectedSegment == SeekerJobSegment.active,
            ),
            const SizedBox(width: 8),
            _buildSegmentPill(
              segment: SeekerJobSegment.completed,
              label: 'Completed',
              count: state.segments[SeekerJobSegment.completed]?.length ?? 0,
              isSelected: state.selectedSegment == SeekerJobSegment.completed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentPill({
    required SeekerJobSegment segment,
    required String label,
    required int count,
    required bool isSelected,
    bool isHighlight = false,
  }) {
    Color bg;
    Color fg;
    BorderSide side;

    if (isSelected) {
      bg = AppColors.headerGreenDark;
      fg = Colors.white;
      side = BorderSide.none;
    } else if (isHighlight) {
      bg = const Color(0xFFFEF3C7); // Amber light
      fg = const Color(0xFFB45309); // Amber dark
      side = const BorderSide(color: Color(0xFFF59E0B));
    } else {
      bg = const Color(0xFFF1F5F9);
      fg = AppColors.textDark;
      side = BorderSide.none;
    }

    return InkWell(
      onTap: () => ref.read(seekerJobsControllerProvider.notifier).selectSegment(segment),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: side == BorderSide.none ? null : Border.fromBorderSide(side),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
                color: fg,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : (isHighlight ? const Color(0xFFF59E0B) : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : (isHighlight ? Colors.white : AppColors.textDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentList(BuildContext context, SeekerJobsState state) {
    final list = state.currentList;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (list.isEmpty)
          _buildEmptyState(state.selectedSegment)
        else
          ...list.map((item) => _buildJobCard(context, item, state.selectedSegment)),
      ],
    );
  }

  Widget _buildJobCard(BuildContext context, SeekerJobItem item, SeekerJobSegment segment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          if (segment == SeekerJobSegment.active || segment == SeekerJobSegment.accepted) {
            context.push('/jobs/active/${item.id}');
          } else {
            context.push('/job/${item.jobId}');
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Category icon, Title, Wage badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  JobThumbnailWidget(
                    categorySlug: item.categorySlug,
                    jobId: item.jobId,
                    title: item.title,
                    width: 48,
                    height: 48,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              item.providerName,
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            if (item.providerVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 14),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.paleMint,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorderGreen),
                    ),
                    child: Text(
                      '₹${item.wageRupees}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.headerGreenDark,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Details row: Time & Location
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatDate(item.startAt)} • ${item.durationDisplay}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const Spacer(),
                  _buildStatusBadge(item.status),
                ],
              ),

              // Action buttons specific to segment
              if (segment == SeekerJobSegment.requests) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Accept button
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.headerGreenDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => _handleAccept(context, item),
                        child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Decline button
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: () => _handleDecline(context, item),
                      child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.headerGreenDark,
                      side: const BorderSide(color: AppColors.cardBorderGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    label: const Text('Request More Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Chat with ${item.providerName} opens in P7.1')),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'applied':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        label = 'Applied';
        break;
      case 'shortlisted':
        bg = Colors.purple.shade50;
        fg = Colors.purple.shade800;
        label = 'Shortlisted ★';
        break;
      case 'hired':
      case 'accepted':
      case 'ticket_issued':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        label = 'Accepted ✓';
        break;
      case 'requested':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        label = 'Invitation Pending';
        break;
      case 'arrived':
      case 'in_progress_verified':
        bg = Colors.teal.shade50;
        fg = Colors.teal.shade800;
        label = 'In Progress ⏳';
        break;
      case 'completed':
      case 'payment_released':
        bg = Colors.green.shade50;
        fg = AppColors.headerGreenDark;
        label = 'Completed ✓';
        break;
      case 'rejected':
      case 'cancelled':
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        label = 'Closed';
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade800;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: fg),
      ),
    );
  }

  Widget _buildEmptyState(SeekerJobSegment segment) {
    String title;
    String subtitle;
    IconData icon;

    switch (segment) {
      case SeekerJobSegment.applied:
        title = 'No Applications Yet';
        subtitle = 'Jobs you apply for will appear here with live employer responses.';
        icon = Icons.send_outlined;
        break;
      case SeekerJobSegment.requests:
        title = 'No Direct Requests';
        subtitle = 'When employers book you directly, invitations appear here with Accept/Decline options.';
        icon = Icons.inbox_rounded;
        break;
      case SeekerJobSegment.accepted:
        title = 'No Upcoming Accepted Jobs';
        subtitle = 'Accepted work shifts and your digital QR job tickets will appear here.';
        icon = Icons.event_available_rounded;
        break;
      case SeekerJobSegment.active:
        title = 'No Active Jobs in Progress';
        subtitle = 'Shifts verified with on-site QR scans will be tracked here in realtime.';
        icon = Icons.hourglass_empty_rounded;
        break;
      case SeekerJobSegment.completed:
        title = 'No Completed Jobs Yet';
        subtitle = 'Your finished jobs, earnings receipts, and reviews will be listed here.';
        icon = Icons.task_alt_rounded;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.headerGreenDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () => context.go(AppRoutes.seekerMap),
              icon: const Icon(Icons.explore_outlined, size: 18),
              label: const Text('Find jobs near you 📍', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAccept(BuildContext context, SeekerJobItem item) async {
    final result = await ref.read(seekerJobsControllerProvider.notifier).acceptAssignment(item.id);

    if (!context.mounted) return;

    if (result.success) {
      // If travel warning returned by SQL
      if (result.travelWarning) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber),
                SizedBox(width: 8),
                Text('Travel Time Warning', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: Text(
              'Job "${item.title}" accepted! Note: This job starts within 60 minutes of another scheduled shift (${result.gapMinutes?.toStringAsFixed(0) ?? 'less than 60'} min gap). Please plan travel carefully.',
              style: const TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Understood'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Accepted "${item.title}"! Moved to Accepted jobs. ✓')),
        );
      }
    } else {
      // Double booking conflict or other refusal
      final error = result.error ?? 'Failed to accept invitation';
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.event_busy_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Schedule Conflict', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            error.contains('overlapping')
                ? 'You already have an overlapping active or accepted job assignment scheduled at this time. Double-booking is not permitted.'
                : error,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleDecline(BuildContext context, SeekerJobItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Invitation?'),
        content: Text('Are you sure you want to decline this job invitation from ${item.providerName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Decline', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final ok = await ref.read(seekerJobsControllerProvider.notifier).declineAssignment(item.id);
      if (context.mounted && ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation declined.')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return 'Today';
    } else if (date.day == now.day + 1 && date.month == now.month && date.year == now.year) {
      return 'Tomorrow';
    }
    return '${date.day}/${date.month}';
  }
}
