// Domain entity: ChatMessage (Step P7.1)

class ChatMessage {
  final String id;
  final String threadId;
  final String senderId;
  final String? senderName;
  final String body;
  final String? attachmentPath;
  final bool wasMasked;
  final DateTime? readAt;
  final DateTime createdAt;
  final bool isMe;

  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    this.senderName,
    required this.body,
    this.attachmentPath,
    this.wasMasked = false,
    this.readAt,
    required this.createdAt,
    this.isMe = false,
  });

  bool get isRead => readAt != null;

  factory ChatMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    final sender = json['sender_id'] as String? ?? '';
    return ChatMessage(
      id: json['id'] as String? ?? '',
      threadId: json['thread_id'] as String? ?? '',
      senderId: sender,
      senderName: json['sender_name'] as String?,
      body: json['body'] as String? ?? '',
      attachmentPath: json['attachment_path'] as String?,
      wasMasked: json['was_masked'] as bool? ?? false,
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'] as String) : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      isMe: sender == currentUserId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'thread_id': threadId,
    'sender_id': senderId,
    'sender_name': senderName,
    'body': body,
    'attachment_path': attachmentPath,
    'was_masked': wasMasked,
    'read_at': readAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'is_me': isMe,
  };
}
