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
      };

  bool get isCredit => direction.toLowerCase() == 'credit';
  bool get isDebit => direction.toLowerCase() == 'debit';

  double get amountRupees => amountPaise / 100.0;
  double get feeRupees => feePaise / 100.0;

  /// Returns formatted amount with signed prefix (+₹700 or -₹1,200)
  String get formattedSignedAmount {
    final String prefix = isCredit ? '+' : '-';
    return '$prefix${WalletBalance.formatIndianCurrency(amountPaise)}';
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
