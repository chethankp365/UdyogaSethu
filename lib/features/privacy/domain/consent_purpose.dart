enum ConsentPurpose {
  kyc,
  face,
  gps,
  notifications,
  ads;

  String get key {
    switch (this) {
      case ConsentPurpose.kyc:
        return 'kyc';
      case ConsentPurpose.face:
        return 'face';
      case ConsentPurpose.gps:
        return 'gps';
      case ConsentPurpose.notifications:
        return 'notifications';
      case ConsentPurpose.ads:
        return 'ads';
    }
  }

  static ConsentPurpose fromKey(String key) {
    switch (key.toLowerCase()) {
      case 'kyc':
        return ConsentPurpose.kyc;
      case 'face':
        return ConsentPurpose.face;
      case 'gps':
        return ConsentPurpose.gps;
      case 'notifications':
        return ConsentPurpose.notifications;
      case 'ads':
        return ConsentPurpose.ads;
      default:
        return ConsentPurpose.kyc;
    }
  }
}

class ConsentLog {
  final String purpose;
  final bool granted;
  final DateTime timestamp;
  final String version;
  final Map<String, dynamic>? metadata;

  const ConsentLog({
    required this.purpose,
    required this.granted,
    required this.timestamp,
    this.version = '1.0',
    this.metadata,
  });

  factory ConsentLog.fromJson(Map<String, dynamic> json) {
    return ConsentLog(
      purpose: json['consent_type'] as String? ?? 'kyc',
      granted: json['granted'] as bool? ?? false,
      timestamp: json['granted_at'] != null
          ? DateTime.tryParse(json['granted_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      version: json['version'] as String? ?? '1.0',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
