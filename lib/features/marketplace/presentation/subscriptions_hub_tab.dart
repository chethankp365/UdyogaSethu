import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/marketplace/presentation/subscriptions_controller.dart';
import 'package:udyogasethu/features/marketplace/presentation/widgets/create_group_order_modal.dart';
import 'package:udyogasethu/features/marketplace/presentation/widgets/create_subscription_modal.dart';
import 'package:udyogasethu/features/marketplace/presentation/widgets/group_order_card.dart';
import 'package:udyogasethu/features/marketplace/presentation/widgets/join_group_order_modal.dart';
import 'package:udyogasethu/features/marketplace/presentation/widgets/subscription_card.dart';

class SubscriptionsHubTab extends ConsumerStatefulWidget {
  const SubscriptionsHubTab({super.key});

  @override
  ConsumerState<SubscriptionsHubTab> createState() => _SubscriptionsHubTabState();
}

class _SubscriptionsHubTabState extends ConsumerState<SubscriptionsHubTab> {
  Map<String, dynamic>? _lastSchedulerResult;
  bool _isRunningScheduler = false;

  Future<void> _runSchedulerNow() async {
    setState(() => _isRunningScheduler = true);
    try {
      final res = await ref.read(subscriptionsControllerProvider.notifier).runSchedulerNow();
      setState(() => _lastSchedulerResult = res);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Scheduler ran: ${res['generated_orders']} orders created, ${res['skipped_orders']} skipped, ${res['stock_failures']} shortages.',
            ),
            backgroundColor: AppColors.headerGreenDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scheduler failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRunningScheduler = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionsAsync = ref.watch(userSubscriptionsProvider);
    final groupOrdersAsync = ref.watch(communityGroupOrdersProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header: DAILY FARM SUBSCRIPTIONS (Screen 30)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAILY FARM SUBSCRIPTIONS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Fresh morning milk and organic veggie boxes',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.headerGreenDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 34),
                ),
                icon: const Icon(Icons.add_rounded, size: 15),
                label: const Text(
                  '+ New Subscription',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                onPressed: () => CreateSubscriptionModal.show(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Subscriptions List
          subscriptionsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Error loading subscriptions: $err', style: TextStyle(color: Colors.red.shade900, fontSize: 12)),
            ),
            data: (subs) {
              if (subs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 36, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 6),
                      const Text(
                        'No active farm subscriptions yet',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Start a daily milk or weekly veggie subscription with doorstep delivery.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () => CreateSubscriptionModal.show(context),
                        child: const Text('Subscribe to Fresh Farm Produce', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: subs.map((sub) {
                  return SubscriptionCard(
                    subscription: sub,
                    onTogglePause: () =>
                        ref.read(subscriptionsControllerProvider.notifier).togglePause(sub),
                    onSkipTomorrow: () {
                      final tomorrow = DateTime.now().add(const Duration(days: 1));
                      ref
                          .read(subscriptionsControllerProvider.notifier)
                          .skipDeliveryDate(sub, tomorrow);
                    },
                    onUpdateQuantity: (newQty) {
                      ref
                          .read(subscriptionsControllerProvider.notifier)
                          .updateQuantity(sub, newQty);
                    },
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),

          // COMMUNITY & APARTMENT GROUP ORDERS
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMMUNITY GROUP ORDERS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Apartment bulk buying unlocks lower price tiers',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 34),
                ),
                icon: const Icon(Icons.group_add_rounded, size: 15),
                label: const Text(
                  '+ Start Group',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                onPressed: () => CreateGroupOrderModal.show(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Group Orders List
          groupOrdersAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Error loading group orders: $err', style: TextStyle(color: Colors.red.shade900, fontSize: 12)),
            ),
            data: (groups) {
              if (groups.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.groups_outlined, size: 36, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 6),
                      const Text(
                        'No active community group orders',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Start a bulk group order for your apartment building.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => CreateGroupOrderModal.show(context),
                        child: const Text('Start an Apartment Order', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: groups.map((g) {
                  return GroupOrderCard(
                    groupOrder: g,
                    onJoinTap: () => JoinGroupOrderModal.show(context, g),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),

          // DEBUG ONLY SCHEDULER TEST BUTTON
          if (kDebugMode) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.shade400, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bug_report_rounded, color: Colors.amber.shade900, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'DEBUG: Run Scheduler Now',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Generates tomorrow\'s orders from active subscriptions & recurring cleaning jobs, respecting skip dates and stock shortage.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF78350F), height: 1.3),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade900,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: _isRunningScheduler
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.play_arrow_rounded, size: 16),
                      label: const Text('Run Scheduler Now', style: TextStyle(fontSize: 12)),
                      onPressed: _isRunningScheduler ? null : _runSchedulerNow,
                    ),
                  ),
                  if (_lastSchedulerResult != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Result for ${_lastSchedulerResult!['target_date']}:',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Orders: ${_lastSchedulerResult!['generated_orders']} | Skipped: ${_lastSchedulerResult!['skipped_orders']} | Shortages: ${_lastSchedulerResult!['stock_failures']} | Jobs: ${_lastSchedulerResult!['job_assignments_created']}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
