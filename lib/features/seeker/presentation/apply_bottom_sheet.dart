import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/seeker/domain/job_detail.dart';
import 'package:udyogasethu/features/seeker/domain/job_eligibility.dart';
import 'package:udyogasethu/features/seeker/presentation/job_detail_controller.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_jobs_controller.dart';

class ApplyBottomSheet extends ConsumerStatefulWidget {
  final JobDetail job;

  const ApplyBottomSheet({super.key, required this.job});

  static Future<void> show(BuildContext context, JobDetail job) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ApplyBottomSheet(job: job),
    );
  }

  @override
  ConsumerState<ApplyBottomSheet> createState() => _ApplyBottomSheetState();
}

class _ApplyBottomSheetState extends ConsumerState<ApplyBottomSheet> {
  final _messageController = TextEditingController();
  bool _isSubmitted = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  JobEligibility _mergeClientRules(JobEligibility serverEligibility) {
    String? currentUserId;
    try {
      currentUserId = Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {}

    final bool isOwnJob = serverEligibility.isOwnJob ||
        (currentUserId != null && widget.job.providerId.isNotEmpty && widget.job.providerId == currentUserId);
    final bool isPastStart = serverEligibility.isPastStart ||
        (widget.job.status != 'open' && widget.job.startAt.isBefore(DateTime.now()));
    final bool isSlotsFilled = serverEligibility.isSlotsFilled || (widget.job.slotsFilled >= widget.job.slotsTotal);

    final bool isEligible = serverEligibility.isEligible &&
        !isOwnJob &&
        !isPastStart &&
        !isSlotsFilled &&
        !serverEligibility.studentGated &&
        !serverEligibility.alreadyApplied &&
        !serverEligibility.scheduleOverlap &&
        (!serverEligibility.licenceNeeded || serverEligibility.hasLicence) &&
        (!serverEligibility.verifiedNeeded || serverEligibility.isVerified);

    final reasonCode = serverEligibility.reasonCode ??
        (isOwnJob
            ? 'OWN_JOB'
            : isPastStart
                ? 'EXPIRED'
                : isSlotsFilled
                    ? 'SLOTS_FILLED'
                    : null);

    return JobEligibility(
      isEligible: isEligible,
      reasonCode: reasonCode,
      licenceNeeded: serverEligibility.licenceNeeded,
      hasLicence: serverEligibility.hasLicence,
      verifiedNeeded: serverEligibility.verifiedNeeded,
      isVerified: serverEligibility.isVerified,
      studentGated: serverEligibility.studentGated,
      scheduleOverlap: serverEligibility.scheduleOverlap,
      overlapJobTitle: serverEligibility.overlapJobTitle,
      alreadyApplied: serverEligibility.alreadyApplied,
      isOwnJob: isOwnJob,
      isPastStart: isPastStart,
      isSlotsFilled: isSlotsFilled,
      reasons: serverEligibility.reasons,
    );
  }

  String _getIneligibleReason(JobEligibility eligibility) {
    if (eligibility.alreadyApplied) return 'You already applied';
    if (eligibility.isOwnJob) return 'Cannot apply to your own job';
    if (eligibility.isPastStart) return 'Start time has passed';
    if (eligibility.isSlotsFilled) return 'All slots are filled';
    if (eligibility.scheduleOverlap) {
      return eligibility.overlapJobTitle != null && eligibility.overlapJobTitle!.isNotEmpty
          ? 'Schedule clash with "${eligibility.overlapJobTitle}"'
          : 'Schedule clash with another job';
    }
    if (eligibility.studentGated) return 'Audience mismatch for this job';
    if (eligibility.licenceNeeded && !eligibility.hasLicence) return 'Driving licence required';
    if (eligibility.verifiedNeeded && !eligibility.isVerified) return 'Verified badge required';
    if (eligibility.reasons.isNotEmpty) return eligibility.reasons.first;
    return 'Ineligible to Apply';
  }

  String _parseApplyErrorMessage(Object? error) {
    final str = error?.toString() ?? '';
    if (str.contains('OWN_JOB')) return 'Cannot apply to your own job';
    if (str.contains('EXPIRED')) return 'Start time has passed';
    if (str.contains('SLOTS_FILLED')) return 'All slots are filled';
    if (str.contains('AUDIENCE_MISMATCH')) return 'Audience mismatch for this job';
    if (str.contains('LICENCE_REQUIRED')) return 'Driving licence required';
    if (str.contains('VERIFIED_REQUIRED')) return 'Verified badge required';
    if (str.contains('SCHEDULE_CLASH')) return 'Schedule clash with another assignment';
    if (str.contains('ALREADY_APPLIED')) return 'You already applied';
    return str.isNotEmpty ? str : 'Failed to apply';
  }

  @override
  Widget build(BuildContext context) {
    final eligibilityAsync = ref.watch(jobEligibilityFutureProvider(widget.job.id));
    final applyState = ref.watch(jobApplyControllerProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isSubmitted
            ? _buildSuccessView(context)
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
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

                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Apply for ${widget.job.title}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.job.providerName} • ₹${widget.job.wageRupees}/day',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Eligibility Checklist Section
                    const Text(
                      'ELIGIBILITY & COMPATIBILITY CHECK',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),

                    eligibilityAsync.when(
                      data: (rawEligibility) {
                        final eligibility = _mergeClientRules(rawEligibility);
                        return _buildChecklist(eligibility);
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.headerGreenDark),
                        ),
                      ),
                      error: (e, _) => Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Could not verify eligibility online. You can still submit.',
                                style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Short Message Input
                    const Text(
                      'SHORT MESSAGE (OPTIONAL)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageController,
                      maxLines: 2,
                      maxLength: 140,
                      decoration: InputDecoration(
                        hintText: 'e.g. I have 2 years of plumbing experience and can arrive by 8 AM.',
                        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.headerGreenDark, width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Apply Button & Ineligibility Reason
                    eligibilityAsync.when(
                      data: (rawEligibility) {
                        final eligibility = _mergeClientRules(rawEligibility);
                        final blockReason = _getIneligibleReason(eligibility);
                        final canApply = eligibility.isEligible && !eligibility.alreadyApplied;

                        if (kDebugMode) {
                          debugPrint('================= [ApplyBottomSheet Debug] =================');
                          debugPrint('Job ID: ${widget.job.id} | Title: "${widget.job.title}"');
                          debugPrint('Provider ID: ${widget.job.providerId}');
                          debugPrint('Start At: ${widget.job.startAt} (Passed: ${widget.job.startAt.isBefore(DateTime.now())})');
                          debugPrint('Slots: ${widget.job.slotsFilled}/${widget.job.slotsTotal} (Filled: ${widget.job.slotsFilled >= widget.job.slotsTotal})');
                          debugPrint('Rule Evaluations:');
                          debugPrint('  - Server isEligible: ${rawEligibility.isEligible} (code: ${rawEligibility.reasonCode})');
                          debugPrint('  - Licence: needed=${eligibility.licenceNeeded}, has=${eligibility.hasLicence} => ok=${!eligibility.licenceNeeded || eligibility.hasLicence}');
                          debugPrint('  - Verified: needed=${eligibility.verifiedNeeded}, has=${eligibility.isVerified} => ok=${!eligibility.verifiedNeeded || eligibility.isVerified}');
                          debugPrint('  - Category/Audience: studentGated=${eligibility.studentGated} => ok=${!eligibility.studentGated}');
                          debugPrint('  - Schedule clash: overlap=${eligibility.scheduleOverlap} (clash: ${eligibility.overlapJobTitle}) => ok=${!eligibility.scheduleOverlap}');
                          debugPrint('  - Own job: ${eligibility.isOwnJob} => ok=${!eligibility.isOwnJob}');
                          debugPrint('  - Past start: ${eligibility.isPastStart} => ok=${!eligibility.isPastStart}');
                          debugPrint('  - Slots filled: ${eligibility.isSlotsFilled} => ok=${!eligibility.isSlotsFilled}');
                          debugPrint('  - Already applied: ${eligibility.alreadyApplied} => ok=${!eligibility.alreadyApplied}');
                          debugPrint('Server reasons list: ${rawEligibility.reasons}');
                          debugPrint('Final decision: canApply=$canApply | Resolved Reason: "$blockReason"');
                          debugPrint('===========================================================');
                        }

                        if (eligibility.alreadyApplied) {
                          return SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
                              label: const Text('Already Applied', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          );
                        }

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!canApply) ...[
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, color: Colors.red.shade700, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        blockReason,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: canApply ? AppColors.headerGreenDark : Colors.grey.shade400,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: canApply ? 2 : 0,
                                ),
                                onPressed: canApply && !applyState.isLoading
                                    ? () async {
                                        final ok = await ref.read(jobApplyControllerProvider.notifier).apply(
                                              jobId: widget.job.id,
                                              message: _messageController.text.trim().isNotEmpty
                                                  ? _messageController.text.trim()
                                                  : null,
                                            );
                                        if (ok) {
                                          ref.read(seekerJobsControllerProvider.notifier).loadJobs();
                                          setState(() => _isSubmitted = true);
                                        } else {
                                          final lastErr = ref.read(jobApplyControllerProvider).error;
                                          final err = _parseApplyErrorMessage(lastErr);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(err),
                                                backgroundColor: Colors.red.shade700,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    : null,
                                child: applyState.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(
                                        canApply ? 'Confirm Application ✈️' : blockReason,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: null,
                          child: Text('Verifying Eligibility...'),
                        ),
                      ),
                      error: (_, _) => SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.headerGreenDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: !applyState.isLoading
                              ? () async {
                                  final ok = await ref.read(jobApplyControllerProvider.notifier).apply(
                                        jobId: widget.job.id,
                                        message: _messageController.text.trim().isNotEmpty
                                            ? _messageController.text.trim()
                                            : null,
                                      );
                                  if (ok) {
                                    ref.read(seekerJobsControllerProvider.notifier).loadJobs();
                                    setState(() => _isSubmitted = true);
                                  }
                                }
                              : null,
                          child: const Text('Submit Application ✈️'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildChecklist(JobEligibility eligibility) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // 1. Driving Licence Check
          _buildCheckRow(
            label: 'Driving Licence',
            subtitle: widget.job.requirements['licence_required'] == true ? 'Required for delivery/driver role' : 'Not required',
            isSatisfied: !eligibility.licenceNeeded || eligibility.hasLicence,
            statusText: eligibility.licenceNeeded
                ? (eligibility.hasLicence ? 'Verified ✓' : 'Missing Licence ✖')
                : 'Not Needed',
          ),
          const Divider(height: 16),

          // 2. Verified Worker Check
          _buildCheckRow(
            label: 'UdyogaSethu Verified',
            subtitle: widget.job.requirements['verified_only'] == true ? 'Verified worker badge mandatory' : 'Open to all registered workers',
            isSatisfied: !eligibility.verifiedNeeded || eligibility.isVerified,
            statusText: eligibility.verifiedNeeded
                ? (eligibility.isVerified ? 'Verified ✓' : 'Unverified ✖')
                : 'Eligible',
          ),
          const Divider(height: 16),

          // 3. Category & Audience Check
          _buildCheckRow(
            label: 'Category Alignment',
            subtitle: 'Target audience criteria',
            isSatisfied: !eligibility.studentGated,
            statusText: eligibility.studentGated ? 'Category Mismatch ✖' : 'Matched ✓',
          ),
          const Divider(height: 16),

          // 4. Schedule Overlap Check
          _buildCheckRow(
            label: 'Schedule Availability',
            subtitle: eligibility.scheduleOverlap && eligibility.overlapJobTitle != null
                ? 'Conflicts with "${eligibility.overlapJobTitle}"'
                : 'No conflicting shifts on your calendar',
            isSatisfied: !eligibility.scheduleOverlap,
            statusText: eligibility.scheduleOverlap ? 'Overlap Conflict ✖' : 'Available ✓',
          ),
          if (eligibility.isOwnJob) ...[
            const Divider(height: 16),
            _buildCheckRow(
              label: 'Job Ownership',
              subtitle: 'Cannot apply to a job posted by your account',
              isSatisfied: false,
              statusText: 'Own Job ✖',
            ),
          ],
          if (eligibility.isPastStart) ...[
            const Divider(height: 16),
            _buildCheckRow(
              label: 'Job Schedule Timing',
              subtitle: 'Scheduled start time has already passed',
              isSatisfied: false,
              statusText: 'Expired ✖',
            ),
          ],
          if (eligibility.isSlotsFilled) ...[
            const Divider(height: 16),
            _buildCheckRow(
              label: 'Slot Availability',
              subtitle: 'All positions for this job are filled',
              isSatisfied: false,
              statusText: 'Slots Full ✖',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckRow({
    required String label,
    required String subtitle,
    required bool isSatisfied,
    required String statusText,
  }) {
    return Row(
      children: [
        Icon(
          isSatisfied ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: isSatisfied ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isSatisfied ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSatisfied ? Colors.green.shade200 : Colors.red.shade200),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSatisfied ? Colors.green.shade800 : Colors.red.shade800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.paleMint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.headerGreenDark,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Application Submitted! 🎉',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your application for "${widget.job.title}" has been sent to ${widget.job.providerName}. You can track it under the Jobs tab.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.headerGreenDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(context);
                context.go(AppRoutes.seekerJobs);
              },
              child: const Text('View in Jobs Tab →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Job Detail', style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}
