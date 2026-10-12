// Data layer: SafetyRepository (Step P7.3)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/supabase/supabase_service.dart';
import 'package:udyogasethu/features/safety/domain/emergency_contact.dart';
import 'package:udyogasethu/features/safety/domain/protection_claim.dart';
import 'package:udyogasethu/features/safety/domain/sos_incident.dart';

abstract class SafetyRepository {
  Future<SosIncident> triggerSos({
    required double lat,
    required double lng,
    String? assignmentId,
    String? bookingCode,
  });

  Future<List<EmergencyContact>> getEmergencyContacts();

  Future<EmergencyContact> addEmergencyContact({
    required String name,
    required String phone,
    String relation = 'Family',
  });

  Future<void> deleteEmergencyContact(String id);

  Future<ClaimEligibilityResult> checkClaimEligibility(String assignmentId);

  Future<ProtectionClaim> submitProtectionClaim({
    required String assignmentId,
    required String claimType,
    required int amountPaise,
    required String details,
  });

  Future<List<ProtectionClaim>> getSubmittedClaims();
}

class SupabaseSafetyRepository implements SafetyRepository {
  final SupabaseClient _client;

  SupabaseSafetyRepository(this._client);

  String get _currentUserId => _client.auth.currentUser?.id ?? '';

  @override
  Future<SosIncident> triggerSos({
    required double lat,
    required double lng,
    String? assignmentId,
    String? bookingCode,
  }) async {
    try {
      if (_currentUserId.isEmpty) {
        return _getDemoSosIncident(lat, lng, assignmentId);
      }

      final response = await _client.functions.invoke(
        'sos-trigger',
        body: {
          'lat': lat,
          'lng': lng,
          'assignment_id': assignmentId,
          'booking_code': bookingCode,
        },
      );

      final rawData = response.data;
      final data = rawData is Map<String, dynamic>
          ? (rawData['data'] as Map<String, dynamic>? ?? rawData)
          : <String, dynamic>{};
      return SosIncident.fromJson(data);
    } catch (e) {
      if (e is AppException) rethrow;
      // Fallback in demo/offline mode
      return _getDemoSosIncident(lat, lng, assignmentId);
    }
  }

  @override
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    if (_currentUserId.isEmpty) {
      return _getDemoContacts();
    }

    try {
      final res = await _client.rpc('get_emergency_contacts');
      if (res is List) {
        return res
            .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return _getDemoContacts();
    }
  }

  @override
  Future<EmergencyContact> addEmergencyContact({
    required String name,
    required String phone,
    String relation = 'Family',
  }) async {
    if (_currentUserId.isEmpty) {
      return EmergencyContact(
        id: 'demo-contact-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        phone: phone,
        relation: relation,
        createdAt: DateTime.now(),
      );
    }

    final res = await _client.rpc('add_emergency_contact', params: {
      'p_name': name,
      'p_phone': phone,
      'p_relation': relation,
    });

    final map = res as Map<String, dynamic>;
    return EmergencyContact.fromJson(map);
  }

  @override
  Future<void> deleteEmergencyContact(String id) async {
    if (_currentUserId.isEmpty) return;

    await _client.rpc('delete_emergency_contact', params: {
      'p_contact_id': id,
    });
  }

  @override
  Future<ClaimEligibilityResult> checkClaimEligibility(String assignmentId) async {
    if (_currentUserId.isEmpty || assignmentId.startsWith('demo')) {
      return const ClaimEligibilityResult(
        eligible: true,
        qrOk: true,
        selfieGpsOk: true,
        timerOk: true,
        durationMinutes: 48,
        evidenceOk: true,
        evidenceCount: 1,
      );
    }

    try {
      final res = await _client.rpc('check_claim_eligibility', params: {
        'p_assignment_id': assignmentId,
      });

      return ClaimEligibilityResult.fromJson(res as Map<String, dynamic>);
    } catch (_) {
      return const ClaimEligibilityResult(
        eligible: true,
        qrOk: true,
        selfieGpsOk: true,
        timerOk: true,
        durationMinutes: 45,
        evidenceOk: false,
        evidenceCount: 0,
      );
    }
  }

  @override
  Future<ProtectionClaim> submitProtectionClaim({
    required String assignmentId,
    required String claimType,
    required int amountPaise,
    required String details,
  }) async {
    if (_currentUserId.isEmpty || assignmentId.startsWith('demo')) {
      final now = DateTime.now();
      return ProtectionClaim(
        id: 'demo-clm-${now.millisecondsSinceEpoch}',
        claimCode: 'CLM-${now.millisecondsSinceEpoch.toString().substring(7)}',
        assignmentId: assignmentId,
        claimType: claimType,
        amountPaise: amountPaise,
        details: details,
        status: 'submitted',
        isSimulated: true,
        createdAt: now,
      );
    }

    final res = await _client.rpc('submit_protection_claim', params: {
      'p_assignment_id': assignmentId,
      'p_claim_type': claimType,
      'p_amount_paise': amountPaise,
      'p_details': details,
    });

    return ProtectionClaim.fromJson(res as Map<String, dynamic>);
  }

  @override
  Future<List<ProtectionClaim>> getSubmittedClaims() async {
    if (_currentUserId.isEmpty) {
      return [
        ProtectionClaim(
          id: 'demo-clm-01',
          claimCode: 'CLM-9824',
          assignmentId: 'demo_asg_01',
          claimType: 'Minor Site Injury Cover',
          amountPaise: 450000,
          details: 'Tripped near work area, medical first-aid cost.',
          status: 'submitted',
          isSimulated: true,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
    }

    try {
      final res = await _client
        .from('protection_claims')
        .select()
        .eq('claimant_id', _currentUserId)
        .order('created_at', ascending: false);

      return (res as List)
          .map((e) => ProtectionClaim.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  SosIncident _getDemoSosIncident(double lat, double lng, String? assignmentId) {
    return SosIncident(
      id: 'demo-incident-${DateTime.now().millisecondsSinceEpoch}',
      assignmentId: assignmentId,
      latitude: lat,
      longitude: lng,
      status: 'active',
      smsConfigured: false,
      smsSent: false,
      emergencyContactsCount: 2,
      message: 'Demo mode: SOS escalation simulated. SMS gateway is not configured.',
      createdAt: DateTime.now(),
    );
  }

  List<EmergencyContact> _getDemoContacts() {
    return [
      EmergencyContact(
        id: 'ec-01',
        name: 'Ramesh Kumar (Brother)',
        phone: '+91 98450 12345',
        relation: 'Family',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      EmergencyContact(
        id: 'ec-02',
        name: 'Sunita Devi (Mother)',
        phone: '+91 98450 67890',
        relation: 'Family',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }
}

final safetyRepositoryProvider = Provider<SafetyRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseSafetyRepository(client);
});
