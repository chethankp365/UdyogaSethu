class BookingResult {
  final String assignmentId;
  final String jobId;
  final String bookingCode;
  final String status;
  final bool protectionSelected;
  final DateTime startAt;
  final String? recurringId;

  const BookingResult({
    required this.assignmentId,
    required this.jobId,
    required this.bookingCode,
    required this.status,
    required this.protectionSelected,
    required this.startAt,
    this.recurringId,
  });

  factory BookingResult.fromJson(Map<String, dynamic> json) {
    return BookingResult(
      assignmentId: json['assignment_id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      bookingCode: json['booking_code'] as String? ?? '',
      status: json['status'] as String? ?? 'requested',
      protectionSelected: json['protection_selected'] as bool? ?? false,
      startAt: DateTime.tryParse(json['start_at']?.toString() ?? '') ?? DateTime.now(),
      recurringId: json['recurring_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'assignment_id': assignmentId,
    'job_id': jobId,
    'booking_code': bookingCode,
    'status': status,
    'protection_selected': protectionSelected,
    'start_at': startAt.toIso8601String(),
    'recurring_id': recurringId,
  };

  bool get isWaitingForWorker => status == 'requested';
}
