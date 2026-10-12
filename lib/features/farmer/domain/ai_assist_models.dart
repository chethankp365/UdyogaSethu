import 'package:flutter/foundation.dart';

@immutable
class AiAssistResponse<T> {
  final bool ok;
  final String mode; // 'gemini' | 'basic'
  final String? model;
  final String disclaimer;
  final T result;

  const AiAssistResponse({
    required this.ok,
    required this.mode,
    this.model,
    required this.disclaimer,
    required this.result,
  });

  bool get isGemini => mode == 'gemini';
  bool get isBasic => mode == 'basic';
}

@immutable
class PestDiagnosisResult {
  final String likelyCause;
  final String? confidenceLevel;
  final String? symptomsAnalysis;
  final List<String> organicRemedies;
  final String? chemicalAdvice;
  final List<String> preventionTips;
  final String expertWarning;

  const PestDiagnosisResult({
    required this.likelyCause,
    this.confidenceLevel,
    this.symptomsAnalysis,
    required this.organicRemedies,
    this.chemicalAdvice,
    this.preventionTips = const [],
    required this.expertWarning,
  });

  factory PestDiagnosisResult.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      }
      return [];
    }

    return PestDiagnosisResult(
      likelyCause: json['likely_cause']?.toString() ??
          json['likelyCause']?.toString() ??
          'Leaf spot or sap-sucking pest symptoms',
      confidenceLevel: json['confidence_level']?.toString() ?? json['confidence']?.toString(),
      symptomsAnalysis: json['symptoms_analysis']?.toString(),
      organicRemedies: parseList(json['organic_remedies'] ?? json['organicRemedies']),
      chemicalAdvice: json['chemical_options']?.toString() ??
          json['chemical_advice']?.toString() ??
          json['chemicalOptions']?.toString(),
      preventionTips: parseList(json['prevention_tips'] ?? json['preventionTips']),
      expertWarning: json['expert_warning']?.toString() ??
          json['expert_note']?.toString() ??
          'Always confirm chemical dosage with your local Raitha Samparka Kendra agronomist before spraying.',
    );
  }
}

@immutable
class SoilAdviceResult {
  final double soilPh;
  final String phAssessment;
  final List<String> organicAmendments;
  final List<String> recommendedCrops;
  final List<String> nutrientManagement;
  final String expertNote;

  const SoilAdviceResult({
    required this.soilPh,
    required this.phAssessment,
    required this.organicAmendments,
    required this.recommendedCrops,
    this.nutrientManagement = const [],
    required this.expertNote,
  });

  factory SoilAdviceResult.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      }
      return [];
    }

    return SoilAdviceResult(
      soilPh: (json['soil_ph'] as num?)?.toDouble() ?? 6.5,
      phAssessment: json['ph_assessment']?.toString() ?? 'Neutral optimal soil',
      organicAmendments: parseList(json['organic_amendments'] ?? json['organicAmendments']),
      recommendedCrops: parseList(json['recommended_crops'] ?? json['recommendedCrops']),
      nutrientManagement: parseList(json['nutrient_management'] ?? json['nutrientManagement']),
      expertNote: json['expert_note']?.toString() ??
          'Get your soil sample tested at your nearest Taluk laboratory for micronutrient analysis.',
    );
  }
}

@immutable
class IrrigationPlanResult {
  final String wateringFrequency;
  final String bestTimeOfDay;
  final String dripDurationHours;
  final String? weatherAdjustments;
  final List<String> waterSavingTips;
  final String expertNote;

  const IrrigationPlanResult({
    required this.wateringFrequency,
    required this.bestTimeOfDay,
    required this.dripDurationHours,
    this.weatherAdjustments,
    required this.waterSavingTips,
    required this.expertNote,
  });

  factory IrrigationPlanResult.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      }
      return [];
    }

    return IrrigationPlanResult(
      wateringFrequency: json['watering_frequency']?.toString() ??
          json['schedule']?.toString() ??
          'Every 2 to 3 days in morning hours',
      bestTimeOfDay: json['best_time_of_day']?.toString() ?? '06:00 AM - 08:30 AM',
      dripDurationHours: json['drip_duration_hours']?.toString() ??
          json['drip_run_time']?.toString() ??
          '2 hours per cycle',
      weatherAdjustments: json['weather_adjustments']?.toString(),
      waterSavingTips: parseList(json['water_saving_tips'] ?? json['water_conservation']),
      expertNote: json['expert_note']?.toString() ??
          'Check root zone moisture depth before turning on irrigation.',
    );
  }
}

@immutable
class GovernmentScheme {
  final String id;
  final String slug;
  final String nameEn;
  final String nameKn;
  final String nameHi;
  final String nameTe;
  final String nameTa;
  final String shortDescriptionEn;
  final String shortDescriptionKn;
  final String shortDescriptionHi;
  final String shortDescriptionTe;
  final String shortDescriptionTa;
  final String officialUrl;
  final String category;
  final String benefitsSummary;
  final List<String> documentsRequired;

  const GovernmentScheme({
    required this.id,
    required this.slug,
    required this.nameEn,
    required this.nameKn,
    required this.nameHi,
    required this.nameTe,
    required this.nameTa,
    required this.shortDescriptionEn,
    required this.shortDescriptionKn,
    required this.shortDescriptionHi,
    required this.shortDescriptionTe,
    required this.shortDescriptionTa,
    required this.officialUrl,
    required this.category,
    required this.benefitsSummary,
    this.documentsRequired = const [],
  });

  String localizedName(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'kn':
        return nameKn.isNotEmpty ? nameKn : nameEn;
      case 'hi':
        return nameHi.isNotEmpty ? nameHi : nameEn;
      case 'te':
        return nameTe.isNotEmpty ? nameTe : nameEn;
      case 'ta':
        return nameTa.isNotEmpty ? nameTa : nameEn;
      default:
        return nameEn;
    }
  }

  String localizedDescription(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'kn':
        return shortDescriptionKn.isNotEmpty ? shortDescriptionKn : shortDescriptionEn;
      case 'hi':
        return shortDescriptionHi.isNotEmpty ? shortDescriptionHi : shortDescriptionEn;
      case 'te':
        return shortDescriptionTe.isNotEmpty ? shortDescriptionTe : shortDescriptionEn;
      case 'ta':
        return shortDescriptionTa.isNotEmpty ? shortDescriptionTa : shortDescriptionEn;
      default:
        return shortDescriptionEn;
    }
  }

  factory GovernmentScheme.fromJson(Map<String, dynamic> json) {
    List<String> docs = [];
    if (json['documents_required'] is List) {
      docs = (json['documents_required'] as List).map((e) => e?.toString() ?? '').toList();
    }

    return GovernmentScheme(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      nameKn: json['name_kn']?.toString() ?? '',
      nameHi: json['name_hi']?.toString() ?? '',
      nameTe: json['name_te']?.toString() ?? '',
      nameTa: json['name_ta']?.toString() ?? '',
      shortDescriptionEn: json['short_description_en']?.toString() ?? '',
      shortDescriptionKn: json['short_description_kn']?.toString() ?? '',
      shortDescriptionHi: json['short_description_hi']?.toString() ?? '',
      shortDescriptionTe: json['short_description_te']?.toString() ?? '',
      shortDescriptionTa: json['short_description_ta']?.toString() ?? '',
      officialUrl: json['official_url']?.toString() ?? 'https://agricoop.gov.in',
      category: json['category']?.toString() ?? 'general',
      benefitsSummary: json['benefits_summary']?.toString() ?? '',
      documentsRequired: docs,
    );
  }
}
