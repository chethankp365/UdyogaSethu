class JobTicketData {
  final String assignmentId;
  final String bookingCode;
  final String status;
  final String jobId;
  final String jobTitle;
  final String categoryName;
  final String categoryIcon;
  final DateTime startAt;
  final int estDurationMinutes;
  final int agreedWagePaise;
  final String wageType;
  final String paymentMode;
  final String? addressText;
  final double? lat;
  final double? lng;
  final String workerId;
  final String workerName;
  final String? workerAvatar;
  final bool isWorkerVerified;
  final String? workerSeekerType;
  final String providerId;
  final String providerName;
  final String? qrToken;
  final DateTime? qrExpiresAt;
  final int qrExpiresInSeconds;

  const JobTicketData({
    required this.assignmentId,
    required this.bookingCode,
    required this.status,
    required this.jobId,
    required this.jobTitle,
    required this.categoryName,
    required this.categoryIcon,
    required this.startAt,
    required this.estDurationMinutes,
    required this.agreedWagePaise,
    required this.wageType,
    required this.paymentMode,
    this.addressText,
    this.lat,
    this.lng,
    required this.workerId,
    required this.workerName,
    this.workerAvatar,
    required this.isWorkerVerified,
    this.workerSeekerType,
    required this.providerId,
    required this.providerName,
    this.qrToken,
    this.qrExpiresAt,
    this.qrExpiresInSeconds = 120,
  });

  String get formattedWage => '₹${(agreedWagePaise / 100).toStringAsFixed(0)}';

  bool get isQrExpired {
    if (qrExpiresAt == null) return true;
    return DateTime.now().isAfter(qrExpiresAt!);
  }

  JobTicketData copyWith({
    String? qrToken,
    DateTime? qrExpiresAt,
    int? qrExpiresInSeconds,
    String? status,
  }) {
    return JobTicketData(
      assignmentId: assignmentId,
      bookingCode: bookingCode,
      status: status ?? this.status,
      jobId: jobId,
      jobTitle: jobTitle,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      startAt: startAt,
      estDurationMinutes: estDurationMinutes,
      agreedWagePaise: agreedWagePaise,
      wageType: wageType,
      paymentMode: paymentMode,
      addressText: addressText,
      lat: lat,
      lng: lng,
      workerId: workerId,
      workerName: workerName,
      workerAvatar: workerAvatar,
      isWorkerVerified: isWorkerVerified,
      workerSeekerType: workerSeekerType,
      providerId: providerId,
      providerName: providerName,
      qrToken: qrToken ?? this.qrToken,
      qrExpiresAt: qrExpiresAt ?? this.qrExpiresAt,
      qrExpiresInSeconds: qrExpiresInSeconds ?? this.qrExpiresInSeconds,
    );
  }

  factory JobTicketData.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic d) {
      if (d is DateTime) return d;
      if (d is String) {
        return DateTime.tryParse(d) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return JobTicketData(
      assignmentId: json['assignment_id'] as String? ?? json['id'] as String? ?? '',
      bookingCode: json['booking_code'] as String? ?? 'BOOK-000000',
      status: json['status'] as String? ?? 'ticket_issued',
      jobId: json['job_id'] as String? ?? '',
      jobTitle: json['job_title'] as String? ?? 'Job Assignment',
      categoryName: json['category_name'] as String? ?? 'General Services',
      categoryIcon: json['category_icon'] as String? ?? 'work',
      startAt: parseDate(json['start_at']),
      estDurationMinutes: (json['est_duration_minutes'] as num?)?.toInt() ?? 480,
      agreedWagePaise: (json['agreed_wage_paise'] as num?)?.toInt() ?? 0,
      wageType: json['wage_type'] as String? ?? 'daily',
      paymentMode: json['payment_mode'] as String? ?? 'escrow',
      addressText: json['address_text'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      workerId: json['worker_id'] as String? ?? '',
      workerName: json['worker_name'] as String? ?? 'Assigned Worker',
      workerAvatar: json['worker_avatar'] as String?,
      isWorkerVerified: json['is_worker_verified'] == true,
      workerSeekerType: json['worker_seeker_type'] as String?,
      providerId: json['provider_id'] as String? ?? '',
      providerName: json['provider_name'] as String? ?? 'Job Provider',
      qrToken: json['qr_token'] as String?,
      qrExpiresAt: json['qr_expires_at'] != null ? parseDate(json['qr_expires_at']) : null,
      qrExpiresInSeconds: (json['qr_expires_in_seconds'] as num?)?.toInt() ?? 120,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignment_id': assignmentId,
      'booking_code': bookingCode,
      'status': status,
      'job_id': jobId,
      'job_title': jobTitle,
      'category_name': categoryName,
      'category_icon': categoryIcon,
      'start_at': startAt.toIso8601String(),
      'est_duration_minutes': estDurationMinutes,
      'agreed_wage_paise': agreedWagePaise,
      'wage_type': wageType,
      'payment_mode': paymentMode,
      'address_text': addressText,
      'lat': lat,
      'lng': lng,
      'worker_id': workerId,
      'worker_name': workerName,
      'worker_avatar': workerAvatar,
      'is_worker_verified': isWorkerVerified,
      'worker_seeker_type': workerSeekerType,
      'provider_id': providerId,
      'provider_name': providerName,
      'qr_token': qrToken,
      'qr_expires_at': qrExpiresAt?.toIso8601String(),
      'qr_expires_in_seconds': qrExpiresInSeconds,
    };
  }
}

class AttendanceScanResult {
  final bool valid;
  final String purpose;
  final String status;
  final String? assignmentId;
  final String? bookingCode;
  final String? workerId;
  final String? workerName;
  final String? workerAvatar;
  final bool isVerifiedBadge;
  final String? jobTitle;
  final DateTime? arrivedAt;
  final String? message;
  final String? errorCode;
  final String? errorMessage;

  const AttendanceScanResult({
    required this.valid,
    required this.purpose,
    required this.status,
    this.assignmentId,
    this.bookingCode,
    this.workerId,
    this.workerName,
    this.workerAvatar,
    this.isVerifiedBadge = false,
    this.jobTitle,
    this.arrivedAt,
    this.message,
    this.errorCode,
    this.errorMessage,
  });

  factory AttendanceScanResult.error({
    required String code,
    required String message,
  }) {
    return AttendanceScanResult(
      valid: false,
      purpose: 'ticket',
      status: 'error',
      errorCode: code,
      errorMessage: message,
    );
  }

  factory AttendanceScanResult.fromJson(Map<String, dynamic> json) {
    DateTime? arrived;
    if (json['arrived_at'] != null) {
      arrived = DateTime.tryParse(json['arrived_at'].toString());
    }

    return AttendanceScanResult(
      valid: json['valid'] == true,
      purpose: json['purpose'] as String? ?? 'ticket',
      status: json['status'] as String? ?? 'arrived',
      assignmentId: json['assignment_id'] as String?,
      bookingCode: json['booking_code'] as String?,
      workerId: json['worker_id'] as String?,
      workerName: json['worker_name'] as String?,
      workerAvatar: json['worker_avatar'] as String?,
      isVerifiedBadge: json['is_verified_badge'] == true,
      jobTitle: json['job_title'] as String?,
      arrivedAt: arrived,
      message: json['message'] as String?,
      errorCode: json['error_code'] as String?,
      errorMessage: json['error_message'] as String?,
    );
  }
}
