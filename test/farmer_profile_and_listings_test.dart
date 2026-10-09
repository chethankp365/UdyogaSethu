import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/farmer/data/farmer_listings_repository.dart';
import 'package:udyogasethu/features/farmer/domain/produce_listing_model.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_listings_screen.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_profile_screen.dart';
import 'package:udyogasethu/features/provider/presentation/widgets/buyer_produce_tab.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

Widget createTestApp({required Widget child, List<dynamic> overrides = const []}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('kn'),
        Locale('hi'),
        Locale('te'),
        Locale('ta'),
        Locale('mr'),
        Locale('bn'),
        Locale('or'),
      ],
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P6.2 Produce Listings & Buyer Search Invariants', () {
    late FarmerListingsRepository repository;

    setUp(() {
      repository = FarmerListingsRepository();
    });

    test('Buyer feed strictly excludes zero-stock and sold-out items', () async {
      final buyerListings = await repository.getBuyerProduceListings();

      // Seed list has 4 items: Tomatoes (120kg), Rice (450kg), Banana (8 bunch), Potatoes (0kg, soldOut).
      // Verify Potatoes with 0 stock are NOT in buyer listings
      final hasZeroStock = buyerListings.any((l) => l.stockQty <= 0);
      expect(hasZeroStock, isFalse, reason: 'Buyer listings must never contain items with 0 stock');

      final potato = buyerListings.where((l) => l.name.contains('Baby Potatoes'));
      expect(potato.isEmpty, isTrue, reason: 'Sold out potato listing must be excluded from buyer feed');

      // Verify active & in-stock items are present
      final tomato = buyerListings.firstWhere((l) => l.name.contains('Tomatoes'));
      expect(tomato.stockQty, equals(120.0));
      expect(tomato.status, equals(ProduceStatus.active));
    });

    test('CHECK BEFORE MOVING ON: Setting stock to zero immediately hides listing from buyer search', () async {
      // 1. Initial check: Organic Hybrid Tomatoes is in buyer search
      var buyerListings = await repository.getBuyerProduceListings(search: 'Tomatoes');
      expect(buyerListings.length, equals(1));
      expect(buyerListings.first.id, equals('seed-tomato-1'));
      expect(buyerListings.first.isInStock, isTrue);

      // 2. Farmer sets stock to 0
      final updatedListing = await repository.updateStock('seed-tomato-1', 0.0);
      expect(updatedListing.stockQty, equals(0.0));
      expect(updatedListing.status, equals(ProduceStatus.soldOut));

      // 3. Buyer search MUST NO LONGER SHOW IT
      buyerListings = await repository.getBuyerProduceListings(search: 'Tomatoes');
      expect(buyerListings.isEmpty, isTrue, reason: 'Once stock reaches 0, buyer search must immediately hide it');

      // 4. Farmer replenishes stock to 50 kg -> becomes active again and re-appears in buyer search
      await repository.updateStock('seed-tomato-1', 50.0);
      buyerListings = await repository.getBuyerProduceListings(search: 'Tomatoes');
      expect(buyerListings.length, equals(1));
      expect(buyerListings.first.stockQty, equals(50.0));
      expect(buyerListings.first.status, equals(ProduceStatus.active));
    });

    test('Pausing a listing immediately hides it from buyer search', () async {
      // 1. Banana is in buyer search
      var buyerListings = await repository.getBuyerProduceListings(search: 'Banana');
      expect(buyerListings.isNotEmpty, isTrue);

      // 2. Pause listing
      final paused = await repository.setStatus('seed-banana-3', ProduceStatus.paused);
      expect(paused.status, equals(ProduceStatus.paused));

      // 3. Buyer search hides paused listing even though stock > 0
      buyerListings = await repository.getBuyerProduceListings(search: 'Banana');
      expect(buyerListings.isEmpty, isTrue, reason: 'Paused listings must not appear in buyer feed');

      // 4. Activate listing again
      await repository.setStatus('seed-banana-3', ProduceStatus.lowStock);
      buyerListings = await repository.getBuyerProduceListings(search: 'Banana');
      expect(buyerListings.isNotEmpty, isTrue);
    });

    test('Price suggestion band computation from APMC mandi benchmark', () async {
      final suggestion = await repository.getPriceSuggestion(commodity: 'Tomatoes', unit: 'kg');

      expect(suggestion.commodity, equals('Tomatoes'));
      expect(suggestion.mandiModalPriceRupees, equals(25.0));
      expect(suggestion.suggestedMinRupees, equals(22.5));
      expect(suggestion.suggestedMaxRupees, equals(28.75));
      expect(suggestion.formattedBand, equals('₹23 – ₹29'));
    });
  });

  group('Farmer Profile Screen UI Fidelity & Accessibility Tests', () {
    testWidgets('Renders all elements of Page 7 Phone 1 visual reference', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));

      await tester.pumpWidget(createTestApp(
        child: const FarmerProfileScreen(),
      ));
      await tester.pumpAndSettle();

      // 1. Hero Card Elements
      expect(find.text('Farmer Chethan Gowda'), findsOneWidget);
      expect(find.text('VERIFIED FARMER ✓'), findsOneWidget);
      expect(find.text('Greenfield Organic Farm • Mandya Cluster'), findsOneWidget);
      expect(find.text('+91 98450 77889'), findsOneWidget);

      // 3 Live metric boxes
      expect(find.text('4.2 Acres'), findsOneWidget);
      expect(find.text('Organic Land'), findsOneWidget);
      expect(find.text('420 kg'), findsOneWidget);
      expect(find.text('Sold This Month'), findsOneWidget);
      expect(find.text('₹48,500'), findsOneWidget);
      expect(find.text('Direct Sales'), findsOneWidget);

      // 2. Infrastructure & Crop Badges
      expect(find.text('FARM INFRASTRUCTURE & CROP BADGES'), findsOneWidget);
      expect(find.text('Red Loam Soil (pH 6.8)'), findsOneWidget);
      expect(find.text('Tomatoes, Paddy, Banana'), findsOneWidget);
      expect(find.text('Mandya APMC #4812'), findsOneWidget);
      expect(find.text('KCC Approved ✓'), findsOneWidget);

      // 3. Zero-Pesticide Organic Certificate Card
      expect(find.text('Zero-Pesticide Organic Certificate'), findsOneWidget);
      expect(find.text('Verified by Karnataka Organic Farmers Board'), findsOneWidget);
      expect(find.text('VALIDATED ✓'), findsOneWidget);

      // 4. Language Mode Card
      expect(find.text('LANGUAGE MODE'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('ಕನ್ನಡ'), findsOneWidget);
      expect(find.text('తెలుగు'), findsOneWidget);
      expect(find.text('हिंदी'), findsOneWidget);
      expect(find.text('தமிழ்'), findsOneWidget);

      // 5. Manage Produce Listings link
      expect(find.text('Manage Produce Listings'), findsOneWidget);
    });

    testWidgets('Renders without overflow at 1.3x text scale factor', (tester) async {
      await tester.binding.setSurfaceSize(const Size(380, 850));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: FarmerProfileScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Must not trigger RenderFlex overflow at 1.3x scale');
      expect(find.text('Farmer Chethan Gowda'), findsOneWidget);
    });
  });

  group('Farmer Produce Listings Screen Widget Tests', () {
    testWidgets('Renders produce listings cards, filter chips, and add produce FAB', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));

      await tester.pumpWidget(createTestApp(
        child: const FarmerListingsScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Produce Listings'), findsOneWidget);
      expect(find.text('Add New Produce'), findsOneWidget);

      // Filter chips and status pills
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Low Stock'), findsWidgets);
      expect(find.text('Sold Out'), findsWidgets);
      expect(find.text('Paused'), findsWidgets);

      // Items from seed list
      expect(find.text('Organic Hybrid Tomatoes'), findsOneWidget);
      expect(find.text('Fresh Sona Masuri Rice'), findsOneWidget);
    });
  });

  group('Buyer Produce Tab Widget Tests', () {
    testWidgets('Shows only in-stock produce to buyers and excludes zero-stock items', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));

      await tester.pumpWidget(createTestApp(
        child: const Scaffold(
          body: SizedBox(
            height: 700,
            child: BuyerProduceTab(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Fresh farm produce items in stock should be shown
      expect(find.text('Organic Red Tomatoes'), findsOneWidget);
      expect(find.text('Pure A2 Gir Cow Milk'), findsOneWidget);

      // Sold out potatoes (stock 0) must NOT be shown
      expect(find.text('Fresh Farm Baby Potatoes'), findsNothing);

      // Order Direct button
      expect(find.text('Order Direct'), findsWidgets);
    });
  });
}
