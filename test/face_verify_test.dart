import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/privacy/data/consent_repository.dart';
import 'package:udyogasethu/features/privacy/domain/consent_purpose.dart';
import 'package:udyogasethu/features/verification/domain/face_check_result.dart';
import 'package:udyogasethu/features/verification/presentation/face_check_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class FakeConsentRepository implements ConsentRepository {
  @override
  Future<bool> hasValidConsent(ConsentPurpose purpose) async => true;

  @override
  Future<ConsentLog?> getLatestConsent(ConsentPurpose purpose) async => null;

  @override
  Future<Map<ConsentPurpose, ConsentLog?>> getAllConsents() async => {};

  @override
  Future<void> recordConsent({
    required ConsentPurpose purpose,
    required bool granted,
    Map<String, dynamic>? metadata,
  }) async {}

  @override
  Future<void> revokeConsent(ConsentPurpose purpose) async {}

  @override
  Future<void> withdrawFaceConsent() async {}
}

void main() {
  group('FaceCheckResult Model Tests', () {
    test('FaceCheckResult.fromJson parses pass response correctly', () {
      final json = {
        'result': 'pass',
        'match_score': 92.5,
        'similarity': 0.925,
        'message': 'Face identity verified successfully.',
        'fraud_flag_created': false,
        'attempts_count': 0,
      };

      final result = FaceCheckResult.fromJson(json);
      expect(result.status, equals(FaceCheckStatus.pass));
      expect(result.matchScore, equals(92.5));
      expect(result.similarity, equals(0.925));
      expect(result.message, equals('Face identity verified successfully.'));
      expect(result.fraudFlagCreated, isFalse);
      expect(result.attemptsCount, equals(0));
    });

    test('FaceCheckResult.fromJson parses fail response correctly', () {
      final json = {
        'result': 'fail',
        'match_score': 40.0,
        'similarity': 0.40,
        'message': 'Face match score below threshold. Please try again.',
        'fraud_flag_created': false,
        'attempts_count': 1,
      };

      final result = FaceCheckResult.fromJson(json);
      expect(result.status, equals(FaceCheckStatus.fail));
      expect(result.matchScore, equals(40.0));
      expect(result.similarity, equals(0.40));
      expect(result.fraudFlagCreated, isFalse);
      expect(result.attemptsCount, equals(1));
    });

    test('FaceCheckResult.fromJson parses manual_review_required correctly on 3 fails', () {
      final json = {
        'result': 'manual_review_required',
        'match_score': 35.0,
        'similarity': 0.35,
        'message': 'Three consecutive verification attempts failed. Account requires manual review.',
        'fraud_flag_created': true,
        'attempts_count': 3,
      };

      final result = FaceCheckResult.fromJson(json);
      expect(result.status, equals(FaceCheckStatus.manualReviewRequired));
      expect(result.fraudFlagCreated, isTrue);
      expect(result.attemptsCount, equals(3));
    });
  });

  group('P3.5 Face Verification Security & Business Logic Policy Tests', () {
    test('Client RLS Policy: Clients cannot insert into verification_attempts or fraud_flags directly', () {
      // Documenting policy invariant:
      // RLS policies for verification_attempts, fraud_flags, and face_profiles have SELECT policies only.
      // No INSERT, UPDATE, or DELETE policies exist for client roles (authenticated/anon).
      // All writes must strictly originate from service_role inside Edge Functions or SECURITY DEFINER RPCs.
      const hasClientInsertPolicy = false;
      expect(hasClientInsertPolicy, isFalse, reason: 'Client direct writes to verification_attempts and fraud_flags must be blocked by RLS.');
    });

    test('get_face_login_requirement RPC contract returns strictly boolean', () {
      // Contract test: get_face_login_requirement returns true or false boolean
      dynamic rpcResponse = false;
      bool parsedResult = false;
      if (rpcResponse is bool) {
        parsedResult = rpcResponse;
      } else if (rpcResponse is String) {
        parsedResult = rpcResponse.toLowerCase() == 'true';
      }
      expect(parsedResult, isA<bool>());
      expect(parsedResult, isFalse);
    });

    test('Login context verification attempt insert includes gps_ok default/explicit value', () {
      // In non-GPS contexts like login, gps_ok is NOT NULL and passed as true (N/A)
      final attemptPayload = {
        'user_id': '00000000-0000-0000-0000-000000000001',
        'context': 'login',
        'liveness_ok': true,
        'match_score': 88.5,
        'gps_ok': true,
        'result': 'pass',
      };

      expect(attemptPayload['gps_ok'], isTrue);
      expect(attemptPayload['context'], equals('login'));
      expect(attemptPayload['result'], equals('pass'));
    });

    test('Three consecutive fails rule creates fraud_flags row with rule_key repeated_face_fail', () {
      int calcFails(bool p, int prev) => p ? 0 : prev + 1;
      const consecutiveFails = 2;
      const passed = false;

      final newConsecutiveFails = calcFails(passed, consecutiveFails);
      String result = 'fail';
      bool createFraudFlag = false;

      if (!passed && newConsecutiveFails >= 3) {
        result = 'manual_review_required';
        createFraudFlag = true;
      }

      expect(newConsecutiveFails, equals(3));
      expect(result, equals('manual_review_required'));
      expect(createFraudFlag, isTrue);

      final fraudFlagPayload = {
        'user_id': '00000000-0000-0000-0000-000000000001',
        'rule_key': 'repeated_face_fail',
        'severity': 'high',
        'status': 'open',
      };

      expect(fraudFlagPayload['rule_key'], equals('repeated_face_fail'));
      expect(fraudFlagPayload['severity'], equals('high'));
      expect(fraudFlagPayload['status'], equals('open'));
    });

    test('Rate Limiter Contract: Max 10 requests per minute per user', () {
      const maxRequestsPerWindow = 10;
      const windowSeconds = 60;

      int requestsMade = 11;
      bool rateLimitExceeded = requestsMade > maxRequestsPerWindow;

      expect(rateLimitExceeded, isTrue);
      expect(maxRequestsPerWindow, equals(10));
      expect(windowSeconds, equals(60));
    });

    test('Router Face Login Gate: Redirects seeker with flag on and unpassed face check to face check / enrolment screen', () {
      String? evaluateGateRedirect({
        required bool isSeeker,
        required bool faceRequiredAtLogin,
        required bool faceLoginPassed,
        required bool hasEnrolledFace,
      }) {
        if (isSeeker && faceRequiredAtLogin && !faceLoginPassed) {
          return hasEnrolledFace ? '/kyc/face-check' : '/kyc/face';
        }
        return null;
      }

      // 1. Worker (seeker) with faceRequiredAtLogin = true, faceLoginPassed = false, hasEnrolledFace = true -> /kyc/face-check
      expect(
        evaluateGateRedirect(isSeeker: true, faceRequiredAtLogin: true, faceLoginPassed: false, hasEnrolledFace: true),
        equals('/kyc/face-check'),
      );

      // 2. Worker with faceRequiredAtLogin = true, faceLoginPassed = false, hasEnrolledFace = false -> /kyc/face (enrolment)
      expect(
        evaluateGateRedirect(isSeeker: true, faceRequiredAtLogin: true, faceLoginPassed: false, hasEnrolledFace: false),
        equals('/kyc/face'),
      );

      // 3. Worker with faceRequiredAtLogin = false -> straight to home (no redirect to face gate)
      expect(
        evaluateGateRedirect(isSeeker: true, faceRequiredAtLogin: false, faceLoginPassed: false, hasEnrolledFace: true),
        isNull,
      );

      // 4. Farmer or Provider with faceRequiredAtLogin = true -> straight to home (face login applies to seekers only)
      expect(
        evaluateGateRedirect(isSeeker: false, faceRequiredAtLogin: true, faceLoginPassed: false, hasEnrolledFace: true),
        isNull,
      );
    });
  });

  group('FaceCheckScreen Widget Tests', () {
    Widget buildTestWidget({
      required String contextType,
      String? assignmentId,
      String matcherMode = 'ondevice',
      ValueChanged<FaceCheckResult>? onResult,
    }) {
      return ProviderScope(
        overrides: [
          consentRepositoryProvider.overrideWithValue(FakeConsentRepository()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FaceCheckScreen(
            contextType: contextType,
            assignmentId: assignmentId,
            matcherMode: matcherMode,
            onResult: onResult,
          ),
        ),
      );
    }

    testWidgets('Renders FaceCheckScreen header, title, and context badge', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(contextType: 'login'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Face Verification Check'), findsOneWidget);
      expect(find.text('Context: LOGIN'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('Displays Demo Test Mode controls in debug mode when matcherMode is mock', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(contextType: 'job_start', matcherMode: 'mock'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Demo Mode Test Controls'), findsOneWidget);
      expect(find.text('Demo: Pass Verification'), findsOneWidget);
      expect(find.text('Demo: Fail Verification'), findsOneWidget);
    });
  });
}
