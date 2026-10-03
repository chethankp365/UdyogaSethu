-- Migration: 0150_seed_skills.sql
-- Description: Seed realistic multi-lingual skills for all 12 service categories and update RLS policies.

-- 1. Create unique index for idempotent skill seeding
CREATE UNIQUE INDEX IF NOT EXISTS uq_skills_category_en_name
  ON public.skills (category_id, ((names->>'en')));

-- 2. Update RLS policies to allow SELECT for all users (authenticated and anon)
DROP POLICY IF EXISTS service_categories_select ON public.service_categories;
CREATE POLICY service_categories_select ON public.service_categories
  FOR SELECT USING (true);

DROP POLICY IF EXISTS skills_select ON public.skills;
CREATE POLICY skills_select ON public.skills
  FOR SELECT USING (true);

-- 3. Seed Skills for 12 Service Categories dynamically by slug
DO $$
DECLARE
  v_c_const UUID;
  v_c_plumb UUID;
  v_c_paint UUID;
  v_c_deliv UUID;
  v_c_elec  UUID;
  v_c_carp  UUID;
  v_c_mas   UUID;
  v_c_clean UUID;
  v_c_driv  UUID;
  v_c_dom   UUID;
  v_c_agri  UUID;
  v_c_load  UUID;
BEGIN
  -- Lookup category IDs by slug
  SELECT id INTO v_c_const FROM public.service_categories WHERE slug = 'construction';
  SELECT id INTO v_c_plumb FROM public.service_categories WHERE slug = 'plumbing';
  SELECT id INTO v_c_paint FROM public.service_categories WHERE slug = 'painting';
  SELECT id INTO v_c_deliv FROM public.service_categories WHERE slug = 'delivery';
  SELECT id INTO v_c_elec  FROM public.service_categories WHERE slug = 'electrician';
  SELECT id INTO v_c_carp  FROM public.service_categories WHERE slug = 'carpenter';
  SELECT id INTO v_c_mas   FROM public.service_categories WHERE slug = 'mason';
  SELECT id INTO v_c_clean FROM public.service_categories WHERE slug = 'cleaner';
  SELECT id INTO v_c_driv  FROM public.service_categories WHERE slug = 'driver';
  SELECT id INTO v_c_dom   FROM public.service_categories WHERE slug = 'domestic_help';
  SELECT id INTO v_c_agri  FROM public.service_categories WHERE slug = 'agri_labour';
  SELECT id INTO v_c_load  FROM public.service_categories WHERE slug = 'loader';

  -- 1. CONSTRUCTION
  IF v_c_const IS NOT NULL THEN
    INSERT INTO public.skills (category_id, names) VALUES
      (v_c_const, '{"en":"Concrete Mixing & Pouring", "kn":"ಕಾನ್ಕ್ರೀಟ್ ಮಿಕ್ಸಿಂಗ್ ಮತ್ತು ಹಾಕುವುದು", "hi":"कंक्रीट मिक्सिंग और डालना", "te":"కాంక్రీట్ మిక్సింగ్ & పోయడం", "ta":"காங்கிரீட் கலவை மற்றும் ஊற்றுதல்"}'::jsonb),
      (v_c_const, '{"en":"Bar Bending & Steel Work", "kn":"ಬಾರ್ ಬೆಂಡಿಂಗ್ ಮತ್ತು ಸ್ಟೀಲ್ ಕೆಲಸ", "hi":"बार बेंडिंग और स्टील कार्य", "te":"బార్ బెండింగ్ & స్టీల్ పని", "ta":"கம்பி வளைத்தல் மற்றும் எஃகு வேலை"}'::jsonb),
      (v_c_const, '{"en":"Scaffolding Assembly", "kn":"ಸ್ಕ್ಯಾಫೋಲ್ಡಿಂಗ್ ಜೋಡಣೆ", "hi":"स्कैफोल्डिंग असेंबली", "te":"స్కాఫోల్డింగ్ అసెంబ్లీ", "ta":"சாரம் கட்டுதல்"}'::jsonb),
      (v_c_const, '{"en":"Shuttering & Formwork", "kn":"ಶಟರಿಂಗ್ ಕೆಲಸ", "hi":"शटरिंग कार्य", "te":"షట్టరింగ్ పని", "ta":"செட்டரிங் வேலை"}'::jsonb),
      (v_c_const, '{"en":"Site Helper & Material Handling", "kn":"ಸೈಟ್ ಸಹಾಯಕ ಮತ್ತು ಸಾಮಗ್ರಿ ನಿರ್ವಹಣೆ", "hi":"साइट हेल्पर और सामग्री प्रबंधन", "te":"సైట్ హెల్పర్ & మెటీరియల్ హ్యాండ్లింగ్", "ta":"தள உதவியாளர் மற்றும் பொருள் கையாளுதல்"}'::jsonb),
      (v_c_const, '{"en":"Demolition & Chipping", "kn":"ಡಿಮಾಲಿಷನ್ ಮತ್ತು ಚಿಪ್ಪಿಂಗ್", "hi":"डिमोलिशन और चिपिंग", "te":"కూల్చివేత & చిప్పింగ్", "ta":"இடித்தல் மற்றும் சிப்பிங்"}'::jsonb)
    ON CONFLICT (category_id, ((names->>'en'))) DO NOTHING;
  END IF;

  -- 2. PLUMBING
  IF v_c_plumb IS NOT NULL THEN
    INSERT INTO public.skills (category_id, names) VALUES
      (v_c_plumb, '{"en":"Pipe Fitting & Leak Repair", "kn":"ಪೈಪ್ ಫಿಟ್ಟಿಂಗ್ ಮತ್ತು ಸೋರಿಕೆ ದುರಸ್ತಿ", "hi":"पाइप फिटिंग और रिसाव मरम्मत", "te":"పైప్ ఫిట్టింగ్ & లీకేజ్ రిపేర్", "ta":"குழாய் பொருத்துதல் மற்றும் கசிவு சரிசெய்தல்"}'::jsonb),
      (v_c_plumb, '{"en":"Tap & Mixer Fitting", "kn":"ನಲ್ಲಿ ಮತ್ತು ಮಿಕ್ಸರ್ ಫಿಟ್ಟಿಂಗ್", "hi":"नल और मिक्सर फिटिंग", "te":"టాప్ & మిక్సర్ ఫిట్టింగ్", "ta":"நல் மற்றும் மிக்சர் பொருத்துதல்"}'::jsonb),
      (v_c_plumb, '{"en":"Drainage & Sewage Unclogging", "kn":"ಚರಂಡಿ ಮತ್ತು ಒಳಚರಂಡಿ ಸ್ವಚ್ಛತೆ", "hi":"नाली और सीवेज की सफाई", "te":"డ్రైనేజీ & సీవేజ్ అన్‌క్లాగింగ్", "ta":"கழிவுநீர் அடைப்பு நீக்கம்"}'::jsonb),
      (v_c_plumb, '{"en":"Water Tank Cleaning & Installation", "kn":"ನೀರಿನ ಟ್ಯಾಂಕ್ ಸ್ವಚ್ಛತೆ ಮತ್ತು ಸ್ಥಾಪನೆ", "hi":"पानी की टंकी की सफाई और स्थापना", "te":"వాటర్ ట్యాంಕ್ క్లీనింగ్ & ఇన్‌స్టాలేషన్", "ta":"தண்ணீர் தொட்டி சுத்தம் மற்றும் பொருத்துதல்"}'::jsonb),
      (v_c_plumb, '{"en":"Sanitaryware & Closet Fitting", "kn":"ಸ್ಯಾನಿಟರಿ ಮತ್ತು ಕಮೋಡ್ ಫಿಟ್ಟಿಂಗ್", "hi":"सैनिटरीवेयर और क्लोसेट फिटिंग", "te":"శానిటరీవేర్ & క్లోసెట్ ఫిట్టింగ్", "ta":"சுகாதாரப் பொருட்கள் பொருத்துதல்"}'::jsonb),
      (v_c_plumb, '{"en":"Geyser & Water Heater Plumbing", "kn":"ಗೀಸರ್ ಮತ್ತು ವಾಟರ್ ಹೀಟರ್ ಪ್ಲಂಬಿಂಗ್", "hi":"गीजर और वॉटर हीटर प्लंबिंग", "te":"గీజర్ & వాటర్ హీటర్ ప్లంబింగ్", "ta":"கீசர் மற்றும் நீர் சூடೇற்றி குழாய் வேலை"}'::jsonb)
    ON CONFLICT (category_id, ((names->>'en'))) DO NOTHING;
  END IF;

  -- 3. PAINTING
  IF v_c_paint IS NOT NULL THEN
    INSERT INTO public.skills (category_id, names) VALUES
      (v_c_paint, '{"en":"Interior & Exterior Wall Painting", "kn":"ಒಳಾಂಗಣ ಮತ್ತು ಹೊರಾಂಗಣ ಗೋಡೆ ಪೇಂಟಿಂಗ್", "hi":"आंतरिक और बाहरी दीवार पेंटिंग", "te":"ఇంటీరియర్ & ఎక్స్‌టీరియర్ వాల్ పెయింటింగ్", "ta":"உள் மற்றும் வெளி சுவர் ஓவியம்"}'::jsonb),
      (v_c_paint, '{"en":"Putty Work & Surface Sanding", "kn":"ಪುಟ್ಟಿ ಕೆಲಸ ಮತ್ತು ಸರ್ಫೇಸ್ ಸ್ಯಾಂಡಿಂಗ್", "hi":"पुट्टी कार्य और सतह सैंडिंग", "te":"పుట్టీ పని & ఉపరితల సాండింగ్", "ta":"புட்டி வேலை மற்றும் மேற்பரப்பு தேய்த்தல்"}'::jsonb),
      (v_c_paint, '{"en":"Wood & Metal Polishing", "kn":"ಮರ ಮತ್ತು ಲೋಹ ಪಾಲಿಷ್", "hi":"लकड़ी और धातु पॉलिश", "te":"వుడ్ & మెటల్ పాలిషింగ్", "ta":"மரம் மற்றும் உலோக மெருகூட்டல்"}'::jsonb),
      (v_c_paint, '{"en":"Waterproofing & Leak Coating", "kn":"ವಾಟರ್ ಪ್ರೂಫಿಂಗ್ ಮತ್ತು ಸೋರಿಕೆ ತಡೆ", "hi":"वॉटरप्रूफिंग और रिसाव कोटिंग", "te":"వాటర్‌ప్రೂఫಿంగ్ & లీకేజ్ కోటింగ్", "ta":"நீர்ப்புகாப்பு மற்றும் கசிவு பூச்சு"}'::jsonb),
      (v_c_paint, '{"en":"Texture & Spray Painting", "kn":"ಟೆಕ್ಸ್ಚರ್ ಮತ್ತು ಸ್ಪ್ರೇ ಪೇಂಟಿಂಗ್", "hi":"टेक्सचर और स्प्रे पेंटिंग", "te":"టెక్స్చర్ & స్ಪ್ರೇ పెయింటింగ్", "ta":"அமைப்பியல் மற்றும் தெளிப்பு சாயம்"}'::jsonb),
      (v_c_paint, '{"en":"Enamel & Metal Grill Coating", "kn":"ಎನಾಮೆಲ್ ಮತ್ತು ಗ್ರಿಲ್ ಪೇಂಟಿಂಗ್", "hi":"इनैमल और ग्रिल कोटिंग", "te":"ఎనామెల్ & గ్రిల్ కోటింగ్", "ta":"எனாமல் மற்றும் கிரில் பூச்சு"}'::jsonb)
    ON CONFLICT (category_id, ((names->>'en'))) DO NOTHING;
  END IF;

  -- 4. DELIVERY
  IF v_c_deliv IS NOT NULL THEN
    INSERT INTO public.skills (category_id, names) VALUES
      (v_c_deliv, '{"en":"Two-Wheeler Parcel Delivery", "kn":"ದ್ವಿಚಕ್ರ ವಾಹನ ಪಾರ್ಸಲ್ ಡೆಲಿವರಿ", "hi":"टू-व्हीलर पार्सल डिलीवरी", "te":"టూ-వీలర్ పార్శిల్ డెలివరీ", "ta":"இருசக்கர பார்சல் டெலிவரி"}'::jsonb),
      (v_c_deliv, '{"en":"E-Commerce Package Dispatch", "kn":"ಈ-ಕಾಮರ್ಸ್ ಪ್ಯಾಕೇಜ್ ರವಾನಿ", "hi":"ई-कॉमर्स पैकेज डिस्पैच", "te":"ఈ-కామర్స్ ప్యాకేజ్ డిస్పాచ్", "ta":"மின் வணிக பேக்கேஜ் விநியோகம்"}'::jsonb),
      (v_c_deliv, '{"en":"Food & Grocery Delivery", "kn":"ಆಹಾರ ಮತ್ತು ದಿನಸಿ ಡೆಲಿವರಿ", "hi":"खाद्य और किराना डिलीवरी", "te":"ఆహారం & కిరాణా డెలివరీ", "ta":"உணவு மற்றும் மளிகை டெலிவரி"}'::jsonb),
      (v_c_deliv, '{"en":"Express Courier Handling", "kn":"ಎಕ್ಸ್‌ಪ್ರೆಸ್ ಕೊರಿಯರ್ ನಿರ್ವಹಣೆ", "hi":"एक्सप्रेस कूरियर प्रबंधन", "te":"ఎక్స్‌ప్రెస్ కొరియర్ హ్యాండ్లింగ్", "ta":"விரைவு கூரியர் கையாளுதல்"}'::jsonb),
      (v_c_deliv, '{"en":"Heavy Parcel Loading Delivery", "kn":"ಭಾರಿ ಪಾರ್ಸಲ್ ಲೋಡಿಂಗ್ ಡೆಲಿವರಿ", "hi":"भारी पार्सल लोडिंग डिलीवरी", "te":"హెవీ పార్శిల్ లోడింగ్ డెలివరీ", "ta":"கனரக பார்சல் ஏற்றி விநியோகம்"}'::jsonb)
    ON CONFLICT (category_id, ((names->>'en'))) DO NOTHING;
  END IF;

  -- 5. ELECTRICIAN
  IF v_c_elec IS NOT NULL THEN
    INSERT INTO public.skills (category_id, names) VALUES
      (v_c_elec, '{"en":"House Wiring & Circuit Repair", "kn":"ಮನೆ ವೈರಿಂಗ್ ಮತ್ತು ಸರ್ಕ್ಯೂಟ್ ದುರಸ್ತಿ", "hi":"हाउस वायरिंग और सर्किट मरम्मत", "te":"హౌస్ వైరింగ్ & సర్క్యూట్ రిపేర్", "ta":"வீட்டு வயரிங் மற்றும் சர்க்யூட் சரிசெய்தல்"}'::jsonb),
      (v_c_elec, '{"en":"Switchboard & Socket Fitting", "kn":"ಸ್ವಿಚ್ ಬೋರ್ಡ್ ಮತ್ತು ಸಾಕೆಟ್ ಫಿಟ್ಟಿಂಗ್", "hi":"स्विचबोर्ड और सॉकेट फिटिंग", "te":"స్విచ్‌బోర్డ్ & సాకెట్ ఫిట్టింగ్", "ta":"சுவிட்ச்போர்டு மற்றும் சாக்கெட் பொருத்துதல்"}'::jsonb),
      (v_c_elec, '{"en":"Fan, Light & Appliance Installation", "kn":"ಫ್ಯಾನ್, ಲೈಟ್ ಮತ್ತು ಉಪಕರಣಗಳ ಸ್ಥಾಪನೆ", "hi":"पंखा, लाइट और उपकरण स्थापना", "te":"ఫ్యాన్, లైట్ & ఉపకరణాల ఇన్‌స్టాలేషన్", "ta":"மின்விசிறி, விளக்கு மற்றும் சாதன பொருத்துதல்"}'::jsonb),
      (v_c_elec, '{"en":"Inverter & Battery Wiring", "kn":"ಇನ್ವರ್ಟರ್ ಮತ್ತು ಬ್ಯಾಟರಿ ವೈರಿಂಗ್", "hi":"इन्वर्टर और बैटरी वायरिंग", "te":"ఇన్వర్టర్ & బ్యాటరీ వైರಿಂಗ್", "ta":"இன்வெர்ட்டர் மற்றும் பேட்டரி வயரிங்"}'::jsonb),
      (v_c_elec, '{"en":"MCB & Fuse DB Box Fitting", "kn":"ಎಂಸಿಬಿ ಮತ್ತು ಫ್ಯೂಸ್ ಬಾಕ್ಸ್ ಫಿಟ್ಟಿಂಗ್", "hi":"एमसीबी और फ्यूज बॉक्स फिटिंग", "te":"MCB & ఫ్యూజ్ బాಕ್ಸ್ ఫిట్టిಂಗ್", "ta":"MCB மற்றும் ஃப்யூஸ் பாக்ಸ್ பொருத்துதல்"}'::jsonb),
      (v_c_elec, '{"en":"Commercial Cable Laying", "kn":"ವಾಣಿಜ್ಯ ಕೇಬಲ್ ಅಳವಡಿಕೆ", "hi":"कमर्शियल केबल बिछाना", "te":"కమర్షియల్ కేబుల్ లేయింగ్", "ta":"வணிக கேபிள் அமைத்தல்"}'::jsonb)
    ON CONFLICT (category_id, ((names->>'en'))) DO NOTHING;
  END IF;

  -- 6. CARPENTER
  IF v_c_carp IS NOT NULL THEN
    INSERT INTO public.skills (category_id, names) VALUES
      (v_c_carp, '{"en":"Furniture Repair & Assembly", "kn":"ಪೀಠೋಪಕರಣಗಳ ದುರಸ್ತಿ ಮತ್ತು ಜೋಡಣೆ", "hi":"फर्नीचर मरम्मत और असेंबली", "te":"ఫర్నిచర్ రిపేర్ & అసెంబ్లీ", "ta":"மரச்சாமான்கள் சரிசெய்தல் மற்றும் பொருத்துதல்"}'::jsonb),
      (v_c_carp, '{"en":"Door & Window Frame Fitting", "kn":"ಬಾಗಿಲು ಮತ್ತು ಕಿಟಕಿ ಚೌಕಟ್ಟು ಫಿಟ್ಟಿಂಗ್", "hi":"दरवाजा और खिड़की फ्रेम फिटिंग", "te":"డోర్ & విండో ఫ్రేమ్ ఫిట్టింగ్", "ta":"கதவு மற்றும் ஜன்னல் சட்ட பொருத்துதல்"}'::jsonb),
      (v_c_carp, '{"en":"Modular Kitchen & Cabinetry", "kn":"ಮಾಡ್ಯುಲರ್ ಕಿಚನ್ ಮತ್ತು ಕ್ಯಾಬಿನೆಟ್ ಕೆಲಸ", "hi":"मॉड्यूलर किचन और अलमारी कार्य", "te":"మోడ్యులర్ కిచెన్ & క్యాబినెట్రీ", "ta":"மாடுலர் சமையலறை மற்றும் அலமாரி வேலை"}'::jsonb),
      (v_c_carp, '{"en":"Lock, Latch & Hinge Fitting", "kn":"ಲಾಕ್, ಲ್ಯಾಚ್ ಮತ್ತು ಹಿಂಜ್ ಫಿಟ್ಟಿಂಗ್", "hi":"लॉक, कुंडी और कब्जा फिटिंग", "te":"లాక్, లాచ్ & హింజ్ ఫిట్టింగ్", "ta":"பூட்டு, தாழ்ப்பாள் மற்றும் கீல் பொருத்துதல்"}'::jsonb),
      (v_c_carp, '{"en":"Wooden Flooring & Shelving", "kn":"ಮರದ ಫ್ಲೋರಿಂಗ್ ಮತ್ತು ರ್ಯಾಕ್ ಕೆಲಸ", "hi":"लकड़ी का फर्श और शेल्विंग", "te":"వుడెన్ ఫ్లోరింగ్ & షెల్వింగ్", "ta":"மரத் தரை மற்றும் அலமாரி அமைத்தல்"}'::jsonb)
    ON CONFLICT (category_id, ((names->>'en'))) DO NOTHING;
  END IF;

  -- 7. MASON
  IF v_c_mas IS NOT NULL THEN
    INSERT INTO public.skills (category_id, names) VALUES
      (v_c_mas, '{"en":"Brickwork & Block Laying", "kn":"ಇಟ್ಟಿಗೆ ಮತ್ತು ಬ್ಲಾಕ್ ನಿರ್ಮಾಣ", "hi":"ईंट और ब्लॉक चिनाई", "te":"ఇటుక & బ్లాక్ పని", "ta":"செங்கல் மற்றும் பிளாக் கட்டுதல்"}'::jsonb),
      (v_c_mas, '{"en":"Wall Plastering & Smooth Finishing", "kn":"ಗೋಡೆ ಪ್ಲಾಸ್ಟರಿಂಗ್ ಮತ್ತು ಫಿನಿಷಿಂಗ್", "hi":"दीवार प्लास्टर और फिनिशिंग", "te":"గోడ ప్లాస్టరింగ్ & ఫినిషింగ్", "ta":"சுவர் பூச்சு மற்றும் மெருகூட்டல்"}'::jsonb),
      (v_c_mas, '{"en":"Floor Tiling & Granite Fitting", "kn":"ಫ್ಲೋರ್ ಟೈಲಿಂಗ್ ಮತ್ತು ಗ್ರಾನೈಟ್ ಫಿಟ್ಟಿಂಗ್", "hi":"फ्लोर टाइलिंग और ग्रेनाइट फिटिंग", "te":"ఫ్లోర్ టైలింగ్ & గ్రానైಟ್ ఫిట్టింగ్", "ta":"தரை டைல்ஸ் மற்றும் கிரானைட் பொருத்துதல்"}'::jsonb),
      (v_c_mas, '{"en":"Concrete Footing & Pillar Work", "kn":"ಕಾನ್ಕ್ರೀಟ್ ಫುಟಿಂಗ್ ಮತ್ತು ಪಿಲ್ಲರ್ ಕೆಲಸ", "hi":"कंक्रीट फुटिंग और पिलर कार्य", "te":"కాంక్రీట్ ఫుటింగ్ & పిల్లర్ పని", "ta":"காங்கிரீட் அஸ்திவாரம் மற்றும் தூண் வேலை"}'::jsonb),
      (v_c_mas, '{"en":"Compound Wall Construction", "kn":"ಕಾಂಪೌಂಡ್ ಗೋಡೆ ನಿರ್ಮಾಣ", "hi":"कंपाउंड वॉल निर्माण", "te":"కాంపౌండ్ వాల్ నిర్మాణం", "ta":"காம்பவுண்ட் சுவர் கட்டுதல்"}'::jsonb)
    ON CONFLICT (category_id, ((names->>'en'))) DO NOTHING;
  END IF;

  -- 8. CLEANER
  IF v_c_clean IS NOT NULL THEN
    INSERT INTO public.skills (category_id, names) VALUES
      (v_c_clean, '{"en":"Deep Home & Room Cleaning", "kn":"ಮನೆ ಮತ್ತು ಕೊಠಡಿಗಳ ಆಳವಾದ ಸ್ವಚ್ಛತೆ", "hi":"घर और कमरे की गहरी सफाई", "te":"డీప్ హోమ్ & రూమ్ క్లీనింగ్", "ta":"ஆழ்ந்த வீடு மற்றும் அறை சுத்தம்"}'::jsonb),
      (v_c_clean, '{"en":"Bathroom & Toilet Scrubbing", "kn":"ಬಾತ್‌ರೂಮ್ ಮತ್ತು ಶೌಚಾಲಯ ಸ್ವಚ್ಛತೆ", "hi":"बाथरूम और शौचालय की सफाई", "te":"బాత్‌రూమ్ & టాయిలెట్ స్క్రబ్బಿಂಗ್", "ta":"குளியலறை மற்றும் கழிப்பறை சுத்தம்"}'::jsonb),
      (v_c_clean, '{"en":"Sofa, Carpet & Mattress Washing", "kn":"ಸೋಫಾ, ಕಾರ್ಪೆಟ್ ಮತ್ತು ಹಾಸಿಗೆ ತೊಳೆಯುವುದು", "hi":"सोफा, कालीन और गद्दे की सफाई", "te":"సోఫా, కార్పెట్ & పరుపుల వాషింగ్", "ta":"சோஃபா, கார்பெட் மற்றும் மெத்தை சுத்தம்"}'::jsonb),
      (v_c_clean, '{"en":"Water Tank & Sump Cleaning", "kn":"ವಾಟರ್ ಟ್ಯಾಂಕ್ ಮತ್ತು ಸಂಪಿನ ಸ್ವಚ್ಛತೆ", "hi":"पानी की टंकी और सम्प की सफाई", "te":"వాటర్ ట్యాంಕ್ & సంప్ క్లీనిಂಗ್", "ta":"தண்ணீர் தொட்டி மற்றும் சம்ப் சுத்தம்"}'::jsonb),
      (v_c_clean, '{"en":"Post-Construction Debris Cleaning", "kn":"ನಿರ್ಮಾಣ ನಂತರದ ಕಸ ಸ್ವಚ್ಛತೆ", "hi":"निर्माण के बाद का मलबा सफाई", "te":"నిర్మాణ అనంతర వ్యర్థాల క్లీనిಂಗ್", "ta":"கட்டுமானத்திற்கு பிந்தைய கழிவு சுத்தம்"}'::jsonb)
    ON CONFLICT (category_id, ((names->>'en'))) DO NOTHING;
  END IF;

  -- 9. DRIVER
  IF v_c_driv IS NOT NULL THEN
    INSERT INTO public.skills (category_id, names) VALUES
      (v_c_driv, '{"en":"LMV Personal Car Driver", "kn":"ಖಾಸಗಿ ಕಾರು ಚಾಲಕ (LMV)", "hi":"एलएमवी पर्सनल कार ड्राइवर", "te":"LMV వ్యక్తిగత కార్ డ్రైవర్", "ta":"சொந்த கார் ஓட்டுநர் (LMV)"}'::jsonb),
      (v_c_driv, '{"en":"Commercial Van & Goods Driver", "kn":"ವಾಣಿಜ್ಯ ವ್ಯಾನ್ ಮತ್ತು ಸರಕು ವಾಹನ ಚಾಲಕ", "hi":"कमर्शियल वैन और सामान वाहन ड्राइवर", "te":"కమర్షియల్ వ్యాన్ & గూడ్స్ డ్రైవర్", "ta":"வணிக வேன் மற்றும் சரக்கு வாகன ஓட்டுநர்"}'::jsonb),
      (v_c_driv, '{"en":"Night & Outstation Driving", "kn":"ರಾತ್ರಿ ಮತ್ತು ಹೊರಊರು ಚಾಲನೆ", "hi":"नाइट और आउटस्टेशन ड्राइविंग", "te":"నైట్ & అవుట్‌స్టేషన్ డ్రైవింగ్", "ta":"இரவு மற்றும் வெளியூர் பயணம்"}'::jsonb),
      (v_c_driv, '{"en":"Automatic & Valet Car Driving", "kn":"ಆಟೋಮ್ಯಾಟಿಕ್ ಕಾರು ಮತ್ತು ವ್ಯಾಲೆಟ್ ಚಾಲನೆ", "hi":"ऑटोमैटिक और वैले कार ड्राइविंग", "te":"ఆటోమేటిక్ & వాలెಟ್ కార్ డ్రైవిಂಗ್", "ta":"தானியங்கி கார் ஓட்டுநர்"}'::jsonb),
      (v_c_driv, '{"en":"Heavy Goods Vehicle Driving", "kn":"ಭಾರಿ ಸರಕು ವಾಹನ ಚಾಲನೆ", "hi":"भारी सामान वाहन ड्राइविंग", "te":"హెవీ గూడ్స్ వెహికల్ డ్రైవింగ్", "ta":"கனரக சரக்கு வாகன ஓட்டுநர்"}'::jsonb)
    ON CONFLICT (category_id, ((names->>'en'))) DO NOTHING;
  END IF;

  -- 10. DOMESTIC HELP
  IF v_c_dom IS NOT NULL THEN
    INSERT INTO public.skills (category_id, names) VALUES
      (v_c_dom, '{"en":"House Sweeping & Mopping", "kn":"ಮನೆ ಕಸ ಗುಡಿಸುವುದು ಮತ್ತು ಒರೆಸುವುದು", "hi":"घर की झाड़ू-पोंछा", "te":"ఇల్లు తుడవడం & మోపింగ్", "ta":"வீடு கூட்டுதல் மற்றும் துடைத்தல்"}'::jsonb),
      (v_c_dom, '{"en":"Vessel & Utensil Washing", "kn":"ಪಾತ್ರೆ ತೊಳೆಯುವ ಕೆಲಸ", "hi":"बर्तन धोना", "te":"పాత్రలు కడగడం", "ta":"பாத்திரம் கழுவுதல்"}'::jsonb),
      (v_c_dom, '{"en":"Laundry & Clothes Ironing", "kn":"ಬಟ್ಟೆ ತೊಳೆಯುವುದು ಮತ್ತು ಐರನ್ ಮಾಡುವುದು", "hi":"कपड़े धोना और इस्त्री करना", "te":"లాండ్రీ & దుస్తుల ఐరనింగ్", "ta":"துணி துவைத்தல் மற்றும் அயர்ன் செய்தல்"}'::jsonb),
      (v_c_dom, '{"en":"Home Cooking & Meal Prep", "kn":"ಮನೆ ಅಡುಗೆ ಮತ್ತು ಆಹಾರ ತಯಾರಿ", "hi":"घर का खाना बनाना", "te":"వంట వండడం & భోజన తయారీ", "ta":"வீட்டு சமையல்"}'::jsonb),
      (v_c_dom, '{"en":"Elderly & Patient Care", "kn":"ಹಿರಿಯರ ಮತ್ತು ರೋಗಿಗಳ ಆರೈಕೆ", "hi":"बुजुर्गों और मरीजों की देखभाल", "te":"వృద్ధులు & రోగుల సంరక్షణ", "ta":"முதியோர் ಮತ್ತು ನೋಯಾಳಿ பராமரிப்பு"}'::jsonb),
      (v_c_dom, '{"en":"Childcare & Babysitting", "kn":"ಮಕ್ಕಳ ಆರೈಕೆ ಮತ್ತು ಬೇಬಿ ಸಿಟ್ಟಿಂಗ್", "hi":"बच्चों की देखभाल", "te":"పిల్లల సంరక్షణ", "ta":"குழந்தை பராமரிப்பு"}'::jsonb)
    ON CONFLICT (category_id, ((names->>'en'))) DO NOTHING;
  END IF;

  -- 11. AGRI LABOUR
  IF v_c_agri IS NOT NULL THEN
    INSERT INTO public.skills (category_id, names) VALUES
      (v_c_agri, '{"en":"Crop Sowing & Transplanting", "kn":"ಬೆಳೆ ಬಿತ್ತನೆ ಮತ್ತು ನಾಟಿ", "hi":"फसल बुआई और रोपाई", "te":"పంట విత్తడం & నాట్లు వేయడం", "ta":"பயிர் விதைப்பு மற்றும் நடுதல்"}'::jsonb),
      (v_c_agri, '{"en":"Weeding & De-trashing", "kn":"ಕಳೆ ತೆಗೆಯುವುದು", "hi":"निराई और गुड़ाई", "te":"కలుపు తీయడం", "ta":"களை எடுத்தல்"}'::jsonb),
      (v_c_agri, '{"en":"Crop Harvesting & Threshing", "kn":"ಬೆಳೆ ಕೊಯ್ಲು ಮತ್ತು ಒಕ್ಕಣೆ", "hi":"फसल कटाई और गहाई", "te":"పంట కోత & నూర్పిడి", "ta":"பயிರ್ அறுவடை மற்றும் தூற்றுதல்"}'::jsonb),
      (v_c_agri, '{"en":"Pesticide & Fertilizer Spraying", "kn":"ಕೀಟನಾಶಕ ಮತ್ತು ರಸಗೊಬ್ಬರ ಸಿಂಪಡಣೆ", "hi":"कीटनाशक और उर्वरक छिड़काव", "te":"పెస్టిసైడ్ & ఎరువుల పిచಿಕారీ", "ta":"பூச்சிக்கொல்லி தெளித்தல்"}'::jsonb),
      (v_c_agri, '{"en":"Drip Irrigation & Canal Work", "kn":"ಹನಿ ನೀರಾವರಿ ಮತ್ತು ಕಾಲುವೆ ಕೆಲಸ", "hi":"ड्रिप सिंचाई और नहर कार्य", "te":"డ్రిప్ ఇరిగేషన్ & కాలువ పని", "ta":"சொட்டு நீர் பாசனம்"}'::jsonb),
      (v_c_agri, '{"en":"Farm Fencing & Land Prep", "kn":"ಜಮೀನು ಬೇಲಿ ಮತ್ತು ಭೂಮಿ ಸಿದ್ಧತೆ", "hi":"खेत की बाड़ और भूमि तैयारी", "te":"ఫామ్ ఫెన్సింగ్ & భూమి తయారీ", "ta":"வேலி அமைத்தல் மற்றும் நில ஆயத்தம்"}'::jsonb)
    ON CONFLICT (category_id, ((names->>'en'))) DO NOTHING;
  END IF;

  -- 12. LOADER
  IF v_c_load IS NOT NULL THEN
    INSERT INTO public.skills (category_id, names) VALUES
      (v_c_load, '{"en":"Heavy Cargo Loading & Unloading", "kn":"ಭಾರಿ ಸರಕು ಲೋಡಿಂಗ್ ಮತ್ತು ಅನ್‌ಲೋಡಿಂಗ್", "hi":"भारी सामान लोडिंग और अनलोडिंग", "te":"హెవీ కార్గో లోడింగ్ & అన్‌లోడింగ్", "ta":"கனரக சரக்கு ஏற்றுதல் மற்றும் இறக்குதல்"}'::jsonb),
      (v_c_load, '{"en":"Warehouse Stacking & Sorting", "kn":"ವೇರ್‌ಹೌಸ್ ಸರಕು ವಿಂಗಡಣೆ ಮತ್ತು ಜೋಡಣೆ", "hi":"गोदाम स्टैकिंग और छंटाई", "te":"వేర్‌హೌస్ స్టాకింగ్ & సార్టింగ్", "ta":"கிடங்கு அடுக்குதல்"}'::jsonb),
      (v_c_load, '{"en":"Furniture Shifting & Moving", "kn":"ಪೀಠೋಪಕರಣಗಳ ಸ್ಥಳಾಂತರ", "hi":"फर्नीचर शिफ्टिंग और मूवेबल कार्य", "te":"ఫర్నిచర్ షిఫ్టింగ్ & మూవింగ్", "ta":"மரச்சாமான்கள் நகர்த்துதல்"}'::jsonb),
      (v_c_load, '{"en":"Truck Loading & Lashing", "kn":"ಟ್ರಕ್ ಲೋಡಿಂಗ್ ಮತ್ತು ಕಟ್ಟುವುದು", "hi":"ट्रक लोडिंग और लैशिंग", "te":"ట్రక్ లోడింగ్ & ల్యాషింగ్", "ta":"லாரி ஏற்றி கட்டுதல்"}'::jsonb),
      (v_c_load, '{"en":"Construction Material Lifting", "kn":"ನಿರ್ಮಾಣ ಸಾಮಗ್ರಿ ಎತ್ತುವ ಕೆಲಸ", "hi":"निर्माण सामग्री लिफ्टिंग", "te":"కన్స్ట్రక్షన్ మెటీరియల్ లిఫ్టింగ్", "ta":"கட்டுமானப் பொருள் தூக்குதல்"}'::jsonb)
    ON CONFLICT (category_id, ((names->>'en'))) DO NOTHING;
  END IF;

END $$;

-- 4. Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
