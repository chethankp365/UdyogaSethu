// Domain entity: CallSession (Step P7.2)

class CallSession {
  final String callId;
  final String status;
  final String proxyDisplay;
  final bool isDemo;
  final String callerName;
  final String recipientName;
  final String? recipientRole;
  final String bookingCode;
  final int durationSeconds;

  const CallSession({
    required this.callId,
    required this.status,
    required this.proxyDisplay,
    required this.isDemo,
    required this.callerName,
    required this.recipientName,
    this.recipientRole,
    required this.bookingCode,
    this.durationSeconds = 0,
  });

  factory CallSession.fromJson(Map<String, dynamic> json) {
    return CallSession(
      callId: json['call_id'] as String? ?? '',
      status: json['status'] as String? ?? 'connected',
      proxyDisplay: json['proxy_display'] as String? ?? '+91 80 4719 8200 (Udyoga Proxy)',
      isDemo: json['is_demo'] as bool? ?? true,
      callerName: json['caller_name'] as String? ?? 'Udyoga User',
      recipientName: json['recipient_name'] as String? ?? 'Verified Contact',
      recipientRole: json['recipient_role'] as String?,
      bookingCode: json['booking_code'] as String? ?? 'CALL-ACTIVE',
      durationSeconds: json['duration_seconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'call_id': callId,
    'status': status,
    'proxy_display': proxyDisplay,
    'is_demo': isDemo,
    'caller_name': callerName,
    'recipient_name': recipientName,
    'recipient_role': recipientRole,
    'booking_code': bookingCode,
    'duration_seconds': durationSeconds,
  };
}
