import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:udyogasethu/features/seeker/data/nearby_jobs_repository.dart';
import 'package:udyogasethu/features/seeker/domain/job_pin.dart';
import 'package:udyogasethu/features/seeker/presentation/map/nearby_jobs_map_controller.dart';
import 'package:udyogasethu/features/seeker/presentation/map/nearby_jobs_map_screen.dart';
import 'package:udyogasethu/features/seeker/presentation/map/tile_config.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class FakeNearbyJobsRepository implements NearbyJobsRepository {
  final List<JobPin> _pins;
  final List<CategoryFilterItem> _categories;

  FakeNearbyJobsRepository({
    List<JobPin>? pins,
    List<CategoryFilterItem>? categories,
  })  : _pins = pins ?? _defaultPins(),
        _categories = categories ?? _defaultCategories();

  static List<JobPin> _defaultPins() {
    return const [
      JobPin(
        id: 'job-1',
        providerId: 'prov-1',
        title: 'Commercial Electrician',
        description: 'Commercial wiring work',
        wageType: 'daily',
        wagePaise: 88000,
        addressText: 'Sai Electricals • Koramangala, Bengaluru',
        distanceM: 800,
        lat: 12.9340,
        lng: 77.6180,
        employerName: 'Sai Electricals',
        employerVerified: true,
        employerRating: 4.9,
        categoryName: {'en': 'Electrician', 'kn': 'ವಿದ್ಯುತ್ ತಜ್ಞ'},
        categoryIcon: 'electrical_services',
      ),
      JobPin(
        id: 'job-2',
        providerId: 'prov-2',
        title: 'Construction Helper',
        description: 'Site civil assistant',
        wageType: 'daily',
        wagePaise: 70000,
        addressText: 'Sharma Builders • Koramangala 4th Block, Bengaluru',
        distanceM: 1900,
        lat: 12.9310,
        lng: 77.6250,
        employerName: 'Sharma Builders',
        employerVerified: true,
        employerRating: 4.8,
        categoryName: {'en': 'Construction', 'kn': 'ನಿರ್ಮಾಣ'},
        categoryIcon: 'construction',
      ),
      JobPin(
        id: 'job-3',
        providerId: 'prov-3',
        title: 'Plumber',
        description: 'Pipeline maintenance',
        wageType: 'daily',
        wagePaise: 91000,
        addressText: 'R.K. Plumbing Services • Koramangala, Bengaluru',
        distanceM: 300,
        lat: 12.9360,
        lng: 77.6220,
        employerName: 'R.K. Plumbing Services',
        employerVerified: false,
        employerRating: 4.7,
        categoryName: {'en': 'Plumbing', 'kn': 'ಪ್ಲಂಬಿಂಗ್'},
        categoryIcon: 'plumbing',
      ),
    ];
  }

  static List<CategoryFilterItem> _defaultCategories() {
    return const [
      CategoryFilterItem(
        id: 'cat-const',
        slug: 'construction',
        names: {'en': 'Construction', 'kn': 'ನಿರ್ಮಾಣ'},
        icon: 'construction',
      ),
      CategoryFilterItem(
        id: 'cat-plumb',
        slug: 'plumbing',
        names: {'en': 'Plumbing', 'kn': 'ಪ್ಲಂಬಿಂಗ್'},
        icon: 'plumbing',
      ),
    ];
  }

  @override
  Future<List<JobPin>> getNearbyJobPins({
    required double lat,
    required double lng,
    double radiusM = 25000,
    String? categoryId,
    String? searchQuery,
    int limit = 50,
  }) async {
    if (categoryId != null) {
      return _pins.where((p) => p.categoryId == categoryId).toList();
    }
    return _pins;
  }

  @override
  Future<List<CategoryFilterItem>> getCategories() async {
    return _categories;
  }

  @override
  Stream<void> watchJobsTable() {
    return const Stream.empty();
  }

  @override
  Future<bool> applyToJob(String jobId) async => true;
}

void main() {
  group('Nearby Jobs Map Domain & TileConfig Tests', () {
    test('JobPin parses JSON and computes price pins and distance', () {
      final json = {
        'id': 'job-abc',
        'provider_id': 'prov-xyz',
        'title': 'Commercial Electrician Helper',
        'wage_type': 'daily',
        'wage_paise': 88000,
        'distance_m': 800.0,
        'lat': 12.9340,
        'lng': 77.6180,
        'employer_name': 'Sai Electricals',
        'employer_verified': true,
        'employer_rating': 4.9,
        'address_text': 'Koramangala, Bengaluru',
        'category_name': {'en': 'Electrician', 'kn': 'ವಿದ್ಯುತ್ ತಜ್ಞ'},
        'category_icon': 'electrical_services',
      };

      final pin = JobPin.fromJson(json);

      expect(pin.id, equals('job-abc'));
      expect(pin.pricePinText, equals('₹880'));
      expect(pin.formattedWage, equals('₹880 / day'));
      expect(pin.formattedDistance, equals('800 m away'));
      expect(pin.latLng.latitude, closeTo(12.9340, 0.001));
      expect(pin.latLng.longitude, closeTo(77.6180, 0.001));
      expect(pin.employerVerified, isTrue);
      expect(pin.getLocalizedCategory('en'), equals('Electrician'));
      expect(pin.getLocalizedCategory('kn'), equals('ವಿದ್ಯುತ್ ತಜ್ಞ'));
    });

    test('TileConfig provides OpenStreetMap defaults and allows custom override', () {
      const defaultConfig = TileConfig();
      expect(defaultConfig.urlTemplate, contains('tile.openstreetmap.org'));
      expect(defaultConfig.userAgentPackageName, equals('in.udyogasethu'));
      expect(defaultConfig.attributionText, contains('OpenStreetMap contributors'));

      const customConfig = TileConfig(
        urlTemplate: 'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}',
        userAgentPackageName: 'custom.pkg',
        maxZoom: 22,
      );
      expect(customConfig.urlTemplate, contains('mapbox.com'));
      expect(customConfig.maxZoom, equals(22));
    });
  });

  group('NearbyJobsMapScreen Widget Tests', () {
    Widget buildTestWidget({NearbyJobsMapState? overrideState}) {
      return ProviderScope(
        overrides: [
          nearbyJobsRepositoryProvider.overrideWithValue(FakeNearbyJobsRepository()),
          if (overrideState != null)
            nearbyJobsMapNotifierProvider.overrideWith(
              () => _TestNotifier(overrideState),
            ),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en')],
          home: NearbyJobsMapScreen(),
        ),
      );
    }

    testWidgets('Renders Top Header, Live Pins Badge, Category Chips and Listings Header',
        (tester) async {
      final loadedState = NearbyJobsMapState(
        mapCenter: const LatLng(12.9352, 77.6245),
        jobPins: FakeNearbyJobsRepository._defaultPins(),
        categories: FakeNearbyJobsRepository._defaultCategories(),
        hasLocationPermission: true,
      );

      await tester.pumpWidget(buildTestWidget(overrideState: loadedState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Top Header text matching Screen 7
      expect(find.text('NEARBY DAILY WAGE JOBS & WORK SITES'), findsOneWidget);

      // Live Pins Badge
      expect(find.text('3 Live Pins'), findsOneWidget);

      // Category Chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Construction'), findsOneWidget);
      expect(find.text('Plumbing'), findsOneWidget);

      // Listings Bottom Sheet Header matching Screen 7
      expect(find.text('NEARBY GPS PIN LISTINGS (3)'), findsOneWidget);
      expect(find.text('Tap pin or card to inspect'), findsOneWidget);

      // Job Cards
      expect(find.text('Commercial Electrician'), findsOneWidget);
      expect(find.text('Construction Helper'), findsOneWidget);
      expect(find.text('Sai Electricals'), findsOneWidget);
    });

    testWidgets('Tapping card highlights job and apply updates state to Applied',
        (tester) async {
      final loadedState = NearbyJobsMapState(
        mapCenter: const LatLng(12.9352, 77.6245),
        jobPins: FakeNearbyJobsRepository._defaultPins(),
        categories: FakeNearbyJobsRepository._defaultCategories(),
        hasLocationPermission: true,
      );

      await tester.pumpWidget(buildTestWidget(overrideState: loadedState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Find first Apply button
      final applyButtons = find.widgetWithText(ElevatedButton, 'Apply');
      expect(applyButtons, findsWidgets);

      // Tap Apply on first card
      await tester.tap(applyButtons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Verify that Applied state is shown
      expect(find.text('Applied ✓'), findsOneWidget);
    });

    testWidgets('Shows GPS disabled banner with Settings action when isGpsDisabled is true',
        (tester) async {
      const disabledState = NearbyJobsMapState(
        mapCenter: LatLng(12.9352, 77.6245),
        isGpsDisabled: true,
      );

      await tester.pumpWidget(buildTestWidget(overrideState: disabledState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.textContaining('GPS is turned off'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}

class _TestNotifier extends NearbyJobsMapNotifier {
  final NearbyJobsMapState _customInitialState;
  _TestNotifier(this._customInitialState);

  @override
  NearbyJobsMapState build() => _customInitialState;

  @override
  Future<bool> applyToJob(String jobId) async {
    final updated = Set<String>.from(state.appliedJobIds)..add(jobId);
    state = state.copyWith(appliedJobIds: updated);
    return true;
  }
}
