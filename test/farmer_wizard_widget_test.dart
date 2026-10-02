import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/farmer/domain/farmer_profile_draft.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_home_screen.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_wizard_controller.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_wizard_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

import 'farmer_wizard_test.dart';

void main() {
  testWidgets('FarmerWizardScreen renders Step 1 Basics properly', (WidgetTester tester) async {
    final repo = FakeFarmerProfileRepository();
    repo.draft = const FarmerProfileDraft(
      userId: 'f-123',
      fullName: 'Basavaraj',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          farmerProfileRepositoryProvider.overrideWithValue(repo),
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
          home: FarmerWizardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Farmer Profile Setup'), findsOneWidget);
    expect(find.text('Basics'), findsOneWidget);
    expect(find.text('Basavaraj'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsWidgets);
  });

  testWidgets('FarmerHomeScreen renders farm card data and badges', (WidgetTester tester) async {
    final repo = FakeFarmerProfileRepository();
    repo.draft = const FarmerProfileDraft(
      userId: 'f-123',
      fullName: 'Basavaraj Gowda',
      farmName: 'Cauvery Organic Farm',
      clusterVillage: 'Mandya',
      acres: 8.0,
      soilType: 'Red Soil',
      primaryCrops: ['Sugarcane', 'Paddy / Rice'],
      farmingMethod: 'organic',
      apmcRegistration: 'APMC-MANDYA-88',
      kccStatus: 'approved',
      organicCertStatus: 'pending',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          farmerProfileRepositoryProvider.overrideWithValue(repo),
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
          home: FarmerHomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Farmer Home'), findsOneWidget);
    expect(find.text('Cauvery Organic Farm'), findsOneWidget);
    expect(find.text('Mandya • 8.0 Acres'), findsOneWidget);
    expect(find.text('ORGANIC'), findsOneWidget);
    expect(find.text('APMC REGISTERED'), findsOneWidget);
    expect(find.text('KCC APPROVED'), findsOneWidget);
    expect(find.text('ORGANIC CERT (PENDING)'), findsOneWidget);
    expect(find.text('Sugarcane'), findsOneWidget);
    expect(find.text('Paddy / Rice'), findsOneWidget);
  });
}
