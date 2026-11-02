import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:udyogasethu/core/supabase/edge_api.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/job_execution/data/job_execution_repository.dart';
import 'package:udyogasethu/features/trust/data/face_embedding_service.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class MidJobDialog extends ConsumerStatefulWidget {
  final String assignmentId;
  final bool isCustomer;

  const MidJobDialog({
    super.key,
    required this.assignmentId,
    required this.isCustomer,
  });

  static Future<bool?> show(BuildContext context, {required String assignmentId, required bool isCustomer}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MidJobDialog(
        assignmentId: assignmentId,
        isCustomer: isCustomer,
      ),
    );
  }

  @override
  ConsumerState<MidJobDialog> createState() => _MidJobDialogState();
}

class _MidJobDialogState extends ConsumerState<MidJobDialog> {
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _submitMidJobSelfie() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(jobExecutionRepositoryProvider);

      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 720,
      );

      if (picked == null) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Selfie required to verify mid-job attendance.';
        });
        return;
      }

      final embeddingService = ref.read(faceEmbeddingServiceProvider);
      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(enableClassification: false, performanceMode: FaceDetectorMode.fast),
      );

      List<double>? midVector;
      try {
        await embeddingService.initialize();
        midVector = await embeddingService.extractEmbeddingFromPhoto(
          photoFile: File(picked.path),
          faceDetector: faceDetector,
        );
      } catch (err) {
        faceDetector.close();
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Face detection failed: Please frame your face clearly facing the camera.';
        });
        return;
      }
      faceDetector.close();

      if (midVector.isEmpty) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'No face detected in mid-job selfie.';
        });
        return;
      }

      final matchResult = await embeddingService.verifyAgainstEnrolledFace(midVector);
      if (!matchResult.isMatch && !matchResult.notEnrolled) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Face mismatch: The selfie does not match your enrolled profile face (${(matchResult.similarity * 100).toStringAsFixed(0)}% match). Only the enrolled worker can verify presence.';
        });
        return;
      }

      final bytes = await picked.readAsBytes();
      try {
        final edgeApi = ref.read(edgeApiClientProvider);
        final faceRes = await edgeApi.faceVerifyVector(
          embedding: midVector,
          imageBase64: base64Encode(bytes),
          context: 'mid_job',
          assignmentId: widget.assignmentId,
        );
        if (faceRes['result'] == 'fail') {
          setState(() {
            _isSubmitting = false;
            _errorMessage = faceRes['message']?.toString() ?? 'Face verification failed.';
          });
          return;
        }
      } catch (_) {}

      final selfiePath = await repo.uploadJobEvidence(
        assignmentId: widget.assignmentId,
        fileBytes: bytes,
        fileName: 'midjob_selfie.jpg',
      );

      double? lat;
      double? lng;
      bool isMocked = false;
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(timeLimit: Duration(seconds: 3)),
        );
        lat = pos.latitude;
        lng = pos.longitude;
        isMocked = pos.isMocked;
      } catch (_) {}

      final res = await repo.verifyMidJobCheck(
        assignmentId: widget.assignmentId,
        lat: lat,
        lng: lng,
        isMocked: isMocked,
        selfiePath: selfiePath,
      );

      if (!mounted) return;

      if (res.success) {
        ref.invalidate(activeJobDetailProvider(widget.assignmentId));
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF0D6548),
            content: Text('Mid-job verification verified successfully!'),
          ),
        );
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = res.errorMessage ?? 'Verification refused';
        });
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

  Future<void> _submitCustomerConfirmation() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(jobExecutionRepositoryProvider);
      final res = await repo.verifyMidJobCheck(
        assignmentId: widget.assignmentId,
      );

      if (!mounted) return;

      if (res.success) {
        ref.invalidate(activeJobDetailProvider(widget.assignmentId));
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF0D6548),
            content: Text('Customer progress confirmed!'),
          ),
        );
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = res.errorMessage ?? 'Confirmation failed';
        });
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

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.security_update_good, color: AppColors.headerGreenDark, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n?.midJobCheckTitle ?? 'Mid-Job Verification',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.midJobCheckSubtitle ??
                'This high-value job requires a mid-shift check to guarantee safety and verified progress.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade800, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (widget.isCustomer)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.headerGreenDark),
            onPressed: _isSubmitting ? null : _submitCustomerConfirmation,
            child: _isSubmitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(l10n?.midJobCustomerConfirm ?? 'Confirm Progress', style: const TextStyle(color: Colors.white)),
          )
        else
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.headerGreenDark),
            onPressed: _isSubmitting ? null : _submitMidJobSelfie,
            icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
            label: _isSubmitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(l10n?.midJobConfirmSelfie ?? 'Take Mid-Shift Selfie', style: const TextStyle(color: Colors.white)),
          ),
      ],
    );
  }
}
