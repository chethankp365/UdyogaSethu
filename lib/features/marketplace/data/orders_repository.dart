import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import '../domain/cart_item.dart';
import '../domain/delivery_slot.dart';
import '../domain/order_timeline_event.dart';
import '../domain/produce_marketplace_item.dart';
import '../domain/produce_order.dart';

abstract class OrdersRepository {
  Future<List<DeliverySlot>> getFarmerDeliverySlots(String farmerId);
  Future<String> createDeliverySlot({
    required DateTime date,
    required String windowStart,
    required String windowEnd,
    required int capacity,
  });
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
  });
  Future<ProduceOrder?> getOrderDetails(String orderId);
  Stream<ProduceOrder?> watchOrder(String orderId);
  Stream<List<OrderTimelineEvent>> watchOrderEvents(String orderId);
  Future<List<ProduceOrder>> getFarmerOrders({String? status});
  Stream<List<ProduceOrder>> watchFarmerOrders({String? status});
  Future<List<ProduceOrder>> getCustomerOrders();
  Stream<List<ProduceOrder>> watchCustomerOrders();
  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
    String? pin,
    String? notes,
  });
  Future<void> submitOrderReview({
    required String orderId,
    required String targetId,
    required int stars,
    required List<String> tags,
    String? comment,
  });
  Future<void> createOrderDispute({
    required String orderId,
    required String againstId,
    required String issueType,
    required String details,
  });
}

class SupabaseOrdersRepository implements OrdersRepository {
  final SupabaseClient _client;

  SupabaseOrdersRepository(this._client);

  @override
  Future<List<DeliverySlot>> getFarmerDeliverySlots(String farmerId) async {
    try {
      final todayStr = DateTime.now().toIso8601String().split('T').first;
      final response = await _client
          .from('delivery_slots')
          .select()
          .eq('farmer_id', farmerId)
          .gte('slot_date', todayStr)
          .order('slot_date', ascending: true)
          .order('window_start', ascending: true);

      final list = (response as List<dynamic>)
          .map((row) => DeliverySlot.fromJson(row as Map<String, dynamic>))
          .toList();

      if (list.isNotEmpty) return list;
    } catch (_) {
      // Fallback to sample slots below
    }

    final now = DateTime.now();
    return [
      DeliverySlot(
        id: 'slot-sample-1',
        farmerId: farmerId,
        slotDate: now,
        windowStart: '07:00:00',
        windowEnd: '11:00:00',
        capacity: 10,
        used: 3,
      ),
      DeliverySlot(
        id: 'slot-sample-2',
        farmerId: farmerId,
        slotDate: now,
        windowStart: '16:00:00',
        windowEnd: '19:00:00',
        capacity: 10,
        used: 6,
      ),
    ];
  }

  @override
  Future<String> createDeliverySlot({
    required DateTime date,
    required String windowStart,
    required String windowEnd,
    required int capacity,
  }) async {
    final dateStr = date.toIso8601String().split('T').first;
    try {
      final res = await _client.rpc('create_delivery_slot', params: {
        'p_slot_date': dateStr,
        'p_window_start': windowStart,
        'p_window_end': windowEnd,
        'p_capacity': capacity,
      });
      return res as String;
    } catch (_) {
      final insertRes = await _client.from('delivery_slots').insert({
        'farmer_id': _client.auth.currentUser?.id ?? '44444444-4444-4444-8444-444444444401',
        'slot_date': dateStr,
        'window_start': windowStart,
        'window_end': windowEnd,
        'capacity': capacity,
        'used': 0,
      }).select('id').single();
      return insertRes['id'] as String;
    }
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
    try {
      final response = await _client.rpc('place_order', params: {
        'p_items': items,
        'p_fulfilment': fulfilment,
        'p_address_text': addressText,
        'p_slot_id': slotId,
        'p_slots': slots,
        'p_protected': isProtected,
        'p_apply_reward_credits': applyRewardCredits,
        'p_payment_method': paymentMethod,
        'p_delivery_notes': deliveryNotes,
      });

      final rows = (response as List<dynamic>)
          .map((r) => ProduceOrder.fromJson(r as Map<String, dynamic>))
          .toList();
      if (rows.isNotEmpty) return rows;
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('Out of stock') ||
          errorMsg.contains('Delivery slot is full') ||
          errorMsg.contains('not available')) {
        rethrow;
      }
      throw Exception(errorMsg.replaceAll('Exception: ', ''));
    }

    return [
      ProduceOrder(
        orderId: 'mock-order-${DateTime.now().millisecondsSinceEpoch}',
        orderCode: 'ORD-${DateTime.now().year % 100}1009-TEST01',
        farmerId: '44444444-4444-4444-8444-444444444401',
        farmerName: 'Cauvery Bio Farm',
        totalPaise: 3400,
        feePaise: isProtected ? 500 : 0,
        discountPaise: applyRewardCredits ? 170 : 0,
        status: 'pending',
        itemsCount: items.length,
        slotId: slotId,
        fulfilment: fulfilment,
        protected: isProtected,
        paymentMethod: paymentMethod,
        deliveryPin: '4819',
        createdAt: DateTime.now(),
      )
    ];
  }

  @override
  Future<ProduceOrder?> getOrderDetails(String orderId) async {
    try {
      final res = await _client.rpc('get_order_details', params: {
        'p_order_id': orderId,
      });
      if (res != null) {
        return ProduceOrder.fromJson(res as Map<String, dynamic>);
      }
    } catch (_) {
      // Fallback to table query
      try {
        final row = await _client.from('orders').select().eq('id', orderId).maybeSingle();
        if (row != null) {
          return ProduceOrder.fromJson(row);
        }
      } catch (_) {}
    }
    return null;
  }

  @override
  Stream<ProduceOrder?> watchOrder(String orderId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .asyncMap((rows) async {
          if (rows.isEmpty) {
            return await getOrderDetails(orderId);
          }
          // Fetch full enriched details with items and slot
          return await getOrderDetails(orderId);
        });
  }

  @override
  Stream<List<OrderTimelineEvent>> watchOrderEvents(String orderId) {
    return _client
        .from('order_events')
        .stream(primaryKey: ['id'])
        .eq('order_id', orderId)
        .order('created_at', ascending: true)
        .map((rows) {
          return rows.map((r) => OrderTimelineEvent.fromJson(r)).toList();
        });
  }

  @override
  Future<List<ProduceOrder>> getFarmerOrders({String? status}) async {
    try {
      final res = await _client.rpc('get_farmer_orders', params: {
        'p_status': status,
      });
      if (res is List) {
        return res
            .map((r) => ProduceOrder.fromJson(r as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      try {
        var query = _client.from('orders').select();
        if (status != null) {
          query = query.eq('status', status);
        }
        final rows = await query.order('created_at', ascending: false);
        return (rows as List)
            .map((r) => ProduceOrder.fromJson(r as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    return [];
  }

  @override
  Stream<List<ProduceOrder>> watchFarmerOrders({String? status}) {
    final farmerId = _client.auth.currentUser?.id;
    if (farmerId == null) {
      return Stream.value([]);
    }

    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('farmer_id', farmerId)
        .order('created_at', ascending: false)
        .asyncMap((_) async => await getFarmerOrders(status: status));
  }

  @override
  Future<List<ProduceOrder>> getCustomerOrders() async {
    try {
      final res = await _client.rpc('get_customer_orders');
      if (res is List) {
        return res
            .map((r) => ProduceOrder.fromJson(r as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      try {
        final rows = await _client
            .from('orders')
            .select()
            .order('created_at', ascending: false);
        return (rows as List)
            .map((r) => ProduceOrder.fromJson(r as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    return [];
  }

  @override
  Stream<List<ProduceOrder>> watchCustomerOrders() {
    final customerId = _client.auth.currentUser?.id;
    if (customerId == null) {
      return Stream.value([]);
    }

    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('customer_id', customerId)
        .order('created_at', ascending: false)
        .asyncMap((_) async => await getCustomerOrders());
  }

  @override
  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
    String? pin,
    String? notes,
  }) async {
    try {
      final res = await _client.rpc('update_order_status', params: {
        'p_order_id': orderId,
        'p_status': status,
        'p_pin': pin,
        'p_notes': notes,
      });
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      final err = e.toString().replaceAll('Exception: ', '');
      throw Exception(err);
    }
  }

  @override
  Future<void> submitOrderReview({
    required String orderId,
    required String targetId,
    required int stars,
    required List<String> tags,
    String? comment,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Authentication required');

    await _client.from('ratings_reviews').insert({
      'ref_type': 'order',
      'ref_id': orderId,
      'rater_id': uid,
      'target_id': targetId,
      'stars': stars,
      'tags': tags,
      'comment': comment,
      'hidden': false,
    });
  }

  @override
  Future<void> createOrderDispute({
    required String orderId,
    required String againstId,
    required String issueType,
    required String details,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Authentication required');

    // Update order status to disputed
    await updateOrderStatus(
      orderId: orderId,
      status: 'disputed',
      notes: 'Customer dispute: $details',
    );

    // Insert into disputes table
    await _client.from('disputes').insert({
      'ref_type': 'order',
      'ref_id': orderId,
      'raised_by': uid,
      'against': againstId,
      'issue_type': issueType == 'damaged' ? 'wrong_product' : 'poor_quality',
      'details': details,
      'status': 'open',
    });
  }
}

// -----------------------------------------------------------------------------
// Cart Notifier State Management
// -----------------------------------------------------------------------------

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  void addItem(ProduceMarketplaceItem item, {double quantity = 1.0}) {
    final current = state.items[item.id];
    final newQty = current != null
        ? (current.quantity + quantity).clamp(1.0, item.stockQty)
        : quantity.clamp(1.0, item.stockQty);

    final updated = Map<String, CartItem>.from(state.items);
    updated[item.id] = CartItem(produceItem: item, quantity: newQty);

    state = state.copyWith(items: updated);
  }

  void addOrderItems(List<ProduceOrderItem> orderItems, {String farmerId = ''}) {
    final updated = Map<String, CartItem>.from(state.items);
    for (final it in orderItems) {
      if (it.listingId == null) continue;
      final dummyItem = ProduceMarketplaceItem(
        id: it.listingId!,
        farmerId: farmerId,
        farmerName: 'Farmer',
        name: it.name,
        category: 'vegetable',
        pricePaise: it.unitPricePaise,
        unit: it.unit,
        stockQty: 50.0,
        lotNumber: 'LOT-REORDER',
        createdAt: DateTime.now(),
        harvestAt: DateTime.now(),
        farmingMethod: 'Natural',
        farmerRatingAvg: 4.8,
        farmerRatingCount: 12,
        isVerifiedFarmer: true,
      );
      updated[it.listingId!] = CartItem(produceItem: dummyItem, quantity: it.quantity);
    }
    state = state.copyWith(items: updated);
  }

  void updateQuantity(String listingId, double quantity) {
    if (!state.items.containsKey(listingId)) return;
    final item = state.items[listingId]!;
    if (quantity <= 0) {
      removeItem(listingId);
      return;
    }

    final newQty = quantity.clamp(1.0, item.maxStock);
    final updated = Map<String, CartItem>.from(state.items);
    updated[listingId] = item.copyWith(quantity: newQty);

    state = state.copyWith(items: updated);
  }

  void removeItem(String listingId) {
    final updated = Map<String, CartItem>.from(state.items);
    updated.remove(listingId);
    state = state.copyWith(items: updated);
  }

  void toggleRewardCredits() {
    state = state.copyWith(useRewardCredits: !state.useRewardCredits);
  }

  void selectSlot(String farmerId, String slotId) {
    final updatedSlots = Map<String, String>.from(state.selectedSlotIds);
    updatedSlots[farmerId] = slotId;
    state = state.copyWith(selectedSlotIds: updatedSlots);
  }

  void clear() {
    state = const CartState();
  }
}

// -----------------------------------------------------------------------------
// Riverpod Providers
// -----------------------------------------------------------------------------

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseOrdersRepository(client);
});

final cartNotifierProvider =
    NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

final farmerDeliverySlotsProvider =
    FutureProvider.family<List<DeliverySlot>, String>((ref, farmerId) async {
  final repo = ref.watch(ordersRepositoryProvider);
  return repo.getFarmerDeliverySlots(farmerId);
});

final orderDetailsStreamProvider =
    StreamProvider.family<ProduceOrder?, String>((ref, orderId) {
  final repo = ref.watch(ordersRepositoryProvider);
  return repo.watchOrder(orderId);
});

final orderEventsStreamProvider =
    StreamProvider.family<List<OrderTimelineEvent>, String>((ref, orderId) {
  final repo = ref.watch(ordersRepositoryProvider);
  return repo.watchOrderEvents(orderId);
});

final farmerOrdersProvider =
    FutureProvider.family<List<ProduceOrder>, String?>((ref, status) async {
  final repo = ref.watch(ordersRepositoryProvider);
  return repo.getFarmerOrders(status: status);
});

final farmerOrdersStreamProvider =
    StreamProvider.family<List<ProduceOrder>, String?>((ref, status) {
  final repo = ref.watch(ordersRepositoryProvider);
  return repo.watchFarmerOrders(status: status);
});

final customerOrdersProvider = FutureProvider<List<ProduceOrder>>((ref) async {
  final repo = ref.watch(ordersRepositoryProvider);
  return repo.getCustomerOrders();
});

final customerOrdersStreamProvider = StreamProvider<List<ProduceOrder>>((ref) {
  final repo = ref.watch(ordersRepositoryProvider);
  return repo.watchCustomerOrders();
});
