import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_spacing.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';
import 'package:udyogasethu/core/widgets/app_button.dart';
import 'package:udyogasethu/core/widgets/app_card.dart';
import 'package:udyogasethu/core/widgets/empty_state.dart';
import 'package:udyogasethu/core/widgets/responsive_container.dart';

class PlaceholderScreen extends StatefulWidget {
  final String title;
  final String roleName;
  final IconData icon;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.roleName,
    required this.icon,
  });

  @override
  State<PlaceholderScreen> createState() => _PlaceholderScreenState();
}

class _PlaceholderScreenState extends State<PlaceholderScreen> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.roleName}: ${widget.title}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.developer_mode),
            tooltip: 'Open Role Debug Switcher (/dev/role)',
            onPressed: () {
              context.push(AppRoutes.devRole);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        key: PageStorageKey('placeholder_scroll_${widget.roleName}_${widget.title}'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ResponsiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EmptyState(
                title: widget.title,
                description:
                    'This is a placeholder for ${widget.roleName} -> ${widget.title}.\nStatefulShellRoute preserves your scroll position and local state across tab switches.',
                icon: widget.icon,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Interactive Local State Test Card
              AppCard(
                child: Column(
                  children: [
                    Text(
                      'Tab State Preservation Test',
                      style: AppTypography.titleMedium(textColor),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Counter Value: $_counter',
                      style: AppTypography.titleLarge(AppColors.primaryTeal),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _counter++;
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Increment State'),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _counter = 0;
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Scroll State Test Cards
              Text(
                'Dummy Content List (Scroll down & switch tabs to test scroll retention)',
                style: AppTypography.bodySmall(AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...List.generate(8, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.paleMint,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: AppColors.primaryTeal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text('Item #${index + 1} on ${widget.title}'),
                        subtitle: const Text('Tab state stays preserved during navigation'),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.md),

              AppButton(
                label: '⚡ Open Role Switcher (/dev/role)',
                variant: AppButtonVariant.secondary,
                onPressed: () => context.push(AppRoutes.devRole),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
