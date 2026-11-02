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
  openProfile,
  openSettings,
  postJob,
  checkMandi,
  confirmSos,
  answerQuestion,
  viewActiveJobs,
  viewSchedule,
  viewApplicants,
  digitalId,
  scanVerify,
  openChat,
  openNotifications,
  farmAi,
  goHome,
  viewFavourites,
  unknown,
}

extension VoiceIntentTypeExtension on VoiceIntentType {
  String get code {
    switch (this) {
      case VoiceIntentType.findJobs:
        return 'open_nearby_jobs';
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
      case VoiceIntentType.openProfile:
        return 'open_profile';
      case VoiceIntentType.openSettings:
        return 'open_settings';
      case VoiceIntentType.postJob:
        return 'post_job';
      case VoiceIntentType.checkMandi:
        return 'check_mandi';
      case VoiceIntentType.confirmSos:
        return 'confirm_sos';
      case VoiceIntentType.answerQuestion:
        return 'answer_question';
      case VoiceIntentType.viewActiveJobs:
        return 'view_active_jobs';
      case VoiceIntentType.viewSchedule:
        return 'view_schedule';
      case VoiceIntentType.viewApplicants:
        return 'view_applicants';
      case VoiceIntentType.digitalId:
        return 'digital_id';
      case VoiceIntentType.scanVerify:
        return 'scan_verify';
      case VoiceIntentType.openChat:
        return 'open_chat';
      case VoiceIntentType.openNotifications:
        return 'open_notifications';
      case VoiceIntentType.farmAi:
        return 'farm_ai';
      case VoiceIntentType.goHome:
        return 'go_home';
      case VoiceIntentType.viewFavourites:
        return 'view_favourites';
      case VoiceIntentType.unknown:
        return 'unknown';
    }
  }

  static VoiceIntentType fromCode(String? code) {
    final clean = (code ?? '').toLowerCase().replaceAll('_', '').replaceAll('-', '').replaceAll(' ', '');
    switch (clean) {
      case 'opennearbyjobs':
      case 'findjobs':
      case 'nearbyjobs':
      case 'jobs':
        return VoiceIntentType.findJobs;
      case 'findworkers':
      case 'hireworkers':
      case 'workers':
        return VoiceIntentType.findWorkers;
      case 'searchproduce':
      case 'marketplace':
        return VoiceIntentType.searchProduce;
      case 'checkearnings':
      case 'earnings':
        return VoiceIntentType.checkEarnings;
      case 'vieworders':
      case 'orders':
        return VoiceIntentType.viewOrders;
      case 'openwallet':
      case 'wallet':
        return VoiceIntentType.openWallet;
      case 'opensafety':
      case 'safety':
      case 'safetyhub':
        return VoiceIntentType.openSafety;
      case 'openprofile':
      case 'profile':
        return VoiceIntentType.openProfile;
      case 'opensettings':
      case 'settings':
        return VoiceIntentType.openSettings;
      case 'postjob':
      case 'newjob':
      case 'postnewjob':
        return VoiceIntentType.postJob;
      case 'checkmandi':
      case 'mandiprices':
      case 'mandi':
        return VoiceIntentType.checkMandi;
      case 'confirmsos':
      case 'sos':
      case 'emergency':
        return VoiceIntentType.confirmSos;
      case 'viewactivejobs':
      case 'activejobs':
      case 'myjobs':
        return VoiceIntentType.viewActiveJobs;
      case 'viewschedule':
      case 'schedule':
      case 'timetable':
        return VoiceIntentType.viewSchedule;
      case 'viewapplicants':
      case 'applicants':
      case 'candidates':
        return VoiceIntentType.viewApplicants;
      case 'digitalid':
      case 'id':
      case 'myqr':
      case 'qrcode':
        return VoiceIntentType.digitalId;
      case 'scanverify':
      case 'scan':
      case 'scanner':
        return VoiceIntentType.scanVerify;
      case 'openchat':
      case 'chat':
      case 'messages':
      case 'inbox':
        return VoiceIntentType.openChat;
      case 'opennotifications':
      case 'notifications':
      case 'alerts':
        return VoiceIntentType.openNotifications;
      case 'farmai':
      case 'crophelp':
      case 'pestai':
      case 'soilai':
        return VoiceIntentType.farmAi;
      case 'gohome':
      case 'home':
      case 'dashboard':
        return VoiceIntentType.goHome;
      case 'viewfavourites':
      case 'favourites':
      case 'favorites':
      case 'savedjobs':
        return VoiceIntentType.viewFavourites;
      case 'answerquestion':
      case 'generalhelp':
      case 'faq':
        return VoiceIntentType.answerQuestion;
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

  factory VoiceIntentParameters.fromJson(Map<String, dynamic> json) {
    return VoiceIntentParameters(
      category: json['category']?.toString(),
      produce: json['produce']?.toString(),
      query: json['search_query']?.toString() ?? json['query']?.toString(),
      minPrice: (json['min_wage'] as num?)?.toInt() ?? (json['minPrice'] as num?)?.toInt(),
      maxPrice: (json['max_wage'] as num?)?.toInt() ?? (json['maxPrice'] as num?)?.toInt(),
      radiusKm: (json['radius_km'] as num?)?.toDouble() ?? (json['radiusKm'] as num?)?.toDouble(),
    );
  }
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
  final String? provider;
  final String? model;
  final int? latencyMs;
  final String? audioBase64;
  final String? audioMime;
  final List<String>? fallbackChain;

  const VoiceIntentResult({
    required this.type,
    required this.rawText,
    required this.confidence,
    this.parameters = const VoiceIntentParameters(),
    required this.targetRoute,
    required this.spokenReply,
    this.isAiFallback = false,
    this.provider,
    this.model,
    this.latencyMs,
    this.audioBase64,
    this.audioMime,
    this.fallbackChain,
  });

  bool get isRecognized => type != VoiceIntentType.unknown;

  factory VoiceIntentResult.unrecognized(String rawText, {String? customReply}) {
    return VoiceIntentResult(
      type: VoiceIntentType.unknown,
      rawText: rawText,
      confidence: 0.0,
      targetRoute: '',
      spokenReply: customReply ?? 'I did not understand that command. Please try again.',
      isAiFallback: false,
      provider: 'rule_engine',
    );
  }
}
