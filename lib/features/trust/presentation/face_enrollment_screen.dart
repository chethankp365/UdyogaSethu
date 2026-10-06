import 'dart:async';
import 'dart:io';
import 'dart:math';
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

  CameraController? _cameraController;
  CameraDescription? _frontCamera;
  FaceDetector? _faceDetector;

  bool _isCameraInitializing = true;
  bool _cameraPermissionDenied = false;
  String? _cameraError;

  bool _isProcessingFrame = false;
  bool _isSubmitting = false;
  bool _isEnrolled = false;
  bool _isTimedOut = false;

  bool _faceDetected = false;
  bool _qualityPassed = false;

  List<LivenessChallenge> _challenges = [];
  int _currentChallengeIndex = 0;
  int _secondsRemaining = LivenessThresholds.challengeTimeoutSeconds;
  Timer? _timer;

  String _currentHint = 'Position face inside the oval frame';
  final BlinkStateMachine _blinkStateMachine = BlinkStateMachine();
  int _headTurnHoldCount = 0;

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
      await _initializeCameraAndDetector();
    } else {
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

    if (granted) {
      await _initializeCameraAndDetector();
    }
  }

  Future<void> _initializeCameraAndDetector() async {
    if (!_hasFaceConsent) return;

    setState(() {
      _isCameraInitializing = true;
      _cameraPermissionDenied = false;
      _cameraError = null;
      _isTimedOut = false;
      _isEnrolled = false;
      _faceDetected = false;
      _qualityPassed = false;
      _currentChallengeIndex = 0;
      _secondsRemaining = LivenessThresholds.challengeTimeoutSeconds;
      _currentHint = 'Initializing camera preview...';
      _blinkStateMachine.reset();
      _headTurnHoldCount = 0;
    });

    try {
      final status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        if (!mounted) return;
        setState(() {
          _isCameraInitializing = false;
          _cameraPermissionDenied = true;
          _currentHint = 'Camera permission required';
        });
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isCameraInitializing = false;
          _cameraError = 'No camera device found on this device';
          _currentHint = 'No camera found';
        });
        return;
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

      // Instantiate ML Kit Face Detector with fast performance mode for real-time camera stream
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          enableLandmarks: true,
          enableTracking: true,
          performanceMode: FaceDetectorMode.fast,
          minFaceSize: 0.15,
        ),
      );

      await ref.read(faceEmbeddingServiceProvider).initialize();

      _challenges = LivenessChallenge.generateSequence(count: 2);

      if (!mounted) return;
      setState(() {
        _isCameraInitializing = false;
        _currentHint = 'Position face inside the oval frame';
      });

      await _cameraController!.startImageStream(_processCameraFrame);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCameraInitializing = false;
        _cameraError = 'Failed to initialize camera: $e';
        _currentHint = 'Camera initialization failed';
      });
    }
  }

  Future<void> _stopCameraStream() async {
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      try {
        await _cameraController!.stopImageStream();
      } catch (_) {}
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsRemaining = LivenessThresholds.challengeTimeoutSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0 && !_isEnrolled && !_isSubmitting && !_isTimedOut) {
        setState(() {
          _secondsRemaining--;
        });
      } else if (_secondsRemaining == 0 && !_isEnrolled && !_isSubmitting) {
        _timer?.cancel();
        _stopCameraStream();
        setState(() {
          _isTimedOut = true;
          _currentHint = 'Challenge timed out! Tap Reset to try again.';
        });
      }
    });
  }

  InputImage? _buildInputImage(CameraImage image) {
    if (_frontCamera == null) return null;

    final sensorOrientation = _frontCamera!.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isAndroid) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    }
    rotation ??= InputImageRotation.rotation0deg;

    final format = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: metadata,
    );
  }

  Future<void> _processCameraFrame(CameraImage image) async {
    if (_isProcessingFrame ||
        _isEnrolled ||
        _isSubmitting ||
        _isTimedOut ||
        _faceDetector == null ||
        !mounted) {
      return;
    }

    _isProcessingFrame = true;

    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) {
        _isProcessingFrame = false;
        return;
      }

      final faces = await _faceDetector!.processImage(inputImage);

      if (!mounted) {
        _isProcessingFrame = false;
        return;
      }

      final qualityResult = FaceQualityGates.evaluate(
        faceCount: faces.length,
        boundingBox: faces.isEmpty ? null : faces.first.boundingBox,
        screenSize: Size(image.width.toDouble(), image.height.toDouble()),
        leftEyeOpenProb: faces.isEmpty ? null : faces.first.leftEyeOpenProbability,
        rightEyeOpenProb: faces.isEmpty ? null : faces.first.rightEyeOpenProbability,
        headEulerAngleY: faces.isEmpty ? null : faces.first.headEulerAngleY,
        headEulerAngleZ: faces.isEmpty ? null : faces.first.headEulerAngleZ,
      );

      if (!qualityResult.isValid) {
        setState(() {
          _qualityPassed = false;
          _currentHint = qualityResult.hint;
        });
        _isProcessingFrame = false;
        return;
      }

      final face = faces.first;

      if (!_faceDetected) {
        setState(() {
          _faceDetected = true;
          _qualityPassed = true;
        });
        _startTimer();
      } else {
        setState(() {
          _qualityPassed = true;
        });
      }

      if (_currentChallengeIndex < _challenges.length) {
        final currentChallenge = _challenges[_currentChallengeIndex];
        bool challengePassed = false;

        switch (currentChallenge.type) {
          case LivenessChallengeType.blink:
            challengePassed = _blinkStateMachine.processFrame(
              face.leftEyeOpenProbability,
              face.rightEyeOpenProbability,
            );
            break;

          case LivenessChallengeType.turnRight:
            final eulerY = face.headEulerAngleY ?? 0.0;
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
            final eulerY = face.headEulerAngleY ?? 0.0;
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
            final smileProb = face.smilingProbability ?? 0.0;
            if (smileProb >= LivenessThresholds.smileThreshold) {
              challengePassed = true;
            }
            break;
        }

        if (challengePassed) {
          currentChallenge.isCompleted = true;
          _currentChallengeIndex++;

          if (_currentChallengeIndex < _challenges.length) {
            setState(() {
              _currentHint = 'Great! Next: ${_challenges[_currentChallengeIndex].label}';
              _blinkStateMachine.reset();
              _headTurnHoldCount = 0;
              _secondsRemaining = LivenessThresholds.challengeTimeoutSeconds;
            });
          } else {
            await _handleEnrolmentSuccess(image);
          }
        } else {
          setState(() {
            _currentHint = currentChallenge.label;
          });
        }
      }
    } catch (e) {
      debugPrint('[FaceEnrollmentScreen] Error processing frame: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  Future<void> _handleEnrolmentSuccess(CameraImage cameraImage) async {
    _timer?.cancel();
    setState(() {
      _isSubmitting = true;
      _currentHint = 'Hold still! Capturing high-quality reference photo...';
    });

    await Future.delayed(const Duration(milliseconds: 300));
    await _stopCameraStream();

    try {
      Uint8List photoBytes;
      List<double> embedding;

      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final XFile file = await _cameraController!.takePicture();
        photoBytes = await file.readAsBytes();

        final embeddingService = ref.read(faceEmbeddingServiceProvider);
        await embeddingService.initialize();

        if (widget.matcherMode == 'mock' && kDebugMode) {
          embedding = FaceEmbeddingService.generateMockVector();
        } else {
          embedding = await embeddingService.extractEmbeddingFromPhoto(
            photoFile: File(file.path),
            faceDetector: _faceDetector!,
          );
        }
      } else {
        throw Exception('Camera is not active for enrollment photo capture.');
      }

      final kycRepo = ref.read(kycRepositoryProvider);
      final challengeNames = _challenges.map((c) => c.type.name).toList();

      await kycRepo.enrollFace(
        embedding: embedding,
        livenessPassed: true,
        challenges: challengeNames,
        photoBytes: photoBytes,
      );

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _isEnrolled = true;
        _currentHint = 'Face Enrolment Successful!';
      });

      ref.read(appSessionProvider.notifier).setHasEnrolledFace(true);

      final session = ref.read(appSessionProvider);
      if (session.faceRequiredAtLogin && !session.faceLoginPassed) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            context.go(AppRoutes.kycFaceCheck, extra: {'context': 'login'});
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _cameraError = 'Enrolment submission failed: $e';
        _currentHint = 'Submission failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMock = kDebugMode && widget.matcherMode == 'mock';

    return Scaffold(
      backgroundColor: AppColors.navyBackground,
      appBar: AppBar(
        title: const Text('Face Enrolment & Liveness', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.navyBackground,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.security_rounded, color: Colors.white70),
            tooltip: 'Trust & Safety Centre',
            onPressed: () => context.push(AppRoutes.trustSafetyCentre),
          ),
        ],
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
                      'Your facial features are converted into a private 128-dimensional embedding vector. Raw photos are never stored publicly.',
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
                    Center(
                      child: Container(
                        width: 260,
                        height: 340,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(170),
                          border: Border.all(
                            color: _isEnrolled
                                ? AppColors.emerald
                                : (_isTimedOut || _cameraError != null
                                    ? Colors.redAccent
                                    : (_qualityPassed ? Colors.cyanAccent : Colors.amber)),
                            width: 3.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(170),
                          child: _buildCameraOverlay(),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              !_faceDetected
                                  ? 'Waiting for face...'
                                  : 'Time Remaining: ${_secondsRemaining}s',
                              style: TextStyle(
                                color: _secondsRemaining <= 4 && _faceDetected
                                    ? Colors.redAccent
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Challenge ${min(_currentChallengeIndex + 1, _challenges.length)}/${_challenges.length}',
                              style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),

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
                            if (_currentChallengeIndex < _challenges.length && !_isEnrolled && !_isTimedOut)
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
                      onPressed: _initializeCameraAndDetector,
                      child: const Text('Reset / Retry', style: TextStyle(color: Colors.white70)),
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
                          : (_isSubmitting ? null : _initializeCameraAndDetector),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              _isEnrolled ? 'Done & Return' : 'Retry Challenges',
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

  Widget _buildCameraOverlay() {
    if (_isCameraInitializing) {
      return Container(
        color: Colors.black45,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.emerald),
            SizedBox(height: 12),
            Text('Initializing Camera...', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      );
    }

    if (_cameraPermissionDenied) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black87,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_photography_outlined, color: Colors.redAccent, size: 48),
            const SizedBox(height: 8),
            const Text(
              'Camera Access Denied',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              'Camera permission is required to detect face liveness.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.amberOrange),
              icon: const Icon(Icons.settings, color: Colors.white, size: 18),
              label: const Text('Open Settings', style: TextStyle(color: Colors.white, fontSize: 12)),
              onPressed: () => openAppSettings(),
            ),
          ],
        ),
      );
    }

    if (_cameraError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black87,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 8),
            Text(
              _cameraError!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
              onPressed: _initializeCameraAndDetector,
              child: const Text('Retry Camera', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_isEnrolled) {
      return Container(
        color: Colors.black54,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.emerald, size: 64),
            SizedBox(height: 8),
            Text('Enrolled!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      );
    }

    if (_cameraController != null && _cameraController!.value.isInitialized) {
      return CameraPreview(_cameraController!);
    }

    return Container(
      color: Colors.black54,
      child: const Center(
        child: Text('Position Face Here', style: TextStyle(color: Colors.white70)),
      ),
    );
  }
}
