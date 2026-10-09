import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/features/earnings/domain/earnings_models.dart';
import 'package:udyogasethu/features/earnings/domain/savings_goal_model.dart';

abstract class EarningsRepository {
  Future<EarningsDashboardData> getEarningsDashboard({int days = 14});
  Future<int> updateDailyEarningsGoal(int goalPaise);
  Future<List<SavingsGoal>> getSavingsGoals();
  Future<SavingsGoal> createSavingsGoal(SavingsGoalDraft draft);
  Future<SavingsGoal> allocateSavingsGoal({
    required String goalId,
    required int amountPaise,
  });
  Future<void> deleteSavingsGoal(String goalId);
}

class SupabaseEarningsRepository implements EarningsRepository {
  final SupabaseClient _client;

  SupabaseEarningsRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  @override
  Future<EarningsDashboardData> getEarningsDashboard({int days = 14}) async {
    try {
      final res = await _client.rpc(
        'get_earnings_dashboard',
        params: {'p_days': days},
      );

      if (res is Map<String, dynamic>) {
        return EarningsDashboardData.fromJson(res);
      }
      return EarningsDashboardData.empty();
    } catch (e) {
      // In offline / unauthenticated fallback, return empty with default goal
      return EarningsDashboardData.empty();
    }
  }

  @override
  Future<int> updateDailyEarningsGoal(int goalPaise) async {
    try {
      final res = await _client.rpc(
        'update_daily_earnings_goal',
        params: {'p_goal_paise': goalPaise},
      );
      if (res is num) {
        return res.toInt();
      }
      return goalPaise;
    } catch (e) {
      throw Exception('Failed to update daily goal: $e');
    }
  }

  @override
  Future<List<SavingsGoal>> getSavingsGoals() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final data = await _client
          .from('savings_goals')
          .select()
          .eq('user_id', user.id)
          .order('is_completed', ascending: true)
          .order('created_at', ascending: false);

      return (data as List<dynamic>)
          .map((item) => SavingsGoal.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<SavingsGoal> createSavingsGoal(SavingsGoalDraft draft) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User is not authenticated');
      }

      final insertData = draft.toInsertJson(user.id);
      final res = await _client
          .from('savings_goals')
          .insert(insertData)
          .select()
          .single();

      return SavingsGoal.fromJson(res);
    } catch (e) {
      throw Exception('Failed to create savings goal: $e');
    }
  }

  @override
  Future<SavingsGoal> allocateSavingsGoal({
    required String goalId,
    required int amountPaise,
  }) async {
    try {
      final res = await _client.rpc(
        'allocate_savings_goal',
        params: {
          'p_goal_id': goalId,
          'p_amount_paise': amountPaise,
        },
      );

      if (res is Map<String, dynamic>) {
        return SavingsGoal.fromJson(res);
      }
      throw Exception('Invalid response from allocate_savings_goal');
    } catch (e) {
      throw Exception('Failed to allocate to savings goal: $e');
    }
  }

  @override
  Future<void> deleteSavingsGoal(String goalId) async {
    try {
      await _client.from('savings_goals').delete().eq('id', goalId);
    } catch (e) {
      throw Exception('Failed to delete savings goal: $e');
    }
  }
}

final earningsRepositoryProvider = Provider<EarningsRepository>((ref) {
  return SupabaseEarningsRepository();
});

final earningsDashboardProvider =
    FutureProvider.family<EarningsDashboardData, int>((ref, days) async {
  final repo = ref.watch(earningsRepositoryProvider);
  return repo.getEarningsDashboard(days: days);
});

final savingsGoalsProvider =
    AsyncNotifierProvider<SavingsGoalsNotifier, List<SavingsGoal>>(
  SavingsGoalsNotifier.new,
);

class SavingsGoalsNotifier extends AsyncNotifier<List<SavingsGoal>> {
  @override
  Future<List<SavingsGoal>> build() async {
    final repo = ref.watch(earningsRepositoryProvider);
    return repo.getSavingsGoals();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(earningsRepositoryProvider);
      return repo.getSavingsGoals();
    });
  }

  Future<void> createGoal(SavingsGoalDraft draft) async {
    final repo = ref.read(earningsRepositoryProvider);
    await repo.createSavingsGoal(draft);
    await refresh();
  }

  Future<void> allocate({
    required String goalId,
    required int amountPaise,
  }) async {
    final repo = ref.read(earningsRepositoryProvider);
    await repo.allocateSavingsGoal(goalId: goalId, amountPaise: amountPaise);
    await refresh();
  }

  Future<void> deleteGoal(String goalId) async {
    final repo = ref.read(earningsRepositoryProvider);
    await repo.deleteSavingsGoal(goalId);
    await refresh();
  }
}
