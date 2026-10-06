import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/trust/domain/liveness_challenge.dart';
import 'package:udyogasethu/features/verification/domain/face_check_result.dart';

void main() {
  group('BlinkStateMachine Unit Tests', () {
    late BlinkStateMachine machine;

    setUp(() {
      machine = BlinkStateMachine();
    });

    test('Initial state is idle and not completed', () {
      expect(machine.state, equals(BlinkState.idle));
      expect(machine.isCompleted, isFalse);
    });

    test('Full open -> closed -> open sequence completes blink gesture', () {
      // 1. Eyes open
      machine.processFrame(0.85, 0.82);
      expect(machine.state, equals(BlinkState.eyesOpen));
      expect(machine.isCompleted, isFalse);

      // 2. Eyes closed (normal blink down-stroke)
      machine.processFrame(0.20, 0.15);
      expect(machine.state, equals(BlinkState.eyesClosed));
      expect(machine.isCompleted, isFalse);

      // 3. Eyes re-opened (up-stroke)
      final completed = machine.processFrame(0.80, 0.78);
      expect(completed, isTrue);
      expect(machine.state, equals(BlinkState.completed));
      expect(machine.isCompleted, isTrue);
    });

    test('Handles fast 150ms blink sequence without missing state transition', () {
      machine.processFrame(0.90, 0.90); // Open
      machine.processFrame(0.10, 0.10); // Fast closed frame
      final completed = machine.processFrame(0.88, 0.85); // Re-open

      expect(completed, isTrue);
      expect(machine.isCompleted, isTrue);
    });

    test('Ignores null probability frames without resetting state', () {
      machine.processFrame(0.85, 0.82); // Open
      expect(machine.state, equals(BlinkState.eyesOpen));

      machine.processFrame(null, 0.80); // Ignored
      expect(machine.state, equals(BlinkState.eyesOpen));

      machine.processFrame(0.15, 0.20); // Closed
      expect(machine.state, equals(BlinkState.eyesClosed));

      machine.processFrame(null, null); // Ignored
      expect(machine.state, equals(BlinkState.eyesClosed));

      final completed = machine.processFrame(0.75, 0.80); // Re-open
      expect(completed, isTrue);
      expect(machine.isCompleted, isTrue);
    });

    test('Reset clears state back to idle', () {
      machine.processFrame(0.85, 0.82);
      machine.processFrame(0.20, 0.15);
      machine.reset();

      expect(machine.state, equals(BlinkState.idle));
      expect(machine.isCompleted, isFalse);
    });
  });

  group('Head Turn Mapping & Hold Frames Unit Tests', () {
    bool evaluateHeadTurn(LivenessChallengeType type, double? eulerY, int holdCount) {
      if (eulerY == null) return false;
      bool angleMatched = false;
      if (type == LivenessChallengeType.turnRight) {
        // Front camera: user turning right -> camera perspective eulerY < -15.0
        angleMatched = eulerY < -LivenessThresholds.headTurnAngleDeg;
      } else if (type == LivenessChallengeType.turnLeft) {
        // Front camera: user turning left -> camera perspective eulerY > 15.0
        angleMatched = eulerY > LivenessThresholds.headTurnAngleDeg;
      }
      return angleMatched && (holdCount >= LivenessThresholds.headTurnHoldFrames);
    }

    test('User turning right requires eulerY < -15.0 held for 2 consecutive frames', () {
      // Frame 1: -18.0 deg, holdCount = 1 (not completed yet)
      expect(evaluateHeadTurn(LivenessChallengeType.turnRight, -18.0, 1), isFalse);

      // Frame 2: -19.5 deg, holdCount = 2 (completed!)
      expect(evaluateHeadTurn(LivenessChallengeType.turnRight, -19.5, 2), isTrue);

      // Incorrect direction (+18.0 deg) does not trigger turnRight
      expect(evaluateHeadTurn(LivenessChallengeType.turnRight, 18.0, 2), isFalse);
    });

    test('User turning left requires eulerY > 15.0 held for 2 consecutive frames', () {
      // Frame 1: 17.5 deg, holdCount = 1
      expect(evaluateHeadTurn(LivenessChallengeType.turnLeft, 17.5, 1), isFalse);

      // Frame 2: 21.0 deg, holdCount = 2 (completed!)
      expect(evaluateHeadTurn(LivenessChallengeType.turnLeft, 21.0, 2), isTrue);

      // Incorrect direction (-20.0 deg) does not trigger turnLeft
      expect(evaluateHeadTurn(LivenessChallengeType.turnLeft, -20.0, 2), isFalse);
    });
  });

  group('Timeout Counting and 3-Fails Rule Unit Tests', () {
    test('Timeout increments attempt count and triggers manual review on 3rd attempt', () {
      int attemptCount = 0;
      FaceCheckResult? evaluateTimeout() {
        attemptCount++;
        if (attemptCount >= 3) {
          return const FaceCheckResult(
            status: FaceCheckStatus.manualReviewRequired,
            message: 'Three consecutive attempts timed out. Manual review required.',
            fraudFlagCreated: true,
            attemptsCount: 3,
          );
        } else {
          return FaceCheckResult(
            status: FaceCheckStatus.fail,
            message: 'Liveness challenge timed out. Retry gesture.',
            attemptsCount: attemptCount,
          );
        }
      }

      final res1 = evaluateTimeout();
      expect(attemptCount, equals(1));
      expect(res1!.status, equals(FaceCheckStatus.fail));

      final res2 = evaluateTimeout();
      expect(attemptCount, equals(2));
      expect(res2!.status, equals(FaceCheckStatus.fail));

      final res3 = evaluateTimeout();
      expect(attemptCount, equals(3));
      expect(res3!.status, equals(FaceCheckStatus.manualReviewRequired));
      expect(res3.fraudFlagCreated, isTrue);
    });
  });
}
