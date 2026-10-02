import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/provider/domain/provider_profile_draft.dart';
import 'package:udyogasethu/features/provider/presentation/provider_home_screen.dart';
import 'package:udyogasethu/features/provider/presentation/provider_wizard_controller.dart';
import 'package:udyogasethu/features/provider/presentation/provider_wizard_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

import 'provider_wizard_test.dart';

void main() {
  testWidgets('ProviderWizardScreen renders step 1 basics correctly', (tester) async {
    final fakeRepo = FakeProviderProfileRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          providerProfileRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProviderWizardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Job Provider Setup'), findsOneWidget);
    expect(find.text('Basics'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Languages Spoken'), findsOneWidget);
  });

  testWidgets('ProviderWizardScreen navigates through steps for Household type', (tester) async {
    final fakeRepo = FakeProviderProfileRepository();
    fakeRepo.draft = const ProviderProfileDraft(
      userId: 'test-p-1',
      fullName: 'Sunita Sharma',
      providerType: 'household',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          providerProfileRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProviderWizardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Step 1 -> Step 2
    final continueBtn = find.text('Continue ->');
    expect(continueBtn, findsOneWidget);
    await tester.tap(continueBtn);
    await tester.pumpAndSettle();

    expect(find.text('Provider Category'), findsOneWidget);
    expect(find.text('Household'), findsOneWidget);
    expect(find.text('Business / Employer'), findsOneWidget);

    // Step 2 -> Step 3 (Household)
    await tester.tap(continueBtn);
    await tester.pumpAndSettle();

    expect(find.text('Doorstep Address & Delivery'), findsOneWidget);
    expect(find.text('Default Doorstep Delivery Address Card'), findsOneWidget);
  });

  testWidgets('ProviderHomeScreen renders Household and Employer provider cards', (tester) async {
    final fakeRepo = FakeProviderProfileRepository();
    fakeRepo.draft = const ProviderProfileDraft(
      userId: 'test-p-3',
      fullName: 'Anand Kumar',
      providerType: 'employer',
      orgName: 'Sethu Infra Construction',
      siteAddressLine1: 'Plot 45, Phase 2, Electronics City',
      siteLandmark: 'Near Flyover',
      siteCity: 'Bengaluru',
      sitePincode: '560100',
      categoriesHiring: ['Construction & Labour', 'Maintenance & Electrician'],
      typicalCrewSize: 20,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          providerProfileRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProviderHomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Provider Home'), findsOneWidget);
    expect(find.text('Sethu Infra Construction'), findsOneWidget);
    expect(find.text('Employer / Contractor'), findsOneWidget);
    expect(find.text('Plot 45, Phase 2, Electronics City, Near Flyover'), findsOneWidget);
    expect(find.text('Construction & Labour'), findsOneWidget);
    expect(find.text('Typical Crew Size Needed: 20 workers'), findsOneWidget);
  });
}
