import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/marketplace/data/produce_marketplace_repository.dart';
import 'package:udyogasethu/features/marketplace/domain/lot_traceability_data.dart';
import 'package:udyogasethu/features/marketplace/domain/produce_filters.dart';
import 'package:udyogasethu/features/marketplace/presentation/produce_detail_screen.dart';
import 'package:udyogasethu/features/marketplace/presentation/widgets/farm_traceability_modal.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

Widget _buildTestApp(Widget child, {Locale locale = const Locale('en'), double textScale = 1.0, Size size = const Size(360, 640)}) {
  return ProviderScope(
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  group('P6.4 Produce Marketplace Repository & Filter Combinations', () {
    late ProduceMarketplaceRepository repo;

    setUp(() {
      repo = ProduceMarketplaceRepository();
    });

    test('Loads catalog with 6 realistic Karnataka produce items and verified farm lots', () async {
      final items = await repo.getNearbyProduce();
      expect(items.length, 6);

      final tomatoes = items.firstWhere((p) => p.lotNumber == 'LOT-KA-2026-TOM-01');
      expect(tomatoes.name, 'Organic Red Tomatoes');
      expect(tomatoes.pricePaise, 3400); // ₹34/kg
      expect(tomatoes.unit, 'kg');
      expect(tomatoes.stockQty, 120.0);
      expect(tomatoes.category, 'vegetable');
      expect(tomatoes.farmingMethod, 'Zero-Pesticide Organic');
      expect(tomatoes.organicCertified, isTrue);
      expect(tomatoes.walkInStore, isFalse);
      expect(tomatoes.deliveryAvailable, isTrue);
      expect(tomatoes.isVerifiedFarmer, isTrue);
      expect(tomatoes.formattedPrice, '₹34/kg');
      expect(tomatoes.freshnessLabel, contains('Harvested'));

      final milk = items.firstWhere((p) => p.lotNumber == 'LOT-KA-2026-MLK-02');
      expect(milk.name, 'Pure A2 Gir Cow Milk');
      expect(milk.pricePaise, 6000); // ₹60/Liter
      expect(milk.unit, 'Liter');
      expect(milk.category, 'dairy');
      expect(milk.walkInStore, isTrue);
    });

    test('Category filter isolates categories correctly', () async {
      final vegItems = await repo.getNearbyProduce(
        filters: const ProduceFilters(category: 'vegetable'),
      );
      expect(vegItems.every((item) => item.category == 'vegetable'), isTrue);
      expect(vegItems.length, 1);

      final dairyItems = await repo.getNearbyProduce(
        filters: const ProduceFilters(category: 'dairy'),
      );
      expect(dairyItems.every((item) => item.category == 'dairy'), isTrue);
      expect(dairyItems.length, 1);

      final fruitItems = await repo.getNearbyProduce(
        filters: const ProduceFilters(category: 'fruit'),
      );
      expect(fruitItems.every((item) => item.category == 'fruit'), isTrue);
      expect(fruitItems.length, 1);
    });

    test('Filter combinations: price, distance, rating, organic & walk-in store combine correctly', () async {
      // 1. Max price ₹50/unit
      final affordable = await repo.getNearbyProduce(
        filters: const ProduceFilters(maxPricePaise: 5000),
      );
      expect(affordable.every((item) => item.pricePaise <= 5000), isTrue);

      // 2. Max distance 5 km
      final nearby = await repo.getNearbyProduce(
        filters: const ProduceFilters(maxDistanceKm: 5.0),
      );
      expect(nearby.every((item) => item.distanceM != null && item.distanceM! <= 5000), isTrue);

      // 3. Min farmer rating 4.8 stars
      final topRated = await repo.getNearbyProduce(
        filters: const ProduceFilters(minRating: 4.8),
      );
      expect(topRated.every((item) => item.farmerRatingAvg >= 4.8), isTrue);

      // 4. Combined: Organic certified only + Walk-in store pickup only
      final organicDepot = await repo.getNearbyProduce(
        filters: const ProduceFilters(
          organicCertifiedOnly: true,
          walkInStoreOnly: true,
        ),
      );
      expect(organicDepot.every((item) => item.organicCertified && item.walkInStore), isTrue);
      expect(organicDepot.length, greaterThanOrEqualTo(2));

      // 5. Freshness filter: harvested last 24h
      final freshest24h = await repo.getNearbyProduce(
        filters: const ProduceFilters(freshness: FreshnessFilter.last24h),
      );
      expect(freshest24h.length, greaterThanOrEqualTo(3));
      final now = DateTime.now();
      expect(
        freshest24h.every((item) => item.harvestAt != null && now.difference(item.harvestAt!).inHours <= 24),
        isTrue,
      );
    });

    test('Sorting orders produce by distance, price asc/desc, rating, and freshness', () async {
      // Price low to high
      final priceAsc = await repo.getNearbyProduce(
        filters: const ProduceFilters(sortBy: ProduceSortOption.priceAsc),
      );
      for (int i = 0; i < priceAsc.length - 1; i++) {
        expect(priceAsc[i].pricePaise <= priceAsc[i + 1].pricePaise, isTrue);
      }

      // Price high to low
      final priceDesc = await repo.getNearbyProduce(
        filters: const ProduceFilters(sortBy: ProduceSortOption.priceDesc),
      );
      for (int i = 0; i < priceDesc.length - 1; i++) {
        expect(priceDesc[i].pricePaise >= priceDesc[i + 1].pricePaise, isTrue);
      }

      // Rating high to low
      final ratingDesc = await repo.getNearbyProduce(
        filters: const ProduceFilters(sortBy: ProduceSortOption.ratingDesc),
      );
      for (int i = 0; i < ratingDesc.length - 1; i++) {
        expect(ratingDesc[i].farmerRatingAvg >= ratingDesc[i + 1].farmerRatingAvg, isTrue);
      }

      // Freshest first
      final freshest = await repo.getNearbyProduce(
        filters: const ProduceFilters(sortBy: ProduceSortOption.freshnessDesc),
      );
      for (int i = 0; i < freshest.length - 1; i++) {
        if (freshest[i].harvestAt != null && freshest[i + 1].harvestAt != null) {
          expect(
            freshest[i].harvestAt!.isAfter(freshest[i + 1].harvestAt!) ||
            freshest[i].harvestAt!.isAtSameMomentAs(freshest[i + 1].harvestAt!),
            isTrue,
          );
        }
      }
    });
  });

  group('P6.4 Farm Lot Traceability & Security Token Signing', () {
    test('Token is HMAC signed without leaking database ids or personal data', () {
      final token = LotTraceabilityData.createSignedLotToken(
        lotNumber: 'LOT-KA-2026-TOM-01',
        listingId: 'a1111111-3333-4333-8333-111111111111',
      );

      expect(token, contains('.'));
      final parsed = LotTraceabilityData.parseSignedLotToken(token);
      expect(parsed, isNotNull);
      expect(parsed!['lot_id'], 'LOT-KA-2026-TOM-01');
      expect(parsed['pur'], 'produce_lot');

      // Verify tampered signature fails verification
      final tampered = '${token.substring(0, token.length - 6)}XXXXXX';
      final tamperedParsed = LotTraceabilityData.parseSignedLotToken(tampered);
      expect(tamperedParsed, isNull);
    });

    test('CHECK BEFORE MOVING ON: Scanned lot QR resolves to matching crop and harvest time', () async {
      final repo = ProduceMarketplaceRepository();

      final items = await repo.getNearbyProduce();
      final targetListing = items.firstWhere((p) => p.lotNumber == 'LOT-KA-2026-TOM-01');

      // 1. Farmer generates lot QR token
      final token = await repo.getOrGenerateLotToken(targetListing);

      // 2. Buyer scans token on a second phone
      final parsed = LotTraceabilityData.parseSignedLotToken(token);
      expect(parsed, isNotNull);

      // 3. Buyer fetches public traceability record
      final trace = await repo.getLotTraceability(token);

      // Invariant checks:
      expect(trace.cropItem, equals(targetListing.name));
      expect(trace.harvestTime, equals(targetListing.freshnessLabel));
      expect(trace.lotNumber, equals(targetListing.lotNumber));
      expect(trace.farmingMethod, equals(targetListing.farmingMethod));
      expect(trace.farmerOrigin, contains(targetListing.farmName));
      expect(trace.farmerOrigin, contains(targetListing.clusterVillage));
    });
  });

  group('P6.4 UI Widget & Layout Overflow Tests', () {
    testWidgets('FarmTraceabilityModal displays verified quality fields matching Screen 28', (tester) async {
      final trace = LotTraceabilityData(
        listingId: 'listing-1',
        lotNumber: 'LOT-KA-2026-TOM-01',
        cropItem: 'Organic Red Tomatoes',
        category: 'vegetable',
        farmerOrigin: 'Ravi Organic Vegetable Farm • Devanahalli Organic Cluster',
        clusterVillage: 'Devanahalli Organic Cluster',
        harvestTime: 'Harvested Today (4h ago)',
        harvestAt: DateTime.now().subtract(const Duration(hours: 4)),
        farmingMethod: 'ZBNF Natural',
        organicCertification: 'Zero-Pesticide Certified ✓',
        qualityNotes: 'Grade A table tomatoes picked at dawn. Zero chemical sprays.',
        pricePaise: 3400,
        unit: 'kg',
        ratingAvg: 4.9,
      );

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => FarmTraceabilityModal.show(context, trace),
              child: const Text('Open Traceability'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Traceability'));
      await tester.pumpAndSettle();

      expect(find.text('Farm Quality Traceability Verified'), findsOneWidget);
      expect(find.text('Organic Red Tomatoes'), findsOneWidget);
      expect(find.textContaining('LOT-KA-2026-TOM-01'), findsOneWidget);
      expect(find.text('Ravi Organic Vegetable Farm • Devanahalli Organic Cluster'), findsOneWidget);
      expect(find.text('Harvested Today (4h ago)'), findsOneWidget);
      expect(find.text('Zero-Pesticide Certified ✓'), findsOneWidget);
      expect(find.text('ZBNF Natural'), findsOneWidget);
      expect(find.text('Close Traceability Details'), findsOneWidget);
    });

    testWidgets('ProduceDetailScreen stepper and debug helper render without overflow at 360dp width and textScale 1.6', (tester) async {
      tester.view.physicalSize = const Size(360, 640) * 2.0;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = ProduceMarketplaceRepository();
      final item = repo.fallbackProduceCatalog.first;

      await tester.pumpWidget(
        _buildTestApp(
          ProduceDetailScreen(item: item),
          size: const Size(360, 640),
          textScale: 1.6,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Organic Red Tomatoes'), findsWidgets);
      expect(find.text('Order Now'), findsOneWidget);

      // Verify debug helper button exists in debug build
      final debugButton = find.text('Show Lot QR Code for Scanning');
      expect(debugButton, findsOneWidget);

      // Ensure debug QR button is scrolled into view before tapping
      await tester.ensureVisible(debugButton);
      await tester.pumpAndSettle();
      await tester.tap(debugButton);
      await tester.pumpAndSettle();

      expect(find.text('Debug Mode: Lot QR for Testing'), findsOneWidget);
      expect(find.text('Copy Token String'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
