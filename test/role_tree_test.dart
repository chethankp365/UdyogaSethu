import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/features/onboarding/data/role_tree_service.dart';
import 'package:udyogasethu/features/onboarding/domain/pending_role_selection.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RoleTreeNotifier Unit Tests', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state starts at Step 1 with no selection', () {
      final state = container.read(roleTreeProvider);
      expect(state.currentStep, 1);
      expect(state.selectedCategory, null);
      expect(state.selectedRole, null);
      expect(state.selectedSeekerType, null);
      expect(state.completedSelection, null);
      expect(state.canContinue, false);
    });

    test('Path 1: Selecting Farmer completes selection at Step 1', () {
      final notifier = container.read(roleTreeProvider.notifier);
      notifier.selectCategory('farmer');

      final state = container.read(roleTreeProvider);
      expect(state.currentStep, 1);
      expect(state.selectedCategory, 'farmer');
      expect(state.selectedRole, UserRole.farmer);
      expect(state.canContinue, true);
      expect(
        state.completedSelection,
        const PendingRoleSelection(role: UserRole.farmer),
      );
    });

    test('Path 2: Worker -> Provider completes selection at Step 2', () {
      final notifier = container.read(roleTreeProvider.notifier);
      notifier.selectCategory('worker');
      notifier.confirmStep1();

      var state = container.read(roleTreeProvider);
      expect(state.currentStep, 2);
      expect(state.canContinue, false);

      notifier.selectRole(UserRole.provider);
      state = container.read(roleTreeProvider);
      expect(state.canContinue, true);
      expect(
        state.completedSelection,
        const PendingRoleSelection(role: UserRole.provider),
      );
    });

    test('Path 3: Worker -> Seeker -> Informal completes selection at Step 3', () {
      final notifier = container.read(roleTreeProvider.notifier);
      notifier.selectCategory('worker');
      notifier.confirmStep1();
      notifier.selectRole(UserRole.seeker);
      notifier.confirmStep2();

      var state = container.read(roleTreeProvider);
      expect(state.currentStep, 3);
      expect(state.canContinue, false);

      notifier.selectSeekerType(SeekerType.informal);
      state = container.read(roleTreeProvider);
      expect(state.canContinue, true);
      expect(
        state.completedSelection,
        const PendingRoleSelection(role: UserRole.seeker, seekerType: SeekerType.informal),
      );
    });

    test('Path 4: Worker -> Seeker -> Student completes selection at Step 3', () {
      final notifier = container.read(roleTreeProvider.notifier);
      notifier.selectCategory('worker');
      notifier.confirmStep1();
      notifier.selectRole(UserRole.seeker);
      notifier.confirmStep2();
      notifier.selectSeekerType(SeekerType.student);

      final state = container.read(roleTreeProvider);
      expect(
        state.completedSelection,
        const PendingRoleSelection(role: UserRole.seeker, seekerType: SeekerType.student),
      );
    });

    test('Path 5: Worker -> Seeker -> PartTime completes selection at Step 3', () {
      final notifier = container.read(roleTreeProvider.notifier);
      notifier.selectCategory('worker');
      notifier.confirmStep1();
      notifier.selectRole(UserRole.seeker);
      notifier.confirmStep2();
      notifier.selectSeekerType(SeekerType.partTime);

      final state = container.read(roleTreeProvider);
      expect(
        state.completedSelection,
        const PendingRoleSelection(role: UserRole.seeker, seekerType: SeekerType.partTime),
      );
    });

    test('Back navigation clears downstream choices correctly', () {
      final notifier = container.read(roleTreeProvider.notifier);
      notifier.selectCategory('worker');
      notifier.confirmStep1();
      notifier.selectRole(UserRole.seeker);
      notifier.confirmStep2();
      notifier.selectSeekerType(SeekerType.student);

      // Back from step 3 to step 2
      final back1 = notifier.goBack();
      expect(back1, true);
      var state = container.read(roleTreeProvider);
      expect(state.currentStep, 2);
      expect(state.selectedSeekerType, null);
      expect(state.completedSelection, null);

      // Back from step 2 to step 1
      final back2 = notifier.goBack();
      expect(back2, true);
      state = container.read(roleTreeProvider);
      expect(state.currentStep, 1);
      expect(state.selectedRole, null);
      expect(state.completedSelection, null);

      // Back from step 1 returns false
      final back3 = notifier.goBack();
      expect(back3, false);
    });

    test('Changing an earlier choice clears later choices', () {
      final notifier = container.read(roleTreeProvider.notifier);
      notifier.selectCategory('worker');
      notifier.confirmStep1();
      notifier.selectRole(UserRole.seeker);
      notifier.confirmStep2();
      notifier.selectSeekerType(SeekerType.informal);

      // Go back to step 2 and select Provider
      notifier.goBack();
      notifier.selectRole(UserRole.provider);

      final state = container.read(roleTreeProvider);
      expect(state.currentStep, 2);
      expect(state.selectedSeekerType, null);
      expect(
        state.completedSelection,
        const PendingRoleSelection(role: UserRole.provider),
      );
    });
  });
}
