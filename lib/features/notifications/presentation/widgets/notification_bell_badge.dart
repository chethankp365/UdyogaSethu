// Widget: NotificationBellBadge (Step P7.4)
// Reusable notification bell with realtime unread counter badge for all app headers

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/features/notifications/data/notification_repository.dart';

class NotificationBellBadge extends ConsumerWidget {
  final Color iconColor;

  const NotificationBellBadge({
    super.key,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamAsync = ref.watch(notificationsStreamProvider);

    int unreadCount = 0;
    streamAsync.whenData((list) {
      unreadCount = list.where((n) => !n.isRead).length;
    });

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          onPressed: () => context.push(AppRoutes.notifications),
          icon: Icon(Icons.notifications_outlined, color: iconColor, size: 24),
          tooltip: 'Notifications',
        ),
        if (unreadCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Center(
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
