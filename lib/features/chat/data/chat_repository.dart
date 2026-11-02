import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/supabase/edge_api.dart';
import 'package:udyogasethu/core/supabase/supabase_service.dart';
import 'package:udyogasethu/features/chat/domain/call_session.dart';
import 'package:udyogasethu/features/chat/domain/chat_message.dart';
import 'package:udyogasethu/features/chat/domain/chat_thread.dart';
import 'package:udyogasethu/features/chat/domain/demo_chat_data.dart';

abstract class ChatRepository {
  Future<List<ChatThread>> getThreads({
    String filter = 'all', // 'all', 'active', 'completed'
    String roleFilter = 'all', // 'all', 'worker', 'customer', 'farmer'
    String searchQuery = '',
    UserRole? activeRole,
  });

  Future<ChatThread> getThread(String threadId, {UserRole? activeRole});

  Future<String> getOrCreateThread({
    required String contextType,
    required String contextId,
    required String recipientId,
    String? subject,
    String? bookingCode,
    String? categoryTag,
  });

  Stream<List<ChatMessage>> streamMessages(String threadId);

  Future<ChatMessage> sendMessage({
    required String threadId,
    required String body,
    String? attachmentPath,
  });

  Future<String?> uploadAttachment(File file);

  Future<void> markThreadRead(String threadId);

  Future<bool> blockUser(String userId);

  Future<bool> unblockUser(String userId);

  Future<bool> isUserBlocked(String userId);

  Future<bool> reportUser({
    required String reportedUserId,
    required String conversationId,
    required String reason,
    String? details,
  });

  Future<CallSession> initiateMaskedCall({
    required String recipientId,
    String? bookingCode,
    String? assignmentId,
  });

  Future<void> endMaskedCall({
    required String callId,
    int durationSeconds = 0,
  });

  Future<bool> deleteOrArchiveConversation(String conversationId);
}

class SupabaseChatRepository implements ChatRepository {
  final SupabaseClient _client;
  final EdgeApiClient _edgeApi;

  SupabaseChatRepository(this._client, this._edgeApi);

  String get _currentUserId => _client.auth.currentUser?.id ?? '';

  @override
  Future<List<ChatThread>> getThreads({
    String filter = 'all',
    String roleFilter = 'all',
    String searchQuery = '',
    UserRole? activeRole,
  }) async {
    final uid = _currentUserId;
    final effectiveRole = activeRole ?? UserRole.seeker;

    if (uid.isNotEmpty) {
      try {
        // 1. Fetch conversations via get_conversations RPC
        final rpcRes = await _client.rpc('get_conversations', params: {'p_filter': filter});
        final List<ChatThread> threads = [];

        if (rpcRes is List && rpcRes.isNotEmpty) {
          for (final row in rpcRes) {
            final map = Map<String, dynamic>.from(row as Map);
            final cId = map['conversation_id']?.toString() ?? '';
            if (cId.isEmpty) continue;

            final jId = map['job_id']?.toString() ?? '';
            final otherId = map['other_user_id']?.toString() ?? '';
            final otherName = map['other_user_name']?.toString() ?? 'User';
            final otherAvatar = map['other_user_avatar']?.toString();
            final otherRole = map['other_user_role']?.toString() ?? 'worker';
            final cType = map['context_type']?.toString() ?? 'job';
            final cCtxId = map['context_id']?.toString() ?? jId;
            final subject = map['title']?.toString() ?? map['job_title']?.toString() ?? 'Job Discussion';
            final lastSnippet = map['last_message_body']?.toString();
            final lastMsgAt = map['last_message_at'] != null
                ? DateTime.tryParse(map['last_message_at'].toString()) ?? DateTime.now()
                : DateTime.now();
            final unread = (map['unread_count'] as num?)?.toInt() ?? 0;
            final status = map['status']?.toString() ?? 'active';

            final bookingCode = map['booking_code']?.toString() ??
                (jId.isNotEmpty
                    ? 'JOB-${jId.length >= 6 ? jId.substring(0, 6).toUpperCase() : jId}'
                    : 'CHAT-${cId.length >= 6 ? cId.substring(0, 6).toUpperCase() : cId}');

            final thread = ChatThread(
              id: cId,
              contextType: cType,
              contextId: cCtxId,
              participantA: map['provider_id']?.toString() ?? uid,
              participantB: map['seeker_id']?.toString() ?? otherId,
              subject: subject,
              bookingCode: bookingCode,
              status: status,
              categoryTag: otherRole,
              lastMessageAt: lastMsgAt,
              createdAt: lastMsgAt,
              otherPartyId: otherId,
              otherPartyName: otherName,
              otherPartyAvatar: otherAvatar,
              otherPartyRole: otherRole,
              lastMessageSnippet: lastSnippet,
              unreadCount: unread,
            );

            if (searchQuery.isNotEmpty) {
              final q = searchQuery.toLowerCase();
              final match = thread.subject.toLowerCase().contains(q) ||
                  thread.otherPartyName.toLowerCase().contains(q) ||
                  thread.bookingCode.toLowerCase().contains(q) ||
                  (thread.lastMessageSnippet?.toLowerCase().contains(q) ?? false);
              if (!match) continue;
            }

            threads.add(thread);
          }
          if (threads.isNotEmpty) {
            return threads;
          }
        }
      } catch (e) {
        AppLogger.w('RPC get_conversations failed: $e, falling back to direct table select');
      }

      // 2. Direct Table Fallback
      try {
        final rows = await _client
            .from('conversations')
            .select('id, job_id, provider_id, seeker_id, status, last_message_at, created_at, jobs(title, status)')
            .or('provider_id.eq.$uid,seeker_id.eq.$uid')
            .order('last_message_at', ascending: false);

        final List<ChatThread> directThreads = [];

        for (final r in (rows as List)) {
          final row = Map<String, dynamic>.from(r as Map);
          final cId = row['id']?.toString() ?? '';
          final pId = row['provider_id']?.toString() ?? '';
          final sId = row['seeker_id']?.toString() ?? '';
          final otherId = (uid == pId) ? sId : pId;
          final jMap = row['jobs'] as Map<String, dynamic>?;
          final jobTitle = jMap?['title']?.toString() ?? 'Job Discussion';
          final jId = row['job_id']?.toString() ?? '';
          final rawStatus = row['status']?.toString() ?? 'active';
          final isJobClosed = jMap?['status'] == 'completed' || jMap?['status'] == 'closed' || jMap?['status'] == 'cancelled';
          final status = (isJobClosed || rawStatus == 'read_only' || rawStatus == 'completed') ? 'read_only' : rawStatus;

          if (filter == 'active' && status != 'active') continue;
          if (filter == 'completed' && status == 'active') continue;

          String otherName = 'User';
          String? otherAvatar;
          try {
            final pRow = await _client
                .from('public_profiles')
                .select('full_name, avatar_path')
                .eq('id', otherId)
                .maybeSingle();
            if (pRow != null) {
              otherName = pRow['full_name']?.toString() ?? 'User';
              otherAvatar = pRow['avatar_path']?.toString();
            }
          } catch (_) {}

          String? lastSnippet;
          int unread = 0;
          try {
            final mRows = await _client
                .from('messages')
                .select('body, sender_id, read_at')
                .eq('conversation_id', cId)
                .order('created_at', ascending: false)
                .limit(1);

            if (mRows.isNotEmpty) {
              lastSnippet = mRows.first['body']?.toString();
              unread = mRows.where((m) => m['sender_id'] != uid && m['read_at'] == null).length;
            }
          } catch (_) {}

          final lastAt = row['last_message_at'] != null
              ? DateTime.tryParse(row['last_message_at'].toString()) ?? DateTime.now()
              : DateTime.now();

          directThreads.add(
            ChatThread(
              id: cId,
              contextType: 'job',
              contextId: jId,
              participantA: pId,
              participantB: sId,
              subject: jobTitle,
              bookingCode: jId.isNotEmpty
                  ? 'JOB-${jId.length >= 6 ? jId.substring(0, 6).toUpperCase() : jId}'
                  : 'CHAT-${cId.length >= 6 ? cId.substring(0, 6).toUpperCase() : cId}',
              status: status,
              categoryTag: 'worker',
              lastMessageAt: lastAt,
              createdAt: lastAt,
              otherPartyId: otherId,
              otherPartyName: otherName,
              otherPartyAvatar: otherAvatar,
              otherPartyRole: 'worker',
              lastMessageSnippet: lastSnippet,
              unreadCount: unread,
            ),
          );
        }

        if (directThreads.isNotEmpty) {
          return directThreads;
        }
      } catch (directErr, st) {
        AppLogger.e('Direct conversations query also failed: $directErr', directErr, st);
      }
    }

    // 3. Presentation / Demo Seed Fallback (Category-Aware)
    return DemoChatData.getThreadsForUser(
      currentUserId: uid,
      activeRole: effectiveRole,
      filter: filter,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<ChatThread> getThread(String threadId, {UserRole? activeRole}) async {
    final uid = _currentUserId;

    if (threadId.startsWith('cccccccc-') || uid.isEmpty) {
      return DemoChatData.getThread(
        threadId,
        currentUserId: uid,
        activeRole: activeRole ?? UserRole.seeker,
      );
    }

    try {
      final row = await _client
          .from('conversations')
          .select('*, jobs(title, status)')
          .eq('id', threadId)
          .maybeSingle();

      if (row != null) {
        final pId = row['provider_id']?.toString() ?? '';
        final sId = row['seeker_id']?.toString() ?? '';
        final otherId = (uid == pId) ? sId : pId;
        final jMap = row['jobs'] as Map<String, dynamic>?;
        final jobTitle = jMap?['title']?.toString() ?? 'Job Discussion';
        final jId = row['job_id']?.toString() ?? '';
        final rawStatus = row['status']?.toString() ?? 'active';
        final isJobClosed = jMap?['status'] == 'completed' || jMap?['status'] == 'closed' || jMap?['status'] == 'cancelled';
        final status = (isJobClosed || rawStatus == 'read_only' || rawStatus == 'completed') ? 'read_only' : rawStatus;

        String otherName = 'User';
        String? otherAvatar;
        try {
          final pRow = await _client
              .from('public_profiles')
              .select('full_name, avatar_path')
              .eq('id', otherId)
              .maybeSingle();
          if (pRow != null) {
            otherName = pRow['full_name']?.toString() ?? 'User';
            otherAvatar = pRow['avatar_path']?.toString();
          }
        } catch (_) {}

        final lastAt = row['last_message_at'] != null
            ? DateTime.tryParse(row['last_message_at'].toString()) ?? DateTime.now()
            : DateTime.now();

        return ChatThread(
          id: threadId,
          contextType: 'job',
          contextId: jId,
          participantA: pId,
          participantB: sId,
          subject: jobTitle,
          bookingCode: jId.isNotEmpty
              ? 'JOB-${jId.length >= 6 ? jId.substring(0, 6).toUpperCase() : jId}'
              : 'CHAT-${threadId.length >= 6 ? threadId.substring(0, 6).toUpperCase() : threadId}',
          status: status,
          categoryTag: 'worker',
          lastMessageAt: lastAt,
          createdAt: lastAt,
          otherPartyId: otherId,
          otherPartyName: otherName,
          otherPartyAvatar: otherAvatar,
          otherPartyRole: 'worker',
          unreadCount: 0,
        );
      }
    } catch (e) {
      AppLogger.w('Failed to get thread $threadId: $e');
    }

    return DemoChatData.getThread(
      threadId,
      currentUserId: uid,
      activeRole: activeRole ?? UserRole.seeker,
    );
  }

  @override
  Future<String> getOrCreateThread({
    required String contextType,
    required String contextId,
    required String recipientId,
    String? subject,
    String? bookingCode,
    String? categoryTag,
  }) async {
    final uid = _currentUserId;
    if (uid.isEmpty) return 'offline_thread';

    // 1. Try canonical RPC get_or_create_conversation
    try {
      final res = await _client.rpc('get_or_create_conversation', params: {
        'p_recipient_id': recipientId,
        if (contextId.isNotEmpty && contextId.length == 36) 'p_job_id': contextId,
      });
      if (res != null && res.toString().isNotEmpty) {
        return res.toString();
      }
    } catch (e) {
      AppLogger.w('RPC get_or_create_conversation failed: $e, using direct table fallback');
    }

    // 2. Direct Table query / insert fallback
    try {
      final existing = await _client
          .from('conversations')
          .select('id')
          .or('and(provider_id.eq.$uid,seeker_id.eq.$recipientId),and(provider_id.eq.$recipientId,seeker_id.eq.$uid)')
          .order('last_message_at', ascending: false)
          .limit(1);

      if (existing.isNotEmpty) {
        return existing.first['id'].toString();
      }

      final inserted = await _client
          .from('conversations')
          .insert({
            if (contextId.isNotEmpty && contextId.length == 36) 'job_id': contextId,
            'provider_id': uid,
            'seeker_id': recipientId,
            'last_message_at': DateTime.now().toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      return inserted['id'].toString();
    } catch (e, st) {
      AppLogger.e('Failed to getOrCreateThread direct fallback: $e', e, st);
      return 'offline_thread';
    }
  }

  @override
  Stream<List<ChatMessage>> streamMessages(String threadId) {
    final uid = _currentUserId;
    if (threadId.startsWith('cccccccc-') || uid.isEmpty) {
      return DemoChatData.streamMessages(threadId, uid);
    }

    try {
      return _client
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('conversation_id', threadId)
          .order('created_at', ascending: true)
          .map((rows) => rows.map((r) {
                final sender = r['sender_id']?.toString() ?? '';
                final wasMasked = r['was_masked'] as bool? ?? false;
                final bodyText = r['body']?.toString() ?? '';
                return ChatMessage(
                  id: r['id']?.toString() ?? '',
                  threadId: r['conversation_id']?.toString() ?? threadId,
                  senderId: sender,
                  body: bodyText,
                  attachmentPath: r['image_url']?.toString(),
                  wasMasked: wasMasked,
                  readAt: r['read_at'] != null ? DateTime.tryParse(r['read_at'].toString()) : null,
                  createdAt: r['created_at'] != null
                      ? DateTime.tryParse(r['created_at'].toString()) ?? DateTime.now()
                      : DateTime.now(),
                  isMe: sender == uid,
                );
              }).toList());
    } catch (e) {
      AppLogger.w('streamMessages error: $e, falling back to demo stream');
      return DemoChatData.streamMessages(threadId, uid);
    }
  }

  @override
  Future<ChatMessage> sendMessage({
    required String threadId,
    required String body,
    String? attachmentPath,
  }) async {
    final uid = _currentUserId;

    if (threadId.startsWith('cccccccc-') || uid.isEmpty) {
      return DemoChatData.appendMessage(
        threadId: threadId,
        senderId: uid,
        body: body,
        attachmentPath: attachmentPath,
      );
    }

    try {
      final row = await _client
          .from('messages')
          .insert({
            'conversation_id': threadId,
            'sender_id': uid,
            'body': body,
            'image_url': ?attachmentPath,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      try {
        await _client
            .from('conversations')
            .update({'last_message_at': DateTime.now().toIso8601String()})
            .eq('id', threadId);
      } catch (_) {}

      return ChatMessage(
        id: row['id']?.toString() ?? '',
        threadId: row['conversation_id']?.toString() ?? threadId,
        senderId: uid,
        body: row['body']?.toString() ?? body,
        attachmentPath: row['image_url']?.toString() ?? attachmentPath,
        wasMasked: row['was_masked'] as bool? ?? false,
        readAt: row['read_at'] != null ? DateTime.tryParse(row['read_at'].toString()) : null,
        createdAt: row['created_at'] != null
            ? DateTime.tryParse(row['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        isMe: true,
      );
    } catch (e) {
      AppLogger.w('sendMessage Supabase error: $e, storing in demo session');
      return DemoChatData.appendMessage(
        threadId: threadId,
        senderId: uid,
        body: body,
        attachmentPath: attachmentPath,
      );
    }
  }

  @override
  Future<String?> uploadAttachment(File file) async {
    final uid = _currentUserId;
    if (uid.isEmpty) return null;

    try {
      final ext = file.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
        throw const AppException.validation('Only JPG, PNG and WebP images are permitted');
      }

      final sizeBytes = await file.length();
      if (sizeBytes > 10 * 1024 * 1024) {
        throw const AppException.validation('Image size must be under 10MB');
      }

      final filename = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split(Platform.pathSeparator).last}';
      final path = '$uid/$filename';

      await _client.storage.from('chat-attachments').upload(
        path,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final signedUrl = await _client.storage.from('chat-attachments').createSignedUrl(path, 60 * 60 * 24 * 7);
      return signedUrl;
    } catch (e, st) {
      AppLogger.e('Failed to upload chat attachment', e, st);
      return null;
    }
  }

  @override
  Future<void> markThreadRead(String threadId) async {
    final uid = _currentUserId;
    if (uid.isEmpty) return;

    try {
      await _client
          .from('messages')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('conversation_id', threadId)
          .neq('sender_id', uid)
          .isFilter('read_at', null);
    } catch (e) {
      AppLogger.w('Failed to markThreadRead: $e');
    }
  }

  @override
  Future<bool> blockUser(String userId) async {
    final uid = _currentUserId;
    if (uid.isEmpty) return false;
    try {
      final res = await _client.rpc('block_user', params: {
        'p_blocked_id': userId,
      });
      return res is Map && res['success'] == true;
    } catch (e) {
      AppLogger.e('Failed to block user $userId: $e');
      return false;
    }
  }

  @override
  Future<bool> unblockUser(String userId) async {
    final uid = _currentUserId;
    if (uid.isEmpty) return false;
    try {
      final res = await _client.rpc('unblock_user', params: {
        'p_blocked_id': userId,
      });
      return res is Map && res['success'] == true;
    } catch (e) {
      AppLogger.e('Failed to unblock user $userId: $e');
      return false;
    }
  }

  @override
  Future<bool> isUserBlocked(String userId) async {
    final uid = _currentUserId;
    if (uid.isEmpty) return false;
    try {
      final res = await _client
          .from('chat_blocks')
          .select('blocker_id')
          .eq('blocker_id', uid)
          .eq('blocked_id', userId)
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> reportUser({
    required String reportedUserId,
    required String conversationId,
    required String reason,
    String? details,
  }) async {
    final uid = _currentUserId;
    if (uid.isEmpty) return false;
    try {
      final res = await _client.rpc('report_chat_user', params: {
        'p_reported_user_id': reportedUserId,
        'p_conversation_id': conversationId,
        'p_reason': reason,
        'p_details': details,
      });
      return res is Map && res['success'] == true;
    } catch (e) {
      AppLogger.e('Failed to report user $reportedUserId: $e');
      return false;
    }
  }

  @override
  Future<CallSession> initiateMaskedCall({
    required String recipientId,
    String? bookingCode,
    String? assignmentId,
  }) async {
    try {
      final res = await _edgeApi.maskedCall(
        recipientId: recipientId,
        assignmentId: assignmentId,
      );
      if (res['call_id'] != null) {
        return CallSession(
          callId: res['call_id'].toString(),
          status: 'initiated',
          proxyDisplay: res['virtual_did_number']?.toString() ?? '+91 80 4568 1234 (Proxy)',
          isDemo: false,
          callerName: 'Me',
          recipientName: 'Counterparty',
          bookingCode: bookingCode ?? 'ACTIVE-JOB',
        );
      }
    } catch (e) {
      AppLogger.w('Edge maskedCall failed: $e, using local proxy fallback');
    }

    return CallSession(
      callId: 'call_${DateTime.now().millisecondsSinceEpoch}',
      status: 'initiated',
      proxyDisplay: '+91 80 4719 3200 (Masked Line)',
      isDemo: true,
      callerName: 'Me',
      recipientName: 'Counterparty',
      bookingCode: bookingCode ?? 'ACTIVE-JOB',
    );
  }

  @override
  Future<void> endMaskedCall({
    required String callId,
    int durationSeconds = 0,
  }) async {
    try {
      await _client.rpc('end_masked_call', params: {
        'p_call_id': callId,
        'p_duration_seconds': durationSeconds,
      });
    } catch (_) {}
  }

  @override
  Future<bool> deleteOrArchiveConversation(String conversationId) async {
    try {
      await _client
          .from('conversations')
          .update({'status': 'archived'})
          .eq('id', conversationId);
      return true;
    } catch (e) {
      AppLogger.w('Failed to archive conversation: $e');
      return false;
    }
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final edgeApi = ref.watch(edgeApiClientProvider);
  return SupabaseChatRepository(client, edgeApi);
});
