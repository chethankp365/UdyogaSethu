/// Canonical dispute issue types supported by UdyogaSethu.
enum DisputeIssueType {
  noShow('no_show', 'No-Show / Unreported Absence'),
  incompleteWork('incomplete_work', 'Incomplete Work / Left Early'),
  poorQuality('poor_quality', 'Poor Quality / Substandard Work'),
  wrongProduct('wrong_product', 'Wrong Product / Quality Mismatch'),
  paymentIssue('payment_issue', 'Payment Issue / Escrow Dispute'),
  unsafeConduct('unsafe_conduct', 'Unsafe Conduct / Behaviour Violation'),
  verificationProblem('verification_problem', 'Verification / Identity Mismatch');

  final String dbValue;
  final String defaultLabel;
  const DisputeIssueType(this.dbValue, this.defaultLabel);

  static DisputeIssueType fromDb(String value) {
    for (final t in DisputeIssueType.values) {
      if (t.dbValue == value) return t;
    }
    return DisputeIssueType.poorQuality;
  }
}

/// Dispute status stages.
enum DisputeStatus {
  open('open', 'Open for Mediation'),
  inReview('in_review', 'In Review by Trust Team'),
  resolved('resolved', 'Resolved'),
  rejected('rejected', 'Rejected');

  final String dbValue;
  final String defaultLabel;
  const DisputeStatus(this.dbValue, this.defaultLabel);

  static DisputeStatus fromDb(String value) {
    for (final s in DisputeStatus.values) {
      if (s.dbValue == value) return s;
    }
    return DisputeStatus.open;
  }
}

/// Represents a dispute ticket raised on a job assignment or order.
class DisputeRecord {
  final String id;
  final String? refType;
  final String? refId;
  final String? raisedBy;
  final String? against;
  final DisputeIssueType issueType;
  final String details;
  final DisputeStatus status;
  final String? resolution;
  final int? refundPaise;
  final DateTime createdAt;
  final List<String> evidencePaths;

  const DisputeRecord({
    required this.id,
    this.refType,
    this.refId,
    this.raisedBy,
    this.against,
    required this.issueType,
    required this.details,
    required this.status,
    this.resolution,
    this.refundPaise,
    required this.createdAt,
    this.evidencePaths = const [],
  });

  factory DisputeRecord.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    List<String> evidence = [];
    final rawEvidence = json['evidence'];
    if (rawEvidence is List) {
      evidence = rawEvidence.map((e) => e.toString()).toList();
    }

    return DisputeRecord(
      id: json['id']?.toString() ?? '',
      refType: json['ref_type']?.toString(),
      refId: json['ref_id']?.toString(),
      raisedBy: json['raised_by']?.toString(),
      against: json['against']?.toString(),
      issueType: DisputeIssueType.fromDb(json['issue_type']?.toString() ?? 'poor_quality'),
      details: json['details']?.toString() ?? '',
      status: DisputeStatus.fromDb(json['status']?.toString() ?? 'open'),
      resolution: json['resolution']?.toString(),
      refundPaise: (json['refund_paise'] as num?)?.toInt(),
      createdAt: parsedDate,
      evidencePaths: evidence,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ref_type': refType,
      'ref_id': refId,
      'raised_by': raisedBy,
      'against': against,
      'issue_type': issueType.dbValue,
      'details': details,
      'status': status.dbValue,
      'resolution': resolution,
      'refund_paise': refundPaise,
      'created_at': createdAt.toIso8601String(),
      'evidence': evidencePaths,
    };
  }
}
