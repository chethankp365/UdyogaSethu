import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/features/seeker/domain/job_recommendation.dart';

abstract class SeekerHomeRepository {
  Future<List<JobRecommendation>> fetchRecommendations({
    required String workerId,
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

  @override
  Future<List<JobRecommendation>> fetchRecommendations({
    required String workerId,
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

      if (response is List) {
        return response
            .map((item) => JobRecommendation.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return [];
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
      await _supabase.from('job_applications').upsert({
        'job_id': jobId,
        'worker_id': workerId,
        'status': 'applied',
      }, onConflict: 'job_id,worker_id');
      return true;
    } catch (e, stack) {
      AppLogger.e('Failed to apply to job $jobId: $e', e, stack);
      return false;
    }
  }
}

final seekerHomeRepositoryProvider = Provider<SeekerHomeRepository>((ref) {
  return SupabaseSeekerHomeRepository(Supabase.instance.client);
});
