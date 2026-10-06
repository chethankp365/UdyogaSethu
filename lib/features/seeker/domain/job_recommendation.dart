class JobRecommendation {
  final String id;
  final String providerId;
  final String? categoryId;
  final String title;
  final String? description;
  final String wageType;
  final int wagePaise;
  final int? estDurationMinutes;
  final DateTime? startAt;
  final int slotsTotal;
  final int slotsFilled;
  final String? addressText;
  final double distanceM;
  final String employerName;
  final String? employerAvatar;
  final bool employerVerified;
  final double employerRating;
  final Map<String, dynamic> categoryNames;
  final String categoryIcon;
  final String categorySlug;
  final bool isStudentFriendly;
  final bool isFlexibleShift;
  final double score;
  final List<String> reasons;

  const JobRecommendation({
    required this.id,
    required this.providerId,
    this.categoryId,
    required this.title,
    this.description,
    required this.wageType,
    required this.wagePaise,
    this.estDurationMinutes,
    this.startAt,
    this.slotsTotal = 1,
    this.slotsFilled = 0,
    this.addressText,
    this.distanceM = 1500.0,
    required this.employerName,
    this.employerAvatar,
    this.employerVerified = true,
    this.employerRating = 4.8,
    this.categoryNames = const {},
    this.categoryIcon = 'work',
    this.categorySlug = 'general',
    this.isStudentFriendly = false,
    this.isFlexibleShift = false,
    this.score = 50.0,
    this.reasons = const [],
  });

  factory JobRecommendation.fromJson(Map<String, dynamic> json) {
    List<String> parsedReasons = [];
    final rawReasons = json['reasons'];
    if (rawReasons is List) {
      parsedReasons = rawReasons.map((e) => e.toString()).toList();
    }

    Map<String, dynamic> names = {};
    if (json['category_name'] is Map) {
      names = Map<String, dynamic>.from(json['category_name'] as Map);
    }

    DateTime? parsedStartAt;
    if (json['start_at'] != null) {
      parsedStartAt = DateTime.tryParse(json['start_at'].toString());
    }

    return JobRecommendation(
      id: json['id'] as String? ?? '',
      providerId: json['provider_id'] as String? ?? '',
      categoryId: json['category_id'] as String?,
      title: json['title'] as String? ?? 'Open Job',
      description: json['description'] as String?,
      wageType: json['wage_type'] as String? ?? 'daily',
      wagePaise: (json['wage_paise'] as num?)?.toInt() ?? 0,
      estDurationMinutes: (json['est_duration_minutes'] as num?)?.toInt(),
      startAt: parsedStartAt,
      slotsTotal: (json['slots_total'] as num?)?.toInt() ?? 1,
      slotsFilled: (json['slots_filled'] as num?)?.toInt() ?? 0,
      addressText: json['address_text'] as String?,
      distanceM: (json['distance_m'] as num?)?.toDouble() ?? 1500.0,
      employerName: json['employer_name'] as String? ?? 'Local Employer',
      employerAvatar: json['employer_avatar'] as String?,
      employerVerified: json['employer_verified'] as bool? ?? true,
      employerRating: (json['employer_rating'] as num?)?.toDouble() ?? 4.8,
      categoryNames: names,
      categoryIcon: json['category_icon'] as String? ?? 'work',
      categorySlug: json['category_slug'] as String? ?? 'general',
      isStudentFriendly: json['is_student_friendly'] as bool? ?? false,
      isFlexibleShift: json['is_flexible_shift'] as bool? ?? false,
      score: (json['score'] as num?)?.toDouble() ?? 50.0,
      reasons: parsedReasons,
    );
  }

  String get formattedDistance {
    if (distanceM <= 0) return 'Nearby';
    final km = distanceM / 1000.0;
    if (km < 1.0) {
      return '${(km * 10).round() * 100} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  String get formattedWage {
    final rupees = (wagePaise / 100).round();
    if (wageType == 'hourly') {
      return '₹$rupees / hr';
    } else if (wageType == 'fixed') {
      return '₹$rupees';
    }
    return '₹$rupees';
  }

  String getLocalizedCategory(String langCode) {
    if (categoryNames.containsKey(langCode)) {
      return categoryNames[langCode].toString();
    }
    if (categoryNames.containsKey('en')) {
      return categoryNames['en'].toString();
    }
    return title;
  }
}

class SeekerHomeSummary {
  final int walletBalancePaise;
  final int todayEarningsPaise;
  final int dailyGoalPaise;

  const SeekerHomeSummary({
    this.walletBalancePaise = 0,
    this.todayEarningsPaise = 0,
    this.dailyGoalPaise = 150000,
  });

  factory SeekerHomeSummary.fromJson(Map<String, dynamic> json) {
    return SeekerHomeSummary(
      walletBalancePaise: (json['wallet_balance_paise'] as num?)?.toInt() ?? 0,
      todayEarningsPaise: (json['today_earnings_paise'] as num?)?.toInt() ?? 0,
      dailyGoalPaise: (json['daily_goal_paise'] as num?)?.toInt() ?? 150000,
    );
  }

  double get walletBalanceRupees => walletBalancePaise / 100.0;
  double get todayEarningsRupees => todayEarningsPaise / 100.0;
  double get dailyGoalRupees => dailyGoalPaise / 100.0;

  double get goalProgress {
    if (dailyGoalRupees <= 0) return 0.0;
    final progress = todayEarningsRupees / dailyGoalRupees;
    return progress.clamp(0.0, 1.0);
  }

  int get goalPercentage {
    if (dailyGoalRupees <= 0) return 0;
    final pct = ((todayEarningsRupees / dailyGoalRupees) * 100).round();
    return pct.clamp(0, 100);
  }
}

class SponsoredAdBanner {
  final String id;
  final String title;
  final String? body;
  final String? ctaLabel;
  final String? sponsorName;
  final String? whyText;
  final String? image;

  const SponsoredAdBanner({
    required this.id,
    required this.title,
    this.body,
    this.ctaLabel,
    this.sponsorName,
    this.whyText,
    this.image,
  });

  factory SponsoredAdBanner.fromJson(Map<String, dynamic> json) {
    return SponsoredAdBanner(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Sponsored Partner',
      body: json['body'] as String?,
      ctaLabel: json['cta_label'] as String? ?? 'Explore Offer',
      sponsorName: json['sponsor_name'] as String? ?? 'Verified Partner',
      whyText: json['why_text'] as String?,
      image: json['image'] as String?,
    );
  }
}
