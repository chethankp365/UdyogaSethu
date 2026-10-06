import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/trust/domain/safety_onboarding_status.dart';

void main() {
  group('SafetyOnboardingStatus Unit Tests', () {
    test('Initial SafetyOnboardingStatus defaults to not_booked and unverified', () {
      final status = SafetyOnboardingStatus.initial();

      expect(status.isVerifiedBadge, isFalse);
      expect(status.kycOk, isFalse);
      expect(status.faceOk, isFalse);
      expect(status.trainingOk, isFalse);
      expect(status.docOk, isFalse);
      expect(status.registrationStatus, equals('not_booked'));
      expect(status.isFullyApproved, isFalse);
    });

    test('SafetyOnboardingStatus.fromJson parses 4-tick breakdown correctly', () {
      final json = {
        'is_verified_badge': true,
        'kyc_ok': true,
        'face_ok': true,
        'training_ok': true,
        'doc_ok': true,
        'registration_status': 'approved',
        'registered_at': '2026-10-05T10:00:00Z',
        'event': {
          'id': 'evt-123',
          'title': 'Safety Onboarding Training Day',
          'venue': 'Koramangala Centre',
          'capacity': 50,
          'language': 'en',
        },
      };

      final status = SafetyOnboardingStatus.fromJson(json);

      expect(status.isVerifiedBadge, isTrue);
      expect(status.kycOk, isTrue);
      expect(status.faceOk, isTrue);
      expect(status.trainingOk, isTrue);
      expect(status.docOk, isTrue);
      expect(status.registrationStatus, equals('approved'));
      expect(status.isFullyApproved, isTrue);
      expect(status.event, isNotNull);
      expect(status.event!.id, equals('evt-123'));
      expect(status.event!.title, equals('Safety Onboarding Training Day'));
      expect(status.event!.capacity, equals(50));
    });

    test('isFullyApproved returns false when any tick is missing', () {
      final status = SafetyOnboardingStatus.fromJson({
        'is_verified_badge': false,
        'kyc_ok': true,
        'face_ok': true,
        'training_ok': true,
        'doc_ok': false, // Document review incomplete
        'registration_status': 'attended',
      });

      expect(status.isFullyApproved, isFalse);
      expect(status.isVerifiedBadge, isFalse);
      expect(status.docOk, isFalse);
      expect(status.trainingOk, isTrue);
    });
  });
}
