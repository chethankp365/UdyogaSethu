import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/features/seeker/domain/job_recommendation.dart';

abstract class SeekerHomeRepository {
  Future<List<JobRecommendation>> fetchRecommendations({
    required String workerId,
    required String seekerType,
    double? lat,
    double? lng,
    double radiusM = 50000,
    int limit = 20,
  });

  Future<SeekerHomeSummary> fetchHomeSummary(String workerId);

  Future<SponsoredAdBanner?> fetchSponsoredBanner({String targetRole = 'seeker'});

  Future<bool> applyToJob({required String jobId, required String workerId});
}

class SupabaseSeekerHomeRepository implements SeekerHomeRepository {
  final SupabaseClient _supabase;

  SupabaseSeekerHomeRepository(this._supabase);

  static const Set<String> studentCategorySlugs = {
    'content-writing',
    'design-data-work',
    'tutoring-academics',
    'campus-brand-promotion',
    'retail-food-service',
    'delivery-gig-work',
  };

  static const Set<String> tradeCategorySlugs = {
    'electrician',
    'plumber',
    'carpenter',
    'mason',
    'construction',
    'painting',
    'loader',
    'cleaner',
    'driver',
    'domestic_help',
    'agri_labour',
  };

  @override
  Future<List<JobRecommendation>> fetchRecommendations({
    required String workerId,
    required String seekerType,
    double? lat,
    double? lng,
    double radiusM = 50000,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase.rpc(
        'recommended_jobs',
        params: {
          'p_worker_id': workerId,
          'p_lat': lat,
          'p_lng': lng,
          'p_limit': limit,
          'p_radius_m': radiusM,
        },
      );

      final List<JobRecommendation> rawList = [];
      if (response is List) {
        for (final item in response) {
          if (item is Map) {
            rawList.add(JobRecommendation.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }

      final isStudentOrPartTime = seekerType == 'student' || seekerType == 'part_time';

      final now = DateTime.now();
      final filteredList = rawList.where((job) {
        if (job.startAt != null && job.startAt!.isBefore(now)) return false;
        if (job.slotsTotal > 0 && job.slotsFilled >= job.slotsTotal) return false;
        if (isStudentOrPartTime) {
          if (tradeCategorySlugs.contains(job.categorySlug) && !job.isStudentFriendly) return false;
          return studentCategorySlugs.contains(job.categorySlug) || job.isStudentFriendly;
        } else {
          if (studentCategorySlugs.contains(job.categorySlug) && !job.isStudentFriendly) return false;
          return true;
        }
      }).toList();

      if (kDebugMode) {
        debugPrint('[DEBUG SeekerFeed] RPC called: recommended_jobs(workerId: $workerId, lat: $lat, lng: $lng, radiusM: $radiusM)');
        debugPrint('[DEBUG SeekerFeed] Seeker type: $seekerType');
        debugPrint('[DEBUG SeekerFeed] Target audience filter: ${isStudentOrPartTime ? "[student, part_time]" : "[informal]"}');
        debugPrint('[DEBUG SeekerFeed] Jobs returned before filter: ${rawList.length}');
        debugPrint('[DEBUG SeekerFeed] Jobs returned after filter: ${filteredList.length}');
      }

      return filteredList;
    } catch (e, stack) {
      AppLogger.e('Failed to fetch recommended_jobs: $e', e, stack);
      rethrow;
    }
  }

  @override
  Future<SeekerHomeSummary> fetchHomeSummary(String workerId) async {
    try {
      final response = await _supabase.rpc(
        'get_seeker_home_summary',
        params: {'p_worker_id': workerId},
      );

      if (response != null && response is Map) {
        return SeekerHomeSummary.fromJson(Map<String, dynamic>.from(response));
      }
      return const SeekerHomeSummary();
    } catch (e, stack) {
      AppLogger.e('Failed to fetch seeker home summary: $e', e, stack);
      return const SeekerHomeSummary();
    }
  }

  @override
  Future<SponsoredAdBanner?> fetchSponsoredBanner({String targetRole = 'seeker'}) async {
    try {
      final response = await _supabase
          .from('ad_banners')
          .select()
          .eq('active', true)
          .eq('target_role', targetRole)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return SponsoredAdBanner.fromJson(response);
      }
      return null;
    } catch (e, stack) {
      AppLogger.e('Failed to fetch sponsored ad banner: $e', e, stack);
      return null;
    }
  }

  @override
  Future<bool> applyToJob({required String jobId, required String workerId}) async {
    try {
      final response = await _supabase.rpc(
        'apply_to_job',
        params: {'p_job_id': jobId},
      );
      return response != null;
    } on PostgrestException catch (e, stack) {
      AppLogger.e('RPC apply_to_job error: ${e.message} (code: ${e.code})', e, stack);
      rethrow;
    } catch (e, stack) {
      AppLogger.e('Failed to apply to job $jobId: $e', e, stack);
      rethrow;
    }
  }
}

final seekerHomeRepositoryProvider = Provider<SeekerHomeRepository>((ref) {
  return SupabaseSeekerHomeRepository(Supabase.instance.client);
});
