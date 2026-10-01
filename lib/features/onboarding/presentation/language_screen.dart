import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/l10n/locale_controller.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';
import 'package:udyogasethu/core/widgets/app_button.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

/// Multilingual Language Selection Screen matching Screen 3 in UI_REFERENCE.md.
class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlayingTts = false;
  bool _showVoiceMissingHint = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _isPlayingTts = false);
      });
      _flutterTts.setErrorHandler((_) {
        if (mounted) {
          setState(() {
            _isPlayingTts = false;
            _showVoiceMissingHint = true;
          });
        }
      });
    } catch (_) {
      // Ignore initial TTS setup error
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speakWelcome(AppLanguageOption selectedLang) async {
    setState(() {
      _isPlayingTts = true;
      _showVoiceMissingHint = false;
    });

    try {
      final ttsLangCode = _getTtsLanguageCode(selectedLang.code);
      final isAvailable = await _flutterTts.isLanguageAvailable(ttsLangCode);

      if (isAvailable == true || isAvailable == 1) {
        await _flutterTts.setLanguage(ttsLangCode);
        await _flutterTts.speak(selectedLang.welcomeText);
      } else {
        setState(() {
          _isPlayingTts = false;
          _showVoiceMissingHint = true;
        });
      }
    } catch (_) {
      setState(() {
        _isPlayingTts = false;
        _showVoiceMissingHint = true;
      });
    }
  }

  String _getTtsLanguageCode(String code) {
    switch (code) {
      case 'kn':
        return 'kn-IN';
      case 'hi':
        return 'hi-IN';
      case 'te':
        return 'te-IN';
      case 'ta':
        return 'ta-IN';
      case 'mr':
        return 'mr-IN';
      case 'bn':
        return 'bn-IN';
      case 'or':
        return 'or-IN';
      default:
        return 'en-US';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final selectedOption = AppLanguages.fromCode(currentLocale.languageCode);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar with UdyogaSethu Logo
              Image.asset(
                'assets/images/logo_small.png',
                height: 38,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 16),

              // 2. Title & Subtitle
              Text(
                l10n.languageScreenTitle,
                style: AppTypography.displayMedium(AppColors.headerGreenDark).copyWith(
                  fontSize: 22,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                l10n.languageScreenSubtitle,
                style: AppTypography.bodyMedium(AppColors.textMuted),
              ),

              const SizedBox(height: 16),

              // 3. 2-Column Grid of 8 Language Selector Cards
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: AppLanguages.all.length,
                  itemBuilder: (context, index) {
                    final lang = AppLanguages.all[index];
                    final isSelected = currentLocale.languageCode == lang.code;

                    return _LanguageCardTile(
                      lang: lang,
                      isSelected: isSelected,
                      onTap: () {
                        ref.read(localeProvider.notifier).setLocale(lang.code);
                        setState(() => _showVoiceMissingHint = false);
                      },
                    );
                  },
                ),
              ),

              // Voice Data Missing Hint Banner
              if (_showVoiceMissingHint) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warningOrange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.darkOrange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.ttsVoiceMissingHint(selectedOption.englishName),
                          style: AppTypography.bodySmall(AppColors.textDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 4. Secondary Audio Preview Button (► Listen to welcome in <language>)
              OutlinedButton.icon(
                onPressed: _isPlayingTts ? null : () => _speakWelcome(selectedOption),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                  side: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  backgroundColor: AppColors.paleMint,
                ),
                icon: _isPlayingTts
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.headerGreenDark),
                      )
                    : const Icon(Icons.play_arrow_rounded, color: AppColors.headerGreenDark, size: 20),
                label: Text(
                  l10n.listenToWelcomeIn(
                    selectedOption.code == 'en' ? selectedOption.englishName : selectedOption.nativeName,
                  ),
                  style: AppTypography.button(AppColors.headerGreenDark).copyWith(fontSize: 14),
                ),
              ),

              const SizedBox(height: 12),

              // 5. Primary Action Button (Continue ->)
              AppButton(
                label: l10n.continueButton,
                onPressed: () => context.go(AppRoutes.login),
                variant: AppButtonVariant.primary,
                fullWidth: true,
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCardTile extends StatelessWidget {
  final AppLanguageOption lang;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCardTile({
    required this.lang,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isSelected ? AppColors.paleMint : Colors.white;
    final borderColor = isSelected ? AppColors.primaryTeal : AppColors.borderLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            // Country Badge (GB / IN)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryTeal : AppColors.borderLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                lang.countryCode,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Language Name Stack
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.code == 'en' ? 'English' : '${lang.nativeName} (${lang.englishName})',
                    style: AppTypography.titleSmall(AppColors.textDark).copyWith(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Radio Checkmark Circle
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: isSelected ? AppColors.primaryTeal : AppColors.dividerLight,
            ),
          ],
        ),
      ),
    );
  }
}
