import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/farmer/data/farm_resources_repository.dart';
import 'package:udyogasethu/features/farmer/domain/farm_resource_model.dart';
import 'package:udyogasethu/features/farmer/domain/resource_booking_model.dart';
import 'package:udyogasethu/features/farmer/presentation/farm_resources_map_screen.dart';
import 'package:udyogasethu/features/farmer/presentation/widgets/book_resource_modal.dart';
import 'package:udyogasethu/features/farmer/presentation/widgets/equipment_rental_section.dart';
import 'package:udyogasethu/features/provider/domain/job_post_draft.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('P6.3 Farm Resources & Equipment Booking Invariants', () {
    late FarmResourcesRepository repo;

    setUp(() {
      repo = SupabaseFarmResourcesRepository(null);
    });

    test('Loads 7 realistic Karnataka agricultural resources with GPS coordinates and specs', () async {
      final resources = await repo.getNearbyResources();
      expect(resources.length, greaterThanOrEqualTo(7));

      final tractor = resources.firstWhere((r) => r.type == FarmResourceType.tractor);
      expect(tractor.name, contains('Mahindra 575'));
      expect(tractor.pricePaise, 85000); // ₹850/hr
      expect(tractor.unit, 'hr');
      expect(tractor.lat, isNotNull);
      expect(tractor.lng, isNotNull);
      expect(tractor.specs, contains('50 HP'));

      final drone = resources.firstWhere((r) => r.type == FarmResourceType.drone);
      expect(drone.name, contains('Drone Spraying'));
      expect(drone.pricePaise, 45000); // ₹450/acre
      expect(drone.unit, 'acre');

      final harvester = resources.firstWhere((r) => r.type == FarmResourceType.harvester);
      expect(harvester.name, contains('Harvester'));
      expect(harvester.pricePaise, 140000); // ₹1,400/hr
    });

    test('Category filter correctly partitions equipment and supplies', () async {
      final all = await repo.getNearbyResources();
      expect(all.length, greaterThanOrEqualTo(7));

      final tractorsOnly = await repo.getNearbyResources(type: FarmResourceType.tractor);
      expect(tractorsOnly.every((r) => r.type == FarmResourceType.tractor), isTrue);

      final droneOnly = await repo.getNearbyResources(type: FarmResourceType.drone);
      expect(droneOnly.every((r) => r.type == FarmResourceType.drone), isTrue);
    });

    test('CHECK BEFORE MOVING ON: Book a tractor and verify Escrow is Held', () async {
      final resources = await repo.getNearbyResources();
      final tractor = resources.firstWhere((r) => r.type == FarmResourceType.tractor);

      final startAt = DateTime.now().add(const Duration(hours: 12));
      final endAt = startAt.add(const Duration(hours: 4));

      // Book 4 hours of tractor rental
      final booking = await repo.bookResource(
        resourceId: tractor.id,
        startAt: startAt,
        endAt: endAt,
        quantity: 4.0,
        deliveryAddress: 'Mandya Sugarcane Plot No. 12',
        notes: 'Dry rotavator tilling required',
        paymentMethod: 'upi',
      );

      // Verify booking invariants
      expect(booking.id, isNotEmpty);
      expect(booking.status, ResourceBookingStatus.confirmed);
      expect(booking.isEscrowHeld, isTrue, reason: 'Escrow must be held on booking');
      expect(booking.totalPaise, 85000 * 4); // 4 hours * ₹850
      expect(booking.formattedTotal, '₹3400');
      expect(booking.receiptNo, startsWith('RCP-'));
      expect(booking.deliveryAddress, contains('Mandya'));

      // Verify booking appears in farmer bookings list
      final farmerBookings = await repo.getFarmerBookings(booking.renterId);
      expect(farmerBookings.any((b) => b.id == booking.id), isTrue);
    });

    test('Vendor view: manage machinery listings and booking status lifecycle', () async {
      // 1. Add new vendor equipment
      const newEquipment = FarmResource(
        id: 'test-vendor-eq-1',
        ownerId: 'vendor-123',
        type: FarmResourceType.labourEquipment,
        name: 'Laser Land Leveller Kit',
        pricePaise: 95000,
        unit: 'acre',
        specs: 'Dual Slope GPS Precision',
        addressText: 'Koppa Agri Yard',
        active: true,
      );

      final created = await repo.createOrUpdateResource(newEquipment);
      expect(created.name, 'Laser Land Leveller Kit');

      final vendorResources = await repo.getVendorResources('vendor-123');
      expect(vendorResources.any((r) => r.name.contains('Laser Land Leveller')), isTrue);

      // 2. Book and transition status
      final booking = await repo.bookResource(
        resourceId: created.id,
        startAt: DateTime.now(),
        endAt: DateTime.now().add(const Duration(hours: 4)),
        quantity: 2.0,
        deliveryAddress: 'Plot 7',
      );

      final inProgress = await repo.updateBookingStatus(
        booking.id,
        ResourceBookingStatus.inProgress,
      );
      expect(inProgress.status, ResourceBookingStatus.inProgress);

      final completed = await repo.updateBookingStatus(
        booking.id,
        ResourceBookingStatus.completed,
      );
      expect(completed.status, ResourceBookingStatus.completed);
    });
  });

  group('P6.3 Labour Hiring & Seeker Job Discovery Invariants', () {
    test('CHECK BEFORE MOVING ON: Post a harvest shift job with category Agri Labour and verify job parameters', () async {
      final draft = JobPostDraft(
        title: 'Crop Harvesting & Threshing Shift',
        categoryId: 'b2222222-2222-4222-8222-222222222222',
        categoryName: 'Agri Labour',
        description: 'Harvest helper shift for ready tomato and paddy crops. ₹650 per day.',
        wageType: 'daily',
        wagePaise: 65000,
        slotsTotal: 5,
        startAt: DateTime.now().add(const Duration(days: 1)),
        addressText: 'Mandya Farm Cluster, Field Sector 4',
        latitude: 12.5244,
        longitude: 76.8951,
        paymentMode: 'escrow',
        studentsOk: true,
      );

      expect(draft.categoryName, 'Agri Labour');
      expect(draft.wagePaise, 65000);
      expect(draft.wageInRupees, 650.0);
      expect(draft.slotsTotal, 5);
      expect(draft.paymentMode, 'escrow');
      expect(draft.latitude, 12.5244);
      expect(draft.longitude, 76.8951);
    });
  });

  group('P6.3 UI Fidelity & Widget Tests', () {
    testWidgets('Screen 26 EquipmentRentalSection renders equipment cards, ratings and Book Now CTA', (tester) async {
      const mockResources = [
        FarmResource(
          id: 'res-1',
          ownerId: 'owner-1',
          type: FarmResourceType.tractor,
          name: 'Mahindra 575 DI Tractor + Rotavator',
          pricePaise: 85000,
          unit: 'hr',
          specs: '50 HP • Fuel Included',
          addressText: 'Kisan Machinery Hub • 2.4 km away',
          ratingAvg: 4.9,
          active: true,
        ),
        FarmResource(
          id: 'res-2',
          ownerId: 'owner-2',
          type: FarmResourceType.harvester,
          name: 'Multi-Crop Harvester & Thresher',
          pricePaise: 140000,
          unit: 'hr',
          specs: 'High Yield Grain Cutter',
          addressText: 'AgriTech Rentals Mandya • 4.1 km away',
          ratingAvg: 4.8,
          active: true,
        ),
        FarmResource(
          id: 'res-3',
          ownerId: 'owner-3',
          type: FarmResourceType.drone,
          name: 'Agricultural Drone Spraying Kit',
          pricePaise: 45000,
          unit: 'acre',
          specs: '10L Tank • Precision GPS',
          addressText: 'DroneKisan Karnataka • 1.8 km away',
          ratingAvg: 5.0,
          active: true,
        ),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          const SingleChildScrollView(
            child: EquipmentRentalSection(
              resources: mockResources,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Header & Escrow badge
      expect(find.text('NEARBY EQUIPMENT & DRONE RENTALS'), findsOneWidget);
      expect(find.text('Escrow Guaranteed'), findsOneWidget);

      // Check 3 equipment cards
      expect(find.text('Mahindra 575 DI Tractor + Rotavator'), findsOneWidget);
      expect(find.text('Multi-Crop Harvester & Thresher'), findsOneWidget);
      expect(find.text('Agricultural Drone Spraying Kit'), findsOneWidget);

      // Check specs
      expect(find.text('•  50 HP • Fuel Included'), findsOneWidget);
      expect(find.text('•  High Yield Grain Cutter'), findsOneWidget);
      expect(find.text('•  10L Tank • Precision GPS'), findsOneWidget);

      // Check Book Now buttons
      expect(find.text('Book Now'), findsNWidgets(3));
    });

    testWidgets('BookResourceModal displays escrow guarantee card and itemized breakdown', (tester) async {
      const tractor = FarmResource(
        id: 'res-tractor',
        ownerId: 'owner-kisan',
        type: FarmResourceType.tractor,
        name: 'Mahindra 575 DI Tractor + Rotavator',
        pricePaise: 85000,
        unit: 'hr',
        specs: '50 HP • Fuel Included',
        addressText: 'Kisan Machinery Hub',
        ratingAvg: 4.9,
      );

      await tester.pumpWidget(
        _buildTestApp(
          const BookResourceModal(resource: tractor),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mahindra 575 DI Tractor + Rotavator'), findsOneWidget);
      expect(find.text('Escrow Guaranteed Payment'), findsOneWidget);
      expect(find.textContaining('Total Payable in Escrow'), findsOneWidget);
      expect(find.textContaining('Book with Escrow'), findsOneWidget);
    });

    testWidgets('Screen 23 FarmResourcesMapScreen renders header, category filter chips and search bar', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const FarmResourcesMapScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check Header
      expect(
        find.text('FARMERS REQUIRED PRODUCTS, SEEDS, MACHINERY & SERVICES NEAR ME'),
        findsOneWidget,
      );

      // Check Category Filter Chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Tractors & Implements'), findsOneWidget);
      expect(find.text('Seeds & Bio-Fertilizers'), findsOneWidget);
      expect(find.text('Cold Storage'), findsOneWidget);
      expect(find.text('Drones & Spraying'), findsOneWidget);

      // Check Search bar hint
      expect(find.text('Search machinery, seeds, drones...'), findsOneWidget);
    });

    testWidgets('Equipment rental widgets render without overflow at 1.3x text scale factor', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);

      const mockResources = [
        FarmResource(
          id: 'res-1',
          ownerId: 'owner-1',
          type: FarmResourceType.tractor,
          name: 'Mahindra 575 DI Tractor + Rotavator',
          pricePaise: 85000,
          unit: 'hr',
          specs: '50 HP • Fuel Included',
          addressText: 'Kisan Machinery Hub',
          ratingAvg: 4.9,
          active: true,
        ),
      ];

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: _buildTestApp(
            const SingleChildScrollView(
              child: EquipmentRentalSection(
                resources: mockResources,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
