import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/features/seeker/data/my_applications_repository.dart';
import 'package:udyogasethu/features/seeker/domain/job_application_status.dart';

class MyApplicationsNotifier extends Notifier<Map<String, WorkerJobStatus>> {
  RealtimeChannel? _subscription;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  @override
  Map<String, WorkerJobStatus> build() {
    ref.onDispose(() {
      _subscription?.unsubscribe();
      _subscription = null;
    });

    // Automatically load when notifier is created
    Future.microtask(() => loadAll());

    return const {};
  }

  /// Initial or pull-to-refresh load from Supabase
  Future<void> loadAll() async {
    if (_isLoading) return;
    _isLoading = true;
    try {
      final repo = ref.read(myApplicationsRepositoryProvider);
      final remoteMap = await repo.fetchMyApplicationStatuses();

      // Merge remote map with existing state, preserving optimistic states if newer
      final merged = Map<String, WorkerJobStatus>.from(state);
      for (final entry in remoteMap.entries) {
        final existing = state[entry.key];
        if (existing != null && existing.updatedAt != null) {
          if (entry.value.updatedAt == null || existing.updatedAt!.isAfter(entry.value.updatedAt!)) {
            // Keep local state if local is newer than remote
            continue;
          }
        }
        merged[entry.key] = entry.value;
      }
      state = merged;

      // Ensure realtime listener is attached
      _attachRealtimeListener();
    } catch (e, st) {
      AppLogger.e('MyApplicationsNotifier.loadAll error: $e', e, st);
    } finally {
      _isLoading = false;
    }
  }

  void _attachRealtimeListener() {
    if (_subscription != null) return;
    final repo = ref.read(myApplicationsRepositoryProvider);
    _subscription = repo.subscribeToUserChanges(
      onRecordChanged: (record, table, eventType) {
        final jobId = record['job_id']?.toString();
        if (jobId == null || jobId.isEmpty) return;

        final current = state[jobId];
        if (table == 'job_applications') {
          final newStatus = JobAppStatus.fromString(record['status']?.toString());
          final updated = (current ?? WorkerJobStatus(jobId: jobId)).copyWith(
            applicationId: record['id']?.toString(),
            applicationStatus: newStatus,
            appliedAt: record['created_at'] != null ? DateTime.tryParse(record['created_at'].toString()) : current?.appliedAt,
            updatedAt: record['updated_at'] != null ? DateTime.tryParse(record['updated_at'].toString()) : DateTime.now(),
          );
          state = {...state, jobId: updated};
        } else if (table == 'job_assignments') {
          final asgStatus = record['status']?.toString();
          final updated = (current ?? WorkerJobStatus(jobId: jobId)).copyWith(
            assignmentId: record['id']?.toString(),
            assignmentStatus: asgStatus,
            updatedAt: record['updated_at'] != null ? DateTime.tryParse(record['updated_at'].toString()) : DateTime.now(),
          );
          state = {...state, jobId: updated};
        }
      },
    );
  }

  /// Batch update or seed statuses discovered from job feeds (recommended, nearby, details)
  void seedStatuses(Iterable<WorkerJobStatus> items) {
    if (items.isEmpty) return;
    final updated = Map<String, WorkerJobStatus>.from(state);
    bool changed = false;

    for (final item in items) {
      if (item.jobId.isEmpty) continue;
      final existing = updated[item.jobId];
      // Only seed if not already tracked or if existing is none and incoming is applied/hired
      if (existing == null || (existing.isNone && !item.isNone)) {
        updated[item.jobId] = item;
        changed = true;
      }
    }

    if (changed) {
      state = updated;
    }
  }

  /// Optimistic apply to a job with rollback on failure
  Future<({bool success, String? error, String? applicationId})> applyToJob({
    required String jobId,
    String? message,
  }) async {
    final previous = state[jobId];

    // Optimistic update
    final optimistic = (previous ?? WorkerJobStatus(jobId: jobId)).copyWith(
      applicationStatus: JobAppStatus.applied,
      appliedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    state = {...state, jobId: optimistic};

    try {
      final repo = ref.read(myApplicationsRepositoryProvider);
      final appId = await repo.applyToJob(jobId: jobId, message: message);

      // Confirm with server application ID
      state = {
        ...state,
        jobId: optimistic.copyWith(applicationId: appId),
      };
      return (success: true, error: null, applicationId: appId);
    } catch (e) {
      debugPrint('[MyApplicationsNotifier] applyToJob raw database error: $e');

      // Rollback on failure
      if (previous != null) {
        state = {...state, jobId: previous};
      } else {
        final reverted = Map<String, WorkerJobStatus>.from(state)..remove(jobId);
        state = reverted;
      }

      String userMsg = 'Unable to submit application. Please try again.';
      final errUpper = e.toString().toUpperCase();

      if (errUpper.contains('ALREADY_APPLIED') || errUpper.contains('ALREADY APPLIED') || errUpper.contains('DUPLICATE KEY')) {
        // If server says already applied, reflect applied state!
        state = {
          ...state,
          jobId: optimistic,
        };
        return (success: true, error: null, applicationId: previous?.applicationId);
      } else if (errUpper.contains('SLOTS_FILLED') || errUpper.contains('SLOTS FULL') || errUpper.contains('ALREADY FILLED')) {
        userMsg = 'This job is already full. No more positions available.';
      } else if (errUpper.contains('EXPIRED') || errUpper.contains('JOB CLOSED') || errUpper.contains('PAST_START')) {
        userMsg = 'This job is closed or its scheduled start time has passed.';
      } else if (errUpper.contains('AUDIENCE_MISMATCH') || errUpper.contains('STUDENT_GATED') || errUpper.contains('NOT ELIGIBLE')) {
        userMsg = 'You are not eligible for this job category.';
      } else if (errUpper.contains('OWN_JOB')) {
        userMsg = 'You cannot apply to your own job.';
      } else if (errUpper.contains('NOT_AUTHENTICATED') || errUpper.contains('AUTHENTICATION REQUIRED')) {
        userMsg = 'Please sign in to apply for this job.';
      } else if (errUpper.contains('LICENCE_REQUIRED')) {
        userMsg = 'A valid driving licence is required for this role.';
      } else if (errUpper.contains('VERIFIED_REQUIRED')) {
        userMsg = 'A verified profile badge is required for this role.';
      } else if (errUpper.contains('SCHEDULE_CLASH')) {
        userMsg = 'You have a schedule clash with another active booking.';
      } else if (errUpper.contains('INELIGIBLE TO APPLY:')) {
        final match = RegExp(r'Ineligible to apply:\s*\[(.*?)\]', caseSensitive: false).firstMatch(e.toString());
        if (match != null && match.group(1) != null) {
          userMsg = match.group(1)!.replaceAll('"', '').trim();
        }
      }

      return (success: false, error: userMsg, applicationId: null);
    }
  }

  /// Optimistic withdrawal with rollback on failure
  Future<({bool success, String? error})> withdrawApplication(String jobId) async {
    final previous = state[jobId];
    if (previous == null || !previous.canWithdraw) {
      return (success: false, error: 'Cannot withdraw this application');
    }

    // Optimistic update
    final optimistic = previous.copyWith(
      applicationStatus: JobAppStatus.withdrawn,
      updatedAt: DateTime.now(),
    );
    state = {...state, jobId: optimistic};

    try {
      final repo = ref.read(myApplicationsRepositoryProvider);
      final ok = await repo.withdrawApplication(jobId);
      if (ok) {
        return (success: true, error: null);
      } else {
        // Rollback
        state = {...state, jobId: previous};
        return (success: false, error: 'Failed to withdraw application');
      }
    } catch (e) {
      // Rollback
      state = {...state, jobId: previous};
      return (success: false, error: e.toString());
    }
  }

  /// Clears state on sign out
  void clear() {
    _subscription?.unsubscribe();
    _subscription = null;
    state = const {};
  }
}

final myApplicationsProvider =
    NotifierProvider<MyApplicationsNotifier, Map<String, WorkerJobStatus>>(
  MyApplicationsNotifier.new,
);

/// Convenience selector provider for a specific job's status
final jobStatusProvider = Provider.family<WorkerJobStatus, String>((ref, jobId) {
  final applications = ref.watch(myApplicationsProvider);
  return applications[jobId] ?? WorkerJobStatus(jobId: jobId);
});
