// Service: NotificationService (Step P7.4)
// Push notification initialization, token lifecycle, local heads-up alerts and deep-link routing

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/features/notifications/data/notification_repository.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  AppLogger.i('Handling a background push message: ${message.messageId}');
}

class NotificationService {
  final Ref _ref;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  NotificationService(this._ref);

  Future<void> initialize({void Function(String route)? onNavigate}) async {
    if (_initialized) return;

    try {
      // 1. Initialize Firebase if not already initialized
      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp();
        }
      } catch (e) {
        AppLogger.w('Firebase initialization skipped or failed: $e');
      }

      // 2. Initialize Flutter Local Notifications
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && onNavigate != null) {
            onNavigate(payload);
          }
        },
      );

      // Create Android Notification Channel
      if (!kIsWeb && Platform.isAndroid) {
        const channel = AndroidNotificationChannel(
          'udyoga_notifications',
          'Udyoga Notifications',
          description: 'High-priority updates for job alerts, payments and safety',
          importance: Importance.high,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      // 3. Register FCM Handlers if Firebase is active
      if (Firebase.apps.isNotEmpty) {
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // Foreground Message Handler
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _showForegroundNotification(message);
        });

        // App opened from background notification tap
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          final route = message.data['route'] as String?;
          if (route != null && onNavigate != null) {
            onNavigate(route);
          }
        });

        // App opened from terminated state
        final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
        if (initialMessage != null) {
          final route = initialMessage.data['route'] as String?;
          if (route != null && onNavigate != null) {
            onNavigate(route);
          }
        }

        // Listen for token refresh
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          _registerToken(newToken);
        });
      }

      _initialized = true;
    } catch (e) {
      AppLogger.e('NotificationService init error', e);
    }
  }

  Future<void> requestPermissionAndRegister() async {
    try {
      if (Firebase.apps.isEmpty) return;

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await messaging.getToken();
        if (token != null) {
          await _registerToken(token);
        }
      }
    } catch (e) {
      AppLogger.w('FCM token registration skipped or failed: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      final repo = _ref.read(notificationRepositoryProvider);
      final platform = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');
      await repo.registerDeviceToken(token, platform: platform);
      AppLogger.i('Device token registered with platform: $platform');
    } catch (e) {
      AppLogger.e('Failed to register token in repo', e);
    }
  }

  Future<void> unregisterTokenOnSignOut() async {
    try {
      if (Firebase.apps.isEmpty) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        final repo = _ref.read(notificationRepositoryProvider);
        await repo.removeDeviceToken(token);
      }
    } catch (_) {}
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = const AndroidNotificationDetails(
      'udyoga_notifications',
      'Udyoga Notifications',
      channelDescription: 'High-priority updates for job alerts, payments and safety',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: message.data['route'] as String?,
    );
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});
