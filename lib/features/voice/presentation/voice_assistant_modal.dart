import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:udyogasethu/core/l10n/locale_controller.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/voice/data/voice_service.dart';
import 'package:udyogasethu/features/voice/domain/voice_intent.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

/// Full-screen Siri / Google Assistant Voice-First Personal Assistant for UdyogaSethu.
class VoiceAssistantModal extends ConsumerStatefulWidget {
  const VoiceAssistantModal({super.key});

  /// Present as a full-screen voice assistant page.
  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        fullscreenDialog: true,
        pageBuilder: (context, anim1, anim2) => const VoiceAssistantModal(),
        transitionsBuilder: (context, anim, secAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  ConsumerState<VoiceAssistantModal> createState() => _VoiceAssistantModalState();
}

class _VoiceAssistantModalState extends ConsumerState<VoiceAssistantModal>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _orbAnimController;
  late AnimationController _waveAnimController;

  VoiceServiceState _state = VoiceServiceState.idle;
  String _recognizedText = '';
  String _assistantReply = '';
  double _soundLevel = 0.0;
  bool _isKeyboardMode = false;
  final TextEditingController _textController = TextEditingController();

  MicrophonePermissionState _micPermission = MicrophonePermissionState.granted;
  final List<Map<String, String>> _conversationHistory = [];
  VoiceService? _voiceService;
  VoiceIntentResult? _lastResult;
  StreamSubscription<PlayerState>? _playerSub;
  StreamSubscription<bool>? _ttsSub;
  String? _ttsNotice;
  Timer? _navigationTimer;
  bool _isStartingListening = false;
  bool _isProcessingQuery = false;
  String _selectedVoiceLang = 'auto';

  /// Automatic detection of Indic regional scripts and transliterated triggers
  static String detectLanguageFromText(String text, {String defaultLang = 'en'}) {
    for (final char in text.runes) {
      if (char >= 0x0C80 && char <= 0x0CFF) return 'kn'; // Kannada
      if (char >= 0x0900 && char <= 0x097F) return 'hi'; // Hindi / Devanagari
      if (char >= 0x0C00 && char <= 0x0C7F) return 'te'; // Telugu
      if (char >= 0x0B80 && char <= 0x0BFF) return 'ta'; // Tamil
      if (char >= 0x0980 && char <= 0x09FF) return 'bn'; // Bengali
      if (char >= 0x0B00 && char <= 0x0B7F) return 'or'; // Odia
      if (char >= 0x0D00 && char <= 0x0D7F) return 'ml'; // Malayalam
      if (char >= 0x0A80 && char <= 0x0AFF) return 'gu'; // Gujarati
    }
    final lower = text.toLowerCase();
    if (lower.contains('beku') ||
        lower.contains('kelsa') ||
        lower.contains('kelasa') ||
        lower.contains('illi') ||
        lower.contains('yelli') ||
        lower.contains('namaskara')) {
      return 'kn';
    }
    if (lower.contains('chahiye') ||
        lower.contains('kaam') ||
        lower.contains('naukri') ||
        lower.contains('karo') ||
        lower.contains('dikhao') ||
        lower.contains('batao')) {
      return 'hi';
    }
    if (lower.contains('kavali') ||
        lower.contains('pani') ||
        lower.contains('chudandi') ||
        lower.contains('ikkada') ||
        lower.contains('ekkada') ||
        lower.contains('namaskaram')) {
      return 'te';
    }
    if (lower.contains('vendum') ||
        lower.contains('velai') ||
        lower.contains('kaatu') ||
        lower.contains('enge') ||
        lower.contains('vanakkam')) {
      return 'ta';
    }
    return defaultLang;
  }

  Future<void> _setVoiceLanguage(String langCode) async {
    if (_selectedVoiceLang == langCode) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedVoiceLang = langCode;
      _recognizedText = '';
      _assistantReply = '';
    });
    if (_state == VoiceServiceState.listening) {
      await _voiceService?.stopListening();
      if (mounted) {
        _startListening();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _voiceService = ref.read(voiceServiceProvider);

    _playerSub = _voiceService?.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        if (mounted && _state == VoiceServiceState.speaking) {
          setState(() {
            _state = VoiceServiceState.idle;
          });
        }
      }
    });

    _ttsSub = _voiceService?.onTtsSpeakingChanged.listen((isSpeaking) {
      if (!isSpeaking) {
        if (mounted && _state == VoiceServiceState.speaking) {
          setState(() {
            _state = VoiceServiceState.idle;
          });
        }
      }
    });

    _orbAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _waveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // Auto-start listening on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startListening();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _navigationTimer?.cancel();
    _playerSub?.cancel();
    _ttsSub?.cancel();
    _orbAnimController.dispose();
    _waveAnimController.dispose();
    _textController.dispose();
    _voiceService?.cancelListening();
    _voiceService?.stopSpeaking();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _navigationTimer?.cancel();
      _voiceService?.cancelListening();
      _voiceService?.stopSpeaking();
      if (mounted && (_state == VoiceServiceState.listening || _state == VoiceServiceState.speaking)) {
        setState(() {
          _state = VoiceServiceState.idle;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_micPermission != MicrophonePermissionState.granted) {
        Permission.microphone.status.then((status) {
          if (mounted && status.isGranted) {
            setState(() {
              _micPermission = MicrophonePermissionState.granted;
              if (_state == VoiceServiceState.permissionDenied ||
                  _state == VoiceServiceState.permissionPermanentlyDenied) {
                _state = VoiceServiceState.idle;
              }
            });
          }
        });
      }
    }
  }

  void _resetConversation() {
    HapticFeedback.lightImpact();
    _navigationTimer?.cancel();
    _voiceService?.stopSpeaking();
    _voiceService?.cancelListening();
    setState(() {
      _conversationHistory.clear();
      _recognizedText = '';
      _assistantReply = '';
      _lastResult = null;
      _ttsNotice = null;
      _state = VoiceServiceState.idle;
    });
  }

  Color _getProviderColor(String? provider) {
    switch (provider) {
      case 'groq':
        return const Color(0xFFF97316); // Groq Orange
      case 'gemini':
        return AppColors.emerald; // Gemini Emerald
      case 'openrouter':
        return const Color(0xFF818CF8); // OpenRouter Indigo
      case 'deepgram':
        return const Color(0xFF06B6D4); // Deepgram Cyan
      case 'huggingface':
        return const Color(0xFFFBBF24); // Hugging Face Amber
      default:
        return const Color(0xFF06B6D4); // Default Cyan
    }
  }

  IconData _getProviderIcon(String? provider) {
    switch (provider) {
      case 'groq':
        return Icons.bolt_rounded;
      case 'gemini':
        return Icons.auto_awesome;
      case 'openrouter':
        return Icons.alt_route_rounded;
      case 'deepgram':
        return Icons.graphic_eq_rounded;
      case 'huggingface':
        return Icons.psychology_rounded;
      default:
        return Icons.smart_toy_rounded;
    }
  }

  String _getProviderLabel(VoiceIntentResult? res) {
    if (res == null || res.provider == null) {
      return 'AI Orchestrator (5 Engines)';
    }
    final lat = res.latencyMs != null ? ' (${res.latencyMs}ms)' : '';
    switch (res.provider) {
      case 'groq':
        return 'Groq LPU$lat';
      case 'gemini':
        return 'Gemini 1.5$lat';
      case 'openrouter':
        return 'OpenRouter$lat';
      case 'deepgram':
        return 'Deepgram Aura';
      case 'huggingface':
        return 'Hugging Face$lat';
      default:
        return 'AI Assistant$lat';
    }
  }

  String _getRoleString(UserRole role) {
    switch (role) {
      case UserRole.seeker:
        return 'seeker';
      case UserRole.provider:
        return 'provider';
      case UserRole.farmer:
        return 'farmer';
    }
  }

  Future<void> _startListening() async {
    if (_isStartingListening ||
        _state == VoiceServiceState.thinking ||
        _state == VoiceServiceState.processing) {
      return;
    }
    _isStartingListening = true;
    try {
      _navigationTimer?.cancel();
      final voiceService = ref.read(voiceServiceProvider);
      await voiceService.stopSpeaking();

      if (mounted) {
        setState(() {
          _state = VoiceServiceState.requestingPermission;
        });
      }

      final perm = await voiceService.requestMicrophonePermission();
      if (!mounted) return;

      setState(() {
        _micPermission = perm;
        _soundLevel = 0.0;
      });

      if (perm != MicrophonePermissionState.granted) {
        setState(() {
          _state = perm == MicrophonePermissionState.permanentlyDenied
              ? VoiceServiceState.permissionPermanentlyDenied
              : VoiceServiceState.permissionDenied;
        });
        return;
      }

      final locale = ref.read(localeProvider);
      final langCode = _selectedVoiceLang != 'auto' ? _selectedVoiceLang : locale.languageCode;

      final started = await voiceService.startListening(
        languageCode: langCode,
        onPartialResult: (text) {
          if (mounted && text.trim().isNotEmpty) {
            setState(() {
              _recognizedText = text.trim();
            });
          }
        },
        onFinalResult: (text) {
          if (mounted && text.trim().isNotEmpty) {
            _processQuery(text.trim());
          }
        },
        onStatus: (status) {
          debugPrint('[VoiceAssistantModal] STT status update: $status');
          if (mounted && _state == VoiceServiceState.listening) {
            if (status == 'done' || status == 'notListening') {
              if (_recognizedText.trim().isNotEmpty && !_isProcessingQuery) {
                _processQuery(_recognizedText.trim());
              } else if (_recognizedText.trim().isEmpty && !_isStartingListening) {
                setState(() {
                  _state = VoiceServiceState.idle;
                });
              }
            }
          }
        },
        onSoundLevelChange: (level) {
          if (mounted && _state == VoiceServiceState.listening) {
            setState(() {
              _soundLevel = level.clamp(-2.0, 10.0);
            });
          }
        },
        onError: () {
          if (mounted && _state == VoiceServiceState.listening) {
            if (_recognizedText.trim().isNotEmpty && !_isProcessingQuery) {
              _processQuery(_recognizedText.trim());
            } else {
              setState(() {
                _state = VoiceServiceState.error;
              });
            }
          }
        },
      );

      if (!mounted) return;
      if (started) {
        setState(() {
          _state = VoiceServiceState.listening;
          _recognizedText = '';
          _ttsNotice = null;
        });
      } else {
        setState(() {
          _state = VoiceServiceState.error;
        });
      }
    } finally {
      _isStartingListening = false;
    }
  }

  Future<void> _stopListeningAndProcess() async {
    if (_state == VoiceServiceState.thinking || _state == VoiceServiceState.processing) return;
    _navigationTimer?.cancel();
    final voiceService = ref.read(voiceServiceProvider);
    final locale = ref.read(localeProvider);
    final effectiveLang = _selectedVoiceLang != 'auto' ? _selectedVoiceLang : locale.languageCode;

    setState(() {
      _state = VoiceServiceState.processing;
    });

    final transcript = await voiceService.stopListeningAndTranscribe(
      languageCode: effectiveLang,
      fallbackTranscript: _recognizedText,
    );

    if (transcript != null && transcript.trim().isNotEmpty) {
      _processQuery(transcript.trim());
    } else {
      if (mounted) {
        setState(() {
          _state = VoiceServiceState.idle;
        });
      }
    }
  }

  Future<void> _processQuery(String query) async {
    if (query.trim().isEmpty || _isProcessingQuery) {
      return;
    }
    _isProcessingQuery = true;
    _navigationTimer?.cancel();

    try {
      final l10n = AppLocalizations.of(context);
      final voiceService = ref.read(voiceServiceProvider);
      await voiceService.stopListening();
      await voiceService.stopSpeaking();

      if (!mounted) return;

      setState(() {
        _state = VoiceServiceState.processing;
        _recognizedText = query;
        _ttsNotice = null;
      });

      final session = ref.read(appSessionProvider);
      final roleString = _getRoleString(session.activeRole);
      final locale = ref.read(localeProvider);
      final effectiveLang = _selectedVoiceLang != 'auto'
          ? _selectedVoiceLang
          : detectLanguageFromText(query, defaultLang: locale.languageCode);

      final result = await voiceService.queryAssistant(
        text: query,
        userRole: roleString,
        languageCode: effectiveLang,
        conversationHistory: _conversationHistory,
      );

      if (!mounted) return;

      _conversationHistory.add({'role': 'user', 'text': query});
      _conversationHistory.add({'role': 'assistant', 'text': result.spokenReply});

      setState(() {
        _assistantReply = result.spokenReply;
        _lastResult = result;
        _state = VoiceServiceState.speaking;
      });

      final playbackStatus = await voiceService.speak(
        result.spokenReply,
        languageCode: effectiveLang,
        audioBase64: result.audioBase64,
      );

      if (!mounted) return;

      if (playbackStatus == TtsPlaybackStatus.voiceUnavailable) {
        setState(() {
          _ttsNotice = l10n?.voiceLangNotInstalled ??
              'Voice playback for this language is not installed on your device.';
          _state = VoiceServiceState.idle;
        });
      } else if (playbackStatus == TtsPlaybackStatus.failed ||
          playbackStatus == TtsPlaybackStatus.muted) {
        setState(() {
          _state = VoiceServiceState.idle;
        });
      }

      _handleActionExecution(result);
    } catch (e) {
      debugPrint('[VoiceAssistantModal] Process query error: $e');
      if (mounted) {
        setState(() {
          _state = VoiceServiceState.idle;
        });
      }
    } finally {
      _isProcessingQuery = false;
    }
  }

  void _handleActionExecution(VoiceIntentResult result) {
    if (result.type == VoiceIntentType.confirmSos) {
      _showSosConfirmationDialog();
      return;
    }

    if (result.targetRoute.isNotEmpty && result.targetRoute != 'confirm_sos') {
      _navigationTimer?.cancel();
      final router = GoRouter.maybeOf(context);
      // Delay slightly so the user hears initial audio, but leaves user in control
      _navigationTimer = Timer(const Duration(milliseconds: 1600), () {
        if (mounted && _state != VoiceServiceState.listening) {
          Navigator.of(context).pop();
          if (router != null) {
            if (result.targetRoute.startsWith('/seeker/') ||
                result.targetRoute.startsWith('/provider/') ||
                result.targetRoute.startsWith('/farmer/')) {
              router.go(result.targetRoute);
            } else {
              router.push(result.targetRoute);
            }
          }
        }
      });
    }
  }

  void _showSosConfirmationDialog() {
    HapticFeedback.heavyImpact();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Confirm Emergency SOS',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you in immediate danger? Confirming SOS will immediately send your live GPS location to your emergency contacts.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              context.push('/safety');
            },
            child: const Text('Confirm SOS Alert', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _onOrbTapped() {
    HapticFeedback.lightImpact();
    _navigationTimer?.cancel();
    final voiceService = ref.read(voiceServiceProvider);
    if (_state == VoiceServiceState.speaking) {
      voiceService.stopSpeaking();
      _startListening();
    } else if (_state == VoiceServiceState.listening) {
      _stopListeningAndProcess();
    } else if (_state == VoiceServiceState.idle ||
        _state == VoiceServiceState.error ||
        _state == VoiceServiceState.cancelled ||
        _state == VoiceServiceState.permissionDenied ||
        _state == VoiceServiceState.permissionPermanentlyDenied) {
      _startListening();
    }
  }

  List<({String title, IconData icon})> _getRoleSuggestions(UserRole role, AppLocalizations? l10n) {
    switch (role) {
      case UserRole.seeker:
        return [
          (
            title: l10n?.voicePromptNearbyJobs ?? 'Find nearby jobs',
            icon: Icons.search_rounded,
          ),
          (
            title: l10n?.voicePromptCheckWallet ?? 'Check my wallet balance',
            icon: Icons.account_balance_wallet_outlined,
          ),
          (
            title: l10n?.voicePromptOpenProfile ?? 'Open my profile',
            icon: Icons.person_outline_rounded,
          ),
          (
            title: l10n?.voicePromptActiveJobs ?? 'Show my active jobs',
            icon: Icons.assignment_outlined,
          ),
        ];
      case UserRole.provider:
        return [
          (
            title: l10n?.voicePromptFindWorkers ?? 'Find workers near me',
            icon: Icons.group_outlined,
          ),
          (
            title: l10n?.voicePromptPostJob ?? 'Post a new job',
            icon: Icons.add_circle_outline_rounded,
          ),
          (
            title: l10n?.voicePromptApplicants ?? 'Show my applicants',
            icon: Icons.badge_outlined,
          ),
          (
            title: l10n?.voicePromptCheckEarnings ?? 'Check my earnings',
            icon: Icons.trending_up_rounded,
          ),
        ];
      case UserRole.farmer:
        return [
          (
            title: l10n?.voicePromptMandiPrices ?? "What's today's tomato price?",
            icon: Icons.price_check_rounded,
          ),
          (
            title: l10n?.voicePromptMarketplace ?? 'Open produce marketplace',
            icon: Icons.storefront_outlined,
          ),
          (
            title: l10n?.voicePromptFarmerOrders ?? 'Show my orders',
            icon: Icons.receipt_long_outlined,
          ),
          (
            title: l10n?.voicePromptCropHelp ?? 'Help me diagnose a crop problem',
            icon: Icons.eco_outlined,
          ),
        ];
    }
  }

  String _getTimeGreeting(AppLocalizations? l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return l10n?.voiceGreetingMorning ?? 'Good morning';
    } else if (hour < 17) {
      return l10n?.voiceGreetingAfternoon ?? 'Good afternoon';
    } else {
      return l10n?.voiceGreetingEvening ?? 'Good evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.read(appSessionProvider);
    final activeRole = session.activeRole;
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);

    final isPermDenied = _micPermission == MicrophonePermissionState.denied ||
        _micPermission == MicrophonePermissionState.permanentlyDenied;

    return Scaffold(
      backgroundColor: const Color(0xFF050B14), // Deepest midnight navy
      body: Stack(
        children: [
          // Ambient decorative lighting glow
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00F2FE).withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -50,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.05),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 1. Top Control Bar
                _buildTopBar(locale, l10n),

                // 1b. Fast Language Selector Bar
                _buildLanguageSelectorBar(),

                // 2. Main Scrollable Content Zone
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      children: [
                        // Welcome Greeting & Brand Header (Shown when idle or listening)
                        if (_recognizedText.isEmpty && _assistantReply.isEmpty)
                          _buildWelcomeHeader(l10n, session),

                        // Error / Permission Alerts
                        if (isPermDenied)
                          _buildPermissionBanner(l10n)
                        else if (_state == VoiceServiceState.error)
                          _buildHearErrorBanner(l10n),

                        // User Query Card
                        if (_recognizedText.isNotEmpty)
                          _buildUserSpeechCard(l10n),

                        // Assistant Response Card
                        if (_assistantReply.isNotEmpty)
                          _buildAssistantResponseCard(l10n),

                        const SizedBox(height: 24),

                        // 3. Central Animated Voice Orb
                        GestureDetector(
                          onTap: _onOrbTapped,
                          behavior: HitTestBehavior.opaque,
                          child: _buildCentralOrb(),
                        ),

                        const SizedBox(height: 14),

                        // 4. Fluid Audio Waveform
                        _buildAudioWaveformVisualizer(),

                        const SizedBox(height: 12),

                        // 5. State Indicator Pill
                        _buildStateIndicatorPill(l10n),

                        const SizedBox(height: 20),

                        // 6. Direct Action Button (If result has destination route)
                        if (_lastResult != null &&
                            _lastResult!.targetRoute.isNotEmpty &&
                            _lastResult!.targetRoute != 'confirm_sos')
                          _buildDirectActionPill(_lastResult!),

                        const SizedBox(height: 16),

                        // 7. Role-Tailored Suggestion Chips
                        _buildSuggestionChipsRow(activeRole, l10n),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // 8. Bottom Input Dock (Keyboard text input or Type Instead toggle)
                _buildBottomInputDock(l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(Locale locale, AppLocalizations? l10n) {
    final providerColor = _getProviderColor(_lastResult?.provider);
    final providerLabel = _getProviderLabel(_lastResult);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          // Close button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Provider Badge
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: providerColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: providerColor.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getProviderIcon(_lastResult?.provider), color: providerColor, size: 14),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      providerLabel,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: providerColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Mute / Unmute Button
          IconButton(
            icon: Icon(
              _voiceService?.isMuted == true ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: _voiceService?.isMuted == true ? const Color(0xFFF59E0B) : Colors.white70,
              size: 22,
            ),
            tooltip: _voiceService?.isMuted == true
                ? (l10n?.voiceUnmuteTooltip ?? 'Unmute voice')
                : (l10n?.voiceMuteTooltip ?? 'Mute voice'),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _voiceService?.toggleMute();
              });
            },
          ),

          // Reset Conversation Button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 22),
            tooltip: l10n?.voiceResetConversation ?? 'Reset conversation',
            onPressed: _resetConversation,
          ),

          const SizedBox(width: 4),

          // Interactive Language Selector Chip
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showLanguageSelector(context, locale),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF00F2FE).withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language_rounded, color: Color(0xFF00F2FE), size: 14),
                    const SizedBox(width: 5),
                    Text(
                      _selectedVoiceLang == 'auto' ? 'AUTO' : _selectedVoiceLang.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelectorBar() {
    final languages = [
      {'code': 'auto', 'label': 'Auto • ಸ್ವಯಂ'},
      {'code': 'en', 'label': 'English'},
      {'code': 'kn', 'label': 'ಕನ್ನಡ'},
      {'code': 'hi', 'label': 'हिंदी'},
      {'code': 'te', 'label': 'తెలుగు'},
      {'code': 'ta', 'label': 'தமிழ்'},
      {'code': 'mr', 'label': 'मराठी'},
      {'code': 'bn', 'label': 'বাংলা'},
      {'code': 'or', 'label': 'ଓଡ଼ಿଆ'},
    ];

    return Container(
      height: 38,
      margin: const EdgeInsets.only(top: 2, bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: languages.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final lang = languages[index];
          final isSelected = _selectedVoiceLang == lang['code'];

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _setVoiceLanguage(lang['code']!),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF10B981).withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF10B981)
                        : Colors.white.withValues(alpha: 0.14),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    lang['label']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF6EE7B7) : Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLanguageSelector(BuildContext context, Locale currentLocale) {
    HapticFeedback.lightImpact();
    final languages = [
      {'code': 'auto', 'name': 'Auto-detect spoken language', 'native': 'Auto • ಸ್ವಯಂ'},
      {'code': 'en', 'name': 'English', 'native': 'English'},
      {'code': 'kn', 'name': 'Kannada', 'native': 'ಕನ್ನಡ'},
      {'code': 'hi', 'name': 'Hindi', 'native': 'हिंदी'},
      {'code': 'te', 'name': 'Telugu', 'native': 'తెలుగు'},
      {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்'},
      {'code': 'mr', 'name': 'Marathi', 'native': 'मराठी'},
      {'code': 'bn', 'name': 'Bengali', 'native': 'বাংলা'},
      {'code': 'or', 'name': 'Odia', 'native': 'ଓଡ଼ಿଆ'},
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.language_rounded, color: Color(0xFF00F2FE), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Select Speech Language',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: languages.map((lang) {
                      final isSelected = lang['code'] == _selectedVoiceLang;
                      return ListTile(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _changeSpeechLanguage(lang['code']!);
                        },
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        tileColor: isSelected
                            ? const Color(0xFF00F2FE).withValues(alpha: 0.15)
                            : Colors.transparent,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? const Color(0xFF00F2FE).withValues(alpha: 0.25)
                                : Colors.white10,
                          ),
                          child: Text(
                            lang['code']!.toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF00F2FE) : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        title: Text(
                          lang['native']!,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF00F2FE) : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          lang['name']!,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF00F2FE), size: 20)
                            : null,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _changeSpeechLanguage(String langCode) {
    _setVoiceLanguage(langCode);
  }

  Widget _buildWelcomeHeader(AppLocalizations? l10n, AppSessionData session) {
    final greeting = _getTimeGreeting(l10n);

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      child: Column(
        children: [
          // Mascot / AI Brand Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF10B981),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF10B981),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n?.voiceModalTitle ?? 'AI Voice Assistant',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Main Greeting
          Text(
            greeting,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            l10n?.voiceAskAnything ?? 'How can I help you today?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSpeechCard(AppLocalizations? l10n) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B2F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_circle_outlined, color: Colors.white54, size: 16),
              const SizedBox(width: 6),
              Text(
                l10n?.voiceYouSaid ?? 'You said:',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_state == VoiceServiceState.listening)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00F2FE),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _recognizedText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantResponseCard(AppLocalizations? l10n) {
    final isSpeaking = _state == VoiceServiceState.speaking;
    final providerColor = _getProviderColor(_lastResult?.provider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0E2238),
            Color(0xFF0A192B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: providerColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: providerColor.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: providerColor, size: 16),
              const SizedBox(width: 6),
              Text(
                l10n?.voiceAssistantReply ?? 'Assistant:',
                style: TextStyle(
                  color: providerColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              if (isSpeaking)
                Row(
                  children: [
                    Icon(Icons.volume_up_rounded, color: providerColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Playing',
                      style: TextStyle(color: providerColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _assistantReply,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),

          // Audio control pill row (Replay & Stop)
          Row(
            children: [
              // Listen again button
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  minimumSize: const Size(0, 36),
                ),
                icon: const Icon(Icons.replay_rounded, size: 16),
                label: Text(
                  l10n?.voiceListenAgain ?? 'Listen again',
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final locale = ref.read(localeProvider);
                  final status = await ref.read(voiceServiceProvider).speak(
                        _assistantReply,
                        languageCode: locale.languageCode,
                        audioBase64: _lastResult?.audioBase64,
                      );
                  if (!mounted) return;
                  if (status == TtsPlaybackStatus.voiceUnavailable) {
                    setState(() {
                      _ttsNotice = l10n?.voiceLangNotInstalled ??
                          'Voice playback for this language is not installed on your device.';
                      _state = VoiceServiceState.idle;
                    });
                  } else {
                    setState(() {
                      _state = VoiceServiceState.speaking;
                    });
                  }
                },
              ),
              const SizedBox(width: 8),

              // Stop audio button (if currently speaking)
              if (isSpeaking)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFF59E0B),
                    backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    minimumSize: const Size(0, 36),
                  ),
                  icon: const Icon(Icons.stop_circle_outlined, size: 16),
                  label: Text(
                    l10n?.voiceStopAudio ?? 'Stop audio',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(voiceServiceProvider).stopSpeaking();
                    setState(() {
                      _state = VoiceServiceState.idle;
                    });
                  },
                ),
            ],
          ),

          if (_ttsNotice != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _ttsNotice!,
                      style: const TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDirectActionPill(VoiceIntentResult result) {
    IconData actionIcon;
    String actionLabel;

    switch (result.type) {
      case VoiceIntentType.findJobs:
        actionIcon = Icons.work_outline_rounded;
        actionLabel = 'Open Jobs Screen';
        break;
      case VoiceIntentType.findWorkers:
        actionIcon = Icons.group_outlined;
        actionLabel = 'View Available Workers';
        break;
      case VoiceIntentType.searchProduce:
      case VoiceIntentType.checkMandi:
        actionIcon = Icons.storefront_outlined;
        actionLabel = 'Open Produce Market';
        break;
      case VoiceIntentType.openWallet:
      case VoiceIntentType.checkEarnings:
        actionIcon = Icons.account_balance_wallet_outlined;
        actionLabel = 'View Wallet & Earnings';
        break;
      case VoiceIntentType.openSafety:
        actionIcon = Icons.shield_outlined;
        actionLabel = 'Open Safety & Emergency Hub';
        break;
      case VoiceIntentType.openProfile:
        actionIcon = Icons.person_outline_rounded;
        actionLabel = 'Open Profile';
        break;
      case VoiceIntentType.postJob:
        actionIcon = Icons.add_circle_outline_rounded;
        actionLabel = 'Post New Job Listing';
        break;
      case VoiceIntentType.viewOrders:
        actionIcon = Icons.receipt_long_outlined;
        actionLabel = 'View Orders';
        break;
      case VoiceIntentType.openSettings:
        actionIcon = Icons.settings_outlined;
        actionLabel = 'Open Settings';
        break;
      case VoiceIntentType.viewActiveJobs:
        actionIcon = Icons.assignment_outlined;
        actionLabel = 'View Active Jobs';
        break;
      case VoiceIntentType.viewSchedule:
        actionIcon = Icons.calendar_month_outlined;
        actionLabel = 'View My Schedule';
        break;
      case VoiceIntentType.viewApplicants:
        actionIcon = Icons.badge_outlined;
        actionLabel = 'View Job Applicants';
        break;
      case VoiceIntentType.digitalId:
        actionIcon = Icons.qr_code_2_rounded;
        actionLabel = 'View Digital ID & QR';
        break;
      case VoiceIntentType.scanVerify:
        actionIcon = Icons.qr_code_scanner_rounded;
        actionLabel = 'Open QR Scanner';
        break;
      case VoiceIntentType.openChat:
        actionIcon = Icons.chat_bubble_outline_rounded;
        actionLabel = 'Open Messages';
        break;
      case VoiceIntentType.openNotifications:
        actionIcon = Icons.notifications_none_rounded;
        actionLabel = 'View Notifications';
        break;
      case VoiceIntentType.farmAi:
        actionIcon = Icons.eco_outlined;
        actionLabel = 'Open Crop Doctor AI';
        break;
      case VoiceIntentType.goHome:
        actionIcon = Icons.home_outlined;
        actionLabel = 'Go to Home Dashboard';
        break;
      case VoiceIntentType.viewFavourites:
        actionIcon = Icons.favorite_border_rounded;
        actionLabel = 'View Saved Favourites';
        break;
      default:
        actionIcon = Icons.arrow_forward_rounded;
        actionLabel = 'Continue';
        break;
    }

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        shadowColor: AppColors.emerald.withValues(alpha: 0.4),
      ),
      icon: Icon(actionIcon, size: 18),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_forward_rounded, size: 16),
        ],
      ),
      onPressed: () {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop();
        final route = result.targetRoute;
        final router = GoRouter.maybeOf(context);
        if (router != null && route.isNotEmpty) {
          if (route.startsWith('/seeker/') ||
              route.startsWith('/provider/') ||
              route.startsWith('/farmer/')) {
            router.go(route);
          } else {
            router.push(route);
          }
        }
      },
    );
  }

  Widget _buildCentralOrb() {
    final isListening = _state == VoiceServiceState.listening;
    final isThinking = _state == VoiceServiceState.thinking || _state == VoiceServiceState.processing;
    final isSpeaking = _state == VoiceServiceState.speaking;
    final isError = _state == VoiceServiceState.error ||
        _state == VoiceServiceState.permissionDenied ||
        _state == VoiceServiceState.permissionPermanentlyDenied;

    // Normalize audio level to 0.0 - 1.0 (real sound level input)
    final normSound = isListening
        ? ((_soundLevel + 2.0) / 12.0).clamp(0.0, 1.0)
        : (isSpeaking ? 0.35 : 0.0);

    final dynamicScale = isListening
        ? 1.0 + (normSound * 0.35)
        : (isSpeaking ? 1.0 + (normSound * 0.15) : 1.0);

    return Semantics(
      button: true,
      label: isListening
          ? 'Voice Assistant listening. Tap to finish speaking.'
          : (isSpeaking
              ? 'Voice Assistant speaking. Tap to interrupt and speak.'
              : 'Voice Assistant idle. Tap to start speaking.'),
      child: AnimatedBuilder(
        animation: _orbAnimController,
        builder: (context, child) {
          final pulse = _orbAnimController.value;

          List<Color> orbColors;
          if (isThinking) {
            orbColors = const [Color(0xFFF59E0B), Color(0xFF8B5CF6), Color(0xFFEC4899)];
          } else if (isSpeaking) {
            orbColors = const [Color(0xFF00F2FE), Color(0xFF10B981), Color(0xFF3B82F6)];
          } else if (isListening) {
            orbColors = const [Color(0xFF00F2FE), Color(0xFF10B981), Color(0xFF06B6D4)];
          } else if (isError) {
            orbColors = const [Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFFDC2626)];
          } else {
            orbColors = const [Color(0xFF06B6D4), Color(0xFF10B981), Color(0xFF4F46E5)];
          }

          return Stack(
            alignment: Alignment.center,
            children: [
              // 1. Outermost Acoustic Resonance Aura (expands with live audio level)
              Transform.scale(
                scale: (1.32 + (pulse * 0.18) + (normSound * 0.38)) * dynamicScale,
                child: Container(
                  width: 205,
                  height: 205,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: orbColors[0].withValues(alpha: isListening ? (0.12 + (normSound * 0.14)) : 0.04),
                  ),
                ),
              ),

              // 2. Middle Organic Glow Ring (Breathing)
              Transform.scale(
                scale: (1.18 + (pulse * 0.10)) * dynamicScale,
                child: Container(
                  width: 175,
                  height: 175,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: orbColors[1].withValues(alpha: isListening ? (0.22 + (normSound * 0.15)) : 0.08),
                  ),
                ),
              ),

              // 3. Inner Reactive Corona
              Transform.scale(
                scale: (1.06 + (pulse * 0.06)) * dynamicScale,
                child: Container(
                  width: 152,
                  height: 152,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: orbColors[0].withValues(alpha: isListening ? 0.32 : 0.16),
                  ),
                ),
              ),

              // 4. Core animated plasma orb with SweepGradient
              Transform.scale(
                scale: dynamicScale,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: orbColors,
                      transform: GradientRotation(_orbAnimController.value * 2 * math.pi),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: orbColors[0].withValues(alpha: isListening ? 0.75 : 0.50),
                        blurRadius: isListening ? (36 + (normSound * 16)) : 26,
                        spreadRadius: isListening ? (4 + (normSound * 4)) : 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 114,
                      height: 114,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF0F172A).withValues(alpha: 0.85),
                            const Color(0xFF050B14).withValues(alpha: 0.95),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          isSpeaking
                              ? Icons.volume_up_rounded
                              : isThinking
                                  ? Icons.auto_awesome
                                  : (isError
                                      ? Icons.refresh_rounded
                                      : Icons.mic_rounded),
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAudioWaveformVisualizer() {
    final isListening = _state == VoiceServiceState.listening;
    final isSpeaking = _state == VoiceServiceState.speaking;
    final isThinking = _state == VoiceServiceState.thinking || _state == VoiceServiceState.processing;

    final normSound = isListening
        ? ((_soundLevel + 2.0) / 12.0).clamp(0.0, 1.0)
        : (isSpeaking ? 0.35 : 0.0);

    return AnimatedBuilder(
      animation: _waveAnimController,
      builder: (context, child) {
        final animVal = _waveAnimController.value;

        return SizedBox(
          height: 28,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(9, (i) {
              final centerDist = (4 - i).abs();
              final centerWeight = 1.0 - (centerDist * 0.16);

              double barHeight = 4.0;
              if (isListening) {
                final wavePhase = math.sin((animVal * 2 * math.pi) + (i * 0.7)).abs();
                barHeight = (4.0 + (wavePhase * 12.0 * centerWeight) + (normSound * 22.0 * centerWeight)).clamp(4.0, 28.0);
              } else if (isSpeaking) {
                final wavePhase = math.sin((animVal * 2 * math.pi) + (i * 0.9)).abs();
                barHeight = (4.0 + (wavePhase * 20.0 * centerWeight)).clamp(4.0, 24.0);
              } else if (isThinking) {
                final wavePhase = math.sin((animVal * 2 * math.pi) + (i * 0.45)).abs();
                barHeight = (4.0 + (wavePhase * 8.0 * centerWeight)).clamp(4.0, 14.0);
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                width: 3.5,
                height: barHeight,
                decoration: BoxDecoration(
                  color: isListening
                      ? const Color(0xFF00F2FE)
                      : isSpeaking
                          ? const Color(0xFF10B981)
                          : isThinking
                              ? const Color(0xFFF59E0B)
                              : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildStateIndicatorPill(AppLocalizations? l10n) {
    String stateText;
    Color stateColor;
    IconData stateIcon;

    switch (_state) {
      case VoiceServiceState.requestingPermission:
        stateText = 'Checking microphone...';
        stateColor = const Color(0xFF06B6D4);
        stateIcon = Icons.lock_clock_rounded;
        break;
      case VoiceServiceState.listening:
        stateText = l10n?.voiceListeningNow ?? 'Listening... Speak now';
        stateColor = const Color(0xFF00F2FE);
        stateIcon = Icons.mic_rounded;
        break;
      case VoiceServiceState.processing:
      case VoiceServiceState.thinking:
        stateText = l10n?.voiceThinking ?? 'Finding the right information...';
        stateColor = const Color(0xFFF59E0B);
        stateIcon = Icons.hourglass_top_rounded;
        break;
      case VoiceServiceState.speaking:
        stateText = l10n?.voiceSpeaking ?? 'Speaking reply (Tap to interrupt)';
        stateColor = const Color(0xFF10B981);
        stateIcon = Icons.graphic_eq_rounded;
        break;
      case VoiceServiceState.cancelled:
        stateText = 'Cancelled';
        stateColor = Colors.white60;
        stateIcon = Icons.cancel_outlined;
        break;
      case VoiceServiceState.error:
        stateText = l10n?.voiceHearError ?? 'I didn\'t catch that. Tap to try again';
        stateColor = Colors.white70;
        stateIcon = Icons.mic_none_rounded;
        break;
      case VoiceServiceState.missingLanguagePack:
        stateText = 'Language pack missing. Check settings.';
        stateColor = const Color(0xFFF59E0B);
        stateIcon = Icons.language_rounded;
        break;
      case VoiceServiceState.permissionDenied:
      case VoiceServiceState.permissionPermanentlyDenied:
        stateText = l10n?.voiceMicRequired ?? 'Microphone permission required';
        stateColor = const Color(0xFFEF4444);
        stateIcon = Icons.mic_off_rounded;
        break;
      case VoiceServiceState.idle:
        stateText = l10n?.voiceTapOrbToSpeak ?? 'Tap orb to speak';
        stateColor = Colors.white60;
        stateIcon = Icons.touch_app_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: stateColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: stateColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(stateIcon, color: stateColor, size: 14),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              stateText,
              style: TextStyle(
                color: stateColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChipsRow(UserRole role, AppLocalizations? l10n) {
    final suggestions = _getRoleSuggestions(role, l10n);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: suggestions.map((item) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _processQuery(item.title);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132238),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, size: 15, color: const Color(0xFF00F2FE)),
                      const SizedBox(width: 6),
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomInputDock(AppLocalizations? l10n) {
    if (_isKeyboardMode) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.viewInsetsOf(context).bottom + 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: l10n?.voiceTypeHint ?? 'Type your question here...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF132238),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFF00F2FE), width: 1.5),
                  ),
                ),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    _processQuery(val.trim());
                    _textController.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: Color(0xFF00F2FE)),
              onPressed: () {
                if (_textController.text.trim().isNotEmpty) {
                  _processQuery(_textController.text.trim());
                  _textController.clear();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.mic_rounded, color: Colors.white70),
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _isKeyboardMode = false);
                _startListening();
              },
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white70,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          icon: const Icon(Icons.keyboard_rounded, size: 18),
          label: Text(
            l10n?.voiceTypeInstead ?? 'Type instead',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() => _isKeyboardMode = true);
          },
        ),
      ),
    );
  }

  Widget _buildPermissionBanner(AppLocalizations? l10n) {
    final isPermPermanentlyDenied =
        _micPermission == MicrophonePermissionState.permanentlyDenied;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.mic_off_rounded, color: Color(0xFFEF4444), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n?.voiceMicRequired ?? 'Microphone permission required',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isPermPermanentlyDenied
                ? (l10n?.voiceMicPermanentDesc ?? 'Please open App Settings to allow microphone access.')
                : (l10n?.voiceMicDeniedDesc ?? 'Tap Grant Permission to enable voice commands.'),
            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              HapticFeedback.lightImpact();
              if (isPermPermanentlyDenied) {
                await openAppSettings();
              } else {
                _startListening();
              }
            },
            child: Text(
              isPermPermanentlyDenied
                  ? (l10n?.voiceOpenSettings ?? 'Open Settings')
                  : (l10n?.voiceGrantPermission ?? 'Grant Permission'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHearErrorBanner(AppLocalizations? l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic_none_rounded, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n?.voiceHearError ?? 'I didn\'t catch that. Tap to try again',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: _startListening,
            child: Text(
              l10n?.retry ?? 'Retry',
              style: const TextStyle(color: Color(0xFF00F2FE)),
            ),
          ),
        ],
      ),
    );
  }
}
