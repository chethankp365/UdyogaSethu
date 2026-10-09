import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_order_board_screen.dart';
import 'package:udyogasethu/features/marketplace/data/orders_repository.dart';
import 'package:udyogasethu/features/marketplace/domain/delivery_slot.dart';
import 'package:udyogasethu/features/marketplace/domain/order_timeline_event.dart';
import 'package:udyogasethu/features/marketplace/domain/produce_order.dart';
import 'package:udyogasethu/features/marketplace/presentation/customer_orders_screen.dart';
import 'package:udyogasethu/features/marketplace/presentation/order_tracking_screen.dart';
import 'package:udyogasethu/features/marketplace/presentation/widgets/order_timeline_widget.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class MockP66OrdersRepository implements OrdersRepository {
  final ProduceOrder sampleOrder;
  final List<OrderTimelineEvent> sampleEvents;

  MockP66OrdersRepository({
    required this.sampleOrder,
    required this.sampleEvents,
  });

  @override
  Future<ProduceOrder?> getOrderDetails(String orderId) async => sampleOrder;

  @override
  Stream<ProduceOrder?> watchOrder(String orderId) => Stream.value(sampleOrder);

  @override
  Stream<List<OrderTimelineEvent>> watchOrderEvents(String orderId) =>
      Stream.value(sampleEvents);

  @override
  Future<List<ProduceOrder>> getFarmerOrders({String? status}) async =>
      [sampleOrder];

  @override
  Stream<List<ProduceOrder>> watchFarmerOrders({String? status}) =>
      Stream.value([sampleOrder]);

  @override
  Future<List<ProduceOrder>> getCustomerOrders() async => [sampleOrder];

  @override
  Stream<List<ProduceOrder>> watchCustomerOrders() =>
      Stream.value([sampleOrder]);

  @override
  Future<List<DeliverySlot>> getFarmerDeliverySlots(String farmerId) async => [];

  @override
  Future<String> createDeliverySlot({
    required DateTime date,
    required String windowStart,
    required String windowEnd,
    required int capacity,
  }) async =>
      'slot-1';

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
  }) async =>
      [sampleOrder];

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

void main() {
  final sampleOrder = ProduceOrder(
    orderId: 'ord-test-101',
    orderCode: 'ORD-261009-8472',
    farmerId: 'farmer-uuid-001',
    farmerName: 'Cauvery Bio Farm',
    customerName: 'Suresh Kumar',
    totalPaise: 4800, // ₹48.00
    feePaise: 500, // ₹5.00 platform fee
    discountPaise: 200,
    status: 'out_for_delivery',
    itemsCount: 2,
    fulfilment: 'delivery',
    protected: true,
    deliveryPin: '4829',
    slotDate: '2026-10-10',
    windowStart: '08:00',
    windowEnd: '12:00',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    items: const [
      ProduceOrderItem(
        listingId: 'listing-tomato-1',
        name: 'Organic Tomatoes',
        quantity: 2.0,
        unit: 'kg',
        unitPricePaise: 2000,
        subtotalPaise: 4000,
      ),
      ProduceOrderItem(
        listingId: 'listing-coriander-1',
        name: 'Fresh Coriander',
        quantity: 1.0,
        unit: 'bunch',
        unitPricePaise: 800,
        subtotalPaise: 800,
      ),
    ],
  );

  final sampleEvents = [
    OrderTimelineEvent(
      id: 'evt-1',
      orderId: 'ord-test-101',
      status: 'pending',
      note: 'Customer placed order and held escrow',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    OrderTimelineEvent(
      id: 'evt-2',
      orderId: 'ord-test-101',
      status: 'accepted',
      note: 'Farmer accepted and started harvesting',
      createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
    ),
    OrderTimelineEvent(
      id: 'evt-3',
      orderId: 'ord-test-101',
      status: 'packed',
      note: 'Crates packed and weighed',
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    OrderTimelineEvent(
      id: 'evt-4',
      orderId: 'ord-test-101',
      status: 'out_for_delivery',
      note: 'Dispatched for delivery',
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
  ];

  group('P6.6 Invariant & Settlement Unit Tests', () {
    test('Farmer wallet settlement invariant: net = total - fee', () {
      // Invariant check: CHECK BEFORE MOVING ON
      // After Delivered, the farmer wallet shows the amount minus the platform fee.
      expect(sampleOrder.totalPaise, 4800);
      expect(sampleOrder.feePaise, 500);
      expect(sampleOrder.netEarningsPaise, 4300); // ₹43.00 net
      expect(sampleOrder.formattedNetEarnings, '₹43');
      expect(sampleOrder.formattedFee, '₹5');

      // Double-entry ledger invariant:
      // Escrow Debit = Platform Fee Revenue + Farmer Wallet Credit
      final escrowDebit = sampleOrder.totalPaise;
      final platformRevenue = sampleOrder.feePaise;
      final farmerWalletCredit = sampleOrder.netEarningsPaise;

      expect(escrowDebit, platformRevenue + farmerWalletCredit);
      expect(farmerWalletCredit, escrowDebit - platformRevenue);
    });

    test('Order stage parsing and string mappings', () {
      expect(OrderStage.fromString('pending'), OrderStage.pending);
      expect(OrderStage.fromString('accepted'), OrderStage.accepted);
      expect(OrderStage.fromString('packed'), OrderStage.packed);
      expect(OrderStage.fromString('out_for_delivery'), OrderStage.outForDelivery);
      expect(OrderStage.fromString('delivered'), OrderStage.delivered);
      expect(OrderStage.fromString('cancelled'), OrderStage.cancelled);
      expect(OrderStage.fromString('disputed'), OrderStage.disputed);
    });

    test('4-Digit handover PIN validation', () {
      expect(sampleOrder.deliveryPin, '4829');
      expect(sampleOrder.deliveryPin!.length, 4);
      expect(int.tryParse(sampleOrder.deliveryPin!), isNotNull);

      // Verify farmer PIN match logic
      const enteredCorrectPin = '4829';
      const enteredWrongPin = '1234';

      expect(enteredCorrectPin == sampleOrder.deliveryPin, isTrue);
      expect(enteredWrongPin == sampleOrder.deliveryPin, isFalse);
    });

    test('1-Tap Reorder adds all items to cart state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(cartNotifierProvider).isEmpty, isTrue);

      container
          .read(cartNotifierProvider.notifier)
          .addOrderItems(sampleOrder.items, farmerId: sampleOrder.farmerId);

      final cartState = container.read(cartNotifierProvider);
      expect(cartState.totalUniqueItems, 2);
      expect(cartState.items['listing-tomato-1']?.produceItem.name,
          'Organic Tomatoes');
      expect(cartState.items['listing-tomato-1']?.quantity, 2.0);
      expect(cartState.items['listing-coriander-1']?.produceItem.name,
          'Fresh Coriander');
      expect(cartState.items['listing-coriander-1']?.quantity, 1.0);
    });
  });

  group('P6.6 UI Component & Screen Widget Tests', () {
    testWidgets('OrderTimelineWidget displays active progression correctly',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderEventsStreamProvider('ord-test-101')
                .overrideWith((ref) => Stream.value(sampleEvents)),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: OrderTimelineWidget(
                orderId: 'ord-test-101',
                currentStatus: 'out_for_delivery',
                fulfilment: 'delivery',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OrderTimelineWidget), findsOneWidget);
      expect(find.text('Order Placed'), findsWidgets);
      expect(find.text('Accepted by Farmer'), findsWidgets);
      expect(find.text('Packed & Weighed'), findsWidgets);
      expect(find.text('Out for Delivery'), findsWidgets);
    });

    testWidgets('OrderTrackingScreen renders without overflow at 360dp width and 1.6x text scale',
        (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 740 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockP66OrdersRepository(
        sampleOrder: sampleOrder,
        sampleEvents: sampleEvents,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ordersRepositoryProvider.overrideWithValue(mockRepo),
            orderDetailsStreamProvider('ord-test-101')
                .overrideWith((ref) => Stream.value(sampleOrder)),
            orderEventsStreamProvider('ord-test-101')
                .overrideWith((ref) => Stream.value(sampleEvents)),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(360, 740),
                textScaler: TextScaler.linear(1.6),
              ),
              child: OrderTrackingScreen(orderId: 'ord-test-101'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ORD-261009-8472'), findsOneWidget);
      expect(find.text('4829'), findsOneWidget); // PIN is visible
      expect(find.textContaining('Organic Tomatoes'), findsOneWidget);
      expect(find.textContaining('Fresh Coriander'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('FarmerOrderBoardScreen renders without overflow at 360dp width and 1.6x text scale',
        (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 740 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockP66OrdersRepository(
        sampleOrder: sampleOrder,
        sampleEvents: sampleEvents,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ordersRepositoryProvider.overrideWithValue(mockRepo),
            farmerOrdersStreamProvider(null)
                .overrideWith((ref) => Stream.value([sampleOrder])),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(360, 740),
                textScaler: TextScaler.linear(1.6),
              ),
              child: FarmerOrderBoardScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Farmer Order Board'), findsOneWidget);
      expect(find.text('Incoming'), findsOneWidget);
      expect(find.text('Packing'), findsOneWidget);
      expect(find.text('Dispatch'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CustomerOrdersScreen renders with list and filter chips',
        (tester) async {
      final mockRepo = MockP66OrdersRepository(
        sampleOrder: sampleOrder,
        sampleEvents: sampleEvents,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ordersRepositoryProvider.overrideWithValue(mockRepo),
            customerOrdersStreamProvider
                .overrideWith((ref) => Stream.value([sampleOrder])),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CustomerOrdersScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ORD-261009-8472'), findsOneWidget);
      expect(find.text('Cauvery Bio Farm'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
