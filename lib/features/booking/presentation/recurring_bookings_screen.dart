import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/booking/domain/recurring_booking.dart';
import 'package:udyogasethu/features/booking/presentation/booking_controller.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

/// Screen allowing providers/customers to view and manage recurring booking schedules.
/// Shows active, paused, or cancelled recurring rules with pause, skip, and change options.
class RecurringBookingsScreen extends ConsumerWidget {
  const RecurringBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final recurringListAsync = ref.watch(recurringBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recurringManageTitle),
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
      ),
      body: recurringListAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(err.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.read(recurringBookingsProvider.notifier).load(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.repeat, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    l10n.recurringNoBookings,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildRecurringCard(context, ref, l10n, item);
            },
          );
        },
      ),
    );
  }

  Widget _buildRecurringCard(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    RecurringBooking item,
  ) {
    final isActive = item.isActive;
    final isPaused = item.isPaused;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.headerGreenDark.withValues(alpha: 0.1),
                  child: const Icon(Icons.repeat, color: AppColors.headerGreenDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.workerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${item.categoryName} • ${item.isWeekly ? l10n.bookingRecurringWeekly : l10n.bookingRecurringMonthly}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.shade50
                        : isPaused
                            ? Colors.amber.shade50
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? Colors.green.shade300
                          : isPaused
                              ? Colors.amber.shade400
                              : Colors.grey.shade400,
                    ),
                  ),
                  child: Text(
                    isActive
                        ? l10n.recurringStatusActive
                        : isPaused
                            ? l10n.recurringStatusPaused
                            : l10n.recurringStatusCancelled,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? Colors.green.shade800
                          : isPaused
                              ? Colors.amber.shade900
                              : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (item.preferredTime != null && item.preferredTime!.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Preferred Time: ${item.preferredTime}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (item.skipDates.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Text(
                    'Skipped dates: ',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  ...item.skipDates.map(
                    (d) => Chip(
                      label: Text(d, style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            const Divider(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!item.isCancelled) ...[
                  // Pause / Resume
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isActive ? AppColors.amberOrange : AppColors.headerGreenDark,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: Icon(isActive ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 16),
                    label: Text(isActive ? l10n.recurringPause : l10n.recurringResume),
                    onPressed: () {
                      if (isActive) {
                        ref.read(recurringBookingsProvider.notifier).pauseBooking(item.id);
                      } else {
                        ref.read(recurringBookingsProvider.notifier).resumeBooking(item.id);
                      }
                    },
                  ),
                  // Skip Next Date
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.skip_next_rounded, size: 16),
                    label: Text(l10n.recurringSkipDate),
                    onPressed: () => _showSkipDateDialog(context, ref, l10n, item),
                  ),
                  // Cancel
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: Text(l10n.recurringCancel),
                    onPressed: () => _confirmCancel(context, ref, l10n, item),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSkipDateDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    RecurringBooking item,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      final success = await ref.read(recurringBookingsProvider.notifier).skipDate(item.id, picked);
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.recurringDateSkipped)),
        );
      }
    }
  }

  void _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    RecurringBooking item,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.recurringCancel),
        content: const Text('Are you sure you want to cancel this recurring schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(recurringBookingsProvider.notifier).cancelBooking(item.id);
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
