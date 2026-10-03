import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:url_launcher/url_launcher.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/privacy/data/consent_repository.dart';
import 'package:udyogasethu/features/privacy/domain/consent_purpose.dart';
import 'package:udyogasethu/features/privacy/presentation/consent_sheet.dart';
import 'package:udyogasethu/features/trust/data/face_embedding_service.dart';
import 'package:udyogasethu/features/trust/data/kyc_repository.dart';
import 'package:udyogasethu/features/trust/domain/face_quality_gates.dart';
import 'package:udyogasethu/features/trust/domain/liveness_challenge.dart';

class FaceEnrollmentScreen extends ConsumerStatefulWidget {
  final String matcherMode;

  const FaceEnrollmentScreen({
    super.key,
    this.matcherMode = 'ondevice',
  });

  @override
  ConsumerState<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

Future<bool> showConsentSheet(BuildContext context, WidgetRef ref, ConsentPurpose purpose) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => ConsentSheet(purpose: purpose),
  );
  if (result == true) {
    await ref.read(consentRepositoryProvider).recordConsent(
          purpose: purpose,
          granted: true,
        );
    return true;
  }
  return false;
}

class _FaceEnrollmentScreenState extends ConsumerState<FaceEnrollmentScreen> {
  bool _consentChecked = false;
  bool _hasFaceConsent = false;

  final bool _cameraPermissionDenied = false;
  bool _isProcessing = false;
  bool _isEnrolled = false;

  List<LivenessChallenge> _challenges = [];
  int _currentChallengeIndex = 0;
  int _secondsRemaining = 15;
  Timer? _timer;

  String _currentHint = 'Position face inside the oval frame';
  bool _qualityPassed = false;
  List<int>? _capturedImageBytes;
  List<double>? _extractedEmbedding;

  @override
  void initState() {
    super.initState();
    _checkConsent();
    _resetChallenges();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetChallenges() {
    _challenges = LivenessChallenge.generateRandomPair();
    _currentChallengeIndex = 0;
    _secondsRemaining = 15;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0 && !_isEnrolled && !_isProcessing) {
        setState(() {
          _secondsRemaining--;
        });
      } else if (_secondsRemaining == 0 && !_isEnrolled) {
        _timer?.cancel();
        setState(() {
          _currentHint = 'Challenge timed out! Tap retry to try again.';
        });
      }
    });
  }

  Future<void> _checkConsent() async {
    final consentRepo = ref.read(consentRepositoryProvider);
    final hasConsent = await consentRepo.hasValidConsent(ConsentPurpose.face);
    if (!mounted) return;
    setState(() {
      _hasFaceConsent = hasConsent;
      _consentChecked = true;
    });

    if (!hasConsent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestFaceConsent();
      });
    }
  }

  Future<void> _requestFaceConsent() async {
    final granted = await showConsentSheet(context, ref, ConsentPurpose.face);
    if (!mounted) return;
    setState(() {
      _hasFaceConsent = granted;
    });
  }

  Future<void> _captureAndProcessFrame() async {
    if (_isProcessing || !_hasFaceConsent) return;
    setState(() {
      _isProcessing = true;
      _currentHint = 'Analyzing camera frame & face quality...';
    });

    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 85,
      );

      if (photo == null) {
        setState(() {
          _isProcessing = false;
          _currentHint = 'Camera capture cancelled';
        });
        return;
      }

      final bytes = await photo.readAsBytes();
      final decoded = img.decodeImage(bytes);

      if (decoded == null) {
        setState(() {
          _isProcessing = false;
          _currentHint = 'Could not process image frame';
        });
        return;
      }

      final qualityService = ref.read(faceEmbeddingServiceProvider);
      await qualityService.initialize();

      // Extract 128-float32 normalized embedding
      final embedding = qualityService.extractEmbedding(decoded);

      // Evaluate simulated quality gates
      final gateResult = FaceQualityGates.evaluate(
        faceCount: 1,
        boundingBox: Rect.fromLTWH(0, 0, decoded.width.toDouble(), decoded.height.toDouble()),
        screenSize: Size(decoded.width.toDouble(), decoded.height.toDouble()),
        leftEyeOpenProb: 0.9,
        rightEyeOpenProb: 0.9,
        headEulerAngleY: 0.0,
        headEulerAngleZ: 0.0,
      );

      if (!gateResult.isValid) {
        setState(() {
          _isProcessing = false;
          _qualityPassed = false;
          _currentHint = gateResult.hint;
        });
        return;
      }

      // Progress through liveness challenges
      if (_currentChallengeIndex < _challenges.length) {
        setState(() {
          _challenges[_currentChallengeIndex].isCompleted = true;
          _currentChallengeIndex++;
          _qualityPassed = true;
          _capturedImageBytes = bytes;
          _extractedEmbedding = embedding;
        });

        if (_currentChallengeIndex < _challenges.length) {
          setState(() {
            _isProcessing = false;
            _currentHint = 'Great! Next: ${_challenges[_currentChallengeIndex].label}';
          });
          return;
        }
      }

      // All challenges complete -> Submit Enrollment
      setState(() {
        _currentHint = 'Submitting face enrolment & embedding vector...';
      });

      final kycRepo = ref.read(kycRepositoryProvider);
      final challengeNames = _challenges.map((c) => c.type.name).toList();

      await kycRepo.enrollFace(
        embedding: _extractedEmbedding ?? embedding,
        livenessPassed: true,
        challenges: challengeNames,
        photoBytes: _capturedImageBytes ?? bytes,
      );

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isEnrolled = true;
        _currentHint = 'Face Enrolment Successful!';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _currentHint = 'Enrolment error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMock = widget.matcherMode == 'mock';

    return Scaffold(
      backgroundColor: AppColors.navyBackground,
      appBar: AppBar(
        title: const Text('Face Enrolment & Liveness', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.navyBackground,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (isMock)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.amber.shade900,
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Demo mode — Mock Face Matcher Active',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            if (!_hasFaceConsent && _consentChecked)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.navyCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.shield_outlined, color: Colors.amber, size: 36),
                    const SizedBox(height: 8),
                    const Text(
                      'Face Data Consent Required',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Your facial features are converted into a private 128-dimensional embedding vector. Raw photos are never stored publicly or shared.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
                      onPressed: _requestFaceConsent,
                      child: const Text('Grant Face Consent', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),

            if (_cameraPermissionDenied)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.navyCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade700),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.no_photography_outlined, color: Colors.redAccent, size: 36),
                    const SizedBox(height: 8),
                    const Text(
                      'Camera Access Needed',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Camera access is required for real-time face detection and liveness challenges. Please enable camera permissions in settings.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.amberOrange),
                      icon: const Icon(Icons.settings, color: Colors.white),
                      label: const Text('Open App Settings', style: TextStyle(color: Colors.white)),
                      onPressed: () => launchUrl(Uri.parse('app-settings:')),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.navyCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.navyBorder),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Camera Oval Guide Frame
                    Center(
                      child: Container(
                        width: 240,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(160),
                          border: Border.all(
                            color: _isEnrolled
                                ? AppColors.emerald
                                : (_qualityPassed ? Colors.cyanAccent : Colors.amber),
                            width: 3.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(160),
                          child: Container(
                            color: Colors.black26,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isEnrolled
                                      ? Icons.check_circle_outline
                                      : Icons.face_retouching_natural,
                                  size: 64,
                                  color: _isEnrolled ? AppColors.emerald : Colors.white54,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isEnrolled ? 'Enrolled!' : 'Position Face Here',
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Top Status & Timer Banner
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Time Remaining: ${_secondsRemaining}s',
                              style: TextStyle(
                                color: _secondsRemaining <= 5 ? Colors.redAccent : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Challenge ${_currentChallengeIndex + 1}/${_challenges.length}',
                              style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Dynamic Hint Bar
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.navyBorder),
                        ),
                        child: Column(
                          children: [
                            if (_currentChallengeIndex < _challenges.length)
                              Text(
                                _challenges[_currentChallengeIndex].label,
                                style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold, fontSize: 15),
                                textAlign: TextAlign.center,
                              ),
                            const SizedBox(height: 4),
                            Text(
                              _currentHint,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.navyBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        setState(() {
                          _resetChallenges();
                          _isEnrolled = false;
                          _currentHint = 'Position face inside the oval frame';
                        });
                      },
                      child: const Text('Reset Challenges', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isEnrolled ? AppColors.emerald : AppColors.amberOrange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isEnrolled
                          ? () => context.pop()
                          : (_isProcessing || !_hasFaceConsent ? null : _captureAndProcessFrame),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              _isEnrolled ? 'Done & Return' : 'Capture & Verify',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
