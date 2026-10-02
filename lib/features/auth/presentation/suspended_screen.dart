import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';
import 'package:udyogasethu/core/widgets/app_button.dart';
import 'package:udyogasethu/features/auth/data/auth_repository.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen displayed when a user account is suspended.
class SuspendedScreen extends ConsumerWidget {
  const SuspendedScreen({super.key});

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    ref.read(appSessionProvider.notifier).setSessionStatus(AuthSessionStatus.signedOut);
    if (context.mounted) {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _handleAppeal(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@udyogasethu.in',
      queryParameters: {
        'subject': 'Account Suspension Appeal',
        'body': 'Hello Support Team,\n\nI would like to appeal the suspension of my UdyogaSethu account.\n\nThank you.',
      },
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please contact support@udyogasethu.in to appeal.'),
            ),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please contact support@udyogasethu.in to appeal.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.dangerBackground,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.warningOrange, width: 2),
                ),
                child: const Icon(
                  Icons.block_rounded,
                  size: 48,
                  color: AppColors.errorRed,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Account Suspended',
                style: AppTypography.displayMedium(AppColors.headerGreenDark).copyWith(
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'Your account has been suspended for safety or policy reasons. If you believe this was an error, you may submit an appeal to our team.',
                style: AppTypography.bodyMedium(AppColors.textMuted),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 36),

              AppButton(
                key: const Key('submitAppealButton'),
                label: 'Submit Appeal',
                onPressed: () => _handleAppeal(context),
                variant: AppButtonVariant.primary,
                fullWidth: true,
              ),

              const SizedBox(height: 12),

              AppButton(
                key: const Key('suspendedSignOutButton'),
                label: 'Sign Out',
                onPressed: () => _handleSignOut(context, ref),
                variant: AppButtonVariant.secondary,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
