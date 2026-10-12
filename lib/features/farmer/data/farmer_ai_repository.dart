import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/supabase/edge_api.dart';
import 'package:udyogasethu/features/farmer/domain/ai_assist_models.dart';

final farmerAiRepositoryProvider = Provider<FarmerAiRepository>((ref) {
  SupabaseClient? client;
  EdgeApiClient? edgeApi;
  try {
    if (Supabase.instance.isInitialized) {
      client = Supabase.instance.client;
      edgeApi = ref.watch(edgeApiClientProvider);
    }
  } catch (_) {}
  return FarmerAiRepository(client: client, edgeApi: edgeApi);
});

class FarmerAiRepository {
  final SupabaseClient? client;
  final EdgeApiClient? edgeApi;

  FarmerAiRepository({this.client, this.edgeApi});

  static const List<GovernmentScheme> _fallbackSchemes = [
    GovernmentScheme(
      id: 'scheme-001',
      slug: 'pm_kisan',
      nameEn: 'PM-KISAN (Pradhan Mantri Kisan Samman Nidhi)',
      nameKn: 'ಪಿಎಂ-ಕಿಸಾನ್ (ಪ್ರಧಾನ ಮಂತ್ರಿ ಕಿಸಾನ್ ಸಮ್ಮಾನ್ ನಿಧಿ)',
      nameHi: 'पीएम-किसान (प्रधानमंत्री किसान सम्मान निधि)',
      nameTe: 'పీఎం-కిసాన్ (ప్రధాన మంత్రి కిసాన్ సమ్మాన్ నిధి)',
      nameTa: 'பிஎம்-கிசான் (பிரதான் மந்திரி கிசான் சம்மான் நிதி)',
      shortDescriptionEn: 'Income support of Rs 6,000 per year in three installments for landholding farmer families.',
      shortDescriptionKn: 'ಭೂಮಿ ಹೊಂದಿರುವ ರೈತ ಕುಟುಂಬಗಳಿಗೆ ವರ್ಷಕ್ಕೆ ರೂ 6,000 ಆದಾಯ ಬೆಂಬಲ.',
      shortDescriptionHi: 'भूमिधारक किसान परिवारों को प्रति वर्ष 6,000 रुपये की आय सहायता।',
      shortDescriptionTe: 'భూమి ఉన్న రైతు కుటుంబాలకు సంవత్సరానికి రూ. 6,000 ఆదాయ మద్దతు.',
      shortDescriptionTa: 'நிலம் வைத்திருக்கும் விவசாய குடும்பங்களுக்கு ஆண்டுக்கு ரூ 6,000 வருமான ஆதரவு.',
      officialUrl: 'https://pmkisan.gov.in',
      category: 'income_support',
      benefitsSummary: 'Direct Benefit Transfer (DBT) into Aadhaar-seeded bank account.',
      documentsRequired: ['Aadhaar Card', 'Land ownership RTC / Pahani', 'Bank Passbook'],
    ),
    GovernmentScheme(
      id: 'scheme-002',
      slug: 'kisan_credit_card',
      nameEn: 'Kisan Credit Card (KCC) Scheme',
      nameKn: 'ಕಿಸಾನ್ ಕ್ರೆಡಿಟ್ ಕಾರ್ಡ್ (KCC) ಯೋಜನೆ',
      nameHi: 'किसान क्रेडिट कार्ड (KCC) योजना',
      nameTe: 'కిసాన్ క్రెడిట్ కార్డ్ (KCC) పథకం',
      nameTa: 'விவசாயிகள் கடன் அட்டை (KCC) திட்டம்',
      shortDescriptionEn: 'Concessional institutional credit for crop cultivation and post-harvest requirements.',
      shortDescriptionKn: 'ಬೆಳೆ ಕೃಷಿ ಮತ್ತು ಕೊಯ್ಲೋತ್ತರ ಅಗತ್ಯಗಳಿಗಾಗಿ ರಿಯಾಯಿತಿ ದರದ ಸಾಂಸ್ಥಿಕ ಸಾಲ.',
      shortDescriptionHi: 'फसल की खेती और कटाई के बाद की आवश्यकताओं के लिए रियायती ऋण।',
      shortDescriptionTe: 'పంట సాగు మరియు కోత అనంతర అవసరాలకు రాయితీ రుణ సదుపాయం.',
      shortDescriptionTa: 'பயிர் சாகுபடி மற்றும் அறுவடைக்கு பிந்தைய தேவைகளுக்கான சலுகை கடன்.',
      officialUrl: 'https://agricoop.gov.in',
      category: 'credit',
      benefitsSummary: 'Flexible revolving credit limit at subsidized interest rate (4% with prompt repayment).',
      documentsRequired: ['Identity Proof', 'Land Revenue Record', 'Application Form at local bank'],
    ),
    GovernmentScheme(
      id: 'scheme-003',
      slug: 'pm_fasal_bima',
      nameEn: 'Pradhan Mantri Fasal Bima Yojana (PMFBY)',
      nameKn: 'ಪ್ರಧಾನ ಮಂತ್ರಿ ಫಸಲ್ ಬಿಮಾ ಯೋಜನೆ (PMFBY)',
      nameHi: 'प्रधानमंत्री फसल बीमा योजना (PMFBY)',
      nameTe: 'ప్రధాన మంత్రి ఫసల్ బీమా యోజన (PMFBY)',
      nameTa: 'பிரதான் மந்திரி பயிர் காப்பீட்டுத் திட்டம் (PMFBY)',
      shortDescriptionEn: 'Comprehensive risk insurance covering yield losses due to non-preventable natural risks.',
      shortDescriptionKn: 'ತಡೆಯಲಾಗದ ನೈಸರ್ಗಿಕ ವಿಕೋಪಗಳಿಂದ ಉಂಟಾಗುವ ಇಳುವರಿ ನಷ್ಟವನ್ನು ಸರಿದೂಗಿಸುವ ಬೆಳೆ ವಿಮೆ.',
      shortDescriptionHi: 'गैर-निवारक प्राकृतिक जोखिमों से होने वाले नुकसान के लिए व्यापक फसल बीमा।',
      shortDescriptionTe: 'నివారించలేని సహజ నష్టాల నుండి రక్షణ కల్పించే సమగ్ర పంట బీమా.',
      shortDescriptionTa: 'இயற்கை சீற்றங்களால் ஏற்படும் விளைச்சல் இழப்புகளுக்கான பயிர் காப்பீடு.',
      officialUrl: 'https://pmfby.gov.in',
      category: 'insurance',
      benefitsSummary: 'Uniform premium of 2% for Kharif and 1.5% for Rabi crops.',
      documentsRequired: ['Crop Sowing Certificate', 'Land RTC', 'Aadhaar Card', 'Bank Account'],
    ),
    GovernmentScheme(
      id: 'scheme-004',
      slug: 'soil_health_card',
      nameEn: 'Soil Health Card Scheme',
      nameKn: 'ಮಣ್ಣು ಆರೋಗ್ಯ ಕಾರ್ಡ್ ಯೋಜನೆ',
      nameHi: 'मृदा स्वास्थ्य कार्ड योजना',
      nameTe: 'నేల ఆరోగ్య కార్డు పథకం',
      nameTa: 'மண் வள அட்டை திட்டம்',
      shortDescriptionEn: 'Soil nutrient status assessment and crop-wise fertilizer recommendations issued every 2 years.',
      shortDescriptionKn: 'ಪ್ರತಿ 2 ವರ್ಷಗಳಿಗೊಮ್ಮೆ ಮಣ್ಣಿನ ಪೋಷಕಾಂಶಗಳ ಪರೀಕ್ಷೆ ಮತ್ತು ರಸಗೊಬ್ಬರ ಶಿಫಾರಸು.',
      shortDescriptionHi: 'मृदा पोषक तत्वों की स्थिति का आकलन और फसलवार उर्वरक सिफारिशें।',
      shortDescriptionTe: 'నేల పోషకాల స్థితి అంచనా మరియు ఎరువుల సిఫార్సులు.',
      shortDescriptionTa: 'மண் ஊட்டச்சத்து மதிப்பீடு மற்றும் பயிர் வாரியான உரப் பரிந்துரைகள்.',
      officialUrl: 'https://soilhealth.dac.gov.in',
      category: 'soil',
      benefitsSummary: 'Laboratory test report identifying 12 parameters (N, P, K, pH, EC, etc.).',
      documentsRequired: ['Soil sample from field', 'Land ownership details'],
    ),
    GovernmentScheme(
      id: 'scheme-005',
      slug: 'krishi_bhagya',
      nameEn: 'Karnataka Krishi Bhagya Scheme',
      nameKn: 'ಕರ್ನಾಟಕ ಕೃಷಿ ಭಾಗ್ಯ ಯೋಜನೆ',
      nameHi: 'कर्नाटक कृषि भाग्य योजना',
      nameTe: 'కర్ణాటక కృషి భాగ్య పథకం',
      nameTa: 'கர்நாடகா கிருஷி பாக்யா திட்டம்',
      shortDescriptionEn: 'State government scheme providing farm ponds, polythene lining, and diesel pumpsets.',
      shortDescriptionKn: 'ಕೃಷಿ ಹೊಂಡ, ಪಾಲಿಥೀನ್ ಹೊದಿಕೆ ಮತ್ತು ಡೀಸೆಲ್ ಪಂಪ್‌ಸೆಟ್‌ಗಳಿಗೆ ರಾಜ್ಯ ಸರ್ಕಾರದ ಸಹಾಯಧನ.',
      shortDescriptionHi: 'खेत तालाब, पॉलीथीन लाइनिंग और डीजल पंप सेट प्रदान करने वाली राज्य सरकार की योजना।',
      shortDescriptionTe: 'రైతు చెరువులు, పాలీథిన్ లైనింగ్ మరియు పంపుసెట్లను అందించే రాష్ట్ర ప్రభుత్వ పథకం.',
      shortDescriptionTa: 'பண்ணைக் குட்டைகள், பாலிதீன் அமைப்புகள் வழங்கும் மாநில அரசு திட்டம்.',
      officialUrl: 'https://raitamitra.karnataka.gov.in',
      category: 'irrigation',
      benefitsSummary: '80% to 90% subsidy for dryland farmers constructing on-farm rain harvesting ponds.',
      documentsRequired: ['Land Pahani (RTC)', 'Caste Certificate (if SC/ST)', 'Bank Passbook'],
    ),
  ];

  Future<List<GovernmentScheme>> getCuratedSchemes() async {
    if (client != null) {
      try {
        final res = await client!.from('government_schemes').select('*').order('created_at');
        if (res.isNotEmpty) {
          return res.map((r) => GovernmentScheme.fromJson(r)).toList();
        }
      } catch (e) {
        debugPrint('Error fetching schemes from Supabase: $e');
      }
    }
    return _fallbackSchemes;
  }

  Future<AiAssistResponse<PestDiagnosisResult>> diagnosePest({
    required String crop,
    required String symptoms,
    String? imageBase64,
    String? imageMime,
    String? district,
    String? language,
  }) async {
    try {
      if (client != null) {
        final response = await client!.functions.invoke('ai-assist', body: {
          'task': 'pest_diagnosis',
          'crop': crop,
          'symptoms': symptoms,
          'image_base64': imageBase64,
          'image_mime': imageMime,
          'district': district ?? 'Karnataka',
          'language': language ?? 'en',
        });
        final res = response.data;

        if (res is Map && res['ok'] == true && res['result'] is Map) {
          return AiAssistResponse<PestDiagnosisResult>(
            ok: true,
            mode: res['mode']?.toString() ?? 'gemini',
            model: res['model']?.toString(),
            disclaimer: res['disclaimer']?.toString() ?? 'AI suggestion (Gemini), not professional advice',
            result: PestDiagnosisResult.fromJson(Map<String, dynamic>.from(res['result'] as Map)),
          );
        }
      }
    } catch (e) {
      debugPrint('Edge function ai-assist error: $e');
    }

    // Basic mode fallback (offline rules)
    final fallbackKn = language == 'kn';
    return AiAssistResponse<PestDiagnosisResult>(
      ok: true,
      mode: 'basic',
      disclaimer: 'Basic mode (offline rules)',
      result: PestDiagnosisResult(
        likelyCause: fallbackKn
            ? 'ಎಲೆ ಚುಕ್ಕೆ ಅಥವಾ ಕೀಟಗಳ ಬಾಧೆಯ ಆರಂಭಿಕ ಲಕ್ಷಣಗಳು ($crop)'
            : 'Early fungal leaf spot or sucking pest damage on $crop',
        confidenceLevel: 'Basic rule assessment',
        symptomsAnalysis: symptoms,
        organicRemedies: fallbackKn
            ? const [
                'ಬೇವಿನ ಎಣ್ಣೆ ಸಿಂಪಡಣೆ (ಪ್ರತಿ ಲೀಟರ್ ನೀರಿಗೆ 5 ಮಿ.ಲೀ ಜೊತೆ ಸೋಪು ದ್ರಾವಣ)',
                'ಗಿಡದ ಬುಡಕ್ಕೆ ಬೂದಿ ಹಾಕುವುದು',
                'ರೋಗಪೀಡಿತ ಕೆಳಭಾಗದ ಎಲೆಗಳನ್ನು ಕಿತ್ತು ನಾಶಮಾಡಿ',
              ]
            : const [
                'Neem oil spray (5ml per liter with mild soap emulsifier)',
                'Wood ash dusting around the root zone',
                'Prune and safely dispose of infected lower leaves',
              ],
        chemicalAdvice: fallbackKn
            ? 'ಮ್ಯಾಂಕೋಜೆಬ್ ಅಥವಾ ತಾಮ್ರದ ಆಕ್ಸಿಕ್ಲೋರೈಡ್ (ರೈತ ಸಂಪರ್ಕ ಕೇಂದ್ರದ ತಜ್ಞರ ಸಲಹೆಯಂತೆ ಮಾತ್ರ ಬಳಸಿ)'
            : 'Copper Oxychloride or Mancozeb spray (Consult agronomist before spraying)',
        expertWarning: fallbackKn
            ? 'ಯಾವುದೇ ರಾಸಾಯನಿಕ ಸಿಂಪಡಿಸುವ ಮುನ್ನ ಸಮೀಪದ ಕೃಷಿ ವಿಜ್ಞಾನ ಕೇಂದ್ರ (KVK) ಅಥವಾ ರೈತ ಸಂಪರ್ಕ ಕೇಂದ್ರವನ್ನು ಸಂಪರ್ಕಿಸಿ.'
            : 'AI suggestion only. Please confirm with your local Raitha Samparka Kendra officer before chemical application.',
      ),
    );
  }

  Future<AiAssistResponse<SoilAdviceResult>> getSoilAdvice({
    required double soilPh,
    String? soilType,
    String? crop,
    String? district,
    String? language,
  }) async {
    try {
      if (client != null) {
        final response = await client!.functions.invoke('ai-assist', body: {
          'task': 'soil_advice',
          'soil_ph': soilPh,
          'soil_type': soilType,
          'crop': crop,
          'district': district ?? 'Karnataka',
          'language': language ?? 'en',
        });
        final res = response.data;

        if (res is Map && res['ok'] == true && res['result'] is Map) {
          return AiAssistResponse<SoilAdviceResult>(
            ok: true,
            mode: res['mode']?.toString() ?? 'gemini',
            model: res['model']?.toString(),
            disclaimer: res['disclaimer']?.toString() ?? 'AI suggestion (Gemini), not professional advice',
            result: SoilAdviceResult.fromJson(Map<String, dynamic>.from(res['result'] as Map)),
          );
        }
      }
    } catch (e) {
      debugPrint('Edge function ai-assist error: $e');
    }

    // Basic rule fallback
    String phAssessment = 'Optimal neutral pH ($soilPh)';
    List<String> amendments = const [
      'Well-rotted Farm Yard Manure (FYM) 5-8 tonnes/acre',
      'Jeevamrutha / vermicompost during intercultural operations',
    ];
    List<String> recommended = const ['Tomato', 'Onion', 'Chilli', 'Paddy', 'Maize'];

    if (soilPh < 6.0) {
      phAssessment = 'Acidic soil (pH $soilPh). Micronutrient uptake may be impaired.';
      amendments = const [
        'Apply agricultural lime or dolomite (200-300 kg/acre)',
        'Incorporate green manure (Dhaincha/Sunhemp)',
      ];
      recommended = const ['Potato', 'Ginger', 'Tea', 'Arecanut'];
    } else if (soilPh > 7.5) {
      phAssessment = 'Alkaline/calcareous soil (pH $soilPh). Zinc and iron availability reduced.';
      amendments = const [
        'Apply agricultural gypsum (200-400 kg/acre)',
        'Heavy application of organic compost and sulfur',
      ];
      recommended = const ['Cotton', 'Paddy', 'Barley', 'Pomegranate'];
    }

    return AiAssistResponse<SoilAdviceResult>(
      ok: true,
      mode: 'basic',
      disclaimer: 'Basic mode (offline rules)',
      result: SoilAdviceResult(
        soilPh: soilPh,
        phAssessment: phAssessment,
        organicAmendments: amendments,
        recommendedCrops: recommended,
        expertNote: 'Based on standard agricultural rules. Obtain a Soil Health Card for laboratory testing.',
      ),
    );
  }

  Future<AiAssistResponse<IrrigationPlanResult>> getIrrigationPlan({
    required String crop,
    String? cropStage,
    String? irrigationSource,
    String? weatherSummary,
    String? district,
    String? language,
  }) async {
    try {
      if (client != null) {
        final response = await client!.functions.invoke('ai-assist', body: {
          'task': 'irrigation_plan',
          'crop': crop,
          'crop_stage': cropStage,
          'irrigation_source': irrigationSource,
          'weather_summary': weatherSummary,
          'district': district ?? 'Karnataka',
          'language': language ?? 'en',
        });
        final res = response.data;

        if (res is Map && res['ok'] == true && res['result'] is Map) {
          return AiAssistResponse<IrrigationPlanResult>(
            ok: true,
            mode: res['mode']?.toString() ?? 'gemini',
            model: res['model']?.toString(),
            disclaimer: res['disclaimer']?.toString() ?? 'AI suggestion (Gemini), not professional advice',
            result: IrrigationPlanResult.fromJson(Map<String, dynamic>.from(res['result'] as Map)),
          );
        }
      }
    } catch (e) {
      debugPrint('Edge function ai-assist error: $e');
    }

    return const AiAssistResponse<IrrigationPlanResult>(
      ok: true,
      mode: 'basic',
      disclaimer: 'Basic mode (offline rules)',
      result: IrrigationPlanResult(
        wateringFrequency: 'Every 2 to 3 days via drip; ensure 20-30 liters per plant bed',
        bestTimeOfDay: '06:00 AM - 08:30 AM (Cool morning hours to prevent evaporation)',
        dripDurationHours: '1.5 to 2.5 hours per cycle',
        weatherAdjustments: 'If rainfall exceeds 10mm in your taluk, pause irrigation for 48 hours.',
        waterSavingTips: [
          'Apply organic dry crop residue mulching around plant bases',
          'Inspect drip laterals and drippers for salt blockage weekly',
          'Check soil moisture at 10cm depth before starting pumps',
        ],
        expertNote: 'Adjust pump runtime based on soil moisture depth and seasonal humidity.',
      ),
    );
  }
}
