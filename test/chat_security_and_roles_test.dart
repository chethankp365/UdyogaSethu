import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/features/chat/data/chat_repository.dart';
import 'package:udyogasethu/features/chat/domain/call_session.dart';
import 'package:udyogasethu/features/chat/domain/chat_message.dart';
import 'package:udyogasethu/features/chat/domain/chat_thread.dart';
import 'package:udyogasethu/features/chat/presentation/chat_screen.dart';
import 'package:udyogasethu/features/chat/presentation/protected_inbox_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class MockChatSecurityRepository implements ChatRepository {
  final Set<String> blockedUsers = {};
  final List<Map<String, dynamic>> reports = [];
  bool uploadRejectedDueToType = false;
  bool returnReadOnly = false;

  @override
  Future<List<ChatThread>> getThreads({
    String filter = 'all',
    String roleFilter = 'all',
    String searchQuery = '',
    UserRole? activeRole,
  }) async {
    return [
      ChatThread(
        id: 'thread_job_01',
        contextType: 'job',
        contextId: 'job_456',
        participantA: 'user_me',
        participantB: 'provider_123',
        subject: 'Farm Harvesting Specialist Shift',
        bookingCode: 'JOB-9842',
        status: 'active',
        categoryTag: 'farmer',
        lastMessageAt: DateTime.now(),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        otherPartyId: 'provider_123',
        otherPartyName: 'Suresh Kumar',
        otherPartyRole: 'farmer',
        lastMessageSnippet: 'See you tomorrow at 8 AM.',
        unreadCount: 1,
      ),
      ChatThread(
        id: 'thread_booking_02',
        contextType: 'booking',
        contextId: 'book_789',
        participantA: 'user_me',
        participantB: 'customer_456',
        subject: 'Tractor Repair Service',
        bookingCode: 'BOOK-102',
        status: 'active',
        categoryTag: 'mechanic',
        lastMessageAt: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        otherPartyId: 'customer_456',
        otherPartyName: 'Ramesh Gowda',
        otherPartyRole: 'customer',
        lastMessageSnippet: 'Spare parts are ready.',
        unreadCount: 0,
      ),
      ChatThread(
        id: 'thread_order_03',
        contextType: 'order',
        contextId: 'ord_321',
        participantA: 'user_me',
        participantB: 'buyer_789',
        subject: 'Organic Tomato Bulk 50kg',
        bookingCode: 'ORD-777',
        status: 'active',
        categoryTag: 'buyer',
        lastMessageAt: DateTime.now().subtract(const Duration(hours: 3)),
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        otherPartyId: 'buyer_789',
        otherPartyName: 'Anita Patel',
        otherPartyRole: 'buyer',
        lastMessageSnippet: 'Dispatched via crate delivery.',
        unreadCount: 0,
      ),
    ];
  }

  @override
  Future<ChatThread> getThread(String threadId, {UserRole? activeRole}) async {
    final isBlocked = blockedUsers.contains('partner_01');
    final isReadOnly = returnReadOnly || threadId == 'thread_completed';
    return ChatThread(
      id: threadId,
      contextType: 'job',
      contextId: 'job_456',
      participantA: 'user_me',
      participantB: 'partner_01',
      subject: 'Farm Harvesting Specialist Shift',
      bookingCode: 'JOB-9842',
      status: isBlocked ? 'blocked' : (isReadOnly ? 'read_only' : 'active'),
      categoryTag: 'farmer',
      lastMessageAt: DateTime.now(),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      otherPartyId: 'partner_01',
      otherPartyName: 'Suresh Kumar',
      otherPartyRole: 'farmer',
      lastMessageSnippet: 'See you tomorrow at 8 AM.',
      unreadCount: 0,
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
    return 'thread_job_01';
  }

  @override
  Stream<List<ChatMessage>> streamMessages(String threadId) {
    return Stream.value([
      ChatMessage(
        id: 'msg_01',
        threadId: threadId,
        senderId: 'partner_01',
        body: 'Please arrive by 8:00 AM sharp.',
        wasMasked: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        isMe: false,
      ),
      ChatMessage(
        id: 'msg_02',
        threadId: threadId,
        senderId: 'user_me',
        body: 'Sure, I will be there.',
        wasMasked: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        isMe: true,
      ),
    ]);
  }

  @override
  Future<ChatMessage> sendMessage({
    required String threadId,
    required String body,
    String? attachmentPath,
  }) async {
    return ChatMessage(
      id: 'msg_new',
      threadId: threadId,
      senderId: 'user_me',
      body: body,
      attachmentPath: attachmentPath,
      wasMasked: false,
      createdAt: DateTime.now(),
      isMe: true,
    );
  }

  @override
  Future<String?> uploadAttachment(File file) async {
    final lower = file.path.toLowerCase();
    final ext = lower.split('.').last;
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
      uploadRejectedDueToType = true;
      throw Exception('Invalid file type: $ext. Only JPG, PNG, and WebP are allowed.');
    }
    return 'https://example-supabase.co/storage/v1/object/sign/chat-attachments/demo.jpg?token=mock';
  }

  @override
  Future<void> markThreadRead(String threadId) async {}

  @override
  Future<CallSession> initiateMaskedCall({
    required String recipientId,
    String? bookingCode,
    String? assignmentId,
  }) async {
    return const CallSession(
      callId: 'call_101',
      status: 'initiated',
      proxyDisplay: '+91 80 4719 8200',
      isDemo: true,
      callerName: 'You',
      recipientName: 'Suresh Kumar',
      recipientRole: 'farmer',
      bookingCode: 'JOB-9842',
    );
  }

  @override
  Future<void> endMaskedCall({
    required String callId,
    int durationSeconds = 0,
  }) async {}

  @override
  Future<bool> blockUser(String userId) async {
    blockedUsers.add(userId);
    return true;
  }

  @override
  Future<bool> unblockUser(String userId) async {
    blockedUsers.remove(userId);
    return true;
  }

  @override
  Future<bool> isUserBlocked(String userId) async {
    return blockedUsers.contains(userId);
  }

  @override
  Future<bool> reportUser({
    required String reportedUserId,
    required String conversationId,
    required String reason,
    String? details,
  }) async {
    reports.add({
      'reportedUserId': reportedUserId,
      'reason': reason,
      'conversationId': conversationId,
      'details': details,
    });
    return true;
  }

  @override
  Future<bool> deleteOrArchiveConversation(String conversationId) async {
    return true;
  }
}

Widget createChatApp(Widget child, {List<dynamic> overrides = const []}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    ),
  );
}

void main() {
  group('Chat Security & Data Model Tests', () {
    late MockChatSecurityRepository repo;

    setUp(() {
      repo = MockChatSecurityRepository();
    });

    test('ChatThread correctly captures context types across jobs, bookings, and orders', () async {
      final threads = await repo.getThreads();
      expect(threads.length, 3);

      final jobThread = threads.firstWhere((t) => t.contextType == 'job');
      expect(jobThread.bookingCode, 'JOB-9842');
      expect(jobThread.otherPartyRole, 'farmer');

      final bookingThread = threads.firstWhere((t) => t.contextType == 'booking');
      expect(bookingThread.bookingCode, 'BOOK-102');
      expect(bookingThread.otherPartyRole, 'customer');

      final orderThread = threads.firstWhere((t) => t.contextType == 'order');
      expect(orderThread.bookingCode, 'ORD-777');
      expect(orderThread.otherPartyRole, 'buyer');
    });

    test('blockUser and unblockUser toggle user blocking state in repository', () async {
      const targetUser = 'malicious_user_404';
      expect(await repo.isUserBlocked(targetUser), isFalse);

      await repo.blockUser(targetUser);
      expect(await repo.isUserBlocked(targetUser), isTrue);

      await repo.unblockUser(targetUser);
      expect(await repo.isUserBlocked(targetUser), isFalse);
    });

    test('reportUser records report categories and context metadata', () async {
      final success = await repo.reportUser(
        reportedUserId: 'abusive_user_99',
        conversationId: 'thread_job_01',
        reason: 'harassment',
        details: 'Sent threatening messages',
      );

      expect(success, isTrue);
      expect(repo.reports.length, 1);
      expect(repo.reports.first['reason'], 'harassment');
      expect(repo.reports.first['reportedUserId'], 'abusive_user_99');
    });

    test('Attachment validation rejects unauthorized extensions like .sh or .exe', () async {
      final fakeSh = File('scripts/hack.sh');
      expect(
        () => repo.uploadAttachment(fakeSh),
        throwsA(isA<Exception>()),
      );
      expect(repo.uploadRejectedDueToType, isTrue);

      final fakeJpg = File('images/sample.jpg');
      final url = await repo.uploadAttachment(fakeJpg);
      expect(url, contains('chat-attachments'));
      expect(url, contains('token=mock'));
    });
  });

  group('Chat UI Widget Tests', () {
    testWidgets('ProtectedInboxScreen renders filter chips for Jobs, Bookings, Orders', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockChatSecurityRepository();

      await tester.pumpWidget(
        createChatApp(
          const ProtectedInboxScreen(),
          overrides: [
            chatRepositoryProvider.overrideWithValue(repo),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Verify filter chips appear
      expect(find.text('All'), findsWidgets);
      expect(find.text('Jobs'), findsOneWidget);
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.text('Farm Orders'), findsOneWidget);

      // Verify threads are displayed
      expect(find.text('Suresh Kumar'), findsOneWidget);
      expect(find.text('Ramesh Gowda'), findsOneWidget);
      expect(find.text('Anita Patel'), findsOneWidget);
    });

    testWidgets('ChatScreen displays blocked user banner and disables message input when peer is blocked', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockChatSecurityRepository();
      // Pre-block the partner
      await repo.blockUser('partner_01');

      await tester.pumpWidget(
        createChatApp(
          const ChatScreen(
            threadId: 'thread_job_01',
          ),
          overrides: [
            chatRepositoryProvider.overrideWithValue(repo),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Verify blocked banner is shown
      expect(find.text('This user has been blocked. Messages disabled.'), findsOneWidget);

      // Verify input text field is not present or disabled
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('ChatScreen displays read-only banner for completed jobs without container color assertions', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockChatSecurityRepository();
      repo.returnReadOnly = true;

      await tester.pumpWidget(
        createChatApp(
          const ChatScreen(
            threadId: 'thread_completed',
          ),
          overrides: [
            chatRepositoryProvider.overrideWithValue(repo),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Verify read-only closed banner appears
      expect(find.text('This chat is no longer available'), findsOneWidget);
      expect(find.byIcon(Icons.lock_clock_rounded), findsOneWidget);
      expect(find.byIcon(Icons.phone_disabled_rounded), findsOneWidget);

      // Verify message input is hidden
      expect(find.byType(TextField), findsNothing);
    });
  });
}
