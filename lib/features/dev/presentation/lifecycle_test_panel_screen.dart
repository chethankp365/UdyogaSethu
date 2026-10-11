import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:udyogasethu/core/supabase/edge_api.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_spacing.dart';
import 'package:udyogasethu/core/widgets/app_button.dart';
import 'package:udyogasethu/core/widgets/app_card.dart';
import 'package:udyogasethu/features/job_execution/data/job_execution_repository.dart';
import 'package:udyogasethu/features/job_execution/domain/assignment_event_item.dart';

class LifecycleTestPanelScreen extends ConsumerStatefulWidget {
  final String? initialAssignmentId;

  const LifecycleTestPanelScreen({super.key, this.initialAssignmentId});

  @override
  ConsumerState<LifecycleTestPanelScreen> createState() => _LifecycleTestPanelScreenState();
}

class _LifecycleTestPanelScreenState extends ConsumerState<LifecycleTestPanelScreen> {
  late final TextEditingController _assignmentIdController;
  String _activeAssignmentId = 'demo-assignment-101';

  // Token state
  String? _qrToken;
  DateTime? _tokenExpiresAt;
  int _secondsLeft = 0;
  Timer? _countdownTimer;
  bool _isLoadingToken = false;
  bool _shortTtlActive = false;

  // Function Health Check state
  final Map<String, String> _fnStatus = {
    'qr-issue': 'Unchecked',
    'qr-verify': 'Unchecked',
    'face-verify': 'Unchecked',
  };
  final Map<String, bool> _fnChecking = {
    'qr-issue': false,
    'qr-verify': false,
    'face-verify': false,
  };

  @override
  void initState() {
    super.initState();
    _activeAssignmentId = widget.initialAssignmentId ?? 'demo-assignment-101';
    _assignmentIdController = TextEditingController(text: _activeAssignmentId);
    _fetchToken();
    _startTimer();
  }

  @override
  void dispose() {
    _assignmentIdController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_tokenExpiresAt != null) {
        final diff = _tokenExpiresAt!.difference(DateTime.now()).inSeconds;
        setState(() {
          _secondsLeft = diff > 0 ? diff : 0;
        });
      }
    });
  }

  Future<void> _fetchToken({bool shortTtl = false}) async {
    setState(() {
      _isLoadingToken = true;
      _shortTtlActive = shortTtl;
    });

    try {
      final repo = ref.read(jobExecutionRepositoryProvider);
      final res = await repo.getRotatingTicketToken(_activeAssignmentId, debugShortTtl: shortTtl);
      final token = res['qr_token'] as String?;
      final exp = res['expires_at'] != null ? DateTime.tryParse(res['expires_at'].toString()) : null;
      final ttl = (res['expires_in_seconds'] as num?)?.toInt() ?? (shortTtl ? 15 : 120);

      if (mounted) {
        setState(() {
          _qrToken = token;
          _tokenExpiresAt = exp ?? DateTime.now().add(Duration(seconds: ttl));
          _secondsLeft = ttl;
          _isLoadingToken = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingToken = false;
        });
      }
    }
  }

  Future<void> _checkHealth(String fnName) async {
    setState(() {
      _fnChecking[fnName] = true;
    });

    try {
      final edgeApi = ref.read(edgeApiClientProvider);
      final res = await edgeApi.checkFunctionHealth(fnName);
      final ok = res['ok'] as bool? ?? false;
      final missingSecrets = (res['missing_secrets'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

      if (mounted) {
        setState(() {
          _fnChecking[fnName] = false;
          if (ok) {
            _fnStatus[fnName] = 'OK (Healthy)';
          } else if (missingSecrets.isNotEmpty) {
            _fnStatus[fnName] = 'Missing: ${missingSecrets.join(", ")}';
          } else {
            _fnStatus[fnName] = 'Failed';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fnChecking[fnName] = false;
          _fnStatus[fnName] = 'Error: $e';
        });
      }
    }
  }

  Future<void> _checkAllFunctions() async {
    for (final fn in _fnStatus.keys) {
      await _checkHealth(fn);
    }
  }

  Future<void> _advanceStage(String stage) async {
    try {
      final repo = ref.read(jobExecutionRepositoryProvider);
      await repo.advanceStage(_activeAssignmentId, stage);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Advanced stage to "$stage"'),
          backgroundColor: AppColors.headerGreenDark,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to advance: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lifecycle Test Panel')),
        body: const Center(child: Text('Debug mode only.')),
      );
    }

    final repo = ref.watch(jobExecutionRepositoryProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Lifecycle Test Panel', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: One-tap Function Health Checks
            _buildSectionHeader('1. One-Tap Function Health Checks', Icons.health_and_safety_outlined),
            AppCard(
              child: Column(
                children: [
                  for (final fn in _fnStatus.keys)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _fnStatus[fn]!.startsWith('OK')
                            ? Icons.check_circle_rounded
                            : (_fnStatus[fn] == 'Unchecked' ? Icons.help_outline_rounded : Icons.error_outline_rounded),
                        color: _fnStatus[fn]!.startsWith('OK')
                            ? Colors.green
                            : (_fnStatus[fn] == 'Unchecked' ? Colors.grey : Colors.red),
                      ),
                      title: Text(fn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(_fnStatus[fn]!, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      trailing: _fnChecking[fn] == true
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : TextButton(
                              onPressed: () => _checkHealth(fn),
                              child: const Text('Check'),
                            ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: '⚡ Check All 3 Functions',
                      onPressed: _checkAllFunctions,
                      variant: AppButtonVariant.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section 2: Assignment Selector & Time Windows
            _buildSectionHeader('2. Active Assignment & Time Windows', Icons.tune_rounded),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _assignmentIdController,
                    decoration: InputDecoration(
                      labelText: 'Assignment ID',
                      hintText: 'Enter assignment UUID',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () {
                          setState(() {
                            _activeAssignmentId = _assignmentIdController.text.trim();
                          });
                          _fetchToken();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: Color(0xFF0284C7)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Time Window Defaults: 60m before job start to 120m after job start.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF0369A1)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Quick Advance Stage:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Accepted'),
                        onPressed: () => _advanceStage('accepted'),
                      ),
                      ActionChip(
                        label: const Text('Arrived'),
                        onPressed: () => _advanceStage('arrived'),
                      ),
                      ActionChip(
                        label: const Text('In Progress'),
                        onPressed: () => _advanceStage('in_progress_verified'),
                      ),
                      ActionChip(
                        label: const Text('Completed'),
                        onPressed: () => _advanceStage('completed'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section 3: Rotating QR Token State & Expiry Controls
            _buildSectionHeader('3. Rotating QR Token & TTL Controls', Icons.qr_code_2_rounded),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _secondsLeft > 0 ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _secondsLeft > 0 ? 'ACTIVE (${_secondsLeft}s left)' : 'EXPIRED',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _secondsLeft > 0 ? const Color(0xFF166534) : const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: () => _fetchToken(shortTtl: _shortTtlActive),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isLoadingToken)
                    const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                  else ...[
                    Text(
                      'Token Hash: ${_qrToken != null ? (_qrToken!.length > 20 ? "${_qrToken!.substring(0, 20)}..." : _qrToken!) : "None"}',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    ),
                    if (_tokenExpiresAt != null)
                      Text(
                        'Expires At: ${DateFormat("HH:mm:ss").format(_tokenExpiresAt!.toLocal())}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _shortTtlActive ? Colors.deepOrange : AppColors.headerGreenDark,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _fetchToken(shortTtl: !_shortTtlActive),
                          child: Text(_shortTtlActive ? 'Short TTL (15s) [Active]' : 'Set Short TTL (15s)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Copy Token',
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: _qrToken != null
                            ? () {
                                Clipboard.setData(ClipboardData(text: _qrToken!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Token copied to clipboard')),
                                );
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section 4: Live Assignment Events Timeline
            _buildSectionHeader('4. Live Assignment Events (Realtime Stream)', Icons.history_rounded),
            StreamBuilder<List<AssignmentEventItem>>(
              stream: repo.watchAssignmentEvents(_activeAssignmentId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                }

                if (snapshot.hasError) {
                  return AppCard(
                    child: Text('Error streaming events: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  );
                }

                final events = snapshot.data ?? [];
                if (events.isEmpty) {
                  return const AppCard(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No events recorded for this assignment yet.', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  );
                }

                return AppCard(
                  child: Column(
                    children: [
                      for (int i = 0; i < events.length; i++) ...[
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.headerGreenDark.withValues(alpha: 0.1),
                            child: Text('${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark)),
                          ),
                          title: Text(
                            events[i].rawEventType,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(DateFormat('HH:mm:ss • dd MMM yyyy').format(events[i].createdAt), style: const TextStyle(fontSize: 11)),
                              if (events[i].meta.isNotEmpty)
                                Text('meta: ${events[i].meta}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontFamily: 'monospace')),
                            ],
                          ),
                        ),
                        if (i < events.length - 1) const Divider(height: 1),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.headerGreenDark),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }
}
