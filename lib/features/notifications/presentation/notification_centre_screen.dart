import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_spacing.dart';
import 'package:udyogasethu/features/notifications/data/notification_repository.dart';
import 'package:udyogasethu/features/notifications/domain/app_notification.dart';
import 'package:udyogasethu/features/privacy/data/consent_repository.dart';
import 'package:udyogasethu/features/privacy/domain/consent_purpose.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class NotificationCentreScreen extends ConsumerStatefulWidget {
  const NotificationCentreScreen({super.key});

  @override
  ConsumerState<NotificationCentreScreen> createState() =>
      _NotificationCentreScreenState();
}

class _NotificationCentreScreenState
    extends ConsumerState<NotificationCentreScreen> {
  String _selectedCategory = 'all';

  void _showWhatsAppPreferenceModal(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(consentRepositoryProvider);
    final currentLog = await repo.getLatestConsent(ConsentPurpose.notifications);
    bool isOptedIn = currentLog?.granted ?? true;

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.mark_chat_unread_rounded, color: Color(0xFF25D366), size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n?.whatsappNotifyOptIn ?? 'WhatsApp Notifications',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.whatsappNotifyDesc ??
                      'Receive critical job updates, booking status, and payment receipts via WhatsApp',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable WhatsApp Alerts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(
                      isOptedIn ? 'Subscribed to transactional alerts' : 'Notifications disabled',
                      style: TextStyle(fontSize: 12, color: isOptedIn ? const Color(0xFF0D6548) : Colors.grey),
                    ),
                    value: isOptedIn,
                    activeTrackColor: const Color(0xFF25D366),
                    onChanged: (val) async {
                      setModalState(() => isOptedIn = val);
                      await repo.recordConsent(purpose: ConsentPurpose.notifications, granted: val);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.whatsappConsentNote ??
                      'By enabling, you agree to receive transactional alerts from UdyogaSethu on your registered mobile number.',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Notification Centre'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 20, color: Color(0xFF0F172A)),
            tooltip: 'WhatsApp Preferences',
            onPressed: () => _showWhatsAppPreferenceModal(context),
          ),
          TextButton(
            onPressed: () async {
              final repo = ref.read(notificationRepositoryProvider);
              await repo.markAllRead();
            },
            child: const Text('Mark all read', style: TextStyle(color: Color(0xFF059669))),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          _buildFilterChips(),

          // Notification List
          Expanded(
            child: notificationsAsync.when(
              data: (list) => _buildList(list),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading notifications: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final categories = [
      {'key': 'all', 'label': 'All'},
      {'key': 'job', 'label': 'Jobs'},
      {'key': 'payment', 'label': 'Payments'},
      {'key': 'order', 'label': 'Orders'},
      {'key': 'safety', 'label': 'Safety'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((c) {
            final isSelected = _selectedCategory == c['key'];
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                selected: isSelected,
                label: Text(c['label']!),
                selectedColor: AppColors.primaryGreen.withAlpha(25),
                checkmarkColor: AppColors.primaryGreen,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primaryGreen : const Color(0xFF475569),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                onSelected: (_) {
                  setState(() => _selectedCategory = c['key']!);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildList(List<AppNotification> allList) {
    final filtered = allList.where((n) {
      if (_selectedCategory == 'all') return true;
      if (_selectedCategory == 'job') {
        return n.type.contains('job') || n.type.contains('assignment') || n.type.contains('application');
      }
      if (_selectedCategory == 'payment') return n.type.contains('payment');
      if (_selectedCategory == 'order') return n.type.contains('order');
      if (_selectedCategory == 'safety') {
        return n.type.contains('sos') || n.type.contains('claim');
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'No notifications found',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF475569)),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'You are completely caught up!',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    // Group by Day: Today, Yesterday, Earlier
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayList = <AppNotification>[];
    final yesterdayList = <AppNotification>[];
    final earlierList = <AppNotification>[];

    for (final n in filtered) {
      final date = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      if (date == today) {
        todayList.add(n);
      } else if (date == yesterday) {
        yesterdayList.add(n);
      } else {
        earlierList.add(n);
      }
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (todayList.isNotEmpty) ...[
          _buildDayHeader('Today'),
          ...todayList.map((n) => _buildNotificationTile(n)),
          const SizedBox(height: AppSpacing.md),
        ],
        if (yesterdayList.isNotEmpty) ...[
          _buildDayHeader('Yesterday'),
          ...yesterdayList.map((n) => _buildNotificationTile(n)),
          const SizedBox(height: AppSpacing.md),
        ],
        if (earlierList.isNotEmpty) ...[
          _buildDayHeader('Earlier'),
          ...earlierList.map((n) => _buildNotificationTile(n)),
        ],
      ],
    );
  }

  Widget _buildDayHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(AppNotification item) {
    final isUnread = !item.isRead;

    IconData iconData = Icons.notifications_outlined;
    Color iconColor = AppColors.primaryGreen;

    if (item.type.contains('payment')) {
      iconData = Icons.currency_rupee;
      iconColor = const Color(0xFF0D9488);
    } else if (item.type.contains('order')) {
      iconData = Icons.shopping_bag_outlined;
      iconColor = const Color(0xFFE65100);
    } else if (item.type.contains('sos')) {
      iconData = Icons.warning_amber_rounded;
      iconColor = const Color(0xFFDC2626);
    } else if (item.type.contains('claim')) {
      iconData = Icons.shield_outlined;
      iconColor = const Color(0xFF7C3AED);
    } else if (item.type.contains('job') || item.type.contains('assignment')) {
      iconData = Icons.work_outline;
      iconColor = const Color(0xFF0D6548);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUnread ? AppColors.primaryGreen.withAlpha(60) : const Color(0xFFE2E8F0),
        ),
      ),
      elevation: 0,
      color: isUnread ? const Color(0xFFF0FDF4) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // Mark as read
          if (!item.isRead) {
            final repo = ref.read(notificationRepositoryProvider);
            await repo.markRead(item.id);
          }

          // Deep-link navigation
          final target = item.targetRoute;
          if (target != null && mounted) {
            context.push(target);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.getDisplayTitle(context),
                            style: TextStyle(
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(item.createdAt),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.getDisplayBody(context),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (isUnread) ...[
                const SizedBox(width: AppSpacing.xs),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF059669),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }
}
