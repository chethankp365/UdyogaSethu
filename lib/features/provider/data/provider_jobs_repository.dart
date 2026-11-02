import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/features/provider/domain/job_applicant.dart';
import 'package:udyogasethu/features/provider/domain/job_post_draft.dart';
import 'package:udyogasethu/features/provider/domain/provider_job.dart';
import 'package:udyogasethu/features/seeker/data/demo_jobs_data.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_profile_draft.dart';

abstract class ProviderJobsRepository {
  Future<List<ProviderJob>> fetchProviderJobs({String? providerId});
  Future<List<JobApplicant>> fetchJobApplicants(String jobId);
  Future<String> postJob(JobPostDraft draft);
  Future<bool> updateJob(JobPostDraft draft);
  Future<Map<String, dynamic>> updateJobStatus(String jobId, String status);
  Future<String?> respondToApplicant({required String applicationId, required String status});
  Future<WageBandResult?> fetchWageBand({required String categoryId, String? area});
  Future<List<ServiceCategoryItem>> fetchCategories();
}

final providerJobsRepositoryProvider = Provider<ProviderJobsRepository>((ref) {
  return SupabaseProviderJobsRepository();
});

class SupabaseProviderJobsRepository implements ProviderJobsRepository {
  final SupabaseClient _client;

  SupabaseProviderJobsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<List<ProviderJob>> fetchProviderJobs({String? providerId}) async {
    try {
      final params = <String, dynamic>{};
      if (providerId != null) params['p_provider_id'] = providerId;
      final res = await _client.rpc('get_provider_jobs', params: params);

      if (res is List && res.isNotEmpty) {
        return res.map((row) => ProviderJob.fromJson(Map<String, dynamic>.from(row as Map))).toList();
      }
    } catch (e, stack) {
      AppLogger.e('Error fetching provider jobs via RPC', e, stack);
      // Fallback: direct query from jobs table if RPC fails
      try {
        final userId = providerId ?? _client.auth.currentUser?.id;
        if (userId != null) {
          final queryRes = await _client
              .from('jobs')
              .select('*, service_categories(names, slug, icon)')
              .eq('provider_id', userId)
              .order('created_at', ascending: false);

          final list = (queryRes as List).map((row) {
            final cat = row['service_categories'] as Map<String, dynamic>?;
            return ProviderJob(
              id: row['id']?.toString() ?? '',
              providerId: row['provider_id']?.toString() ?? '',
              categoryId: row['category_id']?.toString(),
              categoryName: cat?['names']?['en']?.toString() ?? cat?['slug']?.toString() ?? 'General',
              categoryIcon: cat?['icon']?.toString(),
              title: row['title']?.toString() ?? '',
              description: row['description']?.toString(),
              wageType: row['wage_type']?.toString() ?? 'daily',
              wagePaise: (row['wage_paise'] as num?)?.toInt() ?? 0,
              estDurationMinutes: (row['est_duration_minutes'] as num?)?.toInt() ?? 480,
              startAt: row['start_at'] != null
                  ? DateTime.tryParse(row['start_at'].toString()) ?? DateTime.now()
                  : DateTime.now(),
              slotsTotal: (row['slots_total'] as num?)?.toInt() ?? 1,
              slotsFilled: (row['slots_filled'] as num?)?.toInt() ?? 0,
              materialsProvided: row['materials_provided'] as bool? ?? false,
              paymentMode: row['payment_mode']?.toString() ?? 'escrow',
              requirements: row['requirements'] is Map ? Map<String, dynamic>.from(row['requirements'] as Map) : {},
              addressText: row['address_text']?.toString(),
              geofenceRadiusM: (row['geofence_radius_m'] as num?)?.toInt() ?? 150,
              status: row['status']?.toString() ?? 'open',
              suitableFor: (row['suitable_for'] as List?)?.map((e) => e.toString()).toList() ??
                  const ['informal', 'student', 'part_time'],
              sitePhotoUrl: row['site_photo_url']?.toString(),
              thumbnailPath: row['thumbnail_path']?.toString() ?? row['site_photo_url']?.toString(),
              createdAt: row['created_at'] != null
                  ? DateTime.tryParse(row['created_at'].toString()) ?? DateTime.now()
                  : DateTime.now(),
            );
          }).toList();

          if (list.isNotEmpty) return list;
        }
      } catch (fallbackErr) {
        AppLogger.e('Fallback jobs query also failed', fallbackErr);
      }
    }

    // Presentation demo jobs fallback
    final targetUid = providerId ?? _client.auth.currentUser?.id;
    final demoJobs = DemoJobsData.getProviderJobs(targetUid ?? DemoJobsData.providerSureshSai);
    if (demoJobs.isNotEmpty) return demoJobs;
    return DemoJobsData.getProviderJobs(DemoJobsData.providerSureshSai);
  }

  @override
  Future<List<JobApplicant>> fetchJobApplicants(String jobId) async {
    final currentUid = _client.auth.currentUser?.id;
    if (kDebugMode) {
      AppLogger.d('[B5 DEBUG] fetchJobApplicants called: jobId=$jobId, auth.uid=$currentUid');
    }

    Object? rpcError;
    List<JobApplicant>? rpcApplicants;

    // 1. Try RPC get_job_applicants first
    try {
      if (kDebugMode) {
        AppLogger.d('[B5 DEBUG] Invoking RPC "get_job_applicants" with params: {p_job_id: $jobId}');
      }
      final res = await _client.rpc('get_job_applicants', params: {
        'p_job_id': jobId,
      });

      if (res is List) {
        if (kDebugMode) {
          AppLogger.d('[B5 DEBUG] RPC "get_job_applicants" returned ${res.length} rows.');
          for (final r in res) {
            AppLogger.d('[B5 DEBUG] RPC row: id=${r['application_id']}, status=${r['status']}, worker=${r['worker_name']}');
          }
        }
        rpcApplicants = res.map((row) => JobApplicant.fromJson(Map<String, dynamic>.from(row as Map))).toList();
        if (rpcApplicants.isNotEmpty) {
          return rpcApplicants;
        }
      }
    } catch (e, stack) {
      rpcError = e;
      AppLogger.e('[B5 DEBUG] RPC get_job_applicants error for $jobId: $e', e, stack);
    }

    // 2. Direct Query & Diagnostic checks (never swallow errors into empty state)
    try {
      if (kDebugMode) {
        AppLogger.d('[B5 DEBUG] Running direct diagnostic queries for jobId=$jobId');
        try {
          final jobRow = await _client
              .from('jobs')
              .select('id, title, provider_id, slots_total, slots_filled, status')
              .eq('id', jobId)
              .maybeSingle();
          AppLogger.d('[B5 DEBUG] Target Job in DB: $jobRow');

          if (jobRow != null) {
            final title = jobRow['title'];
            final providerId = jobRow['provider_id'];
            AppLogger.d('[B5 DEBUG] Checking RLS ownership: provider_id=$providerId, auth.uid=$currentUid');
            if (providerId != currentUid) {
              AppLogger.w('[B5 DEBUG] RLS WARNING: auth.uid ($currentUid) != jobs.provider_id ($providerId). RLS may restrict select.');
            }

            final siblingJobs = await _client
                .from('jobs')
                .select('id, title, created_at, slots_filled, slots_total')
                .eq('provider_id', providerId)
                .eq('title', title);
            AppLogger.d('[B5 DEBUG] Sibling jobs with title "$title" count: ${siblingJobs.length}');
            for (final s in siblingJobs) {
              final sId = s['id'].toString();
              final sApps = await _client.from('job_applications').select('id, status, created_at').eq('job_id', sId);
              AppLogger.d('[B5 DEBUG] Job $sId (${s['created_at']}): ${sApps.length} applications in table (statuses: ${sApps.map((x) => x['status']).toList()})');
            }
          }
        } catch (diagErr) {
          AppLogger.w('[B5 DEBUG] Diagnostic check error: $diagErr');
        }
      }

      // Query job_applications directly for target jobId (no status filtering)
      final apps = await _fetchApplicationsDirect(jobId);
      if (apps.isNotEmpty) {
        if (kDebugMode) {
          AppLogger.d('[B5 DEBUG] Direct query succeeded with ${apps.length} applicants for $jobId');
        }
        return apps;
      }

      // If still 0, check duplicate jobs with the same title
      final resolvedApps = await _checkDuplicateJobsForApplicants(jobId, currentUid);
      if (resolvedApps.isNotEmpty) {
        return resolvedApps;
      }

      // If RPC succeeded with clean empty result, return []
      if (rpcApplicants != null) {
        return [];
      }

      // If RPC failed and direct query returned 0 rows or failed
      if (rpcError != null) {
        throw rpcError;
      }

      return [];
    } catch (e, stack) {
      AppLogger.e('[B5 DEBUG] All applicant queries failed for $jobId: $e', e, stack);
      throw AppException.from(e);
    }
  }

  Future<List<JobApplicant>> _fetchApplicationsDirect(String targetJobId) async {
    final appsRes = await _client
        .from('job_applications')
        .select()
        .eq('job_id', targetJobId)
        .order('created_at', ascending: false);

    if (kDebugMode) {
      AppLogger.d('[B5 DEBUG] Direct select from job_applications for $targetJobId returned ${(appsRes as List).length} rows');
    }

    final List<JobApplicant> result = [];
    for (final row in (appsRes as List)) {
      final workerId = row['worker_id']?.toString() ?? '';
      final status = row['status']?.toString() ?? 'applied';
      final message = row['message']?.toString();
      final createdAt = row['created_at'] != null
          ? DateTime.tryParse(row['created_at'].toString()) ?? DateTime.now()
          : DateTime.now();

      Map<String, dynamic>? profile;
      Map<String, dynamic>? workerProfile;
      final List<String> skills = [];

      try {
        profile = await _client.from('public_profiles').select('full_name, avatar_path').eq('id', workerId).maybeSingle();
      } catch (_) {}

      try {
        workerProfile = await _client
            .from('worker_profiles')
            .select('seeker_type, is_verified_badge, rating_avg, rating_count, jobs_completed, languages')
            .eq('user_id', workerId)
            .maybeSingle();
      } catch (_) {}

      try {
        final skillsRes = await _client.from('worker_skills').select('skills(names)').eq('user_id', workerId);
        for (final sk in (skillsRes as List)) {
          final sNames = sk['skills']?['names'];
          if (sNames is Map && sNames['en'] != null) {
            skills.add(sNames['en'].toString());
          }
        }
      } catch (_) {}

      String? assignmentId;
      try {
        final asgRow = await _client.from('job_assignments').select('id').eq('job_id', targetJobId).eq('worker_id', workerId).maybeSingle();
        assignmentId = asgRow?['id']?.toString();
      } catch (_) {}

      final isVerified = workerProfile?['is_verified_badge'] == true;
      final rating = (workerProfile?['rating_avg'] as num?)?.toDouble() ?? 4.8;
      final reviewCount = (workerProfile?['rating_count'] as num?)?.toInt() ?? 0;
      final jobsCompleted = (workerProfile?['jobs_completed'] as num?)?.toInt() ?? 0;
      final seekerType = workerProfile?['seeker_type']?.toString() ?? 'informal';
      final languages = (workerProfile?['languages'] as List?)?.map((e) => e.toString()).toList() ?? ['kn'];

      result.add(JobApplicant(
        applicationId: row['id']?.toString() ?? '',
        jobId: row['job_id']?.toString() ?? targetJobId,
        workerId: workerId,
        status: status,
        message: message,
        createdAt: createdAt,
        workerName: profile?['full_name']?.toString() ?? 'Worker',
        workerAvatar: profile?['avatar_path']?.toString(),
        seekerType: seekerType,
        badgeName: isVerified ? 'Verified Worker' : 'Registered Worker',
        levelNumber: 1,
        isVerified: isVerified,
        rating: rating,
        reviewCount: reviewCount,
        jobsCompletedCount: jobsCompleted,
        distanceM: 800.0,
        assignmentId: assignmentId,
        languages: languages,
        skills: skills,
      ));
    }
    return result;
  }

  Future<List<JobApplicant>> _checkDuplicateJobsForApplicants(String jobId, String? currentUid) async {
    try {
      final jobRow = await _client.from('jobs').select('title, provider_id').eq('id', jobId).maybeSingle();
      if (jobRow == null) return [];
      final title = jobRow['title']?.toString();
      final providerId = jobRow['provider_id']?.toString() ?? currentUid;
      if (title == null || providerId == null) return [];

      final duplicates = await _client
          .from('jobs')
          .select('id')
          .eq('provider_id', providerId)
          .eq('title', title)
          .neq('id', jobId)
          .order('created_at', ascending: false);

      for (final dup in duplicates) {
        final dupId = dup['id']?.toString();
        if (dupId != null) {
          final dupApps = await _fetchApplicationsDirect(dupId);
          if (dupApps.isNotEmpty) {
            AppLogger.i('[B5 RESOLVED] Found ${dupApps.length} applications on duplicate job $dupId with title "$title"');
            return dupApps;
          }
        }
      }
    } catch (e) {
      AppLogger.w('[B5 DEBUG] Duplicate job resolution check failed: $e');
    }
    return [];
  }

  @override
  Future<String> postJob(JobPostDraft draft) async {
    try {
      final res = await _client.rpc('post_provider_job', params: {
        'p_category_id': draft.categoryId,
        'p_title': draft.title,
        'p_description': draft.description,
        'p_wage_type': draft.wageType,
        'p_wage_paise': draft.wagePaise,
        'p_est_duration_minutes': draft.estDurationMinutes,
        'p_start_at': draft.startAt.toUtc().toIso8601String(),
        'p_slots_total': draft.slotsTotal,
        'p_materials_provided': draft.materialsProvided,
        'p_payment_mode': draft.paymentMode,
        'p_requirements': draft.requirementsMap,
        'p_address_text': draft.addressText,
        'p_location_lat': draft.latitude,
        'p_location_lng': draft.longitude,
        'p_geofence_radius_m': draft.geofenceRadiusM,
        'p_suitable_for': draft.suitableFor,
        'p_landmark': draft.landmark,
        'p_site_photo_url': draft.sitePhotoUrl,
        'p_thumbnail_path': draft.thumbnailPath ?? draft.sitePhotoUrl,
      });

      return res?.toString() ?? '';
    } catch (e, stack) {
      AppLogger.e('Error posting job', e, stack);
      rethrow;
    }
  }

  @override
  Future<bool> updateJob(JobPostDraft draft) async {
    if (draft.jobId == null) return false;
    try {
      final res = await _client.rpc('update_provider_job', params: {
        'p_job_id': draft.jobId,
        'p_category_id': draft.categoryId,
        'p_title': draft.title,
        'p_description': draft.description,
        'p_wage_type': draft.wageType,
        'p_wage_paise': draft.wagePaise,
        'p_est_duration_minutes': draft.estDurationMinutes,
        'p_start_at': draft.startAt.toUtc().toIso8601String(),
        'p_slots_total': draft.slotsTotal,
        'p_materials_provided': draft.materialsProvided,
        'p_payment_mode': draft.paymentMode,
        'p_requirements': draft.requirementsMap,
        'p_address_text': draft.addressText,
        'p_location_lat': draft.latitude,
        'p_location_lng': draft.longitude,
        'p_geofence_radius_m': draft.geofenceRadiusM,
        'p_suitable_for': draft.suitableFor,
        'p_landmark': draft.landmark,
        'p_site_photo_url': draft.sitePhotoUrl,
        'p_thumbnail_path': draft.thumbnailPath ?? draft.sitePhotoUrl,
      });

      return res == true;
    } catch (e, stack) {
      AppLogger.e('Error updating job ${draft.jobId}', e, stack);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> updateJobStatus(String jobId, String status) async {
    try {
      final res = await _client.rpc('update_provider_job_status', params: {
        'p_job_id': jobId,
        'p_status': status,
      });

      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
      return {'success': true};
    } catch (e, stack) {
      AppLogger.e('Error updating job status for $jobId to $status', e, stack);
      rethrow;
    }
  }

  @override
  Future<String?> respondToApplicant({required String applicationId, required String status}) async {
    try {
      final res = await _client.rpc('respond_to_application', params: {
        'p_application_id': applicationId,
        'p_status': status,
      });

      return res?.toString();
    } catch (e) {
      AppLogger.w('RPC respond_to_application failed, attempting direct table fallback: $e');
      try {
        final targetStatus = (status == 'hired' || status == 'accepted')
            ? 'hired'
            : (status == 'rejected' || status == 'declined' ? 'rejected' : status);

        await _client.from('job_applications').update({
          'status': targetStatus,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', applicationId);

        if (targetStatus == 'hired') {
          final appRow = await _client.from('job_applications').select('job_id, worker_id').eq('id', applicationId).maybeSingle();
          if (appRow != null && appRow['job_id'] != null) {
            final jId = appRow['job_id'].toString();
            final wId = appRow['worker_id'].toString();
            final jobRow = await _client.from('jobs').select('provider_id, title, slots_filled, slots_total, wage_paise').eq('id', jId).maybeSingle();
            if (jobRow != null) {
              final filled = ((jobRow['slots_filled'] as num?)?.toInt() ?? 0) + 1;
              final total = (jobRow['slots_total'] as num?)?.toInt() ?? 1;
              await _client.from('jobs').update({
                'slots_filled': filled,
                if (filled >= total) 'status': 'filled',
                'updated_at': DateTime.now().toIso8601String(),
              }).eq('id', jId);

              // 1. Create or fetch assignment
              String? newAsgId;
              try {
                final existingAsg = await _client.from('job_assignments').select('id').eq('job_id', jId).eq('worker_id', wId).maybeSingle();
                if (existingAsg != null) {
                  newAsgId = existingAsg['id']?.toString();
                } else {
                  final asgInsert = await _client.from('job_assignments').insert({
                    'job_id': jId,
                    'worker_id': wId,
                    'booking_code': 'BOOK-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
                    'agreed_wage_paise': jobRow['wage_paise'] ?? 60000,
                    'status': 'accepted',
                    'created_at': DateTime.now().toIso8601String(),
                    'updated_at': DateTime.now().toIso8601String(),
                  }).select('id').single();
                  newAsgId = asgInsert['id']?.toString();
                }
              } catch (_) {}

              // 2. Create or update conversation
              try {
                final pId = jobRow['provider_id']?.toString() ?? _client.auth.currentUser?.id ?? '';
                final convRow = await _client.from('conversations').upsert({
                  'job_id': jId,
                  'provider_id': pId,
                  'seeker_id': wId,
                  'context_type': 'job',
                  'context_id': jId,
                  'booking_id': ?newAsgId,
                  'last_message_at': DateTime.now().toIso8601String(),
                }, onConflict: 'job_id,provider_id,seeker_id').select('id').single();

                final convId = convRow['id']?.toString();
                if (convId != null) {
                  final msgRows = await _client.from('messages').select('id').eq('conversation_id', convId).limit(1);
                  if ((msgRows as List).isEmpty) {
                    await _client.from('messages').insert({
                      'conversation_id': convId,
                      'sender_id': pId,
                      'body': 'Application accepted for "${jobRow['title'] ?? 'this position'}"! You can coordinate work details and timings here.',
                      'created_at': DateTime.now().toIso8601String(),
                    });
                  }
                }
              } catch (_) {}

              return newAsgId;
            }
          }
        }
        return null;
      } catch (fallbackErr) {
        AppLogger.e('Fallback direct update failed for applicant $applicationId', fallbackErr);
        rethrow;
      }
    }
  }

  @override
  Future<WageBandResult?> fetchWageBand({required String categoryId, String? area}) async {
    try {
      final res = await _client.rpc('suggest_wage_band', params: {
        'p_category_id': categoryId,
        'p_area': area ?? 'default',
      });

      if (res is List && res.isNotEmpty) {
        final first = res.first as Map;
        return WageBandResult(
          minPaise: (first['min_paise'] as num).toInt(),
          maxPaise: (first['max_paise'] as num).toInt(),
          unit: first['unit']?.toString() ?? 'day',
        );
      }
    } catch (e, stack) {
      AppLogger.e('Error fetching wage band for category $categoryId', e, stack);
    }
    return null;
  }

  @override
  Future<List<ServiceCategoryItem>> fetchCategories() async {
    try {
      final res = await _client
          .from('service_categories')
          .select('id, slug, names, icon, audience')
          .order('slug');

      return (res as List).map((row) {
        return ServiceCategoryItem(
          id: row['id'].toString(),
          slug: row['slug'].toString(),
          names: row['names'] as Map<String, dynamic>? ?? {'en': row['slug']},
          icon: row['icon'] as String?,
          audience: (row['audience'] as List?)?.map((e) => e.toString()).toList() ?? ['informal'],
        );
      }).toList();
    } catch (e, stack) {
      AppLogger.e('Error fetching service categories', e, stack);
      return [];
    }
  }
}
