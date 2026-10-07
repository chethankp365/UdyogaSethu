import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

@immutable
class ProviderActiveBooking {
  final String assignmentId;
  final String jobId;
  final String bookingCode;
  final String jobTitle;
  final String roleName;
  final String workerId;
  final String workerName;
  final String? workerAvatar;
  final bool workerVerified;
  final String addressText;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final int escrowWagePaise;
  final String status;
  final DateTime? arrivedAt;
  final bool isWorkerLate;

  const ProviderActiveBooking({
    required this.assignmentId,
    required this.jobId,
    required this.bookingCode,
    required this.jobTitle,
    required this.roleName,
    required this.workerId,
    required this.workerName,
    this.workerAvatar,
    this.workerVerified = true,
    required this.addressText,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.escrowWagePaise,
    required this.status,
    this.arrivedAt,
    this.isWorkerLate = false,
  });

  factory ProviderActiveBooking.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val is String) {
        return DateTime.tryParse(val) ?? fallback;
      }
      return fallback;
    }

    final now = DateTime.now();
    return ProviderActiveBooking(
      assignmentId: json['assignment_id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      bookingCode: json['booking_code'] as String? ?? 'BOOK-7842',
      jobTitle: json['job_title'] as String? ?? 'Commercial Electrical Repair',
      roleName: json['role_name'] as String? ?? 'Electrician',
      workerId: json['worker_id'] as String? ?? '',
      workerName: json['worker_name'] as String? ?? 'Chethan Kumar',
      workerAvatar: json['worker_avatar'] as String?,
      workerVerified: json['worker_verified'] != false,
      addressText: json['address_text'] as String? ?? 'Koramangala 4th Block',
      scheduledStart: parseDate(json['scheduled_start'], now),
      scheduledEnd: parseDate(json['scheduled_end'], now.add(const Duration(hours: 8))),
      escrowWagePaise: (json['escrow_wage_paise'] as num?)?.toInt() ?? 88000,
      status: json['status'] as String? ?? 'accepted',
      arrivedAt: json['arrived_at'] != null ? DateTime.tryParse(json['arrived_at'].toString()) : null,
      isWorkerLate: json['is_worker_late'] == true,
    );
  }

  String get formattedEscrowWage {
    final rupees = (escrowWagePaise / 100).round();
    return '₹$rupees/day Escrow Held';
  }

  String get formattedScheduledTime {
    final timeStr = DateFormat('hh:mm a').format(scheduledStart);
    final isToday = scheduledStart.day == DateTime.now().day &&
        scheduledStart.month == DateTime.now().month &&
        scheduledStart.year == DateTime.now().year;

    if (isToday) {
      return 'Scheduled Today • $timeStr Shift';
    }
    final dateStr = DateFormat('MMM dd').format(scheduledStart);
    return '$dateStr • $timeStr Shift';
  }

  static ProviderActiveBooking demoBooking() {
    final now = DateTime.now();
    return ProviderActiveBooking(
      assignmentId: 'assign-demo-7842',
      jobId: 'job-demo-7842',
      bookingCode: 'BOOK-7842',
      jobTitle: 'Commercial Electrical Repair',
      roleName: 'Electrician',
      workerId: 'worker-demo-1',
      workerName: 'Chethan Kumar',
      workerVerified: true,
      addressText: 'Koramangala 4th Block',
      scheduledStart: DateTime(now.year, now.month, now.day, 9, 30),
      scheduledEnd: DateTime(now.year, now.month, now.day, 17, 30),
      escrowWagePaise: 88000,
      status: 'accepted',
      isWorkerLate: true,
    );
  }
}
