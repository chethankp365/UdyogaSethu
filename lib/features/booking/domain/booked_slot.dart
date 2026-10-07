class BookedSlot {
  final String assignmentId;
  final String jobId;
  final DateTime startAt;
  final DateTime endAt;
  final String status;

  const BookedSlot({
    required this.assignmentId,
    required this.jobId,
    required this.startAt,
    required this.endAt,
    required this.status,
  });

  factory BookedSlot.fromJson(Map<String, dynamic> json) {
    return BookedSlot(
      assignmentId: json['assignment_id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      startAt: DateTime.tryParse(json['start_at']?.toString() ?? '') ?? DateTime.now(),
      endAt: DateTime.tryParse(json['end_at']?.toString() ?? '') ?? DateTime.now(),
      status: json['status'] as String? ?? 'requested',
    );
  }

  Map<String, dynamic> toJson() => {
    'assignment_id': assignmentId,
    'job_id': jobId,
    'start_at': startAt.toIso8601String(),
    'end_at': endAt.toIso8601String(),
    'status': status,
  };

  /// Checks if a candidate interval [candidateStart, candidateStart + durationMinutes]
  /// overlaps with this booked slot.
  bool overlapsWith(DateTime candidateStart, int durationMinutes) {
    final candidateEnd = candidateStart.add(Duration(minutes: durationMinutes));
    return candidateStart.isBefore(endAt) && candidateEnd.isAfter(startAt);
  }
}
