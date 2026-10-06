import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/features/privacy/domain/consent_purpose.dart';

abstract class ConsentRepository {
  Future<bool> hasValidConsent(ConsentPurpose purpose);
  Future<ConsentLog?> getLatestConsent(ConsentPurpose purpose);
  Future<Map<ConsentPurpose, ConsentLog?>> getAllConsents();
  Future<void> recordConsent({
    required ConsentPurpose purpose,
    required bool granted,
    Map<String, dynamic>? metadata,
  });
  Future<void> revokeConsent(ConsentPurpose purpose);
  Future<void> withdrawFaceConsent();
}

class SupabaseConsentRepository implements ConsentRepository {
  final SupabaseClient? _client;
  // Local in-memory cache fallback for instant verification & mock environments
  static final Map<String, ConsentLog> _localConsentCache = {};

  static SupabaseClient? _getSafeClient(SupabaseClient? client) {
    if (client != null) return client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  SupabaseConsentRepository({SupabaseClient? client})
      : _client = _getSafeClient(client);

  @override
  Future<bool> hasValidConsent(ConsentPurpose purpose) async {
    try {
      if (_client == null) {
        final cached = _localConsentCache[purpose.key];
        return cached?.granted ?? false;
      }
      final user = _client.auth.currentUser;
      if (user == null) {
        final cached = _localConsentCache[purpose.key];
        return cached?.granted ?? false;
      }

      final data = await _client
          .from('consent_logs')
          .select('id, user_id, purpose, granted, version, created_at')
          .eq('user_id', user.id)
          .eq('purpose', purpose.key)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) {
        final cached = _localConsentCache[purpose.key];
        return cached?.granted ?? false;
      }

      final log = ConsentLog.fromJson(data);
      _localConsentCache[purpose.key] = log;
      return log.granted;
    } catch (e, stack) {
      AppLogger.e('Error checking consent for ${purpose.key}', e, stack);
      final cached = _localConsentCache[purpose.key];
      return cached?.granted ?? false;
    }
  }

  @override
  Future<ConsentLog?> getLatestConsent(ConsentPurpose purpose) async {
    try {
      if (_client == null) return _localConsentCache[purpose.key];
      final user = _client.auth.currentUser;
      if (user == null) return _localConsentCache[purpose.key];

      final data = await _client
          .from('consent_logs')
          .select('id, user_id, purpose, granted, version, created_at')
          .eq('user_id', user.id)
          .eq('purpose', purpose.key)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) return _localConsentCache[purpose.key];

      final log = ConsentLog.fromJson(data);
      _localConsentCache[purpose.key] = log;
      return log;
    } catch (e, stack) {
      AppLogger.e('Error fetching consent log for ${purpose.key}', e, stack);
      return _localConsentCache[purpose.key];
    }
  }

  @override
  Future<Map<ConsentPurpose, ConsentLog?>> getAllConsents() async {
    final result = <ConsentPurpose, ConsentLog?>{};

    try {
      if (_client != null && _client.auth.currentUser != null) {
        // Try optimized RPC first
        try {
          final res = await _client.rpc('get_user_consents');
          if (res is List && res.isNotEmpty) {
            for (final item in res) {
              if (item is Map<String, dynamic>) {
                final log = ConsentLog.fromJson(item);
                final purpose = ConsentPurpose.fromKey(log.purpose);
                result[purpose] = log;
                _localConsentCache[purpose.key] = log;
              }
            }
            for (final p in ConsentPurpose.values) {
              result.putIfAbsent(p, () => _localConsentCache[p.key]);
            }
            return result;
          }
        } catch (_) {
          // RPC may not be present in local test DB, fall back to direct select
        }

        final user = _client.auth.currentUser!;
        final rows = await _client
            .from('consent_logs')
            .select('id, user_id, purpose, granted, version, created_at')
            .eq('user_id', user.id)
            .order('created_at', ascending: false);

        for (final row in rows) {
          final log = ConsentLog.fromJson(row);
          final purpose = ConsentPurpose.fromKey(log.purpose);
          if (!result.containsKey(purpose)) {
            result[purpose] = log;
            _localConsentCache[purpose.key] = log;
          }
        }
      }
    } catch (e, stack) {
      AppLogger.e('Error fetching all consents from database', e, stack);
    }

    // Fill any missing from in-memory cache
    for (final purpose in ConsentPurpose.values) {
      result.putIfAbsent(purpose, () => _localConsentCache[purpose.key]);
    }
    return result;
  }

  @override
  Future<void> recordConsent({
    required ConsentPurpose purpose,
    required bool granted,
    Map<String, dynamic>? metadata,
  }) async {
    final now = DateTime.now();
    final log = ConsentLog(
      purpose: purpose.key,
      granted: granted,
      timestamp: now,
      version: '1.0',
      metadata: metadata,
    );
    _localConsentCache[purpose.key] = log;

    try {
      if (_client == null) return;
      final user = _client.auth.currentUser;
      if (user == null) return;

      try {
        await _client.rpc('record_user_consent_v2', params: {
          'p_purpose': purpose.key,
          'p_granted': granted,
          'p_version': '1.0',
        });
        return;
      } catch (_) {
        // Fall back to direct table insert
      }

      await _client.from('consent_logs').insert({
        'user_id': user.id,
        'purpose': purpose.key,
        'granted': granted,
        'version': '1.0',
        'created_at': now.toIso8601String(),
      });
    } catch (e, stack) {
      AppLogger.e('Error recording consent for ${purpose.key}', e, stack);
    }
  }

  @override
  Future<void> revokeConsent(ConsentPurpose purpose) async {
    final now = DateTime.now();
    _localConsentCache[purpose.key] = ConsentLog(
      purpose: purpose.key,
      granted: false,
      timestamp: now,
      version: '1.0',
    );

    try {
      if (_client == null) return;
      final user = _client.auth.currentUser;
      if (user == null) return;

      try {
        await _client.rpc('revoke_consent', params: {'p_purpose': purpose.key});
        return;
      } catch (_) {}

      try {
        await _client.rpc('record_user_consent_v2', params: {
          'p_purpose': purpose.key,
          'p_granted': false,
          'p_version': '1.0',
        });
        return;
      } catch (_) {}

      await _client.from('consent_logs').insert({
        'user_id': user.id,
        'purpose': purpose.key,
        'granted': false,
        'version': '1.0',
        'created_at': now.toIso8601String(),
      });
    } catch (e, stack) {
      AppLogger.e('Error revoking consent for ${purpose.key}', e, stack);
    }
  }

  @override
  Future<void> withdrawFaceConsent() async {
    final now = DateTime.now();
    _localConsentCache[ConsentPurpose.face.key] = ConsentLog(
      purpose: ConsentPurpose.face.key,
      granted: false,
      timestamp: now,
      version: '1.0',
    );

    try {
      if (_client == null) return;
      final user = _client.auth.currentUser;
      if (user == null) return;

      try {
        await _client.rpc('withdraw_face_consent');
        return;
      } catch (_) {}

      await _client.from('consent_logs').insert({
        'user_id': user.id,
        'purpose': ConsentPurpose.face.key,
        'granted': false,
        'version': '1.0',
        'created_at': now.toIso8601String(),
      });

      // Scrub profile references
      try {
        await _client.from('face_profiles').delete().eq('user_id', user.id);
      } catch (_) {}
      try {
        await _client
            .from('verification_attempts')
            .delete()
            .eq('user_id', user.id)
            .eq('verification_type', 'face');
      } catch (_) {}
    } catch (e, stack) {
      AppLogger.e('Error withdrawing face consent', e, stack);
    }
  }
}

final consentRepositoryProvider = Provider<ConsentRepository>((ref) {
  return SupabaseConsentRepository();
});
