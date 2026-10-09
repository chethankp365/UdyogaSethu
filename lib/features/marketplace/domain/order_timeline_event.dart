enum OrderStage {
  pending,
  accepted,
  packed,
  outForDelivery,
  delivered,
  cancelled,
  disputed;

  static OrderStage fromString(String val) {
    switch (val.toLowerCase().replaceAll(' ', '_')) {
      case 'pending':
        return OrderStage.pending;
      case 'accepted':
        return OrderStage.accepted;
      case 'packed':
        return OrderStage.packed;
      case 'out_for_delivery':
      case 'outfordelivery':
        return OrderStage.outForDelivery;
      case 'delivered':
        return OrderStage.delivered;
      case 'cancelled':
        return OrderStage.cancelled;
      case 'disputed':
        return OrderStage.disputed;
      default:
        return OrderStage.pending;
    }
  }

  String get dbValue {
    switch (this) {
      case OrderStage.pending:
        return 'pending';
      case OrderStage.accepted:
        return 'accepted';
      case OrderStage.packed:
        return 'packed';
      case OrderStage.outForDelivery:
        return 'out_for_delivery';
      case OrderStage.delivered:
        return 'delivered';
      case OrderStage.cancelled:
        return 'cancelled';
      case OrderStage.disputed:
        return 'disputed';
    }
  }
}

class OrderTimelineEvent {
  final String id;
  final String orderId;
  final String status;
  final String? actorId;
  final String? note;
  final Map<String, dynamic> meta;
  final DateTime createdAt;

  const OrderTimelineEvent({
    required this.id,
    required this.orderId,
    required this.status,
    this.actorId,
    this.note,
    this.meta = const {},
    required this.createdAt,
  });

  OrderStage get stage => OrderStage.fromString(status);

  factory OrderTimelineEvent.fromJson(Map<String, dynamic> json) {
    return OrderTimelineEvent(
      id: (json['id'] ?? '') as String,
      orderId: (json['order_id'] ?? '') as String,
      status: (json['status'] ?? json['event_type'] ?? 'pending') as String,
      actorId: json['actor_id'] as String?,
      note: json['note'] as String?,
      meta: (json['meta'] as Map<String, dynamic>?) ?? const {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'status': status,
      'actor_id': actorId,
      'note': note,
      'meta': meta,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
