import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/features/seeker/domain/job_application_status.dart';

abstract class MyApplicationsRepository {
  Future<Map<String, WorkerJobStatus>> fetchMyApplicationStatuses();
  RealtimeChannel? subscribeToUserChanges({
    required void Function(Map<String, dynamic> record, String table, String eventType) onRecordChanged,
  });
  Future<String> applyToJob({required String jobId, String? message});
  Future<bool> withdrawApplication(String jobId);
}

class SupabaseMyApplicationsRepository implements MyApplicationsRepository {
  final SupabaseClient? _client;

  SupabaseMyApplicationsRepository([this._client]);

  SupabaseClient? get _effectiveClient {
    if (_client != null) return _client;
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client;
      }
    } catch (_) {}
    return null;
  }

  String? get _currentUserId {
    final client = _effectiveClient;
    if (client == null) return null;
    try {
      return client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, WorkerJobStatus>> fetchMyApplicationStatuses() async {
    final client = _effectiveClient;
    if (client == null) return {};
    final uid = _currentUserId;
    if (uid == null) return {};

    try {
      final res = await client.rpc('get_my_job_application_statuses');
      final Map<String, WorkerJobStatus> map = {};
      if (res is List) {
        for (final row in res) {
          if (row is Map) {
            final status = WorkerJobStatus.fromJson(Map<String, dynamic>.from(row));
            if (status.jobId.isNotEmpty) {
              map[status.jobId] = status;
            }
          }
        }
      }
      return map;
    } catch (e, st) {
      AppLogger.e('Failed to fetch get_my_job_application_statuses: $e', e, st);
      // Fallback: direct query from job_applications and job_assignments
      return _fallbackFetch(uid);
    }
  }

  Future<Map<String, WorkerJobStatus>> _fallbackFetch(String uid) async {
    final client = _effectiveClient;
    if (client == null) return {};
    final Map<String, WorkerJobStatus> map = {};
    try {
      final apps = await client
          .from('job_applications')
          .select('id, job_id, status, created_at, updated_at')
          .eq('worker_id', uid);

      for (final a in (apps as List)) {
        final jId = a['job_id']?.toString() ?? '';
        if (jId.isNotEmpty) {
          map[jId] = WorkerJobStatus(
            jobId: jId,
            applicationId: a['id']?.toString(),
            applicationStatus: JobAppStatus.fromString(a['status']?.toString()),
            appliedAt: a['created_at'] != null ? DateTime.tryParse(a['created_at'].toString()) : null,
            updatedAt: a['updated_at'] != null ? DateTime.tryParse(a['updated_at'].toString()) : null,
          );
        }
      }

      final asgs = await client
          .from('job_assignments')
          .select('id, job_id, status, created_at, updated_at')
          .eq('worker_id', uid);

      for (final asg in (asgs as List)) {
        final jId = asg['job_id']?.toString() ?? '';
        if (jId.isNotEmpty) {
          final existing = map[jId];
          map[jId] = WorkerJobStatus(
            jobId: jId,
            applicationId: existing?.applicationId,
            applicationStatus: existing?.applicationStatus ?? JobAppStatus.none,
            assignmentId: asg['id']?.toString(),
            assignmentStatus: asg['status']?.toString(),
            appliedAt: existing?.appliedAt,
            updatedAt: asg['updated_at'] != null ? DateTime.tryParse(asg['updated_at'].toString()) : existing?.updatedAt,
          );
        }
      }
    } catch (e, st) {
      AppLogger.e('Fallback applications fetch failed: $e', e, st);
    }
    return map;
  }

  @override
  RealtimeChannel? subscribeToUserChanges({
    required void Function(Map<String, dynamic> record, String table, String eventType) onRecordChanged,
  }) {
    final uid = _currentUserId;
    final client = _effectiveClient;
    if (client == null) return null;

    final channelName = 'user-app-status-$uid-${DateTime.now().millisecondsSinceEpoch}';
    final channel = client.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'job_applications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'worker_id',
            value: uid,
          ),
          callback: (payload) {
            final rec = payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;
            onRecordChanged(rec, 'job_applications', payload.eventType.name);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'job_assignments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'worker_id',
            value: uid,
          ),
          callback: (payload) {
            final rec = payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;
            onRecordChanged(rec, 'job_assignments', payload.eventType.name);
          },
        )
        .subscribe();

    return channel;
  }

  @override
  Future<String> applyToJob({required String jobId, String? message}) async {
    final client = _effectiveClient;
    if (client == null) {
      // In offline / test environment without client, return synthetic ID
      return 'test-app-$jobId';
    }
    try {
      final res = await client.rpc('apply_to_job', params: {
        'p_job_id': jobId,
        if (message != null && message.trim().isNotEmpty) 'p_message': message.trim(),
      });
      return res.toString();
    } catch (e, st) {
      AppLogger.e('RPC apply_to_job failed: $e', e, st);
      rethrow;
    }
  }

  @override
  Future<bool> withdrawApplication(String jobId) async {
    final client = _effectiveClient;
    if (client == null) {
      return true;
    }
    try {
      final res = await client.rpc('withdraw_job_application', params: {
        'p_job_id': jobId,
      });
      return res == true;
    } catch (e, st) {
      AppLogger.e('RPC withdraw_job_application failed: $e', e, st);
      rethrow;
    }
  }
}

final myApplicationsRepositoryProvider = Provider<MyApplicationsRepository>((ref) {
  return SupabaseMyApplicationsRepository();
});
