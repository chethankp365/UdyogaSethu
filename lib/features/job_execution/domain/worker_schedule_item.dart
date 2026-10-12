import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

@immutable
class WorkerScheduleItem {
  final String assignmentId;
  final String jobId;
  final String title;
  final String status;
  final String bookingCode;
  final int agreedWagePaise;
  final DateTime startAt;
  final DateTime endAt;
  final int estDurationMinutes;
  final String addressText;
  final double jobLat;
  final double jobLng;
  final String categorySlug;
  final String categoryIcon;
  final String providerName;
  final double? gapFromPrevMinutes;
  final double? gapToNextMinutes;
  final int estimatedTravelMinutes;

  const WorkerScheduleItem({
    required this.assignmentId,
    required this.jobId,
    required this.title,
    required this.status,
    required this.bookingCode,
    required this.agreedWagePaise,
    required this.startAt,
    required this.endAt,
    required this.estDurationMinutes,
    required this.addressText,
    required this.jobLat,
    required this.jobLng,
    required this.categorySlug,
    required this.categoryIcon,
    required this.providerName,
    this.gapFromPrevMinutes,
    this.gapToNextMinutes,
    this.estimatedTravelMinutes = 45,
  });

  int get agreedWageRupees => agreedWagePaise ~/ 100;

  LatLng get location => LatLng(jobLat, jobLng);

  /// True if this job starts before the previous job ends (negative gap).
  bool get isOverlap => gapFromPrevMinutes != null && gapFromPrevMinutes! < 0;

  /// True if the gap between the previous job and this job is shorter than the estimated travel time.
  bool get hasTravelWarning {
    if (isOverlap) return true;
    if (gapFromPrevMinutes != null) {
      return gapFromPrevMinutes! < estimatedTravelMinutes;
    }
    return false;
  }

  factory WorkerScheduleItem.fromJson(Map<String, dynamic> json) {
    final start = json['start_at'] != null
        ? (DateTime.tryParse(json['start_at'].toString()) ?? DateTime.now()).toLocal()
        : DateTime.now();
    final duration = (json['est_duration_minutes'] as num?)?.toInt() ?? 480;
    final end = json['end_at'] != null
        ? (DateTime.tryParse(json['end_at'].toString()) ?? start.add(Duration(minutes: duration))).toLocal()
        : start.add(Duration(minutes: duration));

    return WorkerScheduleItem(
      assignmentId: json['assignment_id'] as String? ?? json['id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      title: json['title'] as String? ?? 'General Work',
      status: json['status'] as String? ?? 'accepted',
      bookingCode: json['booking_code'] as String? ?? 'BOOK-DEMO',
      agreedWagePaise: (json['agreed_wage_paise'] as num?)?.toInt() ?? 60000,
      startAt: start,
      endAt: end,
      estDurationMinutes: duration,
      addressText: json['address_text'] as String? ?? '',
      jobLat: (json['job_lat'] as num?)?.toDouble() ?? (json['lat'] as num?)?.toDouble() ?? 0.0,
      jobLng: (json['job_lng'] as num?)?.toDouble() ?? (json['lng'] as num?)?.toDouble() ?? 0.0,
      categorySlug: json['category_slug'] as String? ?? 'general',
      categoryIcon: json['category_icon'] as String? ?? 'handyman',
      providerName: json['provider_name'] as String? ?? 'Employer',
      gapFromPrevMinutes: (json['gap_from_prev_minutes'] as num?)?.toDouble(),
      gapToNextMinutes: (json['gap_to_next_minutes'] as num?)?.toDouble(),
      estimatedTravelMinutes: (json['estimated_travel_minutes'] as num?)?.toInt() ?? 45,
    );
  }
}
