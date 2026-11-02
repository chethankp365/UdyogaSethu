import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:udyogasethu/core/supabase/edge_api.dart';
import 'package:udyogasethu/features/voice/data/voice_service.dart';
import 'package:udyogasethu/features/voice/domain/voice_intent.dart';

// ---------------------------------------------------------------------------
// Mock Implementations for 8-Language End-to-End Test Matrix
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
          'transcript': 'Mock transcript for ${namedArgs[#language]}',
        },
      });
    }

    if (invocation.memberName == #queryAssistant) {
      final namedArgs = invocation.namedArguments;
      final callData = {
        'query': namedArgs[#query] as String?,
        'role': namedArgs[#role] as String?,
        'language': namedArgs[#language] as String?,
        'conversationHistory': namedArgs[#conversationHistory] as List<dynamic>?,
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
          'reply_text': 'Response in ${namedArgs[#language]}',
          'intent': 'answer_question',
          'params': {},
        },
      });
    }

    return super.noSuchMethod(invocation);
  }
}

class MockAudioRecorder implements AudioRecorder {
  bool recordingState = false;
  bool isDisposed = false;
  String? lastStartedPath;
  RecordConfig? lastConfig;

  @override
  Future<bool> isRecording() async => recordingState;

  @override
  Future<void> start(RecordConfig config, {required String path}) async {
    recordingState = true;
    lastStartedPath = path;
    lastConfig = config;
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
  int isLanguageAvailableReturn = 1;
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
  Source? lastPlayedSource;

  @override
  Future<void> play(
    Source source, {
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
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<void> setReleaseMode(ReleaseMode releaseMode) async {}

  @override
  Stream<PlayerState> get onPlayerStateChanged => Stream.value(PlayerState.completed);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// 8-Language Test Matrix Suite
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter.baseflow.com/permissions/methods'), (call) async => 1);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers.global'), (call) async => 1);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), (call) async => 1);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/connectivity'), (call) async => ['wifi']);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.llfbandit.record/messages'), (call) async => null);
  });

  group('Phase 4: 8-Language End-to-End Validation Matrix', () {
    const languageMatrix = [
      {
        'code': 'en',
        'name': 'English',
        'bcp47': 'en-IN',
        'greeting': 'Hello, good morning',
        'greetingReply': 'Good morning! How can I assist you with jobs, workers, or produce today?',
        'question': 'How can I register as a skilled mason?',
        'questionReply': 'You can complete your profile wizard and add your masonry certificates in the Seeker tab.',
        'jobQuery': 'Find carpentry and plumbing jobs near me',
        'jobCategory': 'plumber',
        'expectedRoute': '/jobs',
        'mandiQuery': 'What is the current mandi price for fresh tomatoes?',
        'produce': 'tomato',
        'mandiRoute': '/marketplace',
        'longUtterance': 'I need an urgent plumber in Whitefield for pipe fixing work paying at least 800 rupees per day today',
        'codeMixed': 'Plumber job idheya near me today?',
      },
      {
        'code': 'hi',
        'name': 'Hindi',
        'bcp47': 'hi-IN',
        'greeting': 'नमस्ते, सुप्रभात',
        'greetingReply': 'नमस्ते! उद्योगसेतु में आपका स्वागत है। मैं आपकी क्या मदद कर सकता हूँ?',
        'question': 'मैं अपना बैंक खाता कैसे जोड़ूं?',
        'questionReply': 'आप वॉलेट में जाकर बैंक विवरण और यूपीआई आईडी सुरक्षित रूप से जोड़ सकते हैं।',
        'jobQuery': 'मुझे बढ़ई और प्लंबर का काम चाहिए',
        'jobCategory': 'plumber',
        'expectedRoute': '/jobs',
        'mandiQuery': 'आज टमाटर का मंडी भाव क्या है?',
        'produce': 'tomato',
        'mandiRoute': '/marketplace',
        'longUtterance': 'मुझे पास के क्षेत्र में कम से कम 700 रुपये दैनिक मजदूरी वाला निर्माण कार्य तुरंत चाहिए',
        'codeMixed': 'Mera wallet balance check karo please',
      },
      {
        'code': 'kn',
        'name': 'Kannada',
        'bcp47': 'kn-IN',
        'greeting': 'ನಮಸ್ಕಾರ, ಶುಭೋದಯ',
        'greetingReply': 'ನಮಸ್ಕಾರ! ಉದ್ಯೋಗಸೇತುವಿಗೆ ಸ್ವಾಗತ. ಇಂದು ನಾನು ನಿಮಗೆ ಹೇಗೆ ಸಹಾಯ ಮಾಡಲಿ?',
        'question': 'ನನ್ನ ಆಧಾರ್ ಕಾರ್ಡ್ ವಿವರಗಳನ್ನು ಹೇಗೆ ಪರಿಶೀಲಿಸುವುದು?',
        'questionReply': 'ಪ್ರೊಫೈಲ್ ಮೆನುವಿನಲ್ಲಿರುವ ಕೆವೈಸಿ ವಿಭಾಗಕ್ಕೆ ಹೋಗಿ ನಿಮ್ಮ ಪರಿಶೀಲನೆ ಸ್ಥಿತಿಯನ್ನು ನೋಡಬಹುದು.',
        'jobQuery': 'ನನ್ನ ಹತ್ತಿರ ಪ್ಲಂಬರ್ ಕೆಲಸ ಬೇಕು',
        'jobCategory': 'plumber',
        'expectedRoute': '/jobs',
        'mandiQuery': 'ಇಂದು ಟೊಮೆಟೊ ಮಾರುವ ರೈತರು ಯಾರು?',
        'produce': 'tomato',
        'mandiRoute': '/marketplace',
        'longUtterance': 'ನನಗೆ ಬೆಂಗಳೂರಿನಲ್ಲಿ ದಿನಕ್ಕೆ ಕನಿಷ್ಠ 800 ರೂಪಾಯಿ ಕೂಲಿ ನೀಡುವ ಎಲೆಕ್ಟ್ರಿಷಿಯನ್ ಕೆಲಸ ತಕ್ಷಣ ಬೇಕಾಗಿದೆ',
        'codeMixed': 'Tomorrow electrician ಕೆಲಸ ಇದೆಯಾ?',
      },
      {
        'code': 'te',
        'name': 'Telugu',
        'bcp47': 'te-IN',
        'greeting': 'నమస్కారం, శుభోదయం',
        'greetingReply': 'నమస్కారం! ఉద్యోగ సేతుకు స్వాగతం. ఈరోజు మీకు ఎలా సహాయపడగలను?',
        'question': 'నేను కొత్త పనిని ఎలా నమోదు చేయాలి?',
        'questionReply': 'ఉద్యోగ ప్రదాత ట్యాబ్ నుండి కొత్త పని వివరాలు మరియు వేతనాన్ని సులభంగా పోస్ట్ చేయవచ్చు.',
        'jobQuery': 'ప్లంబర్ పని కావాలి సమీపంలో',
        'jobCategory': 'plumber',
        'expectedRoute': '/jobs',
        'mandiQuery': 'రైతులు అమ్మే టమోటాలు ధర ఎంత?',
        'produce': 'tomato',
        'mandiRoute': '/marketplace',
        'longUtterance': 'నాకు రోజుకు కనీసం 750 రూపాయలు వేతనం ఇచ్చే వ్యవసాయ పనులు అత్యవసరంగా కావాలి',
        'codeMixed': 'Naa wallet balance entha undi?',
      },
      {
        'code': 'ta',
        'name': 'Tamil',
        'bcp47': 'ta-IN',
        'greeting': 'வணக்கம், காலை வணக்கம்',
        'greetingReply': 'வணக்கம்! உத்யோக சேதுவிற்கு வரவேற்கிறோம். நான் உங்களுக்கு எவ்வாறு உதவ முடியும்?',
        'question': 'எனது தினசரி சம்பளத்தை எங்கு சரிபார்ப்பது?',
        'questionReply': 'உங்கள் வாலட் பக்கத்தில் தினசரி சம்பளம் மற்றும் முடிக்கப்பட்ட வேலைகளின் விவரங்களை காணலாம்.',
        'jobQuery': 'பிளம்பர் வேலை வேண்டும் அருகில்',
        'jobCategory': 'plumber',
        'expectedRoute': '/jobs',
        'mandiQuery': 'தக்காளி விற்கும் விவசாயிகள் பட்டியல் காட்டு',
        'produce': 'tomato',
        'mandiRoute': '/marketplace',
        'longUtterance': 'எனக்கு உடனடியாக 800 ரூபாய் தினசரி கூலியுடன் கூடிய தச்சு வேலை அவசியமாக தேவைப்படுகிறது',
        'codeMixed': 'Innaiku plumber job irukka nearby?',
      },
      {
        'code': 'mr',
        'name': 'Marathi',
        'bcp47': 'mr-IN',
        'greeting': 'नमस्कार, शुभ प्रभात',
        'greetingReply': 'नमस्कार! उद्योगसेतू मध्ये आपले स्वागत आहे. मी आपल्याला कशी मदत करू शकतो?',
        'question': 'माझे प्रोफाइल कागदपत्रे कसे अपडेट करावे?',
        'questionReply': 'प्रोफाइल विभागात जाऊन आपण आधार, ड्रायव्हिंग लायसन्स आणि बँक माहिती अपडेट करू शकता.',
        'jobQuery': 'मला सुतार आणि बांधकाम काम हवे आहे',
        'jobCategory': 'construction',
        'expectedRoute': '/jobs',
        'mandiQuery': 'आज टोमॅटोचा बाजारभाव काय आहे?',
        'produce': 'tomato',
        'mandiRoute': '/marketplace',
        'longUtterance': 'मला माझ्या जवळच्या परिसरात किमान 800 रुपये रोजंदारी देणारे इलेक्ट्रिशियन काम तातडीने हवे आहे',
        'codeMixed': 'Maza profile update kara please',
      },
      {
        'code': 'bn',
        'name': 'Bengali',
        'bcp47': 'bn-IN',
        'greeting': 'নমস্কার, সুপ্রভাত',
        'greetingReply': 'নমস্কার! উদ্যোগ সেতুতে আপনাকে স্বাগতম। আজ আমি আপনাকে কীভাবে সাহায্য করতে পারি?',
        'question': 'আমার দৈনিক মজুরি কিভাবে যাচাই করব?',
        'questionReply': 'আপনি ওয়ালেট ড্যাশবোর্ডে গিয়ে আপনার মোট উপার্জন ও দৈনিক মজুরি দেখতে পারেন।',
        'jobQuery': 'আমার কাছাকাছি রাজমিস্ত্রি কাজ খুঁজুন',
        'jobCategory': 'construction',
        'expectedRoute': '/jobs',
        'mandiQuery': 'আজকের তাজা টমেটো বাজার দর কত?',
        'produce': 'tomato',
        'mandiRoute': '/marketplace',
        'longUtterance': 'আমার অবিলম্বে দৈনিক ৮০০ টাকা মজুরির ইলেকট্রিশিয়ান কাজ প্রয়োজন যাতে আমি কাজ শুরু করতে পারি',
        'codeMixed': 'Amar wallet balance check korun',
      },
      {
        'code': 'or',
        'name': 'Odia',
        'bcp47': 'or-IN',
        'greeting': 'ନମସ୍କାର, ଶୁଭ ସକାଳ',
        'greetingReply': 'ନମସ୍କାର! ଉଦ୍ୟୋଗ ସେତୁକୁ ସ୍ୱାଗତ। ମୁଁ ଆପଣଙ୍କୁ କିପରି ସାହାଯ୍ୟ କରିପାରିବି?',
        'question': 'ମୋର ଆକାଉଣ୍ଟ ସୁରକ୍ଷା କିପରି ଯାଞ୍ଚ କରିବି?',
        'questionReply': 'ସୁରକ୍ଷା ହବ୍ ମାଧ୍ୟମରେ ଆପଣ ଜରୁରୀକାଳୀନ ଯୋଗାଯୋଗ ଏବଂ ସୁରକ୍ଷା ବୀମା ଯାଞ୍ଚ କରିପାରିବେ।',
        'jobQuery': 'ମୋ ନିକଟରେ କାଠମିସ୍ତ୍ରୀ କାମ ଖୋଜନ୍ତୁ',
        'jobCategory': 'carpenter',
        'expectedRoute': '/jobs',
        'mandiQuery': 'ଆଜି ଟମାଟୋ ମଣ୍ଡି ଦର କେତେ?',
        'produce': 'tomato',
        'mandiRoute': '/marketplace',
        'longUtterance': 'ମୋତେ ତୁରନ୍ତ ଦୈନିକ ୭୫୦ ଟଙ୍କା ମଜୁରି ସହିତ ନିର୍ମାଣ କାମ ନିକଟସ୍ଥ ଅଞ୍ଚଳରେ ଆବଶ୍ୟକ',
        'codeMixed': 'Mote carpenter kama darkar nearby',
      },
    ];

    for (final lang in languageMatrix) {
      final code = lang['code'] as String;
      final name = lang['name'] as String;

      group('Language: $name ($code)', () {
        late MockEdgeApiClient mockEdge;
        late MockAudioRecorder mockRecorder;
        late MockFlutterTts mockTts;
        late MockAudioPlayer mockPlayer;
        late VoiceService voiceService;

        setUp(() {
          mockRecorder = MockAudioRecorder();
          mockTts = MockFlutterTts();
          mockPlayer = MockAudioPlayer();
          mockEdge = MockEdgeApiClient(onCall: (method, params) {
            if (method == 'voiceTranscribe') {
              return {
                'ok': true,
                'mode': 'groq',
                'model': 'whisper-large-v3-turbo',
                'result': {
                  'transcript': lang['greeting'] as String,
                },
              };
            }
            if (method == 'queryAssistant') {
              final query = params['query'] as String? ?? '';
              final reply = query.contains(lang['question'] as String)
                  ? lang['questionReply'] as String
                  : (query.contains(lang['mandiQuery'] as String)
                      ? 'The produce rate for tomato is 30/kg in your local mandi.'
                      : lang['greetingReply'] as String);

              return {
                'ok': true,
                'mode': 'groq',
                'model': 'qwen/qwen3.8-27b',
                'result': {
                  'reply_text': reply,
                  'intent': query.contains(lang['jobQuery'] as String)
                      ? 'find_jobs'
                      : (query.contains(lang['mandiQuery'] as String) ? 'search_produce' : 'answer_question'),
                  'params': query.contains(lang['mandiQuery'] as String) ? {'produce': 'tomato'} : {},
                },
              };
            }
            return {'ok': true};
          });

          voiceService = VoiceService(
            edgeApi: mockEdge,
            audioRecorder: mockRecorder,
            tts: mockTts,
            audioPlayer: mockPlayer,
          );
        });

        test('$name: 1. Short greeting preserves native script & language code', () async {
          final greetingText = lang['greeting'] as String;
          final result = await voiceService.queryAssistant(
            text: greetingText,
            userRole: 'seeker',
            languageCode: code,
          );

          expect(result.spokenReply.isNotEmpty, isTrue);
          expect(mockEdge.queryCalls.last['language'], code);
          expect(mockEdge.queryCalls.last['query'], greetingText);
          expect(result.spokenReply, lang['greetingReply']);
        });

        test('$name: 2. Natural question generates coherent native response', () async {
          final questionText = lang['question'] as String;
          final result = await voiceService.queryAssistant(
            text: questionText,
            userRole: 'seeker',
            languageCode: code,
          );

          expect(result.spokenReply, lang['questionReply']);
          expect(mockEdge.queryCalls.last['language'], code);
        });

        test('$name: 3. Local employment query routes safely to job listings', () async {
          final jobQuery = lang['jobQuery'] as String;
          final result = await voiceService.queryAssistant(
            text: jobQuery,
            userRole: 'seeker',
            languageCode: code,
          );

          expect(result.type, VoiceIntentType.findJobs);
          expect(result.targetRoute, contains('/jobs'));
        });

        test('$name: 4. Farmer / produce-price query extracts produce parameter', () async {
          final mandiQuery = lang['mandiQuery'] as String;
          final result = await voiceService.queryAssistant(
            text: mandiQuery,
            userRole: 'farmer',
            languageCode: code,
          );

          expect(result.type, VoiceIntentType.searchProduce);
          expect(result.parameters.produce, 'tomato');
          expect(result.targetRoute, contains('/marketplace'));
        });

        test('$name: 5. Extended multi-constraint utterance parses without error', () async {
          final longText = lang['longUtterance'] as String;
          final result = await voiceService.queryAssistant(
            text: longText,
            userRole: 'seeker',
            languageCode: code,
          );

          expect(result.rawText, longText);
          expect(result.spokenReply.isNotEmpty, isTrue);
        });

        test('$name: 6. Code-mixed utterance handles mixed phrases gracefully', () async {
          final codeMixedText = lang['codeMixed'] as String;
          final result = await voiceService.queryAssistant(
            text: codeMixedText,
            userRole: 'seeker',
            languageCode: code,
          );

          expect(result.rawText, codeMixedText);
          expect(mockEdge.queryCalls.last['language'], code);
        });

        test('$name: 7. Multi-turn conversation retains selected language across turns', () async {
          final history = <Map<String, String>>[];

          // Turn 1
          final res1 = await voiceService.queryAssistant(
            text: lang['greeting'] as String,
            userRole: 'seeker',
            languageCode: code,
            conversationHistory: history,
          );
          history.add({'role': 'user', 'text': lang['greeting'] as String});
          history.add({'role': 'assistant', 'text': res1.spokenReply});

          // Turn 2
          final res2 = await voiceService.queryAssistant(
            text: lang['question'] as String,
            userRole: 'seeker',
            languageCode: code,
            conversationHistory: history,
          );

          expect(mockEdge.queryCalls.length, 2);
          expect(mockEdge.queryCalls[0]['language'], code);
          expect(mockEdge.queryCalls[1]['language'], code);
          expect(res2.spokenReply, lang['questionReply']);
        });

        test('$name: 8. Audio playback handles available and missing device TTS voices cleanly', () async {
          if (code == 'en') {
            // English Case A: On-device English TTS
            final statusDevice = await voiceService.speak(
              lang['greetingReply'] as String,
              languageCode: code,
            );
            expect(statusDevice, TtsPlaybackStatus.playedDevice);
            expect(mockTts.lastSpokenText, lang['greetingReply']);

            // English Case B: Deepgram Aura Neural audio playback
            final dummyAudio = 'UklGRiQAAABXQVZFZm10IBAAAAABAAEARKwAAIhYAQACABAAZGF0YQAAAAA=';
            final statusNeural = await voiceService.speak(
              lang['greetingReply'] as String,
              languageCode: code,
              audioBase64: dummyAudio,
            );
            expect(statusNeural, TtsPlaybackStatus.playedNeural);
            expect(mockPlayer.isPlaying, isTrue);
          } else {
            // Regional Case A: TTS Voice installed on device
            mockTts.isLanguageAvailableReturn = 1;
            final statusOk = await voiceService.speak(
              lang['greetingReply'] as String,
              languageCode: code,
            );
            expect(statusOk, TtsPlaybackStatus.playedDevice);
            expect(mockTts.lastSpokenText, lang['greetingReply']);

            // Regional Case B: TTS Voice NOT installed on device
            mockTts.isLanguageAvailableReturn = 0;
            final statusMissing = await voiceService.speak(
              lang['greetingReply'] as String,
              languageCode: code,
            );
            expect(statusMissing, TtsPlaybackStatus.voiceUnavailable);
          }
        });
      });
    }
  });
}
