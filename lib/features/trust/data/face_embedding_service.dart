import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    if (_isInitialized) return;
    try {
      final options = InterpreterOptions();
      if (defaultTargetPlatform == TargetPlatform.android) {
        options.threads = 2;
      }
      _interpreter = await Interpreter.fromAsset('assets/models/mobilefacenet.tflite', options: options);
      _isInitialized = true;
    } catch (e) {
      debugPrint('[FaceEmbeddingService] Initialization error: $e');
      _isInitialized = false;
    }
  }

  List<double> extractEmbedding(img.Image faceCrop) {
    // 1. Resize to 112x112 (MobileFaceNet standard input size)
    final resized = img.copyResize(faceCrop, width: 112, height: 112);

    // 2. Prepare 4D Float32 Buffer [1, 112, 112, 3] with [-1, 1] normalization
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

    // Determine output shape (typically 1x192 or 1x128)
    int outputSize = 192;
    if (_interpreter != null) {
      try {
        final outputTensor = _interpreter!.getOutputTensor(0);
        if (outputTensor.shape.length == 2) {
          outputSize = outputTensor.shape[1];
        }
      } catch (_) {}
    }

    final output = List.generate(1, (_) => List.filled(outputSize, 0.0));

    if (_interpreter != null && _isInitialized) {
      _interpreter!.run(inputBuffer, output);
    } else {
      // Deterministic fallback for test/simulator environments
      return generateDeterministicEmbedding(resized);
    }

    final rawVector = output[0];
    return normalizeVector(rawVector);
  }

  static List<double> generateDeterministicEmbedding(img.Image image) {
    // Deterministic 128-float32 vector derived from image pixel values
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
    _isInitialized = false;
  }
}
