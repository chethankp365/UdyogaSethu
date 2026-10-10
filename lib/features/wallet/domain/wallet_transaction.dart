import 'package:flutter/material.dart';
import 'package:udyogasethu/features/wallet/domain/wallet_balance.dart';

enum WalletTransactionType {
  dailyWage,
  upiTransfer,
  produceSale,
  autoPayout,
  platformFee,
  rewardCredit,
  refund,
  other;

  static WalletTransactionType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'daily_wage':
      case 'wage':
        return WalletTransactionType.dailyWage;
      case 'upi_transfer':
      case 'payout':
      case 'withdrawal':
        return WalletTransactionType.upiTransfer;
      case 'produce_sale':
      case 'farm_sale':
      case 'order':
        return WalletTransactionType.produceSale;
      case 'auto_payout':
        return WalletTransactionType.autoPayout;
      case 'platform_fee':
      case 'fee':
      case 'commission':
        return WalletTransactionType.platformFee;
      case 'reward_credit':
      case 'reward':
        return WalletTransactionType.rewardCredit;
      case 'refund':
        return WalletTransactionType.refund;
      default:
        return WalletTransactionType.other;
    }
  }

  String get key {
    switch (this) {
      case WalletTransactionType.dailyWage:
        return 'daily_wage';
      case WalletTransactionType.upiTransfer:
        return 'upi_transfer';
      case WalletTransactionType.produceSale:
        return 'produce_sale';
      case WalletTransactionType.autoPayout:
        return 'auto_payout';
      case WalletTransactionType.platformFee:
        return 'platform_fee';
      case WalletTransactionType.rewardCredit:
        return 'reward_credit';
      case WalletTransactionType.refund:
        return 'refund';
      case WalletTransactionType.other:
        return 'other';
    }
  }
}

class WalletTransaction {
  final String id;
  final String direction; // 'credit' or 'debit'
  final int amountPaise;
  final String bucket; // 'available', 'pending', 'escrow', 'reward'
  final String? refType;
  final String? refId;
  final String? note;
  final DateTime createdAt;
  final WalletTransactionType type;
  final int feePaise;
  final String? rpPaymentId;
  final String? rpOrderId;
  final String? utr;
  final String? counterpartyName;
  final String? counterpartyAccount;
  final String? linkedItemTitle;
  final String? rawStatus;

  const WalletTransaction({
    required this.id,
    required this.direction,
    required this.amountPaise,
    required this.bucket,
    this.refType,
    this.refId,
    this.note,
    required this.createdAt,
    required this.type,
    this.feePaise = 0,
    this.rpPaymentId,
    this.rpOrderId,
    this.utr,
    this.counterpartyName,
    this.counterpartyAccount,
    this.linkedItemTitle,
    this.rawStatus,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    final String dir = (json['direction'] as String?) ?? 'credit';
    final String rawType = (json['tx_type'] as String?) ?? (json['type'] as String?) ?? '';
    final String? rawDate = json['created_at'] as String?;
    final DateTime date = rawDate != null ? DateTime.tryParse(rawDate) ?? DateTime.now() : DateTime.now();

    return WalletTransaction(
      id: (json['id'] as String?) ?? '',
      direction: dir,
      amountPaise: (json['amount_paise'] as num?)?.toInt() ?? 0,
      bucket: (json['bucket'] as String?) ?? 'available',
      refType: json['ref_type'] as String?,
      refId: json['ref_id'] as String?,
      note: json['note'] as String?,
      createdAt: date,
      type: WalletTransactionType.fromString(rawType),
      feePaise: (json['fee_paise'] as num?)?.toInt() ?? 0,
      rpPaymentId: (json['rp_payment_id'] as String?) ?? (json['razorpay_payment_id'] as String?),
      rpOrderId: (json['rp_order_id'] as String?) ?? (json['razorpay_order_id'] as String?),
      utr: (json['utr'] as String?) ?? (json['rrn'] as String?) ?? (json['payout_ref'] as String?),
      counterpartyName: (json['counterparty_name'] as String?) ?? (json['from_to_name'] as String?),
      counterpartyAccount: (json['counterparty_account'] as String?) ?? (json['from_to_account'] as String?),
      linkedItemTitle: (json['linked_title'] as String?) ?? (json['item_title'] as String?) ?? (json['job_title'] as String?),
      rawStatus: (json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'direction': direction,
        'amount_paise': amountPaise,
        'bucket': bucket,
        'ref_type': refType,
        'ref_id': refId,
        'note': note,
        'created_at': createdAt.toIso8601String(),
        'tx_type': type.key,
        'fee_paise': feePaise,
        if (rpPaymentId != null) 'rp_payment_id': rpPaymentId,
        if (rpOrderId != null) 'rp_order_id': rpOrderId,
        if (utr != null) 'utr': utr,
        if (counterpartyName != null) 'counterparty_name': counterpartyName,
        if (counterpartyAccount != null) 'counterparty_account': counterpartyAccount,
        if (linkedItemTitle != null) 'linked_title': linkedItemTitle,
        if (rawStatus != null) 'status': rawStatus,
      };

  bool get isCredit => direction.toLowerCase() == 'credit';
  bool get isDebit => direction.toLowerCase() == 'debit';

  double get amountRupees => amountPaise / 100.0;
  double get feeRupees => feePaise / 100.0;
  int get taxPaise => (feePaise * 0.18).round();
  int get grossAmountPaise => isCredit ? amountPaise : (amountPaise + feePaise);

  String get formattedSignedAmount {
    final String prefix = isCredit ? '+' : '-';
    return '$prefix${WalletBalance.formatIndianCurrency(amountPaise)}';
  }

  String get formattedGrossAmount => WalletBalance.formatIndianCurrency(grossAmountPaise);
  String get formattedFee => WalletBalance.formatIndianCurrency(feePaise);
  String get formattedTax => WalletBalance.formatIndianCurrency(taxPaise);
  String get formattedNetAmount => WalletBalance.formatIndianCurrency(amountPaise);

  String get utrNumber {
    if (utr != null && utr!.trim().isNotEmpty) {
      return utr!;
    }
    if (refId != null && refId!.trim().isNotEmpty) {
      final clean = refId!.replaceAll('-', '').toUpperCase();
      if (clean.length >= 12) {
        return 'UTR-${clean.substring(0, 12)}';
      }
      return 'UTR-$clean';
    }
    final cleanId = id.replaceAll('-', '').toUpperCase();
    final sub = cleanId.length >= 8 ? cleanId.substring(0, 8) : cleanId;
    return 'UTR-${createdAt.millisecondsSinceEpoch.toString().substring(5)}-$sub';
  }

  String get status {
    if (rawStatus != null && rawStatus!.trim().isNotEmpty) {
      return rawStatus!.toLowerCase();
    }
    if (type == WalletTransactionType.refund) return 'refunded';
    return 'completed';
  }

  String get statusDisplay {
    final s = status.toLowerCase();
    if (s == 'success' || s == 'completed' || s == 'settled') return 'Success';
    if (s == 'pending' || s == 'requested' || s == 'processing') return 'Pending';
    if (s == 'failed' || s == 'rejected') return 'Failed';
    if (s == 'refunded' || type == WalletTransactionType.refund) return 'Refunded';
    return 'Success';
  }

  Color get statusColor {
    switch (statusDisplay) {
      case 'Success':
        return const Color(0xFF00875A);
      case 'Pending':
        return const Color(0xFFD97706);
      case 'Failed':
        return const Color(0xFFDC2626);
      case 'Refunded':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF00875A);
    }
  }

  /// Subtitle: linked job or order (Prompt D1)
  String get subtitle {
    if (linkedItemTitle != null && linkedItemTitle!.trim().isNotEmpty) {
      return linkedItemTitle!;
    }
    if (refType != null && refType!.isNotEmpty) {
      final cleanRef = refId != null && refId!.isNotEmpty
          ? ' #${refId!.length > 8 ? refId!.substring(0, 8) : refId}'
          : '';
      return '${_formatRefLabel(refType!)}$cleanRef';
    }
    if (note != null && note!.trim().isNotEmpty && note != title) {
      return note!;
    }
    switch (type) {
      case WalletTransactionType.dailyWage:
        return 'Daily Wage Shift Job';
      case WalletTransactionType.produceSale:
        return 'Agri Produce Order';
      case WalletTransactionType.upiTransfer:
        return 'Bank Payout Transfer';
      case WalletTransactionType.autoPayout:
        return 'Auto Scheduled Settlement';
      case WalletTransactionType.platformFee:
        return 'Platform Trust & Protection';
      case WalletTransactionType.rewardCredit:
        return 'Community XP & Reward';
      case WalletTransactionType.refund:
        return 'Escrow Dispute Refund';
      case WalletTransactionType.other:
        return 'Ledger Settlement';
    }
  }

  static String _formatRefLabel(String ref) {
    switch (ref.toLowerCase()) {
      case 'job_assignment':
      case 'job':
        return 'Job';
      case 'order':
      case 'produce_order':
        return 'Produce Order';
      case 'payout':
        return 'UPI Payout';
      case 'payment':
        return 'Online Payment';
      case 'refund':
        return 'Dispute Refund';
      default:
        return ref;
    }
  }

  /// Masked Counterparty representation (Prompt D2)
  String get counterpartyLabel {
    final isTo = isDebit;
    final prefix = isTo ? 'To: ' : 'From: ';

    if (counterpartyName != null && counterpartyName!.trim().isNotEmpty) {
      final account = counterpartyAccount != null ? ' (${_maskAccount(counterpartyAccount!)})' : '';
      return '$prefix$counterpartyName$account';
    }

    if (counterpartyAccount != null && counterpartyAccount!.trim().isNotEmpty) {
      return '$prefix${_maskAccount(counterpartyAccount!)}';
    }

    // Default sensible masked counterparty
    if (isCredit) {
      switch (type) {
        case WalletTransactionType.dailyWage:
          return 'From: Verified Employer (SafeEscrow)';
        case WalletTransactionType.produceSale:
          return 'From: Direct Customer (SafeEscrow)';
        case WalletTransactionType.rewardCredit:
          return 'From: UdyogaSethu Rewards';
        case WalletTransactionType.refund:
          return 'From: Escrow Reserve Fund';
        default:
          return 'From: UdyogaSethu Escrow';
      }
    } else {
      switch (type) {
        case WalletTransactionType.upiTransfer:
        case WalletTransactionType.autoPayout:
          final last4 = utrNumber.replaceAll(RegExp(r'\D'), '');
          final tail = last4.length >= 4 ? last4.substring(last4.length - 4) : '9481';
          return 'To: Bank Account (•••• $tail)';
        case WalletTransactionType.platformFee:
          return 'To: Platform Safety & Protection Pool';
        default:
          return 'To: Linked Payment Provider';
      }
    }
  }

  static String _maskAccount(String raw) {
    final clean = raw.trim();
    if (clean.contains('@')) {
      final parts = clean.split('@');
      final user = parts[0];
      final handle = parts[1];
      if (user.length <= 2) {
        return '$user***@$handle';
      }
      return '${user.substring(0, 2)}***@$handle';
    }
    // Numeric bank account
    if (clean.length > 4) {
      return '•••• ${clean.substring(clean.length - 4)}';
    }
    return '•••• $clean';
  }

  /// Default icon matching Screen 8
  IconData get icon {
    switch (type) {
      case WalletTransactionType.dailyWage:
        return Icons.handyman_outlined;
      case WalletTransactionType.upiTransfer:
        return Icons.arrow_outward_rounded;
      case WalletTransactionType.produceSale:
        return Icons.agriculture_outlined;
      case WalletTransactionType.autoPayout:
        return Icons.payments_outlined;
      case WalletTransactionType.platformFee:
        return Icons.receipt_long_outlined;
      case WalletTransactionType.rewardCredit:
        return Icons.stars_rounded;
      case WalletTransactionType.refund:
        return Icons.replay_rounded;
      case WalletTransactionType.other:
        return isCredit ? Icons.south_west_rounded : Icons.north_east_rounded;
    }
  }

  /// Default title fallback if note is absent
  String get title {
    if (note != null && note!.trim().isNotEmpty) {
      return note!;
    }
    switch (type) {
      case WalletTransactionType.dailyWage:
        return 'Daily Wage';
      case WalletTransactionType.upiTransfer:
        return 'UPI Transfer (Bank)';
      case WalletTransactionType.produceSale:
        return 'Farm Produce Direct Sale';
      case WalletTransactionType.autoPayout:
        return 'UPI Auto-Payout';
      case WalletTransactionType.platformFee:
        return 'Platform Fee & Protection';
      case WalletTransactionType.rewardCredit:
        return 'Reward Credit';
      case WalletTransactionType.refund:
        return 'Escrow Refund';
      case WalletTransactionType.other:
        return isCredit ? 'Wallet Credit' : 'Wallet Debit';
    }
  }
}
