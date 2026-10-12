class RepeatClientItem {
  final String clientId;
  final String clientName;
  final String? clientPhone;
  final String? avatarPath;
  final int completedJobsCount;
  final DateTime lastJobDate;
  final bool isFavourite;

  const RepeatClientItem({
    required this.clientId,
    required this.clientName,
    this.clientPhone,
    this.avatarPath,
    required this.completedJobsCount,
    required this.lastJobDate,
    required this.isFavourite,
  });

  factory RepeatClientItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = json['last_job_date'] != null
          ? DateTime.parse(json['last_job_date'].toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return RepeatClientItem(
      clientId: json['client_id']?.toString() ?? '',
      clientName: json['client_name']?.toString() ?? 'Client',
      clientPhone: json['client_phone']?.toString(),
      avatarPath: json['avatar_path']?.toString(),
      completedJobsCount: (json['completed_jobs_count'] as num?)?.toInt() ?? 1,
      lastJobDate: parsedDate,
      isFavourite: json['is_favourite'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'client_id': clientId,
        'client_name': clientName,
        'client_phone': clientPhone,
        'avatar_path': avatarPath,
        'completed_jobs_count': completedJobsCount,
        'last_job_date': lastJobDate.toIso8601String(),
        'is_favourite': isFavourite,
      };
}
