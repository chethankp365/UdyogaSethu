import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';

/// Redesigned Full-screen Brand Intro Screen (White background) featuring "The Bridge Connects":
/// - 0.0 - 0.8s: Soft green hill (village) & city skyline pop-up + location pin drop/bounce.
/// - 0.8 - 2.0s: Orange bridge arc drawing stroke by stroke with glowing tip & gliding trade icon stream.
/// - 2.0s: Bridge connects, ring pulse spreads out, skyline fades, logo pops in with squash-and-stretch + shimmer, TTS "Welcome to UdyogaSethu" starts.
/// - 2.0 - 3.2s: Confetti sparks burst, tagline "Bridging Work. Empowering Lives." slides up word-by-word.
/// - 3.2 - 4.0s: Hold still and navigate to boot splash.
class BrandIntroScreen extends ConsumerStatefulWidget {
  const BrandIntroScreen({super.key});

  /// In-memory flag tracking if brand intro has been completed during current cold-start session.
  static bool isCompleted = false;

  /// In-memory debug counters to empirically verify stability.
  static int debugInitStateCount = 0;
  static int debugDisposeCount = 0;
  static int debugBuildCount = 0;
  static int debugControllerCreatedCount = 0;
  static int debugSpeakCount = 0;

  /// Static flag ensuring English TTS welcome is spoken at most once per cold start.
  static bool _hasSpokenEnglishWelcome = false;

  /// Resets cold start state flags for testing or fresh app restarts.
  static void resetColdStartFlags() {
    isCompleted = false;
    _hasSpokenEnglishWelcome = false;
    debugInitStateCount = 0;
    debugDisposeCount = 0;
    debugBuildCount = 0;
    debugControllerCreatedCount = 0;
    debugSpeakCount = 0;
  }

  @override
  ConsumerState<BrandIntroScreen> createState() => _BrandIntroScreenState();
}

class _BrandIntroScreenState extends ConsumerState<BrandIntroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  // Phase Animations
  late Animation<double> _popUpProgress;     // 0.0 - 0.8s
  late Animation<double> _pinDropProgress;    // 0.2 - 0.8s
  late Animation<double> _bridgeArcProgress;  // 0.8 - 2.0s
  late Animation<double> _ringPulseScale;    // 2.0 - 2.8s
  late Animation<double> _ringPulseOpacity;  // 2.0 - 2.8s
  late Animation<double> _landscapeFade;     // 2.0 - 2.5s
  late Animation<double> _logoScale;         // 1.9 - 2.5s (Squash & Stretch)
  late Animation<double> _logoOpacity;       // 1.9 - 2.4s
  late Animation<double> _shimmerProgress;   // 2.2 - 2.8s
  late Animation<double> _confettiProgress;  // 2.0 - 3.2s
  late Animation<double> _taglineSlide;      // 2.2 - 3.0s
  late Animation<double> _taglineOpacity;    // 2.2 - 2.9s

  final FlutterTts _flutterTts = FlutterTts();
  Timer? _speechTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    BrandIntroScreen.debugInitStateCount++;
    BrandIntroScreen.debugControllerCreatedCount++;

    if (kDebugMode) {
      AppLogger.i(
        'BrandIntroScreen.initState (Count: ${BrandIntroScreen.debugInitStateCount}, '
        'Controllers: ${BrandIntroScreen.debugControllerCreatedCount})',
      );
    }

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // 1. Pop-Up Landscape (0.0 to 0.8s = 0.0 to 0.20)
    _popUpProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.20, curve: Curves.easeOutBack),
      ),
    );

    // 2. Pin Drop & Bounce (0.2 to 0.8s = 0.05 to 0.20)
    _pinDropProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.05, 0.20, curve: Curves.bounceOut),
      ),
    );

    // 3. Orange Bridge Arc Draw (0.8 to 2.0s = 0.20 to 0.50)
    _bridgeArcProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.20, 0.50, curve: Curves.easeInOutCubic),
      ),
    );

    // 4. Ring Pulse & Landscape Fade (2.0s = 0.50)
    _ringPulseScale = Tween<double>(begin: 0.2, end: 2.2).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.48, 0.70, curve: Curves.easeOutQuad),
      ),
    );

    _ringPulseOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.48, 0.70, curve: Curves.easeOut),
      ),
    );

    _landscapeFade = Tween<double>(begin: 1.0, end: 0.15).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.50, 0.65, curve: Curves.easeInOut),
      ),
    );

    // 5. Elastic Logo Pop (1.9 to 2.5s = 0.48 to 0.625)
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.48, 0.63, curve: Curves.elasticOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.48, 0.58, curve: Curves.easeIn),
      ),
    );

    // 6. Shimmer Sweep (2.2 to 2.8s = 0.55 to 0.70)
    _shimmerProgress = Tween<double>(begin: -0.5, end: 1.5).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.55, 0.70, curve: Curves.easeInOut),
      ),
    );

    // 7. Confetti Burst (2.0 to 3.2s = 0.50 to 0.80)
    _confettiProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.50, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    // 8. Tagline Slide & Fade (2.2 to 3.0s = 0.55 to 0.75)
    _taglineSlide = Tween<double>(begin: 25.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.55, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.55, 0.72, curve: Curves.easeIn),
      ),
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _goToBootSplash();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startIntroSequence();
    });
  }

  void _startIntroSequence() {
    if (!mounted) return;
    final media = MediaQuery.maybeOf(context);
    final isReducedMotion = media?.disableAnimations == true || media?.accessibleNavigation == true;

    if (isReducedMotion) {
      _animController.value = 1.0;
      _triggerTtsOnce();
      _goToBootSplash();
    } else {
      _animController.forward();
      // Trigger TTS welcome at ~800ms into intro animation sequence
      _speechTimer = Timer(const Duration(milliseconds: 800), () {
        _triggerTtsOnce();
      });
    }
  }

  Future<void> _triggerTtsOnce() async {
    if (BrandIntroScreen._hasSpokenEnglishWelcome || !mounted) return;
    BrandIntroScreen._hasSpokenEnglishWelcome = true;
    BrandIntroScreen.debugSpeakCount++;

    if (kDebugMode) {
      AppLogger.i('BrandIntroScreen.speak (SpeakCount: ${BrandIntroScreen.debugSpeakCount})');
    }

    try {
      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.speak('Welcome to UdyogaSethu');
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w('BrandIntroScreen TTS silent failure: $e');
      }
    }
  }

  void _skipAndGoToSplash() {
    if (kDebugMode) {
      AppLogger.i('BrandIntroScreen user tap-skip triggered');
    }
    _goToBootSplash();
  }

  void _goToBootSplash() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    BrandIntroScreen.isCompleted = true;
    _silenceTts();
    context.go(AppRoutes.splash);
  }

  void _silenceTts() {
    _speechTimer?.cancel();
    try {
      _flutterTts.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    BrandIntroScreen.debugDisposeCount++;
    if (kDebugMode) {
      AppLogger.i('BrandIntroScreen.dispose (DisposeCount: ${BrandIntroScreen.debugDisposeCount})');
    }
    _silenceTts();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    BrandIntroScreen.debugBuildCount++;
    if (kDebugMode) {
      AppLogger.d('BrandIntroScreen.build (BuildCount: ${BrandIntroScreen.debugBuildCount})');
    }

    return GestureDetector(
      onTap: _skipAndGoToSplash,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // 1. Pop-Up Village Hill & City Skyline (Background elements on white)
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _landscapeFade.value,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _PopUpLandscapePainter(
                        progress: _popUpProgress.value,
                      ),
                    ),
                  );
                },
              ),
            ),

            // 2. Orange Pin Drop in Gap
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _pinDropProgress,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _PinDropPainter(
                      progress: _pinDropProgress.value,
                    ),
                  );
                },
              ),
            ),

            // 3. Orange Bridge Arc Draw & Icon Stream
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _bridgeArcProgress,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _BridgeArcAndIconStreamPainter(
                      progress: _bridgeArcProgress.value,
                    ),
                  );
                },
              ),
            ),

            // 4. Connecting Ring Pulse Aura
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  if (_ringPulseOpacity.value <= 0.01) return const SizedBox.shrink();
                  return Center(
                    child: Transform.scale(
                      scale: _ringPulseScale.value,
                      child: Opacity(
                        opacity: _ringPulseOpacity.value,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.amberOrange.withValues(alpha: 0.6),
                              width: 3.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.amberOrange.withValues(alpha: 0.25),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 5. Confetti Sparks Burst
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _confettiProgress,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _ConfettiSparksPainter(
                      progress: _confettiProgress.value,
                    ),
                  );
                },
              ),
            ),

            // 6. Main Center Logo & Shimmer Stack
            Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _logoScale.value,
                            child: Opacity(
                              opacity: _logoOpacity.value,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/logo.png',
                                    height: 120,
                                    fit: BoxFit.contain,
                                  ),
                                  // Light Shimmer Sweep
                                  CustomPaint(
                                    size: const Size(130, 120),
                                    painter: _ShimmerSweepPainter(
                                      progress: _shimmerProgress.value,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 7. Tagline Slide & Fade-In (Word-by-word slide look)
                    RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _taglineSlide.value),
                            child: Opacity(
                              opacity: _taglineOpacity.value,
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Bridging Work. ',
                                      style: AppTypography.displayMedium(AppColors.headerGreenDark).copyWith(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Empowering Lives.',
                                      style: AppTypography.displayMedium(AppColors.amberOrange).copyWith(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 8. Bottom Tap-to-Skip Hint
            Positioned(
              bottom: 36,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _taglineOpacity,
                builder: (context, child) {
                  return Opacity(
                    opacity: _taglineOpacity.value * 0.7,
                    child: Text(
                      'Tap anywhere to skip',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall(AppColors.textMuted).copyWith(
                        letterSpacing: 0.5,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for village hill (left) and city skyline (right) pop-up.
class _PopUpLandscapePainter extends CustomPainter {
  final double progress;

  _PopUpLandscapePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final baseY = size.height * 0.65;

    // 1. Soft Green Village Hill (Left)
    final hillPaint = Paint()
      ..color = AppColors.headerGreenDark.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final hillPath = Path()
      ..moveTo(0, baseY)
      ..quadraticBezierTo(
        size.width * 0.2,
        baseY - (60 * progress),
        size.width * 0.4,
        baseY,
      )
      ..lineTo(0, baseY)
      ..close();

    canvas.drawPath(hillPath, hillPaint);

    // 2. Slim City Blocks Skyline (Right)
    final cityPaint = Paint()
      ..color = AppColors.navyBackground.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final blockWidth = size.width * 0.06;
    final startX = size.width * 0.6;

    final heights = [50.0, 75.0, 40.0, 90.0, 60.0];
    for (int i = 0; i < heights.length; i++) {
      final x = startX + (i * (blockWidth + 6));
      final h = heights[i] * progress;
      final rect = Rect.fromLTWH(x, baseY - h, blockWidth, h);
      canvas.drawRect(rect, cityPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PopUpLandscapePainter oldDelegate) => oldDelegate.progress != progress;
}

/// Custom painter for orange location pin drop and bounce in the gap.
class _PinDropPainter extends CustomPainter {
  final double progress;

  _PinDropPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final targetX = size.width * 0.5;
    final startY = size.height * 0.2;
    final endY = size.height * 0.62;

    final currentY = startY + (endY - startY) * progress;

    final pinPaint = Paint()
      ..color = AppColors.amberOrange
      ..style = PaintingStyle.fill;

    // Pin circle
    canvas.drawCircle(Offset(targetX, currentY - 8), 7, pinPaint);
    // Pin tip triangle
    final path = Path()
      ..moveTo(targetX - 6, currentY - 6)
      ..lineTo(targetX + 6, currentY - 6)
      ..lineTo(targetX, currentY + 4)
      ..close();
    canvas.drawPath(path, pinPaint);

    // Inner white dot
    canvas.drawCircle(Offset(targetX, currentY - 8), 2.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _PinDropPainter oldDelegate) => oldDelegate.progress != progress;
}

/// Custom painter for orange bridge arc drawing stroke-by-stroke with glowing tip & icon stream.
class _BridgeArcAndIconStreamPainter extends CustomPainter {
  final double progress;

  _BridgeArcAndIconStreamPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final startPoint = Offset(size.width * 0.15, size.height * 0.65);
    final controlPoint = Offset(size.width * 0.5, size.height * 0.42);
    final endPoint = Offset(size.width * 0.85, size.height * 0.65);

    final path = Path()
      ..moveTo(startPoint.dx, startPoint.dy)
      ..quadraticBezierTo(controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      final currentLength = metric.length * progress;
      final extractPath = metric.extractPath(0.0, currentLength);

      // Arc stroke
      final arcPaint = Paint()
        ..color = AppColors.amberOrange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(extractPath, arcPaint);

      // Glowing tip
      if (progress < 1.0) {
        final tangent = metric.getTangentForOffset(currentLength);
        if (tangent != null) {
          final tipPaint = Paint()
            ..color = AppColors.amberOrange
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6);
          canvas.drawCircle(tangent.position, 6, tipPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BridgeArcAndIconStreamPainter oldDelegate) => oldDelegate.progress != progress;
}

/// Custom painter for green and orange confetti sparks bursting once.
class _ConfettiSparksPainter extends CustomPainter {
  final double progress;

  _ConfettiSparksPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.0) return;

    final centerX = size.width * 0.5;
    final centerY = size.height * 0.5;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * math.pi * 2;
      final distance = progress * (60 + (i % 4) * 20);
      final x = centerX + math.cos(angle) * distance;
      final y = centerY + math.sin(angle) * distance;

      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      paint.color = (i % 2 == 0 ? AppColors.headerGreenDark : AppColors.amberOrange).withValues(alpha: opacity);

      canvas.drawCircle(Offset(x, y), 2.5 + (i % 3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiSparksPainter oldDelegate) => oldDelegate.progress != progress;
}

/// Custom painter sweeping translucent light shimmer across the logo.
class _ShimmerSweepPainter extends CustomPainter {
  final double progress;

  _ShimmerSweepPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.0) return;

    final x = size.width * progress;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.45),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(x - 30, 0, 60, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerSweepPainter oldDelegate) => oldDelegate.progress != progress;
}
