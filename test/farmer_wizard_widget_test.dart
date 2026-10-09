import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/farmer/domain/farmer_profile_draft.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_home_screen.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_wizard_controller.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_wizard_screen.dart';
import 'package:udyogasethu/features/farmer/data/farmer_home_repository.dart';
import 'package:udyogasethu/features/farmer/domain/weather_advisory_model.dart';
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
          farmerWeatherAdvisoryProvider.overrideWith((ref) => WeatherAdvisory.simulatedRain(locationName: 'Mandya Agri-Cluster')),
          mandiPricesProvider.overrideWith((ref) => []),
          farmerStatsProvider.overrideWith((ref) => const FarmerHomeStats()),
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

    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Farmer Home'), findsOneWidget);
    expect(find.text('FARMER WORKSPACE'), findsOneWidget);
    expect(find.text('Cauvery Organic Farm'), findsOneWidget);
    expect(find.text('Mandya Agri-Cluster'), findsNWidgets(2));
    expect(find.text('WEATHER ADVISORY RADAR'), findsOneWidget);
    expect(find.text('LIVE MANDI PRICES & DEMAND'), findsOneWidget);
    expect(find.text('FARMER ESSENTIAL SUITE'), findsOneWidget);
  });
}
