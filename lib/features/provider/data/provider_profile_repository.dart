import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/features/provider/domain/provider_profile_draft.dart';

abstract class ProviderProfileRepository {
  Future<ProviderProfileDraft> loadDraft(String userId);
  Future<void> saveStep(ProviderProfileDraft draft, int step);
  Future<String> uploadAvatar({
    required String userId,
    required List<int> bytes,
    required String filename,
  });
  Future<void> logConsent({required String consentType});
  Future<void> completeWizard(ProviderProfileDraft draft);
}

class SupabaseProviderProfileRepository implements ProviderProfileRepository {
  final SupabaseClient _client;

  SupabaseProviderProfileRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<ProviderProfileDraft> loadDraft(String userId) async {
    try {
      // 1. Fetch profile row
      final profileRes = await _client
          .from('profiles')
          .select('full_name, avatar_path, onboarding_complete')
          .eq('id', userId)
          .maybeSingle();

      // 2. Fetch provider_profile row
      final providerRes = await _client
          .from('provider_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      // 3. Fetch default address row
      final addrRes = await _client
          .from('addresses')
          .select()
          .eq('user_id', userId)
          .eq('is_default', true)
          .maybeSingle();

      String? avatarUrl;
      final avatarPath = profileRes?['avatar_path'] as String?;
      if (avatarPath != null && avatarPath.isNotEmpty) {
        if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
          avatarUrl = avatarPath;
        } else {
          avatarUrl = _client.storage.from('avatars').getPublicUrl(avatarPath);
        }
      }

      double? lat;
      double? lng;
      final loc = addrRes?['location'];
      if (loc != null && loc is Map) {
        final coords = loc['coordinates'];
        if (coords is List && coords.length >= 2) {
          lng = (coords[0] as num).toDouble();
          lat = (coords[1] as num).toDouble();
        }
      }

      final pType = providerRes?['provider_type'] as String? ?? 'household';
      final delPrefs = (providerRes?['delivery_preferences'] as Map<String, dynamic>?) ?? {};

      return ProviderProfileDraft(
        currentStep: (providerRes?['wizard_step'] as num?)?.toInt() ?? 1,
        userId: userId,
        fullName: profileRes?['full_name'] as String? ?? '',
        avatarPath: avatarPath,
        avatarUrl: avatarUrl,
        providerType: pType,
        addressLine1: pType == 'household' ? (addrRes?['line1'] as String? ?? '') : '',
        landmark: pType == 'household' ? (addrRes?['landmark'] as String? ?? '') : '',
        city: pType == 'household' ? (addrRes?['city'] as String? ?? 'Bengaluru') : 'Bengaluru',
        pincode: pType == 'household' ? (addrRes?['pincode'] as String? ?? '560001') : '560001',
        latitude: pType == 'household' ? lat : null,
        longitude: pType == 'household' ? lng : null,
        deliveryDropoffInstruction: delPrefs['instruction'] as String? ?? 'Leave at doorstep',
        gateCode: delPrefs['gate_code'] as String?,
        orgName: providerRes?['org_name'] as String? ?? '',
        siteAddressLine1: pType == 'employer' ? (addrRes?['line1'] as String? ?? '') : '',
        siteLandmark: pType == 'employer' ? (addrRes?['landmark'] as String? ?? '') : '',
        siteCity: pType == 'employer' ? (addrRes?['city'] as String? ?? 'Bengaluru') : 'Bengaluru',
        sitePincode: pType == 'employer' ? (addrRes?['pincode'] as String? ?? '560001') : '560001',
        siteLatitude: pType == 'employer' ? lat : null,
        siteLongitude: pType == 'employer' ? lng : null,
        categoriesHiring: (providerRes?['categories_hiring'] as List?)?.map((e) => e.toString()).toList() ?? [],
        typicalCrewSize: (providerRes?['typical_crew_size'] as num?)?.toInt() ?? 5,
        onboardingComplete: profileRes?['onboarding_complete'] as bool? ?? false,
      );
    } catch (e, stack) {
      AppLogger.e('Error loading provider profile draft', e, stack);
      return ProviderProfileDraft(userId: userId);
    }
  }

  @override
  Future<void> saveStep(ProviderProfileDraft draft, int step) async {
    try {
      // 1. Update profiles table
      final profileUpdates = <String, dynamic>{
        'full_name': draft.fullName,
        'avatar_path': draft.avatarPath,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client.from('profiles').update(profileUpdates).eq('id', draft.userId);

      // 2. Update provider_profiles table
      final delPrefs = draft.isHousehold
          ? {
              'instruction': draft.deliveryDropoffInstruction,
              'gate_code': draft.gateCode,
            }
          : null;

      final providerUpdates = <String, dynamic>{
        'wizard_step': step,
        'provider_type': draft.providerType,
        'org_name': draft.isEmployer ? draft.orgName : null,
        'categories_hiring': draft.isEmployer ? draft.categoriesHiring : null,
        'typical_crew_size': draft.isEmployer ? draft.typicalCrewSize : null,
        'delivery_preferences': delPrefs,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client.from('provider_profiles').upsert({
        'user_id': draft.userId,
        ...providerUpdates,
      });

      // 3. Save default address if provided
      final line1 = draft.isHousehold ? draft.addressLine1 : draft.siteAddressLine1;
      final landmark = draft.isHousehold ? draft.landmark : draft.siteLandmark;
      final city = draft.isHousehold ? draft.city : draft.siteCity;
      final pincode = draft.isHousehold ? draft.pincode : draft.sitePincode;
      final lat = draft.isHousehold ? draft.latitude : draft.siteLatitude;
      final lng = draft.isHousehold ? draft.longitude : draft.siteLongitude;

      if (line1.trim().isNotEmpty) {
        final addrData = <String, dynamic>{
          'user_id': draft.userId,
          'label': draft.isHousehold ? 'Doorstep Address' : 'Primary Site Address',
          'line1': line1,
          'landmark': landmark,
          'city': city.isNotEmpty ? city : 'Bengaluru',
          'pincode': pincode.isNotEmpty ? pincode : '560001',
          'is_default': true,
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (lat != null && lng != null) {
          addrData['location'] = 'POINT($lng $lat)';
        }

        // Delete existing default addresses for user to maintain clean single default
        await _client.from('addresses').delete().eq('user_id', draft.userId).eq('is_default', true);
        await _client.from('addresses').insert(addrData);
      }
    } catch (e, stack) {
      AppLogger.e('Error saving provider wizard step $step', e, stack);
      rethrow;
    }
  }

  @override
  Future<String> uploadAvatar({
    required String userId,
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      final path = '$userId/$filename';
      await _client.storage.from('avatars').uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(upsert: true),
          );

      return path;
    } catch (e, stack) {
      AppLogger.e('Error uploading avatar photo', e, stack);
      throw const AppException.unknown('Failed to upload profile photo');
    }
  }

  @override
  Future<void> logConsent({required String consentType}) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;
      final purpose = consentType.toLowerCase() == 'location' ? 'gps' : consentType.toLowerCase();

      try {
        await _client.rpc('record_user_consent_v2', params: {
          'p_purpose': purpose,
          'p_granted': true,
          'p_version': '1.0',
        });
        return;
      } catch (_) {}

      await _client.from('consent_logs').insert({
        'user_id': user.id,
        'purpose': purpose,
        'granted': true,
        'version': '1.0',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.w('Failed to log consent for $consentType: $e');
    }
  }

  @override
  Future<void> completeWizard(ProviderProfileDraft draft) async {
    try {
      await saveStep(draft, 5);

      await _client.from('provider_profiles').update({
        'is_wizard_complete': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', draft.userId);

      await _client.from('profiles').update({
        'onboarding_complete': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', draft.userId);
    } catch (e, stack) {
      AppLogger.e('Error completing provider wizard', e, stack);
      rethrow;
    }
  }
}
