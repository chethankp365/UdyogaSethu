import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/chat/data/chat_repository.dart';
import 'package:udyogasethu/features/chat/domain/chat_message.dart';
import 'package:udyogasethu/features/chat/domain/chat_thread.dart';

final chatThreadDetailProvider = FutureProvider.family.autoDispose<ChatThread, String>((ref, threadId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getThread(threadId);
});

final chatMessagesStreamProvider = StreamProvider.family.autoDispose<List<ChatMessage>, String>((ref, threadId) {
  final repo = ref.watch(chatRepositoryProvider);
  // Mark thread read on open
  repo.markThreadRead(threadId);
  return repo.streamMessages(threadId);
});

class ChatScreen extends ConsumerStatefulWidget {
  final String threadId;

  const ChatScreen({super.key, required this.threadId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isSending = false;
  File? _selectedAttachment;

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage([String? quickReply]) async {
    final text = quickReply ?? _textCtrl.text.trim();
    if (text.isEmpty && _selectedAttachment == null) return;

    setState(() => _isSending = true);

    try {
      final repo = ref.read(chatRepositoryProvider);
      String? attachmentUrl;

      if (_selectedAttachment != null) {
        attachmentUrl = await repo.uploadAttachment(_selectedAttachment!);
      }

      await repo.sendMessage(
        threadId: widget.threadId,
        body: text.isNotEmpty ? text : 'Photo attachment',
        attachmentPath: attachmentUrl,
      );

      _textCtrl.clear();
      setState(() => _selectedAttachment = null);
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickAttachment() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked != null) {
        setState(() {
          _selectedAttachment = File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showSafetyTipsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.security_rounded, color: AppColors.headerGreenDark, size: 26),
                SizedBox(width: 10),
                Text(
                  'UdyogaSethu Safety Rules',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSafetyTipItem(
              Icons.phone_disabled_rounded,
              'Direct numbers are automatically masked',
              'To protect you from harassment and off-platform fraud, all phone numbers and handles are masked.',
            ),
            const SizedBox(height: 12),
            _buildSafetyTipItem(
              Icons.account_balance_wallet_rounded,
              'Always pay through escrow',
              'Cash advances or direct UPI bypasses platform payment protection and insurance guarantees.',
            ),
            const SizedBox(height: 12),
            _buildSafetyTipItem(
              Icons.verified_user_rounded,
              'Messages are dispute evidence',
              'All conversations are kept securely and reviewed by mediators in case of dispute resolution.',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.headerGreenDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Understood'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyTipItem(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.headerGreenDark),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final threadAsync = ref.watch(chatThreadDetailProvider(widget.threadId));
    final messagesAsync = ref.watch(chatMessagesStreamProvider(widget.threadId));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: _buildAppBar(context, threadAsync),
      body: SafeArea(
        child: Column(
          children: [
            // Safety Header Banner
            _buildSafetyBanner(context),

            // Messages List
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.headerGreenDark),
                ),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Start Protected Conversation',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'All phone numbers and handles are masked for your privacy.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: messages.length,
                    itemBuilder: (context, idx) {
                      final msg = messages[idx];
                      return _buildMessageBubble(msg);
                    },
                  );
                },
              ),
            ),

            // Selected Attachment Preview
            if (_selectedAttachment != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: Row(
                  children: [
                    const Icon(Icons.attach_file_rounded, color: AppColors.headerGreenDark, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Attached: ${_selectedAttachment!.path.split(Platform.pathSeparator).last}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() => _selectedAttachment = null),
                    ),
                  ],
                ),
              ),

            // Quick Replies Row (if active)
            threadAsync.maybeWhen(
              data: (thread) => !thread.isReadOnly ? _buildQuickReplies() : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),

            // Input Row or Read-Only Banner
            threadAsync.maybeWhen(
              data: (thread) => thread.isReadOnly ? _buildReadOnlyBanner() : _buildInputBar(),
              orElse: () => _buildInputBar(),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AsyncValue<ChatThread> threadAsync) {
    return AppBar(
      backgroundColor: AppColors.headerGreenDark,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      title: threadAsync.maybeWhen(
        data: (thread) => Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                thread.otherPartyName.isNotEmpty ? thread.otherPartyName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    thread.otherPartyName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${thread.bookingCode} • ${thread.subject}',
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        orElse: () => const Text('Protected Chat', style: TextStyle(fontSize: 15)),
      ),
      actions: [
        threadAsync.maybeWhen(
          data: (thread) => IconButton(
            icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
            tooltip: 'Protected Masked Voice Proxy',
            onPressed: () {
              context.push(
                AppRoutes.maskedCall,
                extra: {
                  'recipientId': thread.otherPartyId,
                  'recipientName': thread.otherPartyName,
                  'bookingCode': thread.bookingCode,
                  'recipientRole': thread.otherPartyRole,
                },
              );
            },
          ),
          orElse: () => const SizedBox.shrink(),
        ),
        IconButton(
          icon: const Icon(Icons.info_outline_rounded, size: 20),
          tooltip: 'Safety Tips',
          onPressed: () => _showSafetyTipsModal(context),
        ),
      ],
    );
  }

  Widget _buildSafetyBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFEF3C7),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.privacy_tip_rounded, size: 16, color: Color(0xFFB45309)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Escrow Protected: Direct phone numbers and UPI IDs are automatically masked.',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 24),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => _showSafetyTipsModal(context),
            child: const Text('View tips', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies() {
    final replies = [
      '👋 Hello!',
      '🙏 Thanks',
      '📍 Location verified',
      'ℹ️ Work details',
      '💳 Payment in escrow',
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: replies.map((reply) {
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ActionChip(
                backgroundColor: const Color(0xFFF1F5F9),
                side: BorderSide.none,
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                label: Text(
                  reply,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
                onPressed: () => _sendMessage(reply),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isMe = msg.isMe;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFE6F4EA) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: Border.all(
                  color: isMe ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Attachment image if present
                  if (msg.attachmentPath != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          color: Colors.grey.shade100,
                          constraints: const BoxConstraints(maxHeight: 180),
                          child: Image.network(
                            msg.attachmentPath!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Padding(
                              padding: EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(Icons.broken_image_rounded, size: 16),
                                  SizedBox(width: 6),
                                  Text('Attachment photo', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Message text
                  Text(
                    msg.body,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: isMe ? AppColors.textDark : const Color(0xFF0F172A),
                    ),
                  ),

                  // Masked warning chip if was_masked
                  if (msg.wasMasked) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_rounded, size: 11, color: Color(0xFFB45309)),
                            SizedBox(width: 4),
                            Text(
                              'Sensitive info masked',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 4),

                  // Timestamp & read tick
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(msg.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? AppColors.headerGreenDark : AppColors.textMuted,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                          size: 13,
                          color: msg.isRead ? const Color(0xFF0284C7) : AppColors.textMuted,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.headerGreenDark),
            tooltip: 'Attach Photo',
            onPressed: _pickAttachment,
          ),
          Expanded(
            child: TextField(
              controller: _textCtrl,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.headerGreenDark,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
            ),
            icon: _isSending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded, size: 18),
            onPressed: _isSending ? null : () => _sendMessage(),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.all(16),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_clock_rounded, size: 18, color: AppColors.textMuted),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'This thread is completed and read-only.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $ampm';
  }
}
