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

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
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
              'Scheduler ran: ${res['generated_orders']} orders created, ${res['skipped_orders']} skipped, ${res['stock_failures']} stock shortages, ${res['job_assignments_created']} jobs created.',
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Farm Subscriptions & Groups',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(userSubscriptionsProvider);
              ref.invalidate(communityGroupOrdersProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userSubscriptionsProvider);
          ref.invalidate(communityGroupOrdersProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen 30 Top Booking Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D6548), Color(0xFF0F766E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CONFIRMED BOOKING • BOOK-7842',
                            style: TextStyle(
                              color: Colors.lightGreenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Commercial Electrical Repair',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: const Size(0, 36),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text(
                      '+ New Subscription',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Error loading subscriptions: $err', style: TextStyle(color: Colors.red.shade900)),
                ),
                data: (subs) {
                  if (subs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 40, color: Color(0xFF94A3B8)),
                          const SizedBox(height: 8),
                          const Text(
                            'No active farm subscriptions yet',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Start a daily milk or weekly veggie subscription with doorstep delivery.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => CreateSubscriptionModal.show(context),
                            child: const Text('Subscribe to Fresh Farm Produce'),
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
              const SizedBox(height: 24),

              // COMMUNITY & APARTMENT GROUP ORDERS
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COMMUNITY & APARTMENT BULK ORDERS',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Group buying with neighbors unlocks tiered discounts',
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: const Size(0, 36),
                    ),
                    icon: const Icon(Icons.group_add_rounded, size: 16),
                    label: const Text(
                      '+ Start Group',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Error loading group orders: $err', style: TextStyle(color: Colors.red.shade900)),
                ),
                data: (groups) {
                  if (groups.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.groups_outlined, size: 40, color: Color(0xFF94A3B8)),
                          const SizedBox(height: 8),
                          const Text(
                            'No active community group orders',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Start a group order for your apartment building to unlock wholesale farmer pricing.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => CreateGroupOrderModal.show(context),
                            child: const Text('Start an Apartment Order'),
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
              const SizedBox(height: 24),

              // DEBUG ONLY SCHEDULER TEST CARD
              if (kDebugMode) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade400, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bug_report_rounded, color: Colors.amber.shade900, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'DEBUG: Order & Recurring Job Scheduler',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Executes generate_tomorrow_deliveries(tomorrow) to convert active subscriptions and recurring cleaning jobs into tomorrow\'s orders, respecting skip dates and stock shortage.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF78350F), height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade900,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: _isRunningScheduler
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.play_arrow_rounded, size: 18),
                          label: const Text('Run Scheduler Now'),
                          onPressed: _isRunningScheduler ? null : _runSchedulerNow,
                        ),
                      ),
                      if (_lastSchedulerResult != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scheduler Output for ${_lastSchedulerResult!['target_date']}:',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                              const SizedBox(height: 4),
                              Text('• Generated Orders: ${_lastSchedulerResult!['generated_orders']}', style: const TextStyle(fontSize: 11)),
                              Text('• Skipped Orders: ${_lastSchedulerResult!['skipped_orders']}', style: const TextStyle(fontSize: 11)),
                              Text('• Stock Shortages: ${_lastSchedulerResult!['stock_failures']}', style: const TextStyle(fontSize: 11)),
                              Text('• Recurring Jobs Created: ${_lastSchedulerResult!['job_assignments_created']}', style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
