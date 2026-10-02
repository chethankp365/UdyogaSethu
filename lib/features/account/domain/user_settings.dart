import 'package:flutter/foundation.dart';

@immutable
class UserSettings {
  final String language;
  final bool simpleMode;
  final double textScale;
  final bool voiceHints;
  final bool lowDataMode;

  const UserSettings({
    this.language = 'en',
    this.simpleMode = false,
    this.textScale = 1.00,
    this.voiceHints = true,
    this.lowDataMode = false,
  });

  UserSettings copyWith({
    String? language,
    bool? simpleMode,
    double? textScale,
    bool? voiceHints,
    bool? lowDataMode,
  }) {
    return UserSettings(
      language: language ?? this.language,
      simpleMode: simpleMode ?? this.simpleMode,
      textScale: textScale ?? this.textScale,
      voiceHints: voiceHints ?? this.voiceHints,
      lowDataMode: lowDataMode ?? this.lowDataMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'simple_mode': simpleMode,
      'text_scale': textScale,
      'voice_hints': voiceHints,
      'low_data_mode': lowDataMode,
    };
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      language: json['language'] as String? ?? 'en',
      simpleMode: json['simple_mode'] as bool? ?? false,
      textScale: (json['text_scale'] as num?)?.toDouble() ?? 1.00,
      voiceHints: json['voice_hints'] as bool? ?? true,
      lowDataMode: json['low_data_mode'] as bool? ?? false,
    );
  }
}
