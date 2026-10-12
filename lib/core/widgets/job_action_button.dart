import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/seeker/domain/job_application_status.dart';
import 'package:udyogasethu/features/seeker/presentation/my_applications_controller.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class JobActionButton extends ConsumerStatefulWidget {
  final String jobId;
  final String jobTitle;
  final bool isCompact;
  final bool showWithdrawOption;
  final VoidCallback? onApplyCustom;
  final bool isEligible;
  final String? ineligibleReason;
  final String? fallbackAssignmentId;
  final bool isOffline;
  final String? customApplyLabel;
  final bool? isApplied;

  const JobActionButton({
    super.key,
    required this.jobId,
    required this.jobTitle,
    this.isCompact = false,
    this.showWithdrawOption = false,
    this.onApplyCustom,
    this.isEligible = true,
    this.ineligibleReason,
    this.fallbackAssignmentId,
    this.isOffline = false,
    this.customApplyLabel,
    this.isApplied,
  });

  @override
  ConsumerState<JobActionButton> createState() => _JobActionButtonState();
}

class _JobActionButtonState extends ConsumerState<JobActionButton> {
  bool _isSubmitting = false;

  Future<void> _handleApply() async {
    if (widget.onApplyCustom != null) {
      widget.onApplyCustom!();
      return;
    }

    setState(() => _isSubmitting = true);
    final l10n = AppLocalizations.of(context);
    final result = await ref.read(myApplicationsProvider.notifier).applyToJob(
          jobId: widget.jobId,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n != null ? '${l10n.applied} - ${widget.jobTitle}' : 'Applied to ${widget.jobTitle}! ✓',
          ),
          backgroundColor: const Color(0xFF0D6548),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to apply to job'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleWithdraw() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.remove_circle_outline, color: Colors.amber),
            SizedBox(width: 8),
            Text('Withdraw Application', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to withdraw your application for "${widget.jobTitle}"?',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isSubmitting = true);
      final result = await ref.read(myApplicationsProvider.notifier).withdrawApplication(widget.jobId);
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application withdrawn successfully.'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Failed to withdraw application'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Select ONLY this job's status to prevent unnecessary card re-renders
    final status = ref.watch(
      myApplicationsProvider.select(
        (map) => map[widget.jobId] ?? WorkerJobStatus(jobId: widget.jobId),
      ),
    );

    final l10n = AppLocalizations.of(context);
    final effectiveAssignmentId = status.assignmentId ?? widget.fallbackAssignmentId;

    if (_isSubmitting) {
      return SizedBox(
        height: widget.isCompact ? 28 : 44,
        width: widget.isCompact ? 60 : null,
        child: const Center(
          child: SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.headerGreenDark),
          ),
        ),
      );
    }

    // 1. INELIGIBLE CHECK (if not already applied/hired)
    if (!widget.isEligible && (status.isNone || status.isWithdrawn)) {
      final reason = widget.ineligibleReason ?? 'Not eligible';
      if (widget.isCompact) {
        return Tooltip(
          message: reason,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 11, color: Colors.grey.shade600),
                const SizedBox(width: 3),
                Text(
                  'Not eligible',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      }
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade200,
          foregroundColor: Colors.grey.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          elevation: 0,
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot apply: $reason'), backgroundColor: Colors.amber.shade800),
          );
        },
        icon: const Icon(Icons.info_outline, size: 18),
        label: Text('Not Eligible: $reason', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      );
    }

    // 2. HIRED / ACCEPTED
    if (status.isHired) {
      if (widget.isCompact) {
        return InkWell(
          onTap: () {
            if (effectiveAssignmentId != null && effectiveAssignmentId.isNotEmpty) {
              context.push('/jobs/active/$effectiveAssignmentId');
            } else {
              context.push(AppRoutes.seekerJobs);
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF10B981), width: 0.8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF0D6548)),
                SizedBox(width: 4),
                Text(
                  'Accepted ✓',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D6548)),
                ),
              ],
            ),
          ),
        );
      }
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D6548),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 2,
        ),
        onPressed: () {
          if (effectiveAssignmentId != null && effectiveAssignmentId.isNotEmpty) {
            context.push('/jobs/active/$effectiveAssignmentId');
          } else {
            context.push(AppRoutes.seekerJobs);
          }
        },
        icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
        label: const Text('View Active Job Ticket →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      );
    }

    // 3. SHORTLISTED
    if (status.isShortlisted) {
      if (widget.isCompact) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E8FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFC084FC), width: 0.8),
          ),
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Shortlisted ★',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7E22CE)),
            ),
          ),
        );
      }
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7E22CE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: null,
              icon: const Icon(Icons.star_rounded, size: 18),
              label: const Text('Shortlisted ★ (Awaiting Employer)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          if (widget.showWithdrawOption) ...[
            const SizedBox(width: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              onPressed: _handleWithdraw,
              child: const Text('Withdraw', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      );
    }

    // 4. REJECTED
    if (status.isRejected) {
      if (widget.isCompact) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Closed',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
          ),
        );
      }
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade300,
          foregroundColor: Colors.grey.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
        ),
        onPressed: null,
        child: const Text('Application Closed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      );
    }

    // 5. APPLIED
    final effectiveIsApplied = widget.isApplied == true || status.isApplied;
    if (effectiveIsApplied) {
      if (widget.isCompact) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_rounded, size: 12, color: Color(0xFF475569)),
                const SizedBox(width: 3),
                Text(
                  l10n?.applied ?? 'Applied ✓',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE2E8F0),
                foregroundColor: const Color(0xFF334155),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              onPressed: null,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFF334155)),
              label: Text(
                l10n?.applied ?? 'Applied ✓',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          if (widget.showWithdrawOption) ...[
            const SizedBox(width: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              onPressed: _handleWithdraw,
              child: const Text('Withdraw', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      );
    }

    // 6. DEFAULT / NOT APPLIED (or WITHDRAWN)
    if (widget.isOffline) {
      if (widget.isCompact) {
        return SizedBox(
          height: 32,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade400,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: widget.onApplyCustom ?? _handleApply,
            child: const Text('Offline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        );
      }
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade400,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
        ),
        onPressed: widget.onApplyCustom ?? _handleApply,
        icon: const Icon(Icons.cloud_off_rounded, size: 18),
        label: const Text(
          'Offline - Reconnect to Apply',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      );
    }

    if (widget.isCompact) {
      final label = widget.customApplyLabel ?? (l10n?.applyNow ?? 'Apply Now');
      return SizedBox(
        height: 32,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D6548),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            elevation: 0,
          ),
          onPressed: _handleApply,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    final fullLabel = widget.customApplyLabel != null
        ? widget.customApplyLabel!
        : (l10n?.applyNow != null ? '${l10n!.applyNow} (Quick & Easy ✨)' : 'Apply Now (Quick & Easy ✨)');
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0D6548),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 2,
      ),
      onPressed: _handleApply,
      icon: const Icon(Icons.send_rounded, size: 18),
      label: Text(
        fullLabel,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}
