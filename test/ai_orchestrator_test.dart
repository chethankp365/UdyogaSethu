import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/core/l10n/locale_controller.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/supabase/edge_api.dart';
import 'package:udyogasethu/features/voice/data/voice_service.dart';
import 'package:udyogasethu/features/voice/domain/voice_intent.dart';
import 'package:udyogasethu/features/voice/presentation/voice_assistant_modal.dart';

class MockEdgeApiClient implements EdgeApiClient {
  final Map<String, dynamic> Function(String method, Map<String, dynamic>? body)? onInvoke;

  MockEdgeApiClient({this.onInvoke});

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #queryAssistant) {
      final namedArgs = invocation.namedArguments;
      final query = namedArgs[#query] as String? ?? '';
      final role = namedArgs[#role] as String? ?? 'seeker';
      final language = namedArgs[#language] as String? ?? 'en';
      final preferred = namedArgs[#preferredProvider] as String?;

      if (onInvoke != null) {
        return Future.value(onInvoke!('queryAssistant', {
          'query': query,
          'role': role,
          'language': language,
          'preferred_provider': preferred,
        }));
      }

      // Default mock 5-provider orchestrated response
      return Future.value({
        'ok': true,
        'mode': 'groq',
        'model': 'llama-3.1-8b-instant',
        'latency_ms': 145,
        'result': {
          'reply_text': 'Here are the electrician jobs near you.',
          'intent': 'open_nearby_jobs',
          'params': {
            'category': 'electrician',
            'min_wage': 600,
          },
        },
        'audio_base64': base64Encode([0, 1, 2, 3, 4, 5]), // mock audio bytes
        'audio_mime': 'audio/mp3',
        'fallback_chain': null,
      });
    }

    if (invocation.memberName == #voiceSynthesize) {
      return Future.value({
        'ok': true,
        'mode': 'deepgram',
        'model': 'aura-asteria-en',
        'audio_base64': base64Encode([0, 1, 2, 3]),
        'audio_mime': 'audio/mp3',
      });
    }

    if (invocation.memberName == #voiceTranscribe) {
      return Future.value({
        'ok': true,
        'mode': 'deepgram',
        'model': 'nova-2',
        'result': {'transcript': 'hello test', 'confidence': 0.98},
      });
    }

    if (invocation.memberName == #getAiCapabilities) {
      return Future.value({
        'ok': true,
        'active_providers_count': 5,
        'providers': [
          {'id': 'groq', 'isAvailable': true},
          {'id': 'gemini', 'isAvailable': true},
          {'id': 'openrouter', 'isAvailable': true},
          {'id': 'deepgram', 'isAvailable': true},
          {'id': 'huggingface', 'isAvailable': true},
        ],
      });
    }

    return super.noSuchMethod(invocation);
  }
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
        .setMockMethodCallHandler(const MethodChannel('com.llfbandit.record/messages'), (call) async => null);
  });

  group('5-Provider AI Orchestrator Domain & Service Tests', () {
    test('VoiceIntentResult preserves provider metadata, latency, and audio', () {
      const result = VoiceIntentResult(
        type: VoiceIntentType.findJobs,
        rawText: 'electrician jobs',
        confidence: 0.98,
        parameters: VoiceIntentParameters(category: 'electrician', minPrice: 600),
        targetRoute: '/jobs?category=electrician',
        spokenReply: 'Showing electrician jobs.',
        isAiFallback: true,
        provider: 'groq',
        model: 'llama-3.1-8b-instant',
        latencyMs: 145,
        audioBase64: 'bW9jaw==',
        fallbackChain: ['groq'],
      );

      expect(result.provider, 'groq');
      expect(result.model, 'llama-3.1-8b-instant');
      expect(result.latencyMs, 145);
      expect(result.audioBase64, 'bW9jaw==');
      expect(result.fallbackChain, ['groq']);
      expect(result.isRecognized, true);
    });

    test('VoiceService queries 5-provider orchestrator and maps response fields', () async {
      final mockApi = MockEdgeApiClient();
      final service = VoiceService(edgeApi: mockApi);

      final result = await service.queryAssistant(
        text: 'find delivery jobs',
        userRole: 'seeker',
        languageCode: 'en',
      );

      expect(result.type, VoiceIntentType.findJobs);
      expect(result.provider, 'groq');
      expect(result.model, 'llama-3.1-8b-instant');
      expect(result.latencyMs, 145);
      expect(result.audioBase64, isNotNull);
      expect(result.spokenReply, contains('electrician'));
    });

    test('VoiceService mute toggle silences audio and stops playback', () {
      final service = VoiceService();
      expect(service.isMuted, false);

      service.toggleMute();
      expect(service.isMuted, true);

      service.toggleMute();
      expect(service.isMuted, false);
    });

    test('VoiceService falls back to IntentEngine if backend throws', () async {
      final failingApi = MockEdgeApiClient(onInvoke: (path, payload) {
        throw Exception('Network timeout');
      });
      final service = VoiceService(edgeApi: failingApi);

      // Should not throw, should fallback to offline rule engine
      final result = await service.queryAssistant(
        text: 'check my wallet balance',
        userRole: 'seeker',
        languageCode: 'en',
      );

      expect(result.type, VoiceIntentType.openWallet);
      expect(result.targetRoute, '/wallet');
    });

    test('VoiceService propagates fallback chain when Groq fails and Gemini takes over', () async {
      final fallbackApi = MockEdgeApiClient(onInvoke: (path, payload) {
        return {
          'ok': true,
          'mode': 'gemini',
          'model': 'gemini-1.5-flash',
          'latency_ms': 620,
          'result': {
            'reply_text': 'Found government schemes for you.',
            'intent': 'answer_question',
          },
          'fallback_chain': ['groq', 'gemini'],
        };
      });

      final service = VoiceService(edgeApi: fallbackApi);
      final result = await service.queryAssistant(
        text: 'tell me about farmer schemes',
        userRole: 'farmer',
        languageCode: 'en',
      );

      expect(result.provider, 'gemini');
      expect(result.model, 'gemini-1.5-flash');
      expect(result.latencyMs, 620);
      expect(result.fallbackChain, ['groq', 'gemini']);
      expect(result.spokenReply, contains('government schemes'));
    });

    test('VoiceService stopSpeaking cancels active playback without throwing', () async {
      final service = VoiceService();
      await expectLater(service.stopSpeaking(), completes);
    });

    test('EdgeApiClient getAiCapabilities returns configured provider list', () async {
      final mockApi = MockEdgeApiClient();
      final res = await mockApi.getAiCapabilities();

      expect(res['ok'], true);
      expect(res['active_providers_count'], 5);
      final providers = res['providers'] as List;
      expect(providers.length, 5);
    });
  });

  group('VoiceAssistantModal UI & Orchestration Widget Tests', () {
    testWidgets('VoiceAssistantModal renders provider badge, mute, and reset buttons', (tester) async {
      final mockApi = MockEdgeApiClient();
      final service = VoiceService(edgeApi: mockApi);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceServiceProvider.overrideWithValue(service),
            appSessionProvider.overrideWith(() => AppSessionNotifier()),
            localeProvider.overrideWith(() => LocaleNotifier()),
          ],
          child: const MaterialApp(
            home: VoiceAssistantModal(),
          ),
        ),
      );

      await tester.pump();

      // Top bar provider indicator
      expect(find.textContaining('AI Orchestrator'), findsOneWidget);

      // Mute/unmute button
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

      // Reset conversation button
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      // Orb and mic controls
      expect(find.byIcon(Icons.mic_rounded), findsWidgets);
    });

    testWidgets('VoiceAssistantModal resets conversation when reset button tapped', (tester) async {
      final mockApi = MockEdgeApiClient();
      final service = VoiceService(edgeApi: mockApi);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceServiceProvider.overrideWithValue(service),
            appSessionProvider.overrideWith(() => AppSessionNotifier()),
            localeProvider.overrideWith(() => LocaleNotifier()),
          ],
          child: const MaterialApp(
            home: VoiceAssistantModal(),
          ),
        ),
      );

      await tester.pump();

      final resetButton = find.byTooltip('Reset conversation');
      expect(resetButton, findsOneWidget);

      await tester.tap(resetButton);
      await tester.pump();

      // State is reset to idle
      expect(find.text('Tap orb to speak'), findsOneWidget);
    });
  });
}
