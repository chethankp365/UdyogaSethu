import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/trust/data/trust_repository.dart';
import 'package:udyogasethu/features/trust/domain/dispute.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

/// Modal dialog allowing a user to file a structured dispute against an assignment.
/// Freezes escrow release and notifies both parties and admin team.
class RaiseDisputeDialog extends ConsumerStatefulWidget {
  final String assignmentId;
  final String jobTitle;
  final String counterpartyName;
  final VoidCallback? onDisputeRaised;

  const RaiseDisputeDialog({
    super.key,
    required this.assignmentId,
    required this.jobTitle,
    required this.counterpartyName,
    this.onDisputeRaised,
  });

  static Future<void> show(
    BuildContext context, {
    required String assignmentId,
    required String jobTitle,
    required String counterpartyName,
    VoidCallback? onDisputeRaised,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: RaiseDisputeDialog(
          assignmentId: assignmentId,
          jobTitle: jobTitle,
          counterpartyName: counterpartyName,
          onDisputeRaised: onDisputeRaised,
        ),
      ),
    );
  }

  @override
  ConsumerState<RaiseDisputeDialog> createState() => _RaiseDisputeDialogState();
}

class _RaiseDisputeDialogState extends ConsumerState<RaiseDisputeDialog> {
  final ImagePicker _picker = ImagePicker();
  DisputeIssueType _selectedIssue = DisputeIssueType.poorQuality;
  final TextEditingController _detailsController = TextEditingController();
  final List<File> _evidencePhotos = [];
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() => _evidencePhotos.add(File(picked.path)));
      }
    } catch (_) {}
  }

  Future<void> _submitDispute() async {
    final details = _detailsController.text.trim();
    if (details.isEmpty) {
      setState(() => _errorMessage = 'Please describe the issue in detail.');
      return;
    }

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(trustRepositoryProvider);

      // 1. Upload evidence photos if any
      final List<String> uploadedPaths = [];
      for (int i = 0; i < _evidencePhotos.length; i++) {
        final bytes = await _evidencePhotos[i].readAsBytes();
        final path = await repo.uploadDisputeEvidence(
          assignmentId: widget.assignmentId,
          fileBytes: bytes,
          fileName: 'dispute_photo_$i.jpg',
        );
        uploadedPaths.add(path);
      }

      // 2. Create dispute ticket
      await repo.createAssignmentDispute(
        assignmentId: widget.assignmentId,
        issueType: _selectedIssue,
        details: details,
        evidencePaths: uploadedPaths,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFDC2626),
            content: Text('Dispute reported. Escrow payment is frozen pending resolution.'),
            duration: Duration(seconds: 4),
          ),
        );
        widget.onDisputeRaised?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
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

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.reportDisputeTitle ?? 'Report Job Dispute',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
                      ),
                      Text(
                        '${widget.jobTitle} • ${widget.counterpartyName}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Warning Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock_rounded, color: Color(0xFFB45309), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n?.disputeFreezeNotice ??
                          'Filing a dispute pauses automatic escrow release and assigns the case to UdyogaSethu Trust & Safety for review.',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Issue Type Selection
            Text(
              l10n?.disputeIssueTypeLabel ?? 'Select Issue Type',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DisputeIssueType.values.map((type) {
                final isSelected = _selectedIssue == type;
                return ChoiceChip(
                  label: Text(_getIssueLabel(type, l10n)),
                  selected: isSelected,
                  selectedColor: Colors.red.shade100,
                  backgroundColor: Colors.grey.shade100,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFFDC2626) : AppColors.textDark,
                  ),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFFDC2626) : Colors.grey.shade300,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedIssue = type);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            // Details input
            Text(
              l10n?.disputeDetailsLabel ?? 'Issue Details & Timeline',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: l10n?.disputeDetailsHint ??
                    'Please explain what happened clearly, including timestamps and any verbal agreements...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Evidence Photos Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.disputeEvidenceLabel ?? 'Evidence Photos (Optional)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt_rounded, color: AppColors.headerGreenDark, size: 20),
                      tooltip: 'Take Photo',
                      onPressed: () => _pickPhoto(ImageSource.camera),
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo_library_rounded, color: AppColors.headerGreenDark, size: 20),
                      tooltip: 'Choose from Gallery',
                      onPressed: () => _pickPhoto(ImageSource.gallery),
                    ),
                  ],
                ),
              ],
            ),

            if (_evidencePhotos.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _evidencePhotos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (ctx, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _evidencePhotos[index],
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: InkWell(
                            onTap: () => setState(() => _evidencePhotos.removeAt(index)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],

            if (_errorMessage != null) ...[
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade900, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.report_problem_rounded, size: 20),
                label: Text(
                  l10n?.submitDisputeBtn ?? 'Raise Formal Dispute',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: _isSubmitting ? null : _submitDispute,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getIssueLabel(DisputeIssueType type, AppLocalizations? l10n) {
    switch (type) {
      case DisputeIssueType.noShow:
        return l10n?.disputeTypeNoShow ?? 'No-Show';
      case DisputeIssueType.incompleteWork:
        return l10n?.disputeTypeIncompleteWork ?? 'Incomplete Work';
      case DisputeIssueType.poorQuality:
        return l10n?.disputeTypePoorQuality ?? 'Poor Quality';
      case DisputeIssueType.wrongProduct:
        return l10n?.disputeTypeWrongProduct ?? 'Wrong Product';
      case DisputeIssueType.paymentIssue:
        return l10n?.disputeTypePaymentIssue ?? 'Payment Issue';
      case DisputeIssueType.unsafeConduct:
        return l10n?.disputeTypeUnsafeConduct ?? 'Unsafe Conduct';
      case DisputeIssueType.verificationProblem:
        return l10n?.disputeTypeVerificationProblem ?? 'Verification Problem';
    }
  }
}
