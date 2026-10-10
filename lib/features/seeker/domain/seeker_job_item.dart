enum SeekerJobSegment {
  applied,
  accepted,
  active,
  completed,
  requests,
}

class SeekerJobItem {
  final String id;
  final String jobId;
  final String title;
  final String providerName;
  final bool providerVerified;
  final int wagePaise;
  final DateTime startAt;
  final int estDurationMinutes;
  final String status;
  final SeekerJobSegment segment;
  final String? bookingCode;
  final String categorySlug;
  final String categoryIcon;
  final String addressText;
  final String? message;
  final bool travelWarning;
  final double? gapMinutes;

  const SeekerJobItem({
    required this.id,
    required this.jobId,
    required this.title,
    required this.providerName,
    this.providerVerified = true,
    required this.wagePaise,
    required this.startAt,
    this.estDurationMinutes = 480,
    required this.status,
    required this.segment,
    this.bookingCode,
    this.categorySlug = 'general',
    this.categoryIcon = 'handyman',
    this.addressText = 'Workplace Location',
    this.message,
    this.travelWarning = false,
    this.gapMinutes,
  });

  int get wageRupees => wagePaise ~/ 100;

  String get durationDisplay {
    final hours = estDurationMinutes ~/ 60;
    final mins = estDurationMinutes % 60;
    if (mins == 0) return '$hours hrs';
    if (hours == 0) return '$mins mins';
    return '$hours h $mins m';
  }

  factory SeekerJobItem.fromJson(Map<String, dynamic> json, SeekerJobSegment segment) {
    return SeekerJobItem(
      id: json['id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'General Work',
      providerName: json['provider_name'] as String? ?? 'Verified Employer',
      providerVerified: json['provider_verified'] as bool? ?? true,
      wagePaise: (json['wage_paise'] as num?)?.toInt() ?? 60000,
      startAt: json['start_at'] != null
          ? DateTime.tryParse(json['start_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      estDurationMinutes: (json['est_duration_minutes'] as num?)?.toInt() ?? 480,
      status: json['status'] as String? ?? 'applied',
      segment: segment,
      bookingCode: json['booking_code'] as String?,
      categorySlug: json['category_slug'] as String? ?? 'general',
      categoryIcon: json['category_icon'] as String? ?? 'handyman',
      addressText: json['address_text'] as String? ?? 'Workplace Location',
      message: json['message'] as String?,
      travelWarning: json['travel_warning'] as bool? ?? false,
      gapMinutes: (json['gap_minutes'] as num?)?.toDouble(),
    );
  }

  SeekerJobItem copyWith({
    String? id,
    String? jobId,
    String? title,
    String? providerName,
    bool? providerVerified,
    int? wagePaise,
    DateTime? startAt,
    int? estDurationMinutes,
    String? status,
    SeekerJobSegment? segment,
    String? bookingCode,
    String? categorySlug,
    String? categoryIcon,
    String? addressText,
    String? message,
    bool? travelWarning,
    double? gapMinutes,
  }) {
    return SeekerJobItem(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      title: title ?? this.title,
      providerName: providerName ?? this.providerName,
      providerVerified: providerVerified ?? this.providerVerified,
      wagePaise: wagePaise ?? this.wagePaise,
      startAt: startAt ?? this.startAt,
      estDurationMinutes: estDurationMinutes ?? this.estDurationMinutes,
      status: status ?? this.status,
      segment: segment ?? this.segment,
      bookingCode: bookingCode ?? this.bookingCode,
      categorySlug: categorySlug ?? this.categorySlug,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      addressText: addressText ?? this.addressText,
      message: message ?? this.message,
      travelWarning: travelWarning ?? this.travelWarning,
      gapMinutes: gapMinutes ?? this.gapMinutes,
    );
  }
}
