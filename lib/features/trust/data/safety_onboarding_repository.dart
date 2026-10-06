import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/features/trust/domain/safety_onboarding_status.dart';

final safetyOnboardingRepositoryProvider = Provider<SafetyOnboardingRepository>((ref) {
  SupabaseClient? client;
  try {
    if (Supabase.instance.isInitialized) {
      client = Supabase.instance.client;
    }
  } catch (_) {}
  return SafetyOnboardingRepository(client: client);
});

class SafetyOnboardingRepository {
  final SupabaseClient? client;

  SafetyOnboardingRepository({this.client});

  Future<SafetyOnboardingStatus> fetchStatus(String userId) async {
    if (client == null) return SafetyOnboardingStatus.initial();

    try {
      final res = await client!.rpc('get_safety_onboarding_status', params: {
        'p_user_id': userId,
      });

      if (res != null && res is Map) {
        return SafetyOnboardingStatus.fromJson(Map<String, dynamic>.from(res));
      }
    } catch (_) {
      // Fallback read directly from tables if RPC is unavailable
      try {
        final kyc = await client!
            .from('kyc_records')
            .select('status')
            .eq('user_id', userId)
            .maybeSingle();

        final face = await client!
            .from('face_profiles')
            .select('status')
            .eq('user_id', userId)
            .maybeSingle();

        final reg = await client!
            .from('event_registrations')
            .select('status')
            .eq('user_id', userId)
            .maybeSingle();

        final wp = await client!
            .from('worker_profiles')
            .select('is_verified_badge')
            .eq('user_id', userId)
            .maybeSingle();

        final kycOk = kyc != null && kyc['status'] == 'verified';
        final faceOk = face != null && face['status'] == 'verified';
        final regStatus = (reg?['status'] as String?) ?? 'not_booked';
        final trainingOk = ['attended', 'document_review', 'approved'].contains(regStatus);
        final docOk = regStatus == 'approved';
        final isVerified = wp != null && wp['is_verified_badge'] == true;

        return SafetyOnboardingStatus(
          isVerifiedBadge: isVerified,
          kycOk: kycOk,
          faceOk: faceOk,
          trainingOk: trainingOk,
          docOk: docOk,
          registrationStatus: regStatus,
        );
      } catch (_) {}
    }

    return SafetyOnboardingStatus.initial();
  }

  Future<SafetyOnboardingStatus> bookSlot(String eventId) async {
    if (client == null) return SafetyOnboardingStatus.initial();

    try {
      final res = await client!.rpc('book_safety_onboarding_slot', params: {
        'p_event_id': eventId,
      });

      if (res != null && res is Map) {
        return SafetyOnboardingStatus.fromJson(Map<String, dynamic>.from(res));
      }
    } catch (e) {
      rethrow;
    }

    return SafetyOnboardingStatus.initial();
  }

  Future<SafetyOnboardingStatus> simulateStatus(String userId, String status) async {
    if (client == null) return SafetyOnboardingStatus.initial();

    try {
      final res = await client!.rpc('simulate_training_status', params: {
        'p_user_id': userId,
        'p_status': status,
      });

      if (res != null && res is Map) {
        return SafetyOnboardingStatus.fromJson(Map<String, dynamic>.from(res));
      }
    } catch (e) {
      rethrow;
    }

    return fetchStatus(userId);
  }
}
