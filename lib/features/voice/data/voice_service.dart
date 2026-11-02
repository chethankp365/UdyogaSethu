import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/supabase/edge_api.dart';
import 'package:udyogasethu/features/voice/domain/voice_intent.dart';
import 'package:udyogasethu/features/voice/intent/intent_engine.dart';

enum VoiceServiceState {
  idle,
  requestingPermission,
  listening,
  processing,
  thinking,
  speaking,
  error,
  cancelled,
  permissionDenied,
  permissionPermanentlyDenied,
  missingLanguagePack,
}

enum MicrophonePermissionState {
  granted,
  denied,
  permanentlyDenied,
}

enum TtsPlaybackStatus {
  playedNeural,
  playedDevice,
  voiceUnavailable,
  muted,
  failed,
}

class VoiceService {
  final stt.SpeechToText _speech;
  final FlutterTts _tts;
  final AudioPlayer _audioPlayer;
  final EdgeApiClient? edgeApi;

  bool _isSpeechInitialized = false;
  List<stt.LocaleName> availableLocales = [];
  double _currentSoundLevel = 0.0;
  bool _isMuted = false;
  bool _isStartingSession = false;
  bool _finalTranscriptCaptured = false;
  final StreamController<bool> _ttsSpeakingController = StreamController<bool>.broadcast();

  VoiceService({
    this.edgeApi,
    AudioPlayer? audioPlayer,
    stt.SpeechToText? speech,
    FlutterTts? tts,
    dynamic audioRecorder, // Ignored; prevents competing mic recording handles
  })  : _audioPlayer = audioPlayer ?? AudioPlayer(),
        _speech = speech ?? stt.SpeechToText(),
        _tts = tts ?? FlutterTts() {
    try {
      _audioPlayer.setReleaseMode(ReleaseMode.stop);
    } catch (_) {}

    try {
      _tts.setCompletionHandler(() {
        debugPrint('[VoiceService] Device TTS speech completed');
        _ttsSpeakingController.add(false);
      });
      _tts.setErrorHandler((msg) {
        debugPrint('[VoiceService] Device TTS speech error: $msg');
        _ttsSpeakingController.add(false);
      });
      _tts.setCancelHandler(() {
        _ttsSpeakingController.add(false);
      });
    } catch (_) {}
  }

  bool get isInitialized => _isSpeechInitialized;
  bool get isListening => _speech.isListening;
  double get soundLevel => _currentSoundLevel;
  bool get isMuted => _isMuted;
  Stream<PlayerState> get onPlayerStateChanged => _audioPlayer.onPlayerStateChanged;
  Stream<bool> get onTtsSpeakingChanged => _ttsSpeakingController.stream;

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      stopSpeaking();
    }
  }

  /// Map 2-letter app language code to speech BCP-47 locale
  static String getSpeechLocale(String langCode) {
    final code = langCode.toLowerCase().trim();
    if (code.startsWith('kn')) return 'kn_IN';
    if (code.startsWith('hi')) return 'hi_IN';
    if (code.startsWith('te')) return 'te_IN';
    if (code.startsWith('ta')) return 'ta_IN';
    if (code.startsWith('mr')) return 'mr_IN';
    if (code.startsWith('bn')) return 'bn_IN';
    if (code.startsWith('or')) return 'or_IN';
    return 'en_IN';
  }

  /// Map 2-letter app language code to TTS BCP-47 locale
  static String getTtsLocale(String langCode) {
    final code = langCode.toLowerCase().trim();
    if (code.startsWith('kn')) return 'kn-IN';
    if (code.startsWith('hi')) return 'hi-IN';
    if (code.startsWith('te')) return 'te-IN';
    if (code.startsWith('ta')) return 'ta-IN';
    if (code.startsWith('mr')) return 'mr-IN';
    if (code.startsWith('bn')) return 'bn-IN';
    if (code.startsWith('or')) return 'or-IN';
    return 'en-IN';
  }

  /// Request runtime microphone permission
  Future<MicrophonePermissionState> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      if (status.isGranted) {
        return MicrophonePermissionState.granted;
      }

      final requested = await Permission.microphone.request();
      if (requested.isGranted) {
        return MicrophonePermissionState.granted;
      } else if (requested.isPermanentlyDenied) {
        return MicrophonePermissionState.permanentlyDenied;
      } else {
        return MicrophonePermissionState.denied;
      }
    } catch (e) {
      debugPrint('[VoiceService] Permission request error: $e');
      return MicrophonePermissionState.denied;
    }
  }

  ValueChanged<String>? _currentStatusCallback;
  ValueChanged<String>? _currentErrorCallback;

  /// Initialize Speech-to-Text and TTS
  Future<bool> initialize() async {
    try {
      if (!_isSpeechInitialized) {
        final perm = await requestMicrophonePermission();
        if (perm != MicrophonePermissionState.granted) {
          debugPrint('[VoiceService] Cannot init speech: mic permission not granted ($perm)');
          return false;
        }

        _isSpeechInitialized = await _speech.initialize(
          onStatus: (status) {
            debugPrint('[VoiceService] STT Status: $status');
            _currentStatusCallback?.call(status);
          },
          onError: (errorNotification) {
            debugPrint('[VoiceService] STT Error: ${errorNotification.errorMsg}');
            // Filter out transient Android speech recognizer pauses and tear-down events so modal isn't abruptly closed
            if (errorNotification.errorMsg == 'error_no_match' ||
                errorNotification.errorMsg == 'error_speech_timeout' ||
                errorNotification.errorMsg == 'error_client' ||
                errorNotification.errorMsg == 'error_busy') {
              return;
            }
            _currentErrorCallback?.call(errorNotification.errorMsg);
          },
          debugLogging: kDebugMode,
        );

        if (_isSpeechInitialized) {
          availableLocales = await _speech.locales();
          debugPrint('[VoiceService] Available speech locales: ${availableLocales.length}');
        }
      }

      await _tts.setSpeechRate(0.50);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      return _isSpeechInitialized;
    } catch (e) {
      debugPrint('[VoiceService] Init exception: $e');
      return false;
    }
  }

  /// Checks whether the device native Speech-to-Text recognizer has a language pack
  /// for the specified language.
  bool isDeviceLocaleSupported(String langCode) {
    if (availableLocales.isEmpty) return true;
    final clean = langCode.toLowerCase().substring(0, 2);
    final preferred = getSpeechLocale(langCode).toLowerCase().replaceAll('-', '_');
    return availableLocales.any((loc) {
      final locId = loc.localeId.toLowerCase().replaceAll('-', '_');
      return locId == preferred || locId.startsWith(clean);
    });
  }

  /// Pick the best matching speech locale available on the device,
  /// or null if the device recognizer does not support the selected language.
  /// NEVER silently fall back to English for regional languages!
  String? resolveBestLocale(String langCode) {
    final clean = langCode.toLowerCase().substring(0, 2);
    final preferred = getSpeechLocale(langCode).toLowerCase().replaceAll('-', '_');

    if (availableLocales.isEmpty) {
      return clean == 'en' ? 'en_IN' : null;
    }

    final match = availableLocales.firstWhere(
      (loc) => loc.localeId.toLowerCase().replaceAll('-', '_') == preferred,
      orElse: () => availableLocales.firstWhere(
        (loc) => loc.localeId.toLowerCase().startsWith(clean),
        orElse: () => stt.LocaleName('', ''),
      ),
    );

    if (match.localeId.isNotEmpty) {
      return match.localeId;
    }

    return null;
  }

  /// Start listening for voice commands with live sound level & partial results.
  /// Uses coordinated, single-owner audio lifecycle without competing AudioRecorder.
  Future<bool> startListening({
    required String languageCode,
    required ValueChanged<String> onPartialResult,
    required ValueChanged<String> onFinalResult,
    required ValueChanged<double> onSoundLevelChange,
    required VoidCallback onError,
    ValueChanged<String>? onStatus,
  }) async {
    if (_isStartingSession) return false;
    _isStartingSession = true;

    try {
      // 1. Release any active TTS or audio playback before opening microphone
      await stopSpeaking();

      // 2. If SpeechToText was previously listening, stop and allow audio hardware to reset
      if (_speech.isListening) {
        try {
          await _speech.stop();
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 150));
      }

      // 3. Check and request microphone permission
      final perm = await requestMicrophonePermission();
      if (perm != MicrophonePermissionState.granted) {
        onError();
        return false;
      }

      // 4. Initialize if needed
      if (!_isSpeechInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          onError();
          return false;
        }
      }

      _currentStatusCallback = onStatus;
      _currentErrorCallback = (err) {
        onError();
      };
      _finalTranscriptCaptured = false;

      final speechLocale = resolveBestLocale(languageCode) ?? getSpeechLocale(languageCode);
      debugPrint('[VoiceService] Starting SpeechToText with locale: $speechLocale (isAvailable: ${_speech.isAvailable})');

      void handleResult(dynamic result) {
        if (result.finalResult) {
          if (!_finalTranscriptCaptured && result.recognizedWords.trim().isNotEmpty) {
            _finalTranscriptCaptured = true;
            onFinalResult(result.recognizedWords.trim());
          }
        } else {
          if (result.recognizedWords.trim().isNotEmpty) {
            onPartialResult(result.recognizedWords);
          }
        }
      }

      void handleSound(double level) {
        _currentSoundLevel = level;
        onSoundLevelChange(level);
      }

      bool started = false;
      try {
        // SpeechToText.listen returns Future<void> (dynamic null at runtime);
        // do not assign result to bool or Dart throws type 'Null' is not a subtype of type 'bool'.
        await _speech.listen(
          onResult: handleResult,
          onSoundLevelChange: handleSound,
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.confirmation,
            cancelOnError: false,
            partialResults: true,
            listenFor: const Duration(seconds: 30),
            pauseFor: const Duration(seconds: 5),
            localeId: speechLocale,
          ),
        );
        started = true;
      } catch (e) {
        debugPrint('[VoiceService] Speech listen error for locale $speechLocale: $e');
        started = false;
      }

      // If speech listen could not start with the regional locale (e.g. Android lacks kn_IN voice model),
      // retry with device default / en_IN recognizer so microphone session succeeds and user can speak!
      if (!started && speechLocale != 'en_IN') {
        debugPrint('[VoiceService] Retrying SpeechToText with fallback en_IN locale');
        try {
          await _speech.listen(
            onResult: handleResult,
            onSoundLevelChange: handleSound,
            listenOptions: stt.SpeechListenOptions(
              listenMode: stt.ListenMode.confirmation,
              cancelOnError: false,
              partialResults: true,
              listenFor: const Duration(seconds: 30),
              pauseFor: const Duration(seconds: 5),
              localeId: 'en_IN',
            ),
          );
          started = true;
        } catch (e) {
          debugPrint('[VoiceService] Fallback en_IN error: $e');
        }
      }

      // If still not started, try with device default locale (no localeId passed)
      if (!started) {
        debugPrint('[VoiceService] Retrying SpeechToText with device default locale');
        try {
          await _speech.listen(
            onResult: handleResult,
            onSoundLevelChange: handleSound,
            listenOptions: stt.SpeechListenOptions(
              listenMode: stt.ListenMode.confirmation,
              cancelOnError: false,
              partialResults: true,
              listenFor: const Duration(seconds: 30),
              pauseFor: const Duration(seconds: 5),
            ),
          );
          started = true;
        } catch (e) {
          debugPrint('[VoiceService] Device default listen error: $e');
        }
      }

      return started;
    } catch (e) {
      debugPrint('[VoiceService] startListening error: $e');
      onError();
      return false;
    } finally {
      _isStartingSession = false;
    }
  }

  /// Stops listening and returns any captured transcript.
  Future<String?> stopListeningAndTranscribe({
    required String languageCode,
    String? fallbackTranscript,
  }) async {
    await stopListening();
    if (fallbackTranscript != null && fallbackTranscript.trim().isNotEmpty) {
      return fallbackTranscript.trim();
    }
    return null;
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
      if (_speech.isListening) {
        await _speech.cancel();
      }
    } catch (_) {}
    _finalTranscriptCaptured = false;
  }

  /// Speak localized reply:
  /// - English: Deepgram Aura neural audio if provided, falling back to device English TTS.
  /// - Regional Indic languages: Verified language-compatible device TTS voice (isLanguageAvailable check).
  /// Never sends Indic text to English-only Aura!
  Future<TtsPlaybackStatus> speak(
    String text, {
    required String languageCode,
    String? audioBase64,
  }) async {
    if (_isMuted || text.trim().isEmpty) return TtsPlaybackStatus.muted;

    final cleanLang = languageCode.toLowerCase().substring(0, 2);

    // 1. English: Use Deepgram Aura neural audio if provided
    if (cleanLang == 'en') {
      if (audioBase64 != null && audioBase64.isNotEmpty) {
        try {
          final bytes = base64Decode(audioBase64);
          _ttsSpeakingController.add(true);
          await _audioPlayer.play(BytesSource(bytes));
          return TtsPlaybackStatus.playedNeural;
        } catch (e) {
          debugPrint('[VoiceService] Deepgram audio playback error: $e, falling back to device TTS');
        }
      }

      // Fallback to local on-device English TTS
      try {
        final ttsLocale = getTtsLocale(languageCode);
        await _tts.setLanguage(ttsLocale);
        _ttsSpeakingController.add(true);
        await _tts.speak(text);
        return TtsPlaybackStatus.playedDevice;
      } catch (e) {
        debugPrint('[VoiceService] English device TTS error: $e');
        _ttsSpeakingController.add(false);
        return TtsPlaybackStatus.failed;
      }
    }

    // 2. Regional Languages: Never send to English-only Aura!
    // Check if device TTS engine supports this regional language
    final ttsLocale = getTtsLocale(languageCode);
    try {
      final dynamic isAvailable = await _tts.isLanguageAvailable(ttsLocale);
      // isLanguageAvailable returns: 1 (LANG_AVAILABLE), 2 (LANG_COUNTRY_AVAILABLE), 3 (LANG_COUNTRY_VAR_AVAILABLE)
      if (isAvailable == 1 || isAvailable == 2 || isAvailable == 3 || isAvailable == true) {
        await _tts.setLanguage(ttsLocale);
        _ttsSpeakingController.add(true);
        await _tts.speak(text);
        return TtsPlaybackStatus.playedDevice;
      } else {
        debugPrint('[VoiceService] TTS language $ttsLocale is not available on device ($isAvailable)');
        return TtsPlaybackStatus.voiceUnavailable;
      }
    } catch (e) {
      debugPrint('[VoiceService] Regional TTS check/speak error: $e');
      return TtsPlaybackStatus.voiceUnavailable;
    }
  }

  /// Stop speaking immediately (cancels both Deepgram audio and TTS engine)
  Future<void> stopSpeaking() async {
    try {
      await _audioPlayer.stop();
      await _tts.stop();
    } catch (_) {}
    _ttsSpeakingController.add(false);
  }

  /// Process query through 5-Provider Orchestrated AI Assistant
  Future<VoiceIntentResult> queryAssistant({
    required String text,
    required String userRole,
    required String languageCode,
    List<Map<String, String>>? conversationHistory,
    String? preferredProvider,
  }) async {
    if (text.trim().isEmpty) {
      return VoiceIntentResult.unrecognized(text);
    }

    // 1. Try 5-Provider Orchestrator via ai-assist Edge Function
    if (edgeApi != null) {
      try {
        bool isOnline = true;
        try {
          final connectivity = await Connectivity().checkConnectivity();
          isOnline = connectivity.any((c) => c != ConnectivityResult.none);
        } catch (_) {
          isOnline = true;
        }

        if (isOnline) {
          final res = await edgeApi!.queryAssistant(
            query: text,
            role: userRole,
            language: languageCode,
            conversationHistory: conversationHistory,
            preferredProvider: preferredProvider,
          );

          final payload = res['data'] is Map<String, dynamic>
              ? res['data'] as Map<String, dynamic>
              : (res['data'] is Map ? Map<String, dynamic>.from(res['data'] as Map) : res);

          if ((payload['ok'] == true || payload['success'] == true) && payload['result'] is Map) {
            final resultData = Map<String, dynamic>.from(payload['result'] as Map);
            final intentCode = resultData['intent']?.toString();
            final replyText = resultData['reply_text']?.toString() ?? 'Here is what I found.';
            final rawParams = resultData['params'] is Map
                ? Map<String, dynamic>.from(resultData['params'] as Map)
                : <String, dynamic>{};
            final params = VoiceIntentParameters.fromJson(rawParams);

            final intentType = VoiceIntentTypeExtension.fromCode(intentCode);
            final route = _resolveSafeRoute(intentType, params: params, userRole: userRole);

            final provider = payload['provider_used']?.toString() ??
                payload['mode']?.toString() ??
                'groq';
            final model = payload['model_used']?.toString() ??
                payload['model']?.toString();
            final latencyMs = (payload['latency_ms'] as num?)?.toInt();
            final audioBase64 = payload['audio_base64']?.toString();
            final audioMime = payload['audio_mime']?.toString();
            final fallbackList = payload['fallback_chain'] is List
                ? (payload['fallback_chain'] as List).map((e) => e.toString()).toList()
                : null;

            return VoiceIntentResult(
              type: intentType,
              rawText: text,
              confidence: 0.95,
              parameters: params,
              targetRoute: route,
              spokenReply: replyText,
              isAiFallback: true,
              provider: provider,
              model: model,
              latencyMs: latencyMs,
              audioBase64: audioBase64,
              audioMime: audioMime,
              fallbackChain: fallbackList,
            );
          }
        }
      } catch (e) {
        debugPrint('[VoiceService] Orchestrated AI Assistant error: $e');
      }
    }

    // 2. Offline rule engine fallback
    final ruleResult = IntentEngine.parse(text, language: languageCode, userRole: userRole);
    return ruleResult;
  }

  /// Strictly resolve validated internal routes for recognized intent types
  String _resolveSafeRoute(
    VoiceIntentType type, {
    VoiceIntentParameters? params,
    required String userRole,
  }) {
    switch (type) {
      case VoiceIntentType.findJobs:
        final queryParams = <String>[];
        if (params?.category != null && params!.category!.isNotEmpty) {
          queryParams.add('category=${Uri.encodeComponent(params.category!)}');
        }
        if (params?.query != null && params!.query!.isNotEmpty) {
          queryParams.add('query=${Uri.encodeComponent(params.query!)}');
        }
        if (params?.minPrice != null && params!.minPrice! > 0) {
          queryParams.add('minWage=${params.minPrice}');
        }
        return queryParams.isNotEmpty
            ? '${AppRoutes.seekerJobs}?${queryParams.join('&')}'
            : AppRoutes.seekerJobs;

      case VoiceIntentType.findWorkers:
        return params?.category != null && params!.category!.isNotEmpty
            ? '${AppRoutes.providerWorkers}?category=${Uri.encodeComponent(params.category!)}'
            : AppRoutes.providerWorkers;

      case VoiceIntentType.searchProduce:
        return params?.produce != null && params!.produce!.isNotEmpty
            ? '/marketplace?search=${Uri.encodeComponent(params.produce!)}'
            : '/marketplace';

      case VoiceIntentType.checkEarnings:
      case VoiceIntentType.openWallet:
        return AppRoutes.wallet;

      case VoiceIntentType.openSafety:
        return AppRoutes.safetyHub;

      case VoiceIntentType.openProfile:
        if (userRole == 'farmer') return AppRoutes.farmerProfile;
        if (userRole == 'provider') return AppRoutes.providerProfile;
        return AppRoutes.seekerProfile;

      case VoiceIntentType.openSettings:
        return AppRoutes.settings;

      case VoiceIntentType.viewOrders:
        return userRole == 'farmer' ? AppRoutes.farmerOrders : AppRoutes.customerOrders;

      case VoiceIntentType.postJob:
        return AppRoutes.providerJobNew;

      case VoiceIntentType.checkMandi:
        return AppRoutes.farmerMarket;

      case VoiceIntentType.viewActiveJobs:
        return AppRoutes.seekerJobs;

      case VoiceIntentType.viewSchedule:
        return AppRoutes.workerSchedule;

      case VoiceIntentType.viewApplicants:
        return AppRoutes.providerHome;

      case VoiceIntentType.digitalId:
        return AppRoutes.digitalId;

      case VoiceIntentType.scanVerify:
        return AppRoutes.scanVerify;

      case VoiceIntentType.openChat:
        if (userRole == 'farmer') return AppRoutes.farmerChat;
        if (userRole == 'provider') return AppRoutes.providerChat;
        return AppRoutes.seekerChat;

      case VoiceIntentType.openNotifications:
        return AppRoutes.notifications;

      case VoiceIntentType.farmAi:
        return AppRoutes.farmerPestAi;

      case VoiceIntentType.goHome:
        if (userRole == 'farmer') return AppRoutes.farmerHome;
        if (userRole == 'provider') return AppRoutes.providerHome;
        return AppRoutes.seekerHome;

      case VoiceIntentType.viewFavourites:
        return AppRoutes.favourites;

      case VoiceIntentType.confirmSos:
        return 'confirm_sos';

      case VoiceIntentType.answerQuestion:
      case VoiceIntentType.unknown:
        return '';
    }
  }

  void dispose() {
    try {
      _speech.cancel();
    } catch (_) {}
    try {
      _tts.stop();
    } catch (_) {}
    try {
      _audioPlayer.dispose();
    } catch (_) {}
    _ttsSpeakingController.close();
  }
}

final voiceServiceProvider = Provider<VoiceService>((ref) {
  EdgeApiClient? edgeApi;
  try {
    edgeApi = ref.watch(edgeApiClientProvider);
  } catch (_) {}
  return VoiceService(edgeApi: edgeApi);
});
