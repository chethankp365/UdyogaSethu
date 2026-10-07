class UserAddress {
  final String id;
  final String userId;
  final String label;
  final String line1;
  final String? landmark;
  final String city;
  final String pincode;
  final double? lat;
  final double? lng;
  final bool isDefault;
  final DateTime? createdAt;

  const UserAddress({
    required this.id,
    required this.userId,
    required this.label,
    required this.line1,
    this.landmark,
    required this.city,
    required this.pincode,
    this.lat,
    this.lng,
    this.isDefault = false,
    this.createdAt,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      label: json['label'] as String? ?? 'Address',
      line1: json['line1'] as String? ?? '',
      landmark: json['landmark'] as String?,
      city: json['city'] as String? ?? 'Bengaluru',
      pincode: json['pincode'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'label': label,
    'line1': line1,
    'landmark': landmark,
    'city': city,
    'pincode': pincode,
    'lat': lat,
    'lng': lng,
    'is_default': isDefault,
  };

  String get formattedAddress {
    final parts = [
      line1,
      if (landmark != null && landmark!.isNotEmpty) landmark!,
      city,
      if (pincode.isNotEmpty) pincode,
    ];
    return parts.join(', ');
  }
}
