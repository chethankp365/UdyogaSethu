import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/core/widgets/user_avatar.dart';
import 'package:udyogasethu/features/farmer/data/farmer_profile_page_repository.dart';
import 'package:udyogasethu/features/farmer/domain/farmer_profile_model.dart';
import 'package:udyogasethu/features/farmer/domain/mandi_price_model.dart';
import 'package:udyogasethu/features/farmer/domain/weather_advisory_model.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_profile_screen.dart';
import 'package:udyogasethu/features/farmer/presentation/widgets/edit_farm_details_dialog.dart';
import 'package:udyogasethu/features/farmer/presentation/widgets/mandi_prices_section.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

Widget _buildTestApp(Widget child, [List<dynamic> overrides = const []]) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: child,
    ),
  );
}

class _FakeFarmerProfilePageRepository extends FarmerProfilePageRepository {
  Map<String, dynamic>? lastUpdatedPayload;

  @override
  Future<Map<String, dynamic>> updateFarmDetails({
    required String farmName,
    required String clusterVillage,
    required double acres,
    required String soilType,
    required String farmingMethod,
    required String primaryCrops,
    required double deliveryRadiusKm,
    required bool pickupAvailable,
    required int leadTimeHours,
    String? farmPhotoUrl,
    String? apmcRegistration,
    String? kccStatus,
    String? organicCertNumber,
    String? organicCertPath,
  }) async {
    lastUpdatedPayload = {
      'farm_name': farmName,
      'cluster_village': clusterVillage,
      'acres': acres,
      'soil_type': soilType,
      'farming_method': farmingMethod,
      'primary_crops': primaryCrops,
      'delivery_radius_km': deliveryRadiusKm,
      'pickup_available': pickupAvailable,
      'lead_time_hours': leadTimeHours,
      'farm_photo_url': farmPhotoUrl,
      'apmc_registration': apmcRegistration,
      'kcc_status': kccStatus,
      'organic_cert_number': organicCertNumber,
      'organic_cert_path': organicCertPath,
    };
    return lastUpdatedPayload!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Part F: Farmer Advisory and Accuracy Tests', () {
    test('WeatherAdvisory algorithm does not contain hardcoded fake helper counts', () {
      final advisory = WeatherAdvisory.fromForecastData(
        locationName: 'Mandya',
        currentTemp: 27.0,
        maxTemp: 31.0,
        minTemp: 22.0,
        rainProbability: 60,
        precipitationMm: 12.0,
        weatherCode: 61,
      );

      expect(advisory.severity, equals(WeatherAdvisorySeverity.warning));
      expect(advisory.advisoryBody.contains('5 Local harvest helpers'), isFalse);
      expect(advisory.advisoryBody.contains('5 local'), isFalse);
      expect(advisory.actionLabel, equals('Book Harvest Helpers'));
    });

    test('FarmerProfileData honors real verified status and self-declared fields', () {
      const verifiedProfile = FarmerProfileData(
        id: 'farmer-1',
        fullName: 'Chethan Gowda',
        isVerified: true,
        landAcres: 5.0,
      );
      expect(verifiedProfile.isVerified, isTrue);

      const unverifiedProfile = FarmerProfileData(
        id: 'farmer-2',
        fullName: 'Ramesh Patel',
        isVerified: false,
        landAcres: 2.5,
      );
      expect(unverifiedProfile.isVerified, isFalse);
    });
  });

  group('Part F: Farmer Profile UI and Editor Tests', () {
    testWidgets('FarmerProfileScreen renders UserAvatar, verified status, and edit button',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      const testProfile = FarmerProfileData(
        id: 'test-farmer-id',
        fullName: 'Chethan Gowda',
        farmName: 'Cauvery Bio Farm',
        clusterVillage: 'Mandya Rural',
        phone: '+91 98765 43210',
        avatarUrl: null,
        isVerified: true,
        landAcres: 3.5,
      );

      await tester.pumpWidget(
        _buildTestApp(
          const FarmerProfileScreen(),
          [
            farmerProfileDataProvider.overrideWith((ref) => Future.value(testProfile)),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Check UserAvatar widget is rendered
      expect(find.byType(UserAvatar), findsOneWidget);

      // Check verified badge
      expect(find.text('VERIFIED FARMER ✓'), findsOneWidget);

      // Check Edit Farm Details button exists
      expect(find.byKey(const Key('hero_edit_farm_button')), findsOneWidget);
      expect(find.byKey(const Key('edit_farm_details_button')), findsOneWidget);
    });

    testWidgets('FarmerProfileScreen shows SELF-DECLARED PROFILE when isVerified is false',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      const unverifiedProfile = FarmerProfileData(
        id: 'test-farmer-2',
        fullName: 'Basavaraj Patil',
        farmName: 'Patil Farms',
        clusterVillage: 'Haveri',
        phone: '+91 91234 56789',
        isVerified: false,
        landAcres: 6.0,
      );

      await tester.pumpWidget(
        _buildTestApp(
          const FarmerProfileScreen(),
          [
            farmerProfileDataProvider.overrideWith((ref) => Future.value(unverifiedProfile)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SELF-DECLARED PROFILE'), findsOneWidget);
      expect(find.text('VERIFIED FARMER ✓'), findsNothing);
    });

    testWidgets('EditFarmDetailsDialog renders all form fields and validates',
        (tester) async {
      const testProfile = FarmerProfileData(
        id: 'test-farmer-id',
        fullName: 'Chethan Gowda',
        farmName: 'Cauvery Bio Farm',
        clusterVillage: 'Mandya Rural',
        landAcres: 3.5,
        badges: FarmInfrastructureBadges(
          soilClassification: 'Red Soil',
          primaryCrops: 'Tomatoes, Sugarcane',
          apmcRegistration: 'Mandya APMC',
        ),
      );

      await tester.pumpWidget(
        _buildTestApp(
          const Scaffold(
            body: EditFarmDetailsDialog(profile: testProfile),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('farm_name_input')), findsOneWidget);
      expect(find.byKey(const Key('farm_cluster_input')), findsOneWidget);
      expect(find.byKey(const Key('farm_acres_input')), findsOneWidget);
      expect(find.byKey(const Key('farm_soil_input')), findsOneWidget);
      expect(find.byKey(const Key('farm_crops_input')), findsOneWidget);
      expect(find.byKey(const Key('farm_apmc_input')), findsOneWidget);
      expect(find.byKey(const Key('save_farm_details_button')), findsOneWidget);

      // Verify initial field values
      expect(find.text('Cauvery Bio Farm'), findsOneWidget);
      expect(find.text('Mandya Rural'), findsOneWidget);
      expect(find.text('3.5'), findsOneWidget);
    });

    testWidgets(
        'EditFarmDetailsDialog saves all fields with decimal acres, crops, radius and shows success snackbar',
        (tester) async {
      final fakeRepo = _FakeFarmerProfilePageRepository();
      const testProfile = FarmerProfileData(
        id: 'test-farmer-id',
        fullName: 'Chethan Gowda',
        farmName: 'Cauvery Bio Farm',
        clusterVillage: 'Mandya Rural',
        landAcres: 3.5,
        badges: FarmInfrastructureBadges(
          soilClassification: 'Red Soil',
          primaryCrops: 'Tomatoes, Sugarcane',
          deliveryRadiusKm: 25.0,
          pickupAvailable: true,
          leadTimeHours: 24,
        ),
      );

      await tester.pumpWidget(
        _buildTestApp(
          const Scaffold(
            body: EditFarmDetailsDialog(profile: testProfile),
          ),
          [
            farmerProfilePageRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Enter decimal acres
      final acresFinder = find.byKey(const Key('farm_acres_input'));
      await tester.enterText(acresFinder, '12.75');

      // Enter soil
      final soilFinder = find.byKey(const Key('farm_soil_input'));
      await tester.enterText(soilFinder, 'Alluvial Black Soil');

      // Enter crops
      final cropsFinder = find.byKey(const Key('farm_crops_input'));
      await tester.enterText(cropsFinder, 'Organic Rice, Millets, Sugarcane');

      // Enter delivery radius
      final radiusFinder = find.byKey(const Key('delivery_radius_input'));
      await tester.enterText(radiusFinder, '45.5');

      // Enter lead time
      final leadTimeFinder = find.byKey(const Key('lead_time_input'));
      await tester.enterText(leadTimeFinder, '36');

      // Tap save
      final saveBtn = find.byKey(const Key('save_farm_details_button'));
      await tester.tap(saveBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify repo received all fields
      expect(fakeRepo.lastUpdatedPayload, isNotNull);
      expect(fakeRepo.lastUpdatedPayload!['acres'], equals(12.75));
      expect(fakeRepo.lastUpdatedPayload!['soil_type'], equals('Alluvial Black Soil'));
      expect(fakeRepo.lastUpdatedPayload!['primary_crops'], equals('Organic Rice, Millets, Sugarcane'));
      expect(fakeRepo.lastUpdatedPayload!['delivery_radius_km'], equals(45.5));
      expect(fakeRepo.lastUpdatedPayload!['lead_time_hours'], equals(36));
      expect(fakeRepo.lastUpdatedPayload!['pickup_available'], isTrue);

      // Verify success snackbar appears
      expect(find.textContaining('saved successfully'), findsOneWidget);
    });
  });

  group('Part F: Mandi Prices Section Tests', () {
    testWidgets('MandiPricesSection displays Swiggy-style cards and category chips',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testPrices = [
        MandiPrice(
          id: 'price-1',
          state: 'Karnataka',
          district: 'Kolar',
          market: 'Kolar APMC',
          commodity: 'Tomato',
          variety: 'Hybrid Red',
          arrivalDate: DateTime.now(),
          minPrice: 28.0,
          maxPrice: 38.0,
          modalPrice: 3400.0,
          pricePerKg: 34.0,
          changePercent: 6.0,
          demandTag: 'High Demand',
          trendDirection: 'up',
          updatedAt: DateTime.now(),
        ),
        MandiPrice(
          id: 'price-2',
          state: 'Karnataka',
          district: 'Mandya',
          market: 'Mandya APMC',
          commodity: 'Paddy',
          variety: 'Sona Masuri',
          arrivalDate: DateTime.now(),
          minPrice: 2200.0,
          maxPrice: 2800.0,
          modalPrice: 2600.0,
          pricePerKg: 26.0,
          changePercent: -2.0,
          demandTag: 'Stable',
          trendDirection: 'down',
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          Scaffold(
            body: SingleChildScrollView(
              child: MandiPricesSection(prices: testPrices),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check category chips and emoji avatars
      expect(find.text('All Crops'), findsOneWidget);
      expect(find.text('Vegetables'), findsOneWidget);
      expect(find.text('Grains & Pulses'), findsOneWidget);
      expect(find.text('🧺'), findsOneWidget);
      expect(find.text('🥦'), findsOneWidget);

      // Check commodities rendered
      expect(find.text('Tomato'), findsOneWidget);
      expect(find.text('Paddy'), findsOneWidget);
      expect(find.text('+6%'), findsOneWidget);
      expect(find.text('-2%'), findsOneWidget);
    });
  });
}
