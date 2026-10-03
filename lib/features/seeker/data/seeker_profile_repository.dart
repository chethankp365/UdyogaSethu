import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_profile_draft.dart';

abstract class SeekerProfileRepository {
  Future<SeekerProfileDraft> loadDraft(String userId);
  Future<void> saveStep(SeekerProfileDraft draft, int step);
  Future<String> uploadAvatar({
    required String userId,
    required List<int> bytes,
    required String filename,
  });
  Future<List<ServiceCategoryItem>> fetchCategories();
  Future<List<SkillItem>> fetchSkills();
  Future<WageBandResult?> fetchWageBand({String? categoryId, String? city});
  Future<void> logGpsConsent();
  Future<void> completeWizard(SeekerProfileDraft draft);
}

class SupabaseSeekerProfileRepository implements SeekerProfileRepository {
  final SupabaseClient _client;

  SupabaseSeekerProfileRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<SeekerProfileDraft> loadDraft(String userId) async {
    try {
      // 1. Fetch profile row
      final profileRes = await _client
          .from('profiles')
          .select('full_name, avatar_path, gender, home_address, home_location, onboarding_complete')
          .eq('id', userId)
          .maybeSingle();

      // 2. Fetch worker_profile row
      final workerRes = await _client
          .from('worker_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      // 3. Fetch worker skills
      final skillsRes = await _client
          .from('worker_skills')
          .select('skill_id')
          .eq('user_id', userId);

      final List<String> skillIds = (skillsRes as List)
          .map((row) => row['skill_id'].toString())
          .toList();

      // 4. Fetch skill categories from skills table for selected skillIds
      List<String> categoryIds = [];
      if (skillIds.isNotEmpty) {
        final skInfo = await _client
            .from('skills')
            .select('category_id')
            .filter('id', 'in', skillIds);
        categoryIds = (skInfo as List)
            .map((row) => row['category_id'].toString())
            .toSet()
            .toList();
      }

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
      final homeLoc = profileRes?['home_location'];
      if (homeLoc != null && homeLoc is Map) {
        final coords = homeLoc['coordinates'];
        if (coords is List && coords.length >= 2) {
          lng = (coords[0] as num).toDouble();
          lat = (coords[1] as num).toDouble();
        }
      }

      return SeekerProfileDraft(
        currentStep: (workerRes?['wizard_step'] as num?)?.toInt() ?? 1,
        userId: userId,
        fullName: profileRes?['full_name'] as String? ?? '',
        avatarPath: avatarPath,
        avatarUrl: avatarUrl,
        gender: profileRes?['gender'] as String?,
        languages: (workerRes?['languages'] as List?)?.map((e) => e.toString()).toList() ?? ['kn'],
        selectedCategoryIds: categoryIds,
        selectedSkillIds: skillIds,
        subjectsInterests: (workerRes?['subjects_interests'] as List?)?.map((e) => e.toString()).toList() ?? [],
        experienceYears: (workerRes?['experience_years'] as num?)?.toDouble() ?? 0.0,
        dailyRatePaise: (workerRes?['daily_rate_paise'] as num?)?.toInt(),
        hourlyRatePaise: (workerRes?['hourly_rate_paise'] as num?)?.toInt(),
        availabilityStatus: workerRes?['availability'] as String? ?? 'available',
        workingDays: (workerRes?['working_days'] as List?)?.map((e) => e.toString()).toList() ?? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
        workHoursJson: workerRes?['work_hours'] as Map<String, dynamic>? ?? {'start': '09:00', 'end': '18:00'},
        preferredHoursJson: workerRes?['preferred_hours'] as Map<String, dynamic>? ?? {'weekly_hours': 20},
        latitude: lat,
        longitude: lng,
        homeAddress: profileRes?['home_address'] as String?,
        serviceRadiusKm: (workerRes?['service_radius_km'] as num?)?.toDouble() ?? 10.0,
        seekerType: workerRes?['seeker_type'] as String? ?? 'informal',
        collegeName: workerRes?['college_name'] as String?,
        courseName: workerRes?['course'] as String?,
        regNoMasked: workerRes?['reg_no_masked'] as String?,
        hasDrivingLicence: workerRes?['has_driving_licence'] as bool? ?? false,
        onboardingComplete: profileRes?['onboarding_complete'] as bool? ?? false,
      );
    } catch (e, stack) {
      AppLogger.e('Error loading seeker profile draft', e, stack);
      return SeekerProfileDraft(userId: userId);
    }
  }

  @override
  Future<void> saveStep(SeekerProfileDraft draft, int step) async {
    try {
      // Step 1: Update profiles table
      final profileUpdates = <String, dynamic>{
        'full_name': draft.fullName,
        'avatar_path': draft.avatarPath,
        'gender': draft.gender,
        'home_address': draft.homeAddress,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (draft.latitude != null && draft.longitude != null) {
        profileUpdates['home_location'] = 'POINT(${draft.longitude} ${draft.latitude})';
      }

      await _client.from('profiles').update(profileUpdates).eq('id', draft.userId);

      // Step 2: Update worker_profiles table
      final workerUpdates = <String, dynamic>{
        'wizard_step': step,
        'seeker_type': draft.seekerType,
        'experience_years': draft.experienceYears,
        'daily_rate_paise': draft.dailyRatePaise,
        'hourly_rate_paise': draft.hourlyRatePaise,
        'languages': draft.languages,
        'service_radius_km': draft.serviceRadiusKm,
        'availability': draft.availabilityStatus,
        'work_hours': draft.workHoursJson,
        'preferred_hours': draft.preferredHoursJson,
        'college_name': draft.collegeName,
        'course': draft.courseName,
        'reg_no_masked': draft.regNoMasked,
        'has_driving_licence': draft.hasDrivingLicence,
        'subjects_interests': draft.subjectsInterests,
        'working_days': draft.workingDays,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client.from('worker_profiles').upsert({
        'user_id': draft.userId,
        ...workerUpdates,
      });

      // Step 3: Update worker_skills table if skills provided
      await _client.from('worker_skills').delete().eq('user_id', draft.userId);

      if (draft.selectedSkillIds.isNotEmpty) {
        final skillRows = draft.selectedSkillIds
            .map((sId) => {'user_id': draft.userId, 'skill_id': sId})
            .toList();
        await _client.from('worker_skills').insert(skillRows);
      }
    } catch (e, stack) {
      AppLogger.e('Error saving seeker wizard step $step', e, stack);
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

      final publicUrl = _client.storage.from('avatars').getPublicUrl(path);
      return publicUrl;
    } catch (e, stack) {
      AppLogger.e('Error uploading avatar photo', e, stack);
      rethrow;
    }
  }

  @override
  Future<List<ServiceCategoryItem>> fetchCategories() async {
    try {
      final res = await _client
          .from('service_categories')
          .select('id, slug, names, icon, audience')
          .order('sort');

      return (res as List).map((row) {
        final audList = (row['audience'] as List?)?.map((e) => e.toString()).toList() ?? const ['informal'];
        return ServiceCategoryItem(
          id: row['id'].toString(),
          slug: row['slug'].toString(),
          names: row['names'] as Map<String, dynamic>? ?? {'en': row['slug']},
          icon: row['icon'] as String?,
          audience: audList,
        );
      }).toList();
    } catch (e, stack) {
      AppLogger.e('Error fetching service categories', e, stack);
      return [];
    }
  }

  @override
  Future<List<SkillItem>> fetchSkills() async {
    try {
      final res = await _client.from('skills').select('id, category_id, names');

      return (res as List).map((row) {
        return SkillItem(
          id: row['id'].toString(),
          categoryId: row['category_id'].toString(),
          names: row['names'] as Map<String, dynamic>? ?? {'en': 'Skill'},
        );
      }).toList();
    } catch (e, stack) {
      AppLogger.e('Error fetching skills', e, stack);
      return [];
    }
  }

  @override
  Future<WageBandResult?> fetchWageBand({String? categoryId, String? city}) async {
    try {
      final res = await _client.rpc('suggest_wage_band', params: {
        'p_category_id': categoryId,
        'p_area': city ?? 'default',
      });

      if (res is List && res.isNotEmpty) {
        final first = res.first;
        return WageBandResult(
          minPaise: (first['min_paise'] as num).toInt(),
          maxPaise: (first['max_paise'] as num).toInt(),
          unit: first['unit'] as String? ?? 'day',
        );
      }
    } catch (e, stack) {
      AppLogger.e('Error fetching wage band', e, stack);
    }
    return null;
  }

  @override
  Future<void> logGpsConsent() async {
    try {
      await _client.rpc('record_user_consent', params: {
        'p_consent_type': 'gps',
      });
    } catch (e, stack) {
      AppLogger.e('Error logging GPS consent', e, stack);
    }
  }

  @override
  Future<void> completeWizard(SeekerProfileDraft draft) async {
    try {
      await saveStep(draft, 7);
      await _client.from('worker_profiles').update({
        'is_wizard_complete': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', draft.userId);

      await _client.from('profiles').update({
        'onboarding_complete': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', draft.userId);
    } catch (e, stack) {
      AppLogger.e('Error completing seeker profile wizard', e, stack);
      rethrow;
    }
  }
}
