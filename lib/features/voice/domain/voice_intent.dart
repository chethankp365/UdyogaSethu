import 'package:flutter/foundation.dart';

/// Supported voice intents in UdyogaSethu
enum VoiceIntentType {
  findJobs,
  findWorkers,
  searchProduce,
  checkEarnings,
  viewOrders,
  openWallet,
  openSafety,
  openSettings,
  unknown,
}

extension VoiceIntentTypeExtension on VoiceIntentType {
  String get code {
    switch (this) {
      case VoiceIntentType.findJobs:
        return 'find_jobs';
      case VoiceIntentType.findWorkers:
        return 'find_workers';
      case VoiceIntentType.searchProduce:
        return 'search_produce';
      case VoiceIntentType.checkEarnings:
        return 'check_earnings';
      case VoiceIntentType.viewOrders:
        return 'view_orders';
      case VoiceIntentType.openWallet:
        return 'open_wallet';
      case VoiceIntentType.openSafety:
        return 'open_safety';
      case VoiceIntentType.openSettings:
        return 'open_settings';
      case VoiceIntentType.unknown:
        return 'unknown';
    }
  }

  static VoiceIntentType fromCode(String? code) {
    switch (code?.toLowerCase()) {
      case 'find_jobs':
      case 'findjobs':
        return VoiceIntentType.findJobs;
      case 'find_workers':
      case 'findworkers':
        return VoiceIntentType.findWorkers;
      case 'search_produce':
      case 'searchproduce':
        return VoiceIntentType.searchProduce;
      case 'check_earnings':
      case 'checkearnings':
        return VoiceIntentType.checkEarnings;
      case 'view_orders':
      case 'vieworders':
        return VoiceIntentType.viewOrders;
      case 'open_wallet':
      case 'openwallet':
        return VoiceIntentType.openWallet;
      case 'open_safety':
      case 'opensafety':
        return VoiceIntentType.openSafety;
      case 'open_settings':
      case 'opensettings':
        return VoiceIntentType.openSettings;
      default:
        return VoiceIntentType.unknown;
    }
  }
}

/// Parsed voice intent parameters
@immutable
class VoiceIntentParameters {
  final String? category;
  final String? produce;
  final String? query;
  final int? minPrice;
  final int? maxPrice;
  final double? radiusKm;

  const VoiceIntentParameters({
    this.category,
    this.produce,
    this.query,
    this.minPrice,
    this.maxPrice,
    this.radiusKm,
  });

  Map<String, dynamic> toMap() => {
        if (category != null) 'category': category,
        if (produce != null) 'produce': produce,
        if (query != null) 'query': query,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (radiusKm != null) 'radiusKm': radiusKm,
      };
}

/// Result of parsing or classifying spoken speech
@immutable
class VoiceIntentResult {
  final VoiceIntentType type;
  final String rawText;
  final double confidence;
  final VoiceIntentParameters parameters;
  final String targetRoute;
  final String spokenReply;
  final bool isAiFallback;

  const VoiceIntentResult({
    required this.type,
    required this.rawText,
    required this.confidence,
    this.parameters = const VoiceIntentParameters(),
    required this.targetRoute,
    required this.spokenReply,
    this.isAiFallback = false,
  });

  bool get isRecognized => type != VoiceIntentType.unknown;

  factory VoiceIntentResult.unrecognized(String rawText, {String? customReply}) {
    return VoiceIntentResult(
      type: VoiceIntentType.unknown,
      rawText: rawText,
      confidence: 0.0,
      targetRoute: '',
      spokenReply: customReply ?? 'Sorry, I did not understand that command. Please try again.',
      isAiFallback: false,
    );
  }
}
