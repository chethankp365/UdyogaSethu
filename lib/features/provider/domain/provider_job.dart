import 'package:flutter/foundation.dart';

@immutable
class ProviderJob {
  final String id;
  final String providerId;
  final String? categoryId;
  final String categoryName;
  final String? categoryIcon;
  final String title;
  final String? description;
  final String wageType; // 'daily', 'hourly', 'fixed'
  final int wagePaise;
  final int estDurationMinutes;
  final DateTime startAt;
  final int slotsTotal;
  final int slotsFilled;
  final bool materialsProvided;
  final String paymentMode; // 'cash', 'upi', 'escrow'
  final Map<String, dynamic> requirements;
  final String? addressText;
  final int geofenceRadiusM;
  final String status; // 'draft', 'open', 'filled', 'closed', 'cancelled'
  final List<String> suitableFor; // 'informal', 'student', 'part_time'
  final String? sitePhotoUrl;
  final DateTime createdAt;
  final int applicantCount;
  final int hiredCount;

  const ProviderJob({
    required this.id,
    required this.providerId,
    this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    required this.title,
    this.description,
    this.wageType = 'daily',
    required this.wagePaise,
    this.estDurationMinutes = 480,
    required this.startAt,
    this.slotsTotal = 1,
    this.slotsFilled = 0,
    this.materialsProvided = false,
    this.paymentMode = 'escrow',
    this.requirements = const {},
    this.addressText,
    this.geofenceRadiusM = 150,
    this.status = 'open',
    this.suitableFor = const ['informal'],
    this.sitePhotoUrl,
    required this.createdAt,
    this.applicantCount = 0,
    this.hiredCount = 0,
  });

  int get slotsOpen => (slotsTotal - slotsFilled).clamp(0, slotsTotal);

  bool get isOpen => status == 'open' && slotsFilled < slotsTotal;
  bool get isFilled => status == 'filled' || (status == 'open' && slotsFilled >= slotsTotal);
  bool get isCompleted => status == 'closed';
  bool get isPaused => status == 'draft';
  bool get isCancelled => status == 'cancelled';

  bool get verifiedOnly => requirements['verified_only'] == true;
  bool get licenceRequired => requirements['licence_required'] == true;
  bool get studentsOk => requirements['students_ok'] == true;

  String get formattedWage {
    final rupees = (wagePaise / 100).toStringAsFixed(0);
    switch (wageType) {
      case 'hourly':
        return '₹$rupees/hr';
      case 'fixed':
        return '₹$rupees fixed';
      case 'daily':
      default:
        return '₹$rupees/day';
    }
  }

  factory ProviderJob.fromJson(Map<String, dynamic> json) {
    return ProviderJob(
      id: json['id'] as String? ?? '',
      providerId: json['provider_id'] as String? ?? '',
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String? ?? 'General',
      categoryIcon: json['category_icon'] as String?,
      title: json['title'] as String? ?? 'Untitled Job',
      description: json['description'] as String?,
      wageType: json['wage_type'] as String? ?? 'daily',
      wagePaise: (json['wage_paise'] as num?)?.toInt() ?? 0,
      estDurationMinutes: (json['est_duration_minutes'] as num?)?.toInt() ?? 480,
      startAt: json['start_at'] != null
          ? DateTime.tryParse(json['start_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      slotsTotal: (json['slots_total'] as num?)?.toInt() ?? 1,
      slotsFilled: (json['slots_filled'] as num?)?.toInt() ?? 0,
      materialsProvided: json['materials_provided'] as bool? ?? false,
      paymentMode: json['payment_mode'] as String? ?? 'escrow',
      requirements: json['requirements'] is Map
          ? Map<String, dynamic>.from(json['requirements'] as Map)
          : {},
      addressText: json['address_text'] as String?,
      geofenceRadiusM: (json['geofence_radius_m'] as num?)?.toInt() ?? 150,
      status: json['status'] as String? ?? 'open',
      suitableFor: json['suitable_for'] is List
          ? (json['suitable_for'] as List).map((e) => e.toString()).toList()
          : (json['requirements'] is Map && (json['requirements'] as Map)['students_ok'] == true
              ? const ['informal', 'student']
              : const ['informal']),
      sitePhotoUrl: json['site_photo_url'] as String? ?? json['photo_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      applicantCount: (json['applicant_count'] as num?)?.toInt() ?? 0,
      hiredCount: (json['hired_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'category_id': categoryId,
      'category_name': categoryName,
      'category_icon': categoryIcon,
      'title': title,
      'description': description,
      'wage_type': wageType,
      'wage_paise': wagePaise,
      'est_duration_minutes': estDurationMinutes,
      'start_at': startAt.toIso8601String(),
      'slots_total': slotsTotal,
      'slots_filled': slotsFilled,
      'materials_provided': materialsProvided,
      'payment_mode': paymentMode,
      'requirements': requirements,
      'address_text': addressText,
      'geofence_radius_m': geofenceRadiusM,
      'status': status,
      'suitable_for': suitableFor,
      'site_photo_url': sitePhotoUrl,
      'created_at': createdAt.toIso8601String(),
      'applicant_count': applicantCount,
      'hired_count': hiredCount,
    };
  }
}
