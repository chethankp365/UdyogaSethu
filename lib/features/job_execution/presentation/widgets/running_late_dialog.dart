import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/job_execution/data/job_execution_repository.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

/// Modal dialog for worker to report running late with expected ETA delay.
/// Pauses the no-show grace period timer once.
class RunningLateDialog extends ConsumerStatefulWidget {
  final String assignmentId;
  final VoidCallback onReported;

  const RunningLateDialog({
    super.key,
    required this.assignmentId,
    required this.onReported,
  });

  static Future<void> show(
    BuildContext context, {
    required String assignmentId,
    required VoidCallback onReported,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => RunningLateDialog(
        assignmentId: assignmentId,
        onReported: onReported,
      ),
    );
  }

  @override
  ConsumerState<RunningLateDialog> createState() => _RunningLateDialogState();
}

class _RunningLateDialogState extends ConsumerState<RunningLateDialog> {
  int _selectedMinutes = 15;
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<int> _etaOptions = [10, 15, 30, 45];

  Future<void> _submitRunningLate() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(jobExecutionRepositoryProvider);
      await repo.reportRunningLate(
        widget.assignmentId,
        etaMinutes: _selectedMinutes,
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryEmerald,
            content: Text(
              l10n?.runningLateSuccessMsg(_selectedMinutes) ??
                  'Reported +$_selectedMinutes minutes ETA. Employer notified.',
            ),
          ),
        );
        widget.onReported();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.access_time_filled_rounded,
                    color: Color(0xFFD97706),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n?.runningLateDialogTitle ?? 'Running Late?',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n?.runningLateDialogSubtitle ??
                  'Select your expected arrival delay. This notifies your employer and pauses the arrival grace timer once.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Delay Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _etaOptions.map((mins) {
                final isSelected = _selectedMinutes == mins;
                return ChoiceChip(
                  label: Text('+$mins min'),
                  selected: isSelected,
                  selectedColor: AppColors.primaryEmerald,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primaryEmerald
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedMinutes = mins);
                    }
                  },
                );
              }).toList(),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],

            const SizedBox(height: 22),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    l10n?.cancel ?? 'Cancel',
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRunningLate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.headerGreenDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n?.sendEtaAction ?? 'Send ETA'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
