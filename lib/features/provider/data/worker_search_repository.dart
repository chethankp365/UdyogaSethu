import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_profile_draft.dart';
import 'package:udyogasethu/features/provider/domain/nearby_worker.dart';
import 'package:udyogasethu/features/provider/domain/provider_active_booking.dart';
import 'package:udyogasethu/features/provider/domain/worker_detail_profile.dart';
import 'package:udyogasethu/features/provider/domain/worker_filter_criteria.dart';

abstract class WorkerSearchRepository {
  Future<List<NearbyWorker>> searchNearbyWorkers({
    required double lat,
    required double lng,
    required WorkerFilterCriteria criteria,
  });

  Future<WorkerDetailProfile> getWorkerProfileDetail(
    String workerId, {
    double? callerLat,
    double? callerLng,
  });

  Future<ProviderActiveBooking?> getActiveBooking({String? providerId});

  Future<bool> toggleFavourite(String targetId);

  Future<List<ServiceCategoryItem>> getCategories();
}

class SupabaseWorkerSearchRepository implements WorkerSearchRepository {
  final SupabaseClient? client;

  SupabaseWorkerSearchRepository({this.client});

  SupabaseClient? get _safeClient {
    if (client != null) return client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<NearbyWorker>> searchNearbyWorkers({
    required double lat,
    required double lng,
    required WorkerFilterCriteria criteria,
  }) async {
    final client = _safeClient;
    if (client == null) {
      return _filterFallbackWorkers(lat, lng, criteria);
    }

    try {
      final res = await client.rpc('nearby_workers', params: {
        'p_lat': lat,
        'p_lng': lng,
        'p_radius_m': criteria.radiusKm * 1000,
        if (criteria.categoryId != null && criteria.categoryId!.isNotEmpty)
          'p_category_id': criteria.categoryId,
        if (criteria.language != null && criteria.language!.isNotEmpty && criteria.language != 'all')
          'p_language': criteria.language,
        if (criteria.availability != null && criteria.availability!.isNotEmpty && criteria.availability != 'all')
          'p_availability': criteria.availability,
        if (criteria.minRatePaise != null) 'p_min_rate_paise': criteria.minRatePaise,
        if (criteria.maxRatePaise != null) 'p_max_rate_paise': criteria.maxRatePaise,
        if (criteria.genderPreference != null && criteria.genderPreference!.isNotEmpty && criteria.genderPreference != 'any')
          'p_gender': criteria.genderPreference,
        if (criteria.minRating != null) 'p_min_rating': criteria.minRating,
        if (criteria.minJobsCompleted != null) 'p_min_jobs_completed': criteria.minJobsCompleted,
        'p_verified_only': criteria.verifiedOnly,
        if (criteria.searchQuery != null && criteria.searchQuery!.trim().isNotEmpty)
          'p_search_query': criteria.searchQuery!.trim(),
        'p_limit': 50,
        'p_offset': 0,
      });

      if (res is List) {
        return res.map((item) => NearbyWorker.fromJson(Map<String, dynamic>.from(item as Map))).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WorkerSearchRepository] Error calling nearby_workers RPC: $e. Using fallback.');
      }
      return _filterFallbackWorkers(lat, lng, criteria);
    }
  }

  @override
  Future<WorkerDetailProfile> getWorkerProfileDetail(
    String workerId, {
    double? callerLat,
    double? callerLng,
  }) async {
    final client = _safeClient;
    if (client == null) {
      return _fallbackWorkerDetail(workerId);
    }

    try {
      final params = <String, dynamic>{'p_worker_id': workerId};
      if (callerLat != null) params['p_caller_lat'] = callerLat;
      if (callerLng != null) params['p_caller_lng'] = callerLng;
      final res = await client.rpc('get_worker_profile_detail', params: params);

      if (res is Map) {
        return WorkerDetailProfile.fromJson(Map<String, dynamic>.from(res));
      }
      return _fallbackWorkerDetail(workerId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WorkerSearchRepository] Error fetching profile detail: $e');
      }
      return _fallbackWorkerDetail(workerId);
    }
  }

  @override
  Future<ProviderActiveBooking?> getActiveBooking({String? providerId}) async {
    final client = _safeClient;
    if (client == null) {
      return null;
    }

    try {
      final params = <String, dynamic>{};
      if (providerId != null) params['p_provider_id'] = providerId;
      final res = await client.rpc('get_provider_active_booking', params: params);

      if (res is Map && res.isNotEmpty) {
        return ProviderActiveBooking.fromJson(Map<String, dynamic>.from(res));
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WorkerSearchRepository] Error fetching active booking: $e');
      }
      return null;
    }
  }

  @override
  Future<bool> toggleFavourite(String targetId) async {
    final client = _safeClient;
    if (client == null) return true;

    try {
      final res = await client.rpc('toggle_favourite', params: {
        'p_target_id': targetId,
      });
      return res == true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WorkerSearchRepository] Error toggling favourite: $e');
      }
      return false;
    }
  }

  @override
  Future<List<ServiceCategoryItem>> getCategories() async {
    final client = _safeClient;
    if (client == null) return _sampleCategories();

    try {
      final res = await client
          .from('service_categories')
          .select('id, slug, names, icon')
          .order('sort', ascending: true);

      if (res.isNotEmpty) {
        return res.map((row) {
          final m = Map<String, dynamic>.from(row as Map);
          final rawNames = m['names'];
          Map<String, String> namesMap = {};
          if (rawNames is Map) {
            namesMap = rawNames.map((k, v) => MapEntry(k.toString(), v.toString()));
          }
          return ServiceCategoryItem(
            id: m['id']?.toString() ?? '',
            slug: m['slug']?.toString() ?? '',
            names: namesMap,
            icon: m['icon']?.toString(),
          );
        }).toList();
      }
    } catch (_) {}
    return _sampleCategories();
  }

  // --- Fallbacks for Offline & Unit Tests ---

  static List<ServiceCategoryItem> _sampleCategories() {
    return const [
      ServiceCategoryItem(
        id: 'cat-elec',
        slug: 'electrician',
        names: {'en': 'Electrician', 'kn': 'ಎಲೆಕ್ಟ್ರಿಷಿಯನ್', 'hi': 'इलेक्ट्रिशियन'},
        icon: 'electrical_services',
      ),
      ServiceCategoryItem(
        id: 'cat-const',
        slug: 'construction',
        names: {'en': 'Construction Helper', 'kn': 'ಕಟ್ಟಡ ಸಹಾಯಕ', 'hi': 'निर्माण'},
        icon: 'construction',
      ),
      ServiceCategoryItem(
        id: 'cat-plumb',
        slug: 'plumbing',
        names: {'en': 'Plumbing', 'kn': 'ಪ್ಲಂಬಿಂಗ್', 'hi': 'प्लंबिंग'},
        icon: 'plumbing',
      ),
      ServiceCategoryItem(
        id: 'cat-paint',
        slug: 'painting',
        names: {'en': 'Painting', 'kn': 'ಪೇಂಟಿಂಗ್', 'hi': 'पेंटिंग'},
        icon: 'format_paint',
      ),
    ];
  }

  static List<NearbyWorker> _fallbackWorkers() {
    return [
      const NearbyWorker(
        userId: 'worker-101',
        fullName: 'Ramesh Kumar',
        headline: 'Electrician & Wireman',
        bio: '10+ years experience in commercial conduit and wiring.',
        dailyRatePaise: 88000,
        hourlyRatePaise: 12000,
        ratingAvg: 4.9,
        ratingCount: 18,
        jobsCompleted: 18,
        isVerifiedBadge: true,
        distanceM: 800,
        lat: 12.9352,
        lng: 77.6245,
        languages: ['kn', 'en'],
        availability: 'available',
        gender: 'male',
        experienceYears: 10.0,
        skills: [
          WorkerSkillItem(id: 's1', name: 'Wiring Installation', categoryName: 'Electrician'),
          WorkerSkillItem(id: 's2', name: 'Circuit Breakers', categoryName: 'Electrician'),
        ],
      ),
      const NearbyWorker(
        userId: 'worker-102',
        fullName: 'Sunita Devi',
        headline: 'Housekeeping & Domestic Helper',
        bio: 'Punctual, thorough domestic helper trusted by Jayanagar families.',
        dailyRatePaise: 75000,
        hourlyRatePaise: 10000,
        ratingAvg: 4.8,
        ratingCount: 12,
        jobsCompleted: 12,
        isVerifiedBadge: false, // Unverified
        distanceM: 3500,
        lat: 12.9250,
        lng: 77.5938,
        languages: ['hi'],
        availability: 'available',
        gender: 'female',
        experienceYears: 6.0,
        skills: [
          WorkerSkillItem(id: 's3', name: 'Home Deep Cleaning', categoryName: 'Cleaner'),
        ],
      ),
      const NearbyWorker(
        userId: 'worker-103',
        fullName: 'Manjunath B',
        headline: 'Construction Helper & Masonry',
        bio: 'Reliable site loader and material assistant for HSR construction sites.',
        dailyRatePaise: 70000,
        hourlyRatePaise: 9000,
        ratingAvg: 4.6,
        ratingCount: 5,
        jobsCompleted: 5,
        isVerifiedBadge: false, // Unverified
        distanceM: 3300,
        lat: 12.9121,
        lng: 77.6446,
        languages: ['kn'],
        availability: 'available',
        gender: 'male',
        experienceYears: 3.0,
        skills: [
          WorkerSkillItem(id: 's4', name: 'Concrete Mixing', categoryName: 'Construction Helper'),
        ],
      ),
      const NearbyWorker(
        userId: 'worker-104',
        fullName: 'Sai Electricals Crew',
        headline: 'Master Electrician',
        bio: 'Certified industrial electric repairs and emergency wiring.',
        dailyRatePaise: 95000,
        hourlyRatePaise: 14000,
        ratingAvg: 4.9,
        ratingCount: 24,
        jobsCompleted: 24,
        isVerifiedBadge: true,
        distanceM: 1900,
        lat: 12.9300,
        lng: 77.6300,
        languages: ['kn', 'hi', 'en'],
        availability: 'available',
        gender: 'male',
        experienceYears: 8.0,
        skills: [
          WorkerSkillItem(id: 's5', name: 'Three-Phase Wiring', categoryName: 'Electrician'),
        ],
      ),
    ];
  }

  List<NearbyWorker> _filterFallbackWorkers(double lat, double lng, WorkerFilterCriteria criteria) {
    return _fallbackWorkers().where((w) {
      if (criteria.verifiedOnly && !w.isVerifiedBadge) return false;
      if (criteria.radiusKm > 0 && w.distanceM != null && w.distanceM! > criteria.radiusKm * 1000) return false;
      if (criteria.language != null && criteria.language!.isNotEmpty && criteria.language != 'all') {
        if (!w.speaksLanguage(criteria.language!)) return false;
      }
      if (criteria.availability != null && criteria.availability!.isNotEmpty && criteria.availability != 'all') {
        if (w.availability != criteria.availability) return false;
      }
      if (criteria.genderPreference != null && criteria.genderPreference!.isNotEmpty && criteria.genderPreference != 'any') {
        if (w.gender != criteria.genderPreference) return false;
      }
      if (criteria.minRating != null && w.ratingAvg < criteria.minRating!) return false;
      if (criteria.minJobsCompleted != null && w.jobsCompleted < criteria.minJobsCompleted!) return false;
      if (criteria.minRatePaise != null && (w.dailyRatePaise ?? 0) < criteria.minRatePaise!) return false;
      if (criteria.maxRatePaise != null && (w.dailyRatePaise ?? 99999999) > criteria.maxRatePaise!) return false;
      if (criteria.searchQuery != null && criteria.searchQuery!.trim().isNotEmpty) {
        final q = criteria.searchQuery!.toLowerCase();
        final match = w.fullName.toLowerCase().contains(q) ||
            w.headline.toLowerCase().contains(q) ||
            w.bio.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  static WorkerDetailProfile _fallbackWorkerDetail(String workerId) {
    return WorkerDetailProfile(
      userId: workerId,
      fullName: 'Ramesh Kumar',
      phone: '+91 99000 00101',
      avatarPath: null,
      headline: 'Certified Electrician & Wireman',
      bio: 'Over 10 years of reliable electrical installation, maintenance, and domestic repairs across Koramangala and HSR Layout. Known for punctuality, quality workmanship, and safety.',
      experienceYears: 10.0,
      dailyRatePaise: 88000,
      hourlyRatePaise: 12000,
      languages: const ['kn', 'en', 'hi'],
      serviceRadiusKm: 12.0,
      availability: 'available',
      ratingAvg: 4.9,
      ratingCount: 18,
      jobsCompleted: 18,
      isVerifiedBadge: true,
      gender: 'male',
      distanceM: 800,
      lat: 12.9352,
      lng: 77.6245,
      skills: const [
        WorkerSkillItem(id: 's1', name: 'Wiring Installation', categoryName: 'Electrician'),
        WorkerSkillItem(id: 's2', name: 'Circuit Breakers', categoryName: 'Electrician'),
        WorkerSkillItem(id: 's3', name: 'Inverter Backup Setup', categoryName: 'Electrician'),
      ],
      trustBadges: const [
        TrustBadgeItem(code: 'aadhaar', title: '100% Aadhaar Verified', verified: true),
        TrustBadgeItem(code: 'face', title: 'Liveness Face Biometrics', verified: true),
        TrustBadgeItem(code: 'dl', title: 'Driving Licence (LMV)', verified: true),
        TrustBadgeItem(code: 'experience', title: '18 Completed Jobs', verified: true),
      ],
      reviews: const [
        WorkerReviewItem(
          id: 'rev-1',
          raterName: 'Sharma Builders & Contractors',
          stars: 5,
          comment: 'Excellent and punctual worker. Completed commercial conduit wiring with zero rework.',
          createdAt: '2 days ago',
        ),
        WorkerReviewItem(
          id: 'rev-2',
          raterName: 'Reddy Villa Household',
          stars: 5,
          comment: 'Fixed all electrical earthing and main switch issues quickly. Very respectful.',
          createdAt: '1 week ago',
        ),
      ],
      isFavourite: false,
    );
  }
}

final workerSearchRepositoryProvider = Provider<WorkerSearchRepository>((ref) {
  return SupabaseWorkerSearchRepository();
});
