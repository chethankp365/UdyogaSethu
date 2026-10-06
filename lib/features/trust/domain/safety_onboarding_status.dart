class SafetyOnboardingEvent {
  final String id;
  final String title;
  final String? description;
  final String venue;
  final DateTime? startsAt;
  final int capacity;
  final String language;

  const SafetyOnboardingEvent({
    required this.id,
    required this.title,
    this.description,
    required this.venue,
    this.startsAt,
    required this.capacity,
    required this.language,
  });

  factory SafetyOnboardingEvent.fromJson(Map<String, dynamic> json) {
    return SafetyOnboardingEvent(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Safety Onboarding Training Day',
      description: json['description'] as String?,
      venue: json['venue'] as String? ?? 'Training Centre',
      startsAt: json['starts_at'] != null ? DateTime.tryParse(json['starts_at'].toString()) : null,
      capacity: (json['capacity'] as num?)?.toInt() ?? 50,
      language: json['language'] as String? ?? 'en',
    );
  }
}

class SafetyOnboardingStatus {
  final bool isVerifiedBadge;
  final bool kycOk;
  final bool faceOk;
  final bool trainingOk;
  final bool docOk;
  final String registrationStatus;
  final DateTime? registeredAt;
  final SafetyOnboardingEvent? event;

  const SafetyOnboardingStatus({
    required this.isVerifiedBadge,
    required this.kycOk,
    required this.faceOk,
    required this.trainingOk,
    required this.docOk,
    required this.registrationStatus,
    this.registeredAt,
    this.event,
  });

  bool get isFullyApproved => isVerifiedBadge && kycOk && faceOk && trainingOk && docOk;

  factory SafetyOnboardingStatus.initial() {
    return const SafetyOnboardingStatus(
      isVerifiedBadge: false,
      kycOk: false,
      faceOk: false,
      trainingOk: false,
      docOk: false,
      registrationStatus: 'not_booked',
    );
  }

  factory SafetyOnboardingStatus.fromJson(Map<String, dynamic> json) {
    return SafetyOnboardingStatus(
      isVerifiedBadge: json['is_verified_badge'] == true,
      kycOk: json['kyc_ok'] == true,
      faceOk: json['face_ok'] == true,
      trainingOk: json['training_ok'] == true,
      docOk: json['doc_ok'] == true,
      registrationStatus: (json['registration_status'] as String?)?.toLowerCase() ?? 'not_booked',
      registeredAt: json['registered_at'] != null ? DateTime.tryParse(json['registered_at'].toString()) : null,
      event: json['event'] != null ? SafetyOnboardingEvent.fromJson(Map<String, dynamic>.from(json['event'] as Map)) : null,
    );
  }
}
