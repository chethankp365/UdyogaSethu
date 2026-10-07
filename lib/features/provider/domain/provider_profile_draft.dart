import 'package:flutter/foundation.dart';

@immutable
class ProviderProfileDraft {
  final int currentStep;
  final String userId;
  final String fullName;
  final String? avatarPath;
  final String? avatarUrl;
  final List<String> languages;

  // Step 2: Provider Type
  final String providerType; // 'household' or 'employer'

  // Step 3: Household specific (Doorstep delivery address & preferences)
  final String addressLine1;
  final String landmark;
  final String city;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final String deliveryDropoffInstruction;
  final String? gateCode;

  // Step 4: Employer specific (Organization & Site details)
  final String orgName;
  final String siteAddressLine1;
  final String siteLandmark;
  final String siteCity;
  final String sitePincode;
  final double? siteLatitude;
  final double? siteLongitude;
  final List<String> categoriesHiring;
  final int typicalCrewSize;

  // Step 5: JIT Consents
  final bool gpsConsentGranted;
  final bool notificationsConsentGranted;

  final bool onboardingComplete;

  const ProviderProfileDraft({
    this.currentStep = 1,
    required this.userId,
    this.fullName = '',
    this.avatarPath,
    this.avatarUrl,
    this.languages = const ['kn'],
    this.providerType = 'household',
    this.addressLine1 = '',
    this.landmark = '',
    this.city = 'Bengaluru',
    this.pincode = '560001',
    this.latitude,
    this.longitude,
    this.deliveryDropoffInstruction = 'Leave at doorstep',
    this.gateCode,
    this.orgName = '',
    this.siteAddressLine1 = '',
    this.siteLandmark = '',
    this.siteCity = 'Bengaluru',
    this.sitePincode = '560001',
    this.siteLatitude,
    this.siteLongitude,
    this.categoriesHiring = const [],
    this.typicalCrewSize = 5,
    this.gpsConsentGranted = false,
    this.notificationsConsentGranted = false,
    this.onboardingComplete = false,
  });

  bool get isHousehold => providerType == 'household';
  bool get isEmployer => providerType == 'employer';
  String get siteAddress => [siteAddressLine1, siteLandmark].where((s) => s.isNotEmpty).join(', ');
  String get homeAddress => [addressLine1, landmark].where((s) => s.isNotEmpty).join(', ');

  ProviderProfileDraft copyWith({
    int? currentStep,
    String? userId,
    String? fullName,
    String? avatarPath,
    String? avatarUrl,
    List<String>? languages,
    String? providerType,
    String? addressLine1,
    String? landmark,
    String? city,
    String? pincode,
    double? latitude,
    double? longitude,
    String? deliveryDropoffInstruction,
    String? gateCode,
    String? orgName,
    String? siteAddressLine1,
    String? siteLandmark,
    String? siteCity,
    String? sitePincode,
    double? siteLatitude,
    double? siteLongitude,
    List<String>? categoriesHiring,
    int? typicalCrewSize,
    bool? gpsConsentGranted,
    bool? notificationsConsentGranted,
    bool? onboardingComplete,
  }) {
    return ProviderProfileDraft(
      currentStep: currentStep ?? this.currentStep,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      avatarPath: avatarPath ?? this.avatarPath,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      languages: languages ?? this.languages,
      providerType: providerType ?? this.providerType,
      addressLine1: addressLine1 ?? this.addressLine1,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      deliveryDropoffInstruction: deliveryDropoffInstruction ?? this.deliveryDropoffInstruction,
      gateCode: gateCode ?? this.gateCode,
      orgName: orgName ?? this.orgName,
      siteAddressLine1: siteAddressLine1 ?? this.siteAddressLine1,
      siteLandmark: siteLandmark ?? this.siteLandmark,
      siteCity: siteCity ?? this.siteCity,
      sitePincode: sitePincode ?? this.sitePincode,
      siteLatitude: siteLatitude ?? this.siteLatitude,
      siteLongitude: siteLongitude ?? this.siteLongitude,
      categoriesHiring: categoriesHiring ?? this.categoriesHiring,
      typicalCrewSize: typicalCrewSize ?? this.typicalCrewSize,
      gpsConsentGranted: gpsConsentGranted ?? this.gpsConsentGranted,
      notificationsConsentGranted: notificationsConsentGranted ?? this.notificationsConsentGranted,
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
      'providerType': providerType,
      'addressLine1': addressLine1,
      'landmark': landmark,
      'city': city,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'deliveryDropoffInstruction': deliveryDropoffInstruction,
      'gateCode': gateCode,
      'orgName': orgName,
      'siteAddressLine1': siteAddressLine1,
      'siteLandmark': siteLandmark,
      'siteCity': siteCity,
      'sitePincode': sitePincode,
      'siteLatitude': siteLatitude,
      'siteLongitude': siteLongitude,
      'categoriesHiring': categoriesHiring,
      'typicalCrewSize': typicalCrewSize,
      'gpsConsentGranted': gpsConsentGranted,
      'notificationsConsentGranted': notificationsConsentGranted,
      'onboardingComplete': onboardingComplete,
    };
  }

  factory ProviderProfileDraft.fromJson(Map<String, dynamic> json) {
    return ProviderProfileDraft(
      currentStep: (json['currentStep'] as num?)?.toInt() ?? 1,
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      avatarPath: json['avatarPath'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      languages: (json['languages'] as List?)?.map((e) => e.toString()).toList() ?? ['kn'],
      providerType: json['providerType'] as String? ?? 'household',
      addressLine1: json['addressLine1'] as String? ?? '',
      landmark: json['landmark'] as String? ?? '',
      city: json['city'] as String? ?? 'Bengaluru',
      pincode: json['pincode'] as String? ?? '560001',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      deliveryDropoffInstruction: json['deliveryDropoffInstruction'] as String? ?? 'Leave at doorstep',
      gateCode: json['gateCode'] as String?,
      orgName: json['orgName'] as String? ?? '',
      siteAddressLine1: json['siteAddressLine1'] as String? ?? '',
      siteLandmark: json['siteLandmark'] as String? ?? '',
      siteCity: json['siteCity'] as String? ?? 'Bengaluru',
      sitePincode: json['sitePincode'] as String? ?? '560001',
      siteLatitude: (json['siteLatitude'] as num?)?.toDouble(),
      siteLongitude: (json['siteLongitude'] as num?)?.toDouble(),
      categoriesHiring: (json['categoriesHiring'] as List?)?.map((e) => e.toString()).toList() ?? [],
      typicalCrewSize: (json['typicalCrewSize'] as num?)?.toInt() ?? 5,
      gpsConsentGranted: json['gpsConsentGranted'] as bool? ?? false,
      notificationsConsentGranted: json['notificationsConsentGranted'] as bool? ?? false,
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
    );
  }
}
