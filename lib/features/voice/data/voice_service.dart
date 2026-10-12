import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:udyogasethu/core/supabase/edge_api.dart';
import 'package:udyogasethu/features/voice/domain/voice_intent.dart';
import 'package:udyogasethu/features/voice/intent/intent_engine.dart';

enum VoiceServiceState {
  idle,
  listening,
  processing,
  recognized,
  error,
  permissionDenied,
  missingLanguagePack,
}

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final EdgeApiClient? edgeApi;

  bool _isSpeechInitialized = false;
  List<stt.LocaleName> _availableLocales = [];

  VoiceService({this.edgeApi});

  bool get isInitialized => _isSpeechInitialized;
  bool get isListening => _speech.isListening;

  /// Map 2-letter app language code to speech/TTS BCP-47 locale
  static String getSpeechLocale(String langCode) {
    if (langCode.startsWith('kn')) return 'kn_IN';
    if (langCode.startsWith('hi')) return 'hi_IN';
    if (langCode.startsWith('te')) return 'te_IN';
    if (langCode.startsWith('ta')) return 'ta_IN';
    return 'en_IN';
  }

  static String getTtsLocale(String langCode) {
    if (langCode.startsWith('kn')) return 'kn-IN';
    if (langCode.startsWith('hi')) return 'hi-IN';
    if (langCode.startsWith('te')) return 'te-IN';
    if (langCode.startsWith('ta')) return 'ta-IN';
    return 'en-IN';
  }

  /// Initialize Speech-to-Text and TTS
  Future<bool> initialize() async {
    try {
      if (!_isSpeechInitialized) {
        _isSpeechInitialized = await _speech.initialize(
          onStatus: (status) => debugPrint('[VoiceService] Status: $status'),
          onError: (errorNotification) => debugPrint('[VoiceService] Error: ${errorNotification.errorMsg}'),
          debugLogging: kDebugMode,
        );

        if (_isSpeechInitialized) {
          _availableLocales = await _speech.locales();
        }
      }

      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      return _isSpeechInitialized;
    } catch (e) {
      debugPrint('[VoiceService] Init exception: $e');
      return false;
    }
  }

  /// Check whether the device has voice recognition for the selected language
  bool isLocaleSupported(String langCode) {
    if (_availableLocales.isEmpty) return true; // Assume supported if not queried yet
    final target = getSpeechLocale(langCode).toLowerCase().replaceAll('-', '_');
    final short = langCode.substring(0, 2).toLowerCase();

    return _availableLocales.any((loc) {
      final locId = loc.localeId.toLowerCase().replaceAll('-', '_');
      return locId.contains(target) || locId.startsWith(short);
    });
  }

  /// Start listening for voice commands
  Future<bool> startListening({
    required String languageCode,
    required ValueChanged<String> onPartialResult,
    required ValueChanged<String> onFinalResult,
    required VoidCallback onError,
  }) async {
    try {
      if (!_isSpeechInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          onError();
          return false;
        }
      }

      final speechLocale = getSpeechLocale(languageCode);

      return await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onFinalResult(result.recognizedWords);
          } else {
            onPartialResult(result.recognizedWords);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: true,
          partialResults: true,
          listenFor: const Duration(seconds: 12),
          pauseFor: const Duration(seconds: 3),
          localeId: speechLocale,
        ),
      );
    } catch (e) {
      debugPrint('[VoiceService] Listen error: $e');
      onError();
      return false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (_) {}
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    try {
      await _speech.cancel();
    } catch (_) {}
  }

  /// Speak localized reply
  Future<void> speak(String text, {required String languageCode}) async {
    try {
      if (text.trim().isEmpty) return;
      final ttsLocale = getTtsLocale(languageCode);
      await _tts.setLanguage(ttsLocale);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('[VoiceService] TTS speak error: $e');
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// Parse intent with offline rule engine first, then optional Gemini fallback when online
  Future<VoiceIntentResult> classify({
    required String text,
    required String languageCode,
  }) async {
    // 1. Run local pure-Dart offline intent engine
    final ruleResult = IntentEngine.parse(text, language: languageCode);

    // If recognized by rule engine, return immediately (fast & offline)
    if (ruleResult.isRecognized) {
      return ruleResult;
    }

    // 2. Optional Gemini fallback only when online and rule engine returned unrecognized
    if (edgeApi != null) {
      try {
        final connectivity = await Connectivity().checkConnectivity();
        final isOnline = connectivity.any((c) => c != ConnectivityResult.none);

        if (isOnline) {
          final res = await edgeApi!.classifyVoiceIntent(
            spokenText: text,
            language: languageCode,
          );

          final resultObj = res['result'] as Map<String, dynamic>? ?? res;
          final intentStr = resultObj['intent'] as String?;
          final parsedType = VoiceIntentTypeExtension.fromCode(intentStr);

          // Strictly validate against allowed enum: NEVER execute free-form model output
          if (parsedType != VoiceIntentType.unknown) {
            final category = resultObj['category'] as String?;
            final produce = resultObj['produce'] as String?;
            final route = _resolveSafeRoute(parsedType, category: category, produce: produce);
            final spokenReply = (resultObj['spoken_reply'] as String?) ??
                ruleResult.spokenReply;

            return VoiceIntentResult(
              type: parsedType,
              rawText: text,
              confidence: 0.85,
              parameters: VoiceIntentParameters(category: category, produce: produce),
              targetRoute: route,
              spokenReply: spokenReply,
              isAiFallback: true,
            );
          }
        }
      } catch (e) {
        debugPrint('[VoiceService] Gemini fallback exception: $e');
      }
    }

    // Return the unrecognized rule result
    return ruleResult;
  }

  /// Strictly resolve validated internal routes for recognized intent types
  String _resolveSafeRoute(VoiceIntentType type, {String? category, String? produce}) {
    switch (type) {
      case VoiceIntentType.findJobs:
        return category != null && category.isNotEmpty ? '/jobs?category=$category' : '/jobs';
      case VoiceIntentType.findWorkers:
        return category != null && category.isNotEmpty ? '/provider/workers?category=$category' : '/provider/workers';
      case VoiceIntentType.searchProduce:
        return produce != null && produce.isNotEmpty ? '/marketplace?search=$produce' : '/marketplace';
      case VoiceIntentType.checkEarnings:
      case VoiceIntentType.openWallet:
        return '/wallet';
      case VoiceIntentType.openSafety:
        return '/safety/hub';
      case VoiceIntentType.openSettings:
        return '/settings';
      case VoiceIntentType.viewOrders:
        return '/marketplace';
      case VoiceIntentType.unknown:
        return '';
    }
  }
}

final voiceServiceProvider = Provider<VoiceService>((ref) {
  EdgeApiClient? edgeApi;
  try {
    edgeApi = ref.watch(edgeApiClientProvider);
  } catch (_) {}
  return VoiceService(edgeApi: edgeApi);
});
