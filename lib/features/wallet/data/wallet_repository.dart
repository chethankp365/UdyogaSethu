import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/features/wallet/data/demo_wallet_transactions.dart';
import 'package:udyogasethu/features/wallet/domain/wallet_balance.dart';
import 'package:udyogasethu/features/wallet/domain/wallet_transaction.dart';
import 'package:udyogasethu/features/wallet/domain/withdrawal_result.dart';

class TransactionFilterCriteria {
  final String type; // 'all', 'wages', 'transfers', 'escrow', 'farm_sales', 'rewards', 'refunds'
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;

  const TransactionFilterCriteria({
    this.type = 'all',
    this.startDate,
    this.endDate,
    this.limit = 50,
    this.offset = 0,
  });

  TransactionFilterCriteria copyWith({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) {
    return TransactionFilterCriteria(
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionFilterCriteria &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode =>
      type.hashCode ^ startDate.hashCode ^ endDate.hashCode ^ limit.hashCode ^ offset.hashCode;
}

abstract class WalletRepository {
  Future<WalletBalance> getWalletSummary();
  Stream<WalletBalance> watchWalletSummary();
  Future<List<WalletTransaction>> getTransactions(TransactionFilterCriteria criteria);
  Future<WithdrawalResult> requestWithdrawal({
    required int amountPaise,
    String method = 'upi',
    String? payoutRef,
    String? idempotencyKey,
  });
  Future<Map<String, dynamic>> topupWallet({
    required int amountPaise,
    String? paymentRef,
  });
  Future<Map<String, dynamic>> payVpaFromWallet({
    required String payeeVpa,
    required String payeeName,
    required int amountPaise,
    String? note,
  });
}

class SupabaseWalletRepository implements WalletRepository {
  final SupabaseClient _client;

  SupabaseWalletRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  @override
  Future<WalletBalance> getWalletSummary() async {
    try {
      final res = await _client.rpc('get_wallet_summary');
      if (res is Map<String, dynamic>) {
        return WalletBalance.fromJson(res);
      }
      return WalletBalance.zero();
    } catch (_) {
      return WalletBalance.zero();
    }
  }

  @override
  Stream<WalletBalance> watchWalletSummary() {
    final controller = StreamController<WalletBalance>();

    // Initial fetch
    getWalletSummary().then((val) {
      if (!controller.isClosed) controller.add(val);
    }).catchError((_) {
      if (!controller.isClosed) controller.add(WalletBalance.zero());
    });

    // Realtime subscription on ledger_entries to push live balance changes
    final user = _client.auth.currentUser;
    RealtimeChannel? channel;

    if (user != null) {
      channel = _client
          .channel('wallet_summary_updates_${user.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'ledger_entries',
            callback: (_) async {
              try {
                final updated = await getWalletSummary();
                if (!controller.isClosed) controller.add(updated);
              } catch (_) {}
            },
          )
          .subscribe();
    }

    controller.onCancel = () {
      if (channel != null) {
        _client.removeChannel(channel);
      }
    };

    return controller.stream;
  }

  @override
  Future<List<WalletTransaction>> getTransactions(TransactionFilterCriteria criteria) async {
    try {
      // Map client criteria to RPC parameters for seamless compatibility
      String rpcType = criteria.type;
      if (rpcType == 'farm_produce') rpcType = 'farm_sales';
      if (rpcType == 'withdrawals') rpcType = 'transfers';

      final res = await _client.rpc('get_wallet_transactions', params: {
        'p_type': rpcType,
        'p_start_date': criteria.startDate?.toIso8601String(),
        'p_end_date': criteria.endDate?.toIso8601String(),
        'p_limit': criteria.limit,
        'p_offset': criteria.offset,
      });

      if (res is List) {
        return res
            .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<WithdrawalResult> requestWithdrawal({
    required int amountPaise,
    String method = 'upi',
    String? payoutRef,
    String? idempotencyKey,
  }) async {
    try {
      final res = await _client.rpc('request_wallet_withdrawal', params: {
        'p_amount_paise': amountPaise,
        'p_method': method,
        'p_payout_ref': payoutRef,
        'p_idempotency_key': idempotencyKey,
      });
      if (res is Map<String, dynamic>) {
        return WithdrawalResult.fromJson(res);
      }
      return WithdrawalResult(
        payoutId: 'WD-${DateTime.now().millisecondsSinceEpoch}',
        ledgerId: 'LEDGER-${DateTime.now().millisecondsSinceEpoch}',
        amountPaise: amountPaise,
        payoutRef: payoutRef ?? 'UPI-PAYOUT',
        status: 'completed',
        isDemo: false,
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> topupWallet({
    required int amountPaise,
    String? paymentRef,
  }) async {
    try {
      final res = await _client.rpc('topup_wallet', params: {
        'p_amount_paise': amountPaise,
        'p_payment_ref': paymentRef,
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
  Future<Map<String, dynamic>> payVpaFromWallet({
    required String payeeVpa,
    required String payeeName,
    required int amountPaise,
    String? note,
  }) async {
    try {
      final res = await _client.rpc('pay_vpa_from_wallet', params: {
        'p_payee_vpa': payeeVpa,
        'p_payee_name': payeeName,
        'p_amount_paise': amountPaise,
        'p_note': note,
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
}

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return SupabaseWalletRepository();
});

final walletSummaryStreamProvider = StreamProvider<WalletBalance>((ref) {
  final isDemo = ref.watch(walletDemoModeProvider);
  if (isDemo) {
    return Stream.value(DemoWalletData.sampleDemoBalance);
  }
  final repo = ref.watch(walletRepositoryProvider);
  return repo.watchWalletSummary();
});

final walletSummaryProvider = FutureProvider<WalletBalance>((ref) {
  final isDemo = ref.watch(walletDemoModeProvider);
  if (isDemo) {
    return DemoWalletData.sampleDemoBalance;
  }
  final repo = ref.watch(walletRepositoryProvider);
  return repo.getWalletSummary();
});

final walletTransactionsProvider =
    FutureProvider.family<List<WalletTransaction>, TransactionFilterCriteria>((ref, criteria) {
  final isDemo = ref.watch(walletDemoModeProvider);
  if (isDemo) {
    final all = DemoWalletData.getSampleTransactions();
    return DemoWalletData.filterTransactions(all, criteria);
  }
  final repo = ref.watch(walletRepositoryProvider);
  return repo.getTransactions(criteria);
});
