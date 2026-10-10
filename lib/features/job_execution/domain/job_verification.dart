/// Domain model representing the result of an assignment verification action
/// (two-step verified start, mid-job check, or completion with evidence).
class JobVerificationResult {
  final bool success;
  final String? status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int elapsedSeconds;
  final bool paymentEligible;
  final bool isMockedRejected;
  final bool isGeofenceRejected;
  final bool isFaceRejected;
  final bool isTooDarkRejected;
  final bool isManualReviewRequired;
  final double? distanceMeters;
  final int? radiusMeters;
  final String? errorCode;
  final String? errorMessage;
  final String? message;

  const JobVerificationResult({
    required this.success,
    this.status,
    this.startedAt,
    this.endedAt,
    this.elapsedSeconds = 0,
    this.paymentEligible = false,
    this.isMockedRejected = false,
    this.isGeofenceRejected = false,
    this.isFaceRejected = false,
    this.isTooDarkRejected = false,
    this.isManualReviewRequired = false,
    this.distanceMeters,
    this.radiusMeters,
    this.errorCode,
    this.errorMessage,
    this.message,
  });

  factory JobVerificationResult.success({
    required String status,
    DateTime? startedAt,
    DateTime? endedAt,
    int elapsedSeconds = 0,
    bool paymentEligible = false,
    String? message,
  }) {
    return JobVerificationResult(
      success: true,
      status: status,
      startedAt: startedAt,
      endedAt: endedAt,
      elapsedSeconds: elapsedSeconds,
      paymentEligible: paymentEligible,
      message: message,
    );
  }

  factory JobVerificationResult.successStart({
    required String status,
    double? distanceMeters,
    int elapsedSeconds = 0,
  }) {
    return JobVerificationResult(
      success: true,
      status: status,
      distanceMeters: distanceMeters,
      elapsedSeconds: elapsedSeconds,
    );
  }

  factory JobVerificationResult.successMidJob({
    required String status,
    double? distanceMeters,
  }) {
    return JobVerificationResult(
      success: true,
      status: status,
      distanceMeters: distanceMeters,
    );
  }

  factory JobVerificationResult.successCompletion({
    required String status,
    int elapsedSeconds = 0,
    bool paymentEligible = true,
  }) {
    return JobVerificationResult(
      success: true,
      status: status,
      elapsedSeconds: elapsedSeconds,
      paymentEligible: paymentEligible,
    );
  }

  factory JobVerificationResult.error({
    required String code,
    required String message,
    double? distanceMeters,
    int? radiusMeters,
    bool? isMockedRejected,
    bool? isGeofenceRejected,
    bool? isFaceRejected,
    bool? isTooDarkRejected,
    bool? isManualReviewRequired,
  }) {
    final lower = code.toLowerCase();
    final isMock = isMockedRejected ?? (lower == 'mock_location_rejected' || lower == 'mock_location');
    final isGeo = isGeofenceRejected ?? (lower == 'out_of_geofence' || lower == 'outside_geofence');
    final isFace = isFaceRejected ?? (lower == 'face_mismatch' || lower == 'face_verify_failed');
    final isDark = isTooDarkRejected ?? (lower == 'image_too_dark' || lower == 'too_dark');
    final isManual = isManualReviewRequired ?? (lower == 'manual_review_required' || lower == 'repeated_face_fail');

    return JobVerificationResult(
      success: false,
      errorCode: code,
      errorMessage: message,
      isMockedRejected: isMock,
      isGeofenceRejected: isGeo,
      isFaceRejected: isFace,
      isTooDarkRejected: isDark,
      isManualReviewRequired: isManual,
      distanceMeters: distanceMeters,
      radiusMeters: radiusMeters,
    );
  }

  factory JobVerificationResult.fromJson(Map<String, dynamic> json) {
    final success = json['success'] == true;
    if (!success) {
      final err = json['error'] as Map<String, dynamic>?;
      final code = err?['code']?.toString() ?? json['reason_code']?.toString() ?? json['code']?.toString() ?? 'error';
      final msg = err?['message']?.toString() ?? json['message']?.toString() ?? 'Verification failed';
      final details = err?['details'] as Map<String, dynamic>?;
      final dist = (details?['distance_meters'] as num?)?.toDouble() ?? (json['distance_meters'] as num?)?.toDouble();
      final rad = (details?['radius_meters'] as num?)?.toInt() ?? (json['radius_meters'] as num?)?.toInt();

      return JobVerificationResult.error(
        code: code,
        message: msg,
        distanceMeters: dist,
        radiusMeters: rad,
      );
    }

    DateTime? started;
    if (json['started_at'] != null) {
      started = DateTime.tryParse(json['started_at'].toString());
    }

    DateTime? ended;
    if (json['ended_at'] != null) {
      ended = DateTime.tryParse(json['ended_at'].toString());
    }

    return JobVerificationResult(
      success: true,
      status: json['status'] as String?,
      startedAt: started,
      endedAt: ended,
      elapsedSeconds: (json['elapsed_seconds'] as num?)?.toInt() ?? 0,
      paymentEligible: json['payment_eligible'] == true,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'status': status,
      'started_at': startedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'elapsed_seconds': elapsedSeconds,
      'payment_eligible': paymentEligible,
      'is_mocked_rejected': isMockedRejected,
      'is_geofence_rejected': isGeofenceRejected,
      'is_face_rejected': isFaceRejected,
      'is_too_dark_rejected': isTooDarkRejected,
      'is_manual_review_required': isManualReviewRequired,
      'distance_meters': distanceMeters,
      'radius_meters': radiusMeters,
      'error_code': errorCode,
      'error_message': errorMessage,
      'message': message,
    };
  }
}

/// Geofence check status for a job site.
class JobGeofenceStatus {
  final double distanceMeters;
  final int radiusMeters;
  final bool withinGeofence;

  const JobGeofenceStatus({
    required this.distanceMeters,
    required this.radiusMeters,
    required this.withinGeofence,
  });

  factory JobGeofenceStatus.fromJson(Map<String, dynamic> json) {
    return JobGeofenceStatus(
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0.0,
      radiusMeters: (json['radius_meters'] as num?)?.toInt() ?? 150,
      withinGeofence: json['within_geofence'] == true,
    );
  }
}
