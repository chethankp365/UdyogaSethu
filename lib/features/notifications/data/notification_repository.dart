// Data layer: NotificationRepository (Step P7.4)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/supabase/supabase_service.dart';
import 'package:udyogasethu/features/notifications/domain/app_notification.dart';

abstract class NotificationRepository {
  Stream<List<AppNotification>> streamNotifications();
  Future<List<AppNotification>> getNotifications();
  Future<void> markRead(String notificationId);
  Future<void> markAllRead();
  Future<int> getUnreadCount();
  Future<void> registerDeviceToken(String token, {String platform = 'android'});
  Future<void> removeDeviceToken(String token);
}

class SupabaseNotificationRepository implements NotificationRepository {
  final SupabaseClient _client;

  SupabaseNotificationRepository(this._client);

  String get _currentUserId => _client.auth.currentUser?.id ?? '';

  @override
  Stream<List<AppNotification>> streamNotifications() {
    try {
      if (_currentUserId.isEmpty) {
        return Stream.value(_getDemoNotifications());
      }

      return _client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', _currentUserId)
          .order('created_at', ascending: false)
          .map((rows) => rows.map((r) => AppNotification.fromJson(r)).toList());
    } catch (_) {
      return Stream.value(_getDemoNotifications());
    }
  }

  @override
  Future<List<AppNotification>> getNotifications() async {
    if (_currentUserId.isEmpty) {
      return _getDemoNotifications();
    }

    try {
      final res = await _client
          .from('notifications')
          .select()
          .eq('user_id', _currentUserId)
          .order('created_at', ascending: false);

      return (res as List).map((r) => AppNotification.fromJson(r)).toList();
    } catch (_) {
      return _getDemoNotifications();
    }
  }

  @override
  Future<void> markRead(String notificationId) async {
    if (_currentUserId.isEmpty) return;

    try {
      await _client.rpc('mark_notification_read', params: {
        'p_notification_id': notificationId,
      });
    } catch (_) {}
  }

  @override
  Future<void> markAllRead() async {
    if (_currentUserId.isEmpty) return;

    try {
      await _client.rpc('mark_all_notifications_read');
    } catch (_) {}
  }

  @override
  Future<int> getUnreadCount() async {
    if (_currentUserId.isEmpty) return 2;

    try {
      final res = await _client.rpc('get_unread_notification_count');
      return (res as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> registerDeviceToken(String token, {String platform = 'android'}) async {
    if (_currentUserId.isEmpty || token.isEmpty) return;

    try {
      await _client.rpc('register_device_token', params: {
        'p_token': token,
        'p_platform': platform,
      });
    } catch (_) {}
  }

  @override
  Future<void> removeDeviceToken(String token) async {
    if (_currentUserId.isEmpty || token.isEmpty) return;

    try {
      await _client.rpc('remove_device_token', params: {
        'p_token': token,
      });
    } catch (_) {}
  }

  List<AppNotification> _getDemoNotifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'notif-01',
        userId: 'demo-user',
        type: 'assignment_status',
        titleKey: 'notif_assignment_status_title',
        bodyKey: 'notif_assignment_status_body',
        params: {
          'booking_code': 'BOOK-9842',
          'job_title': 'Farm Harvesting Specialist',
          'status': 'in_progress',
        },
        readAt: null,
        createdAt: now.subtract(const Duration(minutes: 15)),
      ),
      AppNotification(
        id: 'notif-02',
        userId: 'demo-user',
        type: 'payment_update',
        titleKey: 'notif_payment_received_title',
        bodyKey: 'notif_payment_received_body',
        params: {
          'amount_paise': 185000,
          'status': 'held_in_escrow',
        },
        readAt: null,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: 'notif-03',
        userId: 'demo-user',
        type: 'order_update',
        titleKey: 'notif_order_status_title',
        bodyKey: 'notif_order_status_body',
        params: {
          'order_code': 'ORD-89421',
          'status': 'dispatched',
        },
        readAt: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      ),
    ];
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseNotificationRepository(client);
});

final notificationsStreamProvider = StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.streamNotifications();
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getUnreadCount();
});
