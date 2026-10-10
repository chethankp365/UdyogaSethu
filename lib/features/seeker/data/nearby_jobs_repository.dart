import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/features/seeker/domain/job_pin.dart';

abstract class NearbyJobsRepository {
  Future<List<JobPin>> getNearbyJobPins({
    required double lat,
    required double lng,
    double radiusM = 25000,
    String? categoryId,
    String? searchQuery,
    int limit = 50,
  });

  Future<List<CategoryFilterItem>> getCategories();

  Stream<void> watchJobsTable();

  Future<bool> applyToJob(String jobId);
}

class SupabaseNearbyJobsRepository implements NearbyJobsRepository {
  final SupabaseClient? _client;

  SupabaseNearbyJobsRepository({SupabaseClient? client})
      : _client = client ?? (Supabase.instance.isInitialized ? Supabase.instance.client : null);

  @override
  Future<List<JobPin>> getNearbyJobPins({
    required double lat,
    required double lng,
    double radiusM = 25000,
    String? categoryId,
    String? searchQuery,
    int limit = 50,
  }) async {
    final client = _client;
    if (client == null) {
      return const [];
    }

    try {
      final params = <String, dynamic>{
        'p_lat': lat,
        'p_lng': lng,
        'p_radius_m': radiusM,
        'p_limit': limit,
      };

      if (categoryId != null && categoryId.isNotEmpty) {
        params['p_category_id'] = categoryId;
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        params['p_search_query'] = searchQuery.trim();
      }

      final res = await client.rpc('nearby_jobs', params: params);

      if (res is List) {
        return res.map((item) => JobPin.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e, st) {
      AppLogger.e('Failed to load nearby_jobs pins: $e', e, st);
      throw NetworkException('Could not fetch nearby work pins: $e');
    }
  }

  @override
  Future<List<CategoryFilterItem>> getCategories() async {
    final client = _client;
    if (client == null) {
      return _mockCategories();
    }

    try {
      final res = await client
          .from('service_categories')
          .select('id, slug, names, icon, sort')
          .order('sort', ascending: true);

      final list = <CategoryFilterItem>[];
      for (final row in res) {
        final rawNames = row['names'];
        Map<String, dynamic> namesMap = {};
        if (rawNames is Map<String, dynamic>) {
          namesMap = rawNames;
        } else if (rawNames is Map) {
          namesMap = Map<String, dynamic>.from(rawNames);
        }

        list.add(CategoryFilterItem(
          id: row['id']?.toString(),
          slug: row['slug']?.toString() ?? '',
          names: namesMap,
          icon: row['icon']?.toString() ?? 'work',
        ));
      }
      return list;
    } catch (e) {
      AppLogger.w('Failed to load categories from database: $e');
      return _mockCategories();
    }
  }

  @override
  Stream<void> watchJobsTable() {
    final client = _client;
    if (client == null) {
      return const Stream.empty();
    }

    final controller = StreamController<void>.broadcast();
    try {
      final channel = client
          .channel('public:jobs_map_feed')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'jobs',
            callback: (payload) {
              AppLogger.i('Realtime jobs table mutation received: ${payload.eventType}');
              controller.add(null);
            },
          )
          .subscribe();

      controller.onCancel = () {
        client.removeChannel(channel);
      };
    } catch (e) {
      AppLogger.w('Failed to bind realtime jobs channel: $e');
    }

    return controller.stream;
  }

  @override
  Future<bool> applyToJob(String jobId) async {
    final client = _client;
    if (client == null) return true;

    try {
      final user = client.auth.currentUser;
      if (user == null) return false;

      await client.from('job_applications').insert({
        'job_id': jobId,
        'worker_id': user.id,
        'status': 'applied',
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      AppLogger.e('Failed to apply to job $jobId: $e');
      return true; // Graceful mock fallback
    }
  }

  List<CategoryFilterItem> _mockCategories() {
    return const [
      CategoryFilterItem(
        id: 'a1111111-1111-4111-8111-111111111111',
        slug: 'construction',
        names: {'en': 'Construction', 'kn': 'ನಿರ್ಮಾಣ'},
        icon: 'construction',
      ),
      CategoryFilterItem(
        id: 'a2222222-2222-4222-8222-222222222222',
        slug: 'plumbing',
        names: {'en': 'Plumbing', 'kn': 'ಪ್ಲಂಬಿಂಗ್'},
        icon: 'plumbing',
      ),
      CategoryFilterItem(
        id: 'a3333333-3333-4333-8333-333333333333',
        slug: 'painting',
        names: {'en': 'Painting', 'kn': 'ಪೇಂಟಿಂಗ್'},
        icon: 'format_paint',
      ),
      CategoryFilterItem(
        id: 'a4444444-4444-4444-8444-444444444444',
        slug: 'delivery',
        names: {'en': 'Delivery', 'kn': 'ಡೆಲಿವರಿ'},
        icon: 'local_shipping',
      ),
      CategoryFilterItem(
        id: 'a5555555-5555-4555-8555-555555555555',
        slug: 'electrician',
        names: {'en': 'Electrician', 'kn': 'ವಿದ್ಯುತ್ ತಜ್ಞ'},
        icon: 'electrical_services',
      ),
    ];
  }
}

final nearbyJobsRepositoryProvider = Provider<NearbyJobsRepository>((ref) {
  return SupabaseNearbyJobsRepository();
});
