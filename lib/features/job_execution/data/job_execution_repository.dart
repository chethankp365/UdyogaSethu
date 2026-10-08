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

abstract class JobExecutionRepository {
  Future<ActiveJobDetail> fetchActiveJob(String assignmentId);
  Future<List<AssignmentEventItem>> fetchAssignmentEvents(String assignmentId);
  Stream<List<AssignmentEventItem>> watchAssignmentEvents(String assignmentId);
  Future<void> advanceStage(String assignmentId, String nextStatus, {Map<String, dynamic>? meta});
  Future<List<WorkerScheduleItem>> fetchWorkerSchedule(String workerId, {DateTime? startDate, DateTime? endDate});
  Future<JobTicketData> fetchJobTicket(String assignmentId);
  Future<Map<String, dynamic>> refreshTicketQr(String assignmentId);
  Future<AttendanceScanResult> verifyAttendanceScan({required String qrToken, double? lat, double? lng});
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
}

class SupabaseJobExecutionRepository implements JobExecutionRepository {
  final SupabaseClient _client;
  final EdgeApiClient _edgeApi;

  SupabaseJobExecutionRepository(this._client, this._edgeApi);

  @override
  Future<ActiveJobDetail> fetchActiveJob(String assignmentId) async {
    try {
      final res = await _client.rpc('get_active_job_details', params: {
        'p_assignment_id': assignmentId,
      });

      if (res != null && res is Map<String, dynamic>) {
        return ActiveJobDetail.fromJson(res);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JobExecutionRepository] fetchActiveJob RPC failed: $e, falling back to query');
      }
      try {
        final row = await _client
            .from('job_assignments')
            .select('*, jobs(*, service_categories(*))')
            .eq('id', assignmentId)
            .maybeSingle();

        if (row != null) {
          final job = row['jobs'] as Map<String, dynamic>? ?? {};
          final cat = job['service_categories'] as Map<String, dynamic>? ?? {};
          return ActiveJobDetail(
            assignmentId: assignmentId,
            jobId: row['job_id'] as String? ?? '',
            bookingCode: row['booking_code'] as String? ?? 'BOOK-DEMO',
            status: row['status'] as String? ?? 'requested',
            stage: AssignmentStage.fromString(row['status'] as String? ?? 'requested'),
            agreedWagePaise: (row['agreed_wage_paise'] as num?)?.toInt() ?? 60000,
            protectionSelected: row['protection_selected'] as bool? ?? false,
            arrivedAt: row['arrived_at'] != null ? DateTime.tryParse(row['arrived_at'].toString()) : null,
            startedAt: row['started_at'] != null ? DateTime.tryParse(row['started_at'].toString()) : null,
            endedAt: row['ended_at'] != null ? DateTime.tryParse(row['ended_at'].toString()) : null,
            elapsedSeconds: (row['elapsed_seconds'] as num?)?.toInt(),
            midjobVerifiedAt: row['midjob_verified_at'] != null
                ? DateTime.tryParse(row['midjob_verified_at'].toString())
                : null,
            paymentEligible: row['payment_eligible'] as bool? ?? false,
            jobTitle: job['title'] as String? ?? 'General Work',
            jobDescription: job['description'] as String?,
            startAt: job['start_at'] != null
                ? DateTime.tryParse(job['start_at'].toString()) ?? DateTime.now()
                : DateTime.now(),
            estDurationMinutes: (job['est_duration_minutes'] as num?)?.toInt() ?? 480,
            addressText: job['address_text'] as String? ?? 'Koramangala, Bengaluru',
            jobLat: 12.9352,
            jobLng: 77.6245,
            categoryName: cat['name'] is Map ? (cat['name']['en'] ?? 'General') : 'General',
            categorySlug: cat['slug'] as String? ?? 'general',
            categoryIcon: cat['icon'] as String? ?? 'handyman',
            providerId: job['provider_id'] as String? ?? '',
            providerName: 'Verified Employer',
            providerPhone: '+91 99000 00002',
            providerVerified: true,
            workerId: row['worker_id'] as String? ?? '',
            workerName: 'Verified Worker',
            workerPhone: '+91 99000 00001',
            workerVerified: true,
            workerLat: 12.9279,
            workerLng: 77.6271,
          );
        }
      } catch (err) {
        if (kDebugMode) {
          debugPrint('[JobExecutionRepository] fallback query failed: $err');
        }
      }
    }

    // Demo fallback for preview / offline demo
    return ActiveJobDetail(
      assignmentId: assignmentId,
      jobId: 'job-demo-401',
      bookingCode: 'BOOK-DEMO78',
      status: 'in_progress_verified',
      stage: AssignmentStage.jobInProgress,
      agreedWagePaise: 75000,
      protectionSelected: true,
      arrivedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      startedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      jobTitle: 'Commercial Electrical Repair & Wiring',
      jobDescription: 'Fix main switchboard and verify secondary circuits with earthing check.',
      startAt: DateTime.now().subtract(const Duration(minutes: 30)),
      estDurationMinutes: 180,
      addressText: '4th Block, Koramangala, Bengaluru - 560034',
      jobLat: 12.9352,
      jobLng: 77.6245,
      categoryName: 'Electrician',
      categorySlug: 'electrician',
      categoryIcon: 'flash_on',
      providerId: 'provider-demo-1',
      providerName: 'SK Sharma Builders',
      providerPhone: '+91 98450 12345',
      providerVerified: true,
      workerId: 'worker-demo-1',
      workerName: 'Chethan Kumar',
      workerPhone: '+91 91234 56789',
      workerVerified: true,
      workerLat: 12.9279,
      workerLng: 77.6271,
    );
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

    // Default seeded events for demo/offline fallback
    final now = DateTime.now();
    return [
      AssignmentEventItem(
        id: 'evt-1',
        assignmentId: assignmentId,
        rawEventType: 'requested',
        stage: AssignmentStage.requestCreated,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      AssignmentEventItem(
        id: 'evt-2',
        assignmentId: assignmentId,
        rawEventType: 'accepted',
        stage: AssignmentStage.accepted,
        createdAt: now.subtract(const Duration(hours: 2, minutes: 30)),
      ),
      AssignmentEventItem(
        id: 'evt-3',
        assignmentId: assignmentId,
        rawEventType: 'ticket_issued',
        stage: AssignmentStage.ticketIssued,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      AssignmentEventItem(
        id: 'evt-4',
        assignmentId: assignmentId,
        rawEventType: 'arrived',
        stage: AssignmentStage.workerArrived,
        createdAt: now.subtract(const Duration(minutes: 45)),
      ),
      AssignmentEventItem(
        id: 'evt-5',
        assignmentId: assignmentId,
        rawEventType: 'verification_completed',
        stage: AssignmentStage.verificationCompleted,
        createdAt: now.subtract(const Duration(minutes: 35)),
      ),
      AssignmentEventItem(
        id: 'evt-6',
        assignmentId: assignmentId,
        rawEventType: 'in_progress_verified',
        stage: AssignmentStage.jobInProgress,
        createdAt: now.subtract(const Duration(minutes: 30)),
      ),
    ];
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
        'p_start_date': start.toIso8601String(),
        'p_end_date': end.toIso8601String(),
      });

      if (res != null && res is List) {
        final list = res.map((item) => WorkerScheduleItem.fromJson(item as Map<String, dynamic>)).toList();
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JobExecutionRepository] get_worker_schedule RPC failed: $e');
      }
    }

    // Demo realistic schedule for testing Day & Week views and Travel Warning chip
    final now = DateTime.now();
    final today10am = DateTime(now.year, now.month, now.day, 10, 0);
    final today12pm = DateTime(now.year, now.month, now.day, 12, 0);
    final today1220pm = DateTime(now.year, now.month, now.day, 12, 20); // 20 min gap!
    final today3pm = DateTime(now.year, now.month, now.day, 15, 0);

    return [
      WorkerScheduleItem(
        assignmentId: 'assign-sched-1',
        jobId: 'job-sched-1',
        title: 'Ceiling Fan Installation & Switch Check',
        status: 'accepted',
        bookingCode: 'BOOK-7801',
        agreedWagePaise: 50000,
        startAt: today10am,
        endAt: today12pm,
        estDurationMinutes: 120,
        addressText: 'Jayanagar 4th T Block, Bengaluru',
        jobLat: 12.9250,
        jobLng: 77.5938,
        categorySlug: 'electrician',
        categoryIcon: 'flash_on',
        providerName: 'Anil Kumar',
        gapFromPrevMinutes: null,
        gapToNextMinutes: 20.0,
        estimatedTravelMinutes: 35,
      ),
      WorkerScheduleItem(
        assignmentId: 'assign-sched-2',
        jobId: 'job-sched-2',
        title: 'Office MCB Fuse & Power Outage Repair',
        status: 'accepted',
        bookingCode: 'BOOK-7802',
        agreedWagePaise: 80000,
        startAt: today1220pm,
        endAt: today3pm,
        estDurationMinutes: 160,
        addressText: 'Indiranagar 100ft Road, Bengaluru',
        jobLat: 12.9719,
        jobLng: 77.6412,
        categorySlug: 'electrician',
        categoryIcon: 'flash_on',
        providerName: 'TechHub Solutions',
        gapFromPrevMinutes: 20.0, // Only 20 min gap, travel time is ~35 min -> Travel warning!
        gapToNextMinutes: 120.0,
        estimatedTravelMinutes: 35,
      ),
      WorkerScheduleItem(
        assignmentId: 'assign-sched-3',
        jobId: 'job-sched-3',
        title: 'Living Room Wall Socket Setup',
        status: 'requested',
        bookingCode: 'BOOK-7803',
        agreedWagePaise: 45000,
        startAt: today10am.add(const Duration(days: 1)),
        endAt: today12pm.add(const Duration(days: 1)),
        estDurationMinutes: 120,
        addressText: 'HSR Layout Sector 2, Bengaluru',
        jobLat: 12.9121,
        jobLng: 77.6446,
        categorySlug: 'electrician',
        categoryIcon: 'flash_on',
        providerName: 'Sneha Rao',
        gapFromPrevMinutes: null,
        gapToNextMinutes: null,
        estimatedTravelMinutes: 25,
      ),
    ];
  }

  @override
  Future<JobTicketData> fetchJobTicket(String assignmentId) async {
    Map<String, dynamic>? data;
    try {
      final res = await _client.rpc('get_job_ticket_details', params: {
        'p_assignment_id': assignmentId,
      });
      if (res != null && res is Map<String, dynamic>) {
        data = res;
        // Save to offline cache
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('job_ticket_cache_$assignmentId', jsonEncode(data));
        } catch (_) {}
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JobExecutionRepository] get_job_ticket_details RPC failed: $e. Checking offline cache.');
      }
    }

    if (data == null) {
      // Try offline cache
      try {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString('job_ticket_cache_$assignmentId');
        if (cached != null) {
          data = jsonDecode(cached) as Map<String, dynamic>?;
        }
      } catch (_) {}
    }

    data ??= {
      // Fallback demo ticket if completely missing
      'assignment_id': assignmentId,
      'booking_code': 'BOOK-7842',
      'status': 'ticket_issued',
      'job_id': 'job-demo',
      'job_title': 'Commercial Electrical Repair',
      'category_name': 'Electrician',
      'category_icon': 'flash_on',
      'start_at': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
      'est_duration_minutes': 240,
      'agreed_wage_paise': 80000,
      'wage_type': 'daily',
      'payment_mode': 'escrow',
      'address_text': 'MG Road, Bengaluru',
      'lat': 12.9716,
      'lng': 77.5946,
      'worker_id': _client.auth.currentUser?.id ?? 'worker-demo',
      'worker_name': 'Assigned Worker',
      'worker_avatar': null,
      'is_worker_verified': true,
      'provider_id': 'provider-demo',
      'provider_name': 'Bengaluru Metro Office',
    };

    var ticket = JobTicketData.fromJson(data);

    // Try issuing fresh QR token
    try {
      final qrRes = await _edgeApi.qrIssue(purpose: 'ticket', assignmentId: assignmentId);
      if (qrRes['success'] == true && qrRes['data'] != null) {
        final d = qrRes['data'] as Map<String, dynamic>;
        ticket = ticket.copyWith(
          qrToken: d['qr_token'] as String?,
          qrExpiresInSeconds: (d['expires_in_seconds'] as num?)?.toInt() ?? 120,
          qrExpiresAt: d['expires_at'] != null ? DateTime.tryParse(d['expires_at'].toString()) : null,
          status: 'ticket_issued',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JobExecutionRepository] qrIssue failed: $e');
      }
    }

    return ticket;
  }

  @override
  Future<Map<String, dynamic>> refreshTicketQr(String assignmentId) async {
    final res = await _edgeApi.qrIssue(purpose: 'ticket', assignmentId: assignmentId);
    if (res['success'] == true && res['data'] != null) {
      return Map<String, dynamic>.from(res['data'] as Map);
    }
    throw AppException.validation(
      res['error']?['message']?.toString() ?? 'Failed to refresh ticket QR code.',
    );
  }

  @override
  Future<AttendanceScanResult> verifyAttendanceScan({required String qrToken, double? lat, double? lng}) async {
    try {
      final res = await _edgeApi.qrVerify(qrToken: qrToken, lat: lat, lng: lng);
      if (res['success'] == true && res['data'] != null) {
        final d = Map<String, dynamic>.from(res['data'] as Map);
        return AttendanceScanResult.fromJson(d);
      }
      final err = res['error'] as Map<String, dynamic>?;
      return AttendanceScanResult.error(
        code: err?['code']?.toString() ?? 'scan_failed',
        message: err?['message']?.toString() ?? 'Verification failed.',
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
