-- Migration 0170: Add Student & Part-time categories and skills with multilingual JSONB names
-- Safe to run multiple times (ON CONFLICT DO NOTHING)

-- 1. Ensure audience column exists on service_categories
ALTER TABLE service_categories
ADD COLUMN IF NOT EXISTS audience text[] NOT NULL DEFAULT '{informal}';

UPDATE service_categories
SET audience = '{informal}'
WHERE audience IS NULL OR cardinality(audience) = 0;

-- 2. Insert Student and Part-time categories
INSERT INTO service_categories (slug, names, icon, sort, audience)
VALUES
  (
    'content-writing',
    '{"en": "Content & Writing", "kn": "ಕಂಟೆಂಟ್ ಮತ್ತು ಬರವಣಿಗೆ", "hi": "कंटेंट और लेखन", "te": "కంటెంట్ మరియు రచన", "ta": "உள்ளடக்கம் மற்றும் எழுத்து"}'::jsonb,
    'edit_note',
    13,
    '{student,part_time}'
  ),
  (
    'design-data-work',
    '{"en": "Design & Data Work", "kn": "ವಿನ್ಯಾಸ ಮತ್ತು ಡೇಟಾ ಕೆಲಸ", "hi": "डिज़ाइन और डेटा कार्य", "te": "డిజైన్ మరియు డేటా వర్క్", "ta": "வடிவமைப்பு மற்றும் தரவு பணி"}'::jsonb,
    'computer',
    14,
    '{student,part_time}'
  ),
  (
    'tutoring-academics',
    '{"en": "Tutoring & Academics", "kn": "ಬೋಧನೆ ಮತ್ತು ಶೈಕ್ಷಣಿಕ", "hi": "ट्यूशन और शिक्षा", "te": "ట్యూటరింగ్ మరియు అకాడమిక్స్", "ta": "டியூஷன் மற்றும் கல்வி"}'::jsonb,
    'school',
    15,
    '{student,part_time}'
  ),
  (
    'campus-brand-promotion',
    '{"en": "Campus & Brand Promotion", "kn": "ಕ್ಯಾಂಪಸ್ ಮತ್ತು ಬ್ರ್ಯಾಂಡ್ ಪ್ರಚಾರ", "hi": "कैंपस और ब्रांड प्रचार", "te": "క్యాంపస్ మరియు బ్రాండ్ ప్రమోషన్", "ta": "கேம்பஸ் மற்றும் பிராண்ட் விளம்பரம்"}'::jsonb,
    'campaign',
    16,
    '{student,part_time}'
  ),
  (
    'retail-food-service',
    '{"en": "Retail & Food Service", "kn": "ಚಿಲ್ಲರೆ ಮತ್ತು ಆಹಾರ ಸೇವೆ", "hi": "रिटेल और खाद्य सेवा", "te": "రిటైల్ మరియు ఫుడ్ సర్వీస్", "ta": "சில்லறை விற்பனை மற்றும் உணவு சேவை"}'::jsonb,
    'storefront',
    17,
    '{student,part_time}'
  ),
  (
    'delivery-gig-work',
    '{"en": "Delivery & Gig Work", "kn": "ಡೆಲಿವರಿ ಮತ್ತು ಗಿಗ್ ಕೆಲಸ", "hi": "डिलीवरी और गिग कार्य", "te": "డెలివరీ మరియు గిగ్ వర్క్", "ta": "டெலிவரி மற்றும் கிக் பணி"}'::jsonb,
    'two_wheeler',
    18,
    '{student,part_time}'
  )
ON CONFLICT (slug) DO UPDATE
SET audience = EXCLUDED.audience,
    names = EXCLUDED.names;

-- 3. Insert Skills under Student & Part-time categories looking up category_id by slug
INSERT INTO skills (category_id, names)
SELECT id, '{"en": "Content Writer", "kn": "ಕಂಟೆಂಟ್ ರೈಟರ್", "hi": "कंटेंट राइटर", "te": "కంటెంట్ రైటర్", "ta": "உள்ளடக்க எழுத்தாளர்"}'::jsonb
FROM service_categories WHERE slug = 'content-writing'
ON CONFLICT DO NOTHING;

INSERT INTO skills (category_id, names)
SELECT id, '{"en": "Copywriter", "kn": "ಕಾಪಿರೈಟರ್", "hi": "कॉपीराइटर", "te": "కాపీరైటర్", "ta": "நகலெழுதுபவர்"}'::jsonb
FROM service_categories WHERE slug = 'content-writing'
ON CONFLICT DO NOTHING;

INSERT INTO skills (category_id, names)
SELECT id, '{"en": "Social Media Assistant", "kn": "ಸೋಷಿಯಲ್ ಮೀಡಿಯಾ ಸಹಾಯಕ", "hi": "सोशल मीडिया असिस्टेंट", "te": "సోషల్ మీడియా అసిస్టెంట్", "ta": "சோஷியல் மீடியா உதவி"}'::jsonb
FROM service_categories WHERE slug = 'content-writing'
ON CONFLICT DO NOTHING;

-- Design & Data Work
INSERT INTO skills (category_id, names)
SELECT id, '{"en": "Graphic Designer", "kn": "ಗ್ರಾಫಿಕ್ ಡಿಸೈನರ್", "hi": "ग्राफिक डिजाइनर", "te": "గ్రాఫిక్ డిజైనర్", "ta": "கிராஃபிக் டிசைனர்"}'::jsonb
FROM service_categories WHERE slug = 'design-data-work'
ON CONFLICT DO NOTHING;

INSERT INTO skills (category_id, names)
SELECT id, '{"en": "Data Entry Specialist", "kn": "ಡೇಟಾ ಎಂಟ್ರಿ ಸ್ಪೆಷಲಿಸ್ಟ್", "hi": "डेटा एंट्री स्पेशलिस्ट", "te": "డేటా ఎంట్రీ నిపుణుడు", "ta": "தரவு உள்ளீடு நிபுணர்"}'::jsonb
FROM service_categories WHERE slug = 'design-data-work'
ON CONFLICT DO NOTHING;

INSERT INTO skills (category_id, names)
SELECT id, '{"en": "Transcriber", "kn": "ಟ್ರಾನ್ಸ್‌ಸ್ಕ್ರೈಬರ್", "hi": "ट्रांसक्राइबर", "te": "ట్రాన్స్‌స్క్రైబర్", "ta": "டிரான்ஸ்கிரைபர்"}'::jsonb
FROM service_categories WHERE slug = 'design-data-work'
ON CONFLICT DO NOTHING;

INSERT INTO skills (category_id, names)
SELECT id, '{"en": "AI Data Annotator", "kn": "ಎಐ ಡೇಟಾ ಅನೋಟೇಟರ್", "hi": "एआई डेटा एनोटेटर", "te": "AI డేటా అనోటేటర్", "ta": "AI தரவு குறிப்பாளர்"}'::jsonb
FROM service_categories WHERE slug = 'design-data-work'
ON CONFLICT DO NOTHING;

INSERT INTO skills (category_id, names)
SELECT id, '{"en": "Model Evaluator", "kn": "ಮಾಡೆಲ್ ಮೌಲ್ಯಮಾಪಕ", "hi": "मॉडल मूल्यांकक", "te": "మోడల్ వేల్యూయేటర్", "ta": "மாதிரி மதிப்பீட்டாளர்"}'::jsonb
FROM service_categories WHERE slug = 'design-data-work'
ON CONFLICT DO NOTHING;

-- Tutoring & Academics
INSERT INTO skills (category_id, names)
SELECT id, '{"en": "Private Tutor", "kn": "ಖಾಸಗಿ ಬೋಧಕ", "hi": "प्राइवेट ट्यूटर", "te": "ప్రైవేట్ ట్యూటర్", "ta": "தனிப்பயிற்சியாளர்"}'::jsonb
FROM service_categories WHERE slug = 'tutoring-academics'
ON CONFLICT DO NOTHING;

INSERT INTO skills (category_id, names)
SELECT id, '{"en": "Online Tutor", "kn": "ಆನ್‌ಲೈನ್ ಬೋಧಕ", "hi": "ऑनलाइन ट्यूटर", "te": "ఆన్‌లైన్ ట్యూటర్", "ta": "ஆன்லைன் ஆசிரியர்"}'::jsonb
FROM service_categories WHERE slug = 'tutoring-academics'
ON CONFLICT DO NOTHING;

INSERT INTO skills (category_id, names)
SELECT id, '{"en": "Teaching Assistant", "kn": "ಬೋಧನಾ ಸಹಾಯಕ", "hi": "शिक्षण सहायक", "te": "టీచింగ్ అసిస్టెంట్", "ta": "கற்பித்தல் உதவியாளர்"}'::jsonb
FROM service_categories WHERE slug = 'tutoring-academics'
ON CONFLICT DO NOTHING;

INSERT INTO skills (category_id, names)
SELECT id, '{"en": "Research Assistant", "kn": "ಸಂಶೋಧನಾ ಸಹಾಯಕ", "hi": "अनुसंधान सहायक", "te": "రీసెర్చ్ అసిస్టెంట్", "ta": "ஆராய்ச்சி உதவியாளர்"}'::jsonb
FROM service_categories WHERE slug = 'tutoring-academics'
ON CONFLICT DO NOTHING;

-- Campus & Brand Promotion
INSERT INTO skills (category_id, names)
SELECT id, '{"en": "Campus Ambassador", "kn": "ಕ್ಯಾಂಪಸ್ ರಾಯಭಾರಿ", "hi": "कैंपस एंबेसडर", "te": "క్యాంపస్ అంబాసిడర్", "ta": "கேம்பஸ் தூதர்"}'::jsonb
FROM service_categories WHERE slug = 'campus-brand-promotion'
ON CONFLICT DO NOTHING;

INSERT INTO skills (category_id, names)
SELECT id, '{"en": "Brand Ambassador", "kn": "ಬ್ರ್ಯಾಂಡ್ ರಾಯಭಾರಿ", "hi": "ब्रांड एंबेसडर", "te": "బ్రాండ్ అంబాసిడర్", "ta": "பிராண்ட் தூதர்"}'::jsonb
FROM service_categories WHERE slug = 'campus-brand-promotion'
ON CONFLICT DO NOTHING;

-- Retail & Food Service
INSERT INTO skills (category_id, names)
SELECT id, '{"en": "Retail Associate", "kn": "ರಿಟೇಲ್ ಸಹಾಯಕ", "hi": "रिटेल एसोसिएट", "te": "రిటైల్ అసోసియేట్", "ta": "சில்லறை விற்பனை உதவியாளர்"}'::jsonb
FROM service_categories WHERE slug = 'retail-food-service'
ON CONFLICT DO NOTHING;

INSERT INTO skills (category_id, names)
SELECT id, '{"en": "Cashier", "kn": "ಕ್ಯಾಷಿಯರ್", "hi": "कैशियर", "te": "క్యాషియర్", "ta": "காசாளர்"}'::jsonb
FROM service_categories WHERE slug = 'retail-food-service'
ON CONFLICT DO NOTHING;

INSERT INTO skills (category_id, names)
SELECT id, '{"en": "Barista", "kn": "ಬರಿಸ್ತಾ", "hi": "बरिस्ता", "te": "బారిస్టా", "ta": "பாரிஸ்டா"}'::jsonb
FROM service_categories WHERE slug = 'retail-food-service'
ON CONFLICT DO NOTHING;

INSERT INTO skills (category_id, names)
SELECT id, '{"en": "Food Service Staff", "kn": "ಆಹಾರ ಸೇವಾ ಸಿಬ್ಬಂದಿ", "hi": "खाद्य सेवा कर्मचारी", "te": "ఫుడ్ సర్వీస్ సిబ్బంది", "ta": "உணவு சேவை ஊழியர்கள்"}'::jsonb
FROM service_categories WHERE slug = 'retail-food-service'
ON CONFLICT DO NOTHING;

-- Delivery & Gig Work
INSERT INTO skills (category_id, names)
SELECT id, '{"en": "Gig Delivery Partner", "kn": "ಗಿಗ್ ಡೆಲಿವರಿ ಪಾರ್ಟ್‌ನೆರ್", "hi": "गिग डिलीवरी पार्टनर", "te": "గిగ్ డెలివరీ పార్ట్‌నర్", "ta": "கிக் டெலிவரி பார்ட்னர்"}'::jsonb
FROM service_categories WHERE slug = 'delivery-gig-work'
ON CONFLICT DO NOTHING;

-- 4. RLS policies allowing authenticated and anon read access
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'service_categories' AND policyname = 'Allow select service_categories for all'
  ) THEN
    CREATE POLICY "Allow select service_categories for all" ON service_categories FOR SELECT USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'skills' AND policyname = 'Allow select skills for all'
  ) THEN
    CREATE POLICY "Allow select skills for all" ON skills FOR SELECT USING (true);
  END IF;
END $$;

NOTIFY pgrst, 'reload schema';
