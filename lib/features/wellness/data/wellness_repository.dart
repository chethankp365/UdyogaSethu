import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/features/farmer/domain/ai_assist_models.dart';
import 'package:udyogasethu/features/wellness/domain/wellness_models.dart';

abstract class WellnessRepository {
  Future<List<GovernmentScheme>> fetchSchemes({String? category});
  List<EmergencyHelplineItem> getHelplines();
  List<SafetyGuidelineItem> getSafetyGuidelines();
}

class SupabaseWellnessRepository implements WellnessRepository {
  final SupabaseClient _client;

  SupabaseWellnessRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  @override
  Future<List<GovernmentScheme>> fetchSchemes({String? category}) async {
    try {
      var query = _client.from('government_schemes').select();
      if (category != null && category.isNotEmpty && category != 'all') {
        query = query.eq('category', category);
      }
      final data = await query;
      if (data.isNotEmpty) {
        return data.map((e) => _mapScheme(Map<String, dynamic>.from(e))).toList();
      }
    } catch (e) {
      AppLogger.w('Failed to query government_schemes from Supabase: $e');
    }

    return _getFallbackSchemes(category);
  }

  GovernmentScheme _mapScheme(Map<String, dynamic> json) {
    List<String> docs = [];
    final rawDocs = json['documents_required'];
    if (rawDocs is List) {
      docs = rawDocs.map((e) => e.toString()).toList();
    }

    return GovernmentScheme(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? 'Welfare Scheme',
      nameKn: json['name_kn']?.toString() ?? '',
      nameHi: json['name_hi']?.toString() ?? '',
      nameTe: json['name_te']?.toString() ?? '',
      nameTa: json['name_ta']?.toString() ?? '',
      shortDescriptionEn: json['short_description_en']?.toString() ?? '',
      shortDescriptionKn: json['short_description_kn']?.toString() ?? '',
      shortDescriptionHi: json['short_description_hi']?.toString() ?? '',
      shortDescriptionTe: json['short_description_te']?.toString() ?? '',
      shortDescriptionTa: json['short_description_ta']?.toString() ?? '',
      officialUrl: json['official_url']?.toString() ?? 'https://india.gov.in',
      category: json['category']?.toString() ?? 'welfare',
      benefitsSummary: json['benefits_summary']?.toString() ?? '',
      documentsRequired: docs,
    );
  }

  List<GovernmentScheme> _getFallbackSchemes(String? category) {
    final all = [
      const GovernmentScheme(
        id: '1',
        slug: 'pm_suraksha_bima',
        nameEn: 'Pradhan Mantri Suraksha Bima Yojana (PMSBY)',
        nameKn: 'ಪ್ರಧಾನ ಮಂತ್ರಿ ಸುರಕ್ಷಾ ಬಿಮಾ ಯೋಜನೆ',
        nameHi: 'प्रधानमंत्री सुरक्षा बीमा योजना',
        nameTe: 'ప్రధాన మంత్రి సురక్షా బీమా యోజన',
        nameTa: 'பிரதான் மந்திரி சுரக்ஷா பீமா யோஜனா',
        shortDescriptionEn: 'Accidental death and disability coverage of ₹2 Lakh for gig and informal workers at ₹20/year.',
        shortDescriptionKn: 'ಕೇವಲ 20 ರೂ. ವಾರ್ಷಿಕ ಕಂತಿನಲ್ಲಿ 2 ಲಕ್ಷ ರೂ. ಅಪಘಾತ ಮತ್ತು ಅಂಗವೈಕಲ್ಯ ವಿಮೆ.',
        shortDescriptionHi: 'असंगठित श्रमिकों के लिए प्रति वर्ष 20 रुपये में 2 लाख रुपये का दुर्घटना बीमा।',
        shortDescriptionTe: 'సంవత్సరానికి రూ. 20 చెల్లించి రూ. 2 లక్షల ప్రమాద బీమా రక్షణ.',
        shortDescriptionTa: 'ஆண்டுக்கு ரூ. 20 கட்டணத்தில் ரூ. 2 லட்சம் விபத்து காப்பீடு.',
        officialUrl: 'https://financialservices.gov.in',
        category: 'insurance',
        benefitsSummary: '₹2 Lakh for accidental death or permanent total disability.',
        documentsRequired: ['Aadhaar Card', 'Bank Account', 'Nominee Details'],
      ),
      const GovernmentScheme(
        id: '2',
        slug: 'pm_jeevan_jyoti',
        nameEn: 'Pradhan Mantri Jeevan Jyoti Bima Yojana (PMJJBY)',
        nameKn: 'ಪ್ರಧಾನ ಮಂತ್ರಿ ಜೀವನ್ ಜ್ಯೋತಿ ಬಿಮಾ ಯೋಜನೆ',
        nameHi: 'प्रधानमंत्री जीवन ज्योति बीमा योजना',
        nameTe: 'ప్రధాన మంత్రి జీవన్ జ్యోతి బీమా యోజన',
        nameTa: 'பிரதான் மந்திரி ஜீவன் ஜோதி பீமா யோஜனா',
        shortDescriptionEn: 'Renewable term life insurance cover of ₹2 Lakh for any cause of death at ₹436/year.',
        shortDescriptionKn: 'ಯಾವುದೇ ಕಾರಣದ ಸಾವಿಗೆ ವರ್ಷಕ್ಕೆ 436 ರೂ. ದರದಲ್ಲಿ 2 ಲಕ್ಷ ರೂ. ಜೀವ ವಿಮೆ.',
        shortDescriptionHi: 'प्रति वर्ष 436 रुपये पर किसी भी कारण से मृत्यु पर 2 लाख रुपये का जीवन बीमा।',
        shortDescriptionTe: 'సంవత్సరానికి రూ. 436 చెల్లించి రూ. 2 లక్షల జీవిత బీమా రక్షణ.',
        shortDescriptionTa: 'ஆண்டுக்கு ரூ. 436 கட்டணத்தில் ரூ. 2 லட்சம் ஆயுள் காப்பீட்டுத் திட்டம்.',
        officialUrl: 'https://financialservices.gov.in',
        category: 'insurance',
        benefitsSummary: '₹2 Lakh paid to nominee on death due to any reason.',
        documentsRequired: ['Aadhaar Card', 'Savings Bank Account'],
      ),
      const GovernmentScheme(
        id: '3',
        slug: 'eshram',
        nameEn: 'e-Shram National Database for Unorganised Workers',
        nameKn: 'ಇ-ಶ್ರಮ್ ರಾಷ್ಟ್ರೀಯ ಪೋರ್ಟಲ್',
        nameHi: 'ई-श्रम राष्ट्रीय पोर्टल',
        nameTe: 'ఈ-శ్రమ్ జాతీయ పోర్టల్',
        nameTa: 'இ-ஷ்ரம் தேசிய போர்ட்டல்',
        shortDescriptionEn: 'Universal Account Number (UAN) for informal workers linking social security & accidental cover.',
        shortDescriptionKn: 'ಅಸಂಘಟಿತ ಕಾರ್ಮಿಕರಿಗೆ ಯುಎಎನ್ ಕಾರ್ಡ್ ಮತ್ತು ಸಾಮಾಜಿಕ ಭದ್ರತಾ ಸೌಲಭ್ಯಗಳು.',
        shortDescriptionHi: 'असंगठित कामगारों के लिए यूएएन कार्ड और सामाजिक सुरक्षा योजनाएं।',
        shortDescriptionTe: 'అసంఘటిత కార్మికులకు యుఏఎన్ కార్డ్ మరియు సామాజిక భద్రతా పథకాలు.',
        shortDescriptionTa: 'அமைப்புசாரா தொழிலாளர்களுக்கு யுஏஎன் அட்டை மற்றும் அரசு நலத்திட்டங்கள்.',
        officialUrl: 'https://eshram.gov.in',
        category: 'welfare',
        benefitsSummary: 'Universal Account Number smart card and free accidental cover under PMSBY.',
        documentsRequired: ['Aadhaar linked with mobile number', 'Bank Passbook'],
      ),
      const GovernmentScheme(
        id: '4',
        slug: 'ayushman_bharat',
        nameEn: 'Ayushman Bharat PM-JAY Health Coverage',
        nameKn: 'ಆಯುಷ್ಮಾನ್ ಭಾರತ್ ಪ್ರಧಾನ ಮಂತ್ರಿ ಜನ ಆರೋಗ್ಯ ಯೋಜನೆ',
        nameHi: 'आयुष्मान भारत प्रधानमंत्री जन आरोग्य योजना',
        nameTe: 'ఆయుష్మాన్ భారత్ ప్రధాన మంత్రి జన్ ఆరోగ్య యోజన',
        nameTa: 'ஆயுஷ்மான் பாரத் பிஎம்-ஜேஏஒய்',
        shortDescriptionEn: 'Cashless inpatient hospitalization cover up to ₹5 Lakh/family/year across 27,000+ hospitals.',
        shortDescriptionKn: 'ಪ್ರತಿ ಕುಟುಂಬಕ್ಕೆ ವರ್ಷಕ್ಕೆ 5 ಲಕ್ಷ ರೂ. ವರೆಗೆ ಉಚಿತ ಆಸ್ಪತ್ರೆ ಚಿಕಿತ್ಸಾ ಕಾರ್ಡ್.',
        shortDescriptionHi: 'प्रति परिवार प्रति वर्ष 5 लाख रुपये तक का मुफ्त अस्पताल इलाज।',
        shortDescriptionTe: 'కుటుంబానికి సంవత్సరానికి రూ. 5 లక్షల వరకు ఉచిత ఆసుపత్రి చికిత్స.',
        shortDescriptionTa: 'குடும்பத்திற்கு ஆண்டுக்கு ரூ. 5 லட்சம் வரை இலவச மருத்துவமனை சிகிச்சை.',
        officialUrl: 'https://pmjay.gov.in',
        category: 'health',
        benefitsSummary: 'Up to ₹5 Lakh cashless hospitalization per family per year.',
        documentsRequired: ['Aadhaar Card / Ration Card', 'SECC status'],
      ),
      const GovernmentScheme(
        id: '5',
        slug: 'pm_kisan',
        nameEn: 'PM-KISAN Income Support for Farmers',
        nameKn: 'ಪಿಎಂ-ಕಿಸಾನ್ ರೈತರ ಸಮ್ಮಾನ್ ನಿಧಿ',
        nameHi: 'पीएम-किसान सम्मान निधि',
        nameTe: 'పీఎం-కిసాన్ సమ్మాన్ నిధి',
        nameTa: 'பிஎம்-கிசான் சம்மான் நிதி',
        shortDescriptionEn: 'Direct income support of ₹6,000 per year in 3 equal installments to landholding farmer families.',
        shortDescriptionKn: 'ರೈತ ಕುಟುಂಬಗಳಿಗೆ ವರ್ಷಕ್ಕೆ 6,000 ರೂ. ನೇರ ಬ್ಯಾಂಕ್ ಖಾತೆಗೆ ಜಮೆ.',
        shortDescriptionHi: 'पात्र किसान परिवारों को प्रति वर्ष 6,000 रुपये की प्रत्यक्ष आय सहायता।',
        shortDescriptionTe: 'రైతు కుటుంబాలకు సంవత్సరానికి రూ. 6,000 ప్రత్యక్ష ఆదాయ సహాయం.',
        shortDescriptionTa: 'விவசாய குடும்பங்களுக்கு ஆண்டுக்கு ரூ. 6,000 நேரடி வருமான ஆதரவு.',
        officialUrl: 'https://pmkisan.gov.in',
        category: 'income_support',
        benefitsSummary: '₹6,000 per year in three ₹2,000 direct bank transfers.',
        documentsRequired: ['Aadhaar Card', 'Land Records (RTC / Pahani)', 'Bank Account'],
      ),
    ];

    if (category == null || category.isEmpty || category == 'all') {
      return all;
    }
    return all.where((s) => s.category == category).toList();
  }

  @override
  List<EmergencyHelplineItem> getHelplines() {
    return const [
      EmergencyHelplineItem(
        name: 'National Emergency',
        number: '112',
        subtitle: 'Police, Fire, and Immediate Rescue',
        badge: '24x7 Free',
        icon: Icons.local_police_rounded,
      ),
      EmergencyHelplineItem(
        name: 'Medical Ambulance',
        number: '108',
        subtitle: 'Emergency Medical Dispatch & Trauma',
        badge: '24x7 Free',
        icon: Icons.medical_services_rounded,
      ),
      EmergencyHelplineItem(
        name: 'Women Helpline',
        number: '1091',
        subtitle: 'Harassment & Safety Protection',
        badge: 'Toll-Free',
        icon: Icons.support_agent_rounded,
      ),
      EmergencyHelplineItem(
        name: 'Shram Suvidha (Labour)',
        number: '14434',
        subtitle: 'Ministry of Labour & Employment Grievances',
        badge: 'Official',
        icon: Icons.handyman_rounded,
      ),
      EmergencyHelplineItem(
        name: 'Kisan Call Centre',
        number: '1551',
        subtitle: 'Agri Advisory, Crop Health & Mandi Guidance',
        badge: 'Toll-Free',
        icon: Icons.agriculture_rounded,
      ),
      EmergencyHelplineItem(
        name: 'Tele-MANAS Mental Health',
        number: '14416',
        subtitle: 'Confidential Counselor Support & Well-being',
        badge: 'Mental Wellness',
        icon: Icons.favorite_rounded,
      ),
    ];
  }

  @override
  List<SafetyGuidelineItem> getSafetyGuidelines() {
    return const [
      SafetyGuidelineItem(
        title: 'Worksite Heat Stroke Prevention',
        category: 'Site Safety',
        summary: 'Essential hydration and rest protocols during peak summer daylight shifts.',
        tips: [
          'Drink 250ml water every 20-30 minutes, even if not thirsty.',
          'Take mandatory 10-minute shade breaks between 12:00 PM and 3:00 PM.',
          'Recognize heat exhaustion signs: dizziness, excessive sweating, rapid pulse.',
          'Report extreme temperatures to job provider for adjusted shift timings.',
        ],
        icon: Icons.wb_sunny_rounded,
      ),
      SafetyGuidelineItem(
        title: 'Personal Protective Equipment (PPE)',
        category: 'Accident Prevention',
        summary: 'Standard gear requirements before starting construction, plumbing, or electrical shifts.',
        tips: [
          'Wear ISI-marked safety helmet and steel-toe footwear on construction sites.',
          'Use insulated rubber gloves and certified testers for electrical maintenance.',
          'Never start work on scaffoldings without an anchored safety harness.',
          'Request required safety gear from site supervisor before executing hazardous tasks.',
        ],
        icon: Icons.shield_rounded,
      ),
      SafetyGuidelineItem(
        title: 'Safe Pesticide & Chemical Handling',
        category: 'Agricultural Safety',
        summary: 'Safety precautions for farm workers spraying fertilizers or pesticides.',
        tips: [
          'Always wear face mask, eye goggles, and protective overalls during spraying.',
          'Spray along the direction of the wind; never spray facing into headwind.',
          'Wash hands thoroughly with soap before eating, drinking, or touching face.',
          'Safely dispose of empty pesticide containers; never reuse for household water.',
        ],
        icon: Icons.eco_rounded,
      ),
      SafetyGuidelineItem(
        title: 'Heavy Lifting & Spine Ergonomics',
        category: 'Physical Wellness',
        summary: 'Correct posture techniques to avoid chronic lumbar and spinal injuries.',
        tips: [
          'Bend at your knees and hips, not at your waist, when picking up heavy loads.',
          'Keep the load close to your body chest rather than at arm length.',
          'Do not twist your back while carrying; pivot with your feet.',
          'Ask for peer assistance when loads exceed 25 kilograms.',
        ],
        icon: Icons.accessibility_new_rounded,
      ),
    ];
  }
}

final wellnessRepositoryProvider = Provider<WellnessRepository>((ref) {
  return SupabaseWellnessRepository();
});

final governmentSchemesProvider =
    FutureProvider.family<List<GovernmentScheme>, String?>((ref, category) async {
  final repo = ref.watch(wellnessRepositoryProvider);
  return repo.fetchSchemes(category: category);
});
