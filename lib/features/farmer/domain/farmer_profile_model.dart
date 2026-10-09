import 'package:flutter/foundation.dart';

@immutable
class FarmInfrastructureBadges {
  final String soilClassification;
  final String primaryCrops;
  final String apmcRegistration;
  final String kisanCreditCardStatus;
  final bool isKccApproved;

  const FarmInfrastructureBadges({
    this.soilClassification = 'Red Loam Soil (pH 6.8)',
    this.primaryCrops = 'Tomatoes, Paddy, Banana',
    this.apmcRegistration = 'Mandya APMC #4812',
    this.kisanCreditCardStatus = 'KCC Approved ✓',
    this.isKccApproved = true,
  });

  factory FarmInfrastructureBadges.fromJson(Map<String, dynamic> json) {
    return FarmInfrastructureBadges(
      soilClassification: json['soil_classification']?.toString() ?? 'Red Loam Soil (pH 6.8)',
      primaryCrops: json['primary_crops']?.toString() ?? 'Tomatoes, Paddy, Banana',
      apmcRegistration: json['apmc_registration']?.toString() ?? 'Mandya APMC #4812',
      kisanCreditCardStatus: json['kcc_status']?.toString() ?? 'KCC Approved ✓',
      isKccApproved: json['is_kcc_approved'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
        'soil_classification': soilClassification,
        'primary_crops': primaryCrops,
        'apmc_registration': apmcRegistration,
        'kcc_status': kisanCreditCardStatus,
        'is_kcc_approved': isKccApproved,
      };
}

@immutable
class OrganicCertificate {
  final String title;
  final String issuer;
  final String statusLabel; // 'VALIDATED ✓', 'UNDER REVIEW', 'SUBMITTED'
  final bool isValidated;
  final String? certificateNumber;
  final DateTime? validUntil;

  const OrganicCertificate({
    this.title = 'Zero-Pesticide Organic Certificate',
    this.issuer = 'Verified by Karnataka Organic Farmers Board',
    this.statusLabel = 'VALIDATED ✓',
    this.isValidated = true,
    this.certificateNumber = 'KOFB-ORG-2026-9812',
    this.validUntil,
  });

  factory OrganicCertificate.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString() ?? 'validated';
    final isValid = status.toLowerCase() == 'validated';
    return OrganicCertificate(
      title: json['title']?.toString() ?? 'Zero-Pesticide Organic Certificate',
      issuer: json['issuer']?.toString() ?? 'Verified by Karnataka Organic Farmers Board',
      statusLabel: isValid ? 'VALIDATED ✓' : 'UNDER REVIEW',
      isValidated: isValid,
      certificateNumber: json['certificate_number']?.toString(),
      validUntil: DateTime.tryParse(json['valid_until']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'issuer': issuer,
        'status': isValidated ? 'validated' : 'under_review',
        'certificate_number': certificateNumber,
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
  final bool isVerified;
  final double landAcres;
  final double produceSoldKgMonth;
  final int directSalesPaise;
  final FarmInfrastructureBadges badges;
  final OrganicCertificate certificate;

  const FarmerProfileData({
    required this.id,
    this.fullName = 'Chethan Gowda',
    this.farmName = 'Greenfield Organic Farm',
    this.clusterVillage = 'Mandya Cluster',
    this.phone = '+91 98450 77889',
    this.avatarUrl,
    this.isVerified = true,
    this.landAcres = 4.2,
    this.produceSoldKgMonth = 420.0,
    this.directSalesPaise = 4850000, // ₹48,500
    this.badges = const FarmInfrastructureBadges(),
    this.certificate = const OrganicCertificate(),
  });

  double get directSalesRupees => directSalesPaise / 100.0;

  factory FarmerProfileData.fromJson(Map<String, dynamic> json) {
    return FarmerProfileData(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'Chethan Gowda',
      farmName: json['farm_name']?.toString() ?? 'Greenfield Organic Farm',
      clusterVillage: json['cluster_village']?.toString() ?? 'Mandya Cluster',
      phone: json['phone']?.toString() ?? '+91 98450 77889',
      avatarUrl: json['avatar_url']?.toString(),
      isVerified: json['is_verified'] != false,
      landAcres: (json['land_acres'] as num?)?.toDouble() ?? 4.2,
      produceSoldKgMonth: (json['produce_sold_kg_month'] as num?)?.toDouble() ?? 420.0,
      directSalesPaise: (json['direct_sales_paise'] as num?)?.toInt() ?? 4850000,
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
        'is_verified': isVerified,
        'land_acres': landAcres,
        'produce_sold_kg_month': produceSoldKgMonth,
        'direct_sales_paise': directSalesPaise,
        'badges': badges.toJson(),
        'certificate': certificate.toJson(),
      };
}
