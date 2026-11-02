import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/supabase/edge_api.dart';
import 'package:udyogasethu/features/privacy/data/consent_repository.dart';
import 'package:udyogasethu/features/privacy/domain/consent_purpose.dart';
import 'package:udyogasethu/features/trust/data/face_embedding_service.dart';
import 'package:udyogasethu/features/trust/domain/face_quality_gates.dart';
import 'package:udyogasethu/features/trust/domain/liveness_challenge.dart';
import 'package:udyogasethu/features/verification/domain/face_check_result.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

/// The 5 explicit stages of the Face Verification Experience.
enum FaceVerificationStep {
  intro,         // Screen 1: Verification Introduction, Privacy & Consent
  cameraPrep,    // Screen 2: Real Camera Live Preview & Quality Guidance
  liveness,      // Screen 3: Observation-Based Randomized Liveness Challenges
  verifying,     // Screen 4: Capturing Selfie & Cloud Biometric Verification
  results,       // Screen 5: 7 Dedicated Animated Result States
}

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

class _FaceCheckScreenState extends ConsumerState<FaceCheckScreen>
    with TickerProviderStateMixin {
  FaceVerificationStep _step = FaceVerificationStep.intro;

  bool _hasFaceConsent = false;
  bool _consentCheckbox = false;

  CameraController? _cameraController;
  CameraDescription? _frontCamera;
  FaceDetector? _faceDetector;

  bool _isCameraInitializing = false;
  bool _cameraPermissionDenied = false;

  bool _isProcessingFrame = false;
  FaceCheckResult? _lastResult;
  int _attemptCount = 0;

  bool _faceDetected = false;
  bool _qualityPassed = false;
  int _faceStableFrames = 0;

  List<LivenessChallenge> _challenges = [];
  int _currentChallengeIndex = 0;
  int _secondsRemaining = LivenessThresholds.challengeTimeoutSeconds;
  Timer? _timer;
  bool _timerStarted = false;

  final BlinkStateMachine _blinkStateMachine = BlinkStateMachine();
  int _headTurnHoldCount = 0;
  bool _showPassToast = false;
  String _currentHint = 'Position face inside the oval frame';

  late AnimationController _scanLineController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _checkConsent();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopCameraStream();
    _cameraController?.dispose();
    _faceDetector?.close();
    _scanLineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkConsent() async {
    final consentRepo = ref.read(consentRepositoryProvider);
    final hasConsent = await consentRepo.hasValidConsent(ConsentPurpose.face);
    if (!mounted) return;

    setState(() {
      _hasFaceConsent = hasConsent;
      _consentCheckbox = hasConsent;
    });
  }

  Future<void> _onStartVerificationPressed() async {
    HapticFeedback.lightImpact();
    if (!_consentCheckbox) return;

    if (!_hasFaceConsent) {
      await ref.read(consentRepositoryProvider).recordConsent(
            purpose: ConsentPurpose.face,
            granted: true,
          );
      if (!mounted) return;
      setState(() {
        _hasFaceConsent = true;
      });
    }

    setState(() {
      _step = FaceVerificationStep.cameraPrep;
      _lastResult = null;
    });

    await _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isCameraInitializing = true;
      _cameraPermissionDenied = false;
      _timerStarted = false;
      _faceStableFrames = 0;
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
          _step = FaceVerificationStep.results;
          _lastResult = const FaceCheckResult(
            status: FaceCheckStatus.error,
            message: 'Camera permission denied. Camera access is required for biometric verification.',
          );
        });
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No camera devices detected on this device.');
      }

      _frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        _frontCamera!,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

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
        _step = FaceVerificationStep.results;
        _lastResult = FaceCheckResult(
          status: FaceCheckStatus.error,
          message: 'Camera initialization error: $e',
        );
      });
    }
  }

  void _startCameraStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    _cameraController!.startImageStream((CameraImage image) async {
      if (_isProcessingFrame ||
          _step == FaceVerificationStep.verifying ||
          _step == FaceVerificationStep.results) {
        return;
      }

      _isProcessingFrame = true;
      try {
        await _processCameraFrame(image);
      } catch (_) {
        // Frame processing exception ignored
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
        _faceStableFrames = 0;
        _currentHint = 'Position face inside the oval frame';
      });
      return;
    }

    final primaryFace = faces.first;
    final activeChallenge = (_step == FaceVerificationStep.liveness && _currentChallengeIndex < _challenges.length)
        ? _challenges[_currentChallengeIndex].type
        : null;

    final qualityCheck = FaceQualityGates.evaluate(
      faceCount: faces.length,
      boundingBox: primaryFace.boundingBox,
      screenSize: Size(image.width.toDouble(), image.height.toDouble()),
      leftEyeOpenProb: primaryFace.leftEyeOpenProbability,
      rightEyeOpenProb: primaryFace.rightEyeOpenProbability,
      headEulerAngleY: primaryFace.headEulerAngleY,
      headEulerAngleZ: primaryFace.headEulerAngleZ,
      activeChallenge: activeChallenge,
    );

    setState(() {
      _faceDetected = true;
      _qualityPassed = qualityCheck.isValid;
      if (!qualityCheck.isValid) {
        _currentHint = qualityCheck.hint;
        _faceStableFrames = 0;
      } else {
        _faceStableFrames++;
        if (_step == FaceVerificationStep.cameraPrep) {
          _currentHint = 'Face centered! Preparing liveness challenges...';
        }
      }
    });

    if (!qualityCheck.isValid) return;

    // Transition from Camera Preparation (Screen 2) to Liveness (Screen 3)
    if (_step == FaceVerificationStep.cameraPrep && _faceStableFrames >= 3) {
      setState(() {
        _step = FaceVerificationStep.liveness;
        _secondsRemaining = LivenessThresholds.challengeTimeoutSeconds;
      });
      _startChallengeTimer();
      return;
    }

    // Process Liveness Challenges (Screen 3)
    if (_step == FaceVerificationStep.liveness) {
      if (!_timerStarted) {
        _startChallengeTimer();
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
        HapticFeedback.mediumImpact();
        currentChallenge.isCompleted = true;
        _showPassToastConfirmation();

        if (_currentChallengeIndex < _challenges.length - 1) {
          setState(() {
            _currentChallengeIndex++;
            _currentHint = 'Great! Next: ${_challenges[_currentChallengeIndex].label}';
            _blinkStateMachine.reset();
            _headTurnHoldCount = 0;
            _secondsRemaining = LivenessThresholds.challengeTimeoutSeconds;
          });
        } else {
          // All liveness challenges completed! Transition to verification submission (Screen 4)
          _stopCameraStream();
          setState(() {
            _step = FaceVerificationStep.verifying;
          });
          await _captureAndVerifyRealFace();
        }
      } else {
        setState(() {
          _currentHint = currentChallenge.label;
        });
      }
    }
  }

  void _showPassToastConfirmation() {
    setState(() {
      _showPassToast = true;
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _showPassToast = false;
        });
      }
    });
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
      _timerStarted = false;
      _step = FaceVerificationStep.results;
    });

    if (newAttemptCount >= 3) {
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
          message: 'Liveness challenge timed out. Position face clearly inside the oval and follow the gesture hint.',
          attemptsCount: newAttemptCount,
        );
      });
    }
  }

  Future<void> _captureAndVerifyRealFace() async {
    _timer?.cancel();
    setState(() {
      _currentHint = 'Hold still! Capturing high-resolution photo...';
    });

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      List<double> vector;
      String? imageBase64;

      if (widget.matcherMode == 'mock' && kDebugMode) {
        vector = FaceEmbeddingService.generateMockVector();
      } else {
        if (_cameraController == null || !_cameraController!.value.isInitialized) {
          throw Exception('Camera is not active for verification photo capture.');
        }

        final XFile photoFile = await _cameraController!.takePicture();
        final bytes = await photoFile.readAsBytes();
        if (bytes.isNotEmpty) {
          imageBase64 = base64Encode(bytes);
        }

        try {
          final embeddingService = ref.read(faceEmbeddingServiceProvider);
          await embeddingService.initialize();

          vector = await embeddingService.extractEmbeddingFromPhoto(
            photoFile: File(photoFile.path),
            faceDetector: _faceDetector!,
          );
        } catch (embErr) {
          debugPrint('[FaceCheckScreen] Local embedding fallback: $embErr');
          vector = List<double>.filled(128, 0.0);
        }
      }

      await _executeFaceVerification(embedding: vector, imageBase64: imageBase64);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = FaceVerificationStep.results;
        _lastResult = FaceCheckResult(
          status: FaceCheckStatus.error,
          message: 'Verification selfie capture failed: $e',
          attemptsCount: _attemptCount,
        );
      });
    }
  }

  Future<void> _executeFaceVerification({List<double>? embedding, String? imageBase64}) async {
    setState(() {
      _step = FaceVerificationStep.verifying;
    });

    final vector = embedding ?? FaceEmbeddingService.generateMockVector();

    try {
      final edgeApi = ref.read(edgeApiClientProvider);
      final rawResponse = await edgeApi.faceVerifyVector(
        embedding: vector,
        context: widget.contextType,
        assignmentId: widget.assignmentId,
        imageBase64: imageBase64,
      );

      final result = FaceCheckResult.fromJson(rawResponse);

      if (!mounted) return;
      setState(() {
        _step = FaceVerificationStep.results;
        _lastResult = result;
        _attemptCount = result.attemptsCount > 0 ? result.attemptsCount : _attemptCount + 1;
      });

      if (widget.onResult != null) {
        widget.onResult!(result);
      }

      if (result.status == FaceCheckStatus.pass) {
        HapticFeedback.heavyImpact();
        ref.read(appSessionProvider.notifier).setFaceLoginPassed(true);
        Future.delayed(const Duration(milliseconds: 1400), () {
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
      String? diagnosticCode;
      String message = e.toString();
      bool needsEnrollment = false;
      if (e is EdgeFunctionException) {
        diagnosticCode = e.code;
        message = e.originalMessage ?? e.toString();
        if (e.code == 'reference_photo_missing' ||
            e.code == 'missing_biometric_data' ||
            e.code == 'not_enrolled') {
          needsEnrollment = true;
        }
      }

      setState(() {
        _step = FaceVerificationStep.results;
        _lastResult = FaceCheckResult(
          status: FaceCheckStatus.error,
          message: message,
          diagnosticCode: diagnosticCode,
          needsEnrollment: needsEnrollment,
          attemptsCount: _attemptCount,
        );
      });
    }
  }

  void _retryVerification() {
    _timer?.cancel();
    _stopCameraStream();
    setState(() {
      _lastResult = null;
      _timerStarted = false;
      _faceStableFrames = 0;
      _blinkStateMachine.reset();
      _headTurnHoldCount = 0;
      _step = FaceVerificationStep.cameraPrep;
    });
    _initializeCamera();
  }

  void _requestManualReviewAction() {
    final result = _lastResult ??
        FaceCheckResult(
          status: FaceCheckStatus.manualReviewRequired,
          message: 'Manual review requested after repeated verification attempts.',
          fraudFlagCreated: true,
          attemptsCount: _attemptCount,
        );

    ref.read(appSessionProvider.notifier).setFaceLoginPassed(false);
    if (widget.onResult != null) {
      widget.onResult!(result);
    }
    if (context.canPop()) {
      context.pop(result);
    } else {
      context.go(AppRoutes.suspended);
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
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMock = kDebugMode && widget.matcherMode == 'mock';

    return Scaffold(
      backgroundColor: const Color(0xFF050B14), // Deepest midnight navy
      appBar: AppBar(
        backgroundColor: const Color(0xFF050B14),
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
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Context & Stage Progress Header Badge
            _buildTopContextBar(),

            // Main Body for the Current Stage
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    if (_step == FaceVerificationStep.intro)
                      _buildScreen1Intro(l10n)
                    else if (_step == FaceVerificationStep.cameraPrep ||
                        _step == FaceVerificationStep.liveness)
                      _buildScreen2Or3Camera(l10n)
                    else if (_step == FaceVerificationStep.verifying)
                      _buildScreen4Verifying(l10n)
                    else if (_step == FaceVerificationStep.results)
                      _buildScreen5Results(l10n),

                    // Test & Debug controls in mock mode
                    if (isMock) ...[
                      const SizedBox(height: 20),
                      _buildDemoControls(l10n),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopContextBar() {
    String stepLabel;
    switch (_step) {
      case FaceVerificationStep.intro:
        stepLabel = 'Step 1 of 5 • Overview & Consent';
        break;
      case FaceVerificationStep.cameraPrep:
        stepLabel = 'Step 2 of 5 • Camera Preparation';
        break;
      case FaceVerificationStep.liveness:
        stepLabel = 'Step 3 of 5 • Liveness Verification';
        break;
      case FaceVerificationStep.verifying:
        stepLabel = 'Step 4 of 5 • Biometric Match';
        break;
      case FaceVerificationStep.results:
        stepLabel = 'Step 5 of 5 • Verification Result';
        break;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00F2FE).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00F2FE).withValues(alpha: 0.15),
            ),
            child: const Icon(Icons.verified_user_rounded, color: Color(0xFF00F2FE), size: 14),
          ),
          const SizedBox(width: 8),
          Text(
            'Context: ${widget.contextType.toUpperCase()}',
            style: const TextStyle(
              color: Color(0xFF00F2FE),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          Text(
            stepLabel,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 1: VERIFICATION INTRODUCTION & EXPLICIT CONSENT
  // ---------------------------------------------------------------------------
  Widget _buildScreen1Intro(AppLocalizations l10n) {
    return Column(
      children: [
        const SizedBox(height: 10),

        // Glowing concentric biometric ring animation
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final pulse = _pulseController.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outermost resonance aura
                Container(
                  width: 140 + (pulse * 24),
                  height: 140 + (pulse * 24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00F2FE).withValues(alpha: 0.05 + (pulse * 0.04)),
                  ),
                ),
                // Intermediate glow ring
                Container(
                  width: 115 + (pulse * 12),
                  height: 115 + (pulse * 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF10B981).withValues(alpha: 0.10 + (pulse * 0.05)),
                    border: Border.all(
                      color: const Color(0xFF00F2FE).withValues(alpha: 0.25 + (pulse * 0.2)),
                      width: 1.5,
                    ),
                  ),
                ),
                // Core biometric disc
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFF00F2FE), Color(0xFF0A192B)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F2FE).withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.fingerprint_rounded, size: 48, color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 24),

        // Title & Purpose explanation
        const Text(
          'Identity Verification',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.faceCheckSubtext,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 20),

        // Privacy & Storage transparency card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1B2F),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Biometric Privacy & Data Security',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildPrivacyBullet(
                'Instant Liveness Check',
                'Your camera detects natural gestures (e.g. blinking) to ensure live presence.',
              ),
              const SizedBox(height: 8),
              _buildPrivacyBullet(
                'Private Reference Storage',
                'Reference photos are stored in private, isolated vaults — never public or shared.',
              ),
              const SizedBox(height: 8),
              _buildPrivacyBullet(
                'Consent & Revocation',
                'You may withdraw biometric consent and erase data anytime under Privacy Settings.',
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Explicit Consent Checkbox
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _consentCheckbox = !_consentCheckbox;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: _consentCheckbox
                    ? const Color(0xFF00F2FE).withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _consentCheckbox
                      ? const Color(0xFF00F2FE).withValues(alpha: 0.4)
                      : Colors.white12,
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _consentCheckbox,
                    activeColor: const Color(0xFF00F2FE),
                    checkColor: Colors.black,
                    onChanged: (val) {
                      setState(() {
                        _consentCheckbox = val ?? false;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'I explicitly consent to biometric facial verification for secure identity authentication.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Primary Action: Start Verification
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _consentCheckbox ? _onStartVerificationPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F2FE),
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.white12,
              disabledForegroundColor: Colors.white30,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_rounded, size: 20),
                SizedBox(width: 8),
                Text(
                  'Start Verification',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Secondary Action: Cancel
        TextButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop(const FaceCheckResult(status: FaceCheckStatus.cancelled));
            }
          },
          child: const Text(
            'Cancel / Return',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyBullet(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Icon(Icons.check_circle_rounded, color: Color(0xFF00F2FE), size: 13),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 2 & 3: CAMERA PREPARATION & OBSERVATION LIVENESS
  // ---------------------------------------------------------------------------
  Widget _buildScreen2Or3Camera(AppLocalizations l10n) {
    final isLiveness = _step == FaceVerificationStep.liveness;

    Color borderColor = Colors.white30;
    if (_showPassToast) {
      borderColor = const Color(0xFF10B981);
    } else if (_faceDetected && _qualityPassed) {
      borderColor = const Color(0xFF00F2FE);
    } else if (_faceDetected && !_qualityPassed) {
      borderColor = const Color(0xFFF59E0B);
    }

    return Column(
      children: [
        // Camera Oval with Corner Brackets & Sweeping Animated Scan Line
        Center(
          child: SizedBox(
            width: 250,
            height: 320,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Camera live preview with oval clipping
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(125),
                    border: Border.all(color: borderColor, width: 3.5),
                    color: Colors.black,
                    boxShadow: [
                      BoxShadow(
                        color: borderColor.withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(125),
                    child: _isCameraInitializing
                        ? const Center(
                            child: CircularProgressIndicator(color: Color(0xFF00F2FE)),
                          )
                        : _cameraController != null && _cameraController!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: 250 / 320,
                                child: CameraPreview(_cameraController!),
                              )
                            : const Center(
                                child: Icon(Icons.face, size: 90, color: Colors.white24),
                              ),
                  ),
                ),

                // 2. Corner Bracket Guides Painter
                CustomPaint(
                  size: const Size(250, 320),
                  painter: _CornerBracketPainter(color: borderColor),
                ),

                // 3. Sweeping Neon Scan Line
                if (!_isCameraInitializing && _cameraController?.value.isInitialized == true)
                  AnimatedBuilder(
                    animation: _scanLineController,
                    builder: (context, child) {
                      final scanY = _scanLineController.value * 300;
                      return Positioned(
                        top: scanY,
                        child: Container(
                          width: 220,
                          height: 2.5,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                Color(0xFF00F2FE),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00F2FE).withValues(alpha: 0.8),
                                blurRadius: 10,
                                spreadRadius: 1.5,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                // 4. Milestone Toast Overlay on Challenge Pass
                if (_showPassToast)
                  Container(
                    width: 250,
                    height: 320,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(125),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 68, color: Colors.white),
                        SizedBox(height: 8),
                        Text(
                          'Challenge Passed! ✓',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Live Real-Time Instruction Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1B2F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLiveness ? const Color(0xFF00F2FE).withValues(alpha: 0.4) : Colors.white12,
            ),
          ),
          child: Column(
            children: [
              if (isLiveness) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F2FE).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Challenge ${_currentChallengeIndex + 1}/${_challenges.length}',
                        style: const TextStyle(
                          color: Color(0xFF00F2FE),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Icon(
                      Icons.timer_rounded,
                      color: _secondsRemaining < 4 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_secondsRemaining}s',
                      style: TextStyle(
                        color: _secondsRemaining < 4 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Text(
                _currentHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Cancel button during camera
        TextButton(
          onPressed: () {
            _stopCameraStream();
            if (context.canPop()) {
              context.pop(const FaceCheckResult(status: FaceCheckStatus.cancelled));
            }
          },
          child: const Text('Cancel Verification', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 4: DISPATCHING SECURE SERVER VERIFICATION
  // ---------------------------------------------------------------------------
  Widget _buildScreen4Verifying(AppLocalizations l10n) {
    return Column(
      children: [
        const SizedBox(height: 40),

        // Animated Rotating Cybernetic Scanner
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFF0F1B2F),
                    Color(0xFF050B14),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF00F2FE).withValues(alpha: 0.6),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F2FE).withValues(alpha: 0.25),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: Color(0xFF00F2FE),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 32),

        const Text(
          'Verifying Face Identity',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Matching captured biometric selfie with your securely enrolled reference photo via encrypted server endpoint...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 5: 7 DEDICATED ANIMATED RESULT STATES
  // ---------------------------------------------------------------------------
  Widget _buildScreen5Results(AppLocalizations l10n) {
    final result = _lastResult;

    // State 1: Verified Success
    if (result?.status == FaceCheckStatus.pass) {
      return _buildResultCard(
        accentColor: const Color(0xFF10B981),
        icon: Icons.check_circle_rounded,
        title: l10n.faceMatchSuccess,
        subtitle: result?.message ?? 'Face identity verified successfully against enrolled profile.',
        badge: result?.matchScore != null
            ? 'Match Score: ${result!.matchScore!.toStringAsFixed(1)}%'
            : 'Similarity Verified',
        primaryActionText: 'Continue',
        onPrimaryAction: () {
          if (context.canPop()) {
            context.pop(result);
          } else {
            final activeRole = ref.read(appSessionProvider).activeRole;
            context.go(AppSessionNotifier.getHomeForRole(activeRole));
          }
        },
      );
    }

    // State 7: Manual Security Review Required (after 3 consecutive fails)
    if (result?.status == FaceCheckStatus.manualReviewRequired || _attemptCount >= 3) {
      return _buildResultCard(
        accentColor: const Color(0xFFDC2626),
        icon: Icons.shield_outlined,
        title: l10n.manualReviewRequiredTitle,
        subtitle: result?.message ?? l10n.manualReviewRequiredBody,
        badge: 'Security Review Required',
        primaryActionText: l10n.requestManualReview,
        onPrimaryAction: _requestManualReviewAction,
        secondaryActionText: 'Close',
        onSecondaryAction: () => context.pop(result),
      );
    }

    // State 4: Enrollment Required (No reference photo found)
    if (result?.needsEnrollment == true || result?.diagnosticCode == 'reference_photo_missing') {
      return _buildResultCard(
        accentColor: const Color(0xFF8B5CF6),
        icon: Icons.person_add_alt_1_rounded,
        title: 'Face Profile Not Enrolled',
        subtitle: 'No enrolled biometric reference was found for your account. Please complete face profile enrollment first.',
        badge: 'Enrollment Needed',
        primaryActionText: 'Enroll Face Profile Now',
        onPrimaryAction: () {
          context.push(AppRoutes.kycFace);
        },
        secondaryActionText: 'Cancel',
        onSecondaryAction: () => context.pop(result),
      );
    }

    // State 5: Camera Permission Denied
    if (_cameraPermissionDenied) {
      return _buildResultCard(
        accentColor: const Color(0xFFEF4444),
        icon: Icons.camera_alt_outlined,
        title: 'Camera Permission Denied',
        subtitle: 'Camera access is required to capture live verification images. Please open settings to grant permission.',
        badge: 'Permission Denied',
        primaryActionText: 'Open App Settings',
        onPrimaryAction: () => openAppSettings(),
        secondaryActionText: 'Cancel',
        onSecondaryAction: () => context.pop(result),
      );
    }

    // State 6: Service or Provider Unavailable
    if (result?.status == FaceCheckStatus.error) {
      return _buildResultCard(
        accentColor: const Color(0xFF64748B),
        icon: Icons.cloud_off_rounded,
        title: 'Verification Service Notice',
        subtitle: result?.message ?? 'Biometric verification service is temporarily unreachable. Please retry.',
        badge: 'Cloud Service Notice',
        primaryActionText: l10n.retryVerification,
        onPrimaryAction: _retryVerification,
        secondaryActionText: 'Cancel',
        onSecondaryAction: () => context.pop(result),
      );
    }

    // State 2 & 3: Face Mismatch / Liveness Failed
    return _buildResultCard(
      accentColor: const Color(0xFFF59E0B),
      icon: Icons.error_outline_rounded,
      title: l10n.faceMatchFailedTitle,
      subtitle: result?.message ?? l10n.faceMatchFailedBody,
      badge: 'Attempt $_attemptCount of 3',
      primaryActionText: l10n.retryVerification,
      onPrimaryAction: _retryVerification,
      secondaryActionText: 'Cancel',
      onSecondaryAction: () => context.pop(result),
    );
  }

  Widget _buildResultCard({
    required Color accentColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required String primaryActionText,
    required VoidCallback onPrimaryAction,
    String? secondaryActionText,
    VoidCallback? onSecondaryAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B2F),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.15),
            ),
            child: Icon(icon, size: 52, color: accentColor),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onPrimaryAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                primaryActionText,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (secondaryActionText != null && onSecondaryAction != null) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: onSecondaryAction,
              child: Text(secondaryActionText, style: const TextStyle(color: Colors.white54)),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DEMO MODE TESTING CONTROLS (Debug Mode Only)
  // ---------------------------------------------------------------------------
  Widget _buildDemoControls(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
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
                    backgroundColor: const Color(0xFF10B981),
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
                    backgroundColor: const Color(0xFFEF4444),
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

/// Custom painter for tech-inspired corner brackets around the face oval guide.
class _CornerBracketPainter extends CustomPainter {
  final Color color;

  const _CornerBracketPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const armLen = 22.0;
    const margin = 10.0;

    // Top-Left
    canvas.drawLine(const Offset(margin, margin), const Offset(margin + armLen, margin), paint);
    canvas.drawLine(const Offset(margin, margin), const Offset(margin, margin + armLen), paint);

    // Top-Right
    canvas.drawLine(Offset(size.width - margin, margin), Offset(size.width - margin - armLen, margin), paint);
    canvas.drawLine(Offset(size.width - margin, margin), Offset(size.width - margin, margin + armLen), paint);

    // Bottom-Left
    canvas.drawLine(Offset(margin, size.height - margin), Offset(margin + armLen, size.height - margin), paint);
    canvas.drawLine(Offset(margin, size.height - margin), Offset(margin, size.height - margin - armLen), paint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width - margin, size.height - margin), Offset(size.width - margin - armLen, size.height - margin), paint);
    canvas.drawLine(Offset(size.width - margin, size.height - margin), Offset(size.width - margin, size.height - margin - armLen), paint);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) => oldDelegate.color != color;
}
