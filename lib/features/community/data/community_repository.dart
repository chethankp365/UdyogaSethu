import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/features/community/domain/community_models.dart';

abstract class CommunityRepository {
  Future<List<CommunityPost>> getCommunityPosts({String? kind});
  Future<LocalityTrustIndex> getLocalityTrustIndex();
  Future<List<TrainingEvent>> getTrainingEvents();
  Future<Map<String, dynamic>> registerForTrainingEvent(String eventId);
  Future<List<LearningModule>> getLearningModules();
  Future<LearningModule?> getLearningModuleById(String id);
  Future<Map<String, dynamic>> submitLearningQuiz({
    required String moduleId,
    required int score,
  });
  Future<Map<String, dynamic>> uploadExternalCertificate({
    required String kind,
    required String title,
    required String issuingOrg,
    required String certificatePath,
  });
  Future<List<MicroCredential>> getUserCredentials([String? userId]);
}

class SupabaseCommunityRepository implements CommunityRepository {
  final SupabaseClient _client;

  SupabaseCommunityRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String? get _currentUserId {
    try {
      return _client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<CommunityPost>> getCommunityPosts({String? kind}) async {
    try {
      var query = _client
          .from('community_posts')
          .select('*, profiles(full_name, avatar_path, role)')
          .eq('published', true);

      if (kind != null && kind.isNotEmpty) {
        query = query.eq('kind', kind);
      }

      final res = await query.order('created_at', ascending: false);
      final list = (res as List<dynamic>)
          .map((p) => CommunityPost.fromJson(p as Map<String, dynamic>))
          .toList();

      if (list.isNotEmpty) return list;
    } catch (_) {}

    // Curated initial seed posts if table has no entries
    return [
      CommunityPost(
        id: 'seed-hero-1',
        authorId: 'author-1',
        authorName: 'Ramesh Gowda',
        authorRole: 'Trusted Pro Farmer',
        kind: 'hero',
        title: 'Delivered 500kg Organic Tomatoes Directly with Zero Middlemen',
        body:
            'Using UdyogaSethu escrow and direct consumer booking, received payment within 2 hours of delivery. Honest fair pricing works!',
        images: const ['assets/images/produce/tomatoes.png'],
        locality: 'Mandya Hub',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      CommunityPost(
        id: 'seed-hero-2',
        authorId: 'author-2',
        authorName: 'Sunita Devi',
        authorRole: 'Certified Electrician',
        kind: 'story',
        title: 'Earned Always On-Time Badge & 50+ 5-Star Reviews',
        body:
            'Arriving early and completing safety checklists gave me priority access to high-value commercial repair bookings across Bengaluru.',
        images: const [],
        locality: 'Koramangala, Bengaluru',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      CommunityPost(
        id: 'seed-hero-3',
        authorId: 'author-3',
        authorName: 'Manjunath K',
        authorRole: 'Community Mentor',
        kind: 'tip',
        title: 'Daily Safety Checklist Habit Keeps Everyone Safe',
        body:
            'Always inspect cables, verify two-step geofence check-in, and use in-app emergency SOS if weather turns severe.',
        images: const [],
        locality: 'Dairy Circle Hub',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  @override
  Future<LocalityTrustIndex> getLocalityTrustIndex() async {
    return LocalityTrustIndex.mockDefault();
  }

  @override
  Future<List<TrainingEvent>> getTrainingEvents() async {
    final uid = _currentUserId;
    try {
      final eventsRes = await _client
          .from('training_events')
          .select()
          .order('starts_at', ascending: true);

      List<String> registeredEventIds = [];
      if (uid != null) {
        try {
          final regRes = await _client
              .from('event_registrations')
              .select('event_id')
              .eq('user_id', uid)
              .eq('status', 'registered');
          registeredEventIds = (regRes as List<dynamic>)
              .map((r) => r['event_id'].toString())
              .toList();
        } catch (_) {}
      }

      return (eventsRes as List<dynamic>).map((e) {
        final map = e as Map<String, dynamic>;
        final isReg = registeredEventIds.contains(map['id'].toString());
        return TrainingEvent.fromJson(map, isRegistered: isReg);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> registerForTrainingEvent(String eventId) async {
    try {
      final res = await _client.rpc('register_for_training_event', params: {
        'p_event_id': eventId,
      });

      if (res is Map<String, dynamic>) {
        return res;
      }
      return {'success': true};
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<LearningModule>> getLearningModules() async {
    final uid = _currentUserId;
    try {
      final modulesRes = await _client
          .from('learning_modules')
          .select()
          .order('created_at', ascending: true);

      Map<String, Map<String, dynamic>> progressMap = {};
      if (uid != null) {
        try {
          final progRes = await _client
              .from('learning_progress')
              .select('module_id, score, completed')
              .eq('user_id', uid);
          for (final row in (progRes as List<dynamic>)) {
            final m = row as Map<String, dynamic>;
            progressMap[m['module_id'].toString()] = m;
          }
        } catch (_) {}
      }

      return (modulesRes as List<dynamic>).map((m) {
        final map = m as Map<String, dynamic>;
        final prog = progressMap[map['id'].toString()];
        final isCompleted = prog?['completed'] == true;
        final score = (prog?['score'] as num?)?.toInt();
        return LearningModule.fromJson(map, isCompleted: isCompleted, score: score);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<LearningModule?> getLearningModuleById(String id) async {
    final modules = await getLearningModules();
    try {
      return modules.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> submitLearningQuiz({
    required String moduleId,
    required int score,
  }) async {
    try {
      final res = await _client.rpc('submit_learning_quiz', params: {
        'p_module_id': moduleId,
        'p_score': score,
      });

      if (res is Map<String, dynamic>) {
        return res;
      }
      return {'success': true};
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> uploadExternalCertificate({
    required String kind,
    required String title,
    required String issuingOrg,
    required String certificatePath,
  }) async {
    try {
      final res = await _client.rpc('upload_external_certificate', params: {
        'p_kind': kind,
        'p_title': title,
        'p_issuing_org': issuingOrg,
        'p_certificate_path': certificatePath,
      });

      if (res is Map<String, dynamic>) {
        return res;
      }
      return {'success': true, 'is_verified': false};
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<MicroCredential>> getUserCredentials([String? userId]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return [];

    try {
      final res = await _client
          .from('credentials')
          .select()
          .eq('user_id', uid)
          .order('issued_at', ascending: false);

      return (res as List<dynamic>)
          .map((c) => MicroCredential.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return SupabaseCommunityRepository();
});

final communityPostsProvider =
    FutureProvider.family<List<CommunityPost>, String?>((ref, kind) {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getCommunityPosts(kind: kind);
});

final localityTrustProvider = FutureProvider<LocalityTrustIndex>((ref) {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getLocalityTrustIndex();
});

final trainingEventsProvider = FutureProvider<List<TrainingEvent>>((ref) {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getTrainingEvents();
});

final learningModulesProvider = FutureProvider<List<LearningModule>>((ref) {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getLearningModules();
});

final userCredentialsProvider = FutureProvider<List<MicroCredential>>((ref) {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getUserCredentials();
});
