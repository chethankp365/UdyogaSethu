import 'dart:async';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/features/chat/domain/chat_message.dart';
import 'package:udyogasethu/features/chat/domain/chat_thread.dart';

/// Seeded demo conversations and messages for presentation.
/// Covers realistic dialogues between Job Seekers, Job Providers, and Farmers.
class DemoChatData {
  DemoChatData._();

  // Demo Participant UUIDs matching supabase/seed/seed_demo.sql
  static const String s1RameshKumar = '00000000-0000-0000-0000-000000000101';
  static const String s2SunitaDevi = '00000000-0000-0000-0000-000000000102';
  static const String s4AnanyaRao = '00000000-0000-0000-0000-000000000104';

  static const String p1AnandSharma = '00000000-0000-0000-0000-000000000201';
  static const String p2MeeraReddy = '00000000-0000-0000-0000-000000000202';
  static const String p3SureshSai = '00000000-0000-0000-0000-000000000203';

  static const String f1GowdaFarmer = '00000000-0000-0000-0000-000000000301';

  // Thread IDs
  static const String thread1Id = 'cccccccc-1111-4111-8111-111111111101';
  static const String thread2Id = 'cccccccc-2222-4222-8222-222222222202';
  static const String thread3Id = 'cccccccc-3333-4333-8333-333333333303';
  static const String thread4Id = 'cccccccc-4444-4444-8444-444444444404';

  // In-memory runtime message store to allow live sending during the session
  static final Map<String, List<ChatMessage>> _runtimeMessages = {
    thread1Id: [
      ChatMessage(
        id: 'm1-1',
        threadId: thread1Id,
        senderId: s1RameshKumar,
        senderName: 'Ramesh Kumar',
        body: 'Namaskara sir, I have 3 years experience with 3-phase wiring and switchboard fitting. Is the HSR complex work starting tomorrow?',
        createdAt: DateTime.now().subtract(const Duration(hours: 5, minutes: 30)),
      ),
      ChatMessage(
        id: 'm1-2',
        threadId: thread1Id,
        senderId: p3SureshSai,
        senderName: 'Suresh Sai (Sai Electricals)',
        body: 'Yes Ramesh, we start tomorrow at 8:30 AM sharp at Sector 1 site. Please bring your tester and wire stripper. Safety shoes are provided on site.',
        createdAt: DateTime.now().subtract(const Duration(hours: 5, minutes: 10)),
      ),
      ChatMessage(
        id: 'm1-3',
        threadId: thread1Id,
        senderId: s1RameshKumar,
        senderName: 'Ramesh Kumar',
        body: 'Understood sir, I will be there at 8:15 AM. Thank you.',
        createdAt: DateTime.now().subtract(const Duration(hours: 4, minutes: 55)),
      ),
      ChatMessage(
        id: 'm1-4',
        threadId: thread1Id,
        senderId: p3SureshSai,
        senderName: 'Suresh Sai (Sai Electricals)',
        body: 'Great, escrow daily payment of ₹880 is locked and will be released upon completion.',
        createdAt: DateTime.now().subtract(const Duration(hours: 4, minutes: 40)),
      ),
    ],
    thread2Id: [
      ChatMessage(
        id: 'm2-1',
        threadId: thread2Id,
        senderId: p2MeeraReddy,
        senderName: 'Meera Reddy (CleanPro)',
        body: 'Namaste Sunita, are you available tomorrow morning for the Indiranagar apartment deep cleaning assignment?',
        createdAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 15)),
      ),
      ChatMessage(
        id: 'm2-2',
        threadId: thread2Id,
        senderId: s2SunitaDevi,
        senderName: 'Sunita Devi',
        body: 'Namaste ma\'am, yes I am available! What are the exact timings?',
        createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 55)),
      ),
      ChatMessage(
        id: 'm2-3',
        threadId: thread2Id,
        senderId: p2MeeraReddy,
        senderName: 'Meera Reddy (CleanPro)',
        body: 'It will be 10:00 AM to 4:00 PM. All vacuum and scrubbing tools are on site. Day wage is ₹650 via escrow.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 40)),
      ),
      ChatMessage(
        id: 'm2-4',
        threadId: thread2Id,
        senderId: s2SunitaDevi,
        senderName: 'Sunita Devi',
        body: 'Confirmed ma\'am, I will reach Sobha Sunbeam flat at 9:50 AM with my ID card.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 20)),
      ),
    ],
    thread3Id: [
      ChatMessage(
        id: 'm3-1',
        threadId: thread3Id,
        senderId: p1AnandSharma,
        senderName: 'Dr. Anand Sharma (Anand Catering)',
        body: 'Gowda-re, we need 2 crates (50kg) of ripe salad tomatoes for a family function this weekend.',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      ChatMessage(
        id: 'm3-2',
        threadId: thread3Id,
        senderId: f1GowdaFarmer,
        senderName: 'Gowda Farmer (Gowda Farms)',
        body: 'Doctor-re, harvest is scheduled for tomorrow afternoon. Tomatoes are fresh and organic, graded Grade-A at ₹34/kg.',
        createdAt: DateTime.now().subtract(const Duration(hours: 5, minutes: 40)),
      ),
      ChatMessage(
        id: 'm3-3',
        threadId: thread3Id,
        senderId: p1AnandSharma,
        senderName: 'Dr. Anand Sharma (Anand Catering)',
        body: 'Excellent, can your delivery pickup van drop them at Koramangala hall by 5:00 PM Friday?',
        createdAt: DateTime.now().subtract(const Duration(hours: 5, minutes: 20)),
      ),
      ChatMessage(
        id: 'm3-4',
        threadId: thread3Id,
        senderId: f1GowdaFarmer,
        senderName: 'Gowda Farmer (Gowda Farms)',
        body: 'Confirmed! Delivery will dispatch at 3:30 PM from Devanahalli with farm delivery slip.',
        createdAt: DateTime.now().subtract(const Duration(hours: 5, minutes: 10)),
      ),
    ],
    thread4Id: [
      ChatMessage(
        id: 'm4-1',
        threadId: thread4Id,
        senderId: s4AnanyaRao,
        senderName: 'Ananya Rao',
        body: 'Hello sir, I am a student available for the 4 PM to 8 PM parcel delivery shift in Koramangala. Can I do this on my scooter?',
        createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
      ),
      ChatMessage(
        id: 'm4-2',
        threadId: thread4Id,
        senderId: p3SureshSai,
        senderName: 'Suresh Sai (FastTrack Hub)',
        body: 'Hello Ananya, yes! Scooter delivery is ideal for local parcels. You will get 18-20 deliveries within 3km. Fuel allowance included.',
        createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 35)),
      ),
      ChatMessage(
        id: 'm4-3',
        threadId: thread4Id,
        senderId: s4AnanyaRao,
        senderName: 'Ananya Rao',
        body: 'That fits my college timetable well. I have uploaded my driving licence and student ID.',
        createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
      ),
      ChatMessage(
        id: 'm4-4',
        threadId: thread4Id,
        senderId: p3SureshSai,
        senderName: 'Suresh Sai (FastTrack Hub)',
        body: 'Welcome to the team! Report to Koramangala hub by 3:45 PM for app dispatch training.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
    ],
  };

  /// Returns threads tailored to the signed-in user ID and active role
  static List<ChatThread> getThreadsForUser({
    required String currentUserId,
    required UserRole activeRole,
    String filter = 'all',
    String searchQuery = '',
  }) {
    final List<ChatThread> result = [];

    switch (activeRole) {
      case UserRole.seeker:
        // Seeker sees threads with Employers/Providers
        result.add(
          ChatThread(
            id: thread1Id,
            contextType: 'job',
            contextId: '55555555-5555-4555-8555-555555555501',
            participantA: p3SureshSai,
            participantB: currentUserId.isNotEmpty ? currentUserId : s1RameshKumar,
            subject: 'Commercial Electrician Helper',
            bookingCode: 'JOB-5501',
            status: 'active',
            categoryTag: 'employer',
            lastMessageAt: DateTime.now().subtract(const Duration(hours: 4, minutes: 40)),
            createdAt: DateTime.now().subtract(const Duration(hours: 6)),
            otherPartyId: p3SureshSai,
            otherPartyName: 'Suresh Sai • Sai Electricals',
            otherPartyRole: 'employer',
            lastMessageSnippet: _getLastSnippet(thread1Id),
            unreadCount: 1,
          ),
        );
        result.add(
          ChatThread(
            id: thread4Id,
            contextType: 'job',
            contextId: '55555555-5555-4555-8555-555555555505',
            participantA: p3SureshSai,
            participantB: currentUserId.isNotEmpty ? currentUserId : s4AnanyaRao,
            subject: 'E-Commerce Parcel Delivery Executive',
            bookingCode: 'JOB-5505',
            status: 'active',
            categoryTag: 'employer',
            lastMessageAt: DateTime.now().subtract(const Duration(minutes: 45)),
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            otherPartyId: p3SureshSai,
            otherPartyName: 'FastTrack Logistics • Koramangala',
            otherPartyRole: 'employer',
            lastMessageSnippet: _getLastSnippet(thread4Id),
            unreadCount: 0,
          ),
        );
        result.add(
          ChatThread(
            id: thread2Id,
            contextType: 'job',
            contextId: '55555555-5555-4555-8555-555555555506',
            participantA: p2MeeraReddy,
            participantB: currentUserId.isNotEmpty ? currentUserId : s2SunitaDevi,
            subject: 'Apartment Deep Cleaning Helper',
            bookingCode: 'JOB-5506',
            status: 'active',
            categoryTag: 'employer',
            lastMessageAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 20)),
            createdAt: DateTime.now().subtract(const Duration(hours: 4)),
            otherPartyId: p2MeeraReddy,
            otherPartyName: 'Meera Reddy • CleanPro Services',
            otherPartyRole: 'employer',
            lastMessageSnippet: _getLastSnippet(thread2Id),
            unreadCount: 0,
          ),
        );
        break;

      case UserRole.provider:
        // Provider sees threads with Applicants / Workers
        result.add(
          ChatThread(
            id: thread1Id,
            contextType: 'job',
            contextId: '55555555-5555-4555-8555-555555555501',
            participantA: currentUserId.isNotEmpty ? currentUserId : p3SureshSai,
            participantB: s1RameshKumar,
            subject: 'Job #JOB-5501: Commercial Electrician',
            bookingCode: 'JOB-5501',
            status: 'active',
            categoryTag: 'worker',
            lastMessageAt: DateTime.now().subtract(const Duration(hours: 4, minutes: 40)),
            createdAt: DateTime.now().subtract(const Duration(hours: 6)),
            otherPartyId: s1RameshKumar,
            otherPartyName: 'Ramesh Kumar (Electrician)',
            otherPartyRole: 'worker',
            lastMessageSnippet: _getLastSnippet(thread1Id),
            unreadCount: 0,
          ),
        );
        result.add(
          ChatThread(
            id: thread4Id,
            contextType: 'job',
            contextId: '55555555-5555-4555-8555-555555555505',
            participantA: currentUserId.isNotEmpty ? currentUserId : p3SureshSai,
            participantB: s4AnanyaRao,
            subject: 'Job #JOB-5505: Parcel Delivery Shift',
            bookingCode: 'JOB-5505',
            status: 'active',
            categoryTag: 'worker',
            lastMessageAt: DateTime.now().subtract(const Duration(minutes: 45)),
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            otherPartyId: s4AnanyaRao,
            otherPartyName: 'Ananya Rao (Student Applicant)',
            otherPartyRole: 'worker',
            lastMessageSnippet: _getLastSnippet(thread4Id),
            unreadCount: 1,
          ),
        );
        result.add(
          ChatThread(
            id: thread2Id,
            contextType: 'job',
            contextId: '55555555-5555-4555-8555-555555555506',
            participantA: currentUserId.isNotEmpty ? currentUserId : p2MeeraReddy,
            participantB: s2SunitaDevi,
            subject: 'Job #JOB-5506: Deep Cleaning Helper',
            bookingCode: 'JOB-5506',
            status: 'active',
            categoryTag: 'worker',
            lastMessageAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 20)),
            createdAt: DateTime.now().subtract(const Duration(hours: 4)),
            otherPartyId: s2SunitaDevi,
            otherPartyName: 'Sunita Devi (Cleaning Worker)',
            otherPartyRole: 'worker',
            lastMessageSnippet: _getLastSnippet(thread2Id),
            unreadCount: 0,
          ),
        );
        break;

      case UserRole.farmer:
        // Farmer sees threads with Produce Buyers & Orders
        result.add(
          ChatThread(
            id: thread3Id,
            contextType: 'order',
            contextId: '77777777-7777-4777-8777-777777777701',
            participantA: currentUserId.isNotEmpty ? currentUserId : f1GowdaFarmer,
            participantB: p1AnandSharma,
            subject: 'Produce Order #ORD-7701: 50kg Organic Tomatoes',
            bookingCode: 'ORD-7701',
            status: 'active',
            categoryTag: 'customer',
            lastMessageAt: DateTime.now().subtract(const Duration(hours: 5, minutes: 10)),
            createdAt: DateTime.now().subtract(const Duration(hours: 6)),
            otherPartyId: p1AnandSharma,
            otherPartyName: 'Dr. Anand Sharma (Anand Catering)',
            otherPartyRole: 'customer',
            lastMessageSnippet: _getLastSnippet(thread3Id),
            unreadCount: 1,
          ),
        );
        break;
    }

    // Apply status filter
    List<ChatThread> filtered = result;
    if (filter == 'active') {
      filtered = filtered.where((t) => t.status == 'active').toList();
    } else if (filter == 'completed') {
      filtered = filtered.where((t) => t.isReadOnly).toList();
    } else if (filter == 'job') {
      filtered = filtered.where((t) => t.contextType == 'job').toList();
    } else if (filter == 'order') {
      filtered = filtered.where((t) => t.contextType == 'order').toList();
    }

    // Apply search query
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      filtered = filtered.where((t) {
        return t.subject.toLowerCase().contains(q) ||
            t.otherPartyName.toLowerCase().contains(q) ||
            t.bookingCode.toLowerCase().contains(q) ||
            (t.lastMessageSnippet?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return filtered;
  }

  static ChatThread getThread(String threadId, {String? currentUserId, UserRole activeRole = UserRole.seeker}) {
    final list = getThreadsForUser(currentUserId: currentUserId ?? '', activeRole: activeRole);
    return list.firstWhere(
      (t) => t.id == threadId,
      orElse: () => ChatThread(
        id: threadId,
        contextType: 'job',
        contextId: '',
        participantA: currentUserId ?? '',
        participantB: '',
        subject: 'Protected Conversation',
        bookingCode: 'CHAT-DEMO',
        status: 'active',
        categoryTag: 'general',
        lastMessageAt: DateTime.now(),
        createdAt: DateTime.now(),
        otherPartyId: '',
        otherPartyName: 'Verified Counterparty',
        otherPartyRole: 'employer',
        lastMessageSnippet: 'Demo conversation',
      ),
    );
  }

  static final Map<String, StreamController<List<ChatMessage>>> _streamControllers = {};

  static List<ChatMessage> getMessages(String threadId, String currentUserId) {
    final msgs = _runtimeMessages[threadId] ?? [];
    return msgs
        .map((m) => ChatMessage(
              id: m.id,
              threadId: m.threadId,
              senderId: m.senderId,
              senderName: m.senderName,
              body: m.body,
              attachmentPath: m.attachmentPath,
              wasMasked: m.wasMasked,
              readAt: m.readAt,
              createdAt: m.createdAt,
              isMe: m.senderId == currentUserId || (currentUserId.isEmpty && (m.senderId.endsWith('101') || m.senderId.endsWith('102') || m.senderId.endsWith('104'))),
            ))
        .toList();
  }

  static Stream<List<ChatMessage>> streamMessages(String threadId, String currentUserId) async* {
    yield getMessages(threadId, currentUserId);
    final controller = _streamControllers.putIfAbsent(
      threadId,
      () => StreamController<List<ChatMessage>>.broadcast(),
    );
    yield* controller.stream;
  }

  static ChatMessage appendMessage({
    required String threadId,
    required String senderId,
    required String body,
    String? attachmentPath,
  }) {
    final newMsg = ChatMessage(
      id: 'demo_msg_${DateTime.now().millisecondsSinceEpoch}',
      threadId: threadId,
      senderId: senderId.isNotEmpty ? senderId : s1RameshKumar,
      body: body,
      attachmentPath: attachmentPath,
      createdAt: DateTime.now(),
      isMe: true,
    );

    _runtimeMessages.putIfAbsent(threadId, () => []).add(newMsg);

    // Notify stream listeners
    if (_streamControllers.containsKey(threadId)) {
      _streamControllers[threadId]!.add(getMessages(threadId, senderId));
    }

    // Trigger simulated realistic reply after a short delay for interactive presentation
    _simulateAutoReply(threadId, senderId);

    return newMsg;
  }

  static void _simulateAutoReply(String threadId, String currentUserId) {
    Future.delayed(const Duration(milliseconds: 1400), () {
      String replyText;
      String replySenderId;
      String replySenderName;

      switch (threadId) {
        case thread1Id:
          replySenderId = p3SureshSai;
          replySenderName = 'Suresh Sai (Sai Electricals)';
          replyText = 'Received your message! I will meet you at the site gate. Please keep your safety shoes on.';
          break;
        case thread2Id:
          replySenderId = p2MeeraReddy;
          replySenderName = 'Meera Reddy (CleanPro)';
          replyText = 'Thanks for confirming! The apartment supervisor has been informed of your entry.';
          break;
        case thread3Id:
          replySenderId = f1GowdaFarmer;
          replySenderName = 'Gowda Farmer (Gowda Farms)';
          replyText = 'Noted! The crates are being packed now with cold-chain lining.';
          break;
        case thread4Id:
          replySenderId = p3SureshSai;
          replySenderName = 'FastTrack Dispatch Hub';
          replyText = 'Delivery route map and delivery bags will be handed to you upon arrival.';
          break;
        default:
          replySenderId = 'counterparty_id';
          replySenderName = 'Counterparty';
          replyText = 'Thank you for your message. We have received it and will follow up shortly.';
          break;
      }

      final autoMsg = ChatMessage(
        id: 'reply_${DateTime.now().millisecondsSinceEpoch}',
        threadId: threadId,
        senderId: replySenderId,
        senderName: replySenderName,
        body: replyText,
        createdAt: DateTime.now(),
        isMe: false,
      );

      _runtimeMessages.putIfAbsent(threadId, () => []).add(autoMsg);
      if (_streamControllers.containsKey(threadId)) {
        _streamControllers[threadId]!.add(getMessages(threadId, currentUserId));
      }
    });
  }

  static String _getLastSnippet(String threadId) {
    final msgs = _runtimeMessages[threadId];
    if (msgs != null && msgs.isNotEmpty) {
      return msgs.last.body;
    }
    return 'Tap to view conversation';
  }
}
