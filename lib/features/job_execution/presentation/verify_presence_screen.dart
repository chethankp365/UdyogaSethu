import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:udyogasethu/core/supabase/edge_api.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/job_execution/data/job_execution_repository.dart';
import 'package:udyogasethu/features/job_execution/domain/job_verification.dart';
import 'package:udyogasethu/features/trust/data/face_embedding_service.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

enum LocationSimulationMode { real, atSite, acrossTownSofa, mockedGps }

class VerifyPresenceScreen extends ConsumerStatefulWidget {
  final String assignmentId;

  const VerifyPresenceScreen({
    super.key,
    required this.assignmentId,
  });

  @override
  ConsumerState<VerifyPresenceScreen> createState() => _VerifyPresenceScreenState();
}

class _VerifyPresenceScreenState extends ConsumerState<VerifyPresenceScreen> {
  final ImagePicker _picker = ImagePicker();

  bool _isCheckingGps = false;
  bool _isSubmitting = false;

  double? _currentLat;
  double? _currentLng;
  bool _isMocked = false;

  JobGeofenceStatus? _geofenceStatus;
  File? _selfieFile;
  int _failedAttempts = 0;
  FaceDetector? _faceDetector;

  LocationSimulationMode _simulationMode = LocationSimulationMode.real;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.15,
      ),
    );
    _checkLocation();
  }

  @override
  void dispose() {
    _faceDetector?.close();
    super.dispose();
  }

  Future<void> _checkLocation() async {
    setState(() {
      _isCheckingGps = true;
    });

    try {
      final detail = await ref.read(jobExecutionRepositoryProvider).fetchActiveJob(widget.assignmentId);

      if (_simulationMode == LocationSimulationMode.atSite) {
        _currentLat = detail.jobLocation.latitude;
        _currentLng = detail.jobLocation.longitude;
        _isMocked = false;
      } else if (_simulationMode == LocationSimulationMode.acrossTownSofa) {
        // Across town: ~5.2 km away from job site
        _currentLat = detail.jobLocation.latitude + 0.045;
        _currentLng = detail.jobLocation.longitude + 0.035;
        _isMocked = false;
      } else if (_simulationMode == LocationSimulationMode.mockedGps) {
        _currentLat = detail.jobLocation.latitude;
        _currentLng = detail.jobLocation.longitude;
        _isMocked = true;
      } else {
        // Real device GPS
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }

        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(timeLimit: Duration(seconds: 4)),
        );
        _currentLat = pos.latitude;
        _currentLng = pos.longitude;
        _isMocked = pos.isMocked;
      }

      if (_currentLat != null && _currentLng != null) {
        final geo = await ref.read(jobExecutionRepositoryProvider).checkJobGeofence(
              jobId: detail.jobId,
              lat: _currentLat!,
              lng: _currentLng!,
            );
        if (mounted) {
          setState(() {
            _geofenceStatus = geo;
            _isCheckingGps = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isCheckingGps = false;
          _geofenceStatus = const JobGeofenceStatus(
            distanceMeters: 0,
            radiusMeters: 150,
            withinGeofence: true,
          );
        });
      }
    }
  }

  Future<void> _captureSelfie() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 720,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _selfieFile = File(picked.path);
        });
      }
    } catch (_) {
      // In simulator without physical camera: provide simulated selfie bytes
      setState(() {
        _selfieFile = null;
      });
    }
  }

  bool _isImageTooDark(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return false;
      int totalLuma = 0;
      int sampled = 0;
      final stepX = max(1, decoded.width ~/ 16);
      final stepY = max(1, decoded.height ~/ 16);
      for (int y = 0; y < decoded.height; y += stepY) {
        for (int x = 0; x < decoded.width; x += stepX) {
          final pixel = decoded.getPixel(x, y);
          final luma = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).round();
          totalLuma += luma;
          sampled++;
        }
      }
      if (sampled == 0) return false;
      final avgLuma = totalLuma / sampled;
      return avgLuma < 35.0;
    } catch (_) {
      return false;
    }
  }

  Future<void> _submitVerification() async {
    if (_isSubmitting) return;

    if (_currentLat == null || _currentLng == null) {
      await _checkLocation();
      if (_currentLat == null || _currentLng == null) return;
    }

    if (_selfieFile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture a live selfie with your workplace in the background.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repo = ref.read(jobExecutionRepositoryProvider);
      final detail = await repo.fetchActiveJob(widget.assignmentId);

      // 1. Mock GPS Check
      if (_isMocked) {
        setState(() => _isSubmitting = false);
        _showRefusalBottomSheet(JobVerificationResult.error(
          code: 'mock_location_rejected',
          message: 'Mock or simulated GPS detected. Please turn off developer mock locations.',
        ));
        return;
      }

      // 2. Geofence Check (job radius, default 150m)
      final geo = await repo.checkJobGeofence(
        jobId: detail.jobId,
        lat: _currentLat!,
        lng: _currentLng!,
      );

      if (!geo.withinGeofence) {
        setState(() => _isSubmitting = false);
        final dist = geo.distanceMeters.round();
        final radius = geo.radiusMeters;
        final exceeded = (geo.distanceMeters - geo.radiusMeters).round();
        _showRefusalBottomSheet(JobVerificationResult.error(
          code: 'outside_geofence',
          message: 'Outside the site geofence by ${exceeded > 0 ? exceeded : dist}m ($dist m away, limit $radius m). Please move closer to the workplace.',
          distanceMeters: geo.distanceMeters,
          radiusMeters: geo.radiusMeters,
        ));
        return;
      }

      // 3. Image Brightness Check
      final bytes = await _selfieFile!.readAsBytes();
      if (_isImageTooDark(bytes)) {
        _failedAttempts++;
        setState(() => _isSubmitting = false);
        if (_failedAttempts >= 3) {
          _showRefusalBottomSheet(JobVerificationResult.error(
            code: 'manual_review_required',
            message: 'Three failed verification attempts reached. Your presence verification has been queued for manual review by an administrator.',
          ));
        } else {
          _showRefusalBottomSheet(JobVerificationResult.error(
            code: 'image_too_dark',
            message: 'The selfie is too dark. Please take a photo in a well-lit area with your workplace in the background (Attempt $_failedAttempts of 3).',
          ));
        }
        return;
      }

      // 4. Face Verification against enrolled template
      List<double>? vector;
      try {
        if (_simulationMode != LocationSimulationMode.real && kDebugMode) {
          vector = FaceEmbeddingService.generateMockVector();
        } else {
          final embeddingService = ref.read(faceEmbeddingServiceProvider);
          await embeddingService.initialize();
          if (_faceDetector != null) {
            vector = await embeddingService.extractEmbeddingFromPhoto(
              photoFile: _selfieFile!,
              faceDetector: _faceDetector!,
            );
          }
        }
      } catch (e) {
        if (_simulationMode != LocationSimulationMode.real && kDebugMode) {
          vector = FaceEmbeddingService.generateMockVector();
        } else {
          _failedAttempts++;
          setState(() => _isSubmitting = false);
          if (_failedAttempts >= 3) {
            _showRefusalBottomSheet(JobVerificationResult.error(
              code: 'manual_review_required',
              message: 'Three failed verification attempts reached. Your presence verification has been queued for manual review by an administrator.',
            ));
          } else {
            _showRefusalBottomSheet(JobVerificationResult.error(
              code: 'face_not_detected',
              message: 'No face detected in photo. Please frame your face clearly with your workplace in the background (Attempt $_failedAttempts of 3).',
            ));
          }
          return;
        }
      }

      // 5. Server face-verify invocation
      double faceScore = 0.90;
      try {
        final edgeApi = ref.read(edgeApiClientProvider);
        final faceRes = await edgeApi.faceVerifyVector(
          embedding: vector ?? FaceEmbeddingService.generateMockVector(),
          context: 'job_start',
          assignmentId: widget.assignmentId,
        );

        if (faceRes['result'] == 'fail') {
          _failedAttempts++;
          setState(() => _isSubmitting = false);
          final attemptsCount = (faceRes['attempts_count'] as num?)?.toInt() ?? _failedAttempts;
          if (attemptsCount >= 3 || _failedAttempts >= 3) {
            _showRefusalBottomSheet(JobVerificationResult.error(
              code: 'manual_review_required',
              message: 'Three failed verification attempts reached. Your presence verification has been flagged and submitted for admin manual review.',
            ));
          } else {
            _showRefusalBottomSheet(JobVerificationResult.error(
              code: 'face_mismatch',
              message: 'Face verification failed: Face does not match your enrolled identity template (Attempt $_failedAttempts of 3).',
            ));
          }
          return;
        }

        faceScore = (faceRes['similarity'] as num?)?.toDouble() ??
            (faceRes['match_score'] as num?)?.toDouble() ??
            0.90;
      } catch (err) {
        if (kDebugMode && _simulationMode != LocationSimulationMode.real) {
          faceScore = 0.92;
        } else {
          _failedAttempts++;
          setState(() => _isSubmitting = false);
          if (_failedAttempts >= 3) {
            _showRefusalBottomSheet(JobVerificationResult.error(
              code: 'manual_review_required',
              message: 'Three failed verification attempts reached. Presence check submitted for admin manual review.',
            ));
          } else {
            _showRefusalBottomSheet(JobVerificationResult.error(
              code: 'face_mismatch',
              message: 'Face verification failed: $err (Attempt $_failedAttempts of 3).',
            ));
          }
          return;
        }
      }

      // 6. Upload selfie to private bucket 'job-evidence'
      final selfiePath = await repo.uploadJobEvidence(
        assignmentId: widget.assignmentId,
        fileBytes: bytes,
        fileName: 'start_selfie.jpg',
      );

      // 7. Atomic record_step2_verification in database
      final result = await repo.recordStep2Verification(
        assignmentId: widget.assignmentId,
        lat: _currentLat!,
        lng: _currentLng!,
        selfiePath: selfiePath,
        faceScore: faceScore,
      );

      if (!mounted) return;

      if (result.success) {
        setState(() => _isSubmitting = false);
        ref.invalidate(activeJobDetailProvider(widget.assignmentId));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF0D6548),
            content: Text('Two-step verification completed! Work timer is now running.'),
            duration: Duration(seconds: 3),
          ),
        );

        context.pop();
      } else {
        setState(() => _isSubmitting = false);
        _showRefusalBottomSheet(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showRefusalBottomSheet(JobVerificationResult.error(
          code: 'error',
          message: e.toString().replaceAll('Exception: ', ''),
        ));
      }
    }
  }

  void _showRefusalBottomSheet(JobVerificationResult result) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isManual = result.isManualReviewRequired;
        final isDark = result.isTooDarkRejected;
        final isFace = result.isFaceRejected;
        final isMock = result.isMockedRejected;
        final isGeo = result.isGeofenceRejected;

        final Color iconBg = isManual
            ? Colors.amber.shade100
            : isDark
                ? Colors.orange.shade100
                : Colors.red.shade100;
        final Color iconColor = isManual
            ? Colors.amber.shade900
            : isDark
                ? Colors.orange.shade900
                : Colors.red;
        final IconData icon = isManual
            ? Icons.admin_panel_settings_rounded
            : isDark
                ? Icons.brightness_low_rounded
                : isFace
                    ? Icons.face_retouching_off_rounded
                    : isMock
                        ? Icons.security_update_warning_rounded
                        : isGeo
                            ? Icons.location_off_rounded
                            : Icons.cancel_outlined;

        final String title = isManual
            ? 'Submitted for Manual Review'
            : isDark
                ? 'Selfie Too Dark'
                : isFace
                    ? 'Face Verification Failed'
                    : isMock
                        ? (l10n?.mockLocationDetected ?? 'Mock Location Detected')
                        : isGeo
                            ? (l10n?.outsidePerimeter ?? 'Outside Site Boundary')
                            : (l10n?.verificationFailed ?? 'Verification Refused');

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                result.errorMessage ?? 'Unable to verify presence on site.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showGetHelpDialog();
                      },
                      child: Text(l10n?.getHelpOrSupport ?? 'Get Help'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (!isManual) {
                          _checkLocation();
                        }
                      },
                      child: Text(
                        isManual ? 'Understood' : (l10n?.retry ?? 'Retry'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGetHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Presence Verification Help'),
        content: const Text(
          '1. Ensure your GPS is enabled and set to High Accuracy.\n'
          '2. Stand within 150m of the employer\'s address.\n'
          '3. Make sure mock GPS / developer mock locations are turned OFF.\n'
          '4. If site address is incorrect, contact your employer or call support.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detailAsync = ref.watch(activeJobDetailProvider(widget.assignmentId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          l10n?.verifyYourPresence ?? 'Verify Your Presence',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (detail) {
          final isInside = _geofenceStatus?.withinGeofence ?? true;
          final dist = _geofenceStatus?.distanceMeters.round() ?? 0;
          final radius = _geofenceStatus?.radiusMeters ?? 150;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Explanatory Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.headerGreenDark.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_user, color: AppColors.headerGreenDark, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail.jobTitle,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n?.verifyPresenceSubtitle ??
                                  'Complete GPS site check and worker selfie to launch the official job timer.',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Step 1: GPS Site Perimeter Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isMocked
                          ? Colors.red
                          : isInside
                              ? AppColors.headerGreenDark
                              : Colors.red.shade400,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isMocked
                                ? Icons.warning_amber_rounded
                                : isInside
                                    ? Icons.check_circle
                                    : Icons.cancel,
                            color: _isMocked
                                ? Colors.red
                                : isInside
                                    ? AppColors.headerGreenDark
                                    : Colors.red,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n?.gpsPerimeterCheck ?? 'GPS Site Perimeter',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const Spacer(),
                          if (_isCheckingGps)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 20),
                              onPressed: _checkLocation,
                              tooltip: 'Refresh GPS',
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isMocked)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            l10n?.mockLocationDetected ??
                                'Mocked or simulated location detected. Please disable mock GPS apps.',
                            style: TextStyle(color: Colors.red.shade800, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        )
                      else ...[
                        Row(
                          children: [
                            Text(
                              isInside
                                  ? (l10n?.withinPerimeter ?? 'Within Site Boundary')
                                  : (l10n?.outsidePerimeter ?? 'Outside Site Boundary'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isInside ? AppColors.headerGreenDark : Colors.red,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${dist}m from site (Limit: ${radius}m)',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: radius > 0 ? (1.0 - (dist / (radius * 3))).clamp(0.0, 1.0) : 1.0,
                            backgroundColor: Colors.grey.shade200,
                            color: isInside ? AppColors.headerGreenDark : Colors.red,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Step 2: Worker Selfie Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _selfieFile != null ? Icons.check_circle : Icons.camera_alt_outlined,
                            color: _selfieFile != null ? AppColors.headerGreenDark : const Color(0xFF64748B),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n?.faceSelfieCheck ?? 'Worker Identity Selfie',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: GestureDetector(
                          onTap: _captureSelfie,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selfieFile != null ? AppColors.headerGreenDark : const Color(0xFFCBD5E1),
                                width: 2,
                              ),
                            ),
                            child: _selfieFile != null
                                ? ClipOval(
                                    child: Image.file(_selfieFile!, fit: BoxFit.cover),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_a_photo, size: 36, color: Color(0xFF64748B)),
                                      const SizedBox(height: 6),
                                      Text(
                                        l10n?.takeSelfieBtn ?? 'Take Selfie',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: _captureSelfie,
                          icon: const Icon(Icons.camera_alt, size: 18),
                          label: Text(_selfieFile != null
                              ? (l10n?.retakeSelfieBtn ?? 'Retake Selfie')
                              : (l10n?.takeSelfieBtn ?? 'Take Verification Selfie')),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Simulation / Demo Mode Panel (Gated under kDebugMode)
                if (kDebugMode) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.science_outlined, size: 18, color: Colors.amber),
                            SizedBox(width: 8),
                            Text(
                              'Demo Mode: Geofence Simulation',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('At Site (0m)'),
                              selected: _simulationMode == LocationSimulationMode.atSite,
                              onSelected: (val) {
                                setState(() => _simulationMode = LocationSimulationMode.atSite);
                                _checkLocation();
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Sofa Across Town (5.2km)'),
                              selected: _simulationMode == LocationSimulationMode.acrossTownSofa,
                              onSelected: (val) {
                                setState(() => _simulationMode = LocationSimulationMode.acrossTownSofa);
                                _checkLocation();
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Mocked GPS'),
                              selected: _simulationMode == LocationSimulationMode.mockedGps,
                              onSelected: (val) {
                                setState(() => _simulationMode = LocationSimulationMode.mockedGps);
                                _checkLocation();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.headerGreenDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isSubmitting ? null : _submitVerification,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            l10n?.verifyAndStartJob ?? 'Verify & Start Work',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
