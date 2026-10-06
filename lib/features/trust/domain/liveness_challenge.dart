import 'dart:math';

class LivenessThresholds {
  LivenessThresholds._();

  /// Eye open probability threshold to register eyes as open (>= 0.55)
  static const double blinkOpenThreshold = 0.55;

  /// Eye open probability threshold to register eyes as closed (<= 0.35)
  static const double blinkClosedThreshold = 0.35;

  /// Head turn angle threshold in degrees (15.0 deg)
  static const double headTurnAngleDeg = 15.0;

  /// Minimum consecutive frames required to hold a head turn
  static const int headTurnHoldFrames = 2;

  /// Smiling probability threshold (>= 0.65)
  static const double smileThreshold = 0.65;

  /// Time limit per challenge in seconds (9 s)
  static const int challengeTimeoutSeconds = 9;
}

enum LivenessChallengeType {
  blink,
  turnLeft,
  turnRight,
  smile,
}

enum BlinkState {
  idle,
  eyesOpen,
  eyesClosed,
  completed,
}

class BlinkStateMachine {
  BlinkState _state = BlinkState.idle;
  DateTime? _openTimestamp;

  BlinkState get state => _state;
  bool get isCompleted => _state == BlinkState.completed;

  void reset() {
    _state = BlinkState.idle;
    _openTimestamp = null;
  }

  /// Processes a frame with eye-open probabilities.
  /// Ignores frames where left or right probability is null.
  /// Returns true if the blink gesture is completed on this frame.
  bool processFrame(double? leftEyeOpenProb, double? rightEyeOpenProb) {
    if (leftEyeOpenProb == null || rightEyeOpenProb == null) {
      return isCompleted;
    }

    final avgOpen = (leftEyeOpenProb + rightEyeOpenProb) / 2.0;

    switch (_state) {
      case BlinkState.idle:
      case BlinkState.completed:
        if (avgOpen >= LivenessThresholds.blinkOpenThreshold) {
          _state = BlinkState.eyesOpen;
          _openTimestamp = DateTime.now();
        }
        break;

      case BlinkState.eyesOpen:
        if (avgOpen <= LivenessThresholds.blinkClosedThreshold) {
          _state = BlinkState.eyesClosed;
        } else {
          if (_openTimestamp != null &&
              DateTime.now().difference(_openTimestamp!).inMilliseconds > 3000) {
            _openTimestamp = DateTime.now();
          }
        }
        break;

      case BlinkState.eyesClosed:
        if (avgOpen >= LivenessThresholds.blinkOpenThreshold) {
          _state = BlinkState.completed;
          return true;
        }
        break;
    }

    return isCompleted;
  }
}

class LivenessChallenge {
  final LivenessChallengeType type;
  bool isCompleted;

  LivenessChallenge({
    required this.type,
    this.isCompleted = false,
  });

  String get label {
    switch (type) {
      case LivenessChallengeType.blink:
        return 'Blink your eyes naturally';
      case LivenessChallengeType.turnLeft:
        return 'Turn your head to YOUR left';
      case LivenessChallengeType.turnRight:
        return 'Turn your head to YOUR right';
      case LivenessChallengeType.smile:
        return 'Smile warmly at the camera';
    }
  }

  static List<LivenessChallenge> generateSequence({int count = 1}) {
    final types = List<LivenessChallengeType>.from(LivenessChallengeType.values)..shuffle(Random());
    return types.take(count).map((t) => LivenessChallenge(type: t)).toList();
  }

  static List<LivenessChallenge> generateRandomPair() {
    return generateSequence(count: 2);
  }
}
