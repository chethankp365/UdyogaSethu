import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/seeker/data/seeker_profile_repository.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_profile_draft.dart';

class FakeSeekerProfileRepository implements SeekerProfileRepository {
  SeekerProfileDraft draft = const SeekerProfileDraft(userId: 'test-user-123');
  bool loggedConsent = false;

  @override
  Future<SeekerProfileDraft> loadDraft(String userId) async {
    return draft;
  }

  @override
  Future<void> saveStep(SeekerProfileDraft newDraft, int step) async {
    draft = newDraft.copyWith(currentStep: step);
  }

  @override
  Future<String> uploadAvatar({
    required String userId,
    required List<int> bytes,
    required String filename,
  }) async {
    return 'https://example.com/avatars/$userId/$filename';
  }

  @override
  Future<List<ServiceCategoryItem>> fetchCategories() async {
    return [
      const ServiceCategoryItem(
        id: 'cat-1',
        slug: 'construction',
        names: {'en': 'Construction', 'kn': 'ಕಟ್ಟಡ ನಿರ್ಮಾಣ'},
      ),
      const ServiceCategoryItem(
        id: 'cat-2',
        slug: 'plumbing',
        names: {'en': 'Plumbing', 'kn': 'ಪ್ಲಂಬಿಂಗ್'},
      ),
    ];
  }

  @override
  Future<List<SkillItem>> fetchSkills() async {
    return [
      const SkillItem(
        id: 'skill-1',
        categoryId: 'cat-1',
        names: {'en': 'Masonry', 'kn': 'ಗಾರೆ ಕೆಲಸ'},
      ),
      const SkillItem(
        id: 'skill-2',
        categoryId: 'cat-2',
        names: {'en': 'Pipe Repair', 'kn': 'ಪೈಪ್ ರಿಪೇರಿ'},
      ),
    ];
  }

  @override
  Future<WageBandResult?> fetchWageBand({String? categoryId, String? city}) async {
    return const WageBandResult(minPaise: 70000, maxPaise: 120000, unit: 'day');
  }

  @override
  Future<void> logGpsConsent() async {
    loggedConsent = true;
  }

  @override
  Future<void> completeWizard(SeekerProfileDraft newDraft) async {
    draft = newDraft.copyWith(currentStep: 7, onboardingComplete: true);
  }
}

void main() {
  group('SeekerProfileDraft Unit Tests', () {
    test('Default values and copyWith work correctly', () {
      const draft = SeekerProfileDraft(userId: 'user-1');
      expect(draft.currentStep, equals(1));
      expect(draft.seekerType, equals('informal'));
      expect(draft.onboardingComplete, isFalse);

      final updated = draft.copyWith(
        fullName: 'Chethan Kumar',
        currentStep: 3,
        experienceYears: 4.5,
        dailyRatePaise: 80000,
      );

      expect(updated.fullName, equals('Chethan Kumar'));
      expect(updated.currentStep, equals(3));
      expect(updated.experienceYears, equals(4.5));
      expect(updated.dailyRatePaise, equals(80000));
    });

    test('USN Reg No masking helper masks correctly', () {
      expect(SeekerProfileDraft.maskRegNo('1BM23CS108'), equals('XXXXXXS108'));
      expect(SeekerProfileDraft.maskRegNo('1234'), equals('1234'));
      expect(SeekerProfileDraft.maskRegNo('ABC12345'), equals('XXXX2345'));
    });

    test('toJson and fromJson cycle retains data', () {
      const draft = SeekerProfileDraft(
        userId: 'user-77',
        currentStep: 4,
        fullName: 'Test Seeker',
        languages: ['kn', 'en'],
        seekerType: 'student',
        collegeName: 'BMSCE',
        regNoMasked: 'XXXXXX108',
      );

      final jsonMap = draft.toJson();
      final restored = SeekerProfileDraft.fromJson(jsonMap);

      expect(restored.userId, equals('user-77'));
      expect(restored.currentStep, equals(4));
      expect(restored.fullName, equals('Test Seeker'));
      expect(restored.seekerType, equals('student'));
      expect(restored.collegeName, equals('BMSCE'));
    });
  });

  group('FakeSeekerProfileRepository Tests', () {
    late FakeSeekerProfileRepository repo;

    setUp(() {
      repo = FakeSeekerProfileRepository();
    });

    test('loadDraft returns initial draft', () async {
      final draft = await repo.loadDraft('test-user-123');
      expect(draft.userId, equals('test-user-123'));
      expect(draft.currentStep, equals(1));
    });

    test('saveStep updates currentStep and data', () async {
      const draft = SeekerProfileDraft(
        userId: 'test-user-123',
        fullName: 'Ramesh Gowda',
      );
      await repo.saveStep(draft, 3);
      final loaded = await repo.loadDraft('test-user-123');
      expect(loaded.currentStep, equals(3));
      expect(loaded.fullName, equals('Ramesh Gowda'));
    });

    test('completeWizard marks onboarding_complete', () async {
      const draft = SeekerProfileDraft(userId: 'test-user-123');
      await repo.completeWizard(draft);
      final loaded = await repo.loadDraft('test-user-123');
      expect(loaded.currentStep, equals(7));
      expect(loaded.onboardingComplete, isTrue);
    });

    test('uploadAvatar returns public URL', () async {
      final url = await repo.uploadAvatar(
        userId: 'user-1',
        bytes: [1, 2, 3],
        filename: 'photo.jpg',
      );
      expect(url, contains('https://example.com/avatars/user-1/photo.jpg'));
    });

    test('logGpsConsent sets consent flag', () async {
      await repo.logGpsConsent();
      expect(repo.loggedConsent, isTrue);
    });
  });
}
