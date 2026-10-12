import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/farmer/data/farmer_home_repository.dart';
import 'package:udyogasethu/features/farmer/domain/farm_resource_model.dart';
import 'package:udyogasethu/features/farmer/domain/farmer_profile_draft.dart';
import 'package:udyogasethu/features/farmer/domain/mandi_price_model.dart';
import 'package:udyogasethu/features/farmer/domain/weather_advisory_model.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_home_screen.dart';
import 'package:udyogasethu/features/notifications/data/notification_repository.dart';
import 'package:udyogasethu/features/notifications/domain/app_notification.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testWidths = [320.0, 360.0, 393.0, 412.0, 480.0, 600.0];
  const testTextScales = [1.0, 1.3, 1.6, 2.0];
  const testLocales = [
    Locale('en'),
    Locale('kn'),
    Locale('hi'),
    Locale('ta'),
    Locale('te'),
  ];

  final longFarmerProfile = const FarmerProfileDraft(
    userId: 'farmer-long-1',
    fullName: 'Dr. Srikanthan Chandrasekharan Venkataraman',
    farmName: 'Sri Lakshmi Venkateshwara Agro Organic Farm & Cultivation Centre',
    clusterVillage: 'Guddibande Agri-Cluster',
    acres: 12.5,
    farmLatitude: 12.5244,
    farmLongitude: 76.8951,
    primaryCrops: ['Tomato', 'Onion', 'Paddy', 'Sugarcane', 'Banana', 'Cardamom'],
    organicCertStatus: 'verified',
  );

  const longFarmerStats = FarmerHomeStats(
    produceSoldKg: 3450.0,
    directEarningsPaise: 48500000,
    activeLaborBookings: 8,
  );

  final List<MandiPrice> sampleMandiPrices = [
    MandiPrice(
      id: 'mp-1',
      commodity: 'Tomato',
      variety: 'Hybrid F1',
      market: 'Kolar APMC Mandi',
      district: 'Kolar',
      state: 'Karnataka',
      modalPrice: 3200,
      minPrice: 2800,
      maxPrice: 3600,
      pricePerKg: 32.0,
      changePercent: 4.5,
      trendDirection: 'up',
      arrivalDate: DateTime.now(),
      demandTag: 'High Demand',
      updatedAt: DateTime.now(),
    ),
    MandiPrice(
      id: 'mp-2',
      commodity: 'Onion',
      variety: 'Bellary Red',
      market: 'Yeshwanthpur APMC',
      district: 'Bengaluru',
      state: 'Karnataka',
      modalPrice: 2400,
      minPrice: 2100,
      maxPrice: 2650,
      pricePerKg: 24.0,
      changePercent: -2.0,
      trendDirection: 'down',
      arrivalDate: DateTime.now(),
      demandTag: 'Stable',
      updatedAt: DateTime.now(),
    ),
    MandiPrice(
      id: 'mp-3',
      commodity: 'Paddy',
      variety: 'Sona Masoori Grade A',
      market: 'Mandya Central Mandi',
      district: 'Mandya',
      state: 'Karnataka',
      modalPrice: 2650,
      minPrice: 2400,
      maxPrice: 2900,
      pricePerKg: 26.5,
      changePercent: 1.8,
      trendDirection: 'up',
      arrivalDate: DateTime.now(),
      demandTag: 'MSP Protected',
      updatedAt: DateTime.now(),
    ),
    MandiPrice(
      id: 'mp-4',
      commodity: 'Sugarcane',
      variety: 'Co-86032 High Brix',
      market: 'Mandya Sugar Factory Yard',
      district: 'Mandya',
      state: 'Karnataka',
      modalPrice: 350,
      minPrice: 320,
      maxPrice: 380,
      pricePerKg: 3.5,
      changePercent: 0.0,
      trendDirection: 'stable',
      arrivalDate: DateTime.now(),
      demandTag: 'FRP Guaranteed',
      updatedAt: DateTime.now(),
    ),
    MandiPrice(
      id: 'mp-5',
      commodity: 'Banana',
      variety: 'Yelakki Organic Cavendish',
      market: 'Binny Mill Mandi',
      district: 'Bengaluru',
      state: 'Karnataka',
      modalPrice: 4200,
      minPrice: 3800,
      maxPrice: 4600,
      pricePerKg: 42.0,
      changePercent: 5.2,
      trendDirection: 'up',
      arrivalDate: DateTime.now(),
      demandTag: 'High Demand',
      updatedAt: DateTime.now(),
    ),
    MandiPrice(
      id: 'mp-6',
      commodity: 'Cardamom',
      variety: 'Green Alleppey Supreme Export Grade',
      market: 'Sakleshpur Spices Auction',
      district: 'Hassan',
      state: 'Karnataka',
      modalPrice: 145000,
      minPrice: 130000,
      maxPrice: 160000,
      pricePerKg: 1450.0,
      changePercent: 12.0,
      trendDirection: 'up',
      arrivalDate: DateTime.now(),
      demandTag: 'High Demand',
      updatedAt: DateTime.now(),
    ),
  ];

  final sampleWeather = WeatherAdvisory(
    locationName: 'Guddibande Agri-Cluster',
    currentTemp: 28.5,
    maxTemp: 32.0,
    minTemp: 22.0,
    rainProbability: 85,
    precipitationMm: 45.0,
    weatherCode: 65,
    advisoryTitle: 'CRITICAL HARVEST WARNING: Heavy monsoon precipitation within 12 hours',
    advisoryBody: 'Expedite paddy and tomato harvesting immediately before field waterlogging occurs.',
    actionLabel: 'Hire Emergency Labour',
    severity: WeatherAdvisorySeverity.alert,
    date: DateTime.now(),
    isSimulated: false,
  );

  final List<FarmResource> sampleResources = [
    const FarmResource(
      id: 'res-1',
      ownerId: 'farmer-v1',
      name: 'John Deere 5050D 4WD High-Torque Multi-Crop Harvester and Thresher',
      type: FarmResourceType.harvester,
      pricePaise: 180000,
      unit: 'hour',
      addressText: 'Guddibande Agri-Cluster Machinery Yard, Field Sector 4',
      lat: 12.5244,
      lng: 76.8951,
      specs: '50 HP Turbocharged, 4WD, Rotary Thresher with Straw Collector',
    ),
  ];

  testWidgets('FarmerHomeScreen full responsive layout overflow check', (tester) async {
    for (final width in testWidths) {
      for (final textScale in testTextScales) {
        for (final loc in testLocales) {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          String? detectedOverflow;
          final prevOnError = FlutterError.onError;
          FlutterError.onError = (details) {
            final msg = details.exceptionAsString();
            if (msg.contains('overflowed by') || msg.contains('RenderFlex overflowed')) {
              detectedOverflow = details.toString();
            }
          };

          try {
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  farmerHomeProfileProvider.overrideWith((ref) => Future.value(longFarmerProfile)),
                  farmerStatsProvider.overrideWith((ref) => Future.value(longFarmerStats)),
                  mandiPricesProvider.overrideWith((ref) => Future.value(sampleMandiPrices)),
                  farmerWeatherAdvisoryProvider.overrideWith((ref) => Future.value(sampleWeather)),
                  nearbyEquipmentProvider.overrideWith((ref) => Future.value(sampleResources)),
                  notificationsStreamProvider.overrideWith((ref) => Stream.value(<AppNotification>[])),
                ],
                child: MaterialApp(
                  locale: loc,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: MediaQuery(
                    data: MediaQueryData(
                      size: Size(width, 1000),
                      textScaler: TextScaler.linear(textScale),
                    ),
                    child: const FarmerHomeScreen(),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
          } finally {
            FlutterError.onError = prevOnError;
          }

          final exc = tester.takeException();
          if (exc != null && detectedOverflow == null) {
            if (exc.toString().contains('overflowed')) {
              detectedOverflow = exc.toString();
            }
          }

          expect(
            detectedOverflow,
            isNull,
            reason: 'FarmerHomeScreen OVERFLOWED at width ${width.toInt()}dp, scale $textScale, locale ${loc.languageCode}:\n$detectedOverflow',
          );
        }
      }
    }
  });
}
