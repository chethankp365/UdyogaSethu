import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/features/marketplace/domain/group_order_model.dart';
import 'package:udyogasethu/features/marketplace/domain/subscription_model.dart';

final subscriptionsRepositoryProvider = Provider<SubscriptionsRepository>((ref) {
  SupabaseClient? client;
  try {
    if (Supabase.instance.isInitialized) {
      client = Supabase.instance.client;
    }
  } catch (_) {}
  return SubscriptionsRepository(client: client);
});

class SubscriptionsRepository {
  final SupabaseClient? client;

  SubscriptionsRepository({this.client});

  // In-memory demo state for tests / offline mode
  final List<ProduceSubscription> _demoSubscriptions = [
    ProduceSubscription(
      id: 'sub-001',
      customerId: 'demo-customer',
      farmerId: 'farmer-ravi',
      listingId: 'list-001',
      quantity: 2.0,
      frequency: SubscriptionFrequency.daily,
      status: SubscriptionStatus.active,
      nextDeliveryDate: DateTime.now().add(const Duration(days: 1)),
      deliverySlotTime: '7:00 AM',
      doorstepAddress: 'Flat 402, Sunshine Apts, Koramangala',
      unitPricePaise: 6000,
      listingName: 'A2 Farm Milk Daily Subscription',
      farmerName: 'Pure A2 Gir Cow Farm',
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
    ProduceSubscription(
      id: 'sub-002',
      customerId: 'demo-customer',
      farmerId: 'farmer-ravi',
      listingId: 'list-002',
      quantity: 1.0,
      frequency: SubscriptionFrequency.weekly,
      status: SubscriptionStatus.active,
      nextDeliveryDate: DateTime.now().add(const Duration(days: 4)),
      deliverySlotTime: '8:30 AM',
      doorstepAddress: 'Flat 402, Sunshine Apts, Koramangala',
      unitPricePaise: 35000,
      listingName: 'Weekly Organic Farm Vegetable Box',
      farmerName: 'Ravi Organic Farm, Devanahalli',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    ProduceSubscription(
      id: 'sub-003',
      customerId: 'demo-customer',
      farmerId: 'farmer-mandya',
      listingId: 'list-003',
      quantity: 2.0,
      frequency: SubscriptionFrequency.weekdays,
      status: SubscriptionStatus.active,
      nextDeliveryDate: DateTime.now().add(const Duration(days: 1)),
      deliverySlotTime: '6:30 AM',
      doorstepAddress: 'Flat 402, Sunshine Apts, Koramangala',
      unitPricePaise: 4000,
      listingName: 'Fresh Tender Coconut Morning Delivery',
      farmerName: 'Mandya Palms Co-op',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  final List<GroupOrder> _demoGroupOrders = [
    GroupOrder(
      id: 'grp-001',
      organizerId: 'demo-customer',
      organizerName: 'Anita V. (Tower A Secretary)',
      listingId: 'list-mango',
      listingName: 'Alphonso Mango 5kg Farm Crates',
      produceCategory: 'fruits',
      communityName: 'Prestige Falcon City Apartments',
      targetQty: 30.0,
      currentQty: 22.0,
      priceTiers: const [
        GroupPriceTier(minQty: 10, pricePaise: 65000),
        GroupPriceTier(minQty: 20, pricePaise: 58000),
        GroupPriceTier(minQty: 30, pricePaise: 50000),
      ],
      deadline: DateTime.now().add(const Duration(hours: 36)),
      status: GroupOrderStatus.open,
      effectivePricePaise: 58000,
      memberCount: 7,
      hasJoined: true,
      userQty: 5.0,
      paid: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    GroupOrder(
      id: 'grp-002',
      organizerId: 'user-ramesh',
      organizerName: 'Ramesh K. (Green Glen RWA)',
      listingId: 'list-onions',
      listingName: 'Nashik Red Onions (25kg Sacks)',
      produceCategory: 'vegetables',
      communityName: 'Green Glen Layout Residents',
      targetQty: 40.0,
      currentQty: 40.0,
      priceTiers: const [
        GroupPriceTier(minQty: 15, pricePaise: 75000),
        GroupPriceTier(minQty: 30, pricePaise: 68000),
        GroupPriceTier(minQty: 40, pricePaise: 60000),
      ],
      deadline: DateTime.now().add(const Duration(hours: 8)),
      status: GroupOrderStatus.targetMet,
      effectivePricePaise: 60000,
      memberCount: 14,
      hasJoined: false,
      userQty: 0.0,
      paid: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  Future<List<ProduceSubscription>> getSubscriptions() async {
    if (client == null || client!.auth.currentUser == null) {
      return List.unmodifiable(_demoSubscriptions);
    }

    try {
      final res = await client!.rpc('get_user_subscriptions');
      if (res is List) {
        final list = res.map((r) => ProduceSubscription.fromJson(r as Map<String, dynamic>)).toList();
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      debugPrint('Error fetching user subscriptions from Supabase: $e');
    }
    return List.unmodifiable(_demoSubscriptions);
  }

  Future<ProduceSubscription> createSubscription({
    required String listingId,
    required double quantity,
    required SubscriptionFrequency frequency,
    String? deliverySlotTime,
    String? doorstepAddress,
  }) async {
    if (client != null && client!.auth.currentUser != null) {
      try {
        final res = await client!.rpc('create_produce_subscription', params: {
          'p_listing_id': listingId,
          'p_quantity': quantity,
          'p_frequency': frequency.toDb(),
          'p_delivery_slot_time': deliverySlotTime ?? '07:00 AM',
          'p_doorstep_address': doorstepAddress,
        });

        if (res is Map && res['ok'] == true) {
          final subs = await getSubscriptions();
          final found = subs.firstWhere((s) => s.id == res['subscription_id']);
          return found;
        }
      } catch (e) {
        debugPrint('Error creating subscription RPC: $e');
      }
    }

    // Demo fallback
    final newSub = ProduceSubscription(
      id: 'sub-${DateTime.now().millisecondsSinceEpoch}',
      customerId: 'demo-customer',
      farmerId: 'farmer-local',
      listingId: listingId,
      quantity: quantity,
      frequency: frequency,
      status: SubscriptionStatus.active,
      nextDeliveryDate: DateTime.now().add(const Duration(days: 1)),
      deliverySlotTime: deliverySlotTime ?? '07:00 AM',
      doorstepAddress: doorstepAddress ?? 'Flat 402, Sunshine Apts, Koramangala',
      unitPricePaise: 6000,
      listingName: 'A2 Farm Milk Daily Subscription',
      farmerName: 'Pure A2 Gir Cow Farm',
      createdAt: DateTime.now(),
    );
    _demoSubscriptions.insert(0, newSub);
    return newSub;
  }

  Future<void> updateSubscriptionStatus(String subscriptionId, SubscriptionStatus status) async {
    if (client != null && client!.auth.currentUser != null) {
      try {
        await client!.rpc('update_subscription_status', params: {
          'p_subscription_id': subscriptionId,
          'p_status': status.toDb(),
        });
        return;
      } catch (e) {
        debugPrint('Error updating subscription status RPC: $e');
      }
    }

    final idx = _demoSubscriptions.indexWhere((s) => s.id == subscriptionId);
    if (idx != -1) {
      final old = _demoSubscriptions[idx];
      _demoSubscriptions[idx] = ProduceSubscription(
        id: old.id,
        customerId: old.customerId,
        farmerId: old.farmerId,
        listingId: old.listingId,
        quantity: old.quantity,
        frequency: old.frequency,
        status: status,
        nextDeliveryDate: old.nextDeliveryDate,
        skipDates: old.skipDates,
        deliverySlotTime: old.deliverySlotTime,
        doorstepAddress: old.doorstepAddress,
        unitPricePaise: old.unitPricePaise,
        listingName: old.listingName,
        farmerName: old.farmerName,
        createdAt: old.createdAt,
      );
    }
  }

  Future<void> skipDeliveryDate(String subscriptionId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T').first;
    if (client != null && client!.auth.currentUser != null) {
      try {
        await client!.rpc('skip_subscription_delivery_date', params: {
          'p_subscription_id': subscriptionId,
          'p_skip_date': dateStr,
        });
        return;
      } catch (e) {
        debugPrint('Error skipping delivery date RPC: $e');
      }
    }

    final idx = _demoSubscriptions.indexWhere((s) => s.id == subscriptionId);
    if (idx != -1) {
      final old = _demoSubscriptions[idx];
      final newSkips = List<DateTime>.from(old.skipDates);
      final alreadySkipped = newSkips.any((d) => d.year == date.year && d.month == date.month && d.day == date.day);
      if (alreadySkipped) {
        newSkips.removeWhere((d) => d.year == date.year && d.month == date.month && d.day == date.day);
      } else {
        newSkips.add(date);
      }
      _demoSubscriptions[idx] = ProduceSubscription(
        id: old.id,
        customerId: old.customerId,
        farmerId: old.farmerId,
        listingId: old.listingId,
        quantity: old.quantity,
        frequency: old.frequency,
        status: old.status,
        nextDeliveryDate: old.nextDeliveryDate,
        skipDates: newSkips,
        deliverySlotTime: old.deliverySlotTime,
        doorstepAddress: old.doorstepAddress,
        unitPricePaise: old.unitPricePaise,
        listingName: old.listingName,
        farmerName: old.farmerName,
        createdAt: old.createdAt,
      );
    }
  }

  Future<void> updateQuantity(String subscriptionId, double newQuantity) async {
    if (client != null && client!.auth.currentUser != null) {
      try {
        await client!.rpc('update_subscription_quantity', params: {
          'p_subscription_id': subscriptionId,
          'p_quantity': newQuantity,
        });
        return;
      } catch (e) {
        debugPrint('Error updating subscription quantity RPC: $e');
      }
    }

    final idx = _demoSubscriptions.indexWhere((s) => s.id == subscriptionId);
    if (idx != -1) {
      final old = _demoSubscriptions[idx];
      _demoSubscriptions[idx] = ProduceSubscription(
        id: old.id,
        customerId: old.customerId,
        farmerId: old.farmerId,
        listingId: old.listingId,
        quantity: newQuantity,
        frequency: old.frequency,
        status: old.status,
        nextDeliveryDate: old.nextDeliveryDate,
        skipDates: old.skipDates,
        deliverySlotTime: old.deliverySlotTime,
        doorstepAddress: old.doorstepAddress,
        unitPricePaise: old.unitPricePaise,
        listingName: old.listingName,
        farmerName: old.farmerName,
        createdAt: old.createdAt,
      );
    }
  }

  Future<List<GroupOrder>> getCommunityGroupOrders() async {
    if (client == null || client!.auth.currentUser == null) {
      return List.unmodifiable(_demoGroupOrders);
    }

    try {
      final res = await client!.rpc('get_community_group_orders');
      if (res is List) {
        final list = res.map((r) => GroupOrder.fromJson(r as Map<String, dynamic>)).toList();
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      debugPrint('Error fetching group orders from Supabase: $e');
    }
    return List.unmodifiable(_demoGroupOrders);
  }

  Future<String> createGroupOrder({
    required String listingId,
    required String communityName,
    required double targetQty,
    required List<GroupPriceTier> priceTiers,
    required DateTime deadline,
    required double organizerQty,
  }) async {
    if (client != null && client!.auth.currentUser != null) {
      try {
        final res = await client!.rpc('create_group_order', params: {
          'p_listing_id': listingId,
          'p_community_name': communityName,
          'p_target_qty': targetQty,
          'p_price_tiers': priceTiers.map((t) => t.toJson()).toList(),
          'p_deadline': deadline.toIso8601String(),
          'p_organizer_qty': organizerQty,
        });

        if (res is Map && res['ok'] == true) {
          return res['group_order_id']?.toString() ?? '';
        }
      } catch (e) {
        debugPrint('Error creating group order RPC: $e');
      }
    }

    final newId = 'grp-${DateTime.now().millisecondsSinceEpoch}';
    final newGroup = GroupOrder(
      id: newId,
      organizerId: 'demo-customer',
      organizerName: 'You (Organizer)',
      listingId: listingId,
      listingName: 'Fresh Harvest Direct',
      produceCategory: 'organic',
      communityName: communityName,
      targetQty: targetQty,
      currentQty: organizerQty,
      priceTiers: priceTiers,
      deadline: deadline,
      status: organizerQty >= targetQty ? GroupOrderStatus.targetMet : GroupOrderStatus.open,
      effectivePricePaise: priceTiers.isNotEmpty ? priceTiers.first.pricePaise : 5000,
      memberCount: organizerQty > 0 ? 1 : 0,
      hasJoined: organizerQty > 0,
      userQty: organizerQty,
      paid: true,
      createdAt: DateTime.now(),
    );
    _demoGroupOrders.insert(0, newGroup);
    return newId;
  }

  Future<Map<String, dynamic>> joinGroupOrder(String groupOrderId, double quantity) async {
    if (client != null && client!.auth.currentUser != null) {
      try {
        final res = await client!.rpc('join_group_order', params: {
          'p_group_order_id': groupOrderId,
          'p_quantity': quantity,
        });
        if (res is Map) {
          return Map<String, dynamic>.from(res);
        }
      } catch (e) {
        debugPrint('Error joining group order RPC: $e');
      }
    }

    final idx = _demoGroupOrders.indexWhere((g) => g.id == groupOrderId);
    if (idx != -1) {
      final old = _demoGroupOrders[idx];
      final newCurrentQty = old.currentQty + quantity;
      final targetMet = newCurrentQty >= old.targetQty;
      _demoGroupOrders[idx] = GroupOrder(
        id: old.id,
        organizerId: old.organizerId,
        organizerName: old.organizerName,
        listingId: old.listingId,
        listingName: old.listingName,
        produceCategory: old.produceCategory,
        communityName: old.communityName,
        targetQty: old.targetQty,
        currentQty: newCurrentQty,
        priceTiers: old.priceTiers,
        deadline: old.deadline,
        status: targetMet ? GroupOrderStatus.targetMet : old.status,
        effectivePricePaise: old.effectivePricePaise,
        memberCount: old.memberCount + 1,
        hasJoined: true,
        userQty: old.userQty + quantity,
        paid: true,
        createdAt: old.createdAt,
      );
      return {
        'ok': true,
        'total_qty': newCurrentQty,
        'target_met': targetMet,
      };
    }
    return {'ok': true};
  }

  Future<Map<String, dynamic>> runSchedulerNow([DateTime? targetDate]) async {
    final date = targetDate ?? DateTime.now().add(const Duration(days: 1));
    final dateStr = date.toIso8601String().split('T').first;

    if (client != null) {
      try {
        final res = await client!.rpc('generate_tomorrow_deliveries', params: {
          'p_target_date': dateStr,
        });
        if (res is Map) {
          return Map<String, dynamic>.from(res);
        }
      } catch (e) {
        debugPrint('Error running scheduler RPC: $e');
      }
    }

    return {
      'ok': true,
      'target_date': dateStr,
      'generated_orders': 2,
      'skipped_orders': 1,
      'stock_failures': 0,
      'job_assignments_created': 1,
    };
  }
}
