import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/features/account/domain/linked_accounts_state.dart';
import 'package:udyogasethu/features/account/domain/user_settings.dart';
import 'package:udyogasethu/features/onboarding/domain/pending_role_selection.dart';

abstract class AccountRepository {
  Future<UserSettings> loadSettings(String userId);
  Future<void> saveSettings({required String userId, required UserSettings settings});
  Future<void> switchActiveRole({required String userId, required UserRole role});
  Future<void> addRole({required String userId, required UserRole role});
  Future<void> updateSeekerType({required String userId, required SeekerType newType});
  Future<LinkedAccountsState> getLinkedAccounts();
  Future<String> exportUserData();
  Future<void> deleteAccount();
}

class SupabaseAccountRepository implements AccountRepository {
  final SupabaseClient _client;

  SupabaseAccountRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<UserSettings> loadSettings(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select('language, simple_mode, text_scale, voice_hints, low_data_mode')
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return const UserSettings();
      return UserSettings.fromJson(data);
    } catch (e, stack) {
      AppLogger.e('Error loading user settings', e, stack);
      return const UserSettings();
    }
  }

  @override
  Future<void> saveSettings({required String userId, required UserSettings settings}) async {
    try {
      await _client.from('profiles').update(settings.toJson()).eq('id', userId);
    } catch (e, stack) {
      AppLogger.e('Error saving user settings', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> switchActiveRole({required String userId, required UserRole role}) async {
    try {
      final roleStr = role.name;
      await _client.from('profiles').update({
        'active_role': roleStr,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e, stack) {
      AppLogger.e('Error switching active role', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> addRole({required String userId, required UserRole role}) async {
    try {
      final roleStr = role.name;
      await _client.rpc('apply_role_selection', params: {
        'p_role': roleStr,
      });
    } catch (e, stack) {
      AppLogger.e('Error adding new user role', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> updateSeekerType({required String userId, required SeekerType newType}) async {
    try {
      final typeStr = newType.name == 'partTime' ? 'part_time' : newType.name;
      await _client.from('worker_profiles').update({
        'seeker_type': typeStr,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);
    } catch (e, stack) {
      AppLogger.e('Error updating seeker type', e, stack);
      rethrow;
    }
  }

  @override
  Future<LinkedAccountsState> getLinkedAccounts() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return const LinkedAccountsState();

      final phone = user.phone;
      final isPhoneVerified = phone != null && phone.isNotEmpty;

      String? googleEmail;
      bool isGoogleLinked = false;

      final identities = user.identities ?? [];
      for (final identity in identities) {
        if (identity.provider == 'google') {
          isGoogleLinked = true;
          googleEmail = identity.identityData?['email'] as String? ?? user.email;
        }
      }

      return LinkedAccountsState(
        phone: phone,
        isPhoneVerified: isPhoneVerified,
        googleEmail: googleEmail,
        isGoogleLinked: isGoogleLinked,
      );
    } catch (e, stack) {
      AppLogger.e('Error getting linked accounts state', e, stack);
      return const LinkedAccountsState();
    }
  }

  @override
  Future<String> exportUserData() async {
    try {
      final res = await _client.rpc('export_user_data');
      return const JsonEncoder.withIndent('  ').convert(res);
    } catch (e, stack) {
      AppLogger.e('Error exporting user data', e, stack);
      throw const AppException.unknown('Failed to export account data.');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw const AppException.auth('User not authenticated');

      // Call delete-account Edge Function or fallback RPC
      try {
        await _client.functions.invoke('delete-account');
      } catch (_) {
        // Fallback if edge function unavailable in local mock
        await _client.rpc('anonymize_and_delete_user_data', params: {
          'p_target_user_id': user.id,
        });
      }

      await _client.auth.signOut();
    } catch (e, stack) {
      AppLogger.e('Error deleting user account', e, stack);
      rethrow;
    }
  }
}

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return SupabaseAccountRepository();
});

