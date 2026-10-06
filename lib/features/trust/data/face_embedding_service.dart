import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

final faceEmbeddingServiceProvider = Provider<FaceEmbeddingService>((ref) {
  return FaceEmbeddingService();
});

class FaceEmbeddingService {
  Interpreter? _interpreter;
  bool _isInitialized = false;

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
      debugPrint('[FaceEmbeddingService] Initialization error: $e');
      _isInitialized = false;
      throw Exception('Failed to load face embedding TFLite model (assets/models/mobilefacenet.tflite): $e');
    }
  }

  /// Extracts 128d L2-normalized embedding from a high-res photo file by:
  /// 1. Decoding image and baking EXIF orientation.
  /// 2. Detecting face bounding box with MLKit face detector.
  /// 3. Cropping face with 15% margin.
  /// 4. Resizing to 112x112 and normalizing Float32 [-1, 1] RGB input.
  /// 5. Running MobileFaceNet TFLite model and L2-normalizing the output vector.
  Future<List<double>> extractEmbeddingFromPhoto({
    required File photoFile,
    required FaceDetector faceDetector,
  }) async {
    if (!_isInitialized || _interpreter == null) {
      await initialize();
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

    return extractEmbedding(faceCrop);
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
      throw StateError('FaceEmbeddingService model is not initialized. TFLite model failed to load.');
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

  static List<double> generateDeterministicEmbedding(img.Image image) {
    final vector = List<double>.filled(128, 0.0);
    int sumR = 0, sumG = 0, sumB = 0;
    for (int y = 0; y < min(image.height, 30); y++) {
      for (int x = 0; x < min(image.width, 30); x++) {
        final p = image.getPixel(x, y);
        sumR += p.r.toInt();
        sumG += p.g.toInt();
        sumB += p.b.toInt();
      }
    }
    final seed = (sumR * 31 + sumG * 17 + sumB * 7);
    final rng = Random(seed);
    for (int i = 0; i < 128; i++) {
      vector[i] = (rng.nextDouble() * 2.0) - 1.0;
    }
    return normalizeVector(vector);
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

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}

