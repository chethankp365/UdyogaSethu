import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/job_execution/data/job_execution_repository.dart';
import 'package:udyogasethu/features/job_execution/domain/active_job_detail.dart';
import 'package:udyogasethu/features/job_execution/domain/replacement_candidate.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

/// Dark-panel modal sheet displayed to the Job Provider when an assigned
/// worker has not arrived past the scheduled arrival & grace window.
class WorkerNotArrivedSheet extends ConsumerStatefulWidget {
  final ActiveJobDetail jobDetail;
  final VoidCallback onActionCompleted;

  const WorkerNotArrivedSheet({
    super.key,
    required this.jobDetail,
    required this.onActionCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    required ActiveJobDetail jobDetail,
    required VoidCallback onActionCompleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WorkerNotArrivedSheet(
        jobDetail: jobDetail,
        onActionCompleted: onActionCompleted,
      ),
    );
  }

  @override
  ConsumerState<WorkerNotArrivedSheet> createState() =>
      _WorkerNotArrivedSheetState();
}

class _WorkerNotArrivedSheetState extends ConsumerState<WorkerNotArrivedSheet> {
  bool _isExtendingWait = false;
  bool _isFindingReplacements = false;
  bool _isRequestingReplacement = false;
  String? _requestingWorkerId;
  List<ReplacementCandidate>? _candidates;
  String? _errorMessage;

  Future<void> _handleWait10Minutes() async {
    setState(() {
      _isExtendingWait = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(jobExecutionRepositoryProvider);
      await repo.extendWait(widget.jobDetail.assignmentId, minutes: 10);

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryEmerald,
            content: Text(
              l10n?.gracePeriodExtendedMsg ??
                  'Added +10 minutes wait grace. Timer paused.',
            ),
          ),
        );
        widget.onActionCompleted();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isExtendingWait = false;
        });
      }
    }
  }

  void _handleCallWorker() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFF59E0B),
        content: Text(
          l10n?.maskedCallDemoMsg ??
              'Dialing worker... (Demo mode: Masked call arrives in P7.2)',
        ),
      ),
    );
  }

  Future<void> _handleFindReplacements() async {
    setState(() {
      _isFindingReplacements = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(jobExecutionRepositoryProvider);
      final list = await repo
          .findReplacementCandidates(widget.jobDetail.assignmentId);

      if (mounted) {
        setState(() {
          _candidates = list;
          _isFindingReplacements = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isFindingReplacements = false;
        });
      }
    }
  }

  Future<void> _handleConfirmReplacement(ReplacementCandidate candidate) async {
    setState(() {
      _isRequestingReplacement = true;
      _requestingWorkerId = candidate.workerId;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(jobExecutionRepositoryProvider);
      await repo.confirmReplacement(
        assignmentId: widget.jobDetail.assignmentId,
        replacementWorkerId: candidate.workerId,
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryEmerald,
            content: Text(
              l10n?.replacementBookedMsg(candidate.fullName) ??
                  'Replacement booked with ${candidate.fullName}! Original marked as no-show.',
            ),
          ),
        );
        widget.onActionCompleted();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isRequestingReplacement = false;
          _requestingWorkerId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final minutesLate = widget.jobDetail.minutesPastScheduledArrival;
    final workerName = widget.jobDetail.workerName;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0B132B), // Deep Slate Navy Dark Panel
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Urgent Alert Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFEF4444),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.arrivalGraceExpiredAlert ??
                            '⚠️ ARRIVAL GRACE PERIOD EXPIRED',
                        style: const TextStyle(
                          color: Color(0xFFF87171),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n?.workerHasNotArrivedTitle ?? 'Worker Has Not Arrived',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                l10n?.workerHasNotArrivedSubtitle(
                      workerName,
                      minutesLate > 0 ? minutesLate : 15,
                      widget.jobDetail.jobTitle,
                    ) ??
                    '$workerName is ${minutesLate > 0 ? minutesLate : 15} minutes past the scheduled arrival time for ${widget.jobDetail.jobTitle}.',
                style: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action 1: Wait 10 Minutes
            ElevatedButton.icon(
              onPressed: _isExtendingWait ? null : _handleWait10Minutes,
              icon: _isExtendingWait
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.more_time_rounded, size: 20),
              label: Text(
                l10n?.wait10MinutesAction ?? 'Wait 10 Minutes',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF334155),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Action 2: Call Worker Directly (placeholder)
            OutlinedButton.icon(
              onPressed: _handleCallWorker,
              icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
              label: Text(
                l10n?.callWorkerDirectlyAction ?? '📞 Call Worker Directly',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF38BDF8),
                side: const BorderSide(color: Color(0xFF38BDF8)),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Action 3: Find Smart Replacement Worker
            ElevatedButton.icon(
              onPressed:
                  _isFindingReplacements ? null : _handleFindReplacements,
              icon: _isFindingReplacements
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.bolt_rounded, size: 22),
              label: Text(
                l10n?.findSmartReplacementAction ??
                    '⚡ Find Smart Replacement Worker',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentOrange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            // Replacement Candidates List Section
            if (_candidates != null) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(
                    Icons.people_alt_rounded,
                    color: Color(0xFF38BDF8),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n?.rankedReplacementsTitle ?? 'RANKED NEARBY WORKERS',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_candidates!.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      l10n?.noReplacementsFoundMsg ??
                          'No nearby replacement candidates available right now.',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _candidates!.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final candidate = _candidates![index];
                    final isBusy = _isRequestingReplacement &&
                        _requestingWorkerId == candidate.workerId;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: candidate.isVerified
                              ? const Color(0xFF10B981).withValues(alpha: 0.4)
                              : Colors.white12,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFF0F172A),
                                backgroundImage: candidate.avatarUrl != null
                                    ? NetworkImage(candidate.avatarUrl!)
                                    : null,
                                child: candidate.avatarUrl == null
                                    ? Text(
                                        candidate.fullName.isNotEmpty
                                            ? candidate.fullName[0].toUpperCase()
                                            : 'W',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            candidate.fullName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (candidate.isVerified) ...[
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.verified_rounded,
                                            color: Color(0xFF10B981),
                                            size: 16,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Color(0xFFF59E0B),
                                          size: 15,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${candidate.rating}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Icon(
                                          Icons.near_me_rounded,
                                          color: Color(0xFF94A3B8),
                                          size: 13,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          candidate.distanceKmDisplay,
                                          style: const TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (candidate.skills.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: candidate.skills.take(3).map((s) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    s,
                                    style: const TextStyle(
                                      color: Color(0xFFE2E8F0),
                                      fontSize: 11,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                          const SizedBox(height: 10),
                          // 1-Tap Request Button
                          ElevatedButton.icon(
                            onPressed: _isRequestingReplacement
                                ? null
                                : () => _handleConfirmReplacement(candidate),
                            icon: isBusy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.flash_on_rounded, size: 18),
                            label: Text(
                              l10n?.requestReplacementOneTap ??
                                  'Request Replacement (1-Tap)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryEmerald,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(42),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],

            const SizedBox(height: 16),
            Center(
              child: Text(
                l10n?.smartNoShowTrustNote ??
                    'Zero-penalty refund on no-shows. Replacement workers are background-screened.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
