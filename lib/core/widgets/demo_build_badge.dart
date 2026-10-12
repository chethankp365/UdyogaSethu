import 'package:flutter/material.dart';
import 'package:udyogasethu/core/config/env.dart';
import 'package:udyogasethu/features/demo/presentation/demo_launcher_sheet.dart';

/// Floating badge & trigger for guided demo scenarios (P10.1).
/// STRICTLY rendered only in demo builds / debug mode; completely absent in release builds.
class DemoBuildBadge extends StatelessWidget {
  const DemoBuildBadge({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Env.isDemoBuild) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 76, // Above bottom nav bar
      right: 12,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(20),
        color: Colors.transparent,
        child: InkWell(
          key: const Key('demoBuildBadge'),
          onTap: () => DemoLauncherSheet.show(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade400,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.shade600, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_circle_filled_rounded, size: 16, color: Colors.amber.shade900),
                const SizedBox(width: 4),
                Text(
                  'Demo Scenarios',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
