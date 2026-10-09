import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:udyogasethu/features/farmer/domain/produce_listing_model.dart';

@immutable
class ProduceMarketplaceItem {
  final String id;
  final String farmerId;
  final String farmerName;
  final String farmName;
  final String clusterVillage;
  final String? farmerAvatarPath;
  final bool isVerifiedFarmer;
  final double farmerRatingAvg;
  final int farmerRatingCount;
  final String name;
  final String category; // 'vegetable', 'dairy', 'fruit', 'grain', 'flower', 'other'
  final String description;
  final int pricePaise;
  final String unit;
  final double stockQty;
  final List<String> images;
  final double? lat;
  final double? lng;
  final double? distanceM;
  final DateTime? harvestAt;
  final String farmingMethod;
  final String qualityNotes;
  final bool deliveryAvailable;
  final bool pickupAvailable;
  final bool walkInStore;
  final bool organicCertified;
  final String certificationName;
  final String lotNumber;
  final ProduceStatus status;
  final DateTime createdAt;

  const ProduceMarketplaceItem({
    required this.id,
    required this.farmerId,
    this.farmerName = 'Verified Producer',
    this.farmName = 'Cauvery Bio Farm',
    this.clusterVillage = 'Mandya Agri Cluster',
    this.farmerAvatarPath,
    this.isVerifiedFarmer = true,
    this.farmerRatingAvg = 4.8,
    this.farmerRatingCount = 12,
    required this.name,
    this.category = 'vegetable',
    this.description = '',
    required this.pricePaise,
    this.unit = 'kg',
    required this.stockQty,
    this.images = const [],
    this.lat,
    this.lng,
    this.distanceM,
    this.harvestAt,
    this.farmingMethod = 'Natural IPNM',
    this.qualityNotes = 'Naturally ripened, sorted A-grade quality.',
    this.deliveryAvailable = true,
    this.pickupAvailable = true,
    this.walkInStore = false,
    this.organicCertified = false,
    this.certificationName = '',
    required this.lotNumber,
    this.status = ProduceStatus.active,
    required this.createdAt,
  });

  double get priceRupees => pricePaise / 100.0;
  String get formattedPrice => '₹${NumberFormat('#,##0').format(priceRupees.round())}/$unit';

  String get formattedStock {
    final qtyStr = stockQty.truncateToDouble() == stockQty
        ? stockQty.toInt().toString()
        : stockQty.toStringAsFixed(1);
    if (status == ProduceStatus.lowStock) {
      return 'Low Stock: $qtyStr $unit left';
    }
    return '$qtyStr $unit in stock';
  }

  bool get isInStock => stockQty > 0;
  bool get isActiveAndInStock =>
      (status == ProduceStatus.active || status == ProduceStatus.lowStock) && isInStock;

  String get formattedDistance {
    if (distanceM == null) return 'Location not set';
    if (distanceM! < 1000) {
      return '${distanceM!.round()} m away';
    }
    final km = distanceM! / 1000;
    return '${km.toStringAsFixed(1)} km away';
  }

  String get freshnessLabel {
    if (harvestAt == null) return 'Freshly Harvested';
    final now = DateTime.now();
    final diff = now.difference(harvestAt!);
    if (diff.inHours < 6) return 'Harvested < 6 hrs ago';
    if (diff.inHours < 24) return 'Harvested Today';
    if (diff.inDays == 1) return 'Harvested Yesterday';
    if (diff.inDays < 7) return 'Harvested ${diff.inDays} days ago';
    return DateFormat('dd MMM yyyy').format(harvestAt!);
  }

  IconData get categoryIcon {
    switch (category.toLowerCase()) {
      case 'dairy':
        return Icons.local_drink_rounded;
      case 'fruit':
        return Icons.apple_rounded;
      case 'grain':
        return Icons.grain_rounded;
      case 'flower':
        return Icons.local_florist_rounded;
      case 'vegetable':
      default:
        return Icons.eco_rounded;
    }
  }

  factory ProduceMarketplaceItem.fromJson(Map<String, dynamic> json) {
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

    final dist = (json['distance_m'] as num?)?.toDouble();
    final lat = (json['lat'] as num?)?.toDouble();
    final lng = (json['lng'] as num?)?.toDouble();

    return ProduceMarketplaceItem(
      id: json['id']?.toString() ?? '',
      farmerId: json['farmer_id']?.toString() ?? '',
      farmerName: json['farmer_name']?.toString() ?? 'Verified Producer',
      farmName: json['farm_name']?.toString() ?? 'Cauvery Bio Farm',
      clusterVillage: json['cluster_village']?.toString() ?? 'Mandya Agri Cluster',
      farmerAvatarPath: json['farmer_avatar_path']?.toString(),
      isVerifiedFarmer: json['is_verified_farmer'] == true || json['is_verified'] == true,
      farmerRatingAvg: (json['farmer_rating_avg'] as num?)?.toDouble() ?? 4.80,
      farmerRatingCount: (json['farmer_rating_count'] as num?)?.toInt() ?? 12,
      name: json['name']?.toString() ?? 'Farm Produce',
      category: json['category']?.toString() ?? 'vegetable',
      description: json['description']?.toString() ?? '',
      pricePaise: pPaise,
      unit: json['unit']?.toString() ?? 'kg',
      stockQty: stock,
      images: imgList,
      lat: lat,
      lng: lng,
      distanceM: dist,
      harvestAt: DateTime.tryParse(json['harvest_at']?.toString() ?? ''),
      farmingMethod: json['farming_method']?.toString() ?? 'Natural IPNM',
      qualityNotes: json['quality_notes']?.toString() ?? 'Sorted A-grade quality.',
      deliveryAvailable: json['delivery_available'] != false,
      pickupAvailable: json['pickup_available'] != false,
      walkInStore: json['walk_in_store'] == true,
      organicCertified: json['organic_certified'] == true,
      certificationName: json['certification_name']?.toString() ?? '',
      lotNumber: json['lot_number']?.toString() ?? 'LOT-${json['id']?.toString().substring(0, 8).toUpperCase() ?? '001'}',
      status: ProduceStatus.fromString(json['status']?.toString()),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmer_id': farmerId,
    'farmer_name': farmerName,
    'farm_name': farmName,
    'cluster_village': clusterVillage,
    'is_verified_farmer': isVerifiedFarmer,
    'farmer_rating_avg': farmerRatingAvg,
    'farmer_rating_count': farmerRatingCount,
    'name': name,
    'category': category,
    'description': description,
    'price_paise': pricePaise,
    'unit': unit,
    'stock_qty': stockQty,
    'images': images,
    'lat': lat,
    'lng': lng,
    'distance_m': distanceM,
    'harvest_at': harvestAt?.toIso8601String(),
    'farming_method': farmingMethod,
    'quality_notes': qualityNotes,
    'delivery_available': deliveryAvailable,
    'pickup_available': pickupAvailable,
    'walk_in_store': walkInStore,
    'organic_certified': organicCertified,
    'certification_name': certificationName,
    'lot_number': lotNumber,
    'status': status.dbValue,
    'created_at': createdAt.toIso8601String(),
  };
}
