import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/provider/data/provider_profile_repository.dart';
import 'package:udyogasethu/features/provider/domain/provider_profile_draft.dart';

class FakeProviderProfileRepository implements ProviderProfileRepository {
  ProviderProfileDraft draft = const ProviderProfileDraft(userId: 'test-provider-123');
  bool loggedConsent = false;
  bool completedWizard = false;

  @override
  Future<ProviderProfileDraft> loadDraft(String userId) async {
    return draft;
  }

  @override
  Future<void> saveStep(ProviderProfileDraft newDraft, int step) async {
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
  Future<void> logConsent({required String consentType}) async {
    loggedConsent = true;
  }

  @override
  Future<void> completeWizard(ProviderProfileDraft newDraft) async {
    completedWizard = true;
    draft = newDraft.copyWith(currentStep: 6, onboardingComplete: true);
  }
}

void main() {
  group('ProviderProfileDraft Domain Tests', () {
    test('ProviderProfileDraft default values and getters', () {
      const d = ProviderProfileDraft(userId: 'p-1');
      expect(d.currentStep, 1);
      expect(d.providerType, 'household');
      expect(d.isHousehold, true);
      expect(d.isEmployer, false);
      expect(d.typicalCrewSize, 5);
    });

    test('ProviderType employer getters work correctly', () {
      const d = ProviderProfileDraft(
        userId: 'p-2',
        providerType: 'employer',
        orgName: 'Sethu Infra Ltd',
        categoriesHiring: ['Construction & Labour', 'Security Guards'],
        typicalCrewSize: 15,
      );

      expect(d.isHousehold, false);
      expect(d.isEmployer, true);
      expect(d.orgName, 'Sethu Infra Ltd');
      expect(d.categoriesHiring.length, 2);
      expect(d.typicalCrewSize, 15);
    });

    test('Household vs Employer JSON serialization & deserialization cycle', () {
      const householdDraft = ProviderProfileDraft(
        userId: 'p-100',
        fullName: 'Lakshmi Hegde',
        providerType: 'household',
        addressLine1: '#102 Green Park Apartments',
        landmark: 'Near Bus Stop',
        city: 'Bengaluru',
        pincode: '560034',
        deliveryDropoffInstruction: 'Leave at security desk',
        gateCode: '9876',
        gpsConsentGranted: true,
        notificationsConsentGranted: true,
      );

      final jsonH = householdDraft.toJson();
      final restoredH = ProviderProfileDraft.fromJson(jsonH);

      expect(restoredH.userId, householdDraft.userId);
      expect(restoredH.fullName, householdDraft.fullName);
      expect(restoredH.isHousehold, true);
      expect(restoredH.addressLine1, '#102 Green Park Apartments');
      expect(restoredH.deliveryDropoffInstruction, 'Leave at security desk');
      expect(restoredH.gateCode, '9876');

      const employerDraft = ProviderProfileDraft(
        userId: 'p-200',
        fullName: 'Rajesh Sharma',
        providerType: 'employer',
        orgName: 'Metro Builders Corp',
        siteAddressLine1: 'Plot 88, Industrial Layout',
        siteLandmark: 'Opposite Metro Station',
        categoriesHiring: ['Construction & Labour', 'Maintenance & Electrician'],
        typicalCrewSize: 25,
      );

      final jsonE = employerDraft.toJson();
      final restoredE = ProviderProfileDraft.fromJson(jsonE);

      expect(restoredE.userId, employerDraft.userId);
      expect(restoredE.isEmployer, true);
      expect(restoredE.orgName, 'Metro Builders Corp');
      expect(restoredE.categoriesHiring, contains('Construction & Labour'));
      expect(restoredE.typicalCrewSize, 25);
    });
  });

  group('FakeProviderProfileRepository Tests', () {
    late FakeProviderProfileRepository repo;

    setUp(() {
      repo = FakeProviderProfileRepository();
    });

    test('loadDraft returns initial draft', () async {
      final draft = await repo.loadDraft('test-provider-123');
      expect(draft.userId, equals('test-provider-123'));
      expect(draft.currentStep, equals(1));
    });

    test('saveStep updates currentStep and household draft data', () async {
      const draft = ProviderProfileDraft(
        userId: 'test-provider-123',
        fullName: 'Kiran Kumar',
        providerType: 'household',
        addressLine1: '#44 3rd Main',
      );
      await repo.saveStep(draft, 2);
      final loaded = await repo.loadDraft('test-provider-123');
      expect(loaded.currentStep, equals(2));
      expect(loaded.fullName, equals('Kiran Kumar'));
      expect(loaded.addressLine1, equals('#44 3rd Main'));
    });

    test('saveStep saves employer provider data correctly', () async {
      const draft = ProviderProfileDraft(
        userId: 'test-provider-123',
        fullName: 'Anil Mehta',
        providerType: 'employer',
        orgName: 'Mehta Logistics',
        typicalCrewSize: 12,
      );
      await repo.saveStep(draft, 3);
      final loaded = await repo.loadDraft('test-provider-123');
      expect(loaded.currentStep, equals(3));
      expect(loaded.isEmployer, isTrue);
      expect(loaded.orgName, equals('Mehta Logistics'));
      expect(loaded.typicalCrewSize, equals(12));
    });

    test('uploadAvatar returns public URL', () async {
      final url = await repo.uploadAvatar(
        userId: 'p-1',
        bytes: [1, 2, 3],
        filename: 'avatar.jpg',
      );
      expect(url, contains('https://example.com/avatars/p-1/avatar.jpg'));
    });

    test('logConsent sets consent flag', () async {
      await repo.logConsent(consentType: 'gps');
      expect(repo.loggedConsent, isTrue);
    });

    test('completeWizard sets onboardingComplete = true and step 6', () async {
      const draft = ProviderProfileDraft(userId: 'test-provider-123');
      await repo.completeWizard(draft);
      final loaded = await repo.loadDraft('test-provider-123');
      expect(loaded.currentStep, equals(6));
      expect(loaded.onboardingComplete, isTrue);
      expect(repo.completedWizard, isTrue);
    });
  });
}
