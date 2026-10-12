// Domain entity: SosIncident (Step P7.3)

class SosIncident {
  final String id;
  final String? assignmentId;
  final double latitude;
  final double longitude;
  final String status;
  final bool smsConfigured;
  final bool smsSent;
  final int emergencyContactsCount;
  final String message;
  final DateTime createdAt;

  const SosIncident({
    required this.id,
    this.assignmentId,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.smsConfigured,
    required this.smsSent,
    required this.emergencyContactsCount,
    required this.message,
    required this.createdAt,
  });

  factory SosIncident.fromJson(Map<String, dynamic> json) {
    return SosIncident(
      id: json['incident_id'] as String? ?? json['id'] as String? ?? '',
      assignmentId: json['assignment_id'] as String?,
      latitude: (json['lat'] as num?)?.toDouble() ?? 12.9716,
      longitude: (json['lng'] as num?)?.toDouble() ?? 77.5946,
      status: json['status'] as String? ?? 'active',
      smsConfigured: json['sms_configured'] as bool? ?? false,
      smsSent: json['sms_sent'] as bool? ?? false,
      emergencyContactsCount: json['emergency_contacts_count'] as int? ?? 0,
      message: json['message'] as String? ?? 'SOS incident registered.',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
