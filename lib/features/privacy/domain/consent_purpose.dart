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
  final String? id;
  final String? userId;
  final String purpose;
  final bool granted;
  final DateTime timestamp;
  final String version;
  final Map<String, dynamic>? metadata;

  const ConsentLog({
    this.id,
    this.userId,
    required this.purpose,
    required this.granted,
    required this.timestamp,
    this.version = '1.0',
    this.metadata,
  });

  factory ConsentLog.fromJson(Map<String, dynamic> json) {
    final purposeVal = json['purpose'] ?? json['consent_type'] ?? 'kyc';
    final rawDate = json['created_at'] ?? json['granted_at'];
    DateTime parsedDate = DateTime.now();
    if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    }

    return ConsentLog(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      purpose: purposeVal.toString(),
      granted: json['granted'] as bool? ?? false,
      timestamp: parsedDate,
      version: json['version'] as String? ?? '1.0',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'purpose': purpose,
      'granted': granted,
      'version': version,
      'created_at': timestamp.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }
}
