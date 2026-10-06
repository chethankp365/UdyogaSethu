import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/supabase/edge_api.dart';
import 'package:udyogasethu/features/privacy/data/consent_repository.dart';
import 'package:udyogasethu/features/privacy/domain/consent_purpose.dart';
import 'package:udyogasethu/features/privacy/presentation/consent_sheet.dart';
import 'package:udyogasethu/features/trust/data/face_embedding_service.dart';
import 'package:udyogasethu/features/trust/domain/face_quality_gates.dart';
import 'package:udyogasethu/features/trust/domain/liveness_challenge.dart';
import 'package:udyogasethu/features/verification/domain/face_check_result.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class FaceCheckScreen extends ConsumerStatefulWidget {
  final String contextType;
  final String? assignmentId;
  final String matcherMode;
  final int? targetChallengeCount;
  final ValueChanged<FaceCheckResult>? onResult;

  const FaceCheckScreen({
    super.key,
    required this.contextType,
    this.assignmentId,
    this.matcherMode = 'ondevice',
    this.targetChallengeCount,
    this.onResult,
  });

  @override
  ConsumerState<FaceCheckScreen> createState() => _FaceCheckScreenState();
}

class _FaceCheckScreenState extends ConsumerState<FaceCheckScreen> {
  bool _consentChecked = false;
  bool _hasFaceConsent = false;

  CameraController? _cameraController;
  CameraDescription? _frontCamera;
  FaceDetector? _faceDetector;

  bool _isCameraInitializing = true;
  bool _cameraPermissionDenied = false;

  bool _isProcessingFrame = false;
  bool _isVerifying = false;

  FaceCheckResult? _lastResult;
  int _attemptCount = 0;

  bool _faceDetected = false;
  bool _qualityPassed = false;

  List<LivenessChallenge> _challenges = [];
  int _currentChallengeIndex = 0;
  int _secondsRemaining = LivenessThresholds.challengeTimeoutSeconds;
  Timer? _timer;
  bool _timerStarted = false;

  final BlinkStateMachine _blinkStateMachine = BlinkStateMachine();
  int _headTurnHoldCount = 0;

  bool _showPassToast = false;
  bool _skipLivenessInDebug = false;

  // Live Telemetry variables for Debug Readout
  double? _liveLeftEyeProb;
  double? _liveRightEyeProb;
  double? _liveEulerX;
  double? _liveEulerY;
  double? _liveEulerZ;
  double? _liveSmileProb;
  double _liveFaceRatio = 0.0;
  InputImageRotation _liveRotation = InputImageRotation.rotation0deg;
  InputImageFormat _liveFormat = InputImageFormat.nv21;

  String _currentHint = 'Position face inside the oval frame';

  @override
  void initState() {
    super.initState();
    _checkConsentAndInitialize();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopCameraStream();
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  Future<void> _checkConsentAndInitialize() async {
    final consentRepo = ref.read(consentRepositoryProvider);
    final hasConsent = await consentRepo.hasValidConsent(ConsentPurpose.face);
    if (!mounted) return;

    setState(() {
      _hasFaceConsent = hasConsent;
      _consentChecked = true;
    });

    if (hasConsent) {
      await _initializeCamera();
    }
  }

  Future<void> _requestConsent() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const ConsentSheet(purpose: ConsentPurpose.face),
    );

    if (result == true) {
      await ref.read(consentRepositoryProvider).recordConsent(
            purpose: ConsentPurpose.face,
            granted: true,
          );
      if (!mounted) return;
      setState(() {
        _hasFaceConsent = true;
      });
      await _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isCameraInitializing = true;
      _timerStarted = false;
      _blinkStateMachine.reset();
      _headTurnHoldCount = 0;
    });

    try {
      final cameraPermission = await Permission.camera.request();
      if (cameraPermission.isDenied || cameraPermission.isPermanentlyDenied) {
        if (!mounted) return;
        setState(() {
          _cameraPermissionDenied = true;
          _isCameraInitializing = false;
        });
        return;
      }

      final cameras = await availableCameras();
      _frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.isNotEmpty ? cameras.first : throw Exception('No camera found'),
      );

      _cameraController = CameraController(
        _frontCamera!,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

      // Configure FaceDetector with fast performance mode for real-time camera stream processing
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableLandmarks: true,
          enableClassification: true,
          enableTracking: true,
          minFaceSize: 0.15,
        ),
      );

      await ref.read(faceEmbeddingServiceProvider).initialize();

      // Determine challenge count: 1 for login context, 2 for enrollment/other
      final challengeCount = widget.targetChallengeCount ?? (widget.contextType == 'login' ? 1 : 2);
      _challenges = LivenessChallenge.generateSequence(count: challengeCount);
      _currentChallengeIndex = 0;

      if (!mounted) return;
      setState(() {
        _isCameraInitializing = false;
        _cameraPermissionDenied = false;
      });

      _startCameraStream();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCameraInitializing = false;
      });
    }
  }

  void _startChallengeTimer() {
    if (_timerStarted) return;
    _timerStarted = true;

    _timer?.cancel();
    setState(() {
      _secondsRemaining = LivenessThresholds.challengeTimeoutSeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        _handleChallengeTimeout();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  Future<void> _handleChallengeTimeout() async {
    _stopCameraStream();
    final newAttemptCount = _attemptCount + 1;

    setState(() {
      _attemptCount = newAttemptCount;
      _isVerifying = false;
      _timerStarted = false;
    });

    if (newAttemptCount >= 3) {
      // Log failed attempt to Edge Function & require manual review
      final edgeApi = ref.read(edgeApiClientProvider);
      try {
        await edgeApi.faceVerifyVector(
          embedding: List<double>.filled(128, -0.99),
          context: widget.contextType,
          assignmentId: widget.assignmentId,
        );
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _lastResult = const FaceCheckResult(
          status: FaceCheckStatus.manualReviewRequired,
          message: 'Three consecutive liveness / verification attempts timed out. Account requires manual review.',
          fraudFlagCreated: true,
          attemptsCount: 3,
        );
      });
    } else {
      if (!mounted) return;
      setState(() {
        _lastResult = FaceCheckResult(
          status: FaceCheckStatus.fail,
          message: 'Liveness challenge timed out. Position your face clearly inside the oval, ensure good lighting, and follow the gesture hint.',
          attemptsCount: newAttemptCount,
        );
      });
    }
  }

  void _resetChallenge() {
    final challengeCount = widget.targetChallengeCount ?? (widget.contextType == 'login' ? 1 : 2);
    setState(() {
      _challenges = LivenessChallenge.generateSequence(count: challengeCount);
      _currentChallengeIndex = 0;
      _timerStarted = false;
      _blinkStateMachine.reset();
      _headTurnHoldCount = 0;
    });
    _startCameraStream();
  }

  void _startCameraStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    _cameraController!.startImageStream((CameraImage image) async {
      if (_isProcessingFrame || _isVerifying || _lastResult?.status == FaceCheckStatus.pass) {
        return;
      }

      _isProcessingFrame = true;
      try {
        await _processCameraFrame(image);
      } catch (e) {
        // Suppress frame processing exception silently
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  void _stopCameraStream() {
    try {
      if (_cameraController != null && _cameraController!.value.isStreamingImages) {
        _cameraController!.stopImageStream();
      }
    } catch (_) {}
  }

  Future<void> _processCameraFrame(CameraImage image) async {
    if (_faceDetector == null || _frontCamera == null) return;

    final inputImage = _buildInputImage(image, _frontCamera!);
    if (inputImage == null) return;

    final faces = await _faceDetector!.processImage(inputImage);

    if (!mounted) return;

    if (faces.isEmpty) {
      setState(() {
        _faceDetected = false;
        _qualityPassed = false;
        _currentHint = 'Position face inside the oval frame';
        _liveLeftEyeProb = null;
        _liveRightEyeProb = null;
        _liveEulerX = null;
        _liveEulerY = null;
        _liveEulerZ = null;
        _liveSmileProb = null;
        _liveFaceRatio = 0.0;
      });
      return;
    }

    final primaryFace = faces.first;
    final qualityCheck = FaceQualityGates.evaluate(
      faceCount: faces.length,
      boundingBox: primaryFace.boundingBox,
      screenSize: Size(image.width.toDouble(), image.height.toDouble()),
      leftEyeOpenProb: primaryFace.leftEyeOpenProbability,
      rightEyeOpenProb: primaryFace.rightEyeOpenProbability,
      headEulerAngleY: primaryFace.headEulerAngleY,
      headEulerAngleZ: primaryFace.headEulerAngleZ,
    );

    final faceArea = primaryFace.boundingBox.width * primaryFace.boundingBox.height;
    final frameArea = image.width * image.height;

    setState(() {
      _faceDetected = true;
      _qualityPassed = qualityCheck.isValid;
      if (!qualityCheck.isValid) {
        _currentHint = qualityCheck.hint;
      }

      // Record live telemetry variables for debug readout
      _liveLeftEyeProb = primaryFace.leftEyeOpenProbability;
      _liveRightEyeProb = primaryFace.rightEyeOpenProbability;
      _liveEulerX = primaryFace.headEulerAngleX;
      _liveEulerY = primaryFace.headEulerAngleY;
      _liveEulerZ = primaryFace.headEulerAngleZ;
      _liveSmileProb = primaryFace.smilingProbability;
      _liveFaceRatio = frameArea > 0 ? faceArea / frameArea : 0.0;
      _liveRotation = inputImage.metadata?.rotation ?? InputImageRotation.rotation0deg;
      _liveFormat = inputImage.metadata?.format ?? InputImageFormat.nv21;
    });

    if (!qualityCheck.isValid) return;

    // Start 9s timer ONLY after face passes quality check
    if (!_timerStarted) {
      _startChallengeTimer();
    }

    // Debug Bypass Switch Check
    if (kDebugMode && _skipLivenessInDebug) {
      _stopCameraStream();
      await _captureAndVerifyRealFace();
      return;
    }

    final currentChallenge = _challenges[_currentChallengeIndex];
    bool challengePassed = false;

    switch (currentChallenge.type) {
      case LivenessChallengeType.blink:
        challengePassed = _blinkStateMachine.processFrame(
          primaryFace.leftEyeOpenProbability,
          primaryFace.rightEyeOpenProbability,
        );
        break;

      case LivenessChallengeType.turnRight:
        final eulerY = primaryFace.headEulerAngleY ?? 0.0;
        if (eulerY < -LivenessThresholds.headTurnAngleDeg) {
          _headTurnHoldCount++;
          if (_headTurnHoldCount >= LivenessThresholds.headTurnHoldFrames) {
            challengePassed = true;
          }
        } else {
          _headTurnHoldCount = 0;
        }
        break;

      case LivenessChallengeType.turnLeft:
        final eulerY = primaryFace.headEulerAngleY ?? 0.0;
        if (eulerY > LivenessThresholds.headTurnAngleDeg) {
          _headTurnHoldCount++;
          if (_headTurnHoldCount >= LivenessThresholds.headTurnHoldFrames) {
            challengePassed = true;
          }
        } else {
          _headTurnHoldCount = 0;
        }
        break;

      case LivenessChallengeType.smile:
        final smileProb = primaryFace.smilingProbability ?? 0.0;
        if (smileProb >= LivenessThresholds.smileThreshold) {
          challengePassed = true;
        }
        break;
    }

    if (challengePassed) {
      currentChallenge.isCompleted = true;
      _showToastConfirmation();

      if (_currentChallengeIndex < _challenges.length - 1) {
        setState(() {
          _currentChallengeIndex++;
          _currentHint = 'Great! Next: ${_challenges[_currentChallengeIndex].label}';
          _blinkStateMachine.reset();
          _headTurnHoldCount = 0;
          _secondsRemaining = LivenessThresholds.challengeTimeoutSeconds;
        });
      } else {
        _stopCameraStream();
        await _captureAndVerifyRealFace();
      }
    } else {
      setState(() {
        _currentHint = currentChallenge.label;
      });
    }
  }

  void _showToastConfirmation() {
    setState(() {
      _showPassToast = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showPassToast = false;
        });
      }
    });
  }

  Future<void> _captureAndVerifyRealFace() async {
    _timer?.cancel();
    setState(() {
      _isVerifying = true;
      _currentHint = 'Hold still! Capturing verification photo...';
    });

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      List<double> vector;
      if (widget.matcherMode == 'mock' && kDebugMode) {
        vector = FaceEmbeddingService.generateMockVector();
      } else {
        if (_cameraController == null || !_cameraController!.value.isInitialized) {
          throw Exception('Camera is not active for verification photo capture.');
        }

        final XFile photoFile = await _cameraController!.takePicture();
        final embeddingService = ref.read(faceEmbeddingServiceProvider);
        await embeddingService.initialize();

        vector = await embeddingService.extractEmbeddingFromPhoto(
          photoFile: File(photoFile.path),
          faceDetector: _faceDetector!,
        );
      }

      await _executeFaceVerification(embedding: vector);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _lastResult = FaceCheckResult(
          status: FaceCheckStatus.error,
          message: 'Face embedding capture failed: $e',
          attemptsCount: _attemptCount + 1,
        );
      });
    }
  }

  InputImage? _buildInputImage(CameraImage image, CameraDescription camera) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
          InputImageRotation.rotation0deg;

      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ??
          InputImageFormat.nv21;

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: imageRotation,
          format: inputImageFormat,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _executeFaceVerification({List<double>? embedding}) async {
    setState(() {
      _isVerifying = true;
    });

    final vector = embedding ?? FaceEmbeddingService.generateMockVector();

    try {
      final edgeApi = ref.read(edgeApiClientProvider);
      final rawResponse = await edgeApi.faceVerifyVector(
        embedding: vector,
        context: widget.contextType,
        assignmentId: widget.assignmentId,
      );

      final result = FaceCheckResult.fromJson(rawResponse);

      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _lastResult = result;
        _attemptCount = result.attemptsCount > 0 ? result.attemptsCount : _attemptCount + 1;
      });

      if (widget.onResult != null) {
        widget.onResult!(result);
      }

      if (result.status == FaceCheckStatus.pass) {
        ref.read(appSessionProvider.notifier).setFaceLoginPassed(true);
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) {
            if (context.canPop()) {
              context.pop(result);
            } else {
              final activeRole = ref.read(appSessionProvider).activeRole;
              context.go(AppSessionNotifier.getHomeForRole(activeRole));
            }
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _lastResult = FaceCheckResult(
          status: FaceCheckStatus.error,
          message: e.toString(),
          attemptsCount: _attemptCount + 1,
        );
      });
    }
  }

  void _simulateDemoResult(bool pass) {
    List<double> vector;
    if (pass) {
      vector = FaceEmbeddingService.generateMockVector();
    } else {
      vector = List<double>.filled(128, -0.5);
    }
    _executeFaceVerification(embedding: vector);
  }

  void _retryCheck() {
    setState(() {
      _lastResult = null;
      _isVerifying = false;
    });
    _resetChallenge();
  }

  void _requestManualReviewAction() {
    final result = _lastResult ??
        FaceCheckResult(
          status: FaceCheckStatus.manualReviewRequired,
          message: 'Manual review requested after repeated verification attempts.',
          fraudFlagCreated: true,
          attemptsCount: _attemptCount,
        );

    ref.read(appSessionProvider.notifier).setFaceLoginPassed(true);

    if (widget.onResult != null) {
      widget.onResult!(result);
    }
    if (context.canPop()) {
      context.pop(result);
    } else {
      final activeRole = ref.read(appSessionProvider).activeRole;
      context.go(AppSessionNotifier.getHomeForRole(activeRole));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.navyBackground,
      appBar: AppBar(
        backgroundColor: AppColors.navyBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop(const FaceCheckResult(status: FaceCheckStatus.cancelled));
            }
          },
        ),
        title: Text(
          l10n.faceVerificationCheck,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.navyCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_user, color: AppColors.primaryTeal, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Context: ${widget.contextType.toUpperCase()}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    if (_consentChecked && !_hasFaceConsent) ...[
                      _buildConsentPromptCard(l10n),
                    ] else ...[
                      _buildOvalFrameView(l10n),
                      const SizedBox(height: 16),

                      if (_isVerifying) ...[
                        _buildVerifyingIndicator(),
                      ] else if (_lastResult != null) ...[
                        _buildResultCard(l10n, _lastResult!),
                      ] else ...[
                        _buildGuidanceCard(),
                      ],

                      if (kDebugMode && widget.matcherMode == 'mock') ...[
                        const SizedBox(height: 20),
                        _buildDemoControls(l10n),
                      ],

                      if (kDebugMode) ...[
                        const SizedBox(height: 12),
                        _buildDebugReadoutBadge(),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentPromptCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryTeal),
      ),
      child: Column(
        children: [
          const Icon(Icons.security, size: 48, color: AppColors.primaryTeal),
          const SizedBox(height: 12),
          Text(
            l10n.consentSheetTitle,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.faceCheckSubtext,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _requestConsent,
            icon: const Icon(Icons.check_circle),
            label: Text(l10n.consentAgreeButton),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOvalFrameView(AppLocalizations l10n) {
    Color borderColor = Colors.white30;
    if (_lastResult?.status == FaceCheckStatus.pass) {
      borderColor = Colors.green;
    } else if (_lastResult?.status == FaceCheckStatus.fail ||
        _lastResult?.status == FaceCheckStatus.manualReviewRequired) {
      borderColor = Colors.redAccent;
    } else if (_faceDetected && _qualityPassed) {
      borderColor = AppColors.primaryTeal;
    }

    return Center(
      child: SizedBox(
        width: 240,
        height: 310,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(120),
                border: Border.all(color: borderColor, width: 4),
                color: Colors.black,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(120),
                child: _isCameraInitializing
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
                    : _cameraPermissionDenied
                        ? _buildPermissionDeniedView()
                        : _cameraController != null && _cameraController!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: 240 / 310,
                                child: CameraPreview(_cameraController!),
                              )
                            : const Center(
                                child: Icon(Icons.face, size: 100, color: Colors.white30),
                              ),
              ),
            ),

            if (_showPassToast)
              Container(
                width: 240,
                height: 310,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(120),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 64, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      '✓ Great, got it!',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),

            if (_lastResult?.status == FaceCheckStatus.pass)
              Container(
                width: 240,
                height: 310,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(120),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 72, color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'VERIFIED ✓',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedView() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.navyCard,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt_outlined, color: Colors.redAccent, size: 48),
          const SizedBox(height: 8),
          const Text(
            'Camera Access Required',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => openAppSettings(),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidanceCard() {
    final currentChallenge = _challenges.isNotEmpty && _currentChallengeIndex < _challenges.length
        ? _challenges[_currentChallengeIndex]
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Challenge ${_currentChallengeIndex + 1}/${_challenges.length}',
                style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 16),
              Icon(Icons.timer, color: _secondsRemaining < 4 ? Colors.redAccent : Colors.orangeAccent, size: 18),
              const SizedBox(width: 4),
              Text(
                '${_secondsRemaining}s',
                style: TextStyle(
                  color: _secondsRemaining < 4 ? Colors.redAccent : Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currentChallenge?.label ?? _currentHint,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyingIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(color: AppColors.primaryTeal, strokeWidth: 3),
          ),
          SizedBox(width: 16),
          Text(
            'Verifying face identity with server...',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(AppLocalizations l10n, FaceCheckResult result) {
    if (result.status == FaceCheckStatus.pass) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF064E3B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 40),
            const SizedBox(height: 8),
            Text(
              l10n.faceMatchSuccess,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (result.matchScore != null) ...[
              const SizedBox(height: 4),
              Text(
                'Match Score: ${result.matchScore!.toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ],
        ),
      );
    }

    if (result.status == FaceCheckStatus.manualReviewRequired) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF7F1D1D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.redAccent),
        ),
        child: Column(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 44),
            const SizedBox(height: 8),
            Text(
              l10n.manualReviewRequiredTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              result.message ?? l10n.manualReviewRequiredBody,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _requestManualReviewAction,
              icon: const Icon(Icons.assignment_ind),
              label: Text(l10n.requestManualReview),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF331900),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orangeAccent),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.orangeAccent, size: 40),
          const SizedBox(height: 8),
          Text(
            l10n.faceMatchFailedTitle,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            result.message ?? l10n.faceMatchFailedBody,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text(
            'Attempt $_attemptCount of 3',
            style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          if (result.needsEnrollment) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                context.push(AppRoutes.kycFace);
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Enroll Face Profile Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _retryCheck,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retryVerification),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDebugReadoutBadge() {
    if (!kDebugMode) return const SizedBox.shrink();

    final matcherName = widget.matcherMode == 'mock'
        ? 'MockMatcher (Simulated)'
        : 'OnDeviceMatcher (MobileFaceNet 128d)';

    final simStr = _lastResult?.similarity != null
        ? '${(_lastResult!.similarity! * 100).toStringAsFixed(1)}%'
        : 'N/A';

    final threshStr = _lastResult?.threshold != null
        ? '${(_lastResult!.threshold! * 100).toStringAsFixed(1)}%'
        : '65.0%';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyanAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.developer_mode, color: Colors.cyanAccent, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'LIVE TELEMETRY (Debug Build)',
                    style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Skip:', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                  Switch(
                    value: _skipLivenessInDebug,
                    onChanged: (val) {
                      setState(() {
                        _skipLivenessInDebug = val;
                      });
                    },
                    activeThumbColor: Colors.amber,
                  ),
                ],
              ),
            ],
          ),
          Text(
            'Skip Liveness: ${_skipLivenessInDebug ? "ON (Bypass Gestures)" : "OFF"}',
            style: TextStyle(color: _skipLivenessInDebug ? Colors.amber : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const Divider(color: Colors.white24, height: 12),
          Text(
            'Matcher: $matcherName',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Text(
            'Similarity: $simStr | Threshold: $threshStr',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Eyes Open: L: ${_liveLeftEyeProb?.toStringAsFixed(2) ?? "null"} | R: ${_liveRightEyeProb?.toStringAsFixed(2) ?? "null"} (Blink: ${_blinkStateMachine.state.name})',
            style: const TextStyle(color: Colors.cyanAccent, fontSize: 11),
          ),
          Text(
            'Head Pose: Yaw(Y): ${_liveEulerY?.toStringAsFixed(1) ?? "0"}° | Pitch(X): ${_liveEulerX?.toStringAsFixed(1) ?? "0"}° | Roll(Z): ${_liveEulerZ?.toStringAsFixed(1) ?? "0"}°',
            style: const TextStyle(color: Colors.cyanAccent, fontSize: 11),
          ),
          Text(
            'Smile: ${_liveSmileProb?.toStringAsFixed(2) ?? "0"} | Face Size: ${(_liveFaceRatio * 100).toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Text(
            'Rot: ${_liveRotation.name} | Format: ${_liveFormat.name} | Hold: $_headTurnHoldCount/2',
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoControls(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bug_report, color: Colors.amber, size: 16),
              SizedBox(width: 6),
              Text(
                'Demo Mode Test Controls',
                style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _simulateDemoResult(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.demoSimulatePass, style: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _simulateDemoResult(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.demoSimulateFail, style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
