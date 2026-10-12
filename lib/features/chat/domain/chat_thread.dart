// Domain entity: ChatThread (Step P7.1)

class ChatThread {
  final String id;
  final String contextType;
  final String contextId;
  final String participantA;
  final String participantB;
  final String subject;
  final String bookingCode;
  final String status; // 'active', 'read_only', 'archived'
  final DateTime? readOnlyAt;
  final String categoryTag; // 'general', 'worker', 'customer', 'farmer'
  final DateTime lastMessageAt;
  final DateTime createdAt;

  // Joined party data
  final String otherPartyId;
  final String otherPartyName;
  final String? otherPartyAvatar;
  final String otherPartyRole; // 'worker', 'employer', 'farmer', 'customer'
  final String? lastMessageSnippet;
  final int unreadCount;

  const ChatThread({
    required this.id,
    required this.contextType,
    required this.contextId,
    required this.participantA,
    required this.participantB,
    required this.subject,
    required this.bookingCode,
    required this.status,
    this.readOnlyAt,
    required this.categoryTag,
    required this.lastMessageAt,
    required this.createdAt,
    required this.otherPartyId,
    required this.otherPartyName,
    this.otherPartyAvatar,
    required this.otherPartyRole,
    this.lastMessageSnippet,
    this.unreadCount = 0,
  });

  bool get isReadOnly => status == 'read_only';

  factory ChatThread.fromJson(Map<String, dynamic> json, String currentUserId) {
    final pa = json['participant_a'] as String? ?? '';
    final pb = json['participant_b'] as String? ?? '';
    final otherId = (currentUserId == pa) ? pb : pa;

    // Resolved other party info if joined, else fallback
    final otherName = json['other_party_name'] as String? ??
        (json['context_type'] == 'order' ? 'Farm Fresh Producer' : 'Verified Counterparty');
    final otherRole = json['other_party_role'] as String? ?? json['category_tag'] as String? ?? 'worker';

    return ChatThread(
      id: json['id'] as String? ?? '',
      contextType: json['context_type'] as String? ?? 'general',
      contextId: json['context_id'] as String? ?? '',
      participantA: pa,
      participantB: pb,
      subject: json['subject'] as String? ?? 'Direct Discussion',
      bookingCode: json['booking_code'] as String? ?? 'COMM-REQ',
      status: json['status'] as String? ?? 'active',
      readOnlyAt: json['read_only_at'] != null ? DateTime.tryParse(json['read_only_at'] as String) : null,
      categoryTag: json['category_tag'] as String? ?? 'general',
      lastMessageAt: DateTime.tryParse(json['last_message_at'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      otherPartyId: otherId,
      otherPartyName: otherName,
      otherPartyAvatar: json['other_party_avatar'] as String?,
      otherPartyRole: otherRole,
      lastMessageSnippet: json['last_message_snippet'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'context_type': contextType,
    'context_id': contextId,
    'participant_a': participantA,
    'participant_b': participantB,
    'subject': subject,
    'booking_code': bookingCode,
    'status': status,
    'read_only_at': readOnlyAt?.toIso8601String(),
    'category_tag': categoryTag,
    'last_message_at': lastMessageAt.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'other_party_id': otherPartyId,
    'other_party_name': otherPartyName,
    'other_party_avatar': otherPartyAvatar,
    'other_party_role': otherPartyRole,
    'last_message_snippet': lastMessageSnippet,
    'unread_count': unreadCount,
  };
}
