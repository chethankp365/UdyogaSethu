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
  final String? message;
  final bool fraudFlagCreated;
  final int attemptsCount;
  final bool needsEnrollment;

  const FaceCheckResult({
    required this.status,
    this.matchScore,
    this.similarity,
    this.threshold,
    this.message,
    this.fraudFlagCreated = false,
    this.attemptsCount = 0,
    this.needsEnrollment = false,
  });

  factory FaceCheckResult.fromJson(Map<String, dynamic> json) {
    final rawResult = (json['result'] as String? ?? 'fail').toLowerCase();
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
      matchScore: (json['match_score'] as num?)?.toDouble(),
      similarity: (json['similarity'] as num?)?.toDouble(),
      threshold: (json['threshold'] as num?)?.toDouble(),
      message: json['message'] as String?,
      fraudFlagCreated: json['fraud_flag_created'] as bool? ?? false,
      attemptsCount: json['attempts_count'] as int? ?? 0,
      needsEnrollment: json['needs_enrollment'] as bool? ?? false,
    );
  }
}
