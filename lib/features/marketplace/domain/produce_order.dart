class ProduceOrderItem {
  final String? listingId;
  final String name;
  final String unit;
  final int unitPricePaise;
  final double quantity;
  final int subtotalPaise;

  const ProduceOrderItem({
    this.listingId,
    required this.name,
    required this.unit,
    required this.unitPricePaise,
    required this.quantity,
    required this.subtotalPaise,
  });

  String get formattedSubtotal {
    final rupees = subtotalPaise / 100;
    return rupees == rupees.roundToDouble()
        ? '₹${rupees.toInt()}'
        : '₹${rupees.toStringAsFixed(2)}';
  }

  String get formattedUnitPrice {
    final rupees = unitPricePaise / 100;
    return rupees == rupees.roundToDouble()
        ? '₹${rupees.toInt()}/$unit'
        : '₹${rupees.toStringAsFixed(2)}/$unit';
  }

  factory ProduceOrderItem.fromJson(Map<String, dynamic> json) {
    return ProduceOrderItem(
      listingId: (json['listing_id'] ?? json['id']) as String?,
      name: (json['name'] ?? 'Produce Item') as String,
      unit: (json['unit'] ?? 'kg') as String,
      unitPricePaise: (json['unit_price_paise'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      subtotalPaise: (json['subtotal_paise'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'listing_id': listingId,
      'name': name,
      'unit': unit,
      'unit_price_paise': unitPricePaise,
      'quantity': quantity,
      'subtotal_paise': subtotalPaise,
    };
  }
}

class ProduceOrder {
  final String orderId;
  final String orderCode;
  final String farmerId;
  final String farmerName;
  final String? farmerPhone;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final int totalPaise;
  final int feePaise;
  final int discountPaise;
  final String status;
  final int itemsCount;
  final String? slotId;
  final String? slotDate;
  final String? windowStart;
  final String? windowEnd;
  final String fulfilment;
  final String? addressText;
  final String? deliveryNotes;
  final String? deliveryPin;
  final bool protected;
  final String paymentMethod;
  final String? paymentId;
  final String? paymentStatus;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final List<ProduceOrderItem> items;

  const ProduceOrder({
    required this.orderId,
    required this.orderCode,
    required this.farmerId,
    required this.farmerName,
    this.farmerPhone,
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.totalPaise,
    required this.feePaise,
    required this.discountPaise,
    required this.status,
    required this.itemsCount,
    this.slotId,
    this.slotDate,
    this.windowStart,
    this.windowEnd,
    required this.fulfilment,
    this.addressText,
    this.deliveryNotes,
    this.deliveryPin,
    required this.protected,
    this.paymentMethod = 'upi',
    this.paymentId,
    this.paymentStatus,
    required this.createdAt,
    this.deliveredAt,
    this.items = const [],
  });

  String get formattedTotal {
    final rupees = totalPaise / 100;
    return rupees == rupees.roundToDouble()
        ? '₹${rupees.toInt()}'
        : '₹${rupees.toStringAsFixed(2)}';
  }

  int get netEarningsPaise => totalPaise - feePaise;

  String get formattedNetEarnings {
    final netPaise = netEarningsPaise;
    final rupees = netPaise / 100;
    return rupees == rupees.roundToDouble()
        ? '₹${rupees.toInt()}'
        : '₹${rupees.toStringAsFixed(2)}';
  }

  String get formattedFee {
    final rupees = feePaise / 100;
    return rupees == rupees.roundToDouble()
        ? '₹${rupees.toInt()}'
        : '₹${rupees.toStringAsFixed(2)}';
  }

  String get slotDisplayWindow {
    if (slotDate == null) return 'Flexible Window';
    final startFormatted = windowStart != null ? windowStart!.substring(0, 5) : '07:00';
    final endFormatted = windowEnd != null ? windowEnd!.substring(0, 5) : '11:00';
    return '$slotDate ($startFormatted - $endFormatted)';
  }

  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';
  bool get isDisputed => status == 'disputed';
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isPacked => status == 'packed';
  bool get isOutForDelivery => status == 'out_for_delivery';

  factory ProduceOrder.fromJson(Map<String, dynamic> json) {
    // Parse nested slot if present
    final slotObj = json['slot'] as Map<String, dynamic>?;
    final slotDate = json['slot_date'] as String? ?? slotObj?['slot_date'] as String?;
    final windowStart = json['window_start'] as String? ?? slotObj?['window_start'] as String?;
    final windowEnd = json['window_end'] as String? ?? slotObj?['window_end'] as String?;

    // Parse items if present
    final itemsList = <ProduceOrderItem>[];
    if (json['items'] is List) {
      for (final it in (json['items'] as List)) {
        if (it is Map<String, dynamic>) {
          itemsList.add(ProduceOrderItem.fromJson(it));
        }
      }
    }

    return ProduceOrder(
      orderId: (json['order_id'] ?? json['id']) as String,
      orderCode: json['order_code'] as String? ?? 'ORD-REF',
      farmerId: json['farmer_id'] as String? ?? '',
      farmerName: json['farmer_name'] as String? ?? 'Cauvery Bio Farm',
      farmerPhone: json['farmer_phone'] as String?,
      customerId: json['customer_id'] as String?,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      totalPaise: (json['total_paise'] as num?)?.toInt() ?? 0,
      feePaise: (json['fee_paise'] as num?)?.toInt() ?? 0,
      discountPaise: (json['discount_paise'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending',
      itemsCount: (json['items_count'] as num?)?.toInt() ?? (itemsList.isNotEmpty ? itemsList.length : 1),
      slotId: json['slot_id'] as String?,
      slotDate: slotDate,
      windowStart: windowStart,
      windowEnd: windowEnd,
      fulfilment: json['fulfilment'] as String? ?? 'delivery',
      addressText: json['address_text'] as String?,
      deliveryNotes: json['delivery_notes'] as String?,
      deliveryPin: json['delivery_pin'] as String?,
      protected: json['protected'] as bool? ?? false,
      paymentMethod: json['payment_method'] as String? ?? 'upi',
      paymentId: json['payment_id'] as String?,
      paymentStatus: json['payment_status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'order_code': orderCode,
      'farmer_id': farmerId,
      'farmer_name': farmerName,
      'farmer_phone': farmerPhone,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'total_paise': totalPaise,
      'fee_paise': feePaise,
      'discount_paise': discountPaise,
      'status': status,
      'items_count': itemsCount,
      'slot_id': slotId,
      'slot_date': slotDate,
      'window_start': windowStart,
      'window_end': windowEnd,
      'fulfilment': fulfilment,
      'address_text': addressText,
      'delivery_notes': deliveryNotes,
      'delivery_pin': deliveryPin,
      'protected': protected,
      'payment_method': paymentMethod,
      'payment_id': paymentId,
      'payment_status': paymentStatus,
      'created_at': createdAt.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
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
