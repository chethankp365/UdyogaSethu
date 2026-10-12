-- ============================================================================
-- Migration: 0750_wellness_benefits_trust_readiness.sql
-- Description: Batch 3 (P8.5 & P8.6)
--   1. Seed worker welfare and insurance schemes into government_schemes
--   2. Worker repeat clients RPC
--   3. Honest credit readiness metrics RPC
-- ============================================================================

-- 1. Insert worker welfare & social security schemes into public.government_schemes
INSERT INTO public.government_schemes (
  slug, name_en, name_kn, name_hi, name_te, name_ta,
  short_description_en, short_description_kn, short_description_hi, short_description_te, short_description_ta,
  official_url, category, benefits_summary, documents_required
) VALUES
(
  'pm_suraksha_bima',
  'Pradhan Mantri Suraksha Bima Yojana (PMSBY)',
  'ಪ್ರಧಾನ ಮಂತ್ರಿ ಸುರಕ್ಷಾ ಬಿಮಾ ಯೋಜನೆ (ಪಿಎಂಎಸ್‌ಬಿವೈ)',
  'प्रधानमंत्री सुरक्षा बीमा योजना (पीएमएसबीवाई)',
  'ప్రధాన మంత్రి సురక్షా బీమా యోజన (పీఎంఎస్‌బీవై)',
  'பிரதான் மந்திரி சுரக்ஷா பீமா யோஜனா (பிஎம்எஸ்பிஒய்)',
  'Accidental death and disability insurance coverage of Rs 2 Lakh for informal and gig workers at an annual premium of just Rs 20.',
  'ಕೇವಲ 20 ರೂ. ವಾರ್ಷಿಕ ಕಂತಿನಲ್ಲಿ ಅಸಂಘಟಿತ ಕಾರ್ಮಿಕರಿಗೆ 2 ಲಕ್ಷ ರೂ. ಅಪಘಾತ ಮತ್ತು ಅಂಗವೈಕಲ್ಯ ವಿಮಾ ರಕ್ಷಣೆ.',
  'असंगठित और गिग श्रमिकों के लिए केवल 20 रुपये के वार्षिक प्रीमियम पर 2 लाख रुपये का दुर्घटना और विकलांगता बीमा।',
  'అసంఘటిత కార్మికులకు కేవలం రూ. 20 వార్షిక ప్రీమియంతో రూ. 2 లక్షల ప్రమాద మరియు వైకల్య బీమా రక్షణ.',
  'முறைசாரா தொழிலாளர்களுக்கு ஆண்டுக்கு வெறும் ரூ. 20 பிரீமியத்தில் ரூ. 2 லட்சம் விபத்து மற்றும் ஊனமுற்றோர் காப்பீடு.',
  'https://financialservices.gov.in',
  'insurance',
  'Rs 2 Lakh for accidental death or permanent total disability; Rs 1 Lakh for permanent partial disability. Auto-debited annually.',
  ARRAY['Aadhaar Card', 'Bank Account / Jan Dhan Account', 'Nominee details']
),
(
  'pm_jeevan_jyoti',
  'Pradhan Mantri Jeevan Jyoti Bima Yojana (PMJJBY)',
  'ಪ್ರಧಾನ ಮಂತ್ರಿ ಜೀವನ್ ಜ್ಯೋತಿ ಬಿಮಾ ಯೋಜನೆ (ಪಿಎಂಜಂಡಿಬಿವೈ)',
  'प्रधानमंत्री जीवन ज्योति बीमा योजना (पीएमजेजेबीवाई)',
  'ప్రధాన మంత్రి జీవన్ జ్యోతి బీమా యోజన (పీఎంజేజేబీవై)',
  'பிரதான் மந்திரி ஜீவன் ஜோதி பீமா யோஜனா (பிஎம்ஜேஜேபிஒய்)',
  'Renewable term life insurance cover of Rs 2 Lakh for any cause of death at Rs 436 per year for individuals aged 18 to 50.',
  '18 ರಿಂದ 50 ವರ್ಷ ವಯಸ್ಸಿನ ವ್ಯಕ್ತಿಗಳಿಗೆ ಯಾವುದೇ ಕಾರಣದ ಸಾವಿಗೆ ವರ್ಷಕ್ಕೆ 436 ರೂ. ದರದಲ್ಲಿ 2 ಲಕ್ಷ ರೂ. ಜೀವ ವಿಮೆ.',
  '18 से 50 वर्ष की आयु के व्यक्तियों के लिए प्रति वर्ष 436 रुपये पर किसी भी कारण से मृत्यु पर 2 लाख रुपये का जीवन बीमा।',
  '18 నుండి 50 సంవత్సరాల వయస్సు వారికి సంవత్సరానికి రూ. 436 చెల్లించి రూ. 2 లక్షల జీవిత బీమా రక్షణ.',
  '18 முதல் 50 வயதுடைய நபர்களுக்கு ஆண்டுக்கு ரூ. 436 கட்டணத்தில் ரூ. 2 லட்சம் ஆயுள் காப்பீட்டுத் திட்டம்.',
  'https://financialservices.gov.in',
  'insurance',
  'Rs 2 Lakh payable to nominee upon death of the insured due to any cause. Simple auto-debit facility.',
  ARRAY['Aadhaar Card', 'Bank Savings Account', 'Consent for auto-debit']
),
(
  'eshram',
  'e-Shram National Database of Unorganised Workers',
  'ಇ-ಶ್ರಮ್ ಅಸಂಘಟಿತ ಕಾರ್ಮಿಕರ ರಾಷ್ಟ್ರೀಯ ಪೋರ್ಟಲ್',
  'ई-श्रम असंगठित कामगार राष्ट्रीय पोर्टल',
  'ఈ-శ్రమ్ అసంఘటిత కార్మికుల జాతీయ పోర్టల్',
  'இ-ஷ்ரம் அமைப்புசாரா தொழிலாளர் தேசிய போர்ட்டல்',
  'Central registration for informal, domestic, construction and agricultural workers offering Universal Account Number (UAN) and social security benefits.',
  'ಅಸಂಘಟಿತ ಮತ್ತು ಕೃಷಿ ಕಾರ್ಮಿಕರಿಗೆ ಯುಎಎನ್ ಕಾರ್ಡ್ ಮತ್ತು ಸರ್ಕಾರದ ಸಾಮಾಜಿಕ ಭದ್ರತಾ ಸೌಲಭ್ಯಗಳ ನೋಂದಣಿ.',
  'असंगठित और कृषि कामगारों के लिए यूएएन कार्ड और सामाजिक सुरक्षा योजनाओं का केंद्रीय पंजीकरण।',
  'అసంఘటిత మరియు వ్యవసాయ కార్మికులకు యుఏఎన్ కార్డ్ మరియు సామాజిక భద్రతా పథకాల నమోదు.',
  'அமைப்புசாரா தொழிலாளர்களுக்கு யுஏஎன் அட்டை மற்றும் அரசு நலத்திட்டங்களுக்கான தேசிய பதிவு.',
  'https://eshram.gov.in',
  'welfare',
  'UAN smart card, accidental cover of Rs 2 Lakh under PMSBY, direct integration with central welfare schemes.',
  ARRAY['Aadhaar Card with linked mobile number', 'Bank Account Passbook', 'Age 16 to 59 years']
),
(
  'ayushman_bharat',
  'Ayushman Bharat PM-JAY Health Protection',
  'ಆಯುಷ್ಮಾನ್ ಭಾರತ್ ಪ್ರಧಾನ ಮಂತ್ರಿ ಜನ ಆರೋಗ್ಯ ಯೋಜನೆ (ಪಿಎಂ-ಜೆಎವೈ)',
  'आयुष्मान भारत प्रधानमंत्री जन आरोग्य योजना (पीएम-जय)',
  'ఆయుష్మాన్ భారత్ ప్రధాన మంత్రి జన్ ఆరోగ్య యోజన (పీఎం-జేఏవై)',
  'ஆயுஷ்மான் பாரத் பிரதான் மந்திரி ஜன் ஆரோக்கிய திட்டம் (பிஎம்-ஜேஏஒய்)',
  'Cashless and paperless inpatient secondary and tertiary hospitalization cover of up to Rs 5 Lakh per family per year at empaneled hospitals.',
  'ಪ್ರತಿ ಕುಟುಂಬಕ್ಕೆ ವರ್ಷಕ್ಕೆ 5 ಲಕ್ಷ ರೂ. ವರೆಗೆ ಉಚಿತ ಆಸ್ಪತ್ರೆ ಒಳರೋಗಿ ಚಿಕಿತ್ಸಾ ವೆಚ್ಚ ಭರಿಸುವ ಆರೋಗ್ಯ ಕಾರ್ಡ್.',
  'प्रति परिवार प्रति वर्ष 5 लाख रुपये तक का कैशलेस अस्पताल में भर्ती माध्यमिक और तृतीयक स्वास्थ्य कवर।',
  'ప్రతి కుటుంబానికి సంవత్సరానికి రూ. 5 లక్షల వరకు ఉచిత ఆసుపత్రి చికిత్స అందించే ఆరోగ్య పథకం.',
  'குடும்பத்திற்கு ஆண்டுக்கு ரூ. 5 லட்சம் வரை இலவச மருத்துவமனை சிகிச்சை அளிக்கும் சுகாதார அட்டை.',
  'https://pmjay.gov.in',
  'health',
  'Up to Rs 5 Lakh cashless hospitalization per family per year across 27,000+ empaneled public and private hospitals across India.',
  ARRAY['Aadhaar Card / Ration Card', 'SECC status verification', 'Mobile Number']
),
(
  'atal_pension',
  'Atal Pension Yojana (APY)',
  'ಅಟಲ್ ಪಿಂಚಣಿ ಯೋಜನೆ (ಎಪಿವೈ)',
  'अटल पेंशन योजना (एपीवाई)',
  'అటల్ పెన్షన్ యోజన (ఏపీవై)',
  'அடல் ஓய்வூதியத் திட்டம் (ஏபிஒய்)',
  'Guaranteed monthly pension between Rs 1,000 to Rs 5,000 after reaching age 60 for informal and gig workers.',
  'ಅಸಂಘಟಿತ ಕಾರ್ಮಿಕರಿಗೆ 60 ವರ್ಷ ತುಂಬಿದ ನಂತರ ಮಾಸಿಕ 1,000 ರಿಂದ 5,000 ರೂ. ವರೆಗೆ ಖಾತರಿಯ ಪಿಂಚಣಿ.',
  'असंगठित श्रमिकों के लिए 60 वर्ष की आयु के बाद 1,000 से 5,000 रुपये की मासिक गारंटीकृत पेंशन।',
  'అసంఘటిత కార్మికులకు 60 ఏళ్ల వయస్సు తర్వాత రూ. 1,000 నుండి రూ. 5,000 నెలవారీ గ్యారెంటీ పింఛను.',
  'முறைசாரா தொழிலாளர்களுக்கு 60 வயதிற்குப் பிறகு மாதம் ரூ. 1,000 முதல் ரூ. 5,000 வரை உறுதியான ஓய்வூதியம்.',
  'https://www.npscra.nsdl.co.in',
  'pension',
  'Guaranteed lifelong pension from age 60, spouse pension continuation, and corpus return to nominee.',
  ARRAY['Savings Bank Account', 'Aadhaar Card', 'Age between 18 and 40 years']
)
ON CONFLICT (slug) DO UPDATE SET
  name_en = EXCLUDED.name_en,
  name_kn = EXCLUDED.name_kn,
  name_hi = EXCLUDED.name_hi,
  name_te = EXCLUDED.name_te,
  name_ta = EXCLUDED.name_ta,
  short_description_en = EXCLUDED.short_description_en,
  short_description_kn = EXCLUDED.short_description_kn,
  short_description_hi = EXCLUDED.short_description_hi,
  short_description_te = EXCLUDED.short_description_te,
  short_description_ta = EXCLUDED.short_description_ta,
  official_url = EXCLUDED.official_url,
  category = EXCLUDED.category,
  benefits_summary = EXCLUDED.benefits_summary,
  documents_required = EXCLUDED.documents_required;

-- ============================================================================
-- 2. Worker Repeat Clients RPC
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_worker_repeat_clients(
  p_worker_id UUID DEFAULT NULL
)
RETURNS TABLE (
  client_id UUID,
  client_name TEXT,
  client_phone TEXT,
  avatar_path TEXT,
  completed_jobs_count BIGINT,
  last_job_date TIMESTAMPTZ,
  is_favourite BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_target_worker UUID;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
  END IF;

  v_target_worker := COALESCE(p_worker_id, v_caller);

  -- Only allow worker themselves to view their repeat clients
  IF v_caller != v_target_worker THEN
    RAISE EXCEPTION 'Access denied: cannot view another worker repeat clients' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  WITH client_stats AS (
    SELECT
      j.employer_id AS c_id,
      COUNT(ja.id) AS jobs_count,
      MAX(ja.completed_at) AS last_completed
    FROM public.job_assignments ja
    JOIN public.jobs j ON j.id = ja.job_id
    WHERE ja.worker_id = v_target_worker
      AND ja.status = 'completed'
    GROUP BY j.employer_id
    HAVING COUNT(ja.id) >= 1
  )
  SELECT
    cs.c_id AS client_id,
    COALESCE(p.full_name, 'Client') AS client_name,
    p.phone AS client_phone,
    p.avatar_path AS avatar_path,
    cs.jobs_count AS completed_jobs_count,
    cs.last_completed AS last_job_date,
    EXISTS (
      SELECT 1 FROM public.favourites f
      WHERE f.user_id = v_target_worker AND f.target_id = cs.c_id
    ) AS is_favourite
  FROM client_stats cs
  JOIN public.profiles p ON p.id = cs.c_id
  ORDER BY cs.jobs_count DESC, cs.last_completed DESC;
END;
$$;

-- ============================================================================
-- 3. Honest Credit Readiness Metrics RPC
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_credit_readiness_metrics(
  p_user_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_target UUID;
  v_profile RECORD;
  v_completed_count BIGINT := 0;
  v_total_earned_paise BIGINT := 0;
  v_tenure_days INT := 0;
  v_bank_linked BOOLEAN := false;
  v_dispute_count BIGINT := 0;
  v_regularity_score INT := 0;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
  END IF;

  v_target := COALESCE(p_user_id, v_caller);

  IF v_caller != v_target THEN
    RAISE EXCEPTION 'Access denied' USING ERRCODE = '42501';
  END IF;

  SELECT id, is_verified, rating_avg, rating_count, created_at
  INTO v_profile
  FROM public.profiles
  WHERE id = v_target;

  IF v_profile IS NULL THEN
    RAISE EXCEPTION 'Profile not found' USING ERRCODE = 'P0002';
  END IF;

  -- Compute tenure in days
  v_tenure_days := GREATEST(1, EXTRACT(DAY FROM (NOW() - v_profile.created_at))::INT);

  -- Count completed jobs
  SELECT COUNT(id), COALESCE(SUM(agreed_wage_paise), 0)
  INTO v_completed_count, v_total_earned_paise
  FROM public.job_assignments
  WHERE worker_id = v_target AND status = 'completed';

  -- Check if user has bank account or verified payout details
  SELECT EXISTS (
    SELECT 1 FROM public.bank_accounts
    WHERE user_id = v_target AND is_verified = true
  ) INTO v_bank_linked;

  -- Check active disputes
  SELECT COUNT(id)
  INTO v_dispute_count
  FROM public.disputes
  WHERE defendant_id = v_target;

  -- Regularity score: based on completed work history and dispute-free record
  IF v_completed_count >= 10 AND v_dispute_count = 0 THEN
    v_regularity_score := 85;
  ELSIF v_completed_count >= 5 THEN
    v_regularity_score := 70;
  ELSIF v_completed_count >= 2 THEN
    v_regularity_score := 55;
  ELSE
    v_regularity_score := 35;
  END IF;

  RETURN jsonb_build_object(
    'user_id', v_target,
    'identity_verified', COALESCE(v_profile.is_verified, false),
    'bank_linked', v_bank_linked,
    'rating_avg', COALESCE(v_profile.rating_avg, 0.0),
    'rating_count', COALESCE(v_profile.rating_count, 0),
    'completed_jobs_count', v_completed_count,
    'total_earned_paise', v_total_earned_paise,
    'tenure_days', v_tenure_days,
    'disputes_count', v_dispute_count,
    'regularity_score', v_regularity_score
  );
END;
$$;
