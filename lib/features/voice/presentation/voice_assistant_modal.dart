import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_spacing.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';
import 'package:udyogasethu/core/l10n/locale_controller.dart';
import 'package:udyogasethu/features/voice/data/voice_service.dart';
import 'package:udyogasethu/features/voice/domain/voice_intent.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

/// Screen 9: AI Multilingual Voice Assistant Overlay (Dark Navy #0F172A)
class VoiceAssistantModal extends ConsumerStatefulWidget {
  const VoiceAssistantModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VoiceAssistantModal(),
    );
  }

  @override
  ConsumerState<VoiceAssistantModal> createState() => _VoiceAssistantModalState();
}

class _VoiceAssistantModalState extends ConsumerState<VoiceAssistantModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  VoiceServiceState _state = VoiceServiceState.idle;
  String _recognizedText = '';
  VoiceIntentResult? _intentResult;
  String? _errorMessage;
  late VoiceService _voiceService;

  @override
  void initState() {
    super.initState();
    _voiceService = ref.read(voiceServiceProvider);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // Auto-start listening on modal presentation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startVoiceSession();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _voiceService.stopListening();
    _voiceService.stopSpeaking();
    super.dispose();
  }

  String _getLanguageName(String langCode) {
    if (langCode.startsWith('kn')) return 'ಕನ್ನಡ (Kannada)';
    if (langCode.startsWith('hi')) return 'हिंदी (Hindi)';
    if (langCode.startsWith('te')) return 'తెలుగు (Telugu)';
    if (langCode.startsWith('ta')) return 'தமிழ் (Tamil)';
    return 'English';
  }

  List<String> _getExampleCommands(String langCode) {
    if (langCode.startsWith('kn')) {
      return [
        'ಪ್ಲಂಬರ್ ಕೆಲಸ ಬೇಕು',
        'ಇಂದಿನ ಗಳಿಕೆ ತೋರಿಸಿ',
        'ಟೊಮೆಟೊ ಮಾರುವ ರೈತರು',
        'ಕಟ್ಟಡ ಕೆಲಸ ಹುಡುಕಿ',
      ];
    }
    if (langCode.startsWith('hi')) {
      return [
        'प्लंबर का काम ढूंढो',
        'आज की कमाई दिखाओ',
        'टमाटर बेचने वाले किसान',
        'निर्माण कार्य ढूंढो',
      ];
    }
    if (langCode.startsWith('te')) {
      return [
        'ప్లంబర్ పని కావాలి',
        'ఈ రోజు సంపాదన చూపించు',
        'టమోటా అమ్మే రైతులు',
        'నిర్మాణ పని వెతకండి',
      ];
    }
    if (langCode.startsWith('ta')) {
      return [
        'பிளம்பர் வேலை வேண்டும்',
        'இன்றைய வருமானம் காட்டு',
        'தக்காளி விற்கும் விவசாயிகள்',
        'கட்டிட வேலை தேடுங்கள்',
      ];
    }
    return [
      'find plumber near me',
      'show today\'s earnings',
      'farmers selling tomatoes',
      'find construction work',
    ];
  }

  Future<void> _startVoiceSession() async {
    final voiceService = ref.read(voiceServiceProvider);
    final locale = ref.read(localeProvider);
    final langCode = locale.languageCode;

    setState(() {
      _state = VoiceServiceState.listening;
      _recognizedText = '';
      _intentResult = null;
      _errorMessage = null;
    });

    final isSupported = voiceService.isLocaleSupported(langCode);
    if (!isSupported) {
      setState(() {
        _state = VoiceServiceState.missingLanguagePack;
      });
      return;
    }

    final started = await voiceService.startListening(
      languageCode: langCode,
      onPartialResult: (text) {
        if (mounted) {
          setState(() {
            _recognizedText = text;
          });
        }
      },
      onFinalResult: (text) {
        if (mounted) {
          _processSpokenText(text, langCode);
        }
      },
      onError: () {
        if (mounted) {
          setState(() {
            _state = VoiceServiceState.error;
            _errorMessage = 'Speech service unavailable. Please tap an example command.';
          });
        }
      },
    );

    if (!started && mounted) {
      setState(() {
        _state = VoiceServiceState.error;
        _errorMessage = 'Microphone permission denied or speech engine not available.';
      });
    }
  }

  Future<void> _stopListening() async {
    final voiceService = ref.read(voiceServiceProvider);
    await voiceService.stopListening();
    if (_recognizedText.isNotEmpty) {
      final locale = ref.read(localeProvider);
      _processSpokenText(_recognizedText, locale.languageCode);
    } else {
      setState(() {
        _state = VoiceServiceState.idle;
      });
    }
  }

  Future<void> _processSpokenText(String text, String langCode) async {
    if (text.trim().isEmpty) {
      setState(() {
        _state = VoiceServiceState.idle;
      });
      return;
    }

    setState(() {
      _state = VoiceServiceState.processing;
      _recognizedText = text;
    });

    final voiceService = ref.read(voiceServiceProvider);
    final result = await voiceService.classify(text: text, languageCode: langCode);

    if (mounted) {
      setState(() {
        _intentResult = result;
        _state = VoiceServiceState.recognized;
      });

      // Spoken reply confirmation
      if (result.isRecognized) {
        voiceService.speak(result.spokenReply, languageCode: langCode);
      }
    }
  }

  void _onExampleChipTap(String exampleText) {
    final locale = ref.read(localeProvider);
    _processSpokenText(exampleText, locale.languageCode);
  }

  void _navigateToRoute(String route) {
    if (route.isEmpty) return;
    Navigator.of(context).pop();
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.read(localeProvider);
    final langCode = locale.languageCode;
    final langName = _getLanguageName(langCode);
    final examples = _getExampleCommands(langCode);
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Dark Navy Background
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Header: Title & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      l10n?.voiceAssistantTitle ?? 'AI MULTILINGUAL VOICE ASSISTANT',
                      textAlign: TextAlign.center,
                      style: AppTypography.titleSmall(Colors.white).copyWith(
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    tooltip: 'Close',
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.minTouchTarget,
                      minHeight: AppSpacing.minTouchTarget,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Language Indicator Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: AppSpacing.borderRadiusPill,
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language_rounded, color: AppColors.primaryTeal, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Language: $langName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Large Animated Mic Pulse Circle
              _buildMicButton(),

              const SizedBox(height: 20),

              // Main Status & Sub-status
              _buildStatusTexts(l10n),

              const SizedBox(height: 20),

              // Recognized Result Card or Fallback Card
              if (_intentResult != null) ...[
                _buildResultCard(_intentResult!),
                const SizedBox(height: 16),
              ],

              // Missing language pack helper banner
              if (_state == VoiceServiceState.missingLanguagePack) ...[
                _buildMissingPackBanner(langName),
                const SizedBox(height: 16),
              ],

              // Error banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade700),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // TAP EXAMPLE COMMAND TO DIRECT SEARCH
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n?.voiceExampleCommandsTitle ?? 'TAP EXAMPLE COMMAND TO DIRECT SEARCH',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 4 Tappable Suggestion Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                children: examples.map((cmd) {
                  return InkWell(
                    onTap: () => _onExampleChipTap(cmd),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Text(
                        '"$cmd"',
                        style: const TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Bottom Pill Button: Listening / Stop / Tap to Speak
              _buildBottomActionButton(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMicButton() {
    final isListening = _state == VoiceServiceState.listening;

    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = isListening ? _pulseAnimation.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: GestureDetector(
              onTap: () {
                if (isListening) {
                  _stopListening();
                } else {
                  _startVoiceSession();
                }
              },
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isListening ? const Color(0xFF00875A) : const Color(0xFF1E293B),
                  boxShadow: isListening
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00875A).withValues(alpha: 0.5),
                            blurRadius: 24,
                            spreadRadius: 6,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ],
                  border: Border.all(
                    color: isListening ? const Color(0xFF10B981) : const Color(0xFF475569),
                    width: 3,
                  ),
                ),
                child: Icon(
                  isListening ? Icons.mic : Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusTexts(AppLocalizations? l10n) {
    String title = l10n?.voiceListening ?? 'Listening to your voice...';
    String subtitle = l10n?.voiceInstruction ?? 'Tap mic and speak in Kannada, Hindi, Telugu, Tamil or English';

    if (_state == VoiceServiceState.processing) {
      title = l10n?.voiceProcessing ?? 'Understanding command...';
      subtitle = 'Processing speech with multi-lingual intent engine';
    } else if (_state == VoiceServiceState.recognized) {
      title = 'Command recognized!';
      subtitle = _recognizedText.isNotEmpty ? '"$_recognizedText"' : 'Executing requested action';
    } else if (_state == VoiceServiceState.idle) {
      title = 'Ready to listen';
      subtitle = 'Tap mic or select an example command below';
    }

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildResultCard(VoiceIntentResult result) {
    final isRecognized = result.isRecognized;
    final color = isRecognized ? const Color(0xFF10B981) : Colors.amber;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRecognized ? Icons.check_circle_rounded : Icons.help_outline_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRecognized
                      ? 'Matched Intent: ${result.type.name.toUpperCase()}'
                      : 'Unrecognized Command',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              if (result.isAiFallback)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade900,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'AI Assist',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.spokenReply,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          if (isRecognized && result.targetRoute.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _navigateToRoute(result.targetRoute),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Open Result Screen', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMissingPackBanner(String langName) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade900.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade600),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Voice Pack for $langName Needed',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'To enable device voice recognition for this language:\n'
            '1. Open Android Settings > System > Languages & Input\n'
            '2. Select Google Voice Typing / Speech Recognition\n'
            '3. Tap Offline Speech Recognition and install your language pack.',
            style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButton(AppLocalizations? l10n) {
    final isListening = _state == VoiceServiceState.listening;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isListening ? const Color(0xFFDC2626) : const Color(0xFF00875A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          elevation: 2,
        ),
        onPressed: () {
          if (isListening) {
            _stopListening();
          } else {
            _startVoiceSession();
          }
        },
        icon: Icon(isListening ? Icons.stop_rounded : Icons.mic_rounded),
        label: Flexible(
          child: Text(
            isListening
                ? (l10n?.voiceListeningStop ?? '🎙 Listening... (Tap to stop)')
                : (l10n?.voiceTapToSpeak ?? '🎙 Tap to Speak'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
