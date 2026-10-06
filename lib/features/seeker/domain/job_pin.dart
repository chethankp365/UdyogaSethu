import 'package:latlong2/latlong.dart';

/// Domain entity representing a GPS map job pin and its corresponding listing item.
class JobPin {
  final String id;
  final String providerId;
  final String? categoryId;
  final String title;
  final String description;
  final String wageType;
  final int wagePaise;
  final DateTime? startAt;
  final int slotsTotal;
  final int slotsFilled;
  final String addressText;
  final double? distanceM;
  final double lat;
  final double lng;
  final String employerName;
  final String employerAvatar;
  final bool employerVerified;
  final double employerRating;
  final Map<String, dynamic> categoryName;
  final String categoryIcon;
  final String categorySlug;

  const JobPin({
    required this.id,
    required this.providerId,
    this.categoryId,
    required this.title,
    this.description = '',
    this.wageType = 'daily',
    required this.wagePaise,
    this.startAt,
    this.slotsTotal = 1,
    this.slotsFilled = 0,
    required this.addressText,
    this.distanceM,
    required this.lat,
    required this.lng,
    required this.employerName,
    this.employerAvatar = '',
    this.employerVerified = false,
    this.employerRating = 4.8,
    this.categoryName = const {},
    this.categoryIcon = 'work',
    this.categorySlug = 'general',
  });

  LatLng get latLng => LatLng(lat, lng);

  /// Compact price for the map pin (e.g., "₹700" or "Rs 700").
  String get pricePinText {
    final rupees = (wagePaise / 100).round();
    return '₹$rupees';
  }

  /// Formatted wage with rate unit (e.g., "₹880 / day" or "₹450 / hr").
  String get formattedWage {
    final rupees = (wagePaise / 100).round();
    switch (wageType.toLowerCase()) {
      case 'hourly':
        return '₹$rupees / hr';
      case 'daily':
        return '₹$rupees / day';
      case 'monthly':
        return '₹$rupees / mo';
      default:
        return '₹$rupees';
    }
  }

  /// Compact formatted distance string (e.g. "0.8 km away").
  String get formattedDistance {
    if (distanceM == null) return '';
    if (distanceM! < 1000) {
      return '${distanceM!.round()} m away';
    }
    final km = distanceM! / 1000.0;
    return '${km.toStringAsFixed(1)} km away';
  }

  /// Extract localized category name with fallback to English or title.
  String getLocalizedCategory(String langCode) {
    if (categoryName.containsKey(langCode)) {
      return categoryName[langCode].toString();
    }
    if (categoryName.containsKey('en')) {
      return categoryName['en'].toString();
    }
    return title;
  }

  factory JobPin.fromJson(Map<String, dynamic> json) {
    final rawCatName = json['category_name'];
    Map<String, dynamic> catMap = {};
    if (rawCatName is Map<String, dynamic>) {
      catMap = rawCatName;
    } else if (rawCatName is Map) {
      catMap = Map<String, dynamic>.from(rawCatName);
    }

    final rawLat = json['lat'];
    final rawLng = json['lng'];
    final latVal = (rawLat is num) ? rawLat.toDouble() : 12.9716;
    final lngVal = (rawLng is num) ? rawLng.toDouble() : 77.5946;

    final rawDistance = json['distance_m'];
    final distVal = (rawDistance is num) ? rawDistance.toDouble() : null;

    final rawRating = json['employer_rating'];
    final ratingVal = (rawRating is num) ? rawRating.toDouble() : 4.8;

    return JobPin(
      id: json['id']?.toString() ?? '',
      providerId: json['provider_id']?.toString() ?? '',
      categoryId: json['category_id']?.toString(),
      title: json['title']?.toString() ?? 'Daily Wage Work',
      description: json['description']?.toString() ?? '',
      wageType: json['wage_type']?.toString() ?? 'daily',
      wagePaise: (json['wage_paise'] as num?)?.toInt() ?? 65000,
      startAt: json['start_at'] != null ? DateTime.tryParse(json['start_at'].toString()) : null,
      slotsTotal: (json['slots_total'] as num?)?.toInt() ?? 1,
      slotsFilled: (json['slots_filled'] as num?)?.toInt() ?? 0,
      addressText: json['address_text']?.toString() ?? 'Bengaluru, Karnataka',
      distanceM: distVal,
      lat: latVal,
      lng: lngVal,
      employerName: json['employer_name']?.toString() ?? 'Direct Employer',
      employerAvatar: json['employer_avatar']?.toString() ?? '',
      employerVerified: json['employer_verified'] == true,
      employerRating: ratingVal,
      categoryName: catMap,
      categoryIcon: json['category_icon']?.toString() ?? 'work',
      categorySlug: json['category_slug']?.toString() ?? 'general',
    );
  }
}

/// Category chip for map filtering.
class CategoryFilterItem {
  final String? id; // null represents "All"
  final String slug;
  final Map<String, dynamic> names;
  final String icon;

  const CategoryFilterItem({
    this.id,
    required this.slug,
    this.names = const {},
    this.icon = 'work',
  });

  String getLocalizedName(String langCode) {
    if (names.containsKey(langCode)) {
      return names[langCode].toString();
    }
    if (names.containsKey('en')) {
      return names['en'].toString();
    }
    return slug;
  }
}
