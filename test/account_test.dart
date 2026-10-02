import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/features/account/data/account_repository.dart';
import 'package:udyogasethu/features/account/domain/linked_accounts_state.dart';
import 'package:udyogasethu/features/account/domain/user_settings.dart';
import 'package:udyogasethu/features/onboarding/domain/pending_role_selection.dart';

class FakeAccountRepository implements AccountRepository {
  UserSettings settings = const UserSettings();
  UserRole activeRole = UserRole.seeker;
  List<UserRole> assignedRoles = [UserRole.seeker];
  SeekerType seekerType = SeekerType.informal;
  bool deletedAccount = false;

  @override
  Future<UserSettings> loadSettings(String userId) async {
    return settings;
  }

  @override
  Future<void> saveSettings({required String userId, required UserSettings settings}) async {
    this.settings = settings;
  }

  @override
  Future<void> switchActiveRole({required String userId, required UserRole role}) async {
    activeRole = role;
  }

  @override
  Future<void> addRole({required String userId, required UserRole role}) async {
    if (!assignedRoles.contains(role)) {
      assignedRoles.add(role);
    }
    activeRole = role;
  }

  @override
  Future<void> updateSeekerType({required String userId, required SeekerType newType}) async {
    seekerType = newType;
  }

  @override
  Future<LinkedAccountsState> getLinkedAccounts() async {
    return const LinkedAccountsState(
      phone: '+919900000001',
      isPhoneVerified: true,
      googleEmail: 'user@example.com',
      isGoogleLinked: true,
    );
  }

  @override
  Future<String> exportUserData() async {
    return '{\n  "export_timestamp": "2026-10-02T23:55:00Z",\n  "profile": {\n    "full_name": "Test User"\n  }\n}';
  }

  @override
  Future<void> deleteAccount() async {
    deletedAccount = true;
  }
}

void main() {
  group('UserSettings Domain Tests', () {
    test('UserSettings default values', () {
      const s = UserSettings();
      expect(s.language, 'en');
      expect(s.simpleMode, false);
      expect(s.textScale, 1.00);
      expect(s.voiceHints, true);
      expect(s.lowDataMode, false);
    });

    test('UserSettings JSON serialization and copyWith', () {
      const original = UserSettings(
        language: 'kn',
        simpleMode: true,
        textScale: 1.15,
        voiceHints: false,
        lowDataMode: true,
      );

      final json = original.toJson();
      final restored = UserSettings.fromJson(json);

      expect(restored.language, 'kn');
      expect(restored.simpleMode, true);
      expect(restored.textScale, 1.15);
      expect(restored.voiceHints, false);
      expect(restored.lowDataMode, true);

      final updated = original.copyWith(textScale: 1.25);
      expect(updated.textScale, 1.25);
      expect(updated.simpleMode, true);
    });
  });

  group('LinkedAccountsState Domain Tests', () {
    test('canUnlinkGoogle safeguards', () {
      const stateVerified = LinkedAccountsState(
        phone: '+919900000001',
        isPhoneVerified: true,
        isGoogleLinked: true,
      );
      expect(stateVerified.canUnlinkGoogle, isTrue);

      const stateNoPhone = LinkedAccountsState(
        phone: null,
        isPhoneVerified: false,
        isGoogleLinked: true,
      );
      expect(stateNoPhone.canUnlinkGoogle, isFalse);
    });
  });

  group('FakeAccountRepository Tests', () {
    late FakeAccountRepository repo;

    setUp(() {
      repo = FakeAccountRepository();
    });

    test('saveSettings updates settings state', () async {
      await repo.saveSettings(
        userId: 'u-1',
        settings: const UserSettings(simpleMode: true, textScale: 1.20),
      );
      final loaded = await repo.loadSettings('u-1');
      expect(loaded.simpleMode, isTrue);
      expect(loaded.textScale, 1.20);
    });

    test('switchActiveRole updates activeRole', () async {
      await repo.switchActiveRole(userId: 'u-1', role: UserRole.farmer);
      expect(repo.activeRole, equals(UserRole.farmer));
    });

    test('addRole appends to assignedRoles and updates activeRole', () async {
      await repo.addRole(userId: 'u-1', role: UserRole.provider);
      expect(repo.assignedRoles, contains(UserRole.provider));
      expect(repo.activeRole, equals(UserRole.provider));
    });

    test('exportUserData returns formatted JSON', () async {
      final jsonStr = await repo.exportUserData();
      expect(jsonStr, contains('export_timestamp'));
      expect(jsonStr, contains('Test User'));
    });

    test('deleteAccount sets deletedAccount flag', () async {
      await repo.deleteAccount();
      expect(repo.deletedAccount, isTrue);
    });
  });
}
