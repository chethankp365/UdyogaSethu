import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/features/rewards/domain/gamification_models.dart';

abstract class RewardsRepository {
  Future<UserGamificationProfile> getGamificationProfile([String? userId]);
  Future<List<RewardStoreItem>> getRewardItems();
  Future<List<RewardRedemption>> getRedemptions();
  Future<Map<String, dynamic>> redeemRewardItem({
    required String itemId,
    required Map<String, dynamic> shippingAddress,
  });
  Future<String> getOrGenerateReferralCode();
  Future<Map<String, dynamic>> applyReferralCode(String code);
  Stream<UserGamificationProfile> watchGamificationProfile();
}

class SupabaseRewardsRepository implements RewardsRepository {
  final SupabaseClient _client;

  SupabaseRewardsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String? get _currentUserId {
    try {
      return _client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserGamificationProfile> getGamificationProfile([String? userId]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      return UserGamificationProfile.initial();
    }

    try {
      final res = await _client.rpc('get_user_gamification_profile', params: {
        'p_user_id': uid,
      });

      if (res is Map<String, dynamic>) {
        return UserGamificationProfile.fromJson(res);
      }
      return UserGamificationProfile.initial();
    } on PostgrestException catch (_) {
      return UserGamificationProfile.initial();
    } catch (_) {
      return UserGamificationProfile.initial();
    }
  }

  @override
  Future<List<RewardStoreItem>> getRewardItems() async {
    try {
      final res = await _client
          .from('reward_items')
          .select()
          .eq('active', true)
          .order('min_level', ascending: true)
          .order('points_cost', ascending: true);

      return (res as List<dynamic>)
          .map((item) => RewardStoreItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<RewardRedemption>> getRedemptions() async {
    final uid = _currentUserId;
    if (uid == null) return [];

    try {
      final res = await _client
          .from('reward_redemptions')
          .select('*, reward_items(*)')
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      return (res as List<dynamic>)
          .map((item) => RewardRedemption.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> redeemRewardItem({
    required String itemId,
    required Map<String, dynamic> shippingAddress,
  }) async {
    try {
      final res = await _client.rpc('redeem_reward_item', params: {
        'p_item_id': itemId,
        'p_shipping_address': shippingAddress,
      });

      if (res is Map<String, dynamic>) {
        return res;
      }
      return {'success': true};
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<String> getOrGenerateReferralCode() async {
    final uid = _currentUserId;
    if (uid == null) return 'SETU1234';

    try {
      final res = await _client.rpc('get_or_create_referral_code', params: {
        'p_user_id': uid,
      });
      return res?.toString() ?? 'SETU1234';
    } catch (_) {
      return 'SETU1234';
    }
  }

  @override
  Future<Map<String, dynamic>> applyReferralCode(String code) async {
    try {
      final res = await _client.rpc('apply_referral_code', params: {
        'p_code': code.trim(),
      });

      if (res is Map<String, dynamic>) {
        return res;
      }
      return {'success': true};
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Stream<UserGamificationProfile> watchGamificationProfile() {
    final controller = StreamController<UserGamificationProfile>();
    RealtimeChannel? channel;

    Future<void> fetchAndEmit() async {
      final profile = await getGamificationProfile();
      if (!controller.isClosed) {
        controller.add(profile);
      }
    }

    fetchAndEmit();

    try {
      channel = _client.channel('gamification_profile_realtime');
      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'xp_events',
            callback: (_) => fetchAndEmit(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'user_badges',
            callback: (_) => fetchAndEmit(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'streaks',
            callback: (_) => fetchAndEmit(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'reward_redemptions',
            callback: (_) => fetchAndEmit(),
          )
          .subscribe();
    } catch (_) {}

    controller.onCancel = () {
      if (channel != null) {
        _client.removeChannel(channel);
      }
      controller.close();
    };

    return controller.stream;
  }
}

final rewardsRepositoryProvider = Provider<RewardsRepository>((ref) {
  return SupabaseRewardsRepository();
});

final gamificationProfileProvider =
    StreamProvider<UserGamificationProfile>((ref) {
  final repo = ref.watch(rewardsRepositoryProvider);
  return repo.watchGamificationProfile();
});

final rewardItemsProvider = FutureProvider<List<RewardStoreItem>>((ref) {
  final repo = ref.watch(rewardsRepositoryProvider);
  return repo.getRewardItems();
});

final rewardRedemptionsProvider = FutureProvider<List<RewardRedemption>>((ref) {
  final repo = ref.watch(rewardsRepositoryProvider);
  return repo.getRedemptions();
});
