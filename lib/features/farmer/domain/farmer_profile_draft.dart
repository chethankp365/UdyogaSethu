import 'package:flutter/foundation.dart';

@immutable
class FarmerProfileDraft {
  final int currentStep;
  final String userId;
  final String fullName;
  final String? avatarPath;
  final String? avatarUrl;
  final List<String> languages;

  // Step 2: Farm
  final String farmName;
  final double? farmLatitude;
  final double? farmLongitude;
  final String clusterVillage;
  final double acres;
  final String soilType;
  final double? soilPh;
  final List<String> primaryCrops;
  final String farmingMethod; // 'organic', 'natural', 'conventional'

  // Step 3: Registrations
  final String? apmcRegistration;
  final String kccStatus; // 'none', 'applied', 'approved'
  final String organicCertStatus; // 'not_started', 'pending', 'verified', 'rejected'
  final String? organicCertPath;

  // Step 4: Selling Options
  final bool deliveryAvailable;
  final bool pickupAvailable;
  final double deliveryRadiusKm;
  final String leadTime;

  final bool onboardingComplete;

  const FarmerProfileDraft({
    this.currentStep = 1,
    required this.userId,
    this.fullName = '',
    this.avatarPath,
    this.avatarUrl,
    this.languages = const ['kn'],
    this.farmName = '',
    this.farmLatitude,
    this.farmLongitude,
    this.clusterVillage = '',
    this.acres = 1.0,
    this.soilType = 'Red Soil',
    this.soilPh,
    this.primaryCrops = const [],
    this.farmingMethod = '',
    this.apmcRegistration,
    this.kccStatus = 'none',
    this.organicCertStatus = 'not_started',
    this.organicCertPath,
    this.deliveryAvailable = true,
    this.pickupAvailable = true,
    this.deliveryRadiusKm = 15.0,
    this.leadTime = '1 day',
    this.onboardingComplete = false,
  });

  bool get hasApmcBadge => apmcRegistration != null && apmcRegistration!.trim().isNotEmpty;
  bool get hasKccBadge => kccStatus == 'approved' || kccStatus == 'applied';
  bool get hasOrganicBadge => organicCertStatus == 'pending' || organicCertStatus == 'verified';

  FarmerProfileDraft copyWith({
    int? currentStep,
    String? userId,
    String? fullName,
    String? avatarPath,
    String? avatarUrl,
    List<String>? languages,
    String? farmName,
    double? farmLatitude,
    double? farmLongitude,
    String? clusterVillage,
    double? acres,
    String? soilType,
    double? soilPh,
    List<String>? primaryCrops,
    String? farmingMethod,
    String? apmcRegistration,
    String? kccStatus,
    String? organicCertStatus,
    String? organicCertPath,
    bool? deliveryAvailable,
    bool? pickupAvailable,
    double? deliveryRadiusKm,
    String? leadTime,
    bool? onboardingComplete,
  }) {
    return FarmerProfileDraft(
      currentStep: currentStep ?? this.currentStep,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      avatarPath: avatarPath ?? this.avatarPath,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      languages: languages ?? this.languages,
      farmName: farmName ?? this.farmName,
      farmLatitude: farmLatitude ?? this.farmLatitude,
      farmLongitude: farmLongitude ?? this.farmLongitude,
      clusterVillage: clusterVillage ?? this.clusterVillage,
      acres: acres ?? this.acres,
      soilType: soilType ?? this.soilType,
      soilPh: soilPh ?? this.soilPh,
      primaryCrops: primaryCrops ?? this.primaryCrops,
      farmingMethod: farmingMethod ?? this.farmingMethod,
      apmcRegistration: apmcRegistration ?? this.apmcRegistration,
      kccStatus: kccStatus ?? this.kccStatus,
      organicCertStatus: organicCertStatus ?? this.organicCertStatus,
      organicCertPath: organicCertPath ?? this.organicCertPath,
      deliveryAvailable: deliveryAvailable ?? this.deliveryAvailable,
      pickupAvailable: pickupAvailable ?? this.pickupAvailable,
      deliveryRadiusKm: deliveryRadiusKm ?? this.deliveryRadiusKm,
      leadTime: leadTime ?? this.leadTime,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStep': currentStep,
      'userId': userId,
      'fullName': fullName,
      'avatarPath': avatarPath,
      'avatarUrl': avatarUrl,
      'languages': languages,
      'farmName': farmName,
      'farmLatitude': farmLatitude,
      'farmLongitude': farmLongitude,
      'clusterVillage': clusterVillage,
      'acres': acres,
      'soilType': soilType,
      'soilPh': soilPh,
      'primaryCrops': primaryCrops,
      'farmingMethod': farmingMethod,
      'apmcRegistration': apmcRegistration,
      'kccStatus': kccStatus,
      'organicCertStatus': organicCertStatus,
      'organicCertPath': organicCertPath,
      'deliveryAvailable': deliveryAvailable,
      'pickupAvailable': pickupAvailable,
      'deliveryRadiusKm': deliveryRadiusKm,
      'leadTime': leadTime,
      'onboardingComplete': onboardingComplete,
    };
  }

  factory FarmerProfileDraft.fromJson(Map<String, dynamic> json) {
    return FarmerProfileDraft(
      currentStep: (json['currentStep'] as num?)?.toInt() ?? 1,
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      avatarPath: json['avatarPath'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      languages: (json['languages'] as List?)?.map((e) => e.toString()).toList() ?? ['kn'],
      farmName: json['farmName'] as String? ?? '',
      farmLatitude: (json['farmLatitude'] as num?)?.toDouble(),
      farmLongitude: (json['farmLongitude'] as num?)?.toDouble(),
      clusterVillage: json['clusterVillage'] as String? ?? '',
      acres: (json['acres'] as num?)?.toDouble() ?? 1.0,
      soilType: json['soilType'] as String? ?? 'Red Soil',
      soilPh: (json['soilPh'] as num?)?.toDouble(),
      primaryCrops: (json['primaryCrops'] as List?)?.map((e) => e.toString()).toList() ?? [],
      farmingMethod: json['farmingMethod'] as String? ?? '',
      apmcRegistration: json['apmcRegistration'] as String?,
      kccStatus: json['kccStatus'] as String? ?? 'none',
      organicCertStatus: json['organicCertStatus'] as String? ?? 'not_started',
      organicCertPath: json['organicCertPath'] as String?,
      deliveryAvailable: json['deliveryAvailable'] as bool? ?? true,
      pickupAvailable: json['pickupAvailable'] as bool? ?? true,
      deliveryRadiusKm: (json['deliveryRadiusKm'] as num?)?.toDouble() ?? 15.0,
      leadTime: json['leadTime'] as String? ?? '1 day',
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
    );
  }
}
