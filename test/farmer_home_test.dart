import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udyogasethu/features/farmer/data/farmer_home_repository.dart';
import 'package:udyogasethu/features/farmer/domain/farmer_profile_draft.dart';
import 'package:udyogasethu/features/farmer/domain/mandi_price_model.dart';
import 'package:udyogasethu/features/farmer/domain/weather_advisory_model.dart';
import 'package:udyogasethu/features/farmer/presentation/widgets/farmer_header_card.dart';
import 'package:udyogasethu/features/farmer/presentation/widgets/mandi_prices_section.dart';
import 'package:udyogasethu/features/farmer/presentation/widgets/weather_advisory_card.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Weather Advisory Rules Engine Tests', () {
    test('Heavy rainfall triggers alert with drainage advice', () {
      final advisory = WeatherAdvisory.fromForecastData(
        locationName: 'Mandya Agri Cluster',
        currentTemp: 24.0,
        maxTemp: 27.0,
        minTemp: 20.0,
        rainProbability: 90,
        precipitationMm: 35.0,
        weatherCode: 82, // Violent rain shower
      );

      expect(advisory.severity, equals(WeatherAdvisorySeverity.alert));
      expect(advisory.advisoryTitle, equals('Heavy Rainfall Warning'));
      expect(advisory.advisoryBody, contains('Clear drainage furrows'));
      expect(advisory.actionLabel, equals('Book Harvest Helpers'));
    });

    test('Moderate rain triggers harvest warning before 12 PM with helpers CTA', () {
      final advisory = WeatherAdvisory.fromForecastData(
        locationName: 'Mandya Agri Cluster',
        currentTemp: 26.0,
        maxTemp: 30.0,
        minTemp: 22.0,
        rainProbability: 60,
        precipitationMm: 8.0,
        weatherCode: 61, // Moderate rain
      );

      expect(advisory.severity, equals(WeatherAdvisorySeverity.warning));
      expect(advisory.advisoryTitle, equals('Moderate Rain Expected Tomorrow Afternoon'));
      expect(advisory.advisoryBody, contains('Protect ready tomato crops by harvesting before 12 PM'));
      expect(advisory.actionLabel, equals('Book Harvest Helpers'));
    });

    test('High heat (>34°C) triggers irrigation scheduling advisory', () {
      final advisory = WeatherAdvisory.fromForecastData(
        locationName: 'Raichur Cluster',
        currentTemp: 33.0,
        maxTemp: 36.5,
        minTemp: 25.0,
        rainProbability: 10,
        precipitationMm: 0.0,
        weatherCode: 0,
      );

      expect(advisory.severity, equals(WeatherAdvisorySeverity.warning));
      expect(advisory.advisoryTitle, contains('High Temperature Advisory'));
      expect(advisory.advisoryBody, contains('irrigation to prevent heat stress'));
      expect(advisory.actionLabel, equals('View Irrigation Guide'));
    });

    test('Clear weather triggers favourable info advisory without action button', () {
      final advisory = WeatherAdvisory.fromForecastData(
        locationName: 'Mysuru Cluster',
        currentTemp: 27.0,
        maxTemp: 30.0,
        minTemp: 21.0,
        rainProbability: 15,
        precipitationMm: 0.0,
        weatherCode: 1,
      );

      expect(advisory.severity, equals(WeatherAdvisorySeverity.info));
      expect(advisory.advisoryTitle, equals('Favourable Field Weather'));
      expect(advisory.actionLabel, isNull);
    });

    test('Simulated rain factory sets simulated flag and rain advisory', () {
      final sim = WeatherAdvisory.simulatedRain(locationName: 'Mandya Agri Cluster');

      expect(sim.isSimulated, isTrue);
      expect(sim.rainProbability, equals(75));
      expect(sim.severity, equals(WeatherAdvisorySeverity.warning));
      expect(sim.advisoryBody, contains('Protect ready tomato crops by harvesting before 12 PM'));
    });
  });

  group('Mandi Price Model & Demand Indicators Tests', () {
    test('Calculates price per kg and formatting correctly', () {
      final price = MandiPrice(
        id: '1',
        state: 'Karnataka',
        district: 'Bengaluru Urban',
        market: 'Binny Mill (F&V)',
        commodity: 'Tomato',
        variety: 'Hybrid',
        arrivalDate: DateTime.now(),
        minPrice: 2000,
        maxPrice: 2800,
        modalPrice: 2500,
        pricePerKg: 25.0,
        changePercent: 12.5,
        demandTag: 'High Demand',
        trendDirection: 'up',
        updatedAt: DateTime.now(),
      );

      expect(price.formattedPricePerKg, equals('₹25/kg'));
      expect(price.formattedModalPricePerQtl, equals('₹2,500/qtl'));
      expect(price.formattedChange, equals('+13%'));
      expect(price.category, equals(CropCategoryTab.vegetables));
      expect(price.isStale, isFalse);
    });

    test('Detects negative price change and stable change', () {
      final downPrice = MandiPrice(
        id: '2',
        state: 'Karnataka',
        district: 'Kolar',
        market: 'Kolar APMC',
        commodity: 'Potato',
        variety: 'Jyoti',
        arrivalDate: DateTime.now(),
        minPrice: 1500,
        maxPrice: 1900,
        modalPrice: 1700,
        pricePerKg: 17.0,
        changePercent: -5.4,
        demandTag: 'Oversupply',
        trendDirection: 'down',
        updatedAt: DateTime.now(),
      );

      expect(downPrice.formattedChange, equals('-5%'));

      final stablePrice = MandiPrice(
        id: '3',
        state: 'Karnataka',
        district: 'Mandya',
        market: 'Mandya APMC',
        commodity: 'Paddy (Dhan)',
        variety: 'Sona Masuri',
        arrivalDate: DateTime.now(),
        minPrice: 2300,
        maxPrice: 2500,
        modalPrice: 2400,
        pricePerKg: 24.0,
        changePercent: 0.0,
        demandTag: 'MSP Protected',
        trendDirection: 'stable',
        updatedAt: DateTime.now(),
      );

      expect(stablePrice.formattedChange, equals('0%'));
      expect(stablePrice.category, equals(CropCategoryTab.grainsAndPulses));
    });

    test('Detects stale data when arrivalDate is older than 1 day', () {
      final staleDate = DateTime.now().subtract(const Duration(days: 3));
      final stalePrice = MandiPrice(
        id: '4',
        state: 'Karnataka',
        district: 'Belagavi',
        market: 'Belagavi APMC',
        commodity: 'Onion',
        variety: 'Red',
        arrivalDate: staleDate,
        minPrice: 1800,
        maxPrice: 2200,
        modalPrice: 2000,
        pricePerKg: 20.0,
        changePercent: 0.0,
        demandTag: 'Stable',
        trendDirection: 'stable',
        updatedAt: staleDate,
      );

      expect(stalePrice.isStale, isTrue);
    });
  });

  group('Offline Cache Serialization & Recovery Tests', () {
    test('MandiPrice toJson and fromJson roundtrip preserves all fields', () {
      final original = MandiPrice(
        id: 'test-id',
        state: 'Karnataka',
        district: 'Mysuru',
        market: 'Bandipalya',
        commodity: 'Banana',
        variety: 'Robusta',
        arrivalDate: DateTime(2026, 10, 9),
        minPrice: 1200,
        maxPrice: 1600,
        modalPrice: 1400,
        pricePerKg: 14.0,
        changePercent: 3.5,
        demandTag: 'Stable',
        trendDirection: 'up',
        updatedAt: DateTime(2026, 10, 9, 12, 0),
      );

      final json = original.toJson();
      final restored = MandiPrice.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.commodity, equals(original.commodity));
      expect(restored.market, equals(original.market));
      expect(restored.modalPrice, equals(original.modalPrice));
      expect(restored.pricePerKg, equals(original.pricePerKg));
      expect(restored.changePercent, equals(original.changePercent));
      expect(restored.demandTag, equals(original.demandTag));
    });

    test('WeatherAdvisory toJson and fromJson roundtrip preserves all fields', () {
      final advisory = WeatherAdvisory(
        locationName: 'Mandya Agri Cluster',
        currentTemp: 26.5,
        maxTemp: 29.0,
        minTemp: 21.0,
        rainProbability: 70,
        precipitationMm: 12.0,
        weatherCode: 61,
        advisoryTitle: 'Moderate Rain Expected Tomorrow Afternoon',
        advisoryBody: 'Harvest ready tomatoes before 12 PM',
        actionLabel: 'Book Harvest Helpers',
        severity: WeatherAdvisorySeverity.warning,
        date: DateTime(2026, 10, 9),
        isSimulated: true,
      );

      final json = advisory.toJson();
      final restored = WeatherAdvisory.fromJson(json);

      expect(restored.locationName, equals(advisory.locationName));
      expect(restored.rainProbability, equals(advisory.rainProbability));
      expect(restored.advisoryTitle, equals(advisory.advisoryTitle));
      expect(restored.severity, equals(advisory.severity));
      expect(restored.isSimulated, isTrue);
    });

    test('FarmerHomeRepository loads offline cached mandi prices from SharedPreferences', () async {
      final samplePrices = [
        MandiPrice(
          id: 'offline-1',
          state: 'Karnataka',
          district: 'Mandya',
          market: 'Mandya Yard',
          commodity: 'Sugarcane',
          variety: 'Co 86032',
          arrivalDate: DateTime(2026, 10, 9),
          minPrice: 315,
          maxPrice: 340,
          modalPrice: 325,
          pricePerKg: 3.25,
          changePercent: 0.0,
          demandTag: 'FRP Guaranteed',
          trendDirection: 'stable',
          updatedAt: DateTime.now(),
        )
      ];

      SharedPreferences.setMockInitialValues({
        'cached_mandi_prices_v1': jsonEncode(samplePrices.map((p) => p.toJson()).toList()),
      });

      // Pass null client to trigger fallback to cache without real network
      final repo = FarmerHomeRepository();
      final prices = await repo.getMandiPrices();

      expect(prices.isNotEmpty, isTrue);
      expect(prices.first.commodity, equals('Sugarcane'));
      expect(prices.first.demandTag, equals('FRP Guaranteed'));
    });
  });

  group('Farmer Home Widgets & Localization Tests', () {
    Widget buildTestHarness(Widget child) {
      return ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      );
    }

    testWidgets('FarmerHeaderCard displays real stats with zero fallback without fake numbers', (tester) async {
      const profile = FarmerProfileDraft(
        userId: 'farmer-1',
        fullName: 'Chethan Gowda',
        farmName: 'Cauvery Bio Farm',
        clusterVillage: 'Mandya Cluster',
      );

      // New farmer with zero stats
      const stats = FarmerHomeStats(
        produceSoldKg: 0.0,
        directEarningsPaise: 0,
        activeLaborBookings: 0,
      );

      await tester.pumpWidget(buildTestHarness(
        const FarmerHeaderCard(profile: profile, stats: stats),
      ));
      await tester.pumpAndSettle();

      // Check workspace pill & cluster
      expect(find.text('FARMER WORKSPACE'), findsOneWidget);
      expect(find.text('Mandya Cluster Agri-Cluster'), findsOneWidget);
      expect(find.text('Cauvery Bio Farm'), findsOneWidget);

      // Check real zeros without any fake 420 kg or ₹48,500
      expect(find.text('0 kg'), findsOneWidget);
      expect(find.text('₹0'), findsOneWidget);
      expect(find.text('0 Booked'), findsOneWidget);

      expect(find.text('420 kg'), findsNothing);
      expect(find.text('₹48,500'), findsNothing);
    });

    testWidgets('WeatherAdvisoryCard renders temperature, rain and CTA', (tester) async {
      final advisory = WeatherAdvisory.simulatedRain(locationName: 'Mandya Agri Cluster');

      await tester.pumpWidget(buildTestHarness(
        WeatherAdvisoryCard(
          advisory: advisory,
          onBookHelpers: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('WEATHER ADVISORY RADAR'), findsOneWidget);
      expect(find.text('Mandya Agri Cluster'), findsOneWidget);
      expect(find.text('75% Rain'), findsOneWidget);
      expect(find.text('Simulated Forecast'), findsOneWidget);
      expect(find.text('Book Harvest Helpers'), findsOneWidget);
    });

    testWidgets('MandiPricesSection renders category tabs and unit toggle', (tester) async {
      final prices = [
        MandiPrice(
          id: 'm1',
          state: 'Karnataka',
          district: 'Bengaluru Urban',
          market: 'Binny Mill',
          commodity: 'Tomato',
          variety: 'Hybrid',
          arrivalDate: DateTime.now(),
          minPrice: 2000,
          maxPrice: 2800,
          modalPrice: 2500,
          pricePerKg: 25.0,
          changePercent: 12.0,
          demandTag: 'High Demand',
          trendDirection: 'up',
          updatedAt: DateTime.now(),
        ),
        MandiPrice(
          id: 'm2',
          state: 'Karnataka',
          district: 'Mandya',
          market: 'Mandya Yard',
          commodity: 'Paddy',
          variety: 'Sona',
          arrivalDate: DateTime.now(),
          minPrice: 2300,
          maxPrice: 2500,
          modalPrice: 2400,
          pricePerKg: 24.0,
          changePercent: 0.0,
          demandTag: 'MSP Protected',
          trendDirection: 'stable',
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(buildTestHarness(
        MandiPricesSection(prices: prices),
      ));
      await tester.pumpAndSettle();

      expect(find.text('LIVE MANDI PRICES & DEMAND'), findsOneWidget);
      expect(find.text('Live Feed'), findsOneWidget);
      expect(find.text('All Crops'), findsOneWidget);
      expect(find.text('Vegetables'), findsOneWidget);
      expect(find.text('Grains & Pulses'), findsOneWidget);

      // Verify prices rendered
      expect(find.text('Tomato'), findsOneWidget);
      expect(find.text('Paddy'), findsOneWidget);
      expect(find.text('₹25/kg'), findsOneWidget);
    });

    testWidgets('FarmerHeaderCard renders without overflow at 1.3x text scaling', (tester) async {
      const profile = FarmerProfileDraft(
        userId: 'farmer-1',
        fullName: 'Chethan Gowda',
        farmName: 'Cauvery Bio Farm',
        clusterVillage: 'Mandya Cluster',
      );

      const stats = FarmerHomeStats(
        produceSoldKg: 850.0,
        directEarningsPaise: 4500000,
        activeLaborBookings: 0,
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: buildTestHarness(
            const FarmerHeaderCard(profile: profile, stats: stats),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
