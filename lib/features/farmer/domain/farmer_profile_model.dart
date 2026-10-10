import 'package:flutter/foundation.dart';

@immutable
class FarmInfrastructureBadges {
  final String? soilClassification;
  final String? primaryCrops;
  final String? farmingMethod;
  final String? apmcRegistration;
  final String? kisanCreditCardStatus;
  final bool isKccVerified;
  final double deliveryRadiusKm;
  final bool pickupAvailable;
  final int leadTimeHours;
  final String? farmPhotoUrl;

  const FarmInfrastructureBadges({
    this.soilClassification,
    this.primaryCrops,
    this.farmingMethod,
    this.apmcRegistration,
    this.kisanCreditCardStatus,
    bool isKccVerified = false,
    bool? isKccApproved,
    this.deliveryRadiusKm = 25.0,
    this.pickupAvailable = true,
    this.leadTimeHours = 24,
    this.farmPhotoUrl,
  }) : isKccVerified = isKccApproved ?? isKccVerified;

  bool get isKccApproved => isKccVerified;

  factory FarmInfrastructureBadges.fromJson(Map<String, dynamic> json) {
    return FarmInfrastructureBadges(
      soilClassification: json['soil_classification']?.toString(),
      primaryCrops: json['primary_crops'] is List
          ? (json['primary_crops'] as List).join(', ')
          : json['primary_crops']?.toString(),
      farmingMethod: json['farming_method']?.toString(),
      apmcRegistration: json['apmc_registration']?.toString(),
      kisanCreditCardStatus: json['kcc_status']?.toString(),
      isKccVerified: json['is_kcc_verified'] == true,
      deliveryRadiusKm: (json['delivery_radius_km'] as num?)?.toDouble() ?? 25.0,
      pickupAvailable: json['pickup_available'] != false,
      leadTimeHours: (json['lead_time_hours'] as num?)?.toInt() ?? 24,
      farmPhotoUrl: json['farm_photo_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'soil_classification': soilClassification,
        'primary_crops': primaryCrops,
        'farming_method': farmingMethod,
        'apmc_registration': apmcRegistration,
        'kcc_status': kisanCreditCardStatus,
        'is_kcc_verified': isKccVerified,
        'delivery_radius_km': deliveryRadiusKm,
        'pickup_available': pickupAvailable,
        'lead_time_hours': leadTimeHours,
        'farm_photo_url': farmPhotoUrl,
      };
}

@immutable
class OrganicCertificate {
  final String? title;
  final String? issuer;
  final String statusLabel; // 'VERIFIED', 'SELF_DECLARED', 'NOT_PROVIDED'
  final bool isValidatedByAdmin;
  final String? certificateNumber;
  final String? documentPath;
  final DateTime? validUntil;

  const OrganicCertificate({
    this.title,
    this.issuer,
    this.statusLabel = 'Self-declared, not verified yet',
    bool isValidatedByAdmin = false,
    bool? isValidated,
    this.certificateNumber,
    this.documentPath,
    this.validUntil,
  }) : isValidatedByAdmin = isValidated ?? isValidatedByAdmin;

  bool get isValidated => isValidatedByAdmin;

  bool get hasCertificate =>
      certificateNumber != null && certificateNumber!.trim().isNotEmpty;

  factory OrganicCertificate.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString() ?? 'self_declared';
    final isAdminValidated = status.toLowerCase() == 'verified' ||
        status.toLowerCase() == 'validated';

    return OrganicCertificate(
      title: json['title']?.toString() ??
          (json['certificate_number'] != null ? 'Organic Certificate' : null),
      issuer: isAdminValidated
          ? (json['issuer']?.toString() ?? 'Admin Verified')
          : null,
      statusLabel: isAdminValidated
          ? 'VALIDATED ✓'
          : 'Self-declared, not verified yet',
      isValidatedByAdmin: isAdminValidated,
      certificateNumber: json['certificate_number']?.toString(),
      documentPath: json['document_path']?.toString(),
      validUntil: DateTime.tryParse(json['valid_until']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'issuer': issuer,
        'status': isValidatedByAdmin ? 'verified' : 'self_declared',
        'certificate_number': certificateNumber,
        'document_path': documentPath,
        'valid_until': validUntil?.toIso8601String(),
      };
}

@immutable
class FarmerProfileData {
  final String id;
  final String fullName;
  final String farmName;
  final String clusterVillage;
  final String phone;
  final String? avatarUrl;
  final bool isKycVerified;
  final double landAcres;
  final double produceSoldKgMonth;
  final int directSalesPaise;
  final FarmInfrastructureBadges badges;
  final OrganicCertificate certificate;

  const FarmerProfileData({
    required this.id,
    this.fullName = 'Farmer',
    this.farmName = 'My Farm',
    this.clusterVillage = 'Agri Cluster',
    this.phone = '',
    this.avatarUrl,
    bool isKycVerified = false,
    bool? isVerified,
    this.landAcres = 0.0,
    this.produceSoldKgMonth = 0.0,
    this.directSalesPaise = 0,
    this.badges = const FarmInfrastructureBadges(),
    this.certificate = const OrganicCertificate(),
  }) : isKycVerified = isVerified ?? isKycVerified;

  bool get isVerified => isKycVerified;
  double get directSalesRupees => directSalesPaise / 100.0;

  factory FarmerProfileData.fromJson(Map<String, dynamic> json) {
    return FarmerProfileData(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'Farmer',
      farmName: json['farm_name']?.toString() ?? 'My Farm',
      clusterVillage: json['cluster_village']?.toString() ?? 'Agri Cluster',
      phone: json['phone']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      isKycVerified: json['is_kyc_verified'] == true || json['is_verified'] == true,
      landAcres: (json['land_acres'] as num?)?.toDouble() ?? 0.0,
      produceSoldKgMonth: (json['produce_sold_kg_month'] as num?)?.toDouble() ?? 0.0,
      directSalesPaise: (json['direct_sales_paise'] as num?)?.toInt() ?? 0,
      badges: json['badges'] is Map<String, dynamic>
          ? FarmInfrastructureBadges.fromJson(json['badges'] as Map<String, dynamic>)
          : const FarmInfrastructureBadges(),
      certificate: json['certificate'] is Map<String, dynamic>
          ? OrganicCertificate.fromJson(json['certificate'] as Map<String, dynamic>)
          : const OrganicCertificate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'farm_name': farmName,
        'cluster_village': clusterVillage,
        'phone': phone,
        'avatar_url': avatarUrl,
        'is_kyc_verified': isKycVerified,
        'land_acres': landAcres,
        'produce_sold_kg_month': produceSoldKgMonth,
        'direct_sales_paise': directSalesPaise,
        'badges': badges.toJson(),
        'certificate': certificate.toJson(),
      };
}
