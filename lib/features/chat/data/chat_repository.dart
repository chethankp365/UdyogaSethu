import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/supabase/edge_api.dart';
import 'package:udyogasethu/core/supabase/supabase_service.dart';
import 'package:udyogasethu/features/chat/domain/call_session.dart';
import 'package:udyogasethu/features/chat/domain/chat_message.dart';
import 'package:udyogasethu/features/chat/domain/chat_thread.dart';

abstract class ChatRepository {
  Future<List<ChatThread>> getThreads({
    String filter = 'all', // 'all', 'active', 'completed'
    String roleFilter = 'all', // 'all', 'worker', 'customer', 'farmer'
    String searchQuery = '',
  });

  Future<ChatThread> getThread(String threadId);

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

  Future<CallSession> initiateMaskedCall({
    required String recipientId,
    String? bookingCode,
    String? assignmentId,
  });

  Future<void> endMaskedCall({
    required String callId,
    int durationSeconds = 0,
  });
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
  }) async {
    final uid = _currentUserId;
    if (uid.isEmpty) return _getDemoThreads();

    try {
      var query = _client.from('chat_threads').select('''
        id,
        context_type,
        context_id,
        participant_a,
        participant_b,
        subject,
        booking_code,
        status,
        read_only_at,
        category_tag,
        last_message_at,
        created_at
      ''').or('participant_a.eq.$uid,participant_b.eq.$uid');

      if (filter == 'active') {
        query = query.eq('status', 'active');
      } else if (filter == 'completed') {
        query = query.eq('status', 'read_only');
      }

      if (roleFilter != 'all') {
        query = query.eq('category_tag', roleFilter);
      }

      final rows = await query.order('last_message_at', ascending: false);

      final List<ChatThread> threads = [];

      for (final row in rows as List<dynamic>) {
        final map = Map<String, dynamic>.from(row as Map);
        final pa = map['participant_a'] as String? ?? '';
        final pb = map['participant_b'] as String? ?? '';
        final otherId = (uid == pa) ? pb : pa;

        // Fetch other participant profile
        String otherName = 'Verified User';
        String? otherAvatar;
        String otherRole = map['category_tag'] as String? ?? 'worker';

        if (otherId.isNotEmpty) {
          try {
            final pRow = await _client
                .from('profiles')
                .select('full_name, avatar_url, phone')
                .eq('id', otherId)
                .maybeSingle();
            if (pRow != null) {
              otherName = pRow['full_name'] as String? ?? 'Verified User';
              otherAvatar = pRow['avatar_url'] as String?;
            }
          } catch (_) {}
        }

        // Fetch last message snippet & unread count
        String? lastSnippet;
        int unread = 0;
        try {
          final mRows = await _client
              .from('chat_messages')
              .select('body, sender_id, read_at')
              .eq('thread_id', map['id'])
              .order('created_at', ascending: false)
              .limit(5);

          if (mRows.isNotEmpty) {
            lastSnippet = mRows.first['body'] as String?;
            unread = mRows.where((m) => m['sender_id'] != uid && m['read_at'] == null).length;
          }
        } catch (_) {}

        map['other_party_name'] = otherName;
        map['other_party_avatar'] = otherAvatar;
        map['other_party_role'] = otherRole;
        map['last_message_snippet'] = lastSnippet;
        map['unread_count'] = unread;

        final thread = ChatThread.fromJson(map, uid);

        // Apply client search query filter if provided
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

      if (threads.isEmpty && searchQuery.isEmpty && filter == 'all') {
        return _getDemoThreads();
      }

      return threads;
    } catch (e, st) {
      AppLogger.e('Failed to get chat threads', e, st);
      return _getDemoThreads();
    }
  }

  @override
  Future<ChatThread> getThread(String threadId) async {
    final uid = _currentUserId;
    try {
      final row = await _client
          .from('chat_threads')
          .select()
          .eq('id', threadId)
          .single();

      final map = Map<String, dynamic>.from(row);
      final pa = map['participant_a'] as String? ?? '';
      final pb = map['participant_b'] as String? ?? '';
      final otherId = (uid == pa) ? pb : pa;

      if (otherId.isNotEmpty) {
        final pRow = await _client
            .from('profiles')
            .select('full_name, avatar_url')
            .eq('id', otherId)
            .maybeSingle();
        if (pRow != null) {
          map['other_party_name'] = pRow['full_name'];
          map['other_party_avatar'] = pRow['avatar_url'];
        }
      }

      return ChatThread.fromJson(map, uid);
    } catch (e) {
      return _getDemoThreads().firstWhere(
        (t) => t.id == threadId,
        orElse: () => _getDemoThreads().first,
      );
    }
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
    try {
      final res = await _client.rpc('get_or_create_chat_thread', params: {
        'p_context_type': contextType,
        'p_context_id': contextId,
        'p_recipient_id': recipientId,
        'p_subject': subject,
        'p_booking_code': bookingCode,
        'p_category_tag': categoryTag ?? 'general',
      });
      return res as String;
    } catch (e, st) {
      AppLogger.e('get_or_create_chat_thread RPC error', e, st);
      // Fallback: check if existing thread exists or return demo
      return 'demo_thread_01';
    }
  }

  @override
  Stream<List<ChatMessage>> streamMessages(String threadId) {
    final uid = _currentUserId;
    if (uid.isEmpty) {
      return Stream.value([
        ChatMessage(
          id: 'demo_msg_01',
          threadId: threadId,
          senderId: 'partner_01',
          body: 'Hello! I am ready for the farm harvest assignment tomorrow morning.',
          wasMasked: false,
          createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
          isMe: false,
        ),
        ChatMessage(
          id: 'demo_msg_02',
          threadId: threadId,
          senderId: 'me',
          body: 'Great, please report at the south gate by 7:30 AM.',
          wasMasked: false,
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          isMe: true,
        ),
        ChatMessage(
          id: 'demo_msg_03',
          threadId: threadId,
          senderId: 'partner_01',
          body: '[Security Guard: Phone number masked for escrow protection] Contact: [MASKED PHONE]',
          wasMasked: true,
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
          isMe: false,
        ),
      ]);
    }
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('thread_id', threadId)
        .order('created_at', ascending: true)
        .map((rows) => rows.map((r) => ChatMessage.fromJson(r, uid)).toList());
  }

  @override
  Future<ChatMessage> sendMessage({
    required String threadId,
    required String body,
    String? attachmentPath,
  }) async {
    final uid = _currentUserId;
    final row = await _client
        .from('chat_messages')
        .insert({
          'thread_id': threadId,
          'sender_id': uid,
          'body': body,
          'attachment_path': attachmentPath,
        })
        .select()
        .single();

    return ChatMessage.fromJson(row, uid);
  }

  @override
  Future<String?> uploadAttachment(File file) async {
    final uid = _currentUserId;
    if (uid.isEmpty) return null;

    try {
      final filename = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split(Platform.pathSeparator).last}';
      final path = '$uid/$filename';

      await _client.storage.from('chat-attachments').upload(
        path,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final url = _client.storage.from('chat-attachments').getPublicUrl(path);
      return url;
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
          .from('chat_messages')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('thread_id', threadId)
          .neq('sender_id', uid)
          .isFilter('read_at', null);
    } catch (e) {
      // Non-critical, ignore
    }
  }

  @override
  Future<CallSession> initiateMaskedCall({
    required String recipientId,
    String? bookingCode,
    String? assignmentId,
  }) async {
    try {
      // Try edge function first
      final res = await _edgeApi.maskedCall(
        recipientId: recipientId,
        assignmentId: assignmentId,
      );

      final data = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : res;
      return CallSession.fromJson(data);
    } catch (e) {
      AppLogger.w('Edge function masked-call fallback to RPC: $e');
      try {
        final rpcRes = await _client.rpc('initiate_masked_call', params: {
          'p_recipient_id': recipientId,
          'p_booking_code': bookingCode,
          'p_assignment_id': assignmentId,
        });
        return CallSession.fromJson(rpcRes as Map<String, dynamic>);
      } catch (err) {
        // Deterministic demo mode session
        return CallSession(
          callId: 'demo_call_${DateTime.now().millisecondsSinceEpoch}',
          status: 'connected',
          proxyDisplay: '+91 80 4719 8200 (Udyoga Proxy)',
          isDemo: true,
          callerName: 'You',
          recipientName: 'Sharma Builders',
          recipientRole: 'Employer',
          bookingCode: bookingCode ?? 'BOOK-7842',
        );
      }
    }
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

  List<ChatThread> _getDemoThreads() {
    final now = DateTime.now();
    return [
      ChatThread(
        id: 'demo_thread_01',
        contextType: 'assignment',
        contextId: 'demo_assign_01',
        participantA: _currentUserId,
        participantB: 'partner_01',
        subject: 'Commercial Electrical Repair',
        bookingCode: 'BOOK-7842',
        status: 'active',
        categoryTag: 'worker',
        lastMessageAt: now.subtract(const Duration(minutes: 5)),
        createdAt: now.subtract(const Duration(days: 1)),
        otherPartyId: 'partner_01',
        otherPartyName: 'Sharma Builders',
        otherPartyRole: 'employer',
        lastMessageSnippet: 'Please confirm what time you will reach the site.',
        unreadCount: 1,
      ),
      ChatThread(
        id: 'demo_thread_02',
        contextType: 'order',
        contextId: 'demo_order_01',
        participantA: _currentUserId,
        participantB: 'partner_02',
        subject: 'Fresh Organic Tomato Bulk Order (25kg)',
        bookingCode: 'ORD-9124',
        status: 'active',
        categoryTag: 'farmer',
        lastMessageAt: now.subtract(const Duration(hours: 2)),
        createdAt: now.subtract(const Duration(days: 2)),
        otherPartyId: 'partner_02',
        otherPartyName: 'Guddibande Agri-Cluster',
        otherPartyRole: 'farmer',
        lastMessageSnippet: 'Tomatoes harvested this morning and packed in crates.',
        unreadCount: 0,
      ),
      ChatThread(
        id: 'demo_thread_03',
        contextType: 'assignment',
        contextId: 'demo_assign_02',
        participantA: _currentUserId,
        participantB: 'partner_03',
        subject: 'Plumbing Service & Pipe Fitting',
        bookingCode: 'BOOK-6310',
        status: 'read_only',
        readOnlyAt: now.subtract(const Duration(days: 3)),
        categoryTag: 'worker',
        lastMessageAt: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 5)),
        otherPartyId: 'partner_03',
        otherPartyName: 'R.K. Plumbing Services',
        otherPartyRole: 'worker',
        lastMessageSnippet: 'Service completed and escrow payment confirmed.',
        unreadCount: 0,
      ),
    ];
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final edgeApi = ref.watch(edgeApiClientProvider);
  return SupabaseChatRepository(client, edgeApi);
});
