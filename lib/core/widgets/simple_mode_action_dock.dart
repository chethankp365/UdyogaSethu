import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/services/voice_hints_helper.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/account/presentation/settings_controller.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

/// Tactile, high-contrast Essential Actions Dock rendered prominently
/// when Simple Mode is enabled for low-literacy users.
class SimpleModeActionDock extends ConsumerWidget {
  const SimpleModeActionDock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // High contrast dark slate background
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'SIMPLE MODE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  const VoiceHintSpeakerButton(
                    hintText: 'Tap any big button to accept jobs, start work, complete work, book, pay, or ask for help.',
                    color: Colors.white,
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                    ),
                    onPressed: () {
                      ref.read(userSettingsNotifierProvider.notifier).setSimpleMode(false);
                    },
                    child: const Text('Exit Simple Mode', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Essential Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap any action below for immediate one-touch access:',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),

          // 2x3 Grid of 6 Essential Actions
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              // 1. ACCEPT JOB
              _buildLargeActionButton(
                label: l10n?.actionAcceptJob ?? 'Accept Job',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF0D6548),
                onTap: () => context.push(AppRoutes.seekerJobs),
              ),

              // 2. START WORK
              _buildLargeActionButton(
                label: l10n?.actionStartWork ?? 'Start Work',
                icon: Icons.play_circle_fill_rounded,
                color: const Color(0xFF0284C7),
                onTap: () => context.push(AppRoutes.workerSchedule),
              ),

              // 3. COMPLETE JOB
              _buildLargeActionButton(
                label: l10n?.actionCompleteJob ?? 'Complete Job',
                icon: Icons.flag_rounded,
                color: const Color(0xFF16A34A),
                onTap: () => context.push(AppRoutes.jobHistory),
              ),

              // 4. BOOK
              _buildLargeActionButton(
                label: l10n?.actionBook ?? 'Book Worker',
                icon: Icons.person_add_alt_1_rounded,
                color: const Color(0xFF7C3AED),
                onTap: () => context.push(AppRoutes.providerWorkers),
              ),

              // 5. PAY
              _buildLargeActionButton(
                label: l10n?.actionPay ?? 'Pay / Wallet',
                icon: Icons.currency_rupee_rounded,
                color: const Color(0xFFD97706),
                onTap: () => context.push(AppRoutes.wallet),
              ),

              // 6. ASK FOR HELP
              _buildLargeActionButton(
                label: l10n?.actionAskForHelp ?? 'Ask for Help',
                icon: Icons.sos_rounded,
                color: const Color(0xFFDC2626),
                onTap: () => context.push(AppRoutes.safetyHub),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargeActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
