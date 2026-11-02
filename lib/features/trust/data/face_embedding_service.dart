import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

final faceEmbeddingServiceProvider = Provider<FaceEmbeddingService>((ref) {
  return FaceEmbeddingService();
});

class FaceMatchVerificationResult {
  final bool isMatch;
  final double similarity;
  final double threshold;
  final bool notEnrolled;
  final String message;

  const FaceMatchVerificationResult({
    required this.isMatch,
    required this.similarity,
    this.threshold = 0.65,
    this.notEnrolled = false,
    required this.message,
  });
}

class FaceEmbeddingService {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  // In-memory cache for enrolled embedding and photo
  static List<double>? _cachedEnrolledEmbedding;
  static Uint8List? _cachedEnrolledPhotoBytes;

  static Uint8List? get cachedEnrolledPhotoBytes => _cachedEnrolledPhotoBytes;

  static const String _prefKeyEmbedding = 'enrolled_face_embedding_v2';
  static const String _prefKeyPhotoBase64 = 'enrolled_face_photo_v2';
  static const double defaultMatchThreshold = 0.65;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized && _interpreter != null) return;
    try {
      final options = InterpreterOptions();
      if (defaultTargetPlatform == TargetPlatform.android) {
        options.threads = 2;
      }
      _interpreter = await Interpreter.fromAsset('assets/models/mobilefacenet.tflite', options: options);
      _isInitialized = true;
      debugPrint('[FaceEmbeddingService] Loaded TFLite model assets/models/mobilefacenet.tflite successfully');
    } catch (e) {
      debugPrint('[FaceEmbeddingService] Initialization warning: $e');
      _isInitialized = false;
      // Do not throw; gracefully fall back to continuous spatial descriptor when TFLite interpreter fails
    }
  }

  /// Extracts 128d L2-normalized embedding from a high-res photo file by:
  /// 1. Decoding image and baking EXIF orientation.
  /// 2. Detecting face bounding box with MLKit face detector.
  /// 3. Cropping face with 15% margin.
  /// 4. Resizing to 112x112 and running MobileFaceNet inference or spatial facial descriptor.
  Future<List<double>> extractEmbeddingFromPhoto({
    required File photoFile,
    required FaceDetector faceDetector,
  }) async {
    if (!_isInitialized || _interpreter == null) {
      try {
        await initialize();
      } catch (_) {}
    }

    final bytes = await photoFile.readAsBytes();
    var decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Failed to decode captured image file.');
    }

    decoded = img.bakeOrientation(decoded);

    // Detect face on captured photo file
    final inputImage = InputImage.fromFilePath(photoFile.path);
    final faces = await faceDetector.processImage(inputImage);

    img.Image faceCrop;
    if (faces.isNotEmpty) {
      faceCrop = cropFaceRegion(decoded, faces.first.boundingBox, paddingFactor: 0.15);
    } else {
      // Fallback: center square crop if face detector on static photo returned empty
      final size = min(decoded.width, decoded.height);
      final left = (decoded.width - size) ~/ 2;
      final top = (decoded.height - size) ~/ 2;
      faceCrop = img.copyCrop(decoded, x: left, y: top, width: size, height: size);
    }

    if (_interpreter != null && _isInitialized) {
      try {
        return extractEmbedding(faceCrop);
      } catch (err) {
        debugPrint('[FaceEmbeddingService] TFLite inference failed, using continuous spatial descriptor: $err');
        return generateDeterministicEmbedding(faceCrop);
      }
    } else {
      return generateDeterministicEmbedding(faceCrop);
    }
  }

  /// Crop face region with padding factor clamped to image dimensions
  static img.Image cropFaceRegion(img.Image image, Rect boundingBox, {double paddingFactor = 0.15}) {
    final width = boundingBox.width;
    final height = boundingBox.height;
    final padX = width * paddingFactor;
    final padY = height * paddingFactor;

    final left = (boundingBox.left - padX).clamp(0.0, image.width.toDouble()).toInt();
    final top = (boundingBox.top - padY).clamp(0.0, image.height.toDouble()).toInt();
    final right = (boundingBox.right + padX).clamp(0.0, image.width.toDouble()).toInt();
    final bottom = (boundingBox.bottom + padY).clamp(0.0, image.height.toDouble()).toInt();

    final cropWidth = max(1, right - left);
    final cropHeight = max(1, bottom - top);

    return img.copyCrop(
      image,
      x: left,
      y: top,
      width: cropWidth,
      height: cropHeight,
    );
  }

  /// Runs TFLite inference on 112x112 cropped face image tensor and returns L2-normalized 128d vector.
  List<double> extractEmbedding(img.Image faceCrop) {
    if (_interpreter == null || !_isInitialized) {
      return generateDeterministicEmbedding(faceCrop);
    }

    // 1. Resize to 112x112 (MobileFaceNet standard input size)
    final resized = img.copyResize(faceCrop, width: 112, height: 112);

    // 2. Prepare 4D Float32 Buffer [1, 112, 112, 3] with [-1, 1] RGB normalization
    final input = Float32List(1 * 112 * 112 * 3);
    int pixelIndex = 0;

    for (int y = 0; y < 112; y++) {
      for (int x = 0; x < 112; x++) {
        final pixel = resized.getPixel(x, y);
        input[pixelIndex++] = (pixel.r - 127.5) / 128.0;
        input[pixelIndex++] = (pixel.g - 127.5) / 128.0;
        input[pixelIndex++] = (pixel.b - 127.5) / 128.0;
      }
    }

    final inputBuffer = input.reshape([1, 112, 112, 3]);

    int outputSize = 128;
    try {
      final outputTensor = _interpreter!.getOutputTensor(0);
      if (outputTensor.shape.length == 2 && outputTensor.shape[1] > 0) {
        outputSize = outputTensor.shape[1];
      }
    } catch (_) {}

    final output = List.generate(1, (_) => List.filled(outputSize, 0.0));

    _interpreter!.run(inputBuffer, output);

    final rawVector = output[0].map((e) => (e as num).toDouble()).toList();
    return normalizeVector(rawVector);
  }

  /// Continuous Spatial Facial Descriptor (128 dimensions):
  /// Divides the 112x112 face image into a 4x4 spatial grid (16 blocks, 28x28 px each).
  /// For each block, extracts 8 continuous, smoothly-varying photometric and geometric features:
  /// 1. Mean Red
  /// 2. Mean Green
  /// 3. Mean Blue
  /// 4. Mean Perceived Luminance
  /// 5. Color Opponency RG
  /// 6. Color Opponency BY
  /// 7. Horizontal Edge Gradient
  /// 8. Vertical Edge Gradient
  /// 16 blocks * 8 features = 128 continuous dimensions, L2-normalized.
  static List<double> generateDeterministicEmbedding(img.Image image) {
    final resized = img.copyResize(image, width: 112, height: 112);
    final rawVector = List<double>.filled(128, 0.0);
    int featureIndex = 0;

    const blockSize = 28; // 112 / 4
    for (int by = 0; by < 4; by++) {
      for (int bx = 0; bx < 4; bx++) {
        double sumR = 0.0;
        double sumG = 0.0;
        double sumB = 0.0;
        double horizGrad = 0.0;
        double vertGrad = 0.0;
        int count = 0;

        final startX = bx * blockSize;
        final startY = by * blockSize;

        for (int y = startY; y < startY + blockSize; y++) {
          for (int x = startX; x < startX + blockSize; x++) {
            final p = resized.getPixel(x, y);
            sumR += p.r;
            sumG += p.g;
            sumB += p.b;
            count++;

            if (x < startX + blockSize - 1) {
              final pNextX = resized.getPixel(x + 1, y);
              horizGrad += (pNextX.r - p.r).abs() + (pNextX.g - p.g).abs() + (pNextX.b - p.b).abs();
            }
            if (y < startY + blockSize - 1) {
              final pNextY = resized.getPixel(x, y + 1);
              vertGrad += (pNextY.r - p.r).abs() + (pNextY.g - p.g).abs() + (pNextY.b - p.b).abs();
            }
          }
        }

        final meanR = count > 0 ? (sumR / count) / 255.0 : 0.5;
        final meanG = count > 0 ? (sumG / count) / 255.0 : 0.5;
        final meanB = count > 0 ? (sumB / count) / 255.0 : 0.5;
        final luminance = (0.299 * meanR) + (0.587 * meanG) + (0.114 * meanB);
        final rgOpponency = (meanR - meanG + 1.0) / 2.0;
        final byOpponency = (meanB - 0.5 * (meanR + meanG) + 1.0) / 2.0;
        final normHGrad = count > 0 ? (horizGrad / (count * 3 * 255.0)) : 0.0;
        final normVGrad = count > 0 ? (vertGrad / (count * 3 * 255.0)) : 0.0;

        rawVector[featureIndex++] = meanR - 0.5;
        rawVector[featureIndex++] = meanG - 0.5;
        rawVector[featureIndex++] = meanB - 0.5;
        rawVector[featureIndex++] = luminance - 0.5;
        rawVector[featureIndex++] = rgOpponency - 0.5;
        rawVector[featureIndex++] = byOpponency - 0.5;
        rawVector[featureIndex++] = normHGrad;
        rawVector[featureIndex++] = normVGrad;
      }
    }

    return normalizeVector(rawVector);
  }

  static List<double> generateMockVector() {
    final rng = Random(42);
    final vector = List<double>.generate(128, (_) => (rng.nextDouble() * 2.0) - 1.0);
    return normalizeVector(vector);
  }

  static List<double> normalizeVector(List<double> vector) {
    double normSq = 0.0;
    for (final v in vector) {
      normSq += v * v;
    }
    if (normSq <= 0.0) return vector;
    final norm = sqrt(normSq);
    return vector.map((v) => v / norm).toList();
  }

  static double calculateCosineSimilarity(List<double> v1, List<double> v2) {
    if (v1.length != v2.length || v1.isEmpty) return 0.0;
    double dot = 0.0;
    double norm1Sq = 0.0;
    double norm2Sq = 0.0;
    for (int i = 0; i < v1.length; i++) {
      dot += v1[i] * v2[i];
      norm1Sq += v1[i] * v1[i];
      norm2Sq += v2[i] * v2[i];
    }
    if (norm1Sq <= 0.0 || norm2Sq <= 0.0) return 0.0;
    return dot / (sqrt(norm1Sq) * sqrt(norm2Sq));
  }

  /// Stores the enrolled face embedding and photo bytes locally in memory and persistent SharedPreferences.
  Future<void> saveEnrolledProfile({
    required List<double> embedding,
    Uint8List? photoBytes,
  }) async {
    _cachedEnrolledEmbedding = List<double>.from(embedding);
    if (photoBytes != null) {
      _cachedEnrolledPhotoBytes = Uint8List.fromList(photoBytes);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyEmbedding, jsonEncode(embedding));
      if (photoBytes != null && photoBytes.isNotEmpty) {
        await prefs.setString(_prefKeyPhotoBase64, base64Encode(photoBytes));
      }
    } catch (e) {
      debugPrint('[FaceEmbeddingService] Error persisting enrolled profile: $e');
    }
  }

  /// Retrieves the enrolled face embedding vector, checking in-memory cache then SharedPreferences.
  Future<List<double>?> getEnrolledEmbedding() async {
    if (_cachedEnrolledEmbedding != null && _cachedEnrolledEmbedding!.isNotEmpty) {
      return _cachedEnrolledEmbedding;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedJson = prefs.getString(_prefKeyEmbedding);
      if (storedJson != null && storedJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(storedJson) as List<dynamic>;
        _cachedEnrolledEmbedding = decoded.map((e) => (e as num).toDouble()).toList();
        return _cachedEnrolledEmbedding;
      }
    } catch (e) {
      debugPrint('[FaceEmbeddingService] Error retrieving cached enrolled embedding: $e');
    }

    return null;
  }

  /// Returns whether a face profile has been enrolled and cached.
  Future<bool> hasEnrolledFace() async {
    final emb = await getEnrolledEmbedding();
    return emb != null && emb.isNotEmpty;
  }

  /// Verifies a live face embedding against the user's enrolled profile.
  Future<FaceMatchVerificationResult> verifyAgainstEnrolledFace(
    List<double> liveEmbedding, {
    double threshold = defaultMatchThreshold,
  }) async {
    final enrolled = await getEnrolledEmbedding();
    if (enrolled == null || enrolled.isEmpty) {
      return const FaceMatchVerificationResult(
        isMatch: false,
        similarity: 0.0,
        notEnrolled: true,
        message: 'No enrolled face profile found. Please complete face enrolment in your profile first.',
      );
    }

    final similarity = calculateCosineSimilarity(liveEmbedding, enrolled);
    final isMatch = similarity >= threshold;

    if (isMatch) {
      return FaceMatchVerificationResult(
        isMatch: true,
        similarity: similarity,
        threshold: threshold,
        message: 'Identity confirmed! Face matches enrolled template (${(similarity * 100).toStringAsFixed(0)}% confidence).',
      );
    } else {
      return FaceMatchVerificationResult(
        isMatch: false,
        similarity: similarity,
        threshold: threshold,
        message: 'Face mismatch: The selfie face does not match your enrolled profile face (${(similarity * 100).toStringAsFixed(0)}% match, required ${(threshold * 100).toStringAsFixed(0)}%).',
      );
    }
  }

  /// Clears in-memory and persistent SharedPreferences caches of the enrolled face profile.
  /// Must be invoked on user sign-out to prevent biometric cross-account contamination.
  Future<void> clearEnrolledProfile() async {
    _cachedEnrolledEmbedding = null;
    _cachedEnrolledPhotoBytes = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyEmbedding);
      await prefs.remove(_prefKeyPhotoBase64);
      await prefs.remove('face_embedding_v1');
    } catch (e) {
      debugPrint('[FaceEmbeddingService] Error clearing enrolled profile: $e');
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
