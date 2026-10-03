class KycRecord {
  final String id;
  final String userId;
  final String docType;
  final String provider;
  final String? providerRef;
  final String status;
  final String? maskedId;
  final String? nameMasked;
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final DateTime createdAt;

  const KycRecord({
    required this.id,
    required this.userId,
    required this.docType,
    required this.provider,
    this.providerRef,
    required this.status,
    this.maskedId,
    this.nameMasked,
    this.verifiedAt,
    this.rejectionReason,
    required this.createdAt,
  });

  bool get isVerified => status.toLowerCase() == 'verified';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isRejected => status.toLowerCase() == 'rejected' || status.toLowerCase() == 'failed';
  bool get isReviewRequired => status.toLowerCase() == 'review_required';
  bool get isNotRequested => status.isEmpty || status.toLowerCase() == 'not_requested';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'doc_type': docType,
      'provider': provider,
      'provider_ref': providerRef,
      'status': status,
      'masked_id': maskedId,
      'name_masked': nameMasked,
      'verified_at': verifiedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory KycRecord.fromJson(Map<String, dynamic> json) {
    return KycRecord(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      docType: json['doc_type'] as String? ?? 'aadhaar',
      provider: json['provider'] as String? ?? 'digilocker',
      providerRef: json['provider_ref'] as String?,
      status: json['status'] as String? ?? 'pending',
      maskedId: json['masked_id'] as String?,
      nameMasked: json['name_masked'] as String?,
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'].toString())
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
