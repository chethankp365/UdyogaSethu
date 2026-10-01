import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/supabase/supabase_service.dart';
import 'package:udyogasethu/features/onboarding/data/bootstrap_service.dart';

/// Supported application language metadata model.
class AppLanguageOption {
  final String code; // e.g. 'en', 'kn'
  final String countryCode; // e.g. 'GB', 'IN'
  final String nativeName; // e.g. 'ಕನ್ನಡ'
  final String englishName; // e.g. 'Kannada'
  final String welcomeText; // Text sentence spoken by TTS

  const AppLanguageOption({
    required this.code,
    required this.countryCode,
    required this.nativeName,
    required this.englishName,
    required this.welcomeText,
  });

  Locale get locale => Locale(code);
}

/// The 8 supported application languages.
class AppLanguages {
  AppLanguages._();

  static const AppLanguageOption english = AppLanguageOption(
    code: 'en',
    countryCode: 'GB',
    nativeName: 'English',
    englishName: 'English',
    welcomeText: 'Welcome to UdyogaSethu. Connecting work and empowering lives.',
  );

  static const AppLanguageOption kannada = AppLanguageOption(
    code: 'kn',
    countryCode: 'IN',
    nativeName: 'ಕನ್ನಡ',
    englishName: 'Kannada',
    welcomeText: 'ಉದ್ಯೋಗಸೇತುಗೆ ಸುಸ್ವಾಗತ. ಕೆಲಸವನ್ನು ಜೋಡಿಸಿ ಬಾಳನ್ನು ಸಬಲಗೊಳಿಸುತ್ತಿದ್ದೇವೆ.',
  );

  static const AppLanguageOption hindi = AppLanguageOption(
    code: 'hi',
    countryCode: 'IN',
    nativeName: 'हिंदी',
    englishName: 'Hindi',
    welcomeText: 'उद्योगसेतु में आपका स्वागत है। काम जोड़ना और जीवन सशक्त बनाना।',
  );

  static const AppLanguageOption telugu = AppLanguageOption(
    code: 'te',
    countryCode: 'IN',
    nativeName: 'తెలుగు',
    englishName: 'Telugu',
    welcomeText: 'ఉద్యోగసేతుకు స్వాగతం. పనిని అనుసంధానిస్తూ జీవితాలను సాధికారం చేయడం.',
  );

  static const AppLanguageOption tamil = AppLanguageOption(
    code: 'ta',
    countryCode: 'IN',
    nativeName: 'தமிழ்',
    englishName: 'Tamil',
    welcomeText: 'உத்யோகசேதுவிற்கு நல்வரவு. வேலையை இணைத்து வாழ்க்கையை வளப்படுத்துகிறோம்.',
  );

  static const AppLanguageOption marathi = AppLanguageOption(
    code: 'mr',
    countryCode: 'IN',
    nativeName: 'मराठी',
    englishName: 'Marathi',
    welcomeText: 'Welcome to UdyogaSethu in Marathi.',
  );

  static const AppLanguageOption bengali = AppLanguageOption(
    code: 'bn',
    countryCode: 'IN',
    nativeName: 'বাংলা',
    englishName: 'Bengali',
    welcomeText: 'Welcome to UdyogaSethu in Bengali.',
  );

  static const AppLanguageOption odia = AppLanguageOption(
    code: 'or',
    countryCode: 'IN',
    nativeName: 'ଓଡ଼ିଆ',
    englishName: 'Odia',
    welcomeText: 'Welcome to UdyogaSethu in Odia.',
  );

  static const List<AppLanguageOption> all = [
    english,
    kannada,
    hindi,
    telugu,
    tamil,
    marathi,
    bengali,
    odia,
  ];

  static AppLanguageOption fromCode(String code) {
    return all.firstWhere(
      (lang) => lang.code == code,
      orElse: () => english,
    );
  }
}

/// Notifier managing current active locale, persisting to SharedPreferences & Supabase.
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    _loadInitialLocale();
    return const Locale('en');
  }

  Future<void> _loadInitialLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(SharedPrefKeys.selectedLanguage);
      if (savedCode != null && savedCode.isNotEmpty) {
        state = Locale(savedCode);
      }
    } catch (_) {
      // Fallback to default English
    }
  }

  /// Changes application locale live and persists selection.
  Future<void> setLocale(String languageCode) async {
    state = Locale(languageCode);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(SharedPrefKeys.selectedLanguage, languageCode);
    } catch (_) {}

    // Synchronize to profiles table if signed in
    try {
      final supabase = ref.read(supabaseClientProvider);
      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        await supabase.from('profiles').update({
          'language': languageCode,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', currentUser.id);
      }
    } catch (err) {
      AppLogger.w('Could not write language to Supabase profile: $err');
    }
  }
}

/// Global provider for application locale state.
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
