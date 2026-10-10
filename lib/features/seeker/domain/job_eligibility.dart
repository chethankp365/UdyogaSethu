class JobEligibility {
  final bool isEligible;
  final String? reasonCode;
  final bool licenceNeeded;
  final bool hasLicence;
  final bool verifiedNeeded;
  final bool isVerified;
  final bool studentGated;
  final bool scheduleOverlap;
  final String? overlapJobTitle;
  final bool alreadyApplied;
  final bool isOwnJob;
  final bool isPastStart;
  final bool isSlotsFilled;
  final List<String> reasons;

  const JobEligibility({
    this.isEligible = true,
    this.reasonCode,
    this.licenceNeeded = false,
    this.hasLicence = false,
    this.verifiedNeeded = false,
    this.isVerified = false,
    this.studentGated = false,
    this.scheduleOverlap = false,
    this.overlapJobTitle,
    this.alreadyApplied = false,
    this.isOwnJob = false,
    this.isPastStart = false,
    this.isSlotsFilled = false,
    this.reasons = const [],
  });

  factory JobEligibility.fromJson(Map<String, dynamic> json) {
    final reasonsRaw = json['reasons'];
    final List<String> parsedReasons = [];
    if (reasonsRaw is List) {
      for (final r in reasonsRaw) {
        if (r != null) parsedReasons.add(r.toString());
      }
    }

    final reasonCode = json['reason_code'] as String?;
    final reasonsLower = parsedReasons.map((r) => r.toLowerCase()).toList();

    final isStudentGated = json['student_gated'] as bool? ??
        (reasonCode == 'AUDIENCE_MISMATCH' ||
            reasonsLower.any((r) => r.contains('reserved') || r.contains('audience') || r.contains('category')));

    final isOwnJob = json['is_own_job'] as bool? ??
        (reasonCode == 'OWN_JOB' || reasonsLower.any((r) => r.contains('own job')));

    final isPastStart = json['is_past_start'] as bool? ??
        (reasonCode == 'EXPIRED' || reasonsLower.any((r) => r.contains('passed') || r.contains('expired')));

    final isSlotsFilled = json['is_slots_filled'] as bool? ??
        (reasonCode == 'SLOTS_FILLED' || reasonsLower.any((r) => r.contains('slots') || r.contains('filled')));

    final isOverlap = json['schedule_overlap'] as bool? ??
        (reasonCode == 'SCHEDULE_CLASH' || reasonsLower.any((r) => r.contains('overlap') || r.contains('clash')));

    final isAlreadyApplied = json['already_applied'] as bool? ??
        (reasonCode == 'ALREADY_APPLIED' || reasonsLower.any((r) => r.contains('already applied')));

    final isLicenceNeeded = json['licence_needed'] as bool? ??
        (reasonCode == 'LICENCE_REQUIRED' || reasonsLower.any((r) => r.contains('licence')));

    final isVerifiedNeeded = json['verified_needed'] as bool? ??
        (reasonCode == 'VERIFIED_REQUIRED' || reasonsLower.any((r) => r.contains('verified')));

    final bool serverEligible = json['is_eligible'] as bool? ?? true;
    final bool isEligible = serverEligible &&
        !isStudentGated &&
        !isOwnJob &&
        !isPastStart &&
        !isSlotsFilled &&
        !isOverlap &&
        !isAlreadyApplied;

    return JobEligibility(
      isEligible: isEligible,
      reasonCode: reasonCode,
      licenceNeeded: isLicenceNeeded,
      hasLicence: json['has_licence'] as bool? ?? false,
      verifiedNeeded: isVerifiedNeeded,
      isVerified: json['is_verified'] as bool? ?? false,
      studentGated: isStudentGated,
      scheduleOverlap: isOverlap,
      overlapJobTitle: json['overlap_job_title'] as String?,
      alreadyApplied: isAlreadyApplied,
      isOwnJob: isOwnJob,
      isPastStart: isPastStart,
      isSlotsFilled: isSlotsFilled,
      reasons: parsedReasons,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_eligible': isEligible,
      'reason_code': reasonCode,
      'licence_needed': licenceNeeded,
      'has_licence': hasLicence,
      'verified_needed': verifiedNeeded,
      'is_verified': isVerified,
      'student_gated': studentGated,
      'schedule_overlap': scheduleOverlap,
      'overlap_job_title': overlapJobTitle,
      'already_applied': alreadyApplied,
      'is_own_job': isOwnJob,
      'is_past_start': isPastStart,
      'is_slots_filled': isSlotsFilled,
      'reasons': reasons,
    };
  }
}

