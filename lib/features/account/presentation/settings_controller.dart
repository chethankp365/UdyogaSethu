import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/features/account/data/account_repository.dart';
import 'package:udyogasethu/features/account/domain/user_settings.dart';

class SettingsKeys {
  SettingsKeys._();
  static const String simpleMode = 'user_setting_simple_mode';
  static const String textScale = 'user_setting_text_scale';
  static const String voiceHints = 'user_setting_voice_hints';
  static const String lowDataMode = 'user_setting_low_data_mode';
  static const String language = 'selected_language';
}

/// Global State Notifier managing UserSettings reactively.
/// Updates reflect immediately across the entire widget tree (text scaling, simple mode, data saver).
class SettingsNotifier extends Notifier<UserSettings> {
  @override
  UserSettings build() {
    _loadFromLocal();
    return const UserSettings();
  }

  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final simpleMode = prefs.getBool(SettingsKeys.simpleMode) ?? false;
      final textScale = prefs.getDouble(SettingsKeys.textScale) ?? 1.00;
      final voiceHints = prefs.getBool(SettingsKeys.voiceHints) ?? true;
      final lowDataMode = prefs.getBool(SettingsKeys.lowDataMode) ?? false;
      final lang = prefs.getString(SettingsKeys.language) ?? 'en';

      state = UserSettings(
        language: lang,
        simpleMode: simpleMode,
        textScale: textScale.clamp(0.85, 1.60),
        voiceHints: voiceHints,
        lowDataMode: lowDataMode,
      );

      // Next, if user is logged in, sync with remote profile
      _syncFromRemote();
    } catch (e) {
      AppLogger.w('Failed loading local user settings: $e');
    }
  }

  Future<void> _syncFromRemote() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final remote = await ref.read(accountRepositoryProvider).loadSettings(user.id);
        state = remote.copyWith(
          textScale: remote.textScale.clamp(0.85, 1.60),
        );
        _persistLocal(state);
      }
    } catch (_) {}
  }

  Future<void> _persistLocal(UserSettings s) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(SettingsKeys.simpleMode, s.simpleMode);
      await prefs.setDouble(SettingsKeys.textScale, s.textScale);
      await prefs.setBool(SettingsKeys.voiceHints, s.voiceHints);
      await prefs.setBool(SettingsKeys.lowDataMode, s.lowDataMode);
    } catch (_) {}
  }

  Future<void> updateSettings(UserSettings updated) async {
    final clamped = updated.copyWith(
      textScale: updated.textScale.clamp(0.85, 1.60),
    );
    state = clamped;
    await _persistLocal(clamped);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await ref.read(accountRepositoryProvider).saveSettings(
              userId: user.id,
              settings: clamped,
            );
      }
    } catch (e) {
      AppLogger.w('Could not write settings to Supabase: $e');
    }
  }

  Future<void> setSimpleMode(bool enabled) async {
    await updateSettings(state.copyWith(simpleMode: enabled));
  }

  Future<void> setTextScale(double scale) async {
    await updateSettings(state.copyWith(textScale: scale.clamp(0.85, 1.60)));
  }

  Future<void> setVoiceHints(bool enabled) async {
    await updateSettings(state.copyWith(voiceHints: enabled));
  }

  Future<void> setLowDataMode(bool enabled) async {
    await updateSettings(state.copyWith(lowDataMode: enabled));
  }
}

final userSettingsNotifierProvider =
    NotifierProvider<SettingsNotifier, UserSettings>(SettingsNotifier.new);
