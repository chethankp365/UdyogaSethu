import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/features/provider/domain/job_applicant.dart';
import 'package:udyogasethu/features/provider/domain/job_post_draft.dart';
import 'package:udyogasethu/features/provider/domain/provider_job.dart';
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

      if (res is List) {
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

          return (queryRes as List).map((row) {
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
              createdAt: row['created_at'] != null
                  ? DateTime.tryParse(row['created_at'].toString()) ?? DateTime.now()
                  : DateTime.now(),
            );
          }).toList();
        }
      } catch (fallbackErr) {
        AppLogger.e('Fallback jobs query also failed', fallbackErr);
      }
    }
    return [];
  }

  @override
  Future<List<JobApplicant>> fetchJobApplicants(String jobId) async {
    try {
      final res = await _client.rpc('get_job_applicants', params: {
        'p_job_id': jobId,
      });

      if (res is List) {
        return res.map((row) => JobApplicant.fromJson(Map<String, dynamic>.from(row as Map))).toList();
      }
    } catch (e, stack) {
      AppLogger.e('Error fetching job applicants for $jobId', e, stack);
      // Fallback: direct query
      try {
        final res = await _client
            .from('job_applications')
            .select('*, profiles!worker_id(full_name, avatar_path)')
            .eq('job_id', jobId)
            .order('created_at', ascending: false);

        return (res as List).map((row) {
          final p = row['profiles'] as Map<String, dynamic>?;
          return JobApplicant(
            applicationId: row['id']?.toString() ?? '',
            jobId: row['job_id']?.toString() ?? '',
            workerId: row['worker_id']?.toString() ?? '',
            status: row['status']?.toString() ?? 'applied',
            message: row['message']?.toString(),
            createdAt: row['created_at'] != null
                ? DateTime.tryParse(row['created_at'].toString()) ?? DateTime.now()
                : DateTime.now(),
            workerName: p?['full_name']?.toString() ?? 'Worker',
            workerAvatar: p?['avatar_path']?.toString(),
            isVerified: false,
            rating: 4.8,
            reviewCount: 0,
          );
        }).toList();
      } catch (fallbackErr) {
        AppLogger.e('Fallback applicants query also failed', fallbackErr);
      }
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
        'p_start_at': draft.startAt.toIso8601String(),
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
        'p_start_at': draft.startAt.toIso8601String(),
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
    } catch (e, stack) {
      AppLogger.e('Error responding to applicant $applicationId with $status', e, stack);
      rethrow;
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
