/// Domain model representing the result of a face verification check.
enum FaceCheckStatus {
  pass,
  fail,
  manualReviewRequired,
  error,
  cancelled,
}

class FaceCheckResult {
  final FaceCheckStatus status;
  final double? matchScore;
  final double? similarity;
  final double? threshold;
  final String? provider;
  final String? message;
  final String? diagnosticCode;
  final bool fraudFlagCreated;
  final int attemptsCount;
  final bool needsEnrollment;

  const FaceCheckResult({
    required this.status,
    this.matchScore,
    this.similarity,
    this.threshold,
    this.provider,
    this.message,
    this.diagnosticCode,
    this.fraudFlagCreated = false,
    this.attemptsCount = 0,
    this.needsEnrollment = false,
  });

  factory FaceCheckResult.fromJson(Map<String, dynamic> rawJson) {
    // 1. Unwrap envelope if wrapped inside { "success": true, "data": { ... } }
    Map<String, dynamic> data = rawJson;
    if (rawJson['data'] is Map<String, dynamic>) {
      data = rawJson['data'] as Map<String, dynamic>;
    } else if (rawJson['data'] is Map) {
      data = Map<String, dynamic>.from(rawJson['data'] as Map);
    }

    // 2. Handle error envelopes { "success": false, "error": { "code": "...", "message": "..." } }
    if (rawJson['success'] == false || data['success'] == false) {
      final errorMap = (data['error'] is Map ? data['error'] as Map : (rawJson['error'] is Map ? rawJson['error'] as Map : null));
      final errorCode = errorMap?['code']?.toString() ?? data['code']?.toString();
      final errorMsg = errorMap?['message']?.toString() ?? data['message']?.toString() ?? 'Verification failed';
      return FaceCheckResult(
        status: FaceCheckStatus.error,
        message: errorMsg,
        diagnosticCode: errorCode,
        needsEnrollment: errorCode == 'reference_photo_missing' || data['needs_enrollment'] == true,
      );
    }

    final rawResult = (data['result'] as String? ?? 'fail').toLowerCase();
    FaceCheckStatus status = FaceCheckStatus.fail;
    if (rawResult == 'pass') {
      status = FaceCheckStatus.pass;
    } else if (rawResult == 'manual_review_required') {
      status = FaceCheckStatus.manualReviewRequired;
    } else if (rawResult == 'error') {
      status = FaceCheckStatus.error;
    }

    return FaceCheckResult(
      status: status,
      matchScore: (data['match_score'] as num?)?.toDouble(),
      similarity: (data['similarity'] as num?)?.toDouble(),
      threshold: (data['threshold'] as num?)?.toDouble(),
      provider: data['provider'] as String?,
      message: data['message'] as String?,
      diagnosticCode: data['diagnostic_code'] as String? ?? data['code'] as String?,
      fraudFlagCreated: data['fraud_flag_created'] as bool? ?? false,
      attemptsCount: data['attempts_count'] as int? ?? 0,
      needsEnrollment: data['needs_enrollment'] as bool? ?? false,
    );
  }
}

