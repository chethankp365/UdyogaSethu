import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/job_execution/data/job_execution_repository.dart';
import 'package:udyogasethu/features/job_execution/domain/assignment_event_item.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

/// Reusable timeline widget reading `assignment_events` in Supabase Realtime.
/// Displays the 9 canonical stages: Request Created, Accepted, Ticket Issued,
/// Worker Arrived, Verification Completed, Job In Progress, Completed,
/// Payment Released, Dispute Raised.
class AssignmentTimelineWidget extends ConsumerWidget {
  final String assignmentId;
  final String currentStatus;
  final bool isProvider;

  const AssignmentTimelineWidget({
    super.key,
    required this.assignmentId,
    required this.currentStatus,
    this.isProvider = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(assignmentEventsStreamProvider(assignmentId));
    final l10n = AppLocalizations.of(context);

    return eventsAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.headerGreenDark),
        ),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Live timeline error: $err',
                style: const TextStyle(fontSize: 13, color: Colors.red),
              ),
            ),
          ],
        ),
      ),
      data: (events) {
        return _buildTimelineCard(context, events, l10n);
      },
    );
  }

  Widget _buildTimelineCard(
    BuildContext context,
    List<AssignmentEventItem> events,
    AppLocalizations? l10n,
  ) {
    // Sort events in true chronological order from event rows
    final sortedEvents = List<AssignmentEventItem>.from(events)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Collect event occurrences by stage
    final Map<AssignmentStage, AssignmentEventItem> stageEvents = {};
    for (final e in sortedEvents) {
      stageEvents[e.stage] = e;
    }

    final currentStage = AssignmentStage.fromString(currentStatus);
    final hasDispute = stageEvents.containsKey(AssignmentStage.disputeRaised) ||
        currentStage == AssignmentStage.disputeRaised;

    // Normal progression stages (1 to 8)
    const normalStages = [
      AssignmentStage.requestCreated,
      AssignmentStage.accepted,
      AssignmentStage.ticketIssued,
      AssignmentStage.workerArrived,
      AssignmentStage.verificationCompleted,
      AssignmentStage.jobInProgress,
      AssignmentStage.completed,
      AssignmentStage.paymentReleased,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderGreen.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Live Pulsing Dot
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n?.timelineTitle ?? 'Assignment Lifecycle Timeline',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.paleMint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt, size: 12, color: AppColors.headerGreenDark),
                      const SizedBox(width: 2),
                      Text(
                        l10n?.timelineLiveDot ?? 'LIVE',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.headerGreenDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // If a dispute was raised, show prominent alert banner at top of timeline
          if (hasDispute) ...[
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2), // Red-50
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF4444)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.timelineDisputeActive ?? 'Dispute Raised Under Mediation',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n?.timelineDisputeSub ?? 'Resolution team is reviewing job evidence and logs.',
                          style: const TextStyle(fontSize: 11, color: Color(0xFFB91C1C)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Vertical Milestones
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                for (int i = 0; i < normalStages.length; i++)
                  _buildMilestoneRow(
                    stage: normalStages[i],
                    currentStage: currentStage,
                    event: stageEvents[normalStages[i]],
                    isLast: i == normalStages.length - 1,
                    l10n: l10n,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneRow({
    required AssignmentStage stage,
    required AssignmentStage currentStage,
    required AssignmentEventItem? event,
    required bool isLast,
    required AppLocalizations? l10n,
  }) {
    final bool isCompleted = event != null || stage.step < currentStage.step;
    final bool isCurrent = stage == currentStage;

    Color nodeBg;
    Color nodeBorder;
    Widget nodeIcon;

    if (isCompleted) {
      nodeBg = const Color(0xFF0D6548);
      nodeBorder = const Color(0xFF0D6548);
      nodeIcon = const Icon(Icons.check, size: 14, color: Colors.white);
    } else if (isCurrent) {
      nodeBg = const Color(0xFFFFF7ED); // Orange-50
      nodeBorder = AppColors.warningOrange;
      nodeIcon = Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.warningOrange,
          shape: BoxShape.circle,
        ),
      );
    } else {
      nodeBg = Colors.white;
      nodeBorder = Colors.grey.shade300;
      nodeIcon = Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          shape: BoxShape.circle,
        ),
      );
    }

    final localizedTitle = _getStageTitle(stage, l10n);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left track: Node + Vertical line
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: nodeBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: nodeBorder, width: 2),
                ),
                child: Center(child: nodeIcon),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? const Color(0xFF0D6548) : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Right content: Title, timestamp, meta
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        localizedTitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.bold : (isCompleted ? FontWeight.w600 : FontWeight.normal),
                          color: isCurrent
                              ? AppColors.warningOrange
                              : (isCompleted ? AppColors.textDark : Colors.grey.shade500),
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n?.timelineCurrentBadge ?? 'Current',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (event != null)
                        Text(
                          DateFormat('hh:mm a').format(event.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                  if (isCurrent) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.arrow_right_alt_rounded, size: 14, color: Colors.orange.shade800),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _getWhoMustActNext(stage, isProvider),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (event != null && event.meta.isNotEmpty && event.meta['note'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      event.meta['note'].toString(),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getWhoMustActNext(AssignmentStage stage, bool isProvider) {
    switch (stage) {
      case AssignmentStage.requestCreated:
        return isProvider ? 'Waiting for worker acceptance' : 'Action needed: Accept job offer';
      case AssignmentStage.accepted:
      case AssignmentStage.ticketIssued:
        return isProvider
            ? 'Action needed: Scan worker QR ticket on site arrival'
            : 'Action needed: Present QR ticket upon arrival';
      case AssignmentStage.workerArrived:
        return isProvider
            ? 'Waiting for worker live selfie & GPS verification'
            : 'Action needed: Complete Step 2 (Live Selfie & GPS)';
      case AssignmentStage.verificationCompleted:
        return 'Both: Verification complete, starting work timer';
      case AssignmentStage.jobInProgress:
        return isProvider
            ? 'Work in progress • Awaiting job completion'
            : 'Action needed: Complete job & submit evidence';
      case AssignmentStage.completed:
        return isProvider
            ? 'Action needed: Confirm & release escrow payment'
            : 'Waiting for employer payment release';
      case AssignmentStage.paymentReleased:
        return 'Job completed and payment settled';
      case AssignmentStage.disputeRaised:
        return 'Under mediation review';
    }
  }

  String _getStageTitle(AssignmentStage stage, AppLocalizations? l10n) {
    switch (stage) {
      case AssignmentStage.requestCreated:
        return l10n?.stageRequestCreated ?? 'Request Created';
      case AssignmentStage.accepted:
        return l10n?.stageAccepted ?? 'Accepted';
      case AssignmentStage.ticketIssued:
        return l10n?.stageTicketIssued ?? 'Ticket Issued';
      case AssignmentStage.workerArrived:
        return l10n?.stageWorkerArrived ?? 'Worker Arrived';
      case AssignmentStage.verificationCompleted:
        return l10n?.stageVerificationCompleted ?? 'Verification Completed';
      case AssignmentStage.jobInProgress:
        return l10n?.stageJobInProgress ?? 'Job In Progress';
      case AssignmentStage.completed:
        return l10n?.stageCompleted ?? 'Completed';
      case AssignmentStage.paymentReleased:
        return l10n?.stagePaymentReleased ?? 'Payment Released';
      case AssignmentStage.disputeRaised:
        return l10n?.stageDisputeRaised ?? 'Dispute Raised';
    }
  }
}
