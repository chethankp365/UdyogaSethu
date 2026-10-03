import 'package:flutter/foundation.dart';

@immutable
class SeekerProfileDraft {
  final int currentStep;
  final String userId;
  final String fullName;
  final String? avatarPath;
  final String? avatarUrl;
  final String? gender;
  final List<String> languages;
  final List<String> selectedCategoryIds;
  final List<String> selectedSkillIds;
  final List<String> subjectsInterests;
  final double experienceYears;
  final int? dailyRatePaise;
  final int? hourlyRatePaise;
  final String availabilityStatus; // 'available', 'busy', 'offline'
  final List<String> workingDays;
  final Map<String, dynamic> workHoursJson;
  final Map<String, dynamic> preferredHoursJson;
  final double? latitude;
  final double? longitude;
  final String? homeAddress;
  final double serviceRadiusKm;
  final String seekerType; // 'informal', 'student', 'part_time'
  final String? collegeName;
  final String? courseName;
  final String? regNoMasked;
  final bool hasDrivingLicence;
  final bool onboardingComplete;

  const SeekerProfileDraft({
    this.currentStep = 1,
    required this.userId,
    this.fullName = '',
    this.avatarPath,
    this.avatarUrl,
    this.gender,
    this.languages = const ['kn'],
    this.selectedCategoryIds = const [],
    this.selectedSkillIds = const [],
    this.subjectsInterests = const [],
    this.experienceYears = 0.0,
    this.dailyRatePaise,
    this.hourlyRatePaise,
    this.availabilityStatus = 'available',
    this.workingDays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    this.workHoursJson = const {'start': '09:00', 'end': '18:00'},
    this.preferredHoursJson = const {'weekly_hours': 20},
    this.latitude,
    this.longitude,
    this.homeAddress,
    this.serviceRadiusKm = 10.0,
    this.seekerType = 'informal',
    this.collegeName,
    this.courseName,
    this.regNoMasked,
    this.hasDrivingLicence = false,
    this.onboardingComplete = false,
  });

  SeekerProfileDraft copyWith({
    int? currentStep,
    String? userId,
    String? fullName,
    String? avatarPath,
    String? avatarUrl,
    String? gender,
    List<String>? languages,
    List<String>? selectedCategoryIds,
    List<String>? selectedSkillIds,
    List<String>? subjectsInterests,
    double? experienceYears,
    int? dailyRatePaise,
    int? hourlyRatePaise,
    String? availabilityStatus,
    List<String>? workingDays,
    Map<String, dynamic>? workHoursJson,
    Map<String, dynamic>? preferredHoursJson,
    double? latitude,
    double? longitude,
    String? homeAddress,
    double? serviceRadiusKm,
    String? seekerType,
    String? collegeName,
    String? courseName,
    String? regNoMasked,
    bool? hasDrivingLicence,
    bool? onboardingComplete,
  }) {
    return SeekerProfileDraft(
      currentStep: currentStep ?? this.currentStep,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      avatarPath: avatarPath ?? this.avatarPath,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
      languages: languages ?? this.languages,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      selectedSkillIds: selectedSkillIds ?? this.selectedSkillIds,
      subjectsInterests: subjectsInterests ?? this.subjectsInterests,
      experienceYears: experienceYears ?? this.experienceYears,
      dailyRatePaise: dailyRatePaise ?? this.dailyRatePaise,
      hourlyRatePaise: hourlyRatePaise ?? this.hourlyRatePaise,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      workingDays: workingDays ?? this.workingDays,
      workHoursJson: workHoursJson ?? this.workHoursJson,
      preferredHoursJson: preferredHoursJson ?? this.preferredHoursJson,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      homeAddress: homeAddress ?? this.homeAddress,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
      seekerType: seekerType ?? this.seekerType,
      collegeName: collegeName ?? this.collegeName,
      courseName: courseName ?? this.courseName,
      regNoMasked: regNoMasked ?? this.regNoMasked,
      hasDrivingLicence: hasDrivingLicence ?? this.hasDrivingLicence,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  factory SeekerProfileDraft.fromJson(Map<String, dynamic> json) {
    return SeekerProfileDraft(
      currentStep: (json['wizard_step'] as num?)?.toInt() ?? 1,
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      avatarPath: json['avatar_path'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      gender: json['gender'] as String?,
      languages: (json['languages'] as List?)?.map((e) => e.toString()).toList() ?? ['kn'],
      selectedCategoryIds: (json['category_ids'] as List?)?.map((e) => e.toString()).toList() ?? [],
      selectedSkillIds: (json['skill_ids'] as List?)?.map((e) => e.toString()).toList() ?? [],
      subjectsInterests: (json['subjects_interests'] as List?)?.map((e) => e.toString()).toList() ?? [],
      experienceYears: (json['experience_years'] as num?)?.toDouble() ?? 0.0,
      dailyRatePaise: (json['daily_rate_paise'] as num?)?.toInt(),
      hourlyRatePaise: (json['hourly_rate_paise'] as num?)?.toInt(),
      availabilityStatus: json['availability'] as String? ?? 'available',
      workingDays: (json['working_days'] as List?)?.map((e) => e.toString()).toList() ?? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      workHoursJson: json['work_hours'] as Map<String, dynamic>? ?? {'start': '09:00', 'end': '18:00'},
      preferredHoursJson: json['preferred_hours'] as Map<String, dynamic>? ?? {'weekly_hours': 20},
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      homeAddress: json['home_address'] as String?,
      serviceRadiusKm: (json['service_radius_km'] as num?)?.toDouble() ?? 10.0,
      seekerType: json['seeker_type'] as String? ?? 'informal',
      collegeName: json['college_name'] as String?,
      courseName: json['course'] as String?,
      regNoMasked: json['reg_no_masked'] as String?,
      hasDrivingLicence: json['has_driving_licence'] as bool? ?? false,
      onboardingComplete: json['onboarding_complete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wizard_step': currentStep,
      'user_id': userId,
      'full_name': fullName,
      'avatar_path': avatarPath,
      'avatar_url': avatarUrl,
      'gender': gender,
      'languages': languages,
      'category_ids': selectedCategoryIds,
      'skill_ids': selectedSkillIds,
      'subjects_interests': subjectsInterests,
      'experience_years': experienceYears,
      'daily_rate_paise': dailyRatePaise,
      'hourly_rate_paise': hourlyRatePaise,
      'availability': availabilityStatus,
      'working_days': workingDays,
      'work_hours': workHoursJson,
      'preferred_hours': preferredHoursJson,
      'latitude': latitude,
      'longitude': longitude,
      'home_address': homeAddress,
      'service_radius_km': serviceRadiusKm,
      'seeker_type': seekerType,
      'college_name': collegeName,
      'course': courseName,
      'reg_no_masked': regNoMasked,
      'has_driving_licence': hasDrivingLicence,
      'onboarding_complete': onboardingComplete,
    };
  }

  /// Utility to format USN / Reg No masked (e.g., "1BM23CS108" -> "XXXXXXS108")
  static String maskRegNo(String regNo) {
    final clean = regNo.trim();
    if (clean.length <= 4) return clean;
    final lastFour = clean.substring(clean.length - 4);
    final maskedPrefix = 'X' * (clean.length - 4);
    return '$maskedPrefix$lastFour';
  }
}

class WageBandResult {
  final int minPaise;
  final int maxPaise;
  final String unit;

  const WageBandResult({
    required this.minPaise,
    required this.maxPaise,
    this.unit = 'day',
  });
}

class ServiceCategoryItem {
  final String id;
  final String slug;
  final Map<String, dynamic> names;
  final String? icon;
  final List<String> audience;

  const ServiceCategoryItem({
    required this.id,
    required this.slug,
    required this.names,
    this.icon,
    this.audience = const ['informal'],
  });

  bool matchesSeekerType(String? seekerType) {
    if (seekerType == 'student') {
      return audience.contains('student');
    } else if (seekerType == 'part_time') {
      return audience.contains('part_time') || audience.contains('student');
    }
    return audience.contains('informal') || audience.isEmpty;
  }

  String getLocalizedName(String langCode) {
    if (names.containsKey(langCode) && names[langCode].toString().isNotEmpty) {
      return names[langCode].toString();
    }
    return names['en']?.toString() ?? slug;
  }
}

class SkillItem {
  final String id;
  final String categoryId;
  final Map<String, dynamic> names;

  const SkillItem({
    required this.id,
    required this.categoryId,
    required this.names,
  });

  String getLocalizedName(String langCode) {
    if (names.containsKey(langCode) && names[langCode].toString().isNotEmpty) {
      return names[langCode].toString();
    }
    return names['en']?.toString() ?? 'Skill';
  }
}
