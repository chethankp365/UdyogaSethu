import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/features/farmer/domain/farmer_profile_draft.dart';

abstract class FarmerProfileRepository {
  Future<FarmerProfileDraft> loadDraft(String userId);
  Future<void> saveStep(FarmerProfileDraft draft, int step);
  Future<String> uploadAvatar({
    required String userId,
    required List<int> bytes,
    required String filename,
  });
  Future<String> uploadOrganicCert({
    required String userId,
    required List<int> bytes,
    required String filename,
  });
  Future<void> logGpsConsent();
  Future<void> completeWizard(FarmerProfileDraft draft);
}

class SupabaseFarmerProfileRepository implements FarmerProfileRepository {
  final SupabaseClient _client;

  SupabaseFarmerProfileRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<FarmerProfileDraft> loadDraft(String userId) async {
    try {
      // 1. Fetch profile row
      final profileRes = await _client
          .from('profiles')
          .select('full_name, avatar_path, onboarding_complete')
          .eq('id', userId)
          .maybeSingle();

      // 2. Fetch farmer_profile row
      final farmerRes = await _client
          .from('farmer_profiles')
          .select()
          .eq('user_id', userId)
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
      final farmLoc = farmerRes?['farm_location'];
      if (farmLoc != null && farmLoc is Map) {
        final coords = farmLoc['coordinates'];
        if (coords is List && coords.length >= 2) {
          lng = (coords[0] as num).toDouble();
          lat = (coords[1] as num).toDouble();
        }
      }

      final deliveryOpts = (farmerRes?['delivery_options'] as Map<String, dynamic>?) ?? {};

      return FarmerProfileDraft(
        currentStep: (farmerRes?['wizard_step'] as num?)?.toInt() ?? 1,
        userId: userId,
        fullName: profileRes?['full_name'] as String? ?? '',
        avatarPath: avatarPath,
        avatarUrl: avatarUrl,
        farmName: farmerRes?['farm_name'] as String? ?? '',
        farmLatitude: lat,
        farmLongitude: lng,
        clusterVillage: farmerRes?['cluster_village'] as String? ?? '',
        acres: (farmerRes?['acres'] as num?)?.toDouble() ?? 1.0,
        soilType: farmerRes?['soil_type'] as String? ?? 'Red Soil',
        soilPh: (farmerRes?['soil_ph'] as num?)?.toDouble(),
        primaryCrops: (farmerRes?['primary_crops'] as List?)?.map((e) => e.toString()).toList() ?? [],
        farmingMethod: farmerRes?['farming_method'] as String? ?? 'organic',
        apmcRegistration: farmerRes?['apmc_registration'] as String?,
        kccStatus: farmerRes?['kcc_status'] as String? ?? 'none',
        organicCertStatus: farmerRes?['organic_cert_status'] as String? ?? 'not_started',
        organicCertPath: farmerRes?['organic_cert_path'] as String?,
        deliveryAvailable: deliveryOpts['delivery_available'] as bool? ?? true,
        pickupAvailable: deliveryOpts['pickup_available'] as bool? ?? true,
        deliveryRadiusKm: (deliveryOpts['delivery_radius_km'] as num?)?.toDouble() ?? 15.0,
        leadTime: deliveryOpts['lead_time'] as String? ?? '1 day',
        onboardingComplete: profileRes?['onboarding_complete'] as bool? ?? false,
      );
    } catch (e, stack) {
      AppLogger.e('Error loading farmer profile draft', e, stack);
      return FarmerProfileDraft(userId: userId);
    }
  }

  @override
  Future<void> saveStep(FarmerProfileDraft draft, int step) async {
    try {
      // Step 1: Update profiles table
      final profileUpdates = <String, dynamic>{
        'full_name': draft.fullName,
        'avatar_path': draft.avatarPath,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client.from('profiles').update(profileUpdates).eq('id', draft.userId);

      // Step 2: Update farmer_profiles table
      final deliveryOpts = {
        'delivery_available': draft.deliveryAvailable,
        'pickup_available': draft.pickupAvailable,
        'delivery_radius_km': draft.deliveryRadiusKm,
        'lead_time': draft.leadTime,
      };

      final farmerUpdates = <String, dynamic>{
        'wizard_step': step,
        'farm_name': draft.farmName,
        'cluster_village': draft.clusterVillage,
        'acres': draft.acres,
        'soil_type': draft.soilType,
        'soil_ph': draft.soilPh,
        'primary_crops': draft.primaryCrops,
        'farming_method': draft.farmingMethod,
        'apmc_registration': draft.apmcRegistration,
        'kcc_status': draft.kccStatus,
        'organic_cert_status': draft.organicCertStatus,
        'organic_cert_path': draft.organicCertPath,
        'delivery_options': deliveryOpts,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (draft.farmLongitude != null && draft.farmLatitude != null) {
        farmerUpdates['farm_location'] = 'POINT(${draft.farmLongitude} ${draft.farmLatitude})';
      }

      await _client.from('farmer_profiles').upsert({
        'user_id': draft.userId,
        ...farmerUpdates,
      });
    } catch (e, stack) {
      AppLogger.e('Error saving farmer wizard step $step', e, stack);
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
  Future<String> uploadOrganicCert({
    required String userId,
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      final path = '$userId/$filename';
      await _client.storage.from('kyc-docs').uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(upsert: true),
          );

      return path;
    } catch (e, stack) {
      AppLogger.e('Error uploading organic certificate to private kyc-docs storage', e, stack);
      throw const AppException.unknown('Failed to upload organic certificate');
    }
  }

  @override
  Future<void> logGpsConsent() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      try {
        await _client.rpc('record_user_consent_v2', params: {
          'p_purpose': 'gps',
          'p_granted': true,
          'p_version': '1.0',
        });
        return;
      } catch (_) {}

      await _client.from('consent_logs').insert({
        'user_id': user.id,
        'purpose': 'gps',
        'granted': true,
        'version': '1.0',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.w('Failed to log GPS consent: $e');
    }
  }

  @override
  Future<void> completeWizard(FarmerProfileDraft draft) async {
    try {
      await saveStep(draft, 5);

      await _client.from('farmer_profiles').update({
        'is_wizard_complete': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', draft.userId);

      await _client.from('profiles').update({
        'onboarding_complete': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', draft.userId);
    } catch (e, stack) {
      AppLogger.e('Error completing farmer wizard', e, stack);
      rethrow;
    }
  }
}
