import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/features/seeker/domain/job_detail.dart';
import 'package:udyogasethu/features/seeker/domain/job_eligibility.dart';

abstract class JobDetailRepository {
  Future<({JobDetail detail, bool isOffline})> fetchJobDetail(String jobId);
  Future<JobEligibility> checkEligibility(String jobId);
  Future<String> applyToJob({required String jobId, String? message});
}

class SupabaseJobDetailRepository implements JobDetailRepository {
  final SupabaseClient? _client;
  final SharedPreferences? _prefs;
  static final Map<String, JobDetail> _memoryCache = {};

  SupabaseJobDetailRepository([this._client, this._prefs]);

  @override
  Future<({JobDetail detail, bool isOffline})> fetchJobDetail(String jobId) async {
    // 1. Try fetching live from Supabase
    if (_client != null && Supabase.instance.isInitialized) {
      try {
        final res = await _client.rpc('get_job_detail', params: {'p_job_id': jobId});
        if (res != null) {
          final Map<String, dynamic> data = res is String
              ? jsonDecode(res) as Map<String, dynamic>
              : Map<String, dynamic>.from(res as Map);
          final detail = JobDetail.fromJson(data);

          // Update memory & disk cache
          _memoryCache[jobId] = detail;
          _saveToDiskCache(jobId, detail);

          return (detail: detail, isOffline: false);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[JobDetailRepository] RPC get_job_detail failed, trying fallback: $e');
        }
      }

      // Fallback query directly on jobs table if RPC fails
      try {
        final row = await _client
            .from('jobs')
            .select('*, profiles!provider_id(full_name, avatar_url, is_verified_badge), service_categories(name, slug, icon)')
            .eq('id', jobId)
            .maybeSingle();

        if (row != null) {
          final profile = row['profiles'] as Map<String, dynamic>?;
          final cat = row['service_categories'] as Map<String, dynamic>?;

          final detail = JobDetail(
            id: row['id'] as String,
            providerId: row['provider_id'] as String? ?? '',
            providerName: profile?['full_name'] as String? ?? 'Verified Employer',
            providerAvatar: profile?['avatar_url'] as String?,
            providerVerified: profile?['is_verified_badge'] as bool? ?? true,
            title: row['title'] as String? ?? 'Work Opportunity',
            description: row['description'] as String? ?? '',
            categoryName: cat?['name'] as String? ?? 'General Work',
            categorySlug: cat?['slug'] as String? ?? 'general',
            categoryIcon: cat?['icon'] as String? ?? 'handyman',
            wagePaise: (row['wage_paise'] as num?)?.toInt() ?? 60000,
            wageType: row['wage_type'] as String? ?? 'daily',
            estDurationMinutes: (row['est_duration_minutes'] as num?)?.toInt() ?? 480,
            startAt: row['start_at'] != null ? DateTime.parse(row['start_at']) : DateTime.now(),
            slotsTotal: (row['slots_total'] as num?)?.toInt() ?? 1,
            slotsFilled: (row['slots_filled'] as num?)?.toInt() ?? 0,
            materialsProvided: row['materials_provided'] as bool? ?? false,
            paymentMode: row['payment_mode'] as String? ?? 'escrow',
            requirements: row['requirements'] is Map<String, dynamic> ? row['requirements'] : {},
            addressText: row['address_text'] as String? ?? 'Koramangala, Bengaluru',
            status: row['status'] as String? ?? 'open',
          );

          _memoryCache[jobId] = detail;
          _saveToDiskCache(jobId, detail);
          return (detail: detail, isOffline: false);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[JobDetailRepository] Fallback query failed: $e');
        }
      }
    }

    // 2. Offline Fallback: Check memory cache first
    if (_memoryCache.containsKey(jobId)) {
      return (detail: _memoryCache[jobId]!, isOffline: true);
    }

    // 3. Check SharedPreferences disk cache
    final diskDetail = await _loadFromDiskCache(jobId);
    if (diskDetail != null) {
      _memoryCache[jobId] = diskDetail;
      return (detail: diskDetail, isOffline: true);
    }

    // 4. Default mocked detail if completely absent
    final fallbackDetail = JobDetail(
      id: jobId,
      providerId: 'demo-provider',
      providerName: 'Sharma Builders ✓',
      title: 'Construction Helper',
      description: 'We are looking for a reliable construction helper to assist in daily site work. No prior experience required.',
      wagePaise: 60000,
      startAt: DateTime.now().add(const Duration(hours: 14)),
      estDurationMinutes: 480,
      materialsProvided: true,
      paymentMode: 'escrow',
      slotsTotal: 5,
      slotsFilled: 0,
    );
    return (detail: fallbackDetail, isOffline: true);
  }

  @override
  Future<JobEligibility> checkEligibility(String jobId) async {
    if (_client != null && Supabase.instance.isInitialized) {
      try {
        final res = await _client.rpc('check_job_eligibility', params: {'p_job_id': jobId});
        if (res != null) {
          final Map<String, dynamic> data = res is String
              ? jsonDecode(res) as Map<String, dynamic>
              : Map<String, dynamic>.from(res as Map);
          return JobEligibility.fromJson(data);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[JobDetailRepository] check_job_eligibility RPC failed: $e');
        }
      }
    }

    // Default optimistic eligibility if offline/unavailable
    return const JobEligibility(isEligible: true);
  }

  @override
  Future<String> applyToJob({required String jobId, String? message}) async {
    if (_client == null || !Supabase.instance.isInitialized) {
      throw Exception('Network offline. Cannot apply to job.');
    }

    final res = await _client.rpc('apply_to_job', params: {
      'p_job_id': jobId,
      'p_message': message,
    });

    return res.toString();
  }

  Future<void> _saveToDiskCache(String jobId, JobDetail detail) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString('job_cache_$jobId', jsonEncode(detail.toJson()));
    } catch (_) {}
  }

  Future<JobDetail?> _loadFromDiskCache(String jobId) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final raw = prefs.getString('job_cache_$jobId');
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        return JobDetail.fromJson(data);
      }
    } catch (_) {}
    return null;
  }
}

final jobDetailRepositoryProvider = Provider<JobDetailRepository>((ref) {
  SupabaseClient? client;
  try {
    if (Supabase.instance.isInitialized) {
      client = Supabase.instance.client;
    }
  } catch (_) {}
  return SupabaseJobDetailRepository(client);
});
