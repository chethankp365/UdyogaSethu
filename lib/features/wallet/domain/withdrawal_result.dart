/// Result of a wallet payout withdrawal request.
class WithdrawalResult {
  final String payoutId;
  final String ledgerId;
  final int amountPaise;
  final String payoutRef;
  final String status;
  final bool isDemo;

  const WithdrawalResult({
    required this.payoutId,
    required this.ledgerId,
    required this.amountPaise,
    required this.payoutRef,
    required this.status,
    this.isDemo = true,
  });

  factory WithdrawalResult.fromJson(Map<String, dynamic> json) {
    return WithdrawalResult(
      payoutId: (json['payout_id'] as String?) ?? '',
      ledgerId: (json['ledger_id'] as String?) ?? '',
      amountPaise: (json['amount_paise'] as num?)?.toInt() ?? 0,
      payoutRef: (json['payout_ref'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'completed',
      isDemo: (json['is_demo'] as bool?) ?? true,
    );
  }

  double get amountRupees => amountPaise / 100.0;
}
