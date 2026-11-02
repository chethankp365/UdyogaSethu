class JobDetail {
  final String id;
  final String providerId;
  final String providerName;
  final String? providerAvatar;
  final bool providerVerified;
  final double providerRating;
  final int providerReviewsCount;
  final bool backgroundVerified;
  final String title;
  final String description;
  final String? categoryId;
  final String categoryName;
  final String categorySlug;
  final String categoryIcon;
  final int wagePaise;
  final String wageType;
  final int estDurationMinutes;
  final DateTime startAt;
  final int slotsTotal;
  final int slotsFilled;
  final bool materialsProvided;
  final String paymentMode;
  final Map<String, dynamic> requirements;
  final String addressText;
  final double distanceKm;
  final int walkingMinutes;
  final String status;
  final String? sitePhotoUrl;
  final List<String> suitableFor;
  final String myApplicationStatus;
  final String? myAssignmentStatus;
  final String? myApplicationId;
  final String? myAssignmentId;
  final bool isDemo;

  const JobDetail({
    required this.id,
    required this.providerId,
    required this.providerName,
    this.providerAvatar,
    this.providerVerified = false,
    this.providerRating = 0.0,
    this.providerReviewsCount = 0,
    this.backgroundVerified = false,
    required this.title,
    required this.description,
    this.categoryId,
    this.categoryName = 'General Work',
    this.categorySlug = 'general',
    this.categoryIcon = 'handyman',
    required this.wagePaise,
    this.wageType = 'daily',
    this.estDurationMinutes = 480,
    required this.startAt,
    this.slotsTotal = 1,
    this.slotsFilled = 0,
    this.materialsProvided = false,
    this.paymentMode = 'escrow',
    this.requirements = const {},
    this.addressText = '',
    this.distanceKm = 0.0,
    this.walkingMinutes = 0,
    this.status = 'open',
    this.sitePhotoUrl,
    this.suitableFor = const ['informal'],
    this.myApplicationStatus = 'none',
    this.myAssignmentStatus,
    this.myApplicationId,
    this.myAssignmentId,
    this.isDemo = false,
  });

  int get slotsOpen => (slotsTotal - slotsFilled).clamp(0, slotsTotal);
  int get wageRupees => wagePaise ~/ 100;
  bool get studentsOk => requirements['students_ok'] == true;

  String get paymentModeDisplay {
    switch (paymentMode.toLowerCase()) {
      case 'cash':
        return 'Daily Cash';
      case 'escrow':
      default:
        return 'Daily Cash / Escrow';
    }
  }

  String get durationDisplay {
    final hours = estDurationMinutes ~/ 60;
    final mins = estDurationMinutes % 60;
    if (mins == 0) return '$hours hours';
    if (hours == 0) return '$mins minutes';
    return '$hours h $mins m';
  }

  factory JobDetail.fromJson(Map<String, dynamic> json) {
    return JobDetail(
      id: json['id'] as String? ?? '',
      providerId: json['provider_id'] as String? ?? '',
      providerName: json['provider_name'] as String? ?? 'Employer',
      providerAvatar: json['provider_avatar'] as String?,
      providerVerified: json['provider_verified'] as bool? ?? false,
      providerRating: (json['provider_rating'] as num?)?.toDouble() ?? 0.0,
      providerReviewsCount: (json['provider_reviews_count'] as num?)?.toInt() ?? 0,
      backgroundVerified: json['background_verified'] as bool? ?? false,
      title: json['title'] as String? ?? 'Daily Work',
      description: json['description'] as String? ?? '',
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String? ?? 'General Work',
      categorySlug: json['category_slug'] as String? ?? 'general',
      categoryIcon: json['category_icon'] as String? ?? 'handyman',
      wagePaise: (json['wage_paise'] as num?)?.toInt() ?? 0,
      wageType: json['wage_type'] as String? ?? 'daily',
      estDurationMinutes: (json['est_duration_minutes'] as num?)?.toInt() ?? 480,
      startAt: json['start_at'] != null
          ? DateTime.tryParse(json['start_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      slotsTotal: (json['slots_total'] as num?)?.toInt() ?? 1,
      slotsFilled: (json['slots_filled'] as num?)?.toInt() ?? 0,
      materialsProvided: json['materials_provided'] as bool? ?? false,
      paymentMode: json['payment_mode'] as String? ?? 'escrow',
      requirements: json['requirements'] is Map<String, dynamic>
          ? json['requirements'] as Map<String, dynamic>
          : (json['requirements'] is Map ? Map<String, dynamic>.from(json['requirements'] as Map) : {}),
      addressText: json['address_text'] as String? ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      walkingMinutes: (json['walking_minutes'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'open',
      sitePhotoUrl: json['thumbnail_path'] as String? ?? json['site_photo_url'] as String? ?? json['photo_url'] as String?,
      suitableFor: (json['suitable_for'] as List?)?.map((e) => e.toString()).toList() ??
          (json['requirements'] is Map && (json['requirements'] as Map)['students_ok'] == true
              ? const ['informal', 'student']
              : const ['informal']),
      myApplicationStatus: (json['my_application_status'] ?? json['application_status'] ?? 'none').toString(),
      myAssignmentStatus: (json['my_assignment_status'] ?? json['assignment_status'])?.toString(),
      myApplicationId: (json['my_application_id'] ?? json['application_id'])?.toString(),
      myAssignmentId: (json['my_assignment_id'] ?? json['assignment_id'])?.toString(),
      isDemo: json['is_demo'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'provider_name': providerName,
      'provider_avatar': providerAvatar,
      'provider_verified': providerVerified,
      'provider_rating': providerRating,
      'provider_reviews_count': providerReviewsCount,
      'background_verified': backgroundVerified,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'category_name': categoryName,
      'category_slug': categorySlug,
      'category_icon': categoryIcon,
      'wage_paise': wagePaise,
      'wage_type': wageType,
      'est_duration_minutes': estDurationMinutes,
      'start_at': startAt.toIso8601String(),
      'slots_total': slotsTotal,
      'slots_filled': slotsFilled,
      'materials_provided': materialsProvided,
      'payment_mode': paymentMode,
      'requirements': requirements,
      'address_text': addressText,
      'distance_km': distanceKm,
      'walking_minutes': walkingMinutes,
      'status': status,
      'is_demo': isDemo,
    };
  }
}
