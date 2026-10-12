import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/account/presentation/settings_controller.dart';
import 'package:udyogasethu/features/voice/data/voice_service.dart';

/// Helper to trigger concise spoken audio instructions on key screens.
class VoiceHintsHelper {
  VoiceHintsHelper._();

  static Future<void> speakScreenHint(
    WidgetRef ref, {
    required String hintText,
    String? languageCode,
  }) async {
    final settings = ref.read(userSettingsNotifierProvider);
    if (!settings.voiceHints) return;

    try {
      final lang = languageCode ?? settings.language;
      final voice = ref.read(voiceServiceProvider);
      await voice.speak(hintText, languageCode: lang);
    } catch (_) {
      // Gracefully catch unavailable speech engine
    }
  }
}

/// Accessible speaker icon button for repeating voice hints on demand.
class VoiceHintSpeakerButton extends ConsumerWidget {
  final String hintText;
  final String? languageCode;
  final Color? color;

  const VoiceHintSpeakerButton({
    super.key,
    required this.hintText,
    this.languageCode,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(Icons.volume_up_rounded, color: color ?? AppColors.headerGreenDark),
      tooltip: 'Play voice instruction',
      onPressed: () {
        final lang = languageCode ?? ref.read(userSettingsNotifierProvider).language;
        ref.read(voiceServiceProvider).speak(hintText, languageCode: lang);
      },
    );
  }
}
