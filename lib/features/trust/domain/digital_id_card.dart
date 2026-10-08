/// Digital ID Card data entity representing a worker's on-screen ID card.
class DigitalIdCardData {
  final String userId;
  final String displayId;
  final String fullName;
  final String? avatarPath;
  final String roleName;
  final bool isVerifiedBadge;
  final int level;
  final String levelName;
  final String? qrToken;
  final DateTime? qrExpiresAt;
  final int qrExpiresInSeconds;

  const DigitalIdCardData({
    required this.userId,
    required this.displayId,
    required this.fullName,
    this.avatarPath,
    required this.roleName,
    required this.isVerifiedBadge,
    required this.level,
    required this.levelName,
    this.qrToken,
    this.qrExpiresAt,
    this.qrExpiresInSeconds = 300,
  });

  /// Generate a standard display ID like 'UDY2026A1B2' from user ID and registration year.
  static String formatDisplayId(String userId, [int? year]) {
    final y = year ?? DateTime.now().year;
    final clean = userId.replaceAll('-', '').toUpperCase();
    final suffix = clean.length >= 4 ? clean.substring(clean.length - 4) : clean.padLeft(4, '0');
    return 'UDY$y$suffix';
  }

  DigitalIdCardData copyWith({
    String? qrToken,
    DateTime? qrExpiresAt,
    int? qrExpiresInSeconds,
  }) {
    return DigitalIdCardData(
      userId: userId,
      displayId: displayId,
      fullName: fullName,
      avatarPath: avatarPath,
      roleName: roleName,
      isVerifiedBadge: isVerifiedBadge,
      level: level,
      levelName: levelName,
      qrToken: qrToken ?? this.qrToken,
      qrExpiresAt: qrExpiresAt ?? this.qrExpiresAt,
      qrExpiresInSeconds: qrExpiresInSeconds ?? this.qrExpiresInSeconds,
    );
  }
}

/// Public verification status returned when scanning a worker's QR code.
/// Notice: Contains strictly public non-PII fields. No real user ID, phone, or email.
class PublicVerificationResult {
  final bool valid;
  final String nameInitial;
  final String displayId;
  final bool isVerifiedBadge;
  final int level;
  final String levelName;
  final DateTime? kycVerifiedAt;
  final DateTime? faceVerifiedAt;
  final DateTime? trainingVerifiedAt;
  final DateTime? verifiedAt;
  final String? errorCode;
  final String? errorMessage;
  final String? purpose;
  final String? assignmentId;
  final String? bookingCode;
  final String? workerName;
  final String? jobTitle;

  const PublicVerificationResult({
    required this.valid,
    required this.nameInitial,
    required this.displayId,
    required this.isVerifiedBadge,
    required this.level,
    required this.levelName,
    this.kycVerifiedAt,
    this.faceVerifiedAt,
    this.trainingVerifiedAt,
    this.verifiedAt,
    this.errorCode,
    this.errorMessage,
    this.purpose,
    this.assignmentId,
    this.bookingCode,
    this.workerName,
    this.jobTitle,
  });

  factory PublicVerificationResult.fromJson(Map<String, dynamic> json) {
    return PublicVerificationResult(
      valid: json['valid'] == true,
      nameInitial: json['name_initial'] as String? ?? (json['worker_name'] != null ? '${json['worker_name'][0]}.' : 'U.'),
      displayId: json['display_id'] as String? ?? json['booking_code'] as String? ?? 'UDY2026****',
      isVerifiedBadge: json['is_verified_badge'] == true,
      level: (json['level'] as num?)?.toInt() ?? 1,
      levelName: json['level_name'] as String? ?? 'Starter',
      kycVerifiedAt: json['kyc_verified_at'] != null ? DateTime.tryParse(json['kyc_verified_at'].toString()) : null,
      faceVerifiedAt: json['face_verified_at'] != null ? DateTime.tryParse(json['face_verified_at'].toString()) : null,
      trainingVerifiedAt: json['training_verified_at'] != null ? DateTime.tryParse(json['training_verified_at'].toString()) : null,
      verifiedAt: json['verified_at'] != null ? DateTime.tryParse(json['verified_at'].toString()) : null,
      purpose: json['purpose'] as String?,
      assignmentId: json['assignment_id'] as String?,
      bookingCode: json['booking_code'] as String?,
      workerName: json['worker_name'] as String?,
      jobTitle: json['job_title'] as String?,
    );
  }

  factory PublicVerificationResult.error({
    required String code,
    required String message,
  }) {
    return PublicVerificationResult(
      valid: false,
      nameInitial: '?',
      displayId: 'UNKNOWN',
      isVerifiedBadge: false,
      level: 1,
      levelName: 'Unverified',
      errorCode: code,
      errorMessage: message,
    );
  }
}
