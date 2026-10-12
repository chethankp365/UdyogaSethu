enum JobAppStatus {
  none,
  applied,
  shortlisted,
  hired,
  rejected,
  withdrawn;

  static JobAppStatus fromString(String? val) {
    if (val == null) return JobAppStatus.none;
    switch (val.toLowerCase().trim()) {
      case 'applied':
        return JobAppStatus.applied;
      case 'shortlisted':
        return JobAppStatus.shortlisted;
      case 'hired':
      case 'accepted':
        return JobAppStatus.hired;
      case 'rejected':
      case 'declined':
        return JobAppStatus.rejected;
      case 'withdrawn':
        return JobAppStatus.withdrawn;
      default:
        return JobAppStatus.none;
    }
  }

  String toDbString() {
    switch (this) {
      case JobAppStatus.applied:
        return 'applied';
      case JobAppStatus.shortlisted:
        return 'shortlisted';
      case JobAppStatus.hired:
        return 'hired';
      case JobAppStatus.rejected:
        return 'rejected';
      case JobAppStatus.withdrawn:
        return 'withdrawn';
      case JobAppStatus.none:
        return 'none';
    }
  }
}

class WorkerJobStatus {
  final String jobId;
  final JobAppStatus applicationStatus;
  final String? assignmentStatus;
  final String? applicationId;
  final String? assignmentId;
  final DateTime? appliedAt;
  final DateTime? updatedAt;

  const WorkerJobStatus({
    required this.jobId,
    this.applicationStatus = JobAppStatus.none,
    this.assignmentStatus,
    this.applicationId,
    this.assignmentId,
    this.appliedAt,
    this.updatedAt,
  });

  bool get isNone => applicationStatus == JobAppStatus.none;
  bool get isApplied => applicationStatus == JobAppStatus.applied;
  bool get isShortlisted => applicationStatus == JobAppStatus.shortlisted;
  bool get isHired =>
      applicationStatus == JobAppStatus.hired ||
      (assignmentStatus != null &&
          assignmentStatus != 'cancelled' &&
          assignmentStatus != 'requested');
  bool get isRejected => applicationStatus == JobAppStatus.rejected;
  bool get isWithdrawn => applicationStatus == JobAppStatus.withdrawn;
  bool get canWithdraw => (isApplied || isShortlisted) && !isHired;

  WorkerJobStatus copyWith({
    String? jobId,
    JobAppStatus? applicationStatus,
    String? assignmentStatus,
    String? applicationId,
    String? assignmentId,
    DateTime? appliedAt,
    DateTime? updatedAt,
  }) {
    return WorkerJobStatus(
      jobId: jobId ?? this.jobId,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      assignmentStatus: assignmentStatus ?? this.assignmentStatus,
      applicationId: applicationId ?? this.applicationId,
      assignmentId: assignmentId ?? this.assignmentId,
      appliedAt: appliedAt ?? this.appliedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory WorkerJobStatus.fromJson(Map<String, dynamic> json) {
    return WorkerJobStatus(
      jobId: (json['job_id'] ?? json['id'] ?? '').toString(),
      applicationStatus: JobAppStatus.fromString(
        (json['application_status'] ?? json['my_application_status'] ?? json['status'])?.toString(),
      ),
      assignmentStatus: (json['assignment_status'] ?? json['my_assignment_status'])?.toString(),
      applicationId: (json['application_id'] ?? json['my_application_id'])?.toString(),
      assignmentId: (json['assignment_id'] ?? json['my_assignment_id'])?.toString(),
      appliedAt: json['applied_at'] != null ? DateTime.tryParse(json['applied_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'job_id': jobId,
        'application_status': applicationStatus.toDbString(),
        'assignment_status': assignmentStatus,
        'application_id': applicationId,
        'assignment_id': assignmentId,
        'applied_at': appliedAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkerJobStatus &&
          runtimeType == other.runtimeType &&
          jobId == other.jobId &&
          applicationStatus == other.applicationStatus &&
          assignmentStatus == other.assignmentStatus &&
          applicationId == other.applicationId &&
          assignmentId == other.assignmentId;

  @override
  int get hashCode => Object.hash(
        jobId,
        applicationStatus,
        assignmentStatus,
        applicationId,
        assignmentId,
      );
}
