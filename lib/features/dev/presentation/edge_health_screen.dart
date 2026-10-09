import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/supabase/edge_api.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/trust/presentation/digital_id_screen.dart';

class FunctionHealthResult {
  final String name;
  final bool isLoading;
  final bool ok;
  final List<String> missingSecrets;
  final List<String> missingDbObjects;
  final String? errorMessage;

  const FunctionHealthResult({
    required this.name,
    this.isLoading = false,
    this.ok = false,
    this.missingSecrets = const [],
    this.missingDbObjects = const [],
    this.errorMessage,
  });
}

class EdgeFunctionHealthScreen extends ConsumerStatefulWidget {
  const EdgeFunctionHealthScreen({super.key});

  @override
  ConsumerState<EdgeFunctionHealthScreen> createState() => _EdgeFunctionHealthScreenState();
}

class _EdgeFunctionHealthScreenState extends ConsumerState<EdgeFunctionHealthScreen> {
  final List<String> _functions = [
    'qr-issue',
    'qr-verify',
    'kyc-start',
    'kyc-callback',
    'face-enroll',
    'face-verify',
    'delete-account',
    'mandi-sync',
  ];

  final Map<String, FunctionHealthResult> _results = {};
  bool _isCheckingAll = false;

  @override
  void initState() {
    super.initState();
    for (final fn in _functions) {
      _results[fn] = FunctionHealthResult(name: fn);
    }
  }

  Future<void> _checkSingleFunction(String name) async {
    setState(() {
      _results[name] = FunctionHealthResult(name: name, isLoading: true);
    });

    try {
      final edgeApi = ref.read(edgeApiClientProvider);
      final res = await edgeApi.checkFunctionHealth(name);

      final ok = res['ok'] as bool? ?? false;
      final missingSecrets = (res['missing_secrets'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      final missingDbObjects = (res['missing_db_objects'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

      if (mounted) {
        setState(() {
          _results[name] = FunctionHealthResult(
            name: name,
            ok: ok,
            missingSecrets: missingSecrets,
            missingDbObjects: missingDbObjects,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _results[name] = FunctionHealthResult(
            name: name,
            ok: false,
            errorMessage: e.toString().replaceAll('Exception: ', ''),
          );
        });
      }
    }
  }

  Future<void> _checkAllFunctions() async {
    setState(() => _isCheckingAll = true);
    for (final fn in _functions) {
      await _checkSingleFunction(fn);
    }
    if (mounted) {
      setState(() => _isCheckingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(child: Text('Dev Menu tools are only available in debug builds.')),
      );
    }

    final isProfileQrEnabled = ref.watch(profileQrEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edge Function Health & D-QR', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Check All',
            onPressed: _isCheckingAll ? null : _checkAllFunctions,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // D-QR Testing Switch Card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.qr_code_2_rounded, color: AppColors.headerGreenDark),
                      SizedBox(width: 8),
                      Text(
                        'D-QR Profile Testing Toggle',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Per Decision D-QR, permanent profile QR codes are hidden in release. Turn ON here in debug mode to test qr-issue & qr-verify scanner with two phones.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Enable Permanent Profile QR (Debug Only)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      isProfileQrEnabled ? 'Enabled (Shows QR pass on Digital ID)' : 'Disabled (Shows job ticket note)',
                      style: TextStyle(fontSize: 11, color: isProfileQrEnabled ? Colors.green : Colors.grey),
                    ),
                    value: isProfileQrEnabled,
                    onChanged: (val) {
                      ref.read(profileQrEnabledProvider.notifier).setEnabled(val);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Overview Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'EDGE FUNCTIONS (P3.2 - P3.7)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
              ),
              TextButton.icon(
                onPressed: _isCheckingAll ? null : _checkAllFunctions,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(_isCheckingAll ? 'Checking...' : 'Check All'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Function status list
          ..._functions.map((fn) {
            final res = _results[fn]!;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: res.isLoading
                      ? Colors.blue.shade200
                      : res.ok
                          ? Colors.green.shade300
                          : (res.missingSecrets.isNotEmpty || res.missingDbObjects.isNotEmpty || res.errorMessage != null)
                              ? Colors.red.shade300
                              : Colors.grey.shade300,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          res.isLoading
                              ? Icons.hourglass_top_rounded
                              : res.ok
                                  ? Icons.check_circle_rounded
                                  : (res.errorMessage != null || res.missingSecrets.isNotEmpty || res.missingDbObjects.isNotEmpty)
                                      ? Icons.error_rounded
                                      : Icons.help_outline_rounded,
                          color: res.isLoading
                              ? Colors.blue
                              : res.ok
                                  ? Colors.green
                                  : (res.errorMessage != null || res.missingSecrets.isNotEmpty || res.missingDbObjects.isNotEmpty)
                                      ? Colors.red
                                      : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          fn,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const Spacer(),
                        if (res.isLoading)
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          TextButton(
                            onPressed: () => _checkSingleFunction(fn),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(40, 28),
                            ),
                            child: const Text('Ping', style: TextStyle(fontSize: 11)),
                          ),
                      ],
                    ),
                    if (res.ok) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                        child: const Text('OK: All required secrets and DB objects present', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                      ),
                    ],
                    if (res.missingSecrets.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Missing Secrets (names only):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                            const SizedBox(height: 2),
                            Text(res.missingSecrets.join(', '), style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    if (res.missingDbObjects.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Missing Database Objects:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                            const SizedBox(height: 2),
                            Text(res.missingDbObjects.join(', '), style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.deepOrange)),
                          ],
                        ),
                      ),
                    ],
                    if (res.errorMessage != null) ...[
                      const SizedBox(height: 6),
                      Text(res.errorMessage!, style: const TextStyle(fontSize: 11, color: Colors.red)),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
