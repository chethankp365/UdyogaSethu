import 'package:flutter/material.dart';
import 'package:udyogasethu/features/trust/domain/liveness_challenge.dart';

class FaceQualityGateResult {
  final bool isValid;
  final String hint;

  const FaceQualityGateResult({
    required this.isValid,
    required this.hint,
  });

  static const valid = FaceQualityGateResult(isValid: true, hint: 'Hold still, position face in oval');
}

class FaceQualityGates {
  static FaceQualityGateResult evaluate({
    required int faceCount,
    required Rect? boundingBox,
    required Size screenSize,
    required double? leftEyeOpenProb,
    required double? rightEyeOpenProb,
    required double? headEulerAngleY,
    required double? headEulerAngleZ,
    LivenessChallengeType? activeChallenge,
  }) {
    if (faceCount == 0) {
      return const FaceQualityGateResult(isValid: false, hint: 'No face detected. Position face inside oval.');
    }
    if (faceCount > 1) {
      return const FaceQualityGateResult(isValid: false, hint: 'Multiple faces detected. Ensure only 1 person is in frame.');
    }
    if (boundingBox == null) {
      return const FaceQualityGateResult(isValid: false, hint: 'Position face clearly inside oval.');
    }

    final frameArea = screenSize.width * screenSize.height;
    final faceArea = boundingBox.width * boundingBox.height;

    if (frameArea > 0) {
      final ratio = faceArea / frameArea;
      if (ratio < 0.05) {
        return const FaceQualityGateResult(isValid: false, hint: 'Move closer to the camera.');
      }
      if (ratio > 0.85) {
        return const FaceQualityGateResult(isValid: false, hint: 'Move slightly further back.');
      }
    }

    // Only enforce eyes-open gate if the current challenge is not asking the user to blink
    if (activeChallenge != LivenessChallengeType.blink) {
      if ((leftEyeOpenProb != null && leftEyeOpenProb < 0.25) || (rightEyeOpenProb != null && rightEyeOpenProb < 0.25)) {
        return const FaceQualityGateResult(isValid: false, hint: 'Keep your eyes open and ensure good lighting.');
      }
    }

    // Only enforce straight-ahead gate if the current challenge is not asking the user to turn head
    if (activeChallenge != LivenessChallengeType.turnLeft && activeChallenge != LivenessChallengeType.turnRight) {
      if ((headEulerAngleY != null && headEulerAngleY.abs() > 18.0) ||
          (headEulerAngleZ != null && headEulerAngleZ.abs() > 20.0)) {
        return const FaceQualityGateResult(isValid: false, hint: 'Look straight at the camera.');
      }
    }

    return FaceQualityGateResult.valid;
  }
}

