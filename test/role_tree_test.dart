import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/features/onboarding/data/role_selection_service.dart';
import 'package:udyogasethu/features/onboarding/presentation/role_tree_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

Widget _createTestWidget({
  required Widget child,
  List overrides = const [],
  GoRouter? router,
}) {
  if (router != null) {
    return ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp.router(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PendingRoleSelection Unit Tests', () {
    test('Initial state is step 1 with null selections', () {
      const selection = PendingRoleSelection();
      expect(selection.currentStep, equals(1));
      expect(selection.primaryRole, isNull);
      expect(selection.secondaryRole, isNull);
      expect(selection.seekerType, isNull);
      expect(selection.resolvedRole, isNull);
      expect(selection.isComplete, isFalse);
      expect(selection.hasSelectionForCurrentStep, isFalse);
    });

    test('Path 1: Farmer selection path', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(roleSelectionProvider.notifier);

      notifier.selectPrimaryRole('farmer');
      final state = container.read(roleSelectionProvider);

      expect(state.primaryRole, equals('farmer'));
      expect(state.resolvedRole, equals('farmer'));
      expect(state.hasSelectionForCurrentStep, isTrue);
      expect(state.isComplete, isTrue);

      final isFinished = notifier.advanceStep();
      expect(isFinished, isTrue);
    });

    test('Path 2: Worker -> Job Provider selection path', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(roleSelectionProvider.notifier);

      notifier.selectPrimaryRole('worker');
      expect(container.read(roleSelectionProvider).hasSelectionForCurrentStep, isTrue);

      final step1Finished = notifier.advanceStep();
      expect(step1Finished, isFalse);
      expect(container.read(roleSelectionProvider).currentStep, equals(2));

      notifier.selectSecondaryRole('provider');
      final state = container.read(roleSelectionProvider);
      expect(state.primaryRole, equals('worker'));
      expect(state.secondaryRole, equals('provider'));
      expect(state.resolvedRole, equals('provider'));
      expect(state.isComplete, isTrue);

      final step2Finished = notifier.advanceStep();
      expect(step2Finished, isTrue);
    });

    test('Path 3: Worker -> Job Seeker -> Informal Worker path', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(roleSelectionProvider.notifier);

      notifier.selectPrimaryRole('worker');
      notifier.advanceStep();

      notifier.selectSecondaryRole('seeker');
      expect(container.read(roleSelectionProvider).currentStep, equals(2));

      final step2Finished = notifier.advanceStep();
      expect(step2Finished, isFalse);
      expect(container.read(roleSelectionProvider).currentStep, equals(3));

      notifier.selectSeekerType('informal');
      final state = container.read(roleSelectionProvider);
      expect(state.primaryRole, equals('worker'));
      expect(state.secondaryRole, equals('seeker'));
      expect(state.seekerType, equals('informal'));
      expect(state.resolvedRole, equals('seeker'));
      expect(state.isComplete, isTrue);

      final step3Finished = notifier.advanceStep();
      expect(step3Finished, isTrue);
    });

    test('Path 4: Worker -> Job Seeker -> Student path', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(roleSelectionProvider.notifier);

      notifier.selectPrimaryRole('worker');
      notifier.advanceStep();
      notifier.selectSecondaryRole('seeker');
      notifier.advanceStep();

      notifier.selectSeekerType('student');
      final state = container.read(roleSelectionProvider);
      expect(state.seekerType, equals('student'));
      expect(state.resolvedRole, equals('seeker'));
      expect(state.isComplete, isTrue);
    });

    test('Path 5: Worker -> Job Seeker -> Part-time path', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(roleSelectionProvider.notifier);

      notifier.selectPrimaryRole('worker');
      notifier.advanceStep();
      notifier.selectSecondaryRole('seeker');
      notifier.advanceStep();

      notifier.selectSeekerType('part_time');
      final state = container.read(roleSelectionProvider);
      expect(state.seekerType, equals('part_time'));
      expect(state.resolvedRole, equals('seeker'));
      expect(state.isComplete, isTrue);
    });

    test('Changing primary role from worker to farmer clears secondaryRole & seekerType', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(roleSelectionProvider.notifier);

      notifier.selectPrimaryRole('worker');
      notifier.advanceStep();
      notifier.selectSecondaryRole('seeker');
      notifier.advanceStep();
      notifier.selectSeekerType('informal');

      // Now change primary role to farmer
      notifier.selectPrimaryRole('farmer');
      final state = container.read(roleSelectionProvider);
      expect(state.primaryRole, equals('farmer'));
      expect(state.secondaryRole, isNull);
      expect(state.seekerType, isNull);
      expect(state.resolvedRole, equals('farmer'));
    });

    test('Changing secondary role from seeker to provider clears seekerType', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(roleSelectionProvider.notifier);

      notifier.selectPrimaryRole('worker');
      notifier.advanceStep();
      notifier.selectSecondaryRole('seeker');
      notifier.advanceStep();
      notifier.selectSeekerType('student');

      // Now change secondary role to provider
      notifier.selectSecondaryRole('provider');
      final state = container.read(roleSelectionProvider);
      expect(state.secondaryRole, equals('provider'));
      expect(state.seekerType, isNull);
      expect(state.resolvedRole, equals('provider'));
    });

    test('Back navigation decreases step by 1', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(roleSelectionProvider.notifier);

      notifier.selectPrimaryRole('worker');
      notifier.advanceStep(); // Step 2
      notifier.selectSecondaryRole('seeker');
      notifier.advanceStep(); // Step 3
      expect(container.read(roleSelectionProvider).currentStep, equals(3));

      notifier.goBackStep();
      expect(container.read(roleSelectionProvider).currentStep, equals(2));

      notifier.goBackStep();
      expect(container.read(roleSelectionProvider).currentStep, equals(1));

      // Cannot go below step 1
      notifier.goBackStep();
      expect(container.read(roleSelectionProvider).currentStep, equals(1));
    });

    test('JSON serialization & deserialization works correctly', () {
      const original = PendingRoleSelection(
        primaryRole: 'worker',
        secondaryRole: 'seeker',
        seekerType: 'informal',
        currentStep: 3,
      );

      final json = original.toJson();
      final restored = PendingRoleSelection.fromJson(json);

      expect(restored, equals(original));
      expect(restored.primaryRole, equals('worker'));
      expect(restored.secondaryRole, equals('seeker'));
      expect(restored.seekerType, equals('informal'));
      expect(restored.currentStep, equals(3));
    });
  });

  group('RoleTreeScreen Widget Tests', () {
    testWidgets('Step 1 renders correctly with disabled Continue button initially',
        (tester) async {
      await tester.pumpWidget(_createTestWidget(child: const RoleTreeScreen()));
      await tester.pumpAndSettle();

      // Verify Title
      expect(find.text('Who are you?'), findsOneWidget);

      // Verify Worker and Farmer cards
      expect(find.byKey(const Key('role_card_worker')), findsOneWidget);
      expect(find.byKey(const Key('role_card_farmer')), findsOneWidget);

      // Verify Continue button is disabled initially
      final continueButton = tester.widget<ElevatedButton>(
        find.descendant(
          of: find.byKey(const Key('role_tree_continue_button')),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(continueButton.onPressed, isNull);

      // Verify Login link is displayed
      expect(find.byKey(const Key('role_tree_login_button')), findsOneWidget);
      expect(find.text('Already have an account? Log in'), findsOneWidget);
    });

    testWidgets('Selecting Worker enables Continue and advances to Step 2', (tester) async {
      await tester.pumpWidget(_createTestWidget(child: const RoleTreeScreen()));
      await tester.pumpAndSettle();

      // Tap Worker card
      await tester.tap(find.byKey(const Key('role_card_worker')));
      await tester.pumpAndSettle();

      // Verify Continue button is now enabled
      final continueButton = tester.widget<ElevatedButton>(
        find.descendant(
          of: find.byKey(const Key('role_tree_continue_button')),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(continueButton.onPressed, isNotNull);

      // Tap Continue
      await tester.tap(find.byKey(const Key('role_tree_continue_button')));
      await tester.pumpAndSettle();

      // Verify Step 2 UI is rendered
      expect(find.text('What do you want to do?'), findsOneWidget);
      expect(find.text('Worker'), findsOneWidget); // Breadcrumb
      expect(find.byKey(const Key('role_card_seeker')), findsOneWidget);
      expect(find.byKey(const Key('role_card_provider')), findsOneWidget);
    });

    testWidgets('Step 2 to Step 3 flow with breadcrumbs and back navigation', (tester) async {
      await tester.pumpWidget(_createTestWidget(child: const RoleTreeScreen()));
      await tester.pumpAndSettle();

      // Step 1: Worker
      await tester.tap(find.byKey(const Key('role_card_worker')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('role_tree_continue_button')));
      await tester.pumpAndSettle();

      // Step 2: Job Seeker
      await tester.tap(find.byKey(const Key('role_card_seeker')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('role_tree_continue_button')));
      await tester.pumpAndSettle();

      // Step 3: Tell us about you
      expect(find.text('Tell us about you'), findsOneWidget);
      expect(find.text('Worker > Job Seeker'), findsOneWidget); // Breadcrumb
      expect(find.byKey(const Key('seeker_type_informal')), findsOneWidget);
      expect(find.byKey(const Key('seeker_type_student')), findsOneWidget);
      expect(find.byKey(const Key('seeker_type_part_time')), findsOneWidget);

      // Test Back button on Step 3
      await tester.tap(find.byKey(const Key('role_tree_back_button')));
      await tester.pumpAndSettle();

      // Should return to Step 2
      expect(find.text('What do you want to do?'), findsOneWidget);
    });

    testWidgets('Tapping Login link navigates to /login', (tester) async {
      final router = GoRouter(
        initialLocation: AppRoutes.roleTree,
        routes: [
          GoRoute(
            path: AppRoutes.roleTree,
            builder: (context, state) => const RoleTreeScreen(),
          ),
          GoRoute(
            path: AppRoutes.login,
            builder: (context, state) => const Scaffold(
              body: Text('Login Screen Landmark'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(_createTestWidget(router: router, child: const SizedBox()));
      await tester.pumpAndSettle();

      // Tap Login link at bottom
      await tester.tap(find.byKey(const Key('role_tree_login_button')));
      await tester.pumpAndSettle();

      expect(find.text('Login Screen Landmark'), findsOneWidget);
    });
  });
}
