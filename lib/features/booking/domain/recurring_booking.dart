class RecurringBooking {
  final String id;
  final String providerId;
  final String workerId;
  final String workerName;
  final String? workerAvatar;
  final String? categoryId;
  final String categoryName;
  final String scheduleRule; // e.g. 'weekly', 'monthly'
  final String? preferredTime; // e.g. '09:00:00'
  final String status; // 'active', 'paused', 'cancelled'
  final List<String> skipDates;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RecurringBooking({
    required this.id,
    required this.providerId,
    required this.workerId,
    required this.workerName,
    this.workerAvatar,
    this.categoryId,
    required this.categoryName,
    required this.scheduleRule,
    this.preferredTime,
    this.status = 'active',
    this.skipDates = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory RecurringBooking.fromJson(Map<String, dynamic> json) {
    return RecurringBooking(
      id: json['id'] as String? ?? '',
      providerId: json['provider_id'] as String? ?? '',
      workerId: json['worker_id'] as String? ?? '',
      workerName: json['worker_name'] as String? ?? 'Worker',
      workerAvatar: json['worker_avatar'] as String?,
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String? ?? 'Service',
      scheduleRule: json['schedule_rule'] as String? ?? 'weekly',
      preferredTime: json['preferred_time'] as String?,
      status: json['status'] as String? ?? 'active',
      skipDates: (json['skip_dates'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'provider_id': providerId,
    'worker_id': workerId,
    'worker_name': workerName,
    'worker_avatar': workerAvatar,
    'category_id': categoryId,
    'category_name': categoryName,
    'schedule_rule': scheduleRule,
    'preferred_time': preferredTime,
    'status': status,
    'skip_dates': skipDates,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isCancelled => status == 'cancelled';
  bool get isWeekly => scheduleRule.toLowerCase() == 'weekly';
  bool get isMonthly => scheduleRule.toLowerCase() == 'monthly';
}
