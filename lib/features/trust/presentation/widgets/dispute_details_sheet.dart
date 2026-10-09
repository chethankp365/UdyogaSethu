import 'package:flutter/material.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/trust/domain/dispute.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

/// Modal bottom sheet displaying active dispute status, issue type, timeline, and evidence.
class DisputeDetailsSheet extends StatelessWidget {
  final DisputeRecord dispute;
  final String jobTitle;

  const DisputeDetailsSheet({
    super.key,
    required this.dispute,
    required this.jobTitle,
  });

  static void show(
    BuildContext context, {
    required DisputeRecord dispute,
    required String jobTitle,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DisputeDetailsSheet(
        dispute: dispute,
        jobTitle: jobTitle,
      ),
    );
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Icon(Icons.gavel_rounded, color: Color(0xFFDC2626), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.disputeTrackingTitle ?? 'Dispute Status Tracking',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textDark),
                    ),
                    Text(
                      jobTitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(dispute.status),
            ],
          ),

          const SizedBox(height: 18),

          // Freeze Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_rounded, color: Color(0xFFB45309), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Escrow release is currently frozen. UdyogaSethu mediation officer is reviewing logs and evidence.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.3),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Details List
          _buildInfoRow('Issue Category', dispute.issueType.defaultLabel),
          const SizedBox(height: 10),
          _buildInfoRow('Filed At', dispute.createdAt.toLocal().toString().split('.')[0]),
          const SizedBox(height: 10),

          Text(
            l10n?.disputeDetailsLabel ?? 'Reported Details',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              dispute.details,
              style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.4),
            ),
          ),

          if (dispute.evidencePaths.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Attached Evidence (${dispute.evidencePaths.length} photos)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: dispute.evidencePaths.map((path) {
                return Chip(
                  avatar: const Icon(Icons.attachment_rounded, size: 16),
                  label: Text('Photo: ${path.split('/').last}'),
                  backgroundColor: AppColors.paleMint,
                  side: const BorderSide(color: AppColors.cardBorderGreen),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textDark,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close Tracking'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(DisputeStatus status) {
    Color bg;
    Color fg;
    String label = status.defaultLabel;

    switch (status) {
      case DisputeStatus.open:
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        break;
      case DisputeStatus.inReview:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
      case DisputeStatus.resolved:
        bg = const Color(0xFFF0FDF4);
        fg = const Color(0xFF16A34A);
        break;
      case DisputeStatus.rejected:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      ],
    );
  }
}
