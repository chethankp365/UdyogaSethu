import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:udyogasethu/features/seeker/presentation/seeker_wizard_controller.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_wizard_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

import 'seeker_wizard_test.dart';

void main() {
  testWidgets('SeekerWizardScreen renders step 1 and navigates correctly', (WidgetTester tester) async {
    final fakeRepo = FakeSeekerProfileRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seekerProfileRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: SeekerWizardScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    // Check title and step progress
    expect(find.text('Step 1 of 7'), findsOneWidget);
    expect(find.text('Basics'), findsOneWidget);

    // Enter Full Name
    final nameField = find.byType(TextFormField).first;
    await tester.enterText(nameField, 'Test Worker Name');
    await tester.pump(const Duration(milliseconds: 100));

    // Tap Continue -> Step 2
    final continueBtn = find.text('Continue ->');
    expect(continueBtn, findsOneWidget);
    await tester.tap(continueBtn);
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Step 2 rendered
    expect(find.text('Step 2 of 7'), findsOneWidget);
    expect(find.text('Skills & Interests'), findsOneWidget);

    // Verify repository saved step 2
    expect(fakeRepo.draft.currentStep, equals(2));
    expect(fakeRepo.draft.fullName, equals('Test Worker Name'));
  });

  testWidgets('SeekerWizardScreen resumes on step 3 if saved', (WidgetTester tester) async {
    final fakeRepo = FakeSeekerProfileRepository();
    fakeRepo.draft = fakeRepo.draft.copyWith(currentStep: 3, fullName: 'Resumed Worker');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seekerProfileRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: SeekerWizardScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    // Check it resumed on Step 3
    expect(find.text('Step 3 of 7'), findsOneWidget);
    expect(find.text('Experience & Rate'), findsOneWidget);
  });

  testWidgets('SeekerWizardScreen Step 2 allows category/skill selection and custom skill entry', (WidgetTester tester) async {
    final fakeRepo = FakeSeekerProfileRepository();
    fakeRepo.draft = fakeRepo.draft.copyWith(currentStep: 2, fullName: 'Skill Tester');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seekerProfileRepositoryProvider.overrideWithValue(fakeRepo),
          categoriesProvider.overrideWith((ref) async => fakeRepo.fetchCategories()),
          skillsProvider.overrideWith((ref) async => fakeRepo.fetchSkills()),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: SeekerWizardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Step 2 rendered
    expect(find.text('Step 2 of 7'), findsOneWidget);
    expect(find.text('Skills & Interests'), findsOneWidget);

    // Verify categories from repo are shown
    expect(find.text('Construction'), findsOneWidget);

    // Tap Construction category chip to reveal skills
    await tester.tap(find.text('Construction'));
    await tester.pumpAndSettle();

    expect(find.text('Plumbing'), findsOneWidget);
    expect(find.text('Masonry'), findsOneWidget);

    // Tap Masonry skill chip
    await tester.tap(find.text('Masonry'));
    await tester.pump(const Duration(milliseconds: 100));

    // Enter custom skill
    final customSkillField = find.byType(TextField).first;
    expect(customSkillField, findsOneWidget);
    await tester.enterText(customSkillField, 'Custom Welding');
    final addSkillBtn = find.text('Add Skill');
    await tester.ensureVisible(addSkillBtn);
    await tester.tap(addSkillBtn);
    await tester.pump(const Duration(milliseconds: 100));

    // Verify custom skill chip appears
    expect(find.text('Custom Welding'), findsOneWidget);

    // Tap Continue -> Step 3
    final continueBtn = find.text('Continue ->');
    await tester.ensureVisible(continueBtn);
    await tester.tap(continueBtn);
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Step 3 reached and skills saved in repository
    expect(fakeRepo.draft.currentStep, equals(3));
    expect(fakeRepo.draft.selectedSkillIds, contains('skill-1'));
    expect(fakeRepo.draft.selectedSkillIds, contains('Custom Welding'));
  });
}
