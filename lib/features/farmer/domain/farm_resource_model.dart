import 'package:flutter/material.dart';

enum FarmResourceType {
  tractor,
  harvester,
  drone,
  seeds,
  fertilizer,
  coldStorage,
  labourEquipment;

  static FarmResourceType fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'tractor':
        return FarmResourceType.tractor;
      case 'harvester':
        return FarmResourceType.harvester;
      case 'drone':
        return FarmResourceType.drone;
      case 'seeds':
        return FarmResourceType.seeds;
      case 'fertilizer':
        return FarmResourceType.fertilizer;
      case 'cold_storage':
      case 'coldstorage':
        return FarmResourceType.coldStorage;
      case 'labour_equipment':
      case 'labourequipment':
        return FarmResourceType.labourEquipment;
      default:
        return FarmResourceType.tractor;
    }
  }

  String get dbValue {
    switch (this) {
      case FarmResourceType.tractor:
        return 'tractor';
      case FarmResourceType.harvester:
        return 'harvester';
      case FarmResourceType.drone:
        return 'drone';
      case FarmResourceType.seeds:
        return 'seeds';
      case FarmResourceType.fertilizer:
        return 'fertilizer';
      case FarmResourceType.coldStorage:
        return 'cold_storage';
      case FarmResourceType.labourEquipment:
        return 'labour_equipment';
    }
  }

  IconData get icon {
    switch (this) {
      case FarmResourceType.tractor:
        return Icons.agriculture_rounded;
      case FarmResourceType.harvester:
        return Icons.precision_manufacturing_rounded;
      case FarmResourceType.drone:
        return Icons.flight_takeoff_rounded;
      case FarmResourceType.seeds:
        return Icons.grain_rounded;
      case FarmResourceType.fertilizer:
        return Icons.eco_rounded;
      case FarmResourceType.coldStorage:
        return Icons.ac_unit_rounded;
      case FarmResourceType.labourEquipment:
        return Icons.handyman_rounded;
    }
  }

  Color get badgeColor {
    switch (this) {
      case FarmResourceType.tractor:
        return const Color(0xFFD97706);
      case FarmResourceType.harvester:
        return const Color(0xFFB45309);
      case FarmResourceType.drone:
        return const Color(0xFF0284C7);
      case FarmResourceType.seeds:
        return const Color(0xFF059669);
      case FarmResourceType.fertilizer:
        return const Color(0xFF10B981);
      case FarmResourceType.coldStorage:
        return const Color(0xFF2563EB);
      case FarmResourceType.labourEquipment:
        return const Color(0xFF7C3AED);
    }
  }
}

enum FarmResourceCategoryFilter {
  all,
  tractorsAndImplements,
  seedsAndBioFertilizers,
  coldStorage,
  dronesAndSpraying;

  bool matches(FarmResourceType type) {
    switch (this) {
      case FarmResourceCategoryFilter.all:
        return true;
      case FarmResourceCategoryFilter.tractorsAndImplements:
        return type == FarmResourceType.tractor ||
            type == FarmResourceType.harvester ||
            type == FarmResourceType.labourEquipment;
      case FarmResourceCategoryFilter.seedsAndBioFertilizers:
        return type == FarmResourceType.seeds ||
            type == FarmResourceType.fertilizer;
      case FarmResourceCategoryFilter.coldStorage:
        return type == FarmResourceType.coldStorage;
      case FarmResourceCategoryFilter.dronesAndSpraying:
        return type == FarmResourceType.drone;
    }
  }
}

class FarmResource {
  final String id;
  final String ownerId;
  final FarmResourceType type;
  final String name;
  final int pricePaise;
  final String unit;
  final List<String> images;
  final double distanceM;
  final double? lat;
  final double? lng;
  final String description;
  final String specs;
  final String addressText;
  final double ratingAvg;
  final int ratingCount;
  final bool verified;
  final String ownerName;
  final bool active;

  const FarmResource({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.name,
    required this.pricePaise,
    required this.unit,
    this.images = const [],
    this.distanceM = 0.0,
    this.lat,
    this.lng,
    this.description = '',
    this.specs = '',
    this.addressText = '',
    this.ratingAvg = 4.8,
    this.ratingCount = 12,
    this.verified = true,
    this.ownerName = 'Agri Service Vendor',
    this.active = true,
  });

  double get priceRupees => pricePaise / 100.0;

  String get formattedPrice {
    final rups = priceRupees;
    if (rups == rups.roundToDouble()) {
      return '₹${rups.toInt()}';
    }
    return '₹${rups.toStringAsFixed(1)}';
  }

  String get pricePerUnitDisplay => '$formattedPrice/$unit';

  String get distanceKmString {
    if (distanceM <= 0) return 'Nearby';
    final km = distanceM / 1000.0;
    return '${km.toStringAsFixed(1)} km away';
  }

  String get formattedRating => ratingAvg.toStringAsFixed(1);

  factory FarmResource.fromJson(Map<String, dynamic> json) {
    final rawImgs = json['images'];
    List<String> parsedImgs = [];
    if (rawImgs is List) {
      parsedImgs = rawImgs.map((e) => e.toString()).toList();
    }

    return FarmResource(
      id: json['id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      type: FarmResourceType.fromString(json['type'] as String?),
      name: json['name'] as String? ?? '',
      pricePaise: (json['price_paise'] as num?)?.toInt() ?? 0,
      unit: json['unit'] as String? ?? 'hr',
      images: parsedImgs,
      distanceM: (json['distance_m'] as num?)?.toDouble() ?? 0.0,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      description: json['description'] as String? ?? '',
      specs: json['specs'] as String? ?? '',
      addressText: json['address_text'] as String? ?? '',
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 4.8,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 12,
      verified: json['verified'] as bool? ?? true,
      ownerName: json['owner_name'] as String? ?? 'Agri Service Vendor',
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'type': type.dbValue,
      'name': name,
      'price_paise': pricePaise,
      'unit': unit,
      'images': images,
      'distance_m': distanceM,
      'lat': lat,
      'lng': lng,
      'description': description,
      'specs': specs,
      'address_text': addressText,
      'rating_avg': ratingAvg,
      'rating_count': ratingCount,
      'verified': verified,
      'owner_name': ownerName,
      'active': active,
    };
  }

  FarmResource copyWith({
    String? id,
    String? ownerId,
    FarmResourceType? type,
    String? name,
    int? pricePaise,
    String? unit,
    List<String>? images,
    double? distanceM,
    double? lat,
    double? lng,
    String? description,
    String? specs,
    String? addressText,
    double? ratingAvg,
    int? ratingCount,
    bool? verified,
    String? ownerName,
    bool? active,
  }) {
    return FarmResource(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      type: type ?? this.type,
      name: name ?? this.name,
      pricePaise: pricePaise ?? this.pricePaise,
      unit: unit ?? this.unit,
      images: images ?? this.images,
      distanceM: distanceM ?? this.distanceM,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      description: description ?? this.description,
      specs: specs ?? this.specs,
      addressText: addressText ?? this.addressText,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
      verified: verified ?? this.verified,
      ownerName: ownerName ?? this.ownerName,
      active: active ?? this.active,
    );
  }
}
