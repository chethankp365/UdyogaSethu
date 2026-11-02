class PaymentBillSummary {
  final int baseAmountPaise;
  final int platformFeePaise;
  final int protectionFeePaise;
  final int totalPaise;
  final bool isProtected;
  final String description;

  const PaymentBillSummary({
    required this.baseAmountPaise,
    required this.platformFeePaise,
    required this.protectionFeePaise,
    required this.totalPaise,
    required this.isProtected,
    required this.description,
  });

  factory PaymentBillSummary.fromJson(Map<String, dynamic> json) {
    return PaymentBillSummary(
      baseAmountPaise: (json['base_amount_paise'] as num?)?.toInt() ?? 0,
      platformFeePaise: (json['platform_fee_paise'] as num?)?.toInt() ?? 0,
      protectionFeePaise: (json['protection_fee_paise'] as num?)?.toInt() ?? 0,
      totalPaise: (json['total_paise'] as num?)?.toInt() ?? 0,
      isProtected: json['is_protected'] as bool? ?? false,
      description: (json['description'] as String?) ?? 'Payment',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base_amount_paise': baseAmountPaise,
      'platform_fee_paise': platformFeePaise,
      'protection_fee_paise': protectionFeePaise,
      'total_paise': totalPaise,
      'is_protected': isProtected,
      'description': description,
    };
  }

  double get baseAmountRupees => baseAmountPaise / 100.0;
  double get platformFeeRupees => platformFeePaise / 100.0;
  double get protectionFeeRupees => protectionFeePaise / 100.0;
  double get totalRupees => totalPaise / 100.0;
}

class PaymentOrderResult {
  final String? orderId;
  final String? keyId;
  final String paymentId;
  final String receiptNo;
  final int amountPaise;
  final String currency;
  final String status;
  final String method;
  final String? upiString;
  final String? upiFlow;
  final PaymentBillSummary billSummary;

  const PaymentOrderResult({
    this.orderId,
    this.keyId,
    required this.paymentId,
    required this.receiptNo,
    required this.amountPaise,
    required this.currency,
    required this.status,
    required this.method,
    this.upiString,
    this.upiFlow,
    required this.billSummary,
  });

  factory PaymentOrderResult.fromJson(Map<String, dynamic> json) {
    final amountPaise = (json['amount_paise'] as num?)?.toInt() ?? 0;
    final rzpOrderId = json['order_id'] as String?;
    final rcpt = (json['receipt_no'] as String?) ?? 'RCP-PENDING';

    // Build standard NPCI UPI URI if UPI string wasn't explicitly supplied
    final rawUpi = json['upi_string'] as String?;
    final upiString = rawUpi ??
        'upi://pay?pa=rzp.test@hdfcbank&pn=UdyogaSethu&am=${(amountPaise / 100.0).toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent(rcpt)}&tr=${rzpOrderId ?? json['payment_id']}';

    return PaymentOrderResult(
      orderId: rzpOrderId,
      keyId: json['key_id'] as String?,
      paymentId: json['payment_id'] as String,
      receiptNo: rcpt,
      amountPaise: amountPaise,
      currency: (json['currency'] as String?) ?? 'INR',
      status: (json['status'] as String?) ?? 'created',
      method: (json['method'] as String?) ?? 'upi',
      upiString: upiString,
      upiFlow: json['upi_flow'] as String?,
      billSummary: json['bill_summary'] != null
          ? PaymentBillSummary.fromJson(json['bill_summary'] as Map<String, dynamic>)
          : PaymentBillSummary(
              baseAmountPaise: amountPaise,
              platformFeePaise: 0,
              protectionFeePaise: 0,
              totalPaise: amountPaise,
              isProtected: false,
              description: 'Payment',
            ),
    );
  }
}
