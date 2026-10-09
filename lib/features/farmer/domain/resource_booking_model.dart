import 'package:flutter/material.dart';

enum ResourceBookingStatus {
  requested,
  confirmed,
  inProgress,
  completed,
  cancelled;

  static ResourceBookingStatus fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'requested':
        return ResourceBookingStatus.requested;
      case 'confirmed':
      case 'accepted':
        return ResourceBookingStatus.confirmed;
      case 'in_progress':
      case 'started':
        return ResourceBookingStatus.inProgress;
      case 'completed':
        return ResourceBookingStatus.completed;
      case 'cancelled':
      case 'declined':
        return ResourceBookingStatus.cancelled;
      default:
        return ResourceBookingStatus.requested;
    }
  }

  String get dbValue {
    switch (this) {
      case ResourceBookingStatus.requested:
        return 'requested';
      case ResourceBookingStatus.confirmed:
        return 'confirmed';
      case ResourceBookingStatus.inProgress:
        return 'in_progress';
      case ResourceBookingStatus.completed:
        return 'completed';
      case ResourceBookingStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case ResourceBookingStatus.requested:
        return 'Requested';
      case ResourceBookingStatus.confirmed:
        return 'Escrow Held';
      case ResourceBookingStatus.inProgress:
        return 'In Progress';
      case ResourceBookingStatus.completed:
        return 'Completed';
      case ResourceBookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case ResourceBookingStatus.requested:
        return const Color(0xFFD97706);
      case ResourceBookingStatus.confirmed:
        return const Color(0xFF0D6548);
      case ResourceBookingStatus.inProgress:
        return const Color(0xFF2563EB);
      case ResourceBookingStatus.completed:
        return const Color(0xFF059669);
      case ResourceBookingStatus.cancelled:
        return const Color(0xFFDC2626);
    }
  }
}

class ResourceBooking {
  final String id;
  final String resourceId;
  final String renterId;
  final DateTime startAt;
  final DateTime endAt;
  final int totalPaise;
  final ResourceBookingStatus status;
  final double quantity;
  final String unit;
  final String deliveryAddress;
  final String notes;
  final String? paymentId;
  final String resourceName;
  final String ownerName;
  final String? receiptNo;
  final bool isEscrowHeld;
  final DateTime createdAt;

  const ResourceBooking({
    required this.id,
    required this.resourceId,
    required this.renterId,
    required this.startAt,
    required this.endAt,
    required this.totalPaise,
    this.status = ResourceBookingStatus.requested,
    this.quantity = 1.0,
    this.unit = 'hr',
    this.deliveryAddress = '',
    this.notes = '',
    this.paymentId,
    this.resourceName = 'Agri Equipment',
    this.ownerName = 'Machinery Vendor',
    this.receiptNo,
    this.isEscrowHeld = true,
    required this.createdAt,
  });

  double get totalRupees => totalPaise / 100.0;

  String get formattedTotal {
    final rups = totalRupees;
    if (rups == rups.roundToDouble()) {
      return '₹${rups.toInt()}';
    }
    return '₹${rups.toStringAsFixed(1)}';
  }

  factory ResourceBooking.fromJson(Map<String, dynamic> json) {
    return ResourceBooking(
      id: json['id'] as String? ?? '',
      resourceId: json['resource_id'] as String? ?? '',
      renterId: json['renter_id'] as String? ?? '',
      startAt: json['start_at'] != null
          ? DateTime.tryParse(json['start_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endAt: json['end_at'] != null
          ? DateTime.tryParse(json['end_at'].toString()) ??
              DateTime.now().add(const Duration(hours: 4))
          : DateTime.now().add(const Duration(hours: 4)),
      totalPaise: (json['total_paise'] as num?)?.toInt() ?? 0,
      status: ResourceBookingStatus.fromString(json['status'] as String?),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] as String? ?? 'hr',
      deliveryAddress: json['delivery_address'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      paymentId: json['payment_id'] as String?,
      resourceName: json['resource_name'] as String? ??
          (json['resource_listings'] is Map
              ? (json['resource_listings']['name'] as String? ?? 'Equipment')
              : 'Equipment'),
      ownerName: json['owner_name'] as String? ?? 'Vendor',
      receiptNo: json['receipt_no'] as String?,
      isEscrowHeld: json['is_escrow_held'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'resource_id': resourceId,
      'renter_id': renterId,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'total_paise': totalPaise,
      'status': status.dbValue,
      'quantity': quantity,
      'unit': unit,
      'delivery_address': deliveryAddress,
      'notes': notes,
      'payment_id': paymentId,
      'resource_name': resourceName,
      'owner_name': ownerName,
      'receipt_no': receiptNo,
      'is_escrow_held': isEscrowHeld,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ResourceBooking copyWith({
    String? id,
    String? resourceId,
    String? renterId,
    DateTime? startAt,
    DateTime? endAt,
    int? totalPaise,
    ResourceBookingStatus? status,
    double? quantity,
    String? unit,
    String? deliveryAddress,
    String? notes,
    String? paymentId,
    String? resourceName,
    String? ownerName,
    String? receiptNo,
    bool? isEscrowHeld,
    DateTime? createdAt,
  }) {
    return ResourceBooking(
      id: id ?? this.id,
      resourceId: resourceId ?? this.resourceId,
      renterId: renterId ?? this.renterId,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      totalPaise: totalPaise ?? this.totalPaise,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      notes: notes ?? this.notes,
      paymentId: paymentId ?? this.paymentId,
      resourceName: resourceName ?? this.resourceName,
      ownerName: ownerName ?? this.ownerName,
      receiptNo: receiptNo ?? this.receiptNo,
      isEscrowHeld: isEscrowHeld ?? this.isEscrowHeld,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
