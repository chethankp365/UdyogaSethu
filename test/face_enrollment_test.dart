import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:udyogasethu/features/privacy/data/consent_repository.dart';
import 'package:udyogasethu/features/privacy/domain/consent_purpose.dart';
import 'package:udyogasethu/features/trust/data/face_embedding_service.dart';
import 'package:udyogasethu/features/trust/data/kyc_repository.dart';
import 'package:udyogasethu/features/trust/domain/face_quality_gates.dart';
import 'package:udyogasethu/features/trust/domain/kyc_record.dart';
import 'package:udyogasethu/features/trust/domain/liveness_challenge.dart';
import 'package:udyogasethu/features/trust/presentation/face_enrollment_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class FakeConsentRepository implements ConsentRepository {
  final Map<ConsentPurpose, bool> _consents = {ConsentPurpose.face: true};

  @override
  Future<bool> hasValidConsent(ConsentPurpose purpose) async => _consents[purpose] ?? false;

  @override
  Future<ConsentLog?> getLatestConsent(ConsentPurpose purpose) async {
    return ConsentLog(purpose: purpose.key, granted: _consents[purpose] ?? false, timestamp: DateTime.now());
  }

  @override
  Future<Map<ConsentPurpose, ConsentLog?>> getAllConsents() async => {};

  @override
  Future<void> recordConsent({required ConsentPurpose purpose, required bool granted, Map<String, dynamic>? metadata}) async {
    _consents[purpose] = granted;
  }

  @override
  Future<void> revokeConsent(ConsentPurpose purpose) async {
    _consents[purpose] = false;
  }

  @override
  Future<void> withdrawFaceConsent() async {
    _consents[ConsentPurpose.face] = false;
  }
}

class FakeKycRepository implements KycRepository {
  final _controller = StreamController<KycRecord?>.broadcast();

  @override
  Future<List<KycRecord>> getKycRecords(String userId) async => [];

  @override
  Future<KycRecord?> getLatestKycRecord(String userId, {String docType = 'aadhaar'}) async => null;

  @override
  Stream<KycRecord?> watchKycRecord(String userId, {String docType = 'aadhaar'}) => _controller.stream;

  @override
  Future<Map<String, dynamic>> startKycSession({required String docType, String? redirectUrl}) async => {};

  @override
  Future<Map<String, dynamic>> simulateCallback({required String providerRef, required String docType}) async => {};

  @override
  Future<KycRecord> submitDrivingLicence({
    required String dlNumber,
    required String vehicleClass,
    required DateTime expiryDate,
    List<int>? frontBytes,
    List<int>? backBytes,
  }) async => throw UnimplementedError();

  @override
  Future<KycRecord> submitStudentVerification({
    required String collegeName,
    required String courseName,
    required String regUsn,
    List<int>? cardBytes,
  }) async => throw UnimplementedError();

  @override
  Future<KycRecord> submitBankUpi({
    required String type,
    required String value,
    String? ifsc,
  }) async => throw UnimplementedError();

  @override
  Future<KycRecord> requestBackgroundCheck() async => throw UnimplementedError();

  @override
  Future<KycRecord> enrollFace({
    required List<double> embedding,
    required bool livenessPassed,
    required List<String> challenges,
    List<int>? photoBytes,
  }) async {
    return KycRecord(
      id: 'face-test-1',
      userId: 'test-user',
      docType: 'face',
      provider: 'ondevice_tflite_matcher',
      providerRef: 'ondevice-tflite-v1-128d',
      status: 'verified',
      maskedId: 'FACE-REF-TEST',
      nameMasked: 'Test Face Template',
      verifiedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }
}

Widget _makeTestableWidget(Widget child) {
  return ProviderScope(
    overrides: [
      consentRepositoryProvider.overrideWithValue(FakeConsentRepository()),
      kycRepositoryProvider.overrideWithValue(FakeKycRepository()),
    ],
    child: MaterialApp(
      home: child,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  group('Phase 3.4: Face Enrolment & Liveness Unit Tests', () {
    test('Liveness Challenge Randomization produces 2 distinct challenges', () {
      final pair = LivenessChallenge.generateRandomPair();
      expect(pair.length, equals(2));
      expect(pair[0].type, isNot(equals(pair[1].type)));
      expect(pair[0].isCompleted, isFalse);
    });

    test('FaceQualityGates evaluation checks 1 face, bounding box size, and angles', () {
      final noFace = FaceQualityGates.evaluate(
        faceCount: 0,
        boundingBox: null,
        screenSize: const Size(400, 600),
        leftEyeOpenProb: 0.9,
        rightEyeOpenProb: 0.9,
        headEulerAngleY: 0.0,
        headEulerAngleZ: 0.0,
      );
      expect(noFace.isValid, isFalse);
      expect(noFace.hint, contains('No face detected'));

      final multiFace = FaceQualityGates.evaluate(
        faceCount: 2,
        boundingBox: const Rect.fromLTWH(50, 50, 200, 200),
        screenSize: const Size(400, 600),
        leftEyeOpenProb: 0.9,
        rightEyeOpenProb: 0.9,
        headEulerAngleY: 0.0,
        headEulerAngleZ: 0.0,
      );
      expect(multiFace.isValid, isFalse);
      expect(multiFace.hint, contains('Multiple faces detected'));

      final validGate = FaceQualityGates.evaluate(
        faceCount: 1,
        boundingBox: const Rect.fromLTWH(50, 50, 200, 300),
        screenSize: const Size(400, 600),
        leftEyeOpenProb: 0.9,
        rightEyeOpenProb: 0.9,
        headEulerAngleY: 0.0,
        headEulerAngleZ: 0.0,
      );
      expect(validGate.isValid, isTrue);
    });

    test('FaceEmbeddingService normalization and Cosine Similarity', () {
      final v1 = [1.0, 0.0, 0.0];
      final v2 = [1.0, 0.0, 0.0];
      final v3 = [0.0, 1.0, 0.0];
      final v4 = [-1.0, 0.0, 0.0];

      final norm = FaceEmbeddingService.normalizeVector([3.0, 4.0]);
      expect(norm[0], closeTo(0.6, 0.01));
      expect(norm[1], closeTo(0.8, 0.01));

      expect(FaceEmbeddingService.calculateCosineSimilarity(v1, v2), closeTo(1.0, 0.001));
      expect(FaceEmbeddingService.calculateCosineSimilarity(v1, v3), closeTo(0.0, 0.001));
      expect(FaceEmbeddingService.calculateCosineSimilarity(v1, v4), closeTo(-1.0, 0.001));
    });

    test('FaceEmbeddingService deterministic fallback extracts 128d unit vector', () {
      final sampleImg = img.Image(width: 112, height: 112);
      final embedding = FaceEmbeddingService.generateDeterministicEmbedding(sampleImg);
      expect(embedding.length, equals(128));

      double normSq = 0.0;
      for (final v in embedding) {
        normSq += v * v;
      }
      expect(normSq, closeTo(1.0, 0.01));
    });
  });

  group('Phase 3.4: Face Enrolment Widget Tests', () {
    testWidgets('FaceEnrollmentScreen renders guided camera oval, timer banner, and action buttons', (tester) async {
      await tester.pumpWidget(_makeTestableWidget(const FaceEnrollmentScreen(matcherMode: 'ondevice')));
      await tester.pump();

      expect(find.text('Face Enrolment & Liveness'), findsOneWidget);
      expect(find.textContaining('Waiting for face'), findsOneWidget);
      expect(find.text('Reset / Retry'), findsOneWidget);
      expect(find.text('Retry Challenges'), findsOneWidget);
    });

    testWidgets('FaceEnrollmentScreen renders Demo Mode banner when matcherMode is mock', (tester) async {
      await tester.pumpWidget(_makeTestableWidget(const FaceEnrollmentScreen(matcherMode: 'mock')));
      await tester.pump();

      expect(find.textContaining('Demo mode — Mock Face Matcher Active'), findsOneWidget);
    });
  });
}
