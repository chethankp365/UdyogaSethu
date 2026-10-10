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

    return JobEligibility(
      isEligible: json['is_eligible'] as bool? ?? true,
      reasonCode: json['reason_code'] as String?,
      licenceNeeded: json['licence_needed'] as bool? ?? false,
      hasLicence: json['has_licence'] as bool? ?? false,
      verifiedNeeded: json['verified_needed'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      studentGated: json['student_gated'] as bool? ?? false,
      scheduleOverlap: json['schedule_overlap'] as bool? ?? false,
      overlapJobTitle: json['overlap_job_title'] as String?,
      alreadyApplied: json['already_applied'] as bool? ?? false,
      isOwnJob: json['is_own_job'] as bool? ?? false,
      isPastStart: json['is_past_start'] as bool? ?? false,
      isSlotsFilled: json['is_slots_filled'] as bool? ?? false,
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

