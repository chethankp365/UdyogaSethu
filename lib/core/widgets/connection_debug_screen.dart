import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/config/env.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/supabase/supabase_service.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_spacing.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';
import 'package:udyogasethu/core/widgets/app_card.dart';
import 'package:udyogasethu/core/widgets/app_button.dart';
import 'package:udyogasethu/core/widgets/error_state.dart';
import 'package:udyogasethu/core/widgets/status_chip.dart';

class ConnectionDebugScreen extends ConsumerStatefulWidget {
  const ConnectionDebugScreen({super.key});

  @override
  ConsumerState<ConnectionDebugScreen> createState() => _ConnectionDebugScreenState();
}

class _ConnectionDebugScreenState extends ConsumerState<ConnectionDebugScreen> {
  bool _isLoading = false;
  bool _isConnected = false;
  Map<String, dynamic>? _pingData;
  AppException? _error;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = ref.read(supabaseServiceProvider);
      final res = await service.pingServer();
      setState(() {
        _isConnected = true;
        _pingData = res;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      final appEx = AppException.from(e, stackTrace);
      AppLogger.e('Connection debug check failed', appEx, stackTrace);
      setState(() {
        _isConnected = false;
        _pingData = null;
        _error = appEx;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Connection Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _checkConnection,
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header Card
            AppCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Backend Connection',
                        style: AppTypography.titleMedium(textColor),
                      ),
                      if (_isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        StatusChip(
                          label: _isConnected ? 'Connected' : 'Offline',
                          style: _isConnected ? StatusChipStyle.success : StatusChipStyle.danger,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),

                  // Host
                  _DetailRow(
                    label: 'Project Host',
                    value: Env.supabaseUrl,
                    textColor: textColor,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Auth State
                  _DetailRow(
                    label: 'Auth State',
                    value: currentUser == null
                        ? 'Unauthenticated (Anon)'
                        : 'Authenticated (${currentUser.phone ?? currentUser.email ?? currentUser.id})',
                    textColor: textColor,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Ping Status / Server Time
                  if (_isConnected && _pingData != null) ...[
                    _DetailRow(
                      label: 'Server Time',
                      value: _pingData!['server_time']?.toString() ?? 'N/A',
                      textColor: textColor,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DetailRow(
                      label: 'Database Info',
                      value: _pingData!['postgres_version']?.toString() ?? 'PostgreSQL Active',
                      textColor: textColor,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Main Body: Connected Details or Friendly Error State
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_isConnected)
              AppCard(
                backgroundColor: isDark ? AppColors.navyCard : AppColors.paleMint,
                child: Column(
                  children: [
                    const Icon(
                      Icons.cloud_done_rounded,
                      color: AppColors.emerald,
                      size: 48,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Supabase Connection Operational',
                      style: AppTypography.titleMedium(AppColors.primaryTeal),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Successfully connected to remote Supabase project: mmzbpeqkfomnywuzoqii',
                      style: AppTypography.bodySmall(AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ErrorState(
                message: _getFriendlyErrorMessage(_error),
                onRetry: _checkConnection,
              ),

            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Re-test Connection',
              onPressed: _isLoading ? null : _checkConnection,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  String _getFriendlyErrorMessage(AppException? exception) {
    if (exception == null) {
      return 'Unable to establish connection to Supabase backend.';
    }
    if (exception is NetworkException) {
      return 'No internet connection. Please check your network or airplane mode settings and retry.';
    }
    if (exception is AppTimeoutException) {
      return 'Connection request timed out. Please verify your internet speed and retry.';
    }
    return 'Backend connection error: ${exception.originalMessage ?? "Service temporarily unavailable."}';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: AppTypography.bodySmall(AppColors.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium(textColor).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
