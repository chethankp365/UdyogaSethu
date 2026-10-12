import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';
import 'package:udyogasethu/features/demo/data/demo_repository.dart';
import 'package:udyogasethu/features/demo/domain/demo_scenario.dart';

/// Evaluator Demo Launcher Modal & Screen (P10.1).
/// Features the 5 guided demo scenarios, progress tracker, and reset_demo shortcut.
class DemoLauncherSheet extends ConsumerWidget {
  const DemoLauncherSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DemoLauncherSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoState = ref.watch(demoNotifierProvider);
    final demoNotifier = ref.read(demoNotifierProvider.notifier);
    final scenarios = DemoScenariosCatalog.scenarios;
    final completedCount = demoState.completedScenarioIds.length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 12),

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.play_circle_filled_rounded, color: AppColors.headerGreenDark, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Guided Demo Scenarios',
                    style: AppTypography.titleMedium(AppColors.textDark).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade400,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'DEMO BUILD',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Progress Bar Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Evaluation Progress',
                        style: AppTypography.titleSmall(AppColors.textDark).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$completedCount of ${scenarios.length} completed',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.headerGreenDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: scenarios.isEmpty ? 0 : completedCount / scenarios.length,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Action shortcuts row: Demo Accounts + Reset State
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.pop();
                      context.push(AppRoutes.demoAccounts);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.people_outline, size: 16),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Demo Accounts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: demoState.isResetting
                        ? null
                        : () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Reset Demo State?'),
                                content: const Text(
                                  'This executes reset_demo() RPC on Supabase, restoring baseline assignments, tomato stock, and wallet credits for all test accounts.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Reset Seed Data'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              final ok = await demoNotifier.resetAllDemoState();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ok ? 'Demo seed state restored cleanly!' : 'Reset completed locally.'),
                                    backgroundColor: AppColors.headerGreenDark,
                                  ),
                                );
                              }
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber.shade900,
                      side: BorderSide(color: Colors.amber.shade300),
                      backgroundColor: Colors.amber.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: demoState.isResetting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                          )
                        : const Icon(Icons.restore_rounded, size: 16),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Reset Demo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Scenarios List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              itemCount: scenarios.length,
              itemBuilder: (context, index) {
                final scenario = scenarios[index];
                final isCompleted = demoState.completedScenarioIds.contains(scenario.id);
                final isActive = demoState.activeScenarioId == scenario.id;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isActive
                          ? Colors.amber.shade400
                          : isCompleted
                              ? AppColors.primaryTeal.withValues(alpha: 0.5)
                              : const Color(0xFFE2E8F0),
                      width: isActive ? 2.0 : 1.0,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: scenario.primaryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(scenario.icon, color: scenario.primaryColor, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          scenario.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                      if (isCompleted) ...[
                                        const Icon(Icons.check_circle, color: AppColors.primaryTeal, size: 18),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    '${scenario.steps.length} steps · ~${scenario.estimatedMinutes} mins · User: ${scenario.testUserName}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          scenario.subtitle,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.3),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // 1. Start scenario
                              demoNotifier.startScenario(scenario.id);
                              context.pop();

                              // 2. Navigate to first step route
                              final firstRoute = scenario.steps.first.targetRoute;
                              try {
                                context.push(firstRoute);
                              } catch (_) {
                                context.go(firstRoute);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isActive ? Colors.amber.shade400 : scenario.primaryColor,
                              foregroundColor: isActive ? Colors.black87 : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: Icon(isActive ? Icons.play_arrow : Icons.rocket_launch_rounded, size: 16),
                            label: Text(
                              isActive
                                  ? 'Resume Scenario'
                                  : isCompleted
                                      ? 'Replay Scenario'
                                      : 'Start Scenario',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
