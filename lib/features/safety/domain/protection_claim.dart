// Domain entity: ProtectionClaim & ClaimEligibility (Step P7.3)

class ClaimEligibilityResult {
  final bool eligible;
  final String? reason;
  final bool qrOk;
  final bool selfieGpsOk;
  final bool timerOk;
  final int durationMinutes;
  final bool evidenceOk;
  final int evidenceCount;
  final int maxCoverPaise;

  const ClaimEligibilityResult({
    required this.eligible,
    this.reason,
    required this.qrOk,
    required this.selfieGpsOk,
    required this.timerOk,
    required this.durationMinutes,
    required this.evidenceOk,
    required this.evidenceCount,
    this.maxCoverPaise = 2500000, // ₹25,000
  });

  factory ClaimEligibilityResult.fromJson(Map<String, dynamic> json) {
    return ClaimEligibilityResult(
      eligible: json['eligible'] as bool? ?? false,
      reason: json['reason'] as String?,
      qrOk: json['qr_ok'] as bool? ?? false,
      selfieGpsOk: json['selfie_gps_ok'] as bool? ?? false,
      timerOk: json['timer_ok'] as bool? ?? false,
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      evidenceOk: json['evidence_ok'] as bool? ?? false,
      evidenceCount: json['evidence_count'] as int? ?? 0,
      maxCoverPaise: json['max_cover_paise'] as int? ?? 2500000,
    );
  }
}

class ProtectionClaim {
  final String id;
  final String claimCode;
  final String assignmentId;
  final String claimType;
  final int amountPaise;
  final String details;
  final String status;
  final bool isSimulated;
  final DateTime createdAt;

  const ProtectionClaim({
    required this.id,
    required this.claimCode,
    required this.assignmentId,
    required this.claimType,
    required this.amountPaise,
    required this.details,
    required this.status,
    required this.isSimulated,
    required this.createdAt,
  });

  factory ProtectionClaim.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] as String? ?? json['claim_id'] as String? ?? '';
    final code = json['claim_code'] as String? ??
        (rawId.length >= 8 ? 'CLM-${rawId.substring(0, 8).toUpperCase()}' : 'CLM-2026');

    return ProtectionClaim(
      id: rawId,
      claimCode: code,
      assignmentId: json['assignment_id'] as String? ?? '',
      claimType: json['claim_type'] as String? ?? 'Accident Cover',
      amountPaise: (json['amount_paise'] as num?)?.toInt() ?? 0,
      details: json['details'] as String? ?? '',
      status: json['status'] as String? ?? 'submitted',
      isSimulated: json['is_simulated'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'claim_code': claimCode,
        'assignment_id': assignmentId,
        'claim_type': claimType,
        'amount_paise': amountPaise,
        'details': details,
        'status': status,
        'is_simulated': isSimulated,
        'created_at': createdAt.toIso8601String(),
      };
}
