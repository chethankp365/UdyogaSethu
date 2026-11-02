import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:udyogasethu/core/supabase/edge_api.dart';
import 'package:udyogasethu/features/voice/data/voice_service.dart';
import 'package:udyogasethu/features/voice/domain/voice_intent.dart';

// ---------------------------------------------------------------------------
// Mock Implementations for Voice Pipeline Components
// ---------------------------------------------------------------------------

class MockEdgeApiClient implements EdgeApiClient {
  final Map<String, dynamic> Function(String method, Map<String, dynamic> params)? onCall;
  final List<Map<String, dynamic>> transcribeCalls = [];
  final List<Map<String, dynamic>> queryCalls = [];

  MockEdgeApiClient({this.onCall});

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #voiceTranscribe) {
      final namedArgs = invocation.namedArguments;
      final callData = {
        'audioBase64': namedArgs[#audioBase64] as String?,
        'mimeType': namedArgs[#mimeType] as String?,
        'language': namedArgs[#language] as String?,
      };
      transcribeCalls.add(callData);

      if (onCall != null) {
        return Future.value(onCall!('voiceTranscribe', callData));
      }
      return Future.value({
        'ok': true,
        'mode': 'groq',
        'model': 'whisper-large-v3-turbo',
        'result': {
          'transcript': 'ಪ್ಲಂಬರ್ ಕೆಲಸ ಬೇಕು',
        },
      });
    }

    if (invocation.memberName == #queryAssistant) {
      final namedArgs = invocation.namedArguments;
      final callData = {
        'query': namedArgs[#query] as String?,
        'role': namedArgs[#role] as String?,
        'language': namedArgs[#language] as String?,
      };
      queryCalls.add(callData);

      if (onCall != null) {
        return Future.value(onCall!('queryAssistant', callData));
      }

      return Future.value({
        'ok': true,
        'mode': 'groq',
        'model': 'llama-3.1-8b-instant',
        'result': {
          'reply_text': 'ಖಂಡಿತ, ನಿಮ್ಮ ಸಮೀಪದಲ್ಲಿರುವ ಪ್ಲಂಬರ್ ಕೆಲಸಗಳು ಇಲ್ಲಿವೆ.',
          'intent': 'find_jobs',
          'params': {'category': 'plumber'},
        },
      });
    }

    return super.noSuchMethod(invocation);
  }
}

class MockAudioRecorder implements AudioRecorder {
  bool recordingState = false;
  bool isDisposed = false;
  bool wasCancelled = false;
  String? lastStartedPath;
  RecordConfig? lastConfig;

  @override
  Future<bool> isRecording() async => recordingState;

  @override
  Future<void> start(RecordConfig config, {required String path}) async {
    recordingState = true;
    wasCancelled = false;
    lastStartedPath = path;
    lastConfig = config;
    // Create dummy file so File(path).exists() returns true and has dummy bytes
    final f = File(path);
    await f.writeAsBytes(Uint8List.fromList(List.generate(1024, (i) => i % 256)));
  }

  @override
  Future<String?> stop() async {
    recordingState = false;
    return lastStartedPath;
  }

  @override
  Future<void> cancel() async {
    recordingState = false;
    wasCancelled = true;
  }

  @override
  Future<void> dispose() async {
    isDisposed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFlutterTts implements FlutterTts {
  String? currentLanguage;
  String? lastSpokenText;
  int isLanguageAvailableReturn = 1; // 1 = available, 0 = unavailable
  int speakCount = 0;
  int stopCount = 0;

  @override
  Future<dynamic> setLanguage(String language) async {
    currentLanguage = language;
    return 1;
  }

  @override
  Future<dynamic> isLanguageAvailable(String language) async {
    return isLanguageAvailableReturn;
  }

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    lastSpokenText = text;
    speakCount++;
    return 1;
  }

  @override
  Future<dynamic> stop() async {
    stopCount++;
    return 1;
  }

  @override
  void setCompletionHandler(VoidCallback callback) {}

  @override
  void setErrorHandler(ErrorHandler handler) {}

  @override
  void setCancelHandler(VoidCallback callback) {}

  @override
  void setStartHandler(VoidCallback callback) {}

  @override
  Future<dynamic> setSpeechRate(double rate) async => 1;
  @override
  Future<dynamic> setVolume(double volume) async => 1;
  @override
  Future<dynamic> setPitch(double pitch) async => 1;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAudioPlayer implements AudioPlayer {
  bool isPlaying = false;
  bool isDisposed = false;
  Source? lastPlayedSource;
  int stopCount = 0;

  @override
  Future<void> play(Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    isPlaying = true;
    lastPlayedSource = source;
  }

  @override
  Future<void> stop() async {
    isPlaying = false;
    stopCount++;
  }

  @override
  Future<void> dispose() async {
    isDisposed = true;
  }

  @override
  Future<void> setReleaseMode(ReleaseMode releaseMode) async {}

  @override
  Stream<PlayerState> get onPlayerStateChanged => Stream.value(PlayerState.completed);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter.baseflow.com/permissions/methods'), (call) async {
      if (call.method == 'checkPermissionStatus' || call.method == 'requestPermissions') {
        return 1; // PermissionStatus.granted
      }
      return 1;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers.global'), (call) async => 1);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), (call) async => 1);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/connectivity'), (call) async => ['wifi']);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.llfbandit.record/messages'), (call) async => null);
  });

  group('Voice Multilingual Pipeline - Section 8 Test Suite', () {
    // -------------------------------------------------------------------------
    // 1. All eight locale mappings
    // -------------------------------------------------------------------------
    test('1. Maps all 8 supported languages to correct BCP-47 speech and TTS locales', () {
      final languages = ['en', 'kn', 'hi', 'te', 'ta', 'mr', 'bn', 'or'];

      final expectedSpeech = {
        'en': 'en_IN',
        'kn': 'kn_IN',
        'hi': 'hi_IN',
        'te': 'te_IN',
        'ta': 'ta_IN',
        'mr': 'mr_IN',
        'bn': 'bn_IN',
        'or': 'or_IN',
      };

      final expectedTts = {
        'en': 'en-IN',
        'kn': 'kn-IN',
        'hi': 'hi-IN',
        'te': 'te-IN',
        'ta': 'ta-IN',
        'mr': 'mr-IN',
        'bn': 'bn-IN',
        'or': 'or-IN',
      };

      for (final lang in languages) {
        expect(VoiceService.getSpeechLocale(lang), expectedSpeech[lang],
            reason: 'Speech locale mapping failed for $lang');
        expect(VoiceService.getTtsLocale(lang), expectedTts[lang],
            reason: 'TTS locale mapping failed for $lang');
      }
    });

    // -------------------------------------------------------------------------
    // 2. No silent fallback from a regional language to English
    // -------------------------------------------------------------------------
    test('2. Never silently replaces a regional language with English when pack is missing', () {
      final mockRecorder = MockAudioRecorder();
      final mockTts = MockFlutterTts();
      final mockPlayer = MockAudioPlayer();

      final service = VoiceService(
        audioRecorder: mockRecorder,
        tts: mockTts,
        audioPlayer: mockPlayer,
      );

      // Suppose device recognizer only has en_US and en_IN installed
      service.availableLocales = [
        stt.LocaleName('en_US', 'English (US)'),
        stt.LocaleName('en_IN', 'English (India)'),
      ];

      // Kannada, Telugu, Tamil, Marathi, Bengali, Odia must NOT return English!
      expect(service.resolveBestLocale('kn'), isNull);
      expect(service.resolveBestLocale('te'), isNull);
      expect(service.resolveBestLocale('ta'), isNull);
      expect(service.resolveBestLocale('mr'), isNull);
      expect(service.resolveBestLocale('bn'), isNull);
      expect(service.resolveBestLocale('or'), isNull);

      // English should correctly resolve to en_IN
      expect(service.resolveBestLocale('en'), equals('en_IN'));

      // If Kannada is installed, it resolves kn_IN
      service.availableLocales = [
        stt.LocaleName('en_IN', 'English (India)'),
        stt.LocaleName('kn_IN', 'Kannada (India)'),
      ];
      expect(service.resolveBestLocale('kn'), equals('kn_IN'));
      expect(service.isDeviceLocaleSupported('kn'), isTrue);
      expect(service.isDeviceLocaleSupported('te'), isFalse);
    });

    // -------------------------------------------------------------------------
    // 3. Device STT success path
    // -------------------------------------------------------------------------
    test('3. Device STT success returns device transcript without competing audio recording', () async {
      final mockApi = MockEdgeApiClient();

      final service = VoiceService(
        edgeApi: mockApi,
      );

      // When device STT produces a valid final transcript
      final result = await service.stopListeningAndTranscribe(
        languageCode: 'kn',
        fallbackTranscript: 'ನನಗೆ ಕೆಲಸ ಬೇಕು',
      );

      expect(result, 'ನನಗೆ ಕೆಲಸ ಬೇಕು');
      // Must NOT invoke cloud STT since device STT already succeeded
      expect(mockApi.transcribeCalls.length, 0);
    });

    // -------------------------------------------------------------------------
    // 4. Device STT returns null when no transcript is captured
    // -------------------------------------------------------------------------
    test('4. Empty fallback transcript returns null cleanly', () async {
      final mockApi = MockEdgeApiClient();

      final service = VoiceService(
        edgeApi: mockApi,
      );

      // Stop listening with NO device transcript (e.g., silence or noise)
      final result = await service.stopListeningAndTranscribe(
        languageCode: 'kn',
        fallbackTranscript: null,
      );

      expect(result, isNull);
    });

    // -------------------------------------------------------------------------
    // 5. Empty transcription handling
    // -------------------------------------------------------------------------
    test('5. Returns null when both device STT and cloud STT return empty', () async {
      final mockRecorder = MockAudioRecorder();
      final mockApi = MockEdgeApiClient(onCall: (method, params) {
        return {
          'ok': true,
          'mode': 'groq',
          'result': {
            'transcript': '   ', // Empty transcript
          },
        };
      });

      final service = VoiceService(
        audioRecorder: mockRecorder,
        edgeApi: mockApi,
      );

      await service.startListening(
        languageCode: 'hi',
        onPartialResult: (_) {},
        onFinalResult: (_) {},
        onSoundLevelChange: (_) {},
        onError: () {},
      );

      final result = await service.stopListeningAndTranscribe(
        languageCode: 'hi',
        fallbackTranscript: '',
      );

      expect(result, isNull);
    });

    // -------------------------------------------------------------------------
    // 6. Correct language passed to Edge Function in queryAssistant
    // -------------------------------------------------------------------------
    test('6. Passes exact selected language and user role to Edge Function queryAssistant', () async {
      final mockApi = MockEdgeApiClient();
      final service = VoiceService(edgeApi: mockApi);

      await service.queryAssistant(
        text: 'ಟೊಮೆಟೊ ಬೆಲೆ ಎಷ್ಟು',
        userRole: 'farmer',
        languageCode: 'kn',
      );

      expect(mockApi.queryCalls.length, 1);
      final call = mockApi.queryCalls.first;
      expect(call['query'], 'ಟೊಮೆಟೊ ಬೆಲೆ ಎಷ್ಟು');
      expect(call['role'], 'farmer');
      expect(call['language'], 'kn');
    });

    // -------------------------------------------------------------------------
    // 7. Regional-language TTS routing (Never sends Indic to English Aura)
    // -------------------------------------------------------------------------
    test('7. Regional languages route to device TTS and never play English Aura audio', () async {
      final mockTts = MockFlutterTts();
      final mockPlayer = MockAudioPlayer();

      final service = VoiceService(
        tts: mockTts,
        audioPlayer: mockPlayer,
      );

      // Even if neural audioBase64 is passed, regional language MUST NOT send to Aura audio player
      final status = await service.speak(
        'ಖಂಡಿತ, ನಿಮ್ಮ ಸಮೀಪದಲ್ಲಿರುವ ಕೆಲಸಗಳು ಇಲ್ಲಿವೆ.',
        languageCode: 'kn',
        audioBase64: base64Encode([0, 1, 2, 3]), // English aura bytes must be ignored
      );

      expect(status, TtsPlaybackStatus.playedDevice);
      expect(mockPlayer.isPlaying, isFalse); // AudioPlayer NOT used!
      expect(mockTts.currentLanguage, 'kn-IN');
      expect(mockTts.lastSpokenText, 'ಖಂಡಿತ, ನಿಮ್ಮ ಸಮೀಪದಲ್ಲಿರುವ ಕೆಲಸಗಳು ಇಲ್ಲಿವೆ.');
      expect(mockTts.speakCount, 1);
    });

    // -------------------------------------------------------------------------
    // 8. Missing TTS voice handling
    // -------------------------------------------------------------------------
    test('8. Returns voiceUnavailable when device lacks TTS voice for regional language', () async {
      final mockTts = MockFlutterTts();
      mockTts.isLanguageAvailableReturn = 0; // Device TTS voice not installed!

      final service = VoiceService(tts: mockTts);

      final status = await service.speak(
        'ଓଡ଼ିଆ କଥାବାର୍ତ୍ତା',
        languageCode: 'or',
      );

      expect(status, TtsPlaybackStatus.voiceUnavailable);
      expect(mockTts.speakCount, 0); // Did not attempt unplayable speech
    });

    // -------------------------------------------------------------------------
    // 9. English TTS behavior (Neural Aura priority with local fallback)
    // -------------------------------------------------------------------------
    test('9. English uses Deepgram Aura neural audio when available, falls back to device TTS', () async {
      final mockTts = MockFlutterTts();
      final mockPlayer = MockAudioPlayer();

      final service = VoiceService(
        tts: mockTts,
        audioPlayer: mockPlayer,
      );

      // Case A: Neural audio bytes provided
      final statusWithAudio = await service.speak(
        'Here are the available jobs.',
        languageCode: 'en',
        audioBase64: base64Encode([1, 2, 3, 4, 5]),
      );

      expect(statusWithAudio, TtsPlaybackStatus.playedNeural);
      expect(mockPlayer.isPlaying, isTrue);
      expect(mockTts.speakCount, 0);

      // Case B: No neural audio bytes (offline or provider failure)
      final statusWithoutAudio = await service.speak(
        'Here are the available jobs.',
        languageCode: 'en',
        audioBase64: null,
      );

      expect(statusWithoutAudio, TtsPlaybackStatus.playedDevice);
      expect(mockTts.currentLanguage, 'en-IN');
      expect(mockTts.speakCount, 1);
    });

    // -------------------------------------------------------------------------
    // 10. Cancellation and disposal of audio resources
    // -------------------------------------------------------------------------
    test('10. Cancellation and disposal properly release all audio and playback handles', () async {
      final mockPlayer = MockAudioPlayer();
      final mockTts = MockFlutterTts();

      final service = VoiceService(
        audioPlayer: mockPlayer,
        tts: mockTts,
      );

      // Cancel listening
      await service.cancelListening();

      // Dispose
      service.dispose();
      expect(mockPlayer.isDisposed, isTrue);
    });

    // -------------------------------------------------------------------------
    // 11. Offline Rule Engine Fallback when Edge API is null or offline
    // -------------------------------------------------------------------------
    test('11. Falls back to offline IntentEngine when Edge API unavailable', () async {
      final service = VoiceService(edgeApi: null);

      final result = await service.queryAssistant(
        text: 'ನನ್ನ ವಾಲೆಟ್ ಬ್ಯಾಲೆನ್ಸ್ ನೋಡಿ',
        userRole: 'seeker',
        languageCode: 'kn',
      );

      expect(result.type, VoiceIntentType.openWallet);
      expect(result.targetRoute, '/wallet');
      expect(result.spokenReply, isNotEmpty);
    });

    // -------------------------------------------------------------------------
    // 12. Mute functionality stops active playback immediately
    // -------------------------------------------------------------------------
    test('12. Muting stops active playback and blocks future speech', () async {
      final mockPlayer = MockAudioPlayer();
      final mockTts = MockFlutterTts();

      final service = VoiceService(
        audioPlayer: mockPlayer,
        tts: mockTts,
      );

      expect(service.isMuted, isFalse);
      service.toggleMute();
      expect(service.isMuted, isTrue);
      await service.stopSpeaking();
      expect(mockPlayer.stopCount, greaterThanOrEqualTo(1));
      expect(mockTts.stopCount, greaterThanOrEqualTo(1));

      final status = await service.speak('Hello', languageCode: 'en');
      expect(status, TtsPlaybackStatus.muted);
    });
  });
}
