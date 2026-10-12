import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_home_controller.dart';

/// Diagnostic model for a job visibility result
class JobVisibilityDiagnosticItem {
  final String jobId;
  final String jobTitle;
  final String status;
  final bool isVisible;
  final List<String> suitableFor;
  final String workerType;
  final double? distanceM;
  final bool alreadyApplied;
  final bool hired;
  final List<String> reasons;

  const JobVisibilityDiagnosticItem({
    required this.jobId,
    required this.jobTitle,
    required this.status,
    required this.isVisible,
    required this.suitableFor,
    required this.workerType,
    this.distanceM,
    required this.alreadyApplied,
    required this.hired,
    required this.reasons,
  });

  factory JobVisibilityDiagnosticItem.fromJson(Map<String, dynamic> json) {
    return JobVisibilityDiagnosticItem(
      jobId: json['job_id']?.toString() ?? '',
      jobTitle: json['job_title']?.toString() ?? 'Untitled Job',
      status: json['status']?.toString() ?? 'UNKNOWN',
      isVisible: json['is_visible'] == true,
      suitableFor: (json['suitable_for'] as List?)?.map((e) => e.toString()).toList() ?? [],
      workerType: json['worker_type']?.toString() ?? 'unknown',
      distanceM: (json['distance_m'] as num?)?.toDouble(),
      alreadyApplied: json['already_applied'] == true,
      hired: json['hired'] == true,
      reasons: (json['reasons'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

/// Debug-only screen `/dev/job-visibility`
/// Shows every job in the database and whether it is VISIBLE or HIDDEN
/// for the current worker with exact granular reasons.
class DebugJobVisibilityScreen extends ConsumerStatefulWidget {
  const DebugJobVisibilityScreen({super.key});

  @override
  ConsumerState<DebugJobVisibilityScreen> createState() => _DebugJobVisibilityScreenState();
}

class _DebugJobVisibilityScreenState extends ConsumerState<DebugJobVisibilityScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<JobVisibilityDiagnosticItem> _items = [];
  String _filter = 'all'; // 'all', 'visible', 'hidden'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDiagnostics());
  }

  Future<void> _loadDiagnostics() async {
    if (!kDebugMode) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      final workerId = user?.id;

      final location = ref.read(seekerLocationProvider);
      final lat = location.lat != 0.0 ? location.lat : null;
      final lng = location.lng != 0.0 ? location.lng : null;

      final res = await client.rpc(
        'get_all_jobs_visibility_diagnostics',
        params: {
          'p_worker_id': workerId,
          'p_worker_lat': lat,
          'p_worker_lng': lng,
        },
      );

      final List<JobVisibilityDiagnosticItem> parsed = [];
      if (res is List) {
        for (final item in res) {
          if (item is Map) {
            parsed.add(JobVisibilityDiagnosticItem.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      } else if (res is String) {
        final decoded = jsonDecode(res);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              parsed.add(JobVisibilityDiagnosticItem.fromJson(Map<String, dynamic>.from(item)));
            }
          }
        }
      }

      setState(() {
        _items = parsed;
        _isLoading = false;
      });
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[DebugJobVisibility] Error: $e\n$stack');
      }
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('Debug tools are only available in debug builds.')),
      );
    }

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    final location = ref.watch(seekerLocationProvider);
    final profileAsync = ref.watch(seekerHomeProfileProvider);
    final workerType = profileAsync.value?.seekerType ?? 'informal';

    final filteredItems = _items.where((item) {
      if (_filter == 'visible') return item.isVisible;
      if (_filter == 'hidden') return !item.isVisible;
      return true;
    }).toList();

    final visibleCount = _items.where((i) => i.isVisible).length;
    final hiddenCount = _items.where((i) => !i.isVisible).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Text(
          'Job Visibility Inspector',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Diagnostics',
            onPressed: _loadDiagnostics,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Worker Status Card
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.badge_rounded, color: AppColors.headerGreenDark, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Worker: ${user?.phone ?? user?.email ?? user?.id ?? "Guest"}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Text(
                          'Role: $workerType'.toUpperCase(),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppColors.amberOrange, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Loc: ${location.displayName} (${location.lat.toStringAsFixed(4)}, ${location.lng.toStringAsFixed(4)})',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  // Filter Chips & Counts
                  Row(
                    children: [
                      _buildFilterChip('All (${_items.length})', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Visible ($visibleCount)', 'visible', color: Colors.green),
                      const SizedBox(width: 8),
                      _buildFilterChip('Hidden ($hiddenCount)', 'hidden', color: Colors.red),
                    ],
                  ),
                ],
              ),
            ),

            // Content List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  'Diagnostic Error: $_errorMessage',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red, fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadDiagnostics,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : filteredItems.isEmpty
                          ? const Center(
                              child: Text('No jobs matched this filter.', style: TextStyle(color: AppColors.textMuted)),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadDiagnostics,
                              child: ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemCount: filteredItems.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  return _buildJobDiagnosticCard(filteredItems[index]);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, {Color? color}) {
    final isSelected = _filter == value;
    final baseColor = color ?? const Color(0xFF0F172A);

    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? baseColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? baseColor : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildJobDiagnosticCard(JobVisibilityDiagnosticItem item) {
    final statusColor = item.isVisible ? Colors.green.shade700 : Colors.red.shade700;
    final statusBg = item.isVisible ? Colors.green.shade50 : Colors.red.shade50;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: item.isVisible ? Colors.green.shade200 : Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.jobTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${item.jobId}',
                        style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.isVisible ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.status,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Metadata Chips Row
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                // Audience chips
                ...item.suitableFor.map((aud) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Audience: $aud',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                    ),
                  );
                }),
                if (item.suitableFor.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Audience: NONE (Visible to nobody)',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ),

                // Distance
                if (item.distanceM != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.distanceM! < 1000
                          ? '${item.distanceM!.round()} m away'
                          : '${(item.distanceM! / 1000).toStringAsFixed(1)} km away',
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textDark),
                    ),
                  ),

                if (item.alreadyApplied)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Applied', style: TextStyle(fontSize: 10.5, color: Colors.amber)),
                  ),
              ],
            ),

            // Reasons section if hidden
            if (!item.isVisible && item.reasons.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.red, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Why is this job hidden from this worker?',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...item.reasons.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(
                                  r,
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF7F1D1D)),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
