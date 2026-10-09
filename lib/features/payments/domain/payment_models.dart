import 'package:flutter/material.dart';

enum PaymentMethod {
  upi,
  card,
  wallet,
  cash;

  String toDbString() => name;

  static PaymentMethod fromDbString(String value) {
    switch (value.toLowerCase()) {
      case 'upi':
        return PaymentMethod.upi;
      case 'card':
        return PaymentMethod.card;
      case 'wallet':
        return PaymentMethod.wallet;
      case 'cash':
        return PaymentMethod.cash;
      default:
        return PaymentMethod.upi;
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.upi:
        return 'UPI (GPay / PhonePe / Paytm)';
      case PaymentMethod.card:
        return 'Credit / Debit Card';
      case PaymentMethod.wallet:
        return 'UdyogaSethu Wallet';
      case PaymentMethod.cash:
        return 'Cash on Completion';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.upi:
        return Icons.qr_code_2;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.wallet:
        return Icons.account_balance_wallet;
      case PaymentMethod.cash:
        return Icons.payments;
    }
  }
}

enum PaymentStatus {
  created,
  authorised,
  captured,
  held,
  released,
  refunded,
  failed;

  String toDbString() => name;

  static PaymentStatus fromDbString(String value) {
    switch (value.toLowerCase()) {
      case 'created':
        return PaymentStatus.created;
      case 'authorised':
        return PaymentStatus.authorised;
      case 'captured':
        return PaymentStatus.captured;
      case 'held':
        return PaymentStatus.held;
      case 'released':
        return PaymentStatus.released;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'failed':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.created;
    }
  }

  bool get isSuccessful => this == PaymentStatus.captured || this == PaymentStatus.held || this == PaymentStatus.released;
  bool get isEscrowProtected => this == PaymentStatus.held;
  bool get isFailed => this == PaymentStatus.failed;
  bool get isPending => this == PaymentStatus.created || this == PaymentStatus.authorised;
}

class PaymentRecord {
  final String id;
  final String payerId;
  final String? payeeId;
  final String refType;
  final String refId;
  final int amountPaise;
  final int platformFeePaise;
  final PaymentMethod method;
  final PaymentStatus status;
  final bool protected;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final bool signatureVerified;
  final String receiptNo;
  final DateTime createdAt;

  const PaymentRecord({
    required this.id,
    required this.payerId,
    this.payeeId,
    required this.refType,
    required this.refId,
    required this.amountPaise,
    required this.platformFeePaise,
    required this.method,
    required this.status,
    required this.protected,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    required this.signatureVerified,
    required this.receiptNo,
    required this.createdAt,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'] as String,
      payerId: json['payer_id'] as String,
      payeeId: json['payee_id'] as String?,
      refType: (json['ref_type'] as String?) ?? 'assignment',
      refId: json['ref_id'] as String,
      amountPaise: (json['amount_paise'] as num).toInt(),
      platformFeePaise: (json['platform_fee_paise'] as num?)?.toInt() ?? 0,
      method: PaymentMethod.fromDbString((json['method'] as String?) ?? 'upi'),
      status: PaymentStatus.fromDbString((json['status'] as String?) ?? 'created'),
      protected: json['protected'] as bool? ?? false,
      razorpayOrderId: json['razorpay_order_id'] as String?,
      razorpayPaymentId: json['razorpay_payment_id'] as String?,
      signatureVerified: json['signature_verified'] as bool? ?? false,
      receiptNo: (json['receipt_no'] as String?) ?? 'RCP-PENDING',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payer_id': payerId,
      'payee_id': payeeId,
      'ref_type': refType,
      'ref_id': refId,
      'amount_paise': amountPaise,
      'platform_fee_paise': platformFeePaise,
      'method': method.toDbString(),
      'status': status.toDbString(),
      'protected': protected,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'signature_verified': signatureVerified,
      'receipt_no': receiptNo,
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get amountRupees => amountPaise / 100.0;
  double get platformFeeRupees => platformFeePaise / 100.0;

  static String formatIndianCurrency(int paise) {
    final double rupees = paise / 100.0;
    final int whole = rupees.floor();
    final int dec = ((rupees - whole) * 100).round();

    final String s = whole.toString();
    if (s.length <= 3) {
      return dec > 0 ? '₹$s.${dec.toString().padLeft(2, '0')}' : '₹$s';
    }

    final String lastThree = s.substring(s.length - 3);
    final String remaining = s.substring(0, s.length - 3);
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < remaining.length; i++) {
      if (i > 0 && (remaining.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(remaining[i]);
    }
    buffer.write(',');
    buffer.write(lastThree);

    final String formatted = buffer.toString();
    return dec > 0 ? '₹$formatted.${dec.toString().padLeft(2, '0')}' : '₹$formatted';
  }
}
