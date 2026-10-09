class ProduceOrder {
  final String orderId;
  final String orderCode;
  final String farmerId;
  final String farmerName;
  final int totalPaise;
  final int feePaise;
  final int discountPaise;
  final String status;
  final int itemsCount;
  final String? slotId;
  final String fulfilment;
  final bool protected;
  final String paymentMethod;
  final DateTime createdAt;

  const ProduceOrder({
    required this.orderId,
    required this.orderCode,
    required this.farmerId,
    required this.farmerName,
    required this.totalPaise,
    required this.feePaise,
    required this.discountPaise,
    required this.status,
    required this.itemsCount,
    this.slotId,
    required this.fulfilment,
    required this.protected,
    this.paymentMethod = 'upi',
    required this.createdAt,
  });

  String get formattedTotal {
    final rupees = totalPaise / 100;
    return rupees == rupees.roundToDouble()
        ? '₹${rupees.toInt()}'
        : '₹${rupees.toStringAsFixed(2)}';
  }

  factory ProduceOrder.fromJson(Map<String, dynamic> json) {
    return ProduceOrder(
      orderId: (json['order_id'] ?? json['id']) as String,
      orderCode: json['order_code'] as String? ?? 'ORD-REF',
      farmerId: json['farmer_id'] as String? ?? '',
      farmerName: json['farmer_name'] as String? ?? 'Cauvery Bio Farm',
      totalPaise: (json['total_paise'] as num?)?.toInt() ?? 0,
      feePaise: (json['fee_paise'] as num?)?.toInt() ?? 0,
      discountPaise: (json['discount_paise'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending',
      itemsCount: (json['items_count'] as num?)?.toInt() ?? 1,
      slotId: json['slot_id'] as String?,
      fulfilment: json['fulfilment'] as String? ?? 'delivery',
      protected: json['protected'] as bool? ?? false,
      paymentMethod: json['payment_method'] as String? ?? 'upi',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'order_code': orderCode,
      'farmer_id': farmerId,
      'farmer_name': farmerName,
      'total_paise': totalPaise,
      'fee_paise': feePaise,
      'discount_paise': discountPaise,
      'status': status,
      'items_count': itemsCount,
      'slot_id': slotId,
      'fulfilment': fulfilment,
      'protected': protected,
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class CheckoutDraft {
  final String deliveryAddress;
  final String? deliveryNotes;
  final bool isProtected;
  final String paymentMethod;
  final String fulfilment; // 'delivery' or 'pickup'
  final Map<String, String> slotIds; // farmerId -> slotId

  const CheckoutDraft({
    this.deliveryAddress = 'Door 42, 3rd Cross, Mandya Agri Market Road',
    this.deliveryNotes,
    this.isProtected = true,
    this.paymentMethod = 'upi',
    this.fulfilment = 'delivery',
    this.slotIds = const {},
  });

  CheckoutDraft copyWith({
    String? deliveryAddress,
    String? deliveryNotes,
    bool? isProtected,
    String? paymentMethod,
    String? fulfilment,
    Map<String, String>? slotIds,
  }) {
    return CheckoutDraft(
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      isProtected: isProtected ?? this.isProtected,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      fulfilment: fulfilment ?? this.fulfilment,
      slotIds: slotIds ?? this.slotIds,
    );
  }
}
