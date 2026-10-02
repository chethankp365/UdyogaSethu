import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/farmer/data/farmer_profile_repository.dart';
import 'package:udyogasethu/features/farmer/domain/farmer_profile_draft.dart';

class FakeFarmerProfileRepository implements FarmerProfileRepository {
  FarmerProfileDraft draft = const FarmerProfileDraft(userId: 'test-farmer-123');
  bool loggedGpsConsent = false;
  bool completedWizard = false;

  @override
  Future<FarmerProfileDraft> loadDraft(String userId) async {
    return draft;
  }

  @override
  Future<void> saveStep(FarmerProfileDraft newDraft, int step) async {
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
  Future<String> uploadOrganicCert({
    required String userId,
    required List<int> bytes,
    required String filename,
  }) async {
    return '$userId/$filename';
  }

  @override
  Future<void> logGpsConsent() async {
    loggedGpsConsent = true;
  }

  @override
  Future<void> completeWizard(FarmerProfileDraft newDraft) async {
    completedWizard = true;
    draft = newDraft.copyWith(currentStep: 5, onboardingComplete: true);
  }
}

void main() {
  group('FarmerProfileDraft Domain Tests', () {
    test('FarmerProfileDraft default values and badges', () {
      const d = FarmerProfileDraft(userId: 'f-1');
      expect(d.currentStep, 1);
      expect(d.acres, 1.0);
      expect(d.hasApmcBadge, false);
      expect(d.hasKccBadge, false);
      expect(d.hasOrganicBadge, false);
    });

    test('Badge evaluation logic works correctly', () {
      const d = FarmerProfileDraft(
        userId: 'f-1',
        apmcRegistration: 'APMC-123',
        kccStatus: 'approved',
        organicCertStatus: 'pending',
      );

      expect(d.hasApmcBadge, true);
      expect(d.hasKccBadge, true);
      expect(d.hasOrganicBadge, true);
    });

    test('JSON serialization & deserialization cycle', () {
      const original = FarmerProfileDraft(
        userId: 'f-99',
        fullName: 'Ramesh Gowda',
        farmName: 'Green Valley Organic',
        clusterVillage: 'Devanahalli',
        acres: 5.5,
        soilType: 'Red Soil',
        soilPh: 6.5,
        primaryCrops: ['Tomatoes', 'Potatoes'],
        farmingMethod: 'organic',
        apmcRegistration: 'APMC-KA-2024',
        kccStatus: 'approved',
        organicCertStatus: 'pending',
        organicCertPath: 'f-99/cert.pdf',
        deliveryAvailable: true,
        pickupAvailable: true,
        deliveryRadiusKm: 20.0,
        leadTime: '1 day',
        onboardingComplete: false,
      );

      final json = original.toJson();
      final restored = FarmerProfileDraft.fromJson(json);

      expect(restored.userId, original.userId);
      expect(restored.fullName, original.fullName);
      expect(restored.farmName, original.farmName);
      expect(restored.acres, 5.5);
      expect(restored.soilPh, 6.5);
      expect(restored.primaryCrops, ['Tomatoes', 'Potatoes']);
      expect(restored.hasApmcBadge, true);
      expect(restored.hasKccBadge, true);
      expect(restored.hasOrganicBadge, true);
    });
  });

  group('FakeFarmerProfileRepository Tests', () {
    late FakeFarmerProfileRepository repo;

    setUp(() {
      repo = FakeFarmerProfileRepository();
    });

    test('loadDraft returns initial draft', () async {
      final draft = await repo.loadDraft('test-farmer-123');
      expect(draft.userId, equals('test-farmer-123'));
      expect(draft.currentStep, equals(1));
    });

    test('saveStep updates currentStep and draft data', () async {
      const draft = FarmerProfileDraft(
        userId: 'test-farmer-123',
        fullName: 'Siddappa Gowda',
        farmName: 'Annapurna Farm',
      );
      await repo.saveStep(draft, 2);
      final loaded = await repo.loadDraft('test-farmer-123');
      expect(loaded.currentStep, equals(2));
      expect(loaded.fullName, equals('Siddappa Gowda'));
      expect(loaded.farmName, equals('Annapurna Farm'));
    });

    test('uploadAvatar returns public URL', () async {
      final url = await repo.uploadAvatar(
        userId: 'f-1',
        bytes: [1, 2, 3],
        filename: 'avatar.jpg',
      );
      expect(url, contains('https://example.com/avatars/f-1/avatar.jpg'));
    });

    test('uploadOrganicCert returns relative private path', () async {
      final path = await repo.uploadOrganicCert(
        userId: 'f-1',
        bytes: [1, 2, 3],
        filename: 'cert.pdf',
      );
      expect(path, equals('f-1/cert.pdf'));
    });

    test('logGpsConsent sets consent flag', () async {
      await repo.logGpsConsent();
      expect(repo.loggedGpsConsent, isTrue);
    });

    test('completeWizard sets onboardingComplete = true and step 5', () async {
      const draft = FarmerProfileDraft(userId: 'test-farmer-123');
      await repo.completeWizard(draft);
      final loaded = await repo.loadDraft('test-farmer-123');
      expect(loaded.currentStep, equals(5));
      expect(loaded.onboardingComplete, isTrue);
      expect(repo.completedWizard, isTrue);
    });
  });
}
