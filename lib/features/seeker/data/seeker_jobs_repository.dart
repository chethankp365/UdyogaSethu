import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_job_item.dart';

abstract class SeekerJobsRepository {
  Future<Map<SeekerJobSegment, List<SeekerJobItem>>> fetchSeekerJobs();
  Stream<Map<SeekerJobSegment, List<SeekerJobItem>>> watchSeekerJobs();
  Future<({bool travelWarning, double? gapMinutes})> acceptAssignment(String assignmentId);
  Future<bool> declineAssignment(String assignmentId);
  Future<void> debugSeedOverlappingRequests();
}

class SupabaseSeekerJobsRepository implements SeekerJobsRepository {
  final SupabaseClient? _client;

  SupabaseSeekerJobsRepository([this._client]);

  String? _getUserId() {
    try {
      if (_client != null && Supabase.instance.isInitialized) {
        return _client.auth.currentUser?.id;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<Map<SeekerJobSegment, List<SeekerJobItem>>> fetchSeekerJobs() async {
    final Map<SeekerJobSegment, List<SeekerJobItem>> result = {
      SeekerJobSegment.applied: [],
      SeekerJobSegment.accepted: [],
      SeekerJobSegment.active: [],
      SeekerJobSegment.completed: [],
      SeekerJobSegment.requests: [],
    };

    final uid = _getUserId();
    if (uid == null || _client == null) {
      return result;
    }

    try {
      // 1. Fetch Job Applications (Applied segment)
      final apps = await _client
          .from('job_applications')
          .select('*, jobs!job_id(title, wage_paise, start_at, est_duration_minutes, address_text, profiles!provider_id(full_name), service_categories(slug, icon))')
          .eq('worker_id', uid)
          .order('created_at', ascending: false);

      for (final a in (apps as List)) {
        final job = a['jobs'] as Map<String, dynamic>? ?? {};
        final provider = job['profiles'] as Map<String, dynamic>?;
        final cat = job['service_categories'] as Map<String, dynamic>?;

        result[SeekerJobSegment.applied]!.add(SeekerJobItem(
          id: a['id'] as String,
          jobId: a['job_id'] as String,
          title: job['title'] as String? ?? 'Work',
          providerName: provider?['full_name'] as String? ?? 'Employer',
          providerVerified: true,
          wagePaise: (job['wage_paise'] as num?)?.toInt() ?? 60000,
          startAt: job['start_at'] != null ? DateTime.parse(job['start_at']) : DateTime.now(),
          estDurationMinutes: (job['est_duration_minutes'] as num?)?.toInt() ?? 480,
          status: a['status'] as String? ?? 'applied',
          segment: SeekerJobSegment.applied,
          categorySlug: cat?['slug'] as String? ?? 'general',
          categoryIcon: cat?['icon'] as String? ?? 'handyman',
          addressText: job['address_text'] as String? ?? '',
          message: a['message'] as String?,
        ));
      }

      // 2. Fetch Job Assignments (Requests, Accepted, Active, Completed)
      final assigns = await _client
          .from('job_assignments')
          .select('*, jobs!job_id(title, wage_paise, start_at, est_duration_minutes, address_text, profiles!provider_id(full_name), service_categories(slug, icon))')
          .eq('worker_id', uid)
          .order('created_at', ascending: false);

      for (final asg in (assigns as List)) {
        final job = asg['jobs'] as Map<String, dynamic>? ?? {};
        final provider = job['profiles'] as Map<String, dynamic>?;
        final cat = job['service_categories'] as Map<String, dynamic>?;
        final status = (asg['status'] as String? ?? 'requested').toLowerCase();

        SeekerJobSegment segment;
        if (status == 'requested') {
          segment = SeekerJobSegment.requests;
        } else if (status == 'accepted' || status == 'ticket_issued') {
          segment = SeekerJobSegment.accepted;
        } else if (status == 'arrived' || status == 'in_progress_verified') {
          segment = SeekerJobSegment.active;
        } else if (status == 'completed' || status == 'payment_released') {
          segment = SeekerJobSegment.completed;
        } else {
          // cancelled, disputed, no_show -> don't show or place in completed
          segment = SeekerJobSegment.completed;
        }

        result[segment]!.add(SeekerJobItem(
          id: asg['id'] as String,
          jobId: asg['job_id'] as String,
          title: job['title'] as String? ?? 'Direct Work Booking',
          providerName: provider?['full_name'] as String? ?? 'Employer',
          providerVerified: true,
          wagePaise: (asg['agreed_wage_paise'] as num?)?.toInt() ?? (job['wage_paise'] as num?)?.toInt() ?? 75000,
          startAt: job['start_at'] != null ? DateTime.parse(job['start_at']) : DateTime.now(),
          estDurationMinutes: (job['est_duration_minutes'] as num?)?.toInt() ?? 240,
          status: status,
          segment: segment,
          bookingCode: asg['booking_code'] as String?,
          categorySlug: cat?['slug'] as String? ?? 'general',
          categoryIcon: cat?['icon'] as String? ?? 'handyman',
          addressText: job['address_text'] as String? ?? '',
        ));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SeekerJobsRepository] fetchSeekerJobs error: $e');
      }
    }

    return result;
  }

  @override
  Stream<Map<SeekerJobSegment, List<SeekerJobItem>>> watchSeekerJobs() {
    final controller = StreamController<Map<SeekerJobSegment, List<SeekerJobItem>>>.broadcast();

    // Initial load
    fetchSeekerJobs().then((data) {
      if (!controller.isClosed) controller.add(data);
    }).catchError((e) {
      if (!controller.isClosed) controller.addError(e);
    });

    if (_client != null && Supabase.instance.isInitialized) {
      final uid = _getUserId();
      if (uid != null) {
        final channel = _client.channel('public:seeker_jobs_$uid');
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
              callback: (_) async {
                final fresh = await fetchSeekerJobs();
                if (!controller.isClosed) controller.add(fresh);
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
              callback: (_) async {
                final fresh = await fetchSeekerJobs();
                if (!controller.isClosed) controller.add(fresh);
              },
            )
            .subscribe();

        controller.onCancel = () {
          _client.removeChannel(channel);
        };
      }
    }

    return controller.stream;
  }

  @override
  Future<({bool travelWarning, double? gapMinutes})> acceptAssignment(String assignmentId) async {
    if (_client == null || !Supabase.instance.isInitialized) {
      throw Exception('Network offline. Cannot accept assignment.');
    }

    final res = await _client.rpc('accept_assignment', params: {
      'p_assignment_id': assignmentId,
    });

    final Map<String, dynamic> data = res is String
        ? jsonDecode(res) as Map<String, dynamic>
        : Map<String, dynamic>.from(res as Map);

    final warning = data['travel_warning'] as bool? ?? false;
    final gap = (data['gap_minutes'] as num?)?.toDouble();

    return (travelWarning: warning, gapMinutes: gap);
  }

  @override
  Future<bool> declineAssignment(String assignmentId) async {
    if (_client == null || !Supabase.instance.isInitialized) {
      throw Exception('Network offline. Cannot decline assignment.');
    }

    final res = await _client.rpc('decline_assignment', params: {
      'p_assignment_id': assignmentId,
    });

    return res == true;
  }

  @override
  Future<void> debugSeedOverlappingRequests() async {
    if (_client == null || !Supabase.instance.isInitialized) {
      throw Exception('Network offline. Cannot seed debug requests.');
    }

    final uid = _getUserId();
    await _client.rpc('debug_seed_overlapping_requests', params: {
      'p_worker_id': uid,
    });
  }
}

final seekerJobsRepositoryProvider = Provider<SeekerJobsRepository>((ref) {
  SupabaseClient? client;
  try {
    if (Supabase.instance.isInitialized) {
      client = Supabase.instance.client;
    }
  } catch (_) {}
  return SupabaseSeekerJobsRepository(client);
});
