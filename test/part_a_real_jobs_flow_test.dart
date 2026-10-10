import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/provider/domain/job_applicant.dart';
import 'package:udyogasethu/features/provider/domain/job_post_draft.dart';
import 'package:udyogasethu/features/provider/domain/provider_job.dart';
import 'package:udyogasethu/features/seeker/domain/job_eligibility.dart';
import 'package:udyogasethu/features/seeker/domain/job_recommendation.dart';

void main() {
  group('Part A1 & A6: Job Eligibility and Stable Reason Codes', () {
    test('JobEligibility parses stable reason codes and flags correctly', () {
      final json = {
        'is_eligible': false,
        'reason_code': 'EXPIRED',
        'reasons': ['This job has already started or expired.'],
        'licence_needed': false,
        'has_licence': true,
        'verified_needed': false,
        'is_verified': true,
        'student_gated': false,
        'schedule_overlap': false,
        'already_applied': false,
        'is_own_job': false,
        'is_past_start': true,
        'is_slots_filled': false,
      };

      final eligibility = JobEligibility.fromJson(json);

      expect(eligibility.isEligible, isFalse);
      expect(eligibility.reasonCode, 'EXPIRED');
      expect(eligibility.isPastStart, isTrue);
      expect(eligibility.isOwnJob, isFalse);
      expect(eligibility.isSlotsFilled, isFalse);
      expect(eligibility.reasons.first, contains('already started'));
    });

    test('JobEligibility handles own job restriction', () {
      final json = {
        'is_eligible': false,
        'reason_code': 'OWN_JOB',
        'reasons': ['You cannot apply to your own posted job.'],
        'is_own_job': true,
      };

      final eligibility = JobEligibility.fromJson(json);

      expect(eligibility.isEligible, isFalse);
      expect(eligibility.reasonCode, 'OWN_JOB');
      expect(eligibility.isOwnJob, isTrue);
    });

    test('JobEligibility handles filled slots restriction', () {
      final json = {
        'is_eligible': false,
        'reason_code': 'SLOTS_FILLED',
        'reasons': ['All slots for this job are filled.'],
        'is_slots_filled': true,
      };

      final eligibility = JobEligibility.fromJson(json);

      expect(eligibility.isEligible, isFalse);
      expect(eligibility.reasonCode, 'SLOTS_FILLED');
      expect(eligibility.isSlotsFilled, isTrue);
    });

    test('JobEligibility handles already applied state', () {
      final json = {
        'is_eligible': false,
        'reason_code': 'ALREADY_APPLIED',
        'reasons': ['You have already applied for this job.'],
        'already_applied': true,
      };

      final eligibility = JobEligibility.fromJson(json);

      expect(eligibility.isEligible, isFalse);
      expect(eligibility.reasonCode, 'ALREADY_APPLIED');
      expect(eligibility.alreadyApplied, isTrue);
    });
  });

  group('Part A3 & B1: Job Post Location & Target Workers Validation', () {
    test('JobPostDraft studentsOk defaults to false per B1', () {
      final draft = JobPostDraft(
        startAt: DateTime.now().add(const Duration(days: 1)),
      );

      expect(draft.studentsOk, isFalse);
      expect(draft.requirementsMap['students_ok'], isFalse);
    });

    test('ProviderJob studentsOk requires explicit true, not inferred', () {
      final jobNotSpecified = ProviderJob(
        id: 'job-1',
        providerId: 'prov-1',
        categoryName: 'General',
        title: 'Painting Job',
        wagePaise: 70000,
        startAt: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
        requirements: const {},
      );

      expect(jobNotSpecified.studentsOk, isFalse);

      final jobExplicitTrue = ProviderJob(
        id: 'job-2',
        providerId: 'prov-1',
        categoryName: 'General',
        title: 'Painting Job',
        wagePaise: 70000,
        startAt: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
        requirements: const {'students_ok': true},
      );

      expect(jobExplicitTrue.studentsOk, isTrue);
    });

    test('Address validation rejects house number only', () {
      bool isInvalidAddress(String address) {
        final trimmed = address.trim();
        if (trimmed.length < 8) return true;
        final houseOnlyRegex = RegExp(r'^(#|no\.?|plot|flat|door|h\.?no\.?)?\s*\d+[\w\s\-/]*$', caseSensitive: false);
        return houseOnlyRegex.hasMatch(trimmed);
      }

      expect(isInvalidAddress('#55'), isTrue);
      expect(isInvalidAddress('55'), isTrue);
      expect(isInvalidAddress('No. 12'), isTrue);
      expect(isInvalidAddress('Plot 42-A'), isTrue);
      expect(isInvalidAddress('#42, 5th Cross, Koramangala 4th Block, Bengaluru'), isFalse);
      expect(isInvalidAddress('100 Feet Road, Indiranagar, Bengaluru'), isFalse);
    });
  });

  group('Part A4: Recommendation and Real Data Only', () {
    test('JobRecommendation defaults to real neutral fallbacks without demo data', () {
      final json = {
        'id': 'real-job-1',
        'provider_id': 'prov-123',
        'title': 'Masonry Work',
        'wage_type': 'daily',
        'wage_paise': 80000,
      };

      final rec = JobRecommendation.fromJson(json);

      expect(rec.id, 'real-job-1');
      expect(rec.employerName, 'Employer'); // Not "Local Employer" or "Sharma Builders"
      expect(rec.employerVerified, isTrue);
    });
  });

  group('Part A5: Job Applicant Details', () {
    test('JobApplicant parses seeker_type, badge_name, and level_number', () {
      final json = {
        'application_id': 'app-1',
        'job_id': 'job-1',
        'worker_id': 'worker-1',
        'status': 'applied',
        'worker_name': 'Ramesh Kumar',
        'seeker_type': 'informal',
        'badge_name': 'Verified Worker',
        'level_number': 3,
        'rating': 4.9,
        'review_count': 12,
        'skills': ['Plumbing', 'Pipe Fitting'],
        'distance_m': 1200.0,
      };

      final applicant = JobApplicant.fromJson(json);

      expect(applicant.applicationId, 'app-1');
      expect(applicant.workerName, 'Ramesh Kumar');
      expect(applicant.seekerType, 'informal');
      expect(applicant.badgeName, 'Verified Worker');
      expect(applicant.levelNumber, 3);
      expect(applicant.rating, 4.9);
      expect(applicant.skills, contains('Plumbing'));
      expect(applicant.formattedDistance, '1.2 km away');
    });
  });
}
