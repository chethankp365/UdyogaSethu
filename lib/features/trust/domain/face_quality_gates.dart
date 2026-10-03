import 'package:flutter/material.dart';

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
      if (ratio < 0.08) {
        return const FaceQualityGateResult(isValid: false, hint: 'Move closer to the camera.');
      }
      if (ratio > 0.75) {
        return const FaceQualityGateResult(isValid: false, hint: 'Move slightly further back.');
      }
    }

    if (leftEyeOpenProb != null && leftEyeOpenProb < 0.2 && rightEyeOpenProb != null && rightEyeOpenProb < 0.2) {
      return const FaceQualityGateResult(isValid: false, hint: 'Keep your eyes open.');
    }

    if (headEulerAngleY != null && (headEulerAngleY.abs() > 30.0)) {
      return const FaceQualityGateResult(isValid: false, hint: 'Look straight at the camera.');
    }

    return FaceQualityGateResult.valid;
  }
}
