class JobEligibility {
  final bool isEligible;
  final bool licenceNeeded;
  final bool hasLicence;
  final bool verifiedNeeded;
  final bool isVerified;
  final bool studentGated;
  final bool scheduleOverlap;
  final String? overlapJobTitle;
  final bool alreadyApplied;
  final List<String> reasons;

  const JobEligibility({
    this.isEligible = true,
    this.licenceNeeded = false,
    this.hasLicence = false,
    this.verifiedNeeded = false,
    this.isVerified = false,
    this.studentGated = false,
    this.scheduleOverlap = false,
    this.overlapJobTitle,
    this.alreadyApplied = false,
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
      licenceNeeded: json['licence_needed'] as bool? ?? false,
      hasLicence: json['has_licence'] as bool? ?? false,
      verifiedNeeded: json['verified_needed'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      studentGated: json['student_gated'] as bool? ?? false,
      scheduleOverlap: json['schedule_overlap'] as bool? ?? false,
      overlapJobTitle: json['overlap_job_title'] as String?,
      alreadyApplied: json['already_applied'] as bool? ?? false,
      reasons: parsedReasons,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_eligible': isEligible,
      'licence_needed': licenceNeeded,
      'has_licence': hasLicence,
      'verified_needed': verifiedNeeded,
      'is_verified': isVerified,
      'student_gated': studentGated,
      'schedule_overlap': scheduleOverlap,
      'overlap_job_title': overlapJobTitle,
      'already_applied': alreadyApplied,
      'reasons': reasons,
    };
  }
}
