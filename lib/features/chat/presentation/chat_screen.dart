import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_motion.dart';
import 'package:udyogasethu/features/chat/data/chat_repository.dart';
import 'package:udyogasethu/features/chat/domain/chat_message.dart';
import 'package:udyogasethu/features/chat/domain/chat_thread.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

final chatThreadDetailProvider = FutureProvider.family.autoDispose<ChatThread, String>((ref, threadId) {
  final repo = ref.watch(chatRepositoryProvider);
  final session = ref.watch(appSessionProvider);
  return repo.getThread(threadId, activeRole: session.activeRole);
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
  bool _isUserBlocked = false;
  bool _isTyping = false;
  File? _selectedAttachment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final thread = ref.read(chatThreadDetailProvider(widget.threadId)).asData?.value;
      if (thread != null && thread.otherPartyId.isNotEmpty) {
        _checkBlockStatus(thread.otherPartyId);
      }
    });
  }

  Future<void> _checkBlockStatus(String otherId) async {
    if (otherId.isEmpty) return;
    final blocked = await ref.read(chatRepositoryProvider).isUserBlocked(otherId);
    if (mounted && blocked) {
      setState(() => _isUserBlocked = true);
    }
  }

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
    if (_isUserBlocked) return;
    final thread = ref.read(chatThreadDetailProvider(widget.threadId)).asData?.value;
    if (thread != null && thread.isReadOnly) {
      final l10n = AppLocalizations.of(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.chatClosedDesc ??
                  'This chat is no longer available. The job has ended, so messaging and calling are disabled.',
            ),
          ),
        );
      }
      return;
    }

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

      if (widget.threadId.startsWith('cccccccc-')) {
        setState(() => _isTyping = true);
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) {
            setState(() => _isTyping = false);
            Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
          }
        });
      }
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
    if (_isUserBlocked) return;
    final thread = ref.read(chatThreadDetailProvider(widget.threadId)).asData?.value;
    if (thread != null && thread.isReadOnly) return;
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

  void _showReportUserDialog(ChatThread thread) {
    final l10n = AppLocalizations.of(context);
    String selectedReason = 'Spam or Scam';
    final detailsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.flag_outlined, color: Colors.orange),
                const SizedBox(width: 8),
                Text(l10n?.chatReportUser ?? 'Report User'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select a reason for reporting:', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: selectedReason,
                    items: const [
                      DropdownMenuItem(value: 'Spam or Scam', child: Text('Spam or Scam')),
                      DropdownMenuItem(value: 'Inappropriate or Abusive Behavior', child: Text('Inappropriate or Abusive Behavior')),
                      DropdownMenuItem(value: 'Payment or Job Dispute', child: Text('Payment or Job Dispute')),
                      DropdownMenuItem(value: 'Other Concern', child: Text('Other Concern')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedReason = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: detailsCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Additional details (optional)...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6548), foregroundColor: Colors.white),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);
                  final ok = await ref.read(chatRepositoryProvider).reportUser(
                    reportedUserId: thread.otherPartyId,
                    conversationId: thread.id,
                    reason: selectedReason,
                    details: detailsCtrl.text.trim().isNotEmpty ? detailsCtrl.text.trim() : null,
                  );
                  if (ok) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n?.chatReportSubmitted ?? 'Report submitted for admin review.')),
                    );
                  }
                },
                child: const Text('Submit Report'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBlockUserConfirmation(ChatThread thread) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.block, color: Colors.red),
            const SizedBox(width: 8),
            Text(l10n?.chatBlockUser ?? 'Block User'),
          ],
        ),
        content: Text(
          'Are you sure you want to block ${thread.otherPartyName}? You will no longer receive messages from them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final ok = await ref.read(chatRepositoryProvider).blockUser(thread.otherPartyId);
              if (mounted && ok) {
                setState(() => _isUserBlocked = true);
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n?.chatUserBlocked ?? 'This user has been blocked. Messages disabled.')),
                );
              }
            },
            child: Text(l10n?.chatBlockUser ?? 'Block User'),
          ),
        ],
      ),
    );
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
    ref.listen<AsyncValue<ChatThread>>(chatThreadDetailProvider(widget.threadId), (prev, next) {
      final thread = next.asData?.value;
      if (thread != null && thread.otherPartyId.isNotEmpty) {
        if (thread.status == 'blocked') {
          setState(() => _isUserBlocked = true);
        } else {
          _checkBlockStatus(thread.otherPartyId);
        }
      }
    });

    final threadAsync = ref.watch(chatThreadDetailProvider(widget.threadId));
    final messagesAsync = ref.watch(chatMessagesStreamProvider(widget.threadId));

    final isBlocked = _isUserBlocked || (threadAsync.asData?.value.status == 'blocked');

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: _buildAppBar(context, threadAsync),
      body: SafeArea(
        child: Column(
          children: [
            // Safety Header Banner
            _buildSafetyBanner(
              context,
              isReadOnly: threadAsync.asData?.value.isReadOnly ?? false,
            ),

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
                    itemCount: messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, idx) {
                      if (idx < messages.length) {
                        final msg = messages[idx];
                        return _buildMessageBubble(msg);
                      }
                      return _buildTypingIndicator();
                    },
                  );
                },
              ),
            ),

            // Quick reply chips (if active and not blocked)
            if (!isBlocked) ...[
              threadAsync.maybeWhen(
                data: (thread) => thread.isReadOnly ? const SizedBox.shrink() : _buildQuickReplies(),
                orElse: () => const SizedBox.shrink(),
              ),
            ],

            // Selected Attachment Preview
            if (_selectedAttachment != null) ...[
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_selectedAttachment!, width: 48, height: 48, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Attached image ready to send',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.red),
                      onPressed: () => setState(() => _selectedAttachment = null),
                    ),
                  ],
                ),
              ),
            ],

            // Input Bar or Blocked / Read-only Banner
            if (isBlocked)
              _buildBlockedBanner()
            else
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
    final l10n = AppLocalizations.of(context);
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
          data: (thread) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  thread.isReadOnly ? Icons.phone_disabled_rounded : Icons.phone_in_talk_rounded,
                  size: 20,
                  color: thread.isReadOnly ? Colors.white54 : Colors.white,
                ),
                tooltip: thread.isReadOnly
                    ? (l10n?.chatCallingDisabled ?? 'Voice calling is disabled because this job has ended.')
                    : 'Protected Masked Voice Proxy',
                onPressed: () {
                  if (thread.isReadOnly) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n?.chatCallingDisabled ??
                              'Voice calling is disabled because this job has ended.',
                        ),
                      ),
                    );
                    return;
                  }
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
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (val) {
                  if (val == 'report') {
                    _showReportUserDialog(thread);
                  } else if (val == 'block') {
                    _showBlockUserConfirmation(thread);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        const Icon(Icons.flag_outlined, size: 18, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(l10n?.chatReportUser ?? 'Report User'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        const Icon(Icons.block, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(l10n?.chatBlockUser ?? 'Block User'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
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

  Widget _buildSafetyBanner(BuildContext context, {bool isReadOnly = false}) {
    final l10n = AppLocalizations.of(context);
    if (isReadOnly) {
      return Container(
        width: double.infinity,
        color: const Color(0xFFF1F5F9),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.lock_rounded, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n?.chatClosedDesc ??
                    'The job has ended. For safety and privacy, messaging and calling are closed.',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isDemo = widget.threadId.startsWith('cccccccc-');

    return Container(
      width: double.infinity,
      color: isDemo ? const Color(0xFFEFF6FF) : const Color(0xFFFEF3C7),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(
            isDemo ? Icons.info_outline_rounded : Icons.privacy_tip_rounded,
            size: 16,
            color: isDemo ? const Color(0xFF1D4ED8) : const Color(0xFFB45309),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isDemo
                  ? 'Demo mode: Simulated live conversation for presentation. Numbers masked.'
                  : 'Escrow Protected: Direct phone numbers and UPI IDs are automatically masked.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDemo ? const Color(0xFF1E40AF) : const Color(0xFF92400E),
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 24),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => _showSafetyTipsModal(context),
            child: Text(
              'View tips',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDemo ? const Color(0xFF1D4ED8) : const Color(0xFF92400E),
              ),
            ),
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
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (msg.attachmentPath != null && msg.attachmentPath!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        msg.attachmentPath!,
                        width: 180,
                        height: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 180,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    msg.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: isMe ? const Color(0xFF0F172A) : AppColors.textDark,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 2,
                    children: [
                      if (msg.wasMasked) ...[
                        const Icon(Icons.shield_outlined, size: 11, color: Color(0xFFB45309)),
                        const Text(
                          'Masked',
                          style: TextStyle(fontSize: 9, color: Color(0xFFB45309), fontWeight: FontWeight.bold),
                        ),
                      ],
                      Text(
                        _formatTime(msg.createdAt),
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                      if (isMe) ...[
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

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x05000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
                const SizedBox(width: 8),
                const Text(
                  'typing...',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 150)),
      curve: Curves.easeInOut,
      builder: (context, val, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.headerGreenDark.withValues(alpha: val),
          ),
        );
      },
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
          BouncingPressable(
            onTap: _isSending ? null : () => _sendMessage(),
            borderRadius: BorderRadius.circular(20),
            child: IconButton(
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
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedBanner() {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      color: const Color(0xFFFEE2E2),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.block, size: 18, color: Colors.red),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              l10n?.chatUserBlocked ?? 'This user has been blocked. Messages disabled.',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyBanner() {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_clock_rounded, size: 22, color: AppColors.textMuted),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n?.chatClosedTitle ?? 'This chat is no longer available',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n?.chatClosedDesc ??
                      'The job has ended. For safety and privacy, messaging and calling are closed.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
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
