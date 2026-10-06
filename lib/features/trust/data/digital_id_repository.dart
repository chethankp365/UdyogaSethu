import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/supabase/edge_api.dart';
import 'package:udyogasethu/features/trust/domain/digital_id_card.dart';

final digitalIdRepositoryProvider = Provider<DigitalIdRepository>((ref) {
  SupabaseClient? client;
  try {
    if (Supabase.instance.isInitialized) {
      client = Supabase.instance.client;
    }
  } catch (_) {}
  final edgeApi = ref.watch(edgeApiClientProvider);
  return DigitalIdRepository(client: client, edgeApi: edgeApi);
});

class DigitalIdRepository {
  final SupabaseClient? client;
  final EdgeApiClient edgeApi;

  DigitalIdRepository({this.client, required this.edgeApi});

  /// Fetch full user ID card details including a freshly signed expiring QR token.
  Future<DigitalIdCardData> fetchDigitalId(String userId) async {
    String fullName = 'UdyogaSethu Member';
    String? avatarPath;
    String roleName = 'Job Seeker';
    bool isVerifiedBadge = false;
    int level = 1;
    String levelName = 'Starter';
    DateTime? createdAt;

    if (client != null) {
      try {
        final profile = await client!
            .from('profiles')
            .select('full_name, avatar_path, created_at')
            .eq('id', userId)
            .maybeSingle();

        if (profile != null) {
          fullName = (profile['full_name'] as String?)?.trim().isNotEmpty == true
              ? profile['full_name']
              : 'UdyogaSethu Member';
          avatarPath = profile['avatar_path'] as String?;
          if (profile['created_at'] != null) {
            createdAt = DateTime.tryParse(profile['created_at'].toString());
          }
        }

        final wp = await client!
            .from('worker_profiles')
            .select('seeker_type, is_verified_badge')
            .eq('user_id', userId)
            .maybeSingle();

        if (wp != null) {
          isVerifiedBadge = wp['is_verified_badge'] == true;
          final sType = wp['seeker_type'] as String?;
          if (sType == 'student') {
            roleName = 'Job Seeker • Student';
          } else if (sType == 'part_time') {
            roleName = 'Job Seeker • Part-Time';
          } else {
            roleName = 'Job Seeker • Informal';
          }
        }

        // Compute level from XP
        try {
          final xpRes = await client!
              .from('xp_events')
              .select('points')
              .eq('user_id', userId);
          int totalXp = 0;
          for (final row in xpRes) {
            totalXp += (row['points'] as num?)?.toInt() ?? 0;
          }

          final levelsRes = await client!
              .from('levels')
              .select('level_number, name, min_xp')
              .lte('min_xp', totalXp)
              .order('min_xp', ascending: false)
              .limit(1);

          if (levelsRes.isNotEmpty) {
            level = (levelsRes.first['level_number'] as num?)?.toInt() ?? 1;
            levelName = levelsRes.first['name'] as String? ?? 'Starter';
          }
        } catch (_) {}
      } catch (_) {}
    }

    final displayId = DigitalIdCardData.formatDisplayId(userId, createdAt?.year);

    // Issue signed QR token
    String? qrToken;
    DateTime? qrExpiresAt;
    int qrExpiresInSeconds = 300;

    try {
      final tokenRes = await edgeApi.qrIssue(purpose: 'profile');
      if (tokenRes['success'] == true && tokenRes['data'] != null) {
        final d = tokenRes['data'] as Map<String, dynamic>;
        qrToken = d['qr_token'] as String?;
        qrExpiresInSeconds = (d['expires_in_seconds'] as num?)?.toInt() ?? 300;
        if (d['expires_at'] != null) {
          qrExpiresAt = DateTime.tryParse(d['expires_at'].toString());
        }
      }
    } catch (_) {
      // In offline / fallback mode, provide an unsigned temporary placeholder
      qrExpiresAt = DateTime.now().add(const Duration(seconds: 300));
    }

    return DigitalIdCardData(
      userId: userId,
      displayId: displayId,
      fullName: fullName,
      avatarPath: avatarPath,
      roleName: roleName,
      isVerifiedBadge: isVerifiedBadge,
      level: level,
      levelName: levelName,
      qrToken: qrToken,
      qrExpiresAt: qrExpiresAt,
      qrExpiresInSeconds: qrExpiresInSeconds,
    );
  }

  /// Request a freshly signed expiring QR token for the active user.
  Future<Map<String, dynamic>> issueFreshQrToken() async {
    final res = await edgeApi.qrIssue(purpose: 'profile');
    if (res['success'] == true && res['data'] != null) {
      return Map<String, dynamic>.from(res['data'] as Map);
    }
    throw const EdgeFunctionException(
      code: 'qr_issue_failed',
      statusCode: 500,
      originalMessage: 'Failed to issue fresh QR token',
    );
  }

  /// Verify a scanned QR token through the Edge Function.
  /// Strictly returns only non-PII public status fields.
  Future<PublicVerificationResult> verifyQrToken(String token) async {
    try {
      final res = await edgeApi.qrVerify(qrToken: token);
      if (res['success'] == true && res['data'] != null) {
        return PublicVerificationResult.fromJson(Map<String, dynamic>.from(res['data'] as Map));
      } else {
        final err = res['error'] as Map<String, dynamic>?;
        return PublicVerificationResult.error(
          code: err?['code'] as String? ?? 'unknown_error',
          message: err?['message'] as String? ?? 'Verification failed',
        );
      }
    } on EdgeFunctionException catch (e) {
      return PublicVerificationResult.error(
        code: e.code,
        message: e.originalMessage ?? 'Verification failed',
      );
    } catch (e) {
      return PublicVerificationResult.error(
        code: 'network_error',
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Revoke a token server-side (for debug/testing or manual revocation).
  Future<bool> revokeToken(String tokenIdHash) async {
    if (client == null) return false;
    try {
      final res = await client!.rpc('revoke_qr_token', params: {
        'p_token_id_hash': tokenIdHash,
      });
      return res == true;
    } catch (_) {
      return false;
    }
  }
}
