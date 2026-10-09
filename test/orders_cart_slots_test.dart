import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/core/supabase/supabase_service.dart';
import 'package:udyogasethu/features/marketplace/data/orders_repository.dart';
import 'package:udyogasethu/features/marketplace/domain/cart_item.dart';
import 'package:udyogasethu/features/marketplace/domain/delivery_slot.dart';
import 'package:udyogasethu/features/marketplace/domain/order_timeline_event.dart';
import 'package:udyogasethu/features/marketplace/domain/produce_marketplace_item.dart';
import 'package:udyogasethu/features/marketplace/domain/produce_order.dart';
import 'package:udyogasethu/features/marketplace/presentation/cart_screen.dart';
import 'package:udyogasethu/features/marketplace/presentation/order_checkout_wizard.dart';
import 'package:udyogasethu/features/marketplace/presentation/order_confirmation_screen.dart';
import 'package:udyogasethu/features/farmer/presentation/delivery_slots_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

void main() {
  final sampleItem1 = ProduceMarketplaceItem(
    id: 'prod-item-1',
    farmerId: 'farmer-101',
    farmerName: 'Cauvery Bio Farm',
    farmName: 'Cauvery Bio Farm',
    clusterVillage: 'Mandya Cluster',
    name: 'Organic Desi Tomatoes',
    category: 'vegetable',
    pricePaise: 3400, // ₹34/kg
    unit: 'kg',
    stockQty: 10.0,
    lotNumber: 'LOT-2026-TOM01',
    createdAt: DateTime.now(),
    harvestAt: DateTime.now(),
  );

  final sampleItem2 = ProduceMarketplaceItem(
    id: 'prod-item-2',
    farmerId: 'farmer-202',
    farmerName: 'Mandya Organic Milk',
    farmName: 'Mandya Dairy Cooperative',
    clusterVillage: 'Maddur Cluster',
    name: 'Fresh A2 Cow Milk',
    category: 'dairy',
    pricePaise: 6000, // ₹60/L
    unit: 'L',
    stockQty: 50.0,
    lotNumber: 'LOT-2026-MILK02',
    createdAt: DateTime.now(),
    harvestAt: DateTime.now(),
  );

  Widget createTestWidget(
    Widget child, {
    CartState? initialCart,
    OrdersRepository? ordersRepo,
  }) {
    final fakeRepo = ordersRepo ?? FakeOrdersRepository();
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(null),
        ordersRepositoryProvider.overrideWithValue(fakeRepo),
        farmerDeliverySlotsProvider.overrideWith((ref, farmerId) async {
          return fakeRepo.getFarmerDeliverySlots(farmerId);
        }),
        if (initialCart != null)
          cartNotifierProvider.overrideWith(() => _TestCartNotifier(initialCart)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: child,
      ),
    );
  }

  group('CartState & Domain Model Tests', () {
    test('CartItem subtotal and stock limits', () {
      final item = CartItem(produceItem: sampleItem1, quantity: 3.0);
      expect(item.subtotalPaise, 10200); // 3 * 3400 = 10200 paise (₹102)
      expect(item.formattedSubtotal, '₹102');
      expect(item.canIncrease, true);
      expect(item.maxStock, 10.0);
    });

    test('Multi-farmer cart groups automatically split', () {
      final cart = CartState(items: {
        'prod-item-1': CartItem(produceItem: sampleItem1, quantity: 2.0),
        'prod-item-2': CartItem(produceItem: sampleItem2, quantity: 3.0),
      });

      expect(cart.farmerGroups.length, 2);
      expect(cart.farmerGroups[0].farmerId, 'farmer-101');
      expect(cart.farmerGroups[0].items.length, 1);
      expect(cart.farmerGroups[1].farmerId, 'farmer-202');
      expect(cart.farmerGroups[1].items.length, 1);

      // Total subtotal: (2 * 3400) + (3 * 6000) = 6800 + 18000 = 24800 paise (₹248)
      expect(cart.subtotalPaise, 24800);
      expect(cart.formattedSubtotal, '₹248');
    });

    test('Reward discount calculation', () {
      final cartNoRewards = CartState(
        items: {
          'prod-item-1': CartItem(produceItem: sampleItem1, quantity: 5.0),
        },
        useRewardCredits: false,
      );
      expect(cartNoRewards.discountPaise, 0);

      final cartWithRewards = CartState(
        items: {
          'prod-item-1': CartItem(produceItem: sampleItem1, quantity: 5.0), // 17000 paise (₹170)
        },
        useRewardCredits: true,
      );
      // 5% of 17000 = 850 paise (₹8.50)
      expect(cartWithRewards.discountPaise, 850);
      expect(cartWithRewards.totalPayablePaise, 16150);
    });
  });

  group('DeliverySlot Domain Tests', () {
    test('Delivery mode badges and capacity', () {
      final now = DateTime.now();
      final todaySlot = DeliverySlot(
        id: 'slot-1',
        farmerId: 'farmer-101',
        slotDate: now,
        windowStart: '07:00:00',
        windowEnd: '11:00:00',
        capacity: 10,
        used: 8,
      );

      expect(todaySlot.mode, DeliveryMode.sameDay);
      expect(todaySlot.availableCapacity, 2);
      expect(todaySlot.isFull, false);
      expect(todaySlot.formattedWindow, '7:00 AM - 11:00 AM');

      final fullSlot = DeliverySlot(
        id: 'slot-2',
        farmerId: 'farmer-101',
        slotDate: now.add(const Duration(days: 1)),
        windowStart: '16:00:00',
        windowEnd: '19:00:00',
        capacity: 10,
        used: 10,
      );

      expect(fullSlot.mode, DeliveryMode.nextDay);
      expect(fullSlot.availableCapacity, 0);
      expect(fullSlot.isFull, true);
    });
  });

  group('Widget & Overflow Tests (360dp width & 1.6x text scale)', () {
    testWidgets('CartScreen renders empty state correctly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestWidget(
          const MediaQuery(
            data: MediaQueryData(size: Size(360, 640), textScaler: TextScaler.linear(1.6)),
            child: CartScreen(),
          ),
          initialCart: const CartState(items: {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your Cart is Empty'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_basket_outlined), findsOneWidget);
    });

    testWidgets('CartScreen renders multi-farmer items without overflow at 360dp & 1.6x scale', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testCart = CartState(items: {
        'prod-item-1': CartItem(produceItem: sampleItem1, quantity: 2.0),
        'prod-item-2': CartItem(produceItem: sampleItem2, quantity: 1.0),
      });

      await tester.pumpWidget(
        createTestWidget(
          const MediaQuery(
            data: MediaQueryData(size: Size(360, 640), textScaler: TextScaler.linear(1.6)),
            child: CartScreen(),
          ),
          initialCart: testCart,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Shopping Cart (3)'), findsOneWidget);
      expect(find.text('Organic Desi Tomatoes'), findsOneWidget);
      expect(find.text('Fresh A2 Cow Milk'), findsOneWidget);
      expect(find.text('Checkout'), findsOneWidget);

      // Verify no RenderFlex overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('OrderCheckoutWizard renders slot and payment steps without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testCart = CartState(items: {
        'prod-item-1': CartItem(produceItem: sampleItem1, quantity: 2.0),
      });

      await tester.pumpWidget(
        createTestWidget(
          const MediaQuery(
            data: MediaQueryData(size: Size(360, 640), textScaler: TextScaler.linear(1.6)),
            child: OrderCheckoutWizard(),
          ),
          initialCart: testCart,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Direct Farm Checkout'), findsOneWidget);
      expect(find.text('Doorstep Delivery'), findsOneWidget);
      expect(find.text('Farm Pickup'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Verify no RenderFlex overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('OrderConfirmationScreen renders order code and escrow badge', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final sampleOrder = ProduceOrder(
        orderId: 'test-ord-1',
        orderCode: 'ORD-261009-TEST99',
        farmerId: 'farmer-101',
        farmerName: 'Cauvery Bio Farm',
        totalPaise: 6800,
        feePaise: 500,
        discountPaise: 0,
        status: 'pending',
        itemsCount: 1,
        fulfilment: 'delivery',
        protected: true,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(360, 640), textScaler: TextScaler.linear(1.6)),
            child: OrderConfirmationScreen(
              orderId: sampleOrder.orderId,
              orders: [sampleOrder],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Order Placed Successfully!'), findsOneWidget);
      expect(find.text('ORD-261009-TEST99'), findsOneWidget);
      expect(find.text('Escrow Protected Payment'), findsOneWidget);
      expect(find.text('Back to Produce Marketplace'), findsOneWidget);

      // Verify no RenderFlex overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('DeliverySlotsScreen renders slots and modal cleanly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestWidget(
          const MediaQuery(
            data: MediaQueryData(size: Size(360, 640), textScaler: TextScaler.linear(1.6)),
            child: DeliverySlotsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Farm Delivery & Pickup Slots'), findsOneWidget);
      expect(find.text('+ Add Delivery Slot'), findsOneWidget);

      // Tap + Add Delivery Slot to test modal sheet
      await tester.tap(find.text('+ Add Delivery Slot'));
      await tester.pumpAndSettle();

      expect(find.text('Add Delivery Window Slot'), findsOneWidget);
      expect(find.text('Slot Capacity (Max Orders)'), findsOneWidget);

      // Verify no RenderFlex overflow
      expect(tester.takeException(), isNull);

      // Close modal sheet
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
    });
  });
}

class _TestCartNotifier extends CartNotifier {
  final CartState _initialState;
  _TestCartNotifier(this._initialState);

  @override
  CartState build() => _initialState;
}

class FakeOrdersRepository implements OrdersRepository {
  final List<DeliverySlot> slots;

  FakeOrdersRepository({List<DeliverySlot>? initialSlots})
      : slots = initialSlots ??
            [
              DeliverySlot(
                id: 'slot-1',
                farmerId: 'farmer-101',
                slotDate: DateTime.now(),
                windowStart: '08:00',
                windowEnd: '12:00',
                capacity: 10,
                used: 2,
              ),
              DeliverySlot(
                id: 'slot-2',
                farmerId: 'farmer-202',
                slotDate: DateTime.now().add(const Duration(days: 1)),
                windowStart: '14:00',
                windowEnd: '18:00',
                capacity: 5,
                used: 1,
              ),
            ];

  @override
  Future<List<DeliverySlot>> getFarmerDeliverySlots(String farmerId) async {
    return slots;
  }

  @override
  Future<String> createDeliverySlot({
    required DateTime date,
    required String windowStart,
    required String windowEnd,
    required int capacity,
  }) async {
    return 'new-slot-id';
  }

  @override
  Future<List<ProduceOrder>> placeOrder({
    required List<Map<String, dynamic>> items,
    required String fulfilment,
    String? addressText,
    String? slotId,
    Map<String, String>? slots,
    required bool isProtected,
    required bool applyRewardCredits,
    required String paymentMethod,
    String? deliveryNotes,
  }) async {
    return [
      ProduceOrder(
        orderId: 'mock-order-id',
        orderCode: 'ORD-261009-MOCK01',
        farmerId: 'farmer-101',
        farmerName: 'Cauvery Bio Farm',
        totalPaise: 3400,
        feePaise: 500,
        discountPaise: 0,
        status: 'pending',
        itemsCount: 1,
        fulfilment: fulfilment,
        protected: isProtected,
        createdAt: DateTime.now(),
      )
    ];
  }

  @override
  Future<ProduceOrder?> getOrderDetails(String orderId) async => null;

  @override
  Stream<ProduceOrder?> watchOrder(String orderId) => const Stream.empty();

  @override
  Stream<List<OrderTimelineEvent>> watchOrderEvents(String orderId) =>
      const Stream.empty();

  @override
  Future<List<ProduceOrder>> getFarmerOrders({String? status}) async => [];

  @override
  Stream<List<ProduceOrder>> watchFarmerOrders({String? status}) =>
      const Stream.empty();

  @override
  Future<List<ProduceOrder>> getCustomerOrders() async => [];

  @override
  Stream<List<ProduceOrder>> watchCustomerOrders() => const Stream.empty();

  @override
  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
    String? pin,
    String? notes,
  }) async =>
      {'status': status, 'order_id': orderId};

  @override
  Future<void> submitOrderReview({
    required String orderId,
    required String targetId,
    required int stars,
    required List<String> tags,
    String? comment,
  }) async {}

  @override
  Future<void> createOrderDispute({
    required String orderId,
    required String againstId,
    required String issueType,
    required String details,
  }) async {}
}

