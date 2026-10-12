import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/features/demo/data/demo_repository.dart';

/// Floating Coach-Mark banner overlay for active guided demo scenarios (P10.1).
/// Persists across screens when a scenario is active, guiding the evaluator.
class DemoCoachMarkOverlay extends ConsumerWidget {
  final Widget child;

  const DemoCoachMarkOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoState = ref.watch(demoNotifierProvider);
    final scenario = demoState.activeScenario;
    final step = demoState.currentStep;

    if (scenario == null || step == null) {
      return child;
    }

    final totalSteps = scenario.steps.length;
    final currentStepNum = demoState.currentStepIndex + 1;
    final isLastStep = currentStepNum == totalSteps;

    return Stack(
      children: [
        child,
        Positioned(
          left: 12,
          right: 12,
          bottom: 16,
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(16),
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), // Dark slate matching UI_REFERENCE
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade400, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Scenario Title + Step Badge + Close
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(scenario.icon, size: 18, color: Colors.amber.shade400),
                          const SizedBox(width: 6),
                          Text(
                            scenario.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade400,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Step $currentStepNum of $totalSteps',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => ref.read(demoNotifierProvider.notifier).exitScenario(),
                            child: const Padding(
                              padding: EdgeInsets.all(2.0),
                              child: Icon(Icons.close, size: 18, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Step Action Title
                  Text(
                    step.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Explanation
                  Text(
                    step.explanation,
                    style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.3),
                  ),

                  const SizedBox(height: 6),

                  // Why it matters badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline_rounded, size: 14, color: Colors.amber.shade300),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Why this matters: ${step.whyItMatters}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.amber.shade200,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Action Buttons Row
                  Row(
                    children: [
                      // Direct Route Shortcut
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            try {
                              context.push(step.targetRoute);
                            } catch (_) {
                              context.go(step.targetRoute);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.touch_app_rounded, size: 15),
                          label: const Text('Open Screen', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Next / Complete Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ref.read(demoNotifierProvider.notifier).nextStep();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade400,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: Icon(isLastStep ? Icons.check_circle_rounded : Icons.arrow_forward_rounded, size: 15),
                          label: Text(
                            isLastStep ? 'Complete Scenario' : 'Next Step',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
