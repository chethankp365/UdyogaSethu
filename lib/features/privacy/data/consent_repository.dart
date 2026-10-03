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

  SupabaseConsentRepository({SupabaseClient? client})
      : _client = client ?? (Supabase.instance.isInitialized ? Supabase.instance.client : null);

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
          .select('consent_type, granted, granted_at, metadata')
          .eq('user_id', user.id)
          .eq('consent_type', purpose.key)
          .order('granted_at', ascending: false)
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
          .select('consent_type, granted, granted_at, metadata')
          .eq('user_id', user.id)
          .eq('consent_type', purpose.key)
          .order('granted_at', ascending: false)
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
    for (final purpose in ConsentPurpose.values) {
      result[purpose] = await getLatestConsent(purpose);
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
      metadata: metadata,
    );
    _localConsentCache[purpose.key] = log;

    try {
      if (_client == null) return;
      final user = _client.auth.currentUser;
      if (user == null) return;

      await _client.from('consent_logs').insert({
        'user_id': user.id,
        'consent_type': purpose.key,
        'granted': granted,
        'granted_at': now.toIso8601String(),
        'metadata': metadata ?? {'version': '1.0', 'granted_via': 'ConsentSheet'},
      });
    } catch (e, stack) {
      AppLogger.e('Error recording consent for ${purpose.key}', e, stack);
      // Saved in _localConsentCache, so flow continues gracefully
    }
  }

  @override
  Future<void> revokeConsent(ConsentPurpose purpose) async {
    final now = DateTime.now();
    _localConsentCache[purpose.key] = ConsentLog(
      purpose: purpose.key,
      granted: false,
      timestamp: now,
    );

    try {
      if (_client == null) return;
      final user = _client.auth.currentUser;
      if (user == null) return;

      try {
        await _client.rpc('revoke_consent', params: {'p_purpose': purpose.key});
      } catch (_) {
        await _client.from('consent_logs').insert({
          'user_id': user.id,
          'consent_type': purpose.key,
          'granted': false,
          'granted_at': now.toIso8601String(),
          'metadata': {'action': 'revoked_by_user'},
        });
      }
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
    );

    try {
      if (_client == null) return;
      final user = _client.auth.currentUser;
      if (user == null) return;

      try {
        await _client.rpc('withdraw_face_consent');
      } catch (_) {
        await _client.from('consent_logs').insert({
          'user_id': user.id,
          'consent_type': ConsentPurpose.face.key,
          'granted': false,
          'granted_at': now.toIso8601String(),
          'metadata': {'action': 'withdrawn_face_consent'},
        });
      }
    } catch (e, stack) {
      AppLogger.e('Error withdrawing face consent', e, stack);
    }
  }
}

final consentRepositoryProvider = Provider<ConsentRepository>((ref) {
  return SupabaseConsentRepository();
});
