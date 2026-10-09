import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/features/payments/domain/payment_bill_summary.dart';
import 'package:udyogasethu/features/payments/domain/payment_models.dart';

abstract class PaymentRepository {
  Future<PaymentBillSummary> computeBill({
    required String refType,
    required String refId,
    bool? protectionOverride,
  });

  Future<PaymentOrderResult> createOrder({
    required String refType,
    required String refId,
    required PaymentMethod method,
    bool? protectionOverride,
  });

  Future<PaymentRecord> getPayment(String paymentId);

  Stream<PaymentRecord?> streamPayment(String paymentId);

  Future<int> getAvailableWalletBalancePaise();

  Future<bool> releaseAssignmentEscrow(String assignmentId);

  Future<bool> confirmJobCompletionAndRelease(String assignmentId);

  Future<bool> refundEscrow(String paymentId, {int? refundPaise, String? reason});

  Future<bool> refundAssignmentEscrow(String assignmentId, {int? refundPaise, String? reason});

  Future<bool> releaseOrderEscrow(String orderId);
}

class SupabasePaymentRepository implements PaymentRepository {
  final SupabaseClient _client;

  SupabasePaymentRepository(this._client);

  @override
  Future<PaymentBillSummary> computeBill({
    required String refType,
    required String refId,
    bool? protectionOverride,
  }) async {
    final response = await _client.rpc(
      'compute_payment_bill',
      params: {
        'p_ref_type': refType,
        'p_ref_id': refId,
        'p_protection_override': protectionOverride,
      },
    );

    if (response is List && response.isNotEmpty) {
      return PaymentBillSummary.fromJson(
        Map<String, dynamic>.from(response.first as Map),
      );
    }
    throw Exception('Failed to compute bill breakdown for $refType:$refId');
  }

  @override
  Future<PaymentOrderResult> createOrder({
    required String refType,
    required String refId,
    required PaymentMethod method,
    bool? protectionOverride,
  }) async {
    final response = await _client.functions.invoke(
      'payment-create-order',
      body: {
        'ref_type': refType,
        'ref_id': refId,
        'method': method.toDbString(),
        'protection_override': ?protectionOverride,
      },
    );

    if (response.status != 200) {
      final errorMap = response.data is Map ? response.data['error'] : null;
      final msg = errorMap != null ? errorMap['message'] : 'Failed to create payment order';
      throw Exception(msg);
    }

    final data = response.data['data'] as Map<String, dynamic>;
    return PaymentOrderResult.fromJson(data);
  }

  @override
  Future<PaymentRecord> getPayment(String paymentId) async {
    final res = await _client
        .from('payments')
        .select()
        .eq('id', paymentId)
        .single();
    return PaymentRecord.fromJson(res);
  }

  @override
  Stream<PaymentRecord?> streamPayment(String paymentId) {
    return _client
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('id', paymentId)
        .map((rows) {
          if (rows.isEmpty) return null;
          return PaymentRecord.fromJson(rows.first);
        });
  }

  @override
  Future<int> getAvailableWalletBalancePaise() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return 0;
    final res = await _client
        .from('wallet_balances')
        .select('available_paise')
        .eq('user_id', uid)
        .maybeSingle();
    if (res == null) return 0;
    return (res['available_paise'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<bool> releaseAssignmentEscrow(String assignmentId) async {
    final res = await _client.rpc('release_assignment_escrow', params: {
      'p_assignment_id': assignmentId,
    });
    return res as bool? ?? false;
  }

  @override
  Future<bool> confirmJobCompletionAndRelease(String assignmentId) async {
    final res = await _client.rpc('confirm_job_completion_and_release', params: {
      'p_assignment_id': assignmentId,
    });
    if (res is Map && res['success'] == true) {
      return true;
    }
    return false;
  }

  @override
  Future<bool> refundEscrow(String paymentId, {int? refundPaise, String? reason}) async {
    final res = await _client.rpc('refund_escrow', params: {
      'p_payment_id': paymentId,
      'p_refund_paise': refundPaise,
      'p_reason': reason ?? 'Refund requested',
    });
    return res as bool? ?? false;
  }

  @override
  Future<bool> refundAssignmentEscrow(String assignmentId, {int? refundPaise, String? reason}) async {
    final res = await _client.rpc('refund_assignment_escrow', params: {
      'p_assignment_id': assignmentId,
      'p_refund_paise': refundPaise,
      'p_reason': reason ?? 'Assignment cancelled/no-show',
    });
    return res as bool? ?? false;
  }

  @override
  Future<bool> releaseOrderEscrow(String orderId) async {
    final res = await _client.rpc('release_order_escrow', params: {
      'p_order_id': orderId,
    });
    return res as bool? ?? false;
  }
}

// Providers
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return SupabasePaymentRepository(Supabase.instance.client);
});

final paymentBillProvider = FutureProvider.family<PaymentBillSummary, ({String refType, String refId, bool? protection})>(
  (ref, args) async {
    final repo = ref.watch(paymentRepositoryProvider);
    return repo.computeBill(
      refType: args.refType,
      refId: args.refId,
      protectionOverride: args.protection,
    );
  },
);

final paymentStreamProvider = StreamProvider.family<PaymentRecord?, String>((ref, paymentId) {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.streamPayment(paymentId);
});

final paymentDetailProvider = FutureProvider.family<PaymentRecord, String>((ref, paymentId) {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.getPayment(paymentId);
});

final availableWalletBalanceProvider = FutureProvider<int>((ref) {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.getAvailableWalletBalancePaise();
});
