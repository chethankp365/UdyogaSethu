import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udyogasethu/features/onboarding/presentation/role_tree_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

Widget createRoleTreeTestWidget() {
  return const ProviderScope(
    child: MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: RoleTreeScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RoleTreeScreen Widget Tests', () {
    testWidgets('Renders Step 1 with Worker and Farmer cards', (tester) async {
      await tester.pumpWidget(createRoleTreeTestWidget());
      await tester.pumpAndSettle();

      // Check Title
      expect(find.text('Who are you?'), findsOneWidget);

      // Check Cards
      expect(find.byKey(const Key('cardWorker')), findsOneWidget);
      expect(find.byKey(const Key('cardFarmer')), findsOneWidget);

      // Check Speaker button and Direct Login link
      expect(find.byKey(const Key('roleTreeSpeakerButton')), findsOneWidget);
      expect(find.byKey(const Key('directLoginButton')), findsOneWidget);
    });

    testWidgets('Selecting Worker card enables Continue button and advances to Step 2',
        (tester) async {
      await tester.pumpWidget(createRoleTreeTestWidget());
      await tester.pumpAndSettle();

      // Tap Worker card
      await tester.tap(find.byKey(const Key('cardWorker')));
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.byKey(const Key('roleTreeContinueButton')));
      await tester.pumpAndSettle();

      // Should be on Step 2
      expect(find.text('What do you want to do?'), findsOneWidget);
      expect(find.byKey(const Key('cardSeeker')), findsOneWidget);
      expect(find.byKey(const Key('cardProvider')), findsOneWidget);
      expect(find.text('Worker'), findsOneWidget); // Breadcrumb
    });

    testWidgets(
        'Advancing to Step 3 and tapping Back button returns to Step 2 and clears choice',
        (tester) async {
      await tester.pumpWidget(createRoleTreeTestWidget());
      await tester.pumpAndSettle();

      // Step 1: Worker
      await tester.tap(find.byKey(const Key('cardWorker')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('roleTreeContinueButton')));
      await tester.pumpAndSettle();

      // Step 2: Seeker
      await tester.tap(find.byKey(const Key('cardSeeker')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('roleTreeContinueButton')));
      await tester.pumpAndSettle();

      // Step 3 UI
      expect(find.text('Tell us about you'), findsOneWidget);
      expect(find.byKey(const Key('cardSeekerInformal')), findsOneWidget);
      expect(find.byKey(const Key('cardSeekerStudent')), findsOneWidget);
      expect(find.byKey(const Key('cardSeekerPartTime')), findsOneWidget);

      // Tap Back button
      await tester.tap(find.byKey(const Key('roleTreeBackButton')));
      await tester.pumpAndSettle();

      // Should return to Step 2
      expect(find.text('What do you want to do?'), findsOneWidget);

      // Tap Back button again
      await tester.tap(find.byKey(const Key('roleTreeBackButton')));
      await tester.pumpAndSettle();

      // Should return to Step 1
      expect(find.text('Who are you?'), findsOneWidget);
    });
  });
}
