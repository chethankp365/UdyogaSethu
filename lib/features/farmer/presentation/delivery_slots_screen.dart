import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../marketplace/data/orders_repository.dart';
import '../../marketplace/domain/delivery_slot.dart';

class DeliverySlotsScreen extends ConsumerStatefulWidget {
  final String? farmerId;
  const DeliverySlotsScreen({super.key, this.farmerId});

  @override
  ConsumerState<DeliverySlotsScreen> createState() => _DeliverySlotsScreenState();
}

class _DeliverySlotsScreenState extends ConsumerState<DeliverySlotsScreen> {
  bool _isLoading = false;

  String _getFarmerId(WidgetRef ref) {
    if (widget.farmerId != null) return widget.farmerId!;
    final user = ref.watch(currentUserProvider);
    return user?.id ?? '44444444-4444-4444-8444-444444444401';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final farmerId = _getFarmerId(ref);
    final slotsAsync = ref.watch(farmerDeliverySlotsProvider(farmerId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          l10n?.farmerDeliverySlotsTitle ?? 'Farm Delivery & Pickup Slots',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(farmerDeliverySlotsProvider(farmerId)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSlotModal(context, farmerId, l10n),
        backgroundColor: const Color(0xFF0D6548),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          l10n?.addSlotButton ?? '+ Add Delivery Slot',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: slotsAsync.when(
        data: (slots) {
          if (slots.isEmpty) {
            return _buildEmptyState(context, farmerId, l10n);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(farmerDeliverySlotsProvider(farmerId)),
            color: const Color(0xFF0D6548),
            child: ListView.builder(
              padding: AppSpacing.fabListPadding,
              itemCount: slots.length,
              itemBuilder: (ctx, i) => _buildSlotCard(slots[i], l10n),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF0D6548)),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              Text('Failed to load slots: $err'),
              TextButton(
                onPressed: () => ref.refresh(farmerDeliverySlotsProvider(farmerId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String farmerId, AppLocalizations? l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F4EA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month,
                size: 40,
                color: Color(0xFF0D6548),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.noSlotsConfiguredTitle ?? 'No Delivery Slots Configured',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.noSlotsConfiguredSubtitle ??
                  'Create delivery or pickup windows so buyers can select convenient harvest delivery times.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _openAddSlotModal(context, farmerId, l10n),
              icon: const Icon(Icons.add),
              label: Text(l10n?.createFirstSlot ?? 'Create First Slot'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6548),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotCard(DeliverySlot slot, AppLocalizations? l10n) {
    final percentUsed = (slot.used / slot.capacity).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Date & Window
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slot.formattedDate,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Color(0xFF0D6548)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              slot.formattedWindow,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0D6548),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Mode pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    slot.mode == DeliveryMode.sameDay
                        ? (l10n?.slotSameDay ?? 'Same Day')
                        : (slot.mode == DeliveryMode.nextDay
                            ? (l10n?.slotNextDay ?? 'Next Day')
                            : (l10n?.slotPreOrder ?? 'Pre-Order')),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D6548),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Text(
              slot.freshnessNote,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),

            // Capacity meter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${slot.used} of ${slot.capacity} orders booked',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  slot.isFull ? 'FULL' : '${slot.availableCapacity} spots left',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: slot.isFull ? Colors.red : const Color(0xFF059669),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentUsed,
                minHeight: 6,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  slot.isFull
                      ? Colors.red
                      : (percentUsed > 0.8 ? Colors.amber : const Color(0xFF00875A)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddSlotModal(BuildContext context, String farmerId, AppLocalizations? l10n) {
    DateTime selectedDate = DateTime.now();
    TimeOfDay startTime = const TimeOfDay(hour: 7, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 11, minute: 0);
    int capacity = 10;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n?.createDeliverySlotModalTitle ?? 'Add Delivery Window Slot',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Date Picker Tile
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today, color: Color(0xFF0D6548)),
                    title: const Text('Slot Date', style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                  ),

                  // Start Time
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time, color: Color(0xFF0D6548)),
                    title: const Text('Window Start', style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      startTime.format(context),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (picked != null) {
                        setModalState(() => startTime = picked);
                      }
                    },
                  ),

                  // End Time
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time_filled, color: Color(0xFF0D6548)),
                    title: const Text('Window End', style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      endTime.format(context),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: endTime,
                      );
                      if (picked != null) {
                        setModalState(() => endTime = picked);
                      }
                    },
                  ),

                  // Capacity Stepper
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Slot Capacity (Max Orders)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: capacity > 1
                                ? () => setModalState(() => capacity -= 1)
                                : null,
                          ),
                          Text(
                            '$capacity',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setModalState(() => capacity += 1),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setModalState(() => _isLoading = true);
                            try {
                              final startStr =
                                  '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00';
                              final endStr =
                                  '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00';

                              final repo = ref.read(ordersRepositoryProvider);
                              await repo.createDeliverySlot(
                                date: selectedDate,
                                windowStart: startStr,
                                windowEnd: endStr,
                                capacity: capacity,
                              );

                              ref.invalidate(farmerDeliverySlotsProvider(farmerId));
                              if (ctx.mounted) {
                                Navigator.pop(sheetCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Delivery slot created successfully!'),
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() => _isLoading = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to create slot: $e')),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6548),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(l10n?.saveSlotButton ?? 'Save Delivery Slot'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
