// Widget: SosConfirmationDialog (Step P7.3)
// Trigger Emergency SOS modal with booking reference, disclaimers, haptic feedback and honest SMS readout

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_spacing.dart';
import 'package:udyogasethu/core/widgets/app_button.dart';
import 'package:udyogasethu/features/safety/data/safety_repository.dart';
import 'package:udyogasethu/features/safety/domain/sos_incident.dart';

class SosConfirmationDialog extends ConsumerStatefulWidget {
  final String? bookingCode;
  final String? assignmentId;

  const SosConfirmationDialog({
    super.key,
    this.bookingCode,
    this.assignmentId,
  });

  static Future<void> show(
    BuildContext context, {
    String? bookingCode,
    String? assignmentId,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SosConfirmationDialog(
        bookingCode: bookingCode,
        assignmentId: assignmentId,
      ),
    );
  }

  @override
  ConsumerState<SosConfirmationDialog> createState() =>
      _SosConfirmationDialogState();
}

class _SosConfirmationDialogState extends ConsumerState<SosConfirmationDialog> {
  bool _isLoading = false;
  SosIncident? _incidentResult;
  String? _errorMessage;

  Future<void> _triggerEscalation() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      double lat = 12.9716;
      double lng = 77.5946;

      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            timeLimit: Duration(seconds: 4),
          ),
        );
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (_) {
        // Fallback to default coordinates if location timeout
      }

      final repo = ref.read(safetyRepositoryProvider);
      final incident = await repo.triggerSos(
        lat: lat,
        lng: lng,
        assignmentId: widget.assignmentId,
        bookingCode: widget.bookingCode,
      );

      HapticFeedback.vibrate();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _incidentResult = incident;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _dialHelpline(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConfirmed = _incidentResult != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: isConfirmed ? _buildConfirmedContent() : _buildPromptContent(),
        ),
      ),
    );
  }

  Widget _buildPromptContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Warning Icon Header
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.errorRed.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.errorRed,
              size: 38,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Title
        const Text(
          'Trigger Emergency SOS?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // Active Booking Chip
        if (widget.bookingCode != null) ...[
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Active Booking: ${widget.bookingCode}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Explanatory note
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: const Text(
            'Safety team and your registered emergency contacts will be notified in real-time with your current GPS location.\n\nNote: This does NOT dial the police directly.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF991B1B),
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (_errorMessage != null) ...[
          Text(
            _errorMessage!,
            style: const TextStyle(color: AppColors.errorRed, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Trigger Button
        AppButton(
          label: _isLoading ? 'Alerting Safety Network...' : 'Yes, Trigger Emergency Escalation',
          variant: AppButtonVariant.danger,
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _triggerEscalation,
          icon: Icons.sos,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Cancel Button
        OutlinedButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmedContent() {
    final incident = _incidentResult!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success / Alert Header
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Color(0xFFDC2626),
              size: 38,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        const Text(
          'Emergency SOS Escalated',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        Text(
          'Incident ID: ${incident.id.substring(0, 8).toUpperCase()}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Honest Status Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 18, color: Color(0xFFB45309)),
                  SizedBox(width: 8),
                  Text(
                    'Safety Team Alerted (Realtime)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    incident.smsSent ? Icons.check_circle : Icons.info_outline,
                    size: 18,
                    color: incident.smsSent ? const Color(0xFF059669) : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      incident.smsSent
                          ? 'Alert SMS with live location link dispatched to ${incident.emergencyContactsCount} emergency contact(s).'
                          : 'SMS gateway not configured: Emergency broadcast logged for admin team.',
                      style: TextStyle(
                        fontSize: 12,
                        color: incident.smsSent ? const Color(0xFF065F46) : const Color(0xFF78350F),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Direct Emergency Dialers
        const Text(
          'Dial Police / Ambulance Directly:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _dialHelpline('112'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.call, size: 18),
                label: const Text('Police 112', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _dialHelpline('108'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.medical_services_outlined, size: 18),
                label: const Text('Ambulance 108', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Dismiss
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close', style: TextStyle(color: Color(0xFF64748B))),
        ),
      ],
    );
  }
}
