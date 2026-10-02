import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_profile_draft.dart';
import 'seeker_wizard_test.dart';

void main() {
  group('P2.7 Check: Seeker Profile Types Comparison', () {
    late FakeSeekerProfileRepository repo;

    setUp(() {
      repo = FakeSeekerProfileRepository();
    });

    test('Creates and compares informal, student, and part-time profiles', () async {
      // 1. Informal Worker Profile
      const informalDraft = SeekerProfileDraft(
        userId: 'user-informal-001',
        fullName: 'Ramappa Mason',
        seekerType: 'informal',
        selectedSkillIds: ['skill-masonry', 'skill-plastering'],
        experienceYears: 5.0,
        dailyRatePaise: 85000,
        hasDrivingLicence: true,
        workingDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
        homeAddress: 'Koramangala 4th Block, Bengaluru',
        serviceRadiusKm: 15.0,
      );
      await repo.saveStep(informalDraft, 7);
      await repo.completeWizard(informalDraft);
      final savedInformal = await repo.loadDraft('user-informal-001');

      // 2. Student Worker Profile
      const studentDraft = SeekerProfileDraft(
        userId: 'user-student-002',
        fullName: 'Ananya Sharma',
        seekerType: 'student',
        selectedSkillIds: ['skill-tutoring'],
        subjectsInterests: ['Mathematics', 'Physics', 'Coding'],
        collegeName: 'BMS College of Engineering',
        courseName: 'B.E. Computer Science',
        regNoMasked: 'XXXXXXS108',
        preferredHoursJson: {'weekly_hours': 15},
        experienceYears: 1.0,
        hourlyRatePaise: 15000,
        workingDays: ['Sat', 'Sun'],
        homeAddress: 'Yelahanka, Bengaluru',
        serviceRadiusKm: 8.0,
      );
      await repo.saveStep(studentDraft, 7);
      await repo.completeWizard(studentDraft);
      final savedStudent = await repo.loadDraft('user-student-002');

      // 3. Part-Time Worker Profile
      const partTimeDraft = SeekerProfileDraft(
        userId: 'user-parttime-003',
        fullName: 'Kiran Kumar',
        seekerType: 'part_time',
        selectedSkillIds: ['skill-delivery', 'skill-packing'],
        preferredHoursJson: {'shift': 'evening'},
        experienceYears: 2.5,
        hourlyRatePaise: 12000,
        dailyRatePaise: 60000,
        workingDays: ['Mon', 'Wed', 'Fri'],
        homeAddress: 'HSR Layout, Bengaluru',
        serviceRadiusKm: 12.0,
      );
      await repo.saveStep(partTimeDraft, 7);
      await repo.completeWizard(partTimeDraft);
      final savedPartTime = await repo.loadDraft('user-parttime-003');

      // Compare Saved Rows
      // Informal verification
      expect(savedInformal.seekerType, equals('informal'));
      expect(savedInformal.hasDrivingLicence, isTrue);
      expect(savedInformal.selectedSkillIds.length, equals(2));
      expect(savedInformal.onboardingComplete, isTrue);

      // Student verification
      expect(savedStudent.seekerType, equals('student'));
      expect(savedStudent.collegeName, equals('BMS College of Engineering'));
      expect(savedStudent.courseName, equals('B.E. Computer Science'));
      expect(savedStudent.regNoMasked, equals('XXXXXXS108'));
      expect(savedStudent.subjectsInterests, contains('Coding'));
      expect(savedStudent.preferredHoursJson['weekly_hours'], equals(15));
      expect(savedStudent.onboardingComplete, isTrue);

      // Part-time verification
      expect(savedPartTime.seekerType, equals('part_time'));
      expect(savedPartTime.preferredHoursJson['shift'], equals('evening'));
      expect(savedPartTime.workingDays, contains('Wed'));
      expect(savedPartTime.onboardingComplete, isTrue);
    });
  });
}
