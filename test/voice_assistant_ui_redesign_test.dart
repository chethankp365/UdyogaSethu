import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/core/l10n/locale_controller.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/supabase/edge_api.dart';
import 'package:udyogasethu/features/voice/data/voice_service.dart';
import 'package:udyogasethu/features/voice/presentation/voice_assistant_modal.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class MockEdgeApiClient implements EdgeApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #queryAssistant) {
      return Future.value({
        'ok': true,
        'mode': 'groq',
        'model': 'qwen/qwen3.8-27b',
        'latency_ms': 102,
        'result': {
          'reply_text': 'Here are the electrician jobs near you.',
          'intent': 'open_nearby_jobs',
          'params': {'category': 'electrician'},
        },
      });
    }
    return super.noSuchMethod(invocation);
  }
}

class FakeAppSessionNotifier extends AppSessionNotifier {
  final UserRole initialRole;
  FakeAppSessionNotifier(this.initialRole);

  @override
  AppSessionData build() {
    return AppSessionData(
      status: AuthSessionStatus.ready,
      activeRole: initialRole,
    );
  }
}

class FakeLocaleNotifier extends LocaleNotifier {
  final Locale _initial;
  FakeLocaleNotifier(this._initial);

  @override
  Locale build() => _initial;
}

class FakeVoiceService extends VoiceService {
  final bool mockListeningSuccess;
  final MicrophonePermissionState permissionState;
  final TtsPlaybackStatus ttsStatus;
  int cancelListeningCount = 0;
  int stopSpeakingCount = 0;

  FakeVoiceService({
    super.edgeApi,
    this.mockListeningSuccess = true,
    this.permissionState = MicrophonePermissionState.granted,
    this.ttsStatus = TtsPlaybackStatus.playedNeural,
  });

  @override
  Future<bool> initialize() async => true;

  @override
  Future<MicrophonePermissionState> requestMicrophonePermission() async => permissionState;

  @override
  Future<bool> startListening({
    required Function(String text) onPartialResult,
    required Function(String text) onFinalResult,
    required Function(double level) onSoundLevelChange,
    required VoidCallback onError,
    String? languageCode,
    ValueChanged<String>? onStatus,
  }) async {
    if (!mockListeningSuccess) {
      onError();
      return false;
    }
    return true;
  }

  @override
  Future<void> cancelListening() async {
    cancelListeningCount++;
  }

  @override
  Future<void> stopListening() async {}

  @override
  Future<void> stopSpeaking() async {
    stopSpeakingCount++;
  }

  @override
  Future<TtsPlaybackStatus> speak(
    String text, {
    required String languageCode,
    String? audioBase64,
  }) async {
    return ttsStatus;
  }
}

Widget createTestWidget({
  required VoiceService service,
  UserRole role = UserRole.seeker,
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [
      voiceServiceProvider.overrideWithValue(service),
      appSessionProvider.overrideWith(() => FakeAppSessionNotifier(role)),
      localeProvider.overrideWith(() => FakeLocaleNotifier(locale)),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: VoiceAssistantModal()),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers.global'), (call) async => 1);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), (call) async => 1);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/connectivity'), (call) async => ['wifi']);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter.baseflow.com/permissions/methods'), (call) async {
      if (call.method == 'checkPermissionStatus') return 1; // PermissionStatus.granted
      if (call.method == 'requestPermissions') return {0: 1, 7: 1};
      return 1;
    });
  });

  group('Phase 2: Premium Voice Assistant UI & Interaction Tests', () {
    testWidgets('Renders greeting, brand tag, orb, state pill, and Seeker suggestions', (tester) async {
      final mockApi = MockEdgeApiClient();
      final service = FakeVoiceService(edgeApi: mockApi);

      await tester.pumpWidget(createTestWidget(service: service, role: UserRole.seeker));
      await tester.pump();

      // Brand Tag
      expect(find.text('AI Voice Assistant'), findsOneWidget);

      // Headline
      expect(find.text('How can I help you today?'), findsOneWidget);

      // State pill (listening state on initial launch)
      expect(find.text('Listening... Speak now'), findsOneWidget);

      // Seeker suggestion chips
      expect(find.text('Find nearby jobs'), findsOneWidget);
      expect(find.text('Check my wallet balance'), findsOneWidget);
      expect(find.text('Open my profile'), findsOneWidget);
      expect(find.text('Show my active jobs'), findsOneWidget);

      // Type instead toggle button
      expect(find.text('Type instead'), findsOneWidget);
    });

    testWidgets('Provider role renders provider-tailored suggestion chips', (tester) async {
      final mockApi = MockEdgeApiClient();
      final service = FakeVoiceService(edgeApi: mockApi);

      await tester.pumpWidget(createTestWidget(service: service, role: UserRole.provider));
      await tester.pump();

      // Provider suggestion chips
      expect(find.text('Find workers near me'), findsOneWidget);
      expect(find.text('Post a new job'), findsOneWidget);
      expect(find.text('Show my applicants'), findsOneWidget);
      expect(find.text('Check my earnings'), findsOneWidget);
    });

    testWidgets('Farmer role renders farmer-tailored suggestion chips', (tester) async {
      final mockApi = MockEdgeApiClient();
      final service = FakeVoiceService(edgeApi: mockApi);

      await tester.pumpWidget(createTestWidget(service: service, role: UserRole.farmer));
      await tester.pump();

      // Farmer suggestion chips
      expect(find.text("What's today's tomato price?"), findsOneWidget);
      expect(find.text('Open produce marketplace'), findsOneWidget);
      expect(find.text('Show my orders'), findsOneWidget);
      expect(find.text('Help me diagnose a crop problem'), findsOneWidget);
    });

    testWidgets('Tapping Type instead opens text input field and switches back to mic', (tester) async {
      final mockApi = MockEdgeApiClient();
      final service = FakeVoiceService(edgeApi: mockApi);

      await tester.pumpWidget(createTestWidget(service: service));
      await tester.pump();

      final typeButton = find.text('Type instead');
      expect(typeButton, findsOneWidget);

      await tester.tap(typeButton);
      await tester.pump();

      // Text input field is now visible
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      // Switch back to mic icon is present
      final micButton = find.byIcon(Icons.mic_rounded);
      expect(micButton, findsWidgets);
    });

    testWidgets('Tapping close button dismisses modal without crashing', (tester) async {
      final mockApi = MockEdgeApiClient();
      final service = FakeVoiceService(edgeApi: mockApi);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceServiceProvider.overrideWithValue(service),
            appSessionProvider.overrideWith(() => FakeAppSessionNotifier(UserRole.seeker)),
            localeProvider.overrideWith(() => FakeLocaleNotifier(const Locale('en'))),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => VoiceAssistantModal.show(ctx),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      // Tap to open modal
      await tester.tap(find.text('Open Modal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(VoiceAssistantModal), findsOneWidget);

      // Tap close button
      final closeBtn = find.byIcon(Icons.close_rounded);
      expect(closeBtn, findsOneWidget);

      await tester.tap(closeBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(VoiceAssistantModal), findsNothing);
    });

    testWidgets('Kannada locale renders localized headers, state, and chips', (tester) async {
      final mockApi = MockEdgeApiClient();
      final service = FakeVoiceService(edgeApi: mockApi);

      await tester.pumpWidget(createTestWidget(
        service: service,
        role: UserRole.seeker,
        locale: const Locale('kn'),
      ));
      await tester.pump();

      // Localized Kannada Title
      expect(find.text('ಎಐ ಧ್ವನಿ ಸಹಾಯಕ'), findsOneWidget);

      // Localized Kannada State Pill
      expect(find.text('ಕೇಳಿಸಿಕೊಳ್ಳುತ್ತಿದೆ... ಈಗ ಮಾತನಾಡಿ'), findsOneWidget);

      // Localized Kannada Suggestion Chips
      expect(find.text('ಹತ್ತಿರದ ಕೆಲಸಗಳನ್ನು ಹುಡುಕಿ'), findsOneWidget);
      expect(find.text('ನನ್ನ ವಾಲೆಟ್ ಬ್ಯಾಲೆನ್ಸ್ ನೋಡಿ'), findsOneWidget);
    });

    testWidgets('Microphone permission denied displays localized warning banner', (tester) async {
      final mockApi = MockEdgeApiClient();
      final service = FakeVoiceService(
        edgeApi: mockApi,
        permissionState: MicrophonePermissionState.denied,
      );

      await tester.pumpWidget(createTestWidget(service: service));
      await tester.pump();

      expect(find.text('Microphone permission required'), findsNWidgets(2));
      expect(find.text('Grant Permission'), findsOneWidget);
      expect(find.byIcon(Icons.mic_off_rounded), findsWidgets);
    });

    testWidgets('Microphone permanently denied displays settings prompt', (tester) async {
      final mockApi = MockEdgeApiClient();
      final service = FakeVoiceService(
        edgeApi: mockApi,
        permissionState: MicrophonePermissionState.permanentlyDenied,
      );

      await tester.pumpWidget(createTestWidget(service: service));
      await tester.pump();

      expect(find.text('Microphone permission required'), findsNWidgets(2));
      expect(find.text('Open Settings'), findsOneWidget);
      expect(find.text('Please open App Settings to allow microphone access.'), findsOneWidget);
    });

    testWidgets('Listening failure triggers hear error banner with retry action', (tester) async {
      final mockApi = MockEdgeApiClient();
      final service = FakeVoiceService(
        edgeApi: mockApi,
        mockListeningSuccess: false,
      );

      await tester.pumpWidget(createTestWidget(service: service));
      await tester.pump();

      expect(find.text("I didn't catch that. Tap to try again"), findsNWidgets(2));
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Regional TTS voice unavailable shows amber notice and resets state to idle', (tester) async {
      final mockApi = MockEdgeApiClient();
      final service = FakeVoiceService(
        edgeApi: mockApi,
        ttsStatus: TtsPlaybackStatus.voiceUnavailable,
      );

      await tester.pumpWidget(createTestWidget(service: service));
      await tester.pump();

      await tester.tap(find.text('Type instead'));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Find jobs');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Voice playback for this language is not installed on your device.'), findsOneWidget);
      expect(find.text('Assistant:'), findsOneWidget);
    });

    testWidgets('App backgrounding cancels listening and silences audio', (tester) async {
      final mockApi = MockEdgeApiClient();
      final service = FakeVoiceService(edgeApi: mockApi);

      await tester.pumpWidget(createTestWidget(service: service));
      await tester.pump();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      expect(service.cancelListeningCount, greaterThan(0));
      expect(service.stopSpeakingCount, greaterThan(0));
    });
  });
}
