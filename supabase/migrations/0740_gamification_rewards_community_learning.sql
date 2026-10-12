-- Migration: 0740_gamification_rewards_community_learning.sql
-- Description: P8.3 XP, levels, streaks, badges and referrals + P8.4 Rewards store, community, events and learning hub

-- 1. Extend credentials table with verification status for external uploads
ALTER TABLE public.credentials
  ADD COLUMN IF NOT EXISTS is_verified BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS verified_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS title TEXT,
  ADD COLUMN IF NOT EXISTS issuing_organization TEXT;

-- For module-based credentials, default to verified
UPDATE public.credentials SET is_verified = true WHERE source_type = 'module';

-- 2. Seed / Update Admin Settings for gamification points
INSERT INTO public.admin_settings (key, value) VALUES
  ('xp_job_completed', '50'::jsonb),
  ('xp_on_time', '20'::jsonb),
  ('xp_good_rating', '30'::jsonb),
  ('xp_training_completed', '40'::jsonb),
  ('xp_referral_reward', '100'::jsonb),
  ('xp_no_dispute_streak', '25'::jsonb),
  ('xp_daily_active', '10'::jsonb)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- 3. Seed Levels with genuine perks (commission_bps, search_boost, priority_support, premium_jobs)
INSERT INTO public.levels (level_number, name, min_xp, perks) VALUES
  (1, 'Starter', 0, '{"commission_bps": 500, "search_boost": 1.0, "priority_support": false, "premium_jobs": false, "badge_title": "Starter"}'::jsonb),
  (2, 'Reliable', 200, '{"commission_bps": 400, "search_boost": 1.15, "priority_support": false, "premium_jobs": true, "badge_title": "Reliable Worker"}'::jsonb),
  (3, 'Trusted Pro', 600, '{"commission_bps": 300, "search_boost": 1.30, "priority_support": true, "premium_jobs": true, "badge_title": "Trusted Pro"}'::jsonb),
  (4, 'Community Hero', 1500, '{"commission_bps": 200, "search_boost": 1.50, "priority_support": true, "premium_jobs": true, "badge_title": "Community Hero"}'::jsonb)
ON CONFLICT (level_number) DO UPDATE SET
  name = EXCLUDED.name,
  min_xp = EXCLUDED.min_xp,
  perks = EXCLUDED.perks;

-- 4. Seed Badges with criteria and localized names
INSERT INTO public.badges (slug, names, criteria) VALUES
  ('always_on_time', '{"en": "Always On-Time", "kn": "ಸದಾ ಸಮಯಪಾಲಕ", "hi": "हमेशा समय पर", "te": "ఎల్లప్పుడూ సమయానికి", "ta": "எப்போதும் சரியான நேரத்தில்"}'::jsonb,
   '{"description": "5+ consecutive on-time job arrivals", "type": "streak", "target": 5}'::jsonb),
  ('clean_record', '{"en": "Clean Record", "kn": "ಸ್ವಚ್ಛ ದಾಖಲೆ", "hi": "स्वच्छ रिकॉर्ड", "te": "క్లీన్ రికార్డ్", "ta": "சுத்தமான பதிவு"}'::jsonb,
   '{"description": "10+ completed jobs with zero disputes", "type": "dispute_free", "target": 10}'::jsonb),
  ('safety_champion', '{"en": "Safety Champion", "kn": "ಸುರಕ್ಷತಾ ಚಾಂಪಿಯನ್", "hi": "सुरक्षा चैंपियन", "te": "భద్రతా ఛాంపియన్", "ta": "பாதுகாப்பு சாம்பியன்"}'::jsonb,
   '{"description": "Completed safety onboarding and 5+ presence verified starts", "type": "safety", "target": 5}'::jsonb),
  ('top_rated', '{"en": "Top Rated", "kn": "ಅತ್ಯುನ್ನತ ರೇಟಿಂಗ್", "hi": "शीर्ष रेटेड", "te": "టాప్ రేటెడ్", "ta": "சிறந்த மதிப்பீடு"}'::jsonb,
   '{"description": "10+ customer reviews with average 4.8+ rating", "type": "rating", "min_rating": 4.8, "min_reviews": 10}'::jsonb),
  ('community_mentor', '{"en": "Community Mentor", "kn": "ಸಮುದಾಯ ಮಾರ್ಗದರ್ಶಿ", "hi": "समुदाय मेंटर", "te": "కమ్యూనిటీ మెంటర్", "ta": "சமூக வழிகாட்டி"}'::jsonb,
   '{"description": "Successfully referred 3+ active workers or farmers", "type": "referral", "target": 3}'::jsonb),
  ('digital_ready_worker', '{"en": "Digital Ready Worker", "kn": "ಡಿಜಿಟಲ್ ಸಿದ್ಧ ಕೆಲಸಗಾರ", "hi": "डिजिटल तैयार कार्यकर्ता", "te": "డిజిటల్ సిద్ధ కార్మికుడు", "ta": "டிஜிட்டல் தயார் பணியாளர்"}'::jsonb,
   '{"description": "Completed digital payments course and verified bank account", "type": "learning", "module": "module_payments"}'::jsonb),
  ('food_hygiene_certified', '{"en": "Food Hygiene Certified", "kn": "ಆಹಾರ ನೈರ್ಮಲ್ಯ ಪ್ರಮಾಣೀಕೃತ", "hi": "खाद्य स्वच्छता प्रमाणित", "te": "ఆహార పరిశుభ్రత సర్టిఫైడ్", "ta": "உணவு சுகாதாரம் சான்றளிக்கப்பட்டது"}'::jsonb,
   '{"description": "Passed food hygiene and crop handling training", "type": "learning", "module": "module_hygiene"}'::jsonb),
  ('verified_farmer', '{"en": "Verified Farmer", "kn": "ಪರಿಶೀಲಿಸಿದ ರೈತ", "hi": "सत्यापित किसान", "te": "ధృవీకరించబడిన రైతు", "ta": "சரிபார்க்கப்பட்ட விவசாயி"}'::jsonb,
   '{"description": "Verified farm profile with 5+ successful produce deliveries", "type": "farmer_orders", "target": 5}'::jsonb)
ON CONFLICT (slug) DO UPDATE SET
  names = EXCLUDED.names,
  criteria = EXCLUDED.criteria;

-- 5. Seed Reward Store Items
INSERT INTO public.reward_items (id, names, points_cost, min_level, required_badge_id, stock, image, active) VALUES
  ('11111111-1111-1111-1111-111111110001',
   '{"en": "UdyogaSethu Official T-Shirt", "kn": "ಉದ್ಯೋಗಸೇತು ಅಧಿಕೃತ ಟೀ-ಶರ್ಟ್", "hi": "उद्योगसेतु आधिकारिक टी-शर्ट", "te": "ఉద్యోగసేతు అధికారిక టీ-షర్ట్", "ta": "உத்யோகசேது அதிகாரப்பூர்வ டி-ஷர்ட்"}'::jsonb,
   300, 2, NULL, 45, 'assets/rewards/tshirt.png', true),
  ('11111111-1111-1111-1111-111111110002',
   '{"en": "UdyogaSethu Cotton Cap", "kn": "ಉದ್ಯೋಗಸೇತು ಹತ್ತಿ ಕ್ಯಾಪ್", "hi": "उद्योगसेतु सूती टोपी", "te": "ఉద్యోగసేతు కాటన్ క్యాప్", "ta": "உத்யோகசேது காட்டன் தொப்பி"}'::jsonb,
   150, 1, NULL, 80, 'assets/rewards/cap.png', true),
  ('11111111-1111-1111-1111-111111110003',
   '{"en": "Stainless Steel Water Bottle (750ml)", "kn": "ಸ್ಟೀಲ್ ನೀರಿನ ಬಾಟಲಿ (750ಮಿಲಿ)", "hi": "स्टेनलेस स्टील पानी की बोतल (750ml)", "te": "స్టెయిన్‌లెస్ స్టీల్ వాటర్ బాటిల్ (750ml)", "ta": "துருப்பிடிக்காத எஃகு தண்ணீர் பாட்டில் (750ml)"}'::jsonb,
   250, 2, NULL, 35, 'assets/rewards/bottle.png', true),
  ('11111111-1111-1111-1111-111111110004',
   '{"en": "Heavy-Duty Field Tool Bag", "kn": "ಗಟ್ಟಿಮುಟ್ಟಾದ ಉಪಕರಣ ಬ್ಯಾಗ್", "hi": "मजबूत फील्ड टूल बैग", "te": "హెవీ డ్యూటీ ఫీల్డ్ టూల్ బ్యాగ్", "ta": "களக் கருவி பை"}'::jsonb,
   500, 3, NULL, 20, 'assets/rewards/bag.png', true),
  ('11111111-1111-1111-1111-111111110005',
   '{"en": "Official ID Lanyard & Holder", "kn": "ಅಧಿಕೃತ ಗುರುತಿನ ಚೀಟಿ ಲ್ಯಾನ್ಯಾರ್ಡ್", "hi": "आधिकारिक आईडी लैनयार्ड और होल्डर", "te": "అధికారిక ఐడి లాన్యార్డ్", "ta": "அடையாள அட்டை லேன்யார்ட்"}'::jsonb,
   100, 1, NULL, 150, 'assets/rewards/lanyard.png', true),
  ('11111111-1111-1111-1111-111111110006',
   '{"en": "Reflective Stickers & Badges Pack", "kn": "ಪ್ರತಿಫಲಕ ಸ್ಟಿಕ್ಕರ್‌ಗಳ ಪ್ಯಾಕ್", "hi": "चिंतनशील स्टिकर और बैज पैक", "te": "రిఫ్లెక్టివ్ స్టిక్కర్ల ప్యాక్", "ta": "பிரதிபலிப்பு ஸ்டிக்கர் பேக்"}'::jsonb,
   50, 1, NULL, 200, 'assets/rewards/stickers.png', true),
  ('11111111-1111-1111-1111-111111110007',
   '{"en": "Hi-Vis Reflective Safety Vest", "kn": "ಹೆಚ್ಚು ಗೋಚರಿಸುವ ಸುರಕ್ಷತಾ ವೆಸ್ಟ್", "hi": "उच्च दृश्यता चिंतनशील सुरक्षा बनियान", "te": "హై-విస్ భద్రతా వెస్ట్", "ta": "பிரதிபலிப்பு பாதுகாப்பு உடுப்பு"}'::jsonb,
   400, 2, (SELECT id FROM public.badges WHERE slug = 'safety_champion'), 25, 'assets/rewards/safety_vest.png', true)
ON CONFLICT (id) DO UPDATE SET
  names = EXCLUDED.names,
  points_cost = EXCLUDED.points_cost,
  min_level = EXCLUDED.min_level,
  required_badge_id = EXCLUDED.required_badge_id,
  stock = EXCLUDED.stock,
  active = EXCLUDED.active;

-- 6. Seed Learning Modules
INSERT INTO public.learning_modules (id, slug, titles, category, content, quiz) VALUES
  ('22222222-2222-2222-2222-222222220001',
   'module_safety',
   '{"en": "Worksite Safety & Emergency Protocols", "kn": "ಕೆಲಸದ ಸ್ಥಳದ ಸುರಕ್ಷತೆ ಮತ್ತು ತುರ್ತು ನಿಯಮಗಳು", "hi": "कार्यस्थल सुरक्षा और आपातकालीन प्रोटोकॉल", "te": "పని ప్రదేశ భద్రత మరియు అత్యవసర నియమాలు", "ta": "பணியிட பாதுகாப்பு மற்றும் அவசர நெறிமுறைகள்"}'::jsonb,
   'safety',
   '{"summary": "Master essential site safety, hazard identification, and emergency SOS triggers.", "video_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ", "duration_minutes": 5, "sections": [{"title": "Personal Protective Equipment", "body": "Always inspect your boots, gloves, and helmets before entering a construction or workshop site."}, {"title": "Two-Step Presence Verification", "body": "Never ask an employer to scan your ticket off-site. Both parties must be present within the 150m geofence."}, {"title": "Emergency SOS Escalation", "body": "If you ever feel in danger or encounter a site hazard, use the in-app SOS button immediately to alert dispatch and emergency contacts."}]}'::jsonb,
   '{"pass_percent": 80, "questions": [{"q": "When should you wear your protective equipment (PPE)?", "options": ["Only when the supervisor is looking", "At all times on the work site", "Only when performing electrical work", "Never"], "answer": 1, "explanation": "Safety gear must be worn at all times while active on any worksite."}, {"q": "What is the maximum geofence distance allowed for Step-2 site verification?", "options": ["50 meters", "150 meters", "1 kilometer", "Anywhere in the city"], "answer": 1, "explanation": "UdyogaSethu enforces a strict 150-meter GPS radius for verified check-in."}, {"q": "Who gets alerted when you trigger the Emergency SOS button?", "options": ["Only your social media", "Safety team, emergency contacts, and active booking log", "Nobody", "Just the client"], "answer": 1, "explanation": "The SOS system immediately registers an incident, notifies your trusted contacts, and records GPS telemetry."}]}'::jsonb),

  ('22222222-2222-2222-2222-222222220002',
   'module_hygiene',
   '{"en": "Food Hygiene & Safe Crop Handling", "kn": "ಆಹಾರ ನೈರ್ಮಲ್ಯ ಮತ್ತು ಸುರಕ್ಷಿತ ಬೆಳೆ ನಿರ್ವಹಣೆ", "hi": "खाद्य स्वच्छता और सुरक्षित फसल प्रबंधन", "te": "ఆహార పరిశుభ్రత మరియు పంట నిర్వహణ", "ta": "உணவு சுகாதாரம் மற்றும் பயிர் கையாளுதல்"}'::jsonb,
   'hygiene',
   '{"summary": "Learn post-harvest storage, clean sorting, and contamination prevention.", "video_url": null, "duration_minutes": 6, "sections": [{"title": "Sanitary Harvesting", "body": "Wash sorting crates with clean water before loading harvested vegetables or fruit."}, {"title": "Direct-to-Consumer Packaging", "body": "Ensure food contact bags are food-grade and free of pesticide traces."}, {"title": "Delivery Freshness", "body": "Keep perishable leafy greens in shaded moisture crates during transport to preserve grade-A crispness."}]}'::jsonb,
   '{"pass_percent": 80, "questions": [{"q": "How should sorting crates be prepared before harvesting?", "options": ["Washed with clean water and sanitized", "Left outdoors in dirt", "Sprayed with heavy chemicals", "Used as-is without checking"], "answer": 0, "explanation": "Clean and sanitized crates prevent bacterial contamination and fungal rot."}, {"q": "What packaging should be used for farm-to-consumer produce?", "options": ["Recycled chemical fertilizer bags", "Clean, food-grade ventilated packaging", "Unwashed newspaper only", "Open buckets"], "answer": 1, "explanation": "Food-grade packaging maintains freshness and complies with FSSAI hygiene guidelines."}, {"q": "Why is keeping vegetables shaded important during transport?", "options": ["To hide low quality", "To retain moisture and prevent wilting", "It is not important", "To make it heavier"], "answer": 1, "explanation": "Moisture preservation ensures consumers receive prime-grade fresh farm produce."}]}'::jsonb),

  ('22222222-2222-2222-2222-222222220003',
   'module_payments',
   '{"en": "Digital Payments & Escrow Literacy", "kn": "ಡಿಜಿಟಲ್ ಪಾವತಿಗಳು ಮತ್ತು ಎಸ್ಕ್ರೋ ಸಾಕ್ಷರತೆ", "hi": "डिजिटल भुगतान और एस्क्रो साक्षरता", "te": "డిజిటల్ చెల్లింపులు మరియు ఎస్క్రో పరిజ్ఞానం", "ta": "டிஜிட்டல் கொடுப்பனவுகள் மற்றும் எஸ்க்ரோ அறிவு"}'::jsonb,
   'finance',
   '{"summary": "Understand protected escrow, avoiding payment scams, and UPI bank transfers.", "video_url": null, "duration_minutes": 5, "sections": [{"title": "How Protected Escrow Works", "body": "Your wage is locked securely in platform escrow when the employer books you. It is released directly to your wallet upon verified job completion."}, {"title": "Never Accept Off-Platform Demands", "body": "Do not accept requests to transfer funds outside the app before work begins. Scammers use fake SMS alerts."}, {"title": "Instant Bank Payouts", "body": "Use the Wallet screen to withdraw your earnings to your verified bank account or UPI ID with 100% transparent fee receipts."}]}'::jsonb,
   '{"pass_percent": 80, "questions": [{"q": "When is platform escrow released to your wallet?", "options": ["Before you leave home", "Only upon verified job completion", "After 30 days", "Never"], "answer": 1, "explanation": "Escrow releases automatically once two-step verification and job completion are recorded."}, {"q": "What should you do if an employer asks you to pay a deposit outside the app?", "options": ["Pay it immediately", "Decline and report the user for off-platform violation", "Share your bank PIN", "Ignore and work anyway"], "answer": 1, "explanation": "UdyogaSethu never requires upfront worker deposits. Off-platform requests violate safety policies."}, {"q": "Where can you view your detailed transaction receipts?", "options": ["In the Wallet screen", "In phone settings", "In your camera gallery", "Nowhere"], "answer": 0, "explanation": "The Wallet screen shows every credit, fee, withdrawal, and 12-digit UTR reference."}]}'::jsonb),

  ('22222222-2222-2222-2222-222222220004',
   'module_conduct',
   '{"en": "Professional Customer Conduct & Communication", "kn": "ವೃತ್ತಿಪರ ಗ್ರಾಹಕ ನಡವಳಿಕೆ ಮತ್ತು ಸಂವಹನ", "hi": "पेशेवर ग्राहक आचरण और संचार", "te": "వృత్తిపరమైన కస్టమర్ ప్రవర్తన మరియు కమ్యూనికేషన్", "ta": "தொழில்முறை வாடிக்கையாளர் நடத்தை மற்றும் தொடர்பு"}'::jsonb,
   'professional',
   '{"summary": "Building strong ratings, punctual arrival, and resolving mid-job questions politely.", "video_url": null, "duration_minutes": 4, "sections": [{"title": "Punctuality & Courtesy", "body": "Arrive 10 minutes early. Greet the household or site manager with a polite greeting in their language."}, {"title": "Handling Delays Honestly", "body": "If traffic or transit delays you, use the in-app Running Late option to notify the provider and extend the arrival window."}, {"title": "Receiving 5-Star Reviews", "body": "Clear your tools, tidy the workspace after work, and encourage the customer to leave an honest review."}]}'::jsonb,
   '{"pass_percent": 80, "questions": [{"q": "What should you do if you are running late due to transit?", "options": ["Turn off your phone", "Tap 'Running Late' in the app to notify the client and pause timer", "Arrive 2 hours later without saying anything", "Cancel the booking immediately"], "answer": 1, "explanation": "Proactive notification pauses the no-show recovery timer and preserves your trust score."}, {"q": "What is the best way to earn repeat bookings from clients?", "options": ["Polite conduct, quality work, and clean workspace handover", "Demanding extra cash", "Rushing through the work without checking", "Arriving unannounced"], "answer": 0, "explanation": "Quality work and respectful conduct earn 5-star ratings and inclusion in client Trust Circles."}, {"q": "Can you use the in-app chat for coordination?", "options": ["Yes, it protects phone numbers and chat history", "No, it is forbidden", "Only for emergencies", "Only if you pay extra"], "answer": 0, "explanation": "Protected in-app chat keeps your personal telephone number confidential."}]}'::jsonb),

  ('22222222-2222-2222-2222-222222220005',
   'module_farming',
   '{"en": "Organic Farming & Sustainable Practices", "kn": "ಸಾವಯವ ಕೃಷಿ ಮತ್ತು ಸುಸ್ಥಿರ ಪದ್ಧತಿಗಳು", "hi": "जैविक खेती और सतत अभ्यास", "te": "సేంద్రీయ వ్యవసాయం మరియు స్థిరమైన పద్ధతులు", "ta": "இயற்கை விவசாயம் மற்றும் நிலையான நடைமுறைகள்"}'::jsonb,
   'agriculture',
   '{"summary": "Soil preparation, Jeevamrutha preparation, and organic pest barriers.", "video_url": null, "duration_minutes": 7, "sections": [{"title": "Soil Organic Matter", "body": "Incorporate farmyard manure and mulching to retain soil moisture during dry spells."}, {"title": "Natural Pest Repellents", "body": "Use Neem oil (Azadirachtin) or Dashaparni Kashaya instead of synthetic organophosphates."}, {"title": "Direct Market Advantage", "body": "Listing produce as Organic Verified commands a 15-20% fair pricing band in urban direct sales."}]}'::jsonb,
   '{"pass_percent": 80, "questions": [{"q": "What is a major advantage of mulching on farm beds?", "options": ["Conserves soil moisture and suppresses weed growth", "Makes soil dry", "Attracts pests", "Reduces crop yield"], "answer": 0, "explanation": "Mulching protects soil biology, cuts water loss, and controls weed competition."}, {"q": "Which natural spray is effective for organic pest control?", "options": ["Neem-based organic decoctions", "Heavy synthetic DDT", "Salt water only", "Diesel fuel"], "answer": 0, "explanation": "Neem oil and traditional herbal decoctions safely repel sucking pests without residue."}, {"q": "How does Organic certification help farmers on UdyogaSethu?", "options": ["Enables premium direct-to-consumer pricing bands", "Restricts market sales", "Increases middleman commission", "Has no benefit"], "answer": 0, "explanation": "Direct-to-consumer buyers eagerly pay fair premiums for verified organic produce."}]}'::jsonb)
ON CONFLICT (slug) DO UPDATE SET
  titles = EXCLUDED.titles,
  category = EXCLUDED.category,
  content = EXCLUDED.content,
  quiz = EXCLUDED.quiz;

-- 7. Seed Training Events
INSERT INTO public.training_events (id, kind, title, description, starts_at, venue, capacity, language) VALUES
  ('33333333-3333-3333-3333-333333330001',
   'workshop',
   'Workplace Electrical Safety Workshop',
   'Hands-on session covering three-phase safety, earth resistance testing, and shock prevention with certified trainers.',
   NOW() + INTERVAL '3 days 4 hours',
   'Government ITI Campus, Dairy Circle, Bengaluru',
   40,
   'kn'),
  ('33333333-3333-3333-3333-333333330002',
   'camp',
   'Digital Payments & Escrow Literacy Camp',
   'Learn UPI Auto-Payouts, verifying escrow releases, and smartphone security for daily-wage workers.',
   NOW() + INTERVAL '7 days 2 hours',
   'Community Hall, Indiranagar BDA Complex, Bengaluru',
   60,
   'en'),
  ('33333333-3333-3333-3333-333333330003',
   'camp',
   'Natural Farming & Direct Mandi Linkage Camp',
   'Soil testing demonstration, organic certification guidance, and direct-to-consumer logistics meetup.',
   NOW() + INTERVAL '12 days 6 hours',
   'APMC Yard Kisan Bhavan, Mandya',
   100,
   'kn')
ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  starts_at = EXCLUDED.starts_at,
  venue = EXCLUDED.venue;

-- 8. Helper Functions: Award XP, update streaks, update badges

-- RPC: award_xp
CREATE OR REPLACE FUNCTION public.award_xp(
  p_user_id UUID,
  p_kind TEXT,
  p_points INT,
  p_ref_type TEXT DEFAULT NULL,
  p_ref_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_exists BOOLEAN := false;
  v_total_xp BIGINT;
  v_old_level INT;
  v_new_level INT;
  v_new_level_name TEXT;
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'User ID required';
  END IF;

  -- 1. Idempotency check if ref_type & ref_id supplied
  IF p_ref_type IS NOT NULL AND p_ref_id IS NOT NULL THEN
    SELECT EXISTS (
      SELECT 1 FROM public.xp_events
      WHERE user_id = p_user_id AND ref_type = p_ref_type AND ref_id = p_ref_id AND kind = p_kind
    ) INTO v_exists;

    IF v_exists THEN
      -- Already awarded, return current total without duplicating
      SELECT COALESCE(SUM(points), 0) INTO v_total_xp FROM public.xp_events WHERE user_id = p_user_id;
      RETURN jsonb_build_object('success', true, 'duplicate', true, 'total_xp', v_total_xp);
    END IF;
  END IF;

  -- 2. Previous total XP
  SELECT COALESCE(SUM(points), 0) INTO v_total_xp FROM public.xp_events WHERE user_id = p_user_id;

  SELECT level_number INTO v_old_level
  FROM public.levels
  WHERE min_xp <= v_total_xp
  ORDER BY min_xp DESC LIMIT 1;
  IF v_old_level IS NULL THEN v_old_level := 1; END IF;

  -- 3. Insert XP event
  INSERT INTO public.xp_events (user_id, kind, points, ref_type, ref_id)
  VALUES (p_user_id, p_kind, p_points, p_ref_type, p_ref_id);

  v_total_xp := v_total_xp + p_points;

  -- 4. Check new level
  SELECT level_number, name INTO v_new_level, v_new_level_name
  FROM public.levels
  WHERE min_xp <= v_total_xp
  ORDER BY min_xp DESC LIMIT 1;
  IF v_new_level IS NULL THEN v_new_level := 1; v_new_level_name := 'Starter'; END IF;

  -- 5. If leveled up, notify user
  IF v_new_level > v_old_level THEN
    INSERT INTO public.notifications (user_id, type, title_key, body_key, params)
    VALUES (
      p_user_id,
      'level_up',
      'notificationLevelUpTitle',
      'notificationLevelUpBody',
      jsonb_build_object('level', v_new_level, 'level_name', v_new_level_name, 'points', p_points)
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'awarded', p_points,
    'total_xp', v_total_xp,
    'level', v_new_level,
    'level_name', v_new_level_name,
    'level_up', v_new_level > v_old_level
  );
END;
$$;

-- RPC: get_user_gamification_profile
CREATE OR REPLACE FUNCTION public.get_user_gamification_profile(p_user_id UUID DEFAULT auth.uid())
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid UUID := COALESCE(p_user_id, auth.uid());
  v_total_xp BIGINT := 0;
  v_spent_points BIGINT := 0;
  v_avail_points BIGINT := 0;
  v_curr_level RECORD;
  v_next_level RECORD;
  v_progress_pct NUMERIC := 0.0;
  v_badges JSONB := '[]'::jsonb;
  v_streaks JSONB := '[]'::jsonb;
  v_ref_code TEXT;
  v_referrals_count INT := 0;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- 1. Total XP and spent points
  SELECT COALESCE(SUM(points), 0) INTO v_total_xp FROM public.xp_events WHERE user_id = v_uid;
  SELECT COALESCE(SUM(points_spent), 0) INTO v_spent_points FROM public.reward_redemptions WHERE user_id = v_uid;
  v_avail_points := GREATEST(0, v_total_xp - v_spent_points);

  -- 2. Current level
  SELECT * INTO v_curr_level
  FROM public.levels
  WHERE min_xp <= v_total_xp
  ORDER BY min_xp DESC
  LIMIT 1;

  IF v_curr_level IS NULL THEN
    SELECT * INTO v_curr_level FROM public.levels WHERE level_number = 1;
  END IF;

  -- 3. Next level
  SELECT * INTO v_next_level
  FROM public.levels
  WHERE min_xp > v_total_xp
  ORDER BY min_xp ASC
  LIMIT 1;

  IF v_next_level IS NOT NULL THEN
    v_progress_pct := ROUND(((v_total_xp - v_curr_level.min_xp)::NUMERIC / NULLIF(v_next_level.min_xp - v_curr_level.min_xp, 0)::NUMERIC) * 100, 1);
  ELSE
    v_progress_pct := 100.0;
  END IF;

  -- 4. Badges (with earned status)
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', b.id,
      'slug', b.slug,
      'names', b.names,
      'criteria', b.criteria,
      'is_earned', (ub.user_id IS NOT NULL),
      'awarded_at', ub.awarded_at
    ) ORDER BY (ub.user_id IS NOT NULL) DESC, b.slug ASC
  ), '[]'::jsonb)
  INTO v_badges
  FROM public.badges b
  LEFT JOIN public.user_badges ub ON b.id = ub.badge_id AND ub.user_id = v_uid;

  -- 5. Streaks
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', s.id,
      'kind', s.kind,
      'current', s.current,
      'best', s.best,
      'last_date', s.last_date,
      'at_risk', (s.last_date IS NOT NULL AND s.last_date < CURRENT_DATE - 1)
    ) ORDER BY s.kind ASC
  ), '[]'::jsonb)
  INTO v_streaks
  FROM public.streaks s
  WHERE s.user_id = v_uid;

  -- 6. Referral code and count
  SELECT code INTO v_ref_code FROM public.referral_codes WHERE user_id = v_uid;
  SELECT COUNT(*) INTO v_referrals_count FROM public.referrals WHERE referrer_id = v_uid AND reward_given = true;

  RETURN jsonb_build_object(
    'user_id', v_uid,
    'total_xp', v_total_xp,
    'spent_points', v_spent_points,
    'available_points', v_avail_points,
    'current_level', jsonb_build_object(
      'level_number', v_curr_level.level_number,
      'name', v_curr_level.name,
      'min_xp', v_curr_level.min_xp,
      'perks', v_curr_level.perks
    ),
    'next_level', CASE WHEN v_next_level IS NOT NULL THEN jsonb_build_object(
      'level_number', v_next_level.level_number,
      'name', v_next_level.name,
      'min_xp', v_next_level.min_xp
    ) ELSE NULL END,
    'progress_percent', v_progress_pct,
    'badges', v_badges,
    'streaks', v_streaks,
    'referral_code', v_ref_code,
    'successful_referrals', v_referrals_count
  );
END;
$$;

-- RPC: redeem_reward_item
CREATE OR REPLACE FUNCTION public.redeem_reward_item(
  p_item_id UUID,
  p_shipping_address JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_item RECORD;
  v_total_xp BIGINT := 0;
  v_spent_points BIGINT := 0;
  v_avail_points BIGINT := 0;
  v_user_level RECORD;
  v_has_badge BOOLEAN := true;
  v_redemption_id UUID;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_shipping_address IS NULL OR p_shipping_address->>'street' IS NULL THEN
    RAISE EXCEPTION 'Complete shipping address is required';
  END IF;

  -- 1. Row-level lock on item to eliminate race conditions
  SELECT * INTO v_item
  FROM public.reward_items
  WHERE id = p_item_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reward item not found';
  END IF;

  IF NOT v_item.active THEN
    RAISE EXCEPTION 'Item is no longer available';
  END IF;

  IF v_item.stock <= 0 THEN
    RAISE EXCEPTION 'Item is out of stock';
  END IF;

  -- 2. Check points balance
  SELECT COALESCE(SUM(points), 0) INTO v_total_xp FROM public.xp_events WHERE user_id = v_uid;
  SELECT COALESCE(SUM(points_spent), 0) INTO v_spent_points FROM public.reward_redemptions WHERE user_id = v_uid;
  v_avail_points := v_total_xp - v_spent_points;

  IF v_avail_points < v_item.points_cost THEN
    RAISE EXCEPTION 'Insufficient points: required %, available %', v_item.points_cost, v_avail_points;
  END IF;

  -- 3. Check level requirement
  SELECT * INTO v_user_level
  FROM public.levels
  WHERE min_xp <= v_total_xp
  ORDER BY min_xp DESC LIMIT 1;

  IF v_user_level IS NULL OR v_user_level.level_number < v_item.min_level THEN
    RAISE EXCEPTION 'Requires Level % or higher', v_item.min_level;
  END IF;

  -- 4. Check required badge if specified
  IF v_item.required_badge_id IS NOT NULL THEN
    SELECT EXISTS (
      SELECT 1 FROM public.user_badges
      WHERE user_id = v_uid AND badge_id = v_item.required_badge_id
    ) INTO v_has_badge;

    IF NOT v_has_badge THEN
      RAISE EXCEPTION 'Required achievement badge not earned for this reward item';
    END IF;
  END IF;

  -- 5. Atomic stock reduction
  UPDATE public.reward_items
  SET stock = stock - 1
  WHERE id = p_item_id;

  -- 6. Record redemption
  INSERT INTO public.reward_redemptions (
    user_id, item_id, points_spent, status, shipping_address
  ) VALUES (
    v_uid, p_item_id, v_item.points_cost, 'requested', p_shipping_address
  ) RETURNING id INTO v_redemption_id;

  -- 7. Notify user
  INSERT INTO public.notifications (user_id, type, title_key, body_key, params)
  VALUES (
    v_uid,
    'reward_redeemed',
    'notificationRewardRedeemedTitle',
    'notificationRewardRedeemedBody',
    jsonb_build_object('item_name', v_item.names->>'en', 'points', v_item.points_cost, 'redemption_id', v_redemption_id)
  );

  RETURN jsonb_build_object(
    'success', true,
    'redemption_id', v_redemption_id,
    'item_id', p_item_id,
    'points_spent', v_item.points_cost,
    'remaining_points', v_avail_points - v_item.points_cost,
    'status', 'requested'
  );
END;
$$;

-- RPC: get_or_create_referral_code
CREATE OR REPLACE FUNCTION public.get_or_create_referral_code(p_user_id UUID DEFAULT auth.uid())
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid UUID := COALESCE(p_user_id, auth.uid());
  v_code TEXT;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT code INTO v_code FROM public.referral_codes WHERE user_id = v_uid;
  IF v_code IS NOT NULL THEN
    RETURN v_code;
  END IF;

  -- Generate clean 8-char uppercase code (e.g. SETU8A4F)
  v_code := 'SETU' || UPPER(SUBSTRING(MD5(v_uid::TEXT || NOW()::TEXT) FROM 1 FOR 4));

  INSERT INTO public.referral_codes (user_id, code)
  VALUES (v_uid, v_code)
  ON CONFLICT (user_id) DO UPDATE SET code = EXCLUDED.code
  RETURNING code INTO v_code;

  RETURN v_code;
END;
$$;

-- RPC: apply_referral_code
CREATE OR REPLACE FUNCTION public.apply_referral_code(p_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_referrer_id UUID;
  v_cleaned_code TEXT := UPPER(TRIM(p_code));
  v_exists BOOLEAN;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- 1. Find referrer
  SELECT user_id INTO v_referrer_id
  FROM public.referral_codes
  WHERE code = v_cleaned_code;

  IF v_referrer_id IS NULL THEN
    RAISE EXCEPTION 'Invalid referral code';
  END IF;

  -- 2. Prevent self-referral
  IF v_referrer_id = v_uid THEN
    RAISE EXCEPTION 'Cannot use your own referral code';
  END IF;

  -- 3. Prevent duplicate referral use
  SELECT EXISTS (
    SELECT 1 FROM public.referrals WHERE referred_id = v_uid
  ) INTO v_exists;

  IF v_exists THEN
    RAISE EXCEPTION 'A referral code has already been applied to your account';
  END IF;

  -- 4. Record pending referral
  INSERT INTO public.referrals (referrer_id, referred_id, status, reward_given)
  VALUES (v_referrer_id, v_uid, 'pending', false);

  RETURN jsonb_build_object(
    'success', true,
    'referrer_id', v_referrer_id,
    'code', v_cleaned_code,
    'message', 'Referral code applied. Rewards will unlock after your first completed job or order!'
  );
END;
$$;

-- RPC: submit_learning_quiz
CREATE OR REPLACE FUNCTION public.submit_learning_quiz(
  p_module_id UUID,
  p_score INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_module RECORD;
  v_passed BOOLEAN;
  v_xp_pts INT := 40;
  v_cred_kind TEXT;
  v_badge_slug TEXT;
  v_badge_id UUID;
  v_already_completed BOOLEAN := false;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_module FROM public.learning_modules WHERE id = p_module_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Module not found';
  END IF;

  v_passed := (p_score >= 80);

  -- Check if already completed previously to guarantee XP awarded exactly once
  SELECT completed INTO v_already_completed
  FROM public.learning_progress
  WHERE user_id = v_uid AND module_id = p_module_id;

  -- Record progress
  INSERT INTO public.learning_progress (user_id, module_id, score, completed, completed_at)
  VALUES (v_uid, p_module_id, p_score, v_passed, CASE WHEN v_passed THEN NOW() ELSE NULL END)
  ON CONFLICT (user_id, module_id) DO UPDATE SET
    score = GREATEST(public.learning_progress.score, EXCLUDED.score),
    completed = public.learning_progress.completed OR EXCLUDED.completed,
    completed_at = COALESCE(public.learning_progress.completed_at, EXCLUDED.completed_at);

  IF v_passed THEN
    -- Map module slug to credential kind and badge
    IF v_module.slug = 'module_safety' THEN
      v_cred_kind := 'worksite_safety_certified';
    ELSIF v_module.slug = 'module_hygiene' THEN
      v_cred_kind := 'food_hygiene_certified';
      v_badge_slug := 'food_hygiene_certified';
    ELSIF v_module.slug = 'module_payments' THEN
      v_cred_kind := 'digital_payments_ready';
      v_badge_slug := 'digital_ready_worker';
    ELSIF v_module.slug = 'module_conduct' THEN
      v_cred_kind := 'customer_relations_certified';
    ELSIF v_module.slug = 'module_farming' THEN
      v_cred_kind := 'organic_farming_practitioner';
    ELSE
      v_cred_kind := v_module.slug || '_certified';
    END IF;

    -- Award micro-credential
    INSERT INTO public.credentials (user_id, kind, source_type, module_id, is_verified, verified_at, title)
    VALUES (v_uid, v_cred_kind, 'module', p_module_id, true, NOW(), v_module.titles->>'en')
    ON CONFLICT DO NOTHING;

    -- Award badge if applicable
    IF v_badge_slug IS NOT NULL THEN
      SELECT id INTO v_badge_id FROM public.badges WHERE slug = v_badge_slug;
      IF v_badge_id IS NOT NULL THEN
        INSERT INTO public.user_badges (user_id, badge_id)
        VALUES (v_uid, v_badge_id)
        ON CONFLICT DO NOTHING;
      END IF;
    END IF;

    -- Award training XP exactly once
    IF NOT COALESCE(v_already_completed, false) THEN
      SELECT (value::TEXT)::INT INTO v_xp_pts FROM public.admin_settings WHERE key = 'xp_training_completed';
      IF v_xp_pts IS NULL THEN v_xp_pts := 40; END IF;
      PERFORM public.award_xp(v_uid, 'training_completion', v_xp_pts, 'learning_module', p_module_id);
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'passed', v_passed,
    'score', p_score,
    'credential_awarded', v_passed,
    'credential_kind', v_cred_kind,
    'xp_awarded', CASE WHEN (v_passed AND NOT COALESCE(v_already_completed, false)) THEN v_xp_pts ELSE 0 END
  );
END;
$$;

-- RPC: register_for_training_event
CREATE OR REPLACE FUNCTION public.register_for_training_event(p_event_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_event RECORD;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_event FROM public.training_events WHERE id = p_event_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Event not found';
  END IF;

  INSERT INTO public.event_registrations (event_id, user_id, status)
  VALUES (p_event_id, v_uid, 'registered')
  ON CONFLICT (event_id, user_id) DO UPDATE SET updated_at = NOW();

  -- Add notification reminder
  INSERT INTO public.notifications (user_id, type, title_key, body_key, params)
  VALUES (
    v_uid,
    'event_registered',
    'notificationEventRegisteredTitle',
    'notificationEventRegisteredBody',
    jsonb_build_object('event_title', v_event.title, 'venue', v_event.venue, 'starts_at', v_event.starts_at)
  );

  RETURN jsonb_build_object(
    'success', true,
    'event_id', p_event_id,
    'status', 'registered'
  );
END;
$$;

-- RPC: upload_external_certificate
CREATE OR REPLACE FUNCTION public.upload_external_certificate(
  p_kind TEXT,
  p_title TEXT,
  p_issuing_org TEXT,
  p_certificate_path TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_cred_id UUID;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Created strictly with is_verified = false (Pending Admin Review)
  INSERT INTO public.credentials (
    user_id, kind, source_type, certificate_path, is_verified, title, issuing_organization
  ) VALUES (
    v_uid, p_kind, 'uploaded_certificate', p_certificate_path, false, p_title, p_issuing_org
  ) RETURNING id INTO v_cred_id;

  RETURN jsonb_build_object(
    'success', true,
    'credential_id', v_cred_id,
    'is_verified', false,
    'status', 'pending_admin_review'
  );
END;
$$;

-- 9. Trigger on job_assignments: Award XP for verified completion & on-time, update streaks, award referral
CREATE OR REPLACE FUNCTION public.handle_job_assignment_gamification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_xp_completion INT := 50;
  v_xp_ontime INT := 20;
  v_is_ontime BOOLEAN := false;
  v_ref_record RECORD;
  v_xp_referral INT := 100;
  v_curr_ontime_streak INT := 0;
  v_dispute_count INT := 0;
BEGIN
  -- Only execute when transitioning to 'completed'
  IF NEW.status = 'completed' AND (OLD.status IS DISTINCT FROM 'completed') THEN
    -- Fetch settings
    SELECT (value::TEXT)::INT INTO v_xp_completion FROM public.admin_settings WHERE key = 'xp_job_completed';
    IF v_xp_completion IS NULL THEN v_xp_completion := 50; END IF;

    SELECT (value::TEXT)::INT INTO v_xp_ontime FROM public.admin_settings WHERE key = 'xp_on_time';
    IF v_xp_ontime IS NULL THEN v_xp_ontime := 20; END IF;

    -- 1. Award Verified Job Completion XP to worker
    PERFORM public.award_xp(NEW.worker_id, 'job_completion', v_xp_completion, 'job_assignment', NEW.id);

    -- 2. Check on-time arrival
    IF NEW.arrived_at IS NOT NULL THEN
      -- If arrived within 15 minutes of job start
      SELECT (NEW.arrived_at <= (j.start_at + INTERVAL '15 minutes')) INTO v_is_ontime
      FROM public.jobs j WHERE j.id = NEW.job_id;

      IF v_is_ontime THEN
        PERFORM public.award_xp(NEW.worker_id, 'on_time_arrival', v_xp_ontime, 'job_assignment_ontime', NEW.id);

        -- Update on-time streak
        INSERT INTO public.streaks (user_id, kind, current, best, last_date)
        VALUES (NEW.worker_id, 'on_time_jobs', 1, 1, CURRENT_DATE)
        ON CONFLICT (user_id, kind) DO UPDATE SET
          current = public.streaks.current + 1,
          best = GREATEST(public.streaks.best, public.streaks.current + 1),
          last_date = CURRENT_DATE
        RETURNING current INTO v_curr_ontime_streak;

        -- Check badge: Always On-Time (5+ consecutive on-time jobs)
        IF v_curr_ontime_streak >= 5 THEN
          INSERT INTO public.user_badges (user_id, badge_id)
          SELECT NEW.worker_id, id FROM public.badges WHERE slug = 'always_on_time'
          ON CONFLICT DO NOTHING;
        END IF;
      ELSE
        -- Reset on-time streak
        UPDATE public.streaks
        SET current = 0, last_date = CURRENT_DATE
        WHERE user_id = NEW.worker_id AND kind = 'on_time_jobs';
      END IF;
    END IF;

    -- 3. Update clean record streak
    SELECT COUNT(*) INTO v_dispute_count
    FROM public.disputes
    WHERE ref_id = NEW.id AND ref_type = 'assignment';

    IF v_dispute_count = 0 THEN
      INSERT INTO public.streaks (user_id, kind, current, best, last_date)
      VALUES (NEW.worker_id, 'clean_record', 1, 1, CURRENT_DATE)
      ON CONFLICT (user_id, kind) DO UPDATE SET
        current = public.streaks.current + 1,
        best = GREATEST(public.streaks.best, public.streaks.current + 1),
        last_date = CURRENT_DATE;

      -- If 10+ completed jobs with zero disputes, award clean_record badge
      IF (SELECT current FROM public.streaks WHERE user_id = NEW.worker_id AND kind = 'clean_record') >= 10 THEN
        INSERT INTO public.user_badges (user_id, badge_id)
        SELECT NEW.worker_id, id FROM public.badges WHERE slug = 'clean_record'
        ON CONFLICT DO NOTHING;
      END IF;
    END IF;

    -- 4. Check referral reward unlocking
    SELECT * INTO v_ref_record
    FROM public.referrals
    WHERE referred_id = NEW.worker_id AND reward_given = false;

    IF v_ref_record.id IS NOT NULL THEN
      SELECT (value::TEXT)::INT INTO v_xp_referral FROM public.admin_settings WHERE key = 'xp_referral_reward';
      IF v_xp_referral IS NULL THEN v_xp_referral := 100; END IF;

      -- Award referrer XP
      PERFORM public.award_xp(v_ref_record.referrer_id, 'valid_referral', v_xp_referral, 'referral', v_ref_record.id);

      -- Mark referral reward given and active
      UPDATE public.referrals
      SET status = 'completed', reward_given = true
      WHERE id = v_ref_record.id;

      -- Check Community Mentor badge (3+ referrals)
      IF (SELECT COUNT(*) FROM public.referrals WHERE referrer_id = v_ref_record.referrer_id AND reward_given = true) >= 3 THEN
        INSERT INTO public.user_badges (user_id, badge_id)
        SELECT v_ref_record.referrer_id, id FROM public.badges WHERE slug = 'community_mentor'
        ON CONFLICT DO NOTHING;
      END IF;

      -- Notify referrer
      INSERT INTO public.notifications (user_id, type, title_key, body_key, params)
      VALUES (
        v_ref_record.referrer_id,
        'referral_reward',
        'notificationReferralSuccessTitle',
        'notificationReferralSuccessBody',
        jsonb_build_object('points', v_xp_referral)
      );
    END IF;

  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_job_assignment_gamification ON public.job_assignments;
CREATE TRIGGER trg_job_assignment_gamification
  AFTER UPDATE OF status ON public.job_assignments
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_job_assignment_gamification();

-- 10. Update record_release_escrow to enforce Genuine Level Commission Perk Override!
CREATE OR REPLACE FUNCTION public.record_release_escrow(
  p_payment_id UUID,
  p_assignment_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_payment RECORD;
  v_bps_setting JSONB;
  v_bps BIGINT := 500;
  v_perk_bps BIGINT;
  v_fee BIGINT;
  v_net BIGINT;
  v_dispute_count INT := 0;
  v_key_debit TEXT;
  v_key_credit TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_payment
  FROM public.payments
  WHERE id = p_payment_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payment % not found.', p_payment_id;
  END IF;

  IF v_payment.status = 'released' THEN
    RETURN jsonb_build_object(
      'success', true,
      'already_released', true,
      'payment_id', p_payment_id,
      'net_amount_paise', v_payment.amount_paise - COALESCE(v_payment.platform_fee_paise, 0)
    );
  END IF;

  IF v_payment.status NOT IN ('captured', 'authorized') THEN
    RAISE EXCEPTION 'Cannot release escrow: payment status is %, expected captured.', v_payment.status;
  END IF;

  -- Check disputes
  IF v_payment.ref_type = 'job' OR v_payment.ref_type = 'assignment' THEN
    SELECT COUNT(*) INTO v_dispute_count
    FROM public.disputes
    WHERE ref_id = v_payment.ref_id
      AND status IN ('open', 'in_review');

    IF v_dispute_count > 0 THEN
      RAISE EXCEPTION 'Cannot release escrow: active dispute exists for assignment %.', v_payment.ref_id;
    END IF;
  END IF;

  -- Platform commission calculation: Check genuine level perks override!
  SELECT value INTO v_bps_setting
  FROM public.admin_settings
  WHERE key = 'commission_bps';

  IF v_bps_setting IS NOT NULL THEN
    v_bps := (v_bps_setting::TEXT)::BIGINT;
  END IF;

  -- Genuine level perk: query payee's level perk commission_bps override
  SELECT (l.perks->>'commission_bps')::BIGINT INTO v_perk_bps
  FROM public.levels l
  WHERE l.min_xp <= (SELECT COALESCE(SUM(points), 0) FROM public.xp_events WHERE user_id = v_payment.payee_id)
  ORDER BY l.min_xp DESC
  LIMIT 1;

  IF v_perk_bps IS NOT NULL AND v_perk_bps > 0 THEN
    v_bps := v_perk_bps; -- Applied level discount!
  END IF;

  IF v_payment.platform_fee_paise IS NOT NULL AND v_payment.platform_fee_paise > 0 THEN
    v_fee := v_payment.platform_fee_paise;
  ELSE
    v_fee := ROUND((v_payment.amount_paise * v_bps)::NUMERIC / 10000.0)::BIGINT;
  END IF;

  IF v_fee > v_payment.amount_paise THEN
    v_fee := 0;
  END IF;
  v_net := v_payment.amount_paise - v_fee;

  -- Ledger postings
  v_key_debit := 'release-debit-escrow-' || p_payment_id;
  v_key_credit := 'release-credit-available-' || p_payment_id;

  PERFORM public.wallet_debit(
    v_payment.payer_id,
    v_payment.amount_paise,
    'escrow',
    'payment',
    p_payment_id,
    v_key_debit,
    'Escrow released for verified service'
  );

  PERFORM public.wallet_credit(
    v_payment.payee_id,
    v_net,
    'available',
    'payment',
    p_payment_id,
    v_key_credit,
    'Earnings credited after platform fee'
  );

  UPDATE public.payments
  SET status = 'released',
      platform_fee_paise = v_fee,
      released_at = NOW(),
      updated_at = NOW()
  WHERE id = p_payment_id;

  RETURN jsonb_build_object(
    'success', true,
    'payment_id', p_payment_id,
    'gross_amount_paise', v_payment.amount_paise,
    'platform_fee_paise', v_fee,
    'commission_bps_applied', v_bps,
    'net_amount_paise', v_net,
    'status', 'released'
  );
END;
$$;

-- 11. Realtime Publication enablement
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE
      public.xp_events,
      public.user_badges,
      public.streaks,
      public.reward_redemptions;
  END IF;
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;
