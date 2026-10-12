import 'package:flutter/foundation.dart';

@immutable
class JobPostDraft {
  final String? jobId; // null for new job, non-null for editing
  final String? categoryId;
  final String? categoryName;
  final String title;
  final String description;
  final String wageType; // 'daily', 'hourly', 'fixed'
  final int wagePaise;
  final int? minWagePaiseHint;
  final int? maxWagePaiseHint;
  final String wageBandUnit;
  final int estDurationMinutes;
  final DateTime startAt;
  final int slotsTotal;
  final bool materialsProvided;
  final String paymentMode; // 'cash', 'upi', 'escrow'
  final bool verifiedOnly;
  final bool licenceRequired;
  final bool studentsOk;
  final String addressText;
  final String landmark;
  final double? latitude;
  final double? longitude;
  final int geofenceRadiusM;
  final List<String> suitableFor; // 'informal', 'student', 'part_time'
  final String? sitePhotoUrl;
  final String? thumbnailPath;
  final int currentStep;

  const JobPostDraft({
    this.jobId,
    this.categoryId,
    this.categoryName,
    this.title = '',
    this.description = '',
    this.wageType = 'daily',
    this.wagePaise = 70000, // Default ₹700
    this.minWagePaiseHint,
    this.maxWagePaiseHint,
    this.wageBandUnit = 'day',
    this.estDurationMinutes = 480, // Default 8 hours
    required this.startAt,
    this.slotsTotal = 1,
    this.materialsProvided = false,
    this.paymentMode = 'escrow',
    this.verifiedOnly = false,
    this.licenceRequired = false,
    this.studentsOk = false,
    this.addressText = '',
    this.landmark = '',
    this.latitude,
    this.longitude,
    this.geofenceRadiusM = 150,
    this.suitableFor = const ['informal'],
    this.sitePhotoUrl,
    this.thumbnailPath,
    this.currentStep = 0,
  });

  bool get isBelowFairWage {
    if (minWagePaiseHint == null || wagePaise <= 0) return false;
    return wagePaise < minWagePaiseHint!;
  }

  bool get isAboveFairWage {
    if (maxWagePaiseHint == null || wagePaise <= 0) return false;
    return wagePaise > maxWagePaiseHint!;
  }

  double get wageInRupees => wagePaise / 100.0;
  double get minWageInRupees => (minWagePaiseHint ?? 0) / 100.0;
  double get maxWageInRupees => (maxWagePaiseHint ?? 0) / 100.0;

  Map<String, dynamic> get requirementsMap => {
        'verified_only': verifiedOnly,
        'licence_required': licenceRequired,
        'students_ok': studentsOk,
      };

  JobPostDraft copyWith({
    String? jobId,
    String? categoryId,
    String? categoryName,
    String? title,
    String? description,
    String? wageType,
    int? wagePaise,
    int? minWagePaiseHint,
    int? maxWagePaiseHint,
    String? wageBandUnit,
    int? estDurationMinutes,
    DateTime? startAt,
    int? slotsTotal,
    bool? materialsProvided,
    String? paymentMode,
    bool? verifiedOnly,
    bool? licenceRequired,
    bool? studentsOk,
    String? addressText,
    String? landmark,
    double? latitude,
    double? longitude,
    int? geofenceRadiusM,
    List<String>? suitableFor,
    String? sitePhotoUrl,
    String? thumbnailPath,
    int? currentStep,
  }) {
    return JobPostDraft(
      jobId: jobId ?? this.jobId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      title: title ?? this.title,
      description: description ?? this.description,
      wageType: wageType ?? this.wageType,
      wagePaise: wagePaise ?? this.wagePaise,
      minWagePaiseHint: minWagePaiseHint ?? this.minWagePaiseHint,
      maxWagePaiseHint: maxWagePaiseHint ?? this.maxWagePaiseHint,
      wageBandUnit: wageBandUnit ?? this.wageBandUnit,
      estDurationMinutes: estDurationMinutes ?? this.estDurationMinutes,
      startAt: startAt ?? this.startAt,
      slotsTotal: slotsTotal ?? this.slotsTotal,
      materialsProvided: materialsProvided ?? this.materialsProvided,
      paymentMode: paymentMode ?? this.paymentMode,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      licenceRequired: licenceRequired ?? this.licenceRequired,
      studentsOk: studentsOk ?? this.studentsOk,
      addressText: addressText ?? this.addressText,
      landmark: landmark ?? this.landmark,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geofenceRadiusM: geofenceRadiusM ?? this.geofenceRadiusM,
      suitableFor: suitableFor ?? this.suitableFor,
      sitePhotoUrl: sitePhotoUrl ?? this.sitePhotoUrl,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}
