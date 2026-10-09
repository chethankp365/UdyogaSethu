import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum ProduceStatus {
  active,
  lowStock,
  soldOut,
  paused;

  String get dbValue {
    switch (this) {
      case ProduceStatus.active:
        return 'active';
      case ProduceStatus.lowStock:
        return 'low_stock';
      case ProduceStatus.soldOut:
        return 'sold_out';
      case ProduceStatus.paused:
        return 'paused';
    }
  }

  static ProduceStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'low_stock':
        return ProduceStatus.lowStock;
      case 'sold_out':
        return ProduceStatus.soldOut;
      case 'paused':
        return ProduceStatus.paused;
      case 'active':
      default:
        return ProduceStatus.active;
    }
  }

  Color get color {
    switch (this) {
      case ProduceStatus.active:
        return const Color(0xFF00875A); // Emerald / Green
      case ProduceStatus.lowStock:
        return const Color(0xFFD97706); // Amber
      case ProduceStatus.soldOut:
        return const Color(0xFFDC2626); // Red
      case ProduceStatus.paused:
        return const Color(0xFF64748B); // Slate
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ProduceStatus.active:
        return const Color(0xFFE6F4EA);
      case ProduceStatus.lowStock:
        return const Color(0xFFFEF3C7);
      case ProduceStatus.soldOut:
        return const Color(0xFFFEE2E2);
      case ProduceStatus.paused:
        return const Color(0xFFF1F5F9);
    }
  }
}

enum AvailabilityMode {
  sameDay,
  nextDay,
  preOrder;

  String get dbValue {
    switch (this) {
      case AvailabilityMode.sameDay:
        return 'same_day';
      case AvailabilityMode.nextDay:
        return 'next_day';
      case AvailabilityMode.preOrder:
        return 'pre_order';
    }
  }

  static AvailabilityMode fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'next_day':
        return AvailabilityMode.nextDay;
      case 'pre_order':
        return AvailabilityMode.preOrder;
      case 'same_day':
      default:
        return AvailabilityMode.sameDay;
    }
  }

  String get label {
    switch (this) {
      case AvailabilityMode.sameDay:
        return 'Same Day Delivery';
      case AvailabilityMode.nextDay:
        return 'Next Day Delivery';
      case AvailabilityMode.preOrder:
        return 'Harvest Pre-Order';
    }
  }
}

@immutable
class ProduceListing {
  final String id;
  final String farmerId;
  final String farmerName;
  final String farmName;
  final String clusterVillage;
  final String? farmerAvatarPath;
  final bool isVerifiedFarmer;
  final String name;
  final String category; // 'vegetable', 'fruit', 'grain', 'pulse', 'spices', 'other'
  final String description;
  final int pricePaise;
  final String unit; // 'kg', 'quintal', 'bunch', 'piece', 'box'
  final double stockQty;
  final double lowStockThreshold;
  final ProduceStatus status;
  final DateTime? harvestAt;
  final String qualityNotes;
  final String farmingMethod;
  final List<String> images;
  final bool deliveryAvailable;
  final bool pickupAvailable;
  final AvailabilityMode availabilityMode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProduceListing({
    required this.id,
    required this.farmerId,
    this.farmerName = 'Verified Farmer',
    this.farmName = 'Greenfield Organic Farm',
    this.clusterVillage = 'Mandya Cluster',
    this.farmerAvatarPath,
    this.isVerifiedFarmer = true,
    required this.name,
    this.category = 'vegetable',
    this.description = '',
    required this.pricePaise,
    this.unit = 'kg',
    required this.stockQty,
    this.lowStockThreshold = 10.0,
    required this.status,
    this.harvestAt,
    this.qualityNotes = '',
    this.farmingMethod = 'Organic',
    this.images = const [],
    this.deliveryAvailable = true,
    this.pickupAvailable = true,
    this.availabilityMode = AvailabilityMode.sameDay,
    required this.createdAt,
    required this.updatedAt,
  });

  double get priceRupees => pricePaise / 100.0;
  String get formattedPrice => '₹${NumberFormat('#,##0').format(priceRupees.round())}/$unit';
  String get formattedStock => '${stockQty.toStringAsFixed(stockQty.truncateToDouble() == stockQty ? 0 : 1)} $unit in stock';

  bool get isInStock => stockQty > 0;
  bool get isActiveAndInStock => (status == ProduceStatus.active || status == ProduceStatus.lowStock) && isInStock;

  factory ProduceListing.fromJson(Map<String, dynamic> json) {
    final imgsRaw = json['images'];
    List<String> imgList = [];
    if (imgsRaw is List) {
      imgList = imgsRaw.map((e) => e.toString()).toList();
    }

    final pPaise = (json['price_paise'] as num?)?.toInt() ??
        (((json['price'] as num?)?.toDouble() ?? 25.0) * 100).round();

    final stock = (json['stock_qty'] as num?)?.toDouble() ??
        (json['stock'] as num?)?.toDouble() ??
        0.0;

    return ProduceListing(
      id: json['id']?.toString() ?? '',
      farmerId: json['farmer_id']?.toString() ?? '',
      farmerName: json['farmer_name']?.toString() ?? 'Verified Farmer',
      farmName: json['farm_name']?.toString() ?? 'Greenfield Organic Farm',
      clusterVillage: json['cluster_village']?.toString() ?? 'Mandya Cluster',
      farmerAvatarPath: json['farmer_avatar_path']?.toString(),
      isVerifiedFarmer: json['is_verified_farmer'] == true || json['is_verified'] == true,
      name: json['name']?.toString() ?? 'Produce Item',
      category: json['category']?.toString() ?? 'vegetable',
      description: json['description']?.toString() ?? '',
      pricePaise: pPaise,
      unit: json['unit']?.toString() ?? 'kg',
      stockQty: stock,
      lowStockThreshold: (json['low_stock_threshold'] as num?)?.toDouble() ?? 10.0,
      status: ProduceStatus.fromString(json['status']?.toString()),
      harvestAt: DateTime.tryParse(json['harvest_at']?.toString() ?? ''),
      qualityNotes: json['quality_notes']?.toString() ?? '',
      farmingMethod: json['farming_method']?.toString() ?? 'Organic',
      images: imgList,
      deliveryAvailable: json['delivery_available'] != false,
      pickupAvailable: json['pickup_available'] != false,
      availabilityMode: AvailabilityMode.fromString(json['availability_mode']?.toString()),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'farmer_id': farmerId,
        'name': name,
        'category': category,
        'description': description,
        'price_paise': pricePaise,
        'unit': unit,
        'stock_qty': stockQty,
        'low_stock_threshold': lowStockThreshold,
        'status': status.dbValue,
        'harvest_at': harvestAt?.toIso8601String(),
        'quality_notes': qualityNotes,
        'farming_method': farmingMethod,
        'images': images,
        'delivery_available': deliveryAvailable,
        'pickup_available': pickupAvailable,
        'availability_mode': availabilityMode.dbValue,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  ProduceListing copyWith({
    String? name,
    String? category,
    String? description,
    int? pricePaise,
    String? unit,
    double? stockQty,
    double? lowStockThreshold,
    ProduceStatus? status,
    DateTime? harvestAt,
    String? qualityNotes,
    String? farmingMethod,
    List<String>? images,
    bool? deliveryAvailable,
    bool? pickupAvailable,
    AvailabilityMode? availabilityMode,
  }) {
    return ProduceListing(
      id: id,
      farmerId: farmerId,
      farmerName: farmerName,
      farmName: farmName,
      clusterVillage: clusterVillage,
      farmerAvatarPath: farmerAvatarPath,
      isVerifiedFarmer: isVerifiedFarmer,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      pricePaise: pricePaise ?? this.pricePaise,
      unit: unit ?? this.unit,
      stockQty: stockQty ?? this.stockQty,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      status: status ?? this.status,
      harvestAt: harvestAt ?? this.harvestAt,
      qualityNotes: qualityNotes ?? this.qualityNotes,
      farmingMethod: farmingMethod ?? this.farmingMethod,
      images: images ?? this.images,
      deliveryAvailable: deliveryAvailable ?? this.deliveryAvailable,
      pickupAvailable: pickupAvailable ?? this.pickupAvailable,
      availabilityMode: availabilityMode ?? this.availabilityMode,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
