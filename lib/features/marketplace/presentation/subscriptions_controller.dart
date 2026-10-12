import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/features/marketplace/data/subscriptions_repository.dart';
import 'package:udyogasethu/features/marketplace/domain/group_order_model.dart';
import 'package:udyogasethu/features/marketplace/domain/subscription_model.dart';

final userSubscriptionsProvider =
    FutureProvider.autoDispose<List<ProduceSubscription>>((ref) async {
  final repo = ref.watch(subscriptionsRepositoryProvider);
  return repo.getSubscriptions();
});

final communityGroupOrdersProvider =
    FutureProvider.autoDispose<List<GroupOrder>>((ref) async {
  final repo = ref.watch(subscriptionsRepositoryProvider);
  return repo.getCommunityGroupOrders();
});

final subscriptionsControllerProvider =
    AsyncNotifierProvider<SubscriptionsController, void>(
  SubscriptionsController.new,
);

class SubscriptionsController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  SubscriptionsRepository get _repo =>
      ref.read(subscriptionsRepositoryProvider);

  Future<void> createSubscription({
    required String listingId,
    required double quantity,
    required SubscriptionFrequency frequency,
    String? deliverySlotTime,
    String? doorstepAddress,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.createSubscription(
        listingId: listingId,
        quantity: quantity,
        frequency: frequency,
        deliverySlotTime: deliverySlotTime,
        doorstepAddress: doorstepAddress,
      );
      ref.invalidate(userSubscriptionsProvider);
    });
  }

  Future<void> togglePause(ProduceSubscription sub) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final newStatus = sub.status == SubscriptionStatus.active
          ? SubscriptionStatus.paused
          : SubscriptionStatus.active;
      await _repo.updateSubscriptionStatus(sub.id, newStatus);
      ref.invalidate(userSubscriptionsProvider);
    });
  }

  Future<void> skipDeliveryDate(ProduceSubscription sub, DateTime date) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.skipDeliveryDate(sub.id, date);
      ref.invalidate(userSubscriptionsProvider);
    });
  }

  Future<void> updateQuantity(ProduceSubscription sub, double quantity) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.updateQuantity(sub.id, quantity);
      ref.invalidate(userSubscriptionsProvider);
    });
  }

  Future<void> joinGroupOrder(String groupOrderId, double quantity) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.joinGroupOrder(groupOrderId, quantity);
      ref.invalidate(communityGroupOrdersProvider);
    });
  }

  Future<String> createGroupOrder({
    required String listingId,
    required String communityName,
    required double targetQty,
    required List<GroupPriceTier> priceTiers,
    required DateTime deadline,
    required double organizerQty,
  }) async {
    state = const AsyncLoading();
    try {
      final id = await _repo.createGroupOrder(
        listingId: listingId,
        communityName: communityName,
        targetQty: targetQty,
        priceTiers: priceTiers,
        deadline: deadline,
        organizerQty: organizerQty,
      );
      ref.invalidate(communityGroupOrdersProvider);
      state = const AsyncData(null);
      return id;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> runSchedulerNow([DateTime? targetDate]) async {
    state = const AsyncLoading();
    try {
      final res = await _repo.runSchedulerNow(targetDate);
      ref.invalidate(userSubscriptionsProvider);
      state = const AsyncData(null);
      return res;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
