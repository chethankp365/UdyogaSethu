import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_spacing.dart';
import 'package:udyogasethu/core/widgets/app_button.dart';
import 'package:udyogasethu/core/widgets/empty_state.dart';
import 'package:udyogasethu/core/widgets/responsive_container.dart';

class NotFoundScreen extends StatelessWidget {
  final GoRouterState? state;

  const NotFoundScreen({
    super.key,
    this.state,
  });

  @override
  Widget build(BuildContext context) {
    final location = state?.uri.toString() ?? 'Requested Page';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found (404)'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ResponsiveContainer(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EmptyState(
                  title: '404 - Page Not Found',
                  description:
                      'The page "$location" does not exist or has been moved.',
                  icon: Icons.error_outline_rounded,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Return to Home',
                  onPressed: () => context.go('/'),
                  variant: AppButtonVariant.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: '⚡ Open Role Switcher (/dev/role)',
                  onPressed: () => context.push(AppRoutes.devRole),
                  variant: AppButtonVariant.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
