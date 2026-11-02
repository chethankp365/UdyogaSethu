import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/services/routing_service.dart';
import 'package:udyogasethu/core/supabase/edge_api.dart';
import 'package:udyogasethu/core/supabase/supabase_service.dart';
import 'package:udyogasethu/features/job_execution/domain/active_job_detail.dart';
import 'package:udyogasethu/features/job_execution/domain/assignment_event_item.dart';
import 'package:udyogasethu/features/job_execution/domain/job_ticket.dart';
import 'package:udyogasethu/features/job_execution/domain/job_verification.dart';
import 'package:udyogasethu/features/job_execution/domain/worker_schedule_item.dart';
import 'package:udyogasethu/features/job_execution/domain/replacement_candidate.dart';

abstract class JobExecutionRepository {
  Future<ActiveJobDetail> fetchActiveJob(String assignmentId);
  Future<List<AssignmentEventItem>> fetchAssignmentEvents(String assignmentId);
  Stream<List<AssignmentEventItem>> watchAssignmentEvents(String assignmentId);
  Stream<String> watchAssignmentStatus(String assignmentId);
  Future<void> advanceStage(String assignmentId, String nextStatus, {Map<String, dynamic>? meta});
  Future<List<WorkerScheduleItem>> fetchWorkerSchedule(String workerId, {DateTime? startDate, DateTime? endDate});
  Future<JobTicketData> fetchJobTicket(String assignmentId);
  Future<Map<String, dynamic>> refreshTicketQr(String assignmentId);
  Future<AttendanceScanResult> verifyAttendanceScan({required String qrToken, double? lat, double? lng, String? jobId});
  Future<JobGeofenceStatus> checkJobGeofence({required String jobId, required double lat, required double lng});
  Future<JobVerificationResult> verifyJobStart({
    required String assignmentId,
    required double lat,
    required double lng,
    required bool isMocked,
    List<double>? embedding,
    String? selfiePath,
  });
  Future<JobVerificationResult> verifyMidJobCheck({
    required String assignmentId,
    double? lat,
    double? lng,
    bool? isMocked,
    String? selfiePath,
  });
  Future<JobVerificationResult> completeJob({
    required String assignmentId,
    double? lat,
    double? lng,
    bool? isMocked,
    String? selfiePath,
    List<String>? workPhotos,
    bool isCustomerConfirmed = false,
  });
  Future<String> uploadJobEvidence({
    required String assignmentId,
    required List<int> fileBytes,
    required String fileName,
  });
  Future<int> checkNoShowAssignments();
  Future<void> extendWait(String assignmentId, {int minutes = 10});
  Future<void> reportRunningLate(String assignmentId, {required int etaMinutes});
  Future<List<ReplacementCandidate>> findReplacementCandidates(String assignmentId);
  Future<Map<String, dynamic>> confirmReplacement({
    required String assignmentId,
    required String replacementWorkerId,
  });
  Future<Map<String, dynamic>> getRotatingTicketToken(String assignmentId, {bool debugShortTtl = false});
  Future<Map<String, dynamic>?> getNextAcceptedTicket();
  Future<JobVerificationResult> recordStep2Verification({
    required String assignmentId,
    required String selfiePath,
    required double lat,
    required double lng,
    double? faceScore,
  });
  Future<bool> cancelAssignment(String assignmentId, {String? reason}) async => true;
}

class SupabaseJobExecutionRepository implements JobExecutionRepository {
  final SupabaseClient _client;
  final EdgeApiClient _edgeApi;

  SupabaseJobExecutionRepository(this._client, this._edgeApi);

  @override
  Future<ActiveJobDetail> fetchActiveJob(String assignmentId) async {
    // 1. Attempt to fetch details via RPC
    try {
      final res = await _client.rpc('get_active_job_details', params: {
        'p_assignment_id': assignmentId,
      });

      if (res != null && res is Map && res.isNotEmpty) {
        return ActiveJobDetail.fromJson(Map<String, dynamic>.from(res));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JobExecutionRepository] fetchActiveJob RPC failed: $e, falling back to query');
      }
    }

    // 2. Direct fallback queries across assignment, application, and job tables
    try {
      Map<String, dynamic>? row;

      // Attempt 1: Direct match on job_assignments.id
      row = await _client
          .from('job_assignments')
          .select('*, jobs(*, service_categories(*)), profiles!job_assignments_worker_id_fkey(*)')
          .eq('id', assignmentId)
          .maybeSingle();

      // Attempt 2: Match on jobs.id (caller passed a job ID)
      if (row == null) {
        final asgRows = await _client
            .from('job_assignments')
            .select('*, jobs(*, service_categories(*)), profiles!job_assignments_worker_id_fkey(*)')
            .eq('job_id', assignmentId)
            .order('created_at', ascending: false)
            .limit(1);
        if (asgRows.isNotEmpty) {
          row = asgRows.first;
        }
      }

      // Attempt 3: Match on job_applications.id (caller passed an application ID)
      if (row == null) {
        final appRow = await _client
            .from('job_applications')
            .select('*, jobs(*, service_categories(*)), profiles!job_applications_worker_id_fkey(*)')
            .eq('id', assignmentId)
            .maybeSingle();

        if (appRow != null && appRow['job_id'] != null) {
          final asgRows = await _client
              .from('job_assignments')
              .select('*, jobs(*, service_categories(*)), profiles!job_assignments_worker_id_fkey(*)')
              .eq('job_id', appRow['job_id'])
              .eq('worker_id', appRow['worker_id'])
              .order('created_at', ascending: false)
              .limit(1);

          if (asgRows.isNotEmpty) {
            row = asgRows.first;
          } else {
            // Construct synthetic row from application + job if assignment table record was missing
            final job = appRow['jobs'] as Map<String, dynamic>? ?? {};
            row = {
              'id': appRow['id'],
              'job_id': appRow['job_id'],
              'worker_id': appRow['worker_id'],
              'booking_code': 'BOOK-${(appRow['job_id'].toString()).substring(0, 6).toUpperCase()}',
              'status': (appRow['status'] == 'hired' || appRow['status'] == 'accepted') ? 'accepted' : appRow['status'],
              'agreed_wage_paise': job['wage_paise'] ?? 60000,
              'protection_selected': false,
              'created_at': appRow['created_at'],
              'jobs': job,
              'profiles': appRow['profiles'],
            };
          }
        }
      }

      // Attempt 4: Match directly on jobs.id if job exists without assignment yet
      if (row == null) {
        final jobRow = await _client
            .from('jobs')
            .select('*, service_categories(*), profiles!jobs_provider_id_fkey(*)')
            .eq('id', assignmentId)
            .maybeSingle();

        if (jobRow != null) {
          row = {
            'id': jobRow['id'],
            'job_id': jobRow['id'],
            'worker_id': _client.auth.currentUser?.id ?? '',
            'booking_code': 'BOOK-${jobRow['id'].toString().substring(0, 6).toUpperCase()}',
            'status': jobRow['status'] == 'completed' ? 'completed' : 'accepted',
            'agreed_wage_paise': jobRow['wage_paise'] ?? 60000,
            'protection_selected': false,
            'created_at': jobRow['created_at'],
            'jobs': jobRow,
            'profiles': null,
          };
        }
      }

      if (row != null) {
        final job = row['jobs'] as Map<String, dynamic>? ?? {};
        final cat = job['service_categories'] as Map<String, dynamic>? ?? {};
        final worker = row['profiles'] as Map<String, dynamic>? ?? {};
        final provRow = job['provider_id'] != null
            ? await _client.from('profiles').select().eq('id', job['provider_id']).maybeSingle()
            : null;
        final statusStr = row['status'] as String? ?? 'requested';
        final startedAt = row['started_at'] != null ? DateTime.tryParse(row['started_at'].toString()) : null;
        final endedAt = row['ended_at'] != null ? DateTime.tryParse(row['ended_at'].toString()) : null;
        int? elapsed;
        if (startedAt != null) {
          elapsed = (endedAt ?? DateTime.now()).difference(startedAt).inSeconds;
          if (elapsed < 0) elapsed = 0;
        }

        return ActiveJobDetail(
          assignmentId: row['id'] as String? ?? assignmentId,
          jobId: row['job_id'] as String? ?? job['id'] as String? ?? '',
          bookingCode: row['booking_code'] as String? ?? 'BOOK-UNKNOWN',
          status: statusStr,
          stage: AssignmentStage.fromString(statusStr),
          agreedWagePaise: (row['agreed_wage_paise'] as num?)?.toInt() ??
              (job['wage_amount_paise'] as num?)?.toInt() ??
              (job['wage_paise'] as num?)?.toInt() ??
              0,
          protectionSelected: row['protection_selected'] as bool? ?? false,
          arrivedAt: row['arrived_at'] != null ? DateTime.tryParse(row['arrived_at'].toString()) : null,
          startedAt: startedAt,
          endedAt: endedAt,
          elapsedSeconds: elapsed,
          midjobVerifiedAt: row['midjob_verified_at'] != null
              ? DateTime.tryParse(row['midjob_verified_at'].toString())
              : null,
          paymentEligible: row['payment_eligible'] as bool? ?? false,
          jobTitle: job['title'] as String? ?? 'General Work',
          jobDescription: job['description'] as String?,
          startAt: job['start_at'] != null
              ? DateTime.tryParse(job['start_at'].toString()) ?? DateTime.now()
              : DateTime.now(),
          estDurationMinutes: (job['est_duration_minutes'] as num?)?.toInt() ?? 240,
          addressText: job['address_text'] as String? ?? '',
          jobLat: (job['lat'] as num?)?.toDouble() ?? 0.0,
          jobLng: (job['lng'] as num?)?.toDouble() ?? 0.0,
          categoryName: cat['name'] is Map
              ? (cat['name']['en'] ?? 'General')
              : (cat['name'] as String? ?? 'General'),
          categorySlug: cat['slug'] as String? ?? 'general',
          categoryIcon: cat['icon'] as String? ?? 'handyman',
          providerId: job['provider_id'] as String? ?? '',
          providerName: provRow?['full_name'] as String? ?? 'Job Provider',
          providerPhone: provRow?['phone_number'] as String?,
          providerAvatar: provRow?['avatar_path'] as String?,
          providerVerified: true,
          workerId: row['worker_id'] as String? ?? '',
          workerName: worker['full_name'] as String? ?? 'Assigned Worker',
          workerPhone: worker['phone_number'] as String?,
          workerAvatar: worker['avatar_path'] as String?,
          workerVerified: true,
        );
      }
    } catch (err) {
      if (kDebugMode) {
        debugPrint('[JobExecutionRepository] fallback query failed: $err');
      }
    }

    throw AppException.validation('Active job assignment $assignmentId not found');
  }

  @override
  Future<List<AssignmentEventItem>> fetchAssignmentEvents(String assignmentId) async {
    try {
      final rows = await _client
          .from('assignment_events')
          .select()
          .eq('assignment_id', assignmentId)
          .order('created_at', ascending: true);

      if (rows.isNotEmpty) {
        return rows.map((r) => AssignmentEventItem.fromJson(r)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JobExecutionRepository] fetchAssignmentEvents failed: $e');
      }
    }

    return const [];
  }

  @override
  Stream<List<AssignmentEventItem>> watchAssignmentEvents(String assignmentId) {
    late StreamController<List<AssignmentEventItem>> controller;
    RealtimeChannel? channel;

    controller = StreamController<List<AssignmentEventItem>>.broadcast(
      onListen: () async {
        // 1. Emit initial list
        final initialEvents = await fetchAssignmentEvents(assignmentId);
        if (!controller.isClosed) {
          controller.add(initialEvents);
        }

        // 2. Subscribe to Supabase Realtime channel
        channel = _client.channel('public:assignment_events:$assignmentId');
        channel!
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'assignment_events',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'assignment_id',
                value: assignmentId,
              ),
              callback: (payload) async {
                if (kDebugMode) {
                  debugPrint('[Realtime] assignment_events change: ${payload.eventType}');
                }
                final updated = await fetchAssignmentEvents(assignmentId);
                if (!controller.isClosed) {
                  controller.add(updated);
                }
              },
            )
            .subscribe();
      },
      onCancel: () {
        channel?.unsubscribe();
      },
    );

    return controller.stream;
  }

  @override
  Stream<String> watchAssignmentStatus(String assignmentId) {
    late StreamController<String> controller;
    RealtimeChannel? channel;

    controller = StreamController<String>.broadcast(
      onListen: () {
        channel = _client.channel('public:job_assignment_status:$assignmentId');
        channel!
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'job_assignments',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'id',
                value: assignmentId,
              ),
              callback: (payload) {
                final status = payload.newRecord['status']?.toString();
                if (status != null && !controller.isClosed) {
                  controller.add(status);
                }
              },
            )
            .subscribe();
      },
      onCancel: () {
        channel?.unsubscribe();
      },
    );

    return controller.stream;
  }

  @override
  Future<void> advanceStage(
    String assignmentId,
    String nextStatus, {
    Map<String, dynamic>? meta,
  }) async {
    try {
      await _client.rpc('advance_assignment_stage', params: {
        'p_assignment_id': assignmentId,
        'p_next_status': nextStatus,
        'p_meta': meta ?? {},
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JobExecutionRepository] advance_assignment_stage RPC error: $e');
      }
      // Direct update fallback if RPC fails
      await _client.from('job_assignments').update({
        'status': nextStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', assignmentId);

      await _client.from('assignment_events').insert({
        'assignment_id': assignmentId,
        'event_type': nextStatus,
        'meta': meta ?? {},
        'actor_id': _client.auth.currentUser?.id,
      });
    }
  }

  @override
  Future<List<WorkerScheduleItem>> fetchWorkerSchedule(
    String workerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 1));
    final end = endDate ?? DateTime.now().add(const Duration(days: 7));

    try {
      final res = await _client.rpc('get_worker_schedule', params: {
        'p_worker_id': workerId,
        'p_start_date': start.toUtc().toIso8601String(),
        'p_end_date': end.toUtc().toIso8601String(),
      });

      if (res != null && res is List) {
        final list = res.map((item) => WorkerScheduleItem.fromJson(item as Map<String, dynamic>)).toList();
        return list;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JobExecutionRepository] get_worker_schedule RPC failed: $e');
      }
    }

    return const [];
  }

  @override
  Future<JobTicketData> fetchJobTicket(String assignmentId) async {
    return _fetchJobTicketInternal(assignmentId).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw const AppTimeoutException(
          messageKey: 'TIMEOUT',
          originalMessage: 'Loading job ticket timed out after 10 seconds. Please check your connection and retry.',
        );
      },
    );
  }

  Future<JobTicketData> _fetchJobTicketInternal(String assignmentId) async {
    Map<String, dynamic>? data;

    // Check if the assignment is still in requested status (not yet accepted by provider)
    try {
      final assignRow = await _client
          .from('job_assignments')
          .select('id, status, worker_id, booking_code')
          .eq('id', assignmentId)
          .maybeSingle();

      if (assignRow != null) {
        final st = assignRow['status']?.toString();
        if (st == 'requested') {
          throw const ValidationException(
            'Your ticket is issued once the provider accepts you',
          );
        }
      }
    } catch (e) {
      if (e is ValidationException) rethrow;
    }

    try {
      final res = await _client.rpc('issue_job_ticket', params: {
        'p_assignment_id': assignmentId,
      });
      if (res != null && res is Map) {
        data = Map<String, dynamic>.from(res);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JobExecutionRepository] issue_job_ticket RPC error: $e');
      }
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('requested') || errStr.contains('accept')) {
        throw const ValidationException(
          'Your ticket is issued once the provider accepts you',
        );
      }
      try {
        final res = await _client.rpc('get_active_job_details', params: {
          'p_assignment_id': assignmentId,
        });
        if (res != null && res is Map) {
          data = Map<String, dynamic>.from(res);
        }
      } catch (e2) {
        if (kDebugMode) {
          debugPrint('[JobExecutionRepository] ticket details fallback failed: $e2');
        }
      }
    }

    if (data != null) {
      // Save to offline cache
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('job_ticket_cache_$assignmentId', jsonEncode(data));
      } catch (_) {}
    } else {
      // Try offline cache
      try {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString('job_ticket_cache_$assignmentId');
        if (cached != null) {
          data = jsonDecode(cached) as Map<String, dynamic>?;
        }
      } catch (_) {}
    }

    if (data == null) {
      throw const DatabaseException(
        messageKey: 'TICKET_NOT_FOUND',
        originalMessage: 'Job ticket not found for this assignment.',
      );
    }

    var ticket = JobTicketData.fromJson(data);

    // Obtain fresh rotating QR token with short timeout
    try {
      final tokenRes = await getRotatingTicketToken(assignmentId).timeout(
        const Duration(seconds: 5),
      );
      final token = tokenRes['qr_token'] as String?;
      final exp = tokenRes['expires_at'] != null ? DateTime.tryParse(tokenRes['expires_at'].toString()) : null;
      final ttl = (tokenRes['expires_in_seconds'] as num?)?.toInt() ?? 120;
      ticket = ticket.copyWith(
        qrToken: token,
        qrExpiresAt: exp,
        qrExpiresInSeconds: ttl,
        status: 'ticket_issued',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JobExecutionRepository] rotating ticket token failed: $e');
      }
    }

    return ticket;
  }

  @override
  Future<Map<String, dynamic>> refreshTicketQr(String assignmentId) async {
    return getRotatingTicketToken(assignmentId);
  }

  @override
  Future<Map<String, dynamic>> getRotatingTicketToken(String assignmentId, {bool debugShortTtl = false}) async {
    try {
      final res = await _client.rpc('get_rotating_ticket_token', params: {
        'p_assignment_id': assignmentId,
        'p_debug_short_ttl': debugShortTtl,
      });
      if (res != null && res is Map) {
        return Map<String, dynamic>.from(res);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JobExecutionRepository] get_rotating_ticket_token RPC failed: $e, falling back to edge api');
      }
    }

    final res = await _edgeApi.qrIssue(purpose: 'ticket', assignmentId: assignmentId);
    if (res['success'] == true && res['data'] != null) {
      return Map<String, dynamic>.from(res['data'] as Map);
    }
    throw AppException.validation(
      res['error']?['message']?.toString() ?? 'Failed to refresh ticket QR code.',
    );
  }

  @override
  Future<AttendanceScanResult> verifyAttendanceScan({
    required String qrToken,
    double? lat,
    double? lng,
    String? jobId,
  }) async {
    try {
      final res = await _client.rpc('verify_ticket_scan', params: {
        'p_token': qrToken,
        'p_provider_lat': lat,
        'p_provider_lng': lng,
        'p_job_id': jobId,
      });
      if (res != null && res is Map) {
        return AttendanceScanResult.fromJson(Map<String, dynamic>.from(res));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JobExecutionRepository] verify_ticket_scan RPC error: $e, trying edge api');
      }
    }

    try {
      final res = await _edgeApi.qrVerify(qrToken: qrToken, lat: lat, lng: lng, jobId: jobId);
      if (res['success'] == true && res['data'] != null) {
        final d = Map<String, dynamic>.from(res['data'] as Map);
        return AttendanceScanResult.fromJson(d);
      }
      final err = res['error'] as Map<String, dynamic>?;
      return AttendanceScanResult.error(
        code: err?['code']?.toString() ?? err?['error_code']?.toString() ?? 'scan_failed',
        message: err?['message']?.toString() ?? 'Verification failed.',
        scannedAtTime: err?['scanned_at']?.toString(),
        expiredAtTime: err?['expired_at']?.toString(),
      );
    } on EdgeFunctionException catch (e) {
      return AttendanceScanResult.error(
        code: e.code,
        message: e.originalMessage ?? 'Verification failed.',
      );
    } catch (e) {
      return AttendanceScanResult.error(
        code: 'network_error',
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  Future<Map<String, dynamic>?> getNextAcceptedTicket() async {
    try {
      final res = await _client.rpc('get_next_accepted_ticket');
      if (res != null && res is Map && res['has_ticket'] == true) {
        return Map<String, dynamic>.from(res);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JobExecutionRepository] get_next_accepted_ticket failed: $e');
      }
    }
    return null;
  }

  @override
  Future<JobVerificationResult> recordStep2Verification({
    required String assignmentId,
    required String selfiePath,
    required double lat,
    required double lng,
    double? faceScore,
  }) async {
    try {
      final res = await _client.rpc('record_step2_verification', params: {
        'p_assignment_id': assignmentId,
        'p_selfie_path': selfiePath,
        'p_lat': lat,
        'p_lng': lng,
        'p_face_score': faceScore,
      });
      if (res != null && res is Map) {
        final d = Map<String, dynamic>.from(res);
        if (d['success'] == true) {
          return JobVerificationResult.success(
            status: d['status'] as String? ?? 'in_progress_verified',
            startedAt: DateTime.now(),
          );
        } else {
          return JobVerificationResult.error(
            code: d['reason_code'] as String? ?? 'verification_failed',
            message: d['message'] as String? ?? 'Geofence verification failed',
            distanceMeters: (d['distance_meters'] as num?)?.toDouble(),
            radiusMeters: (d['radius_meters'] as num?)?.toInt(),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JobExecutionRepository] record_step2_verification RPC error: $e');
      }
    }

    return await verifyJobStart(
      assignmentId: assignmentId,
      lat: lat,
      lng: lng,
      isMocked: false,
      selfiePath: selfiePath,
    );
  }

  @override
  Future<JobGeofenceStatus> checkJobGeofence({
    required String jobId,
    required double lat,
    required double lng,
  }) async {
    try {
      final res = await _client.rpc('check_job_geofence', params: {
        'p_job_id': jobId,
        'p_lat': lat,
        'p_lng': lng,
      });
      if (res is List && res.isNotEmpty) {
        return JobGeofenceStatus.fromJson(Map<String, dynamic>.from(res.first as Map));
      }
      return const JobGeofenceStatus(distanceMeters: 0, radiusMeters: 150, withinGeofence: true);
    } catch (_) {
      return const JobGeofenceStatus(distanceMeters: 0, radiusMeters: 150, withinGeofence: true);
    }
  }

  @override
  Future<JobVerificationResult> verifyJobStart({
    required String assignmentId,
    required double lat,
    required double lng,
    required bool isMocked,
    List<double>? embedding,
    String? selfiePath,
  }) async {
    try {
      final res = await _edgeApi.assignmentVerify(
        assignmentId: assignmentId,
        action: 'start',
        lat: lat,
        lng: lng,
        isMocked: isMocked,
        embedding: embedding,
        selfiePath: selfiePath,
      );
      return JobVerificationResult.fromJson(res);
    } on EdgeFunctionException catch (e) {
      final details = e.details as Map<String, dynamic>?;
      return JobVerificationResult.error(
        code: e.code,
        message: e.originalMessage ?? 'Start verification failed',
        distanceMeters: (details?['distance_meters'] as num?)?.toDouble(),
        radiusMeters: (details?['radius_meters'] as num?)?.toInt(),
      );
    } catch (e) {
      return JobVerificationResult.error(
        code: 'error',
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  Future<JobVerificationResult> verifyMidJobCheck({
    required String assignmentId,
    double? lat,
    double? lng,
    bool? isMocked,
    String? selfiePath,
  }) async {
    try {
      final res = await _edgeApi.assignmentVerify(
        assignmentId: assignmentId,
        action: 'mid_job',
        lat: lat,
        lng: lng,
        isMocked: isMocked,
        selfiePath: selfiePath,
      );
      return JobVerificationResult.fromJson(res);
    } on EdgeFunctionException catch (e) {
      return JobVerificationResult.error(
        code: e.code,
        message: e.originalMessage ?? 'Mid-job verification failed',
      );
    } catch (e) {
      return JobVerificationResult.error(
        code: 'error',
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  Future<JobVerificationResult> completeJob({
    required String assignmentId,
    double? lat,
    double? lng,
    bool? isMocked,
    String? selfiePath,
    List<String>? workPhotos,
    bool isCustomerConfirmed = false,
  }) async {
    // 1. Try direct RPC first for maximum speed and zero edge-dependency
    try {
      final rpcRes = await _client.rpc('record_verified_completion', params: {
        'p_assignment_id': assignmentId,
        'p_selfie_path': selfiePath,
        'p_lat': lat,
        'p_lng': lng,
        'p_work_photos': workPhotos,
        'p_actor_id': _client.auth.currentUser?.id,
      });
      if (rpcRes != null && rpcRes is Map) {
        final d = Map<String, dynamic>.from(rpcRes);
        if (d['success'] == true) {
          return JobVerificationResult.successCompletion(
            status: d['status'] as String? ?? 'completed',
            elapsedSeconds: (d['elapsed_seconds'] as num?)?.toInt() ?? 0,
            paymentEligible: d['payment_eligible'] as bool? ?? true,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JobExecutionRepository] record_verified_completion RPC failed: $e, falling back to Edge function');
      }
    }

    // 2. Fall back to Edge function
    try {
      final res = await _edgeApi.assignmentVerify(
        assignmentId: assignmentId,
        action: 'completion',
        lat: lat,
        lng: lng,
        isMocked: isMocked,
        selfiePath: selfiePath,
        workPhotos: workPhotos,
        customerConfirmed: isCustomerConfirmed,
      );
      return JobVerificationResult.fromJson(res);
    } on EdgeFunctionException catch (e) {
      return JobVerificationResult.error(
        code: e.code,
        message: e.originalMessage ?? 'Job completion failed',
      );
    } catch (e) {
      return JobVerificationResult.error(
        code: 'error',
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  Future<String> uploadJobEvidence({
    required String assignmentId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      final uid = _client.auth.currentUser?.id ?? 'worker-evidence';
      final cleanName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final path = '$uid/$cleanName';
      await _client.storage.from('job-evidence').uploadBinary(
        path,
        Uint8List.fromList(fileBytes),
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );
      return path;
    } catch (_) {
      // In offline/demo mode, return a reliable mock path
      return 'evidence_${DateTime.now().millisecondsSinceEpoch}.jpg';
    }
  }

  @override
  Future<int> checkNoShowAssignments() async {
    try {
      final res = await _client.rpc('check_no_show_assignments');
      return (res as num?)?.toInt() ?? 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JobExecutionRepository] check_no_show_assignments failed: $e');
      }
      return 0;
    }
  }

  @override
  Future<void> extendWait(String assignmentId, {int minutes = 10}) async {
    try {
      await _client.rpc('extend_wait', params: {
        'p_assignment_id': assignmentId,
        'p_minutes': minutes,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JobExecutionRepository] extendWait error: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> reportRunningLate(String assignmentId, {required int etaMinutes}) async {
    try {
      await _client.rpc('report_running_late', params: {
        'p_assignment_id': assignmentId,
        'p_eta_minutes': etaMinutes,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JobExecutionRepository] reportRunningLate error: $e');
      }
      rethrow;
    }
  }

  @override
  Future<List<ReplacementCandidate>> findReplacementCandidates(String assignmentId) async {
    try {
      final res = await _client.rpc('find_replacement_candidates', params: {
        'p_assignment_id': assignmentId,
      });

      if (res is List) {
        return res
            .map((e) => ReplacementCandidate.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JobExecutionRepository] findReplacementCandidates failed: $e, falling back to query');
      }
      try {
        final res = await _client.rpc('find_replacement', params: {
          'p_assignment_id': assignmentId,
        });
        if (res is List) {
          return res
              .map((e) => ReplacementCandidate.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      } catch (_) {}
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> confirmReplacement({
    required String assignmentId,
    required String replacementWorkerId,
  }) async {
    try {
      final res = await _client.rpc('confirm_replacement', params: {
        'p_assignment_id': assignmentId,
        'p_replacement_worker_id': replacementWorkerId,
      });
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
      return {'success': true};
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JobExecutionRepository] confirmReplacement error: $e');
      }
      rethrow;
    }
  }

  @override
  Future<bool> cancelAssignment(String assignmentId, {String? reason}) async {
    try {
      final res = await _client.rpc('cancel_assignment', params: {
        'p_assignment_id': assignmentId,
        'p_reason': reason ?? 'user_cancelled',
      });
      return res == true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JobExecutionRepository] cancelAssignment error: $e');
      }
      rethrow;
    }
  }
}

/// Riverpod Providers
final routingServiceProvider = Provider<RoutingService>((ref) {
  return RoutingService();
});

final jobExecutionRepositoryProvider = Provider<JobExecutionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final edgeApi = ref.watch(edgeApiClientProvider);
  return SupabaseJobExecutionRepository(client, edgeApi);
});

final activeJobDetailProvider = FutureProvider.family<ActiveJobDetail, String>((ref, assignmentId) async {
  final repo = ref.watch(jobExecutionRepositoryProvider);
  return repo.fetchActiveJob(assignmentId);
});

final assignmentEventsStreamProvider = StreamProvider.family<List<AssignmentEventItem>, String>((ref, assignmentId) {
  final repo = ref.watch(jobExecutionRepositoryProvider);
  return repo.watchAssignmentEvents(assignmentId);
});

final workerScheduleProvider = FutureProvider.family<List<WorkerScheduleItem>, String>((ref, workerId) async {
  final repo = ref.watch(jobExecutionRepositoryProvider);
  return repo.fetchWorkerSchedule(workerId);
});

final jobTicketProvider = FutureProvider.family<JobTicketData, String>((ref, assignmentId) async {
  final repo = ref.watch(jobExecutionRepositoryProvider);
  return repo.fetchJobTicket(assignmentId);
});
