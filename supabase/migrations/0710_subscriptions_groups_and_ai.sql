-- Migration: 0710_subscriptions_groups_and_ai.sql
-- Description: P6.7 Subscriptions & Group Orders + P6.8 Government Schemes & Scheduler

-- ============================================================================
-- 1. ENHANCE SUBSCRIPTIONS TABLE
-- ============================================================================
ALTER TABLE public.subscriptions
  ADD COLUMN IF NOT EXISTS delivery_slot_time TEXT DEFAULT '07:00 AM',
  ADD COLUMN IF NOT EXISTS doorstep_address TEXT,
  ADD COLUMN IF NOT EXISTS unit_price_paise BIGINT DEFAULT 0 CHECK (unit_price_paise >= 0),
  ADD COLUMN IF NOT EXISTS listing_name TEXT,
  ADD COLUMN IF NOT EXISTS farmer_name TEXT;

ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS delivery_date DATE;

-- Index for scheduler query
CREATE INDEX IF NOT EXISTS idx_subscriptions_active_next_date
  ON public.subscriptions(status, next_delivery_date)
  WHERE status = 'active';

-- ============================================================================
-- 2. CURATED GOVERNMENT SCHEMES TABLE (P6.8)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.government_schemes (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,
  name_en TEXT NOT NULL,
  name_kn TEXT NOT NULL,
  name_hi TEXT NOT NULL,
  name_te TEXT NOT NULL,
  name_ta TEXT NOT NULL,
  short_description_en TEXT NOT NULL,
  short_description_kn TEXT NOT NULL,
  short_description_hi TEXT NOT NULL,
  short_description_te TEXT NOT NULL,
  short_description_ta TEXT NOT NULL,
  official_url TEXT NOT NULL,
  category TEXT NOT NULL, -- income_support, credit, insurance, soil, irrigation
  benefits_summary TEXT NOT NULL,
  documents_required TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.government_schemes ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'government_schemes' AND policyname = 'government_schemes_public_read'
  ) THEN
    CREATE POLICY government_schemes_public_read
      ON public.government_schemes FOR SELECT
      USING (true);
  END IF;
END $$;

-- Seed curated official government schemes with neutral descriptions and official URLs
INSERT INTO public.government_schemes (
  slug, name_en, name_kn, name_hi, name_te, name_ta,
  short_description_en, short_description_kn, short_description_hi, short_description_te, short_description_ta,
  official_url, category, benefits_summary, documents_required
) VALUES
(
  'pm_kisan',
  'PM-KISAN (Pradhan Mantri Kisan Samman Nidhi)',
  'ಪಿಎಂ-ಕಿಸಾನ್ (ಪ್ರಧಾನ ಮಂತ್ರಿ ಕಿಸಾನ್ ಸಮ್ಮಾನ್ ನಿಧಿ)',
  'पीएम-किसान (प्रधानमंत्री किसान सम्मान निधि)',
  'పీఎం-కిసాన్ (ప్రధాన మంత్రి కిసాన్ సమ్మాన్ నిధి)',
  'பிஎம்-கிசான் (பிரதான் மந்திரி கிசான் சம்மான் நிதி)',
  'Direct income support of Rs 6,000 per year in three equal installments to eligible landholding farmer families.',
  'ಅರ್ಹ ಭೂಮಾಲೀಕ ರೈತ ಕುಟುಂಬಗಳಿಗೆ ವರ್ಷಕ್ಕೆ 6,000 ರೂ. ನೇರ ಆದಾಯ ಬೆಂಬಲ.',
  'पात्र भूमिधारक किसान परिवारों को प्रति वर्ष 6,000 रुपये की प्रत्यक्ष आय सहायता।',
  'అర్హులైన రైతు కుటుంబాలకు సంవత్సరానికి రూ. 6,000 ప్రత్యక్ష ఆదాయ సహాయం.',
  'தகுதியுள்ள விவசாய குடும்பங்களுக்கு ஆண்டுக்கு ரூ. 6,000 நேரடி வருமான ஆதரவு.',
  'https://pmkisan.gov.in',
  'income_support',
  'Rs 6,000 / year deposited directly into bank accounts via DBT.',
  ARRAY['Aadhaar Card', 'Land Record (RTC / Pahani)', 'Bank Account details (Aadhaar linked)']
),
(
  'kisan_credit_card',
  'Kisan Credit Card (KCC) Scheme',
  'ಕಿಸಾನ್ ಕ್ರೆಡಿಟ್ ಕಾರ್ಡ್ (ಕೆಸಿಸಿ) ಯೋಜನೆ',
  'किसान क्रेडिट कार्ड (केसीसी) योजना',
  'కిసాన్ క్రెడిట్ కార్డ్ (కేసీసీ) పథకం',
  'கிசான் கிரெடிட் கார்டு (கேசிசி) திட்டம்',
  'Timely access to affordable short-term institutional credit for cultivation, crop loans, and post-harvest expenses.',
  'ಕೃಷಿ ವೆಚ್ಚಗಳು ಮತ್ತು ಬೆಳೆ ಸಾಲಗಳಿಗಾಗಿ ಕೈಗೆಟುಕುವ ಅಲ್ಪಾವಧಿ ಸಾಲ ಸೌಲಭ್ಯ.',
  'खेती, फसल ऋण और फसल कटाई के बाद के खर्चों के लिए समय पर सस्ता संस्थागत ऋण।',
  'సాగు ఖర్చులు మరియు పంట రుణాల కోసం సరసమైన స్వల్పకాలిక రుణం.',
  'பயிர் சாகுபடி மற்றும் அறுவடை செலவுகளுக்கான மலிவு கடன் வசதி.',
  'https://agricoop.gov.in',
  'credit',
  'Concessional crop loans up to Rs 3 Lakh at 4% effective interest rate with prompt repayment.',
  ARRAY['Aadhaar Card', 'PAN Card or Form 60', 'Land Records / RTC', 'Passport photo']
),
(
  'pm_fasal_bima',
  'Pradhan Mantri Fasal Bima Yojana (PMFBY)',
  'ಪ್ರಧಾನ ಮಂತ್ರಿ ಫಸಲ್ ಬಿಮಾ ಯೋಜನೆ (ಪಿಎಂಎಫ್‌ಬಿವೈ)',
  'प्रधानमंत्री फसल बीमा योजना (पीएमएफबीवाई)',
  'ప్రధాన మంత్రి ఫసల్ బీమా యోజన (పీఎంఎఫ్‌బీవై)',
  'பிரதான் மந்திரி பயிர் காப்பீட்டுத் திட்டம் (பிஎம்எஃப்பிஒய்)',
  'Comprehensive crop insurance against non-preventable natural risks from pre-sowing to post-harvest.',
  'ನೈಸರ್ಗಿಕ ವಿಕೋಪಗಳಿಂದ ಉಂಟಾಗುವ ಬೆಳೆ ಹಾನಿಗೆ ಸಮಗ್ರ ವಿಮಾ ರಕ್ಷಣೆ.',
  'बुआई से लेकर कटाई के बाद तक प्राकृतिक जोखिमों से व्यापक फसल बीमा सुरक्षा।',
  'ప్రకృతి వైపరీత్యాల వల్ల పంట నష్టానికి సమగ్ర బీమా రక్షణ.',
  'இயற்கை இடர்பாடுகளால் ஏற்படும் பயிர் சேதத்திற்கு விரிவான காப்பீட்டு பாதுகாப்பு.',
  'https://pmfby.gov.in',
  'insurance',
  'Low premium: 2% for Kharif crops, 1.5% for Rabi crops, and 5% for commercial/horticultural crops.',
  ARRAY['Aadhaar Card', 'Land Title / Tenancy Agreement', 'Sowing Certificate', 'Bank Passbook']
),
(
  'soil_health_card',
  'Soil Health Card Scheme',
  'ಮಣ್ಣು ಆರೋಗ್ಯ ಕಾರ್ಡ್ ಯೋಜನೆ',
  'मृदा स्वास्थ्य कार्ड योजना',
  'నేల ఆరోగ్య కార్డు పథకం',
  'மண் ஆரோக்கிய அட்டை திட்டம்',
  'Government issued status card on 12 nutrient parameters of soil with customized fertilizer dosage recommendations.',
  'ಮಣ್ಣಿನ ಪೋಷಕಾಂಶಗಳ ಸ್ಥಿತಿ ಮತ್ತು ಸೂಕ್ತ ಗೊಬ್ಬರ ಬಳಕೆಯ ಶಿಫಾರಸು ಪತ್ರ.',
  'मिट्टी के 12 पोषक तत्वों की स्थिति और उपयुक्त उर्वरक खुराक की आधिकारिक रिपोर्ट।',
  'నేల పోషకాల వివరాలు మరియు తగిన ఎరువుల వాడకం సూచనలు.',
  'மண் ஊட்டச்சத்து நிலை மற்றும் உர பயன்பாட்டு பரிந்துரைகள் கொண்ட அட்டை.',
  'https://soilhealth.dac.gov.in',
  'soil',
  'Free soil sampling and scientific nutrient management advice issued every 3 years.',
  ARRAY['Aadhaar Card', 'Land Survey Number / RTC']
),
(
  'krishi_bhagya',
  'Karnataka Krishi Bhagya Scheme',
  'ಕರ್ನಾಟಕ ಕೃಷಿ ಭಾಗ್ಯ ಯೋಜನೆ',
  'कर्नाटक कृषि भाग्य योजना',
  'కర్ణాటక కృషి భాగ్య పథకం',
  'கர்நாடகா கிருஷி பாக்யா திட்டம்',
  'Rainwater harvesting, farm ponds (Krishi Honda), polythene lining, and micro-irrigation subsidies for dryland farmers.',
  'ಮಳೆನೀರು ಕೊಯ್ಲು, ಕೃಷಿ ಹೊಂಡ, ಪಾಲಿಥೀನ್ ಹೊದಿಕೆ ಮತ್ತು ಹನಿ ನೀರಾವರಿ ಸಬ್ಸಿಡಿ ಯೋಜನೆ.',
  'वर्षा जल संचयन, खेत तालाब (कृषि होंडा) और ड्रिप सिंचाई के लिए राज्य सब्सिडी।',
  'వర్షపు నీటి నిల్వ, వ్యవసాయ కుంటలు మరియు సూక్ష్మ సేద్య సబ్సిడీ.',
  'மழைநீர் சேகரிப்பு, பண்ணைக் குட்டை மற்றும் நுண்ணீர் பாசன மானியம்.',
  'https://raitamitra.karnataka.gov.in',
  'irrigation',
  'Up to 80-90% subsidy for construction of farm ponds and micro-irrigation equipment in rainfed areas.',
  ARRAY['Aadhaar Card', 'Karnataka RTC / Pahani', 'Bank Account Passbook', 'Caste Certificate (if applicable)']
)
ON CONFLICT (slug) DO UPDATE SET
  official_url = EXCLUDED.official_url,
  benefits_summary = EXCLUDED.benefits_summary,
  documents_required = EXCLUDED.documents_required;

-- ============================================================================
-- 3. SUBSCRIPTIONS RPCs
-- ============================================================================

-- A. Create Produce Subscription
CREATE OR REPLACE FUNCTION public.create_produce_subscription(
  p_listing_id UUID,
  p_quantity NUMERIC,
  p_frequency TEXT,
  p_delivery_slot_time TEXT DEFAULT '07:00 AM',
  p_doorstep_address TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_listing RECORD;
  v_farmer_name TEXT;
  v_sub_id UUID;
  v_next_date DATE;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
  END IF;

  IF p_quantity <= 0 THEN
    RAISE EXCEPTION 'Quantity must be greater than zero' USING ERRCODE = '22003';
  END IF;

  SELECT pl.*, p.full_name AS farmer_full_name
  INTO v_listing
  FROM public.produce_listings pl
  JOIN public.profiles p ON p.id = pl.farmer_id
  WHERE pl.id = p_listing_id AND pl.status = 'active';

  IF v_listing IS NULL THEN
    RAISE EXCEPTION 'Produce listing not found or inactive' USING ERRCODE = 'P0002';
  END IF;

  -- Default next delivery date is tomorrow
  v_next_date := CURRENT_DATE + 1;

  INSERT INTO public.subscriptions (
    customer_id,
    farmer_id,
    listing_id,
    quantity,
    frequency,
    status,
    next_delivery_date,
    delivery_slot_time,
    doorstep_address,
    unit_price_paise,
    listing_name,
    farmer_name,
    skip_dates
  ) VALUES (
    v_user_id,
    v_listing.farmer_id,
    p_listing_id,
    p_quantity,
    p_frequency,
    'active',
    v_next_date,
    COALESCE(p_delivery_slot_time, '07:00 AM'),
    p_doorstep_address,
    v_listing.price_paise,
    v_listing.name,
    COALESCE(v_listing.farmer_full_name, 'Verified Local Farmer'),
    '{}'
  ) RETURNING id INTO v_sub_id;

  RETURN jsonb_build_object(
    'ok', true,
    'subscription_id', v_sub_id,
    'next_delivery_date', v_next_date,
    'frequency', p_frequency,
    'quantity', p_quantity
  );
END;
$$;

-- B. Get User Subscriptions
CREATE OR REPLACE FUNCTION public.get_user_subscriptions()
RETURNS TABLE (
  id UUID,
  customer_id UUID,
  farmer_id UUID,
  listing_id UUID,
  quantity NUMERIC,
  frequency TEXT,
  status public.subscription_status,
  next_delivery_date DATE,
  skip_dates DATE[],
  delivery_slot_time TEXT,
  doorstep_address TEXT,
  unit_price_paise BIGINT,
  listing_name TEXT,
  farmer_name TEXT,
  created_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    s.id,
    s.customer_id,
    s.farmer_id,
    s.listing_id,
    s.quantity,
    s.frequency,
    s.status,
    s.next_delivery_date,
    s.skip_dates,
    s.delivery_slot_time,
    s.doorstep_address,
    s.unit_price_paise,
    s.listing_name,
    s.farmer_name,
    s.created_at
  FROM public.subscriptions s
  WHERE s.customer_id = auth.uid() OR public.is_admin()
  ORDER BY s.created_at DESC;
$$;

-- C. Update Subscription Status (Pause / Resume / Cancel)
CREATE OR REPLACE FUNCTION public.update_subscription_status(
  p_subscription_id UUID,
  p_status public.subscription_status
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_sub RECORD;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_sub
  FROM public.subscriptions
  WHERE id = p_subscription_id AND (customer_id = v_user_id OR public.is_admin());

  IF v_sub IS NULL THEN
    RAISE EXCEPTION 'Subscription not found' USING ERRCODE = 'P0002';
  END IF;

  UPDATE public.subscriptions
  SET status = p_status,
      updated_at = NOW()
  WHERE id = p_subscription_id;

  RETURN jsonb_build_object(
    'ok', true,
    'subscription_id', p_subscription_id,
    'status', p_status
  );
END;
$$;

-- D. Skip Subscription Delivery Date
CREATE OR REPLACE FUNCTION public.skip_subscription_delivery_date(
  p_subscription_id UUID,
  p_skip_date DATE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_sub RECORD;
  v_dates DATE[];
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_sub
  FROM public.subscriptions
  WHERE id = p_subscription_id AND (customer_id = v_user_id OR public.is_admin());

  IF v_sub IS NULL THEN
    RAISE EXCEPTION 'Subscription not found' USING ERRCODE = 'P0002';
  END IF;

  v_dates := COALESCE(v_sub.skip_dates, '{}');
  IF NOT (p_skip_date = ANY(v_dates)) THEN
    v_dates := array_append(v_dates, p_skip_date);
  END IF;

  UPDATE public.subscriptions
  SET skip_dates = v_dates,
      updated_at = NOW()
  WHERE id = p_subscription_id;

  RETURN jsonb_build_object(
    'ok', true,
    'subscription_id', p_subscription_id,
    'skip_dates', v_dates
  );
END;
$$;

-- E. Update Subscription Quantity
CREATE OR REPLACE FUNCTION public.update_subscription_quantity(
  p_subscription_id UUID,
  p_quantity NUMERIC
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_sub RECORD;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
  END IF;

  IF p_quantity <= 0 THEN
    RAISE EXCEPTION 'Quantity must be greater than zero' USING ERRCODE = '22003';
  END IF;

  SELECT * INTO v_sub
  FROM public.subscriptions
  WHERE id = p_subscription_id AND (customer_id = v_user_id OR public.is_admin());

  IF v_sub IS NULL THEN
    RAISE EXCEPTION 'Subscription not found' USING ERRCODE = 'P0002';
  END IF;

  UPDATE public.subscriptions
  SET quantity = p_quantity,
      updated_at = NOW()
  WHERE id = p_subscription_id;

  RETURN jsonb_build_object(
    'ok', true,
    'subscription_id', p_subscription_id,
    'quantity', p_quantity
  );
END;
$$;

-- ============================================================================
-- 4. ORDER GENERATOR SCHEDULER RPC (P6.7)
-- ============================================================================
-- Creates tomorrow's orders from active subscriptions & recurring bookings
CREATE OR REPLACE FUNCTION public.generate_tomorrow_deliveries(
  p_target_date DATE DEFAULT (CURRENT_DATE + 1)
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_sub RECORD;
  v_listing RECORD;
  v_day_of_week INT; -- 1 = Monday .. 7 = Sunday
  v_should_deliver BOOLEAN;
  v_order_id UUID;
  v_order_code TEXT;
  v_total_paise BIGINT;
  v_generated_orders INT := 0;
  v_skipped_orders INT := 0;
  v_stock_failures INT := 0;
  v_job_assignments_created INT := 0;
  v_rb RECORD;
  v_existing_order UUID;
BEGIN
  v_day_of_week := EXTRACT(ISODOW FROM p_target_date);

  -- 1. PROCESS PRODUCE SUBSCRIPTIONS
  FOR v_sub IN
    SELECT s.*
    FROM public.subscriptions s
    WHERE s.status = 'active'
  LOOP
    -- Check skip dates
    IF v_sub.skip_dates IS NOT NULL AND p_target_date = ANY(v_sub.skip_dates) THEN
      v_skipped_orders := v_skipped_orders + 1;
      CONTINUE;
    END IF;

    -- Check frequency fit
    v_should_deliver := false;
    IF v_sub.frequency = 'daily' THEN
      v_should_deliver := true;
    ELSIF v_sub.frequency = 'weekdays' THEN
      IF v_day_of_week BETWEEN 1 AND 5 THEN
        v_should_deliver := true;
      END IF;
    ELSIF v_sub.frequency = 'weekly' THEN
      -- Default weekly delivers on Monday (1) or whatever day next_delivery_date landed on
      IF v_day_of_week = EXTRACT(ISODOW FROM COALESCE(v_sub.next_delivery_date, p_target_date)) THEN
        v_should_deliver := true;
      END IF;
    ELSE
      v_should_deliver := true;
    END IF;

    IF NOT v_should_deliver THEN
      CONTINUE;
    END IF;

    -- Check idempotency: order already generated for this customer, listing, and delivery date?
    SELECT o.id INTO v_existing_order
    FROM public.orders o
    JOIN public.order_items oi ON oi.order_id = o.id
    WHERE o.customer_id = v_sub.customer_id
      AND oi.listing_id = v_sub.listing_id
      AND o.delivery_date = p_target_date
    LIMIT 1;

    IF v_existing_order IS NOT NULL THEN
      CONTINUE; -- Already generated today
    END IF;

    -- Check produce stock availability
    SELECT * INTO v_listing
    FROM public.produce_listings
    WHERE id = v_sub.listing_id;

    IF v_listing IS NULL OR v_listing.stock_qty < v_sub.quantity THEN
      -- Stock shortage! Do NOT generate order. Send notification.
      v_stock_failures := v_stock_failures + 1;

      INSERT INTO public.notifications (
        user_id,
        title,
        body,
        type,
        data
      ) VALUES (
        v_sub.customer_id,
        'Subscription delivery unavailable for tomorrow',
        'Your scheduled subscription for ' || COALESCE(v_sub.listing_name, 'Produce') || ' cannot be fulfilled tomorrow due to fresh harvest stock shortage.',
        'order_status',
        jsonb_build_object(
          'subscription_id', v_sub.id,
          'target_date', p_target_date,
          'reason', 'stock_shortage'
        )
      );

      CONTINUE;
    END IF;

    -- Deduct stock
    UPDATE public.produce_listings
    SET stock_qty = stock_qty - v_sub.quantity,
        updated_at = NOW()
    WHERE id = v_sub.listing_id;

    -- Generate order
    v_order_code := 'SUB-' || TO_CHAR(p_target_date, 'YYYYMMDD') || '-' || SUBSTRING(v_sub.id::text, 1, 6);
    v_total_paise := (v_sub.quantity * COALESCE(v_sub.unit_price_paise, v_listing.price_paise))::bigint;

    INSERT INTO public.orders (
      order_code,
      customer_id,
      farmer_id,
      total_paise,
      fee_paise,
      discount_paise,
      status,
      fulfilment,
      protected,
      delivery_date,
      address_text
    ) VALUES (
      v_order_code,
      v_sub.customer_id,
      v_sub.farmer_id,
      v_total_paise,
      0,
      0,
      'accepted',
      'delivery',
      true,
      p_target_date,
      COALESCE(v_sub.doorstep_address, 'Doorstep Delivery')
    ) RETURNING id INTO v_order_id;

    INSERT INTO public.order_items (
      order_id,
      listing_id,
      name,
      unit,
      unit_price_paise,
      quantity,
      subtotal_paise
    ) VALUES (
      v_order_id,
      v_sub.listing_id,
      COALESCE(v_sub.listing_name, v_listing.name),
      COALESCE(v_listing.unit, 'unit'),
      COALESCE(v_sub.unit_price_paise, v_listing.price_paise),
      v_sub.quantity,
      v_total_paise
    );

    -- Timeline event
    INSERT INTO public.order_events (
      order_id,
      event_type,
      notes,
      actor_id
    ) VALUES (
      v_order_id,
      'accepted',
      'Automatically generated from active farm subscription ' || v_sub.delivery_slot_time,
      v_sub.farmer_id
    );

    v_generated_orders := v_generated_orders + 1;
  END LOOP;

  -- 2. PROCESS RECURRING SERVICE JOBS (P4.6)
  FOR v_rb IN
    SELECT rb.*, j.title AS job_title
    FROM public.recurring_bookings rb
    LEFT JOIN public.jobs j ON j.id = rb.job_id
    WHERE rb.status = 'active'
  LOOP
    IF v_rb.skip_dates IS NOT NULL AND p_target_date = ANY(v_rb.skip_dates) THEN
      CONTINUE;
    END IF;

    -- Check if assignment already exists for tomorrow
    IF NOT EXISTS (
      SELECT 1 FROM public.job_assignments
      WHERE job_id = v_rb.job_id
        AND worker_id = v_rb.worker_id
        AND scheduled_start::date = p_target_date
    ) THEN
      INSERT INTO public.job_assignments (
        job_id,
        worker_id,
        status,
        scheduled_start,
        escrow_wage_paise,
        created_at
      ) VALUES (
        v_rb.job_id,
        v_rb.worker_id,
        'requested',
        (p_target_date || ' ' || COALESCE(v_rb.preferred_time::text, '09:00:00'))::timestamptz,
        0,
        NOW()
      );
      v_job_assignments_created := v_job_assignments_created + 1;
    END IF;
  END LOOP;

  RETURN jsonb_build_object(
    'ok', true,
    'target_date', p_target_date,
    'generated_orders', v_generated_orders,
    'skipped_orders', v_skipped_orders,
    'stock_failures', v_stock_failures,
    'job_assignments_created', v_job_assignments_created
  );
END;
$$;

-- ============================================================================
-- 5. GROUP ORDERS RPCs (P6.7)
-- ============================================================================

-- A. Create Group Order
CREATE OR REPLACE FUNCTION public.create_group_order(
  p_listing_id UUID,
  p_community_name TEXT,
  p_target_qty NUMERIC,
  p_price_tiers JSONB,
  p_deadline TIMESTAMPTZ,
  p_organizer_qty NUMERIC
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_listing RECORD;
  v_group_id UUID;
  v_tier_price BIGINT;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
  END IF;

  IF p_target_qty <= 0 THEN
    RAISE EXCEPTION 'Target quantity must be greater than zero' USING ERRCODE = '22003';
  END IF;

  IF p_deadline <= NOW() THEN
    RAISE EXCEPTION 'Deadline must be in the future' USING ERRCODE = '22023';
  END IF;

  SELECT * INTO v_listing
  FROM public.produce_listings
  WHERE id = p_listing_id AND status = 'active';

  IF v_listing IS NULL THEN
    RAISE EXCEPTION 'Produce listing not found' USING ERRCODE = 'P0002';
  END IF;

  -- Default tier price to listing price
  v_tier_price := v_listing.price_paise;

  INSERT INTO public.group_orders (
    organizer_id,
    listing_id,
    community_name,
    target_qty,
    price_tiers,
    deadline,
    status
  ) VALUES (
    v_user_id,
    p_listing_id,
    p_community_name,
    p_target_qty,
    p_price_tiers,
    p_deadline,
    'open'
  ) RETURNING id INTO v_group_id;

  -- If organizer joined with an initial quantity
  IF p_organizer_qty > 0 THEN
    INSERT INTO public.group_order_members (
      group_order_id,
      user_id,
      quantity,
      amount_paise,
      paid
    ) VALUES (
      v_group_id,
      v_user_id,
      p_organizer_qty,
      (p_organizer_qty * v_tier_price)::bigint,
      true
    );
  END IF;

  RETURN jsonb_build_object(
    'ok', true,
    'group_order_id', v_group_id,
    'community_name', p_community_name,
    'target_qty', p_target_qty
  );
END;
$$;

-- B. Join Group Order
CREATE OR REPLACE FUNCTION public.join_group_order(
  p_group_order_id UUID,
  p_quantity NUMERIC
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_group RECORD;
  v_listing RECORD;
  v_current_total NUMERIC;
  v_effective_price_paise BIGINT;
  v_tier RECORD;
  v_member_amount BIGINT;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
  END IF;

  IF p_quantity <= 0 THEN
    RAISE EXCEPTION 'Quantity must be greater than zero' USING ERRCODE = '22003';
  END IF;

  SELECT * INTO v_group
  FROM public.group_orders
  WHERE id = p_group_order_id;

  IF v_group IS NULL THEN
    RAISE EXCEPTION 'Group order not found' USING ERRCODE = 'P0002';
  END IF;

  IF v_group.status <> 'open' THEN
    RAISE EXCEPTION 'Group order is no longer accepting members' USING ERRCODE = 'P0003';
  END IF;

  IF v_group.deadline < NOW() THEN
    RAISE EXCEPTION 'Group order deadline has passed' USING ERRCODE = 'P0004';
  END IF;

  SELECT * INTO v_listing
  FROM public.produce_listings
  WHERE id = v_group.listing_id;

  -- Calculate current total with new quantity
  SELECT COALESCE(SUM(quantity), 0) INTO v_current_total
  FROM public.group_order_members
  WHERE group_order_id = p_group_order_id;

  v_current_total := v_current_total + p_quantity;

  -- Determine effective price tier
  v_effective_price_paise := v_listing.price_paise;
  IF v_group.price_tiers IS NOT NULL AND jsonb_array_length(v_group.price_tiers) > 0 THEN
    FOR v_tier IN
      SELECT (elem->>'min_qty')::numeric AS min_qty, (elem->>'price_paise')::bigint AS price_paise
      FROM jsonb_array_elements(v_group.price_tiers) elem
      ORDER BY (elem->>'min_qty')::numeric DESC
    LOOP
      IF v_current_total >= v_tier.min_qty THEN
        v_effective_price_paise := v_tier.price_paise;
        EXIT;
      END IF;
    END LOOP;
  END IF;

  v_member_amount := (p_quantity * v_effective_price_paise)::bigint;

  -- Insert or update member participation
  IF EXISTS (
    SELECT 1 FROM public.group_order_members
    WHERE group_order_id = p_group_order_id AND user_id = v_user_id
  ) THEN
    UPDATE public.group_order_members
    SET quantity = quantity + p_quantity,
        amount_paise = amount_paise + v_member_amount,
        paid = true
    WHERE group_order_id = p_group_order_id AND user_id = v_user_id;
  ELSE
    INSERT INTO public.group_order_members (
      group_order_id,
      user_id,
      quantity,
      amount_paise,
      paid
    ) VALUES (
      p_group_order_id,
      v_user_id,
      p_quantity,
      v_member_amount,
      true
    );
  END IF;

  -- If target met, mark status target_met
  IF v_current_total >= v_group.target_qty THEN
    UPDATE public.group_orders
    SET status = 'target_met',
        updated_at = NOW()
    WHERE id = p_group_order_id;
  END IF;

  RETURN jsonb_build_object(
    'ok', true,
    'group_order_id', p_group_order_id,
    'total_qty', v_current_total,
    'target_qty', v_group.target_qty,
    'effective_price_paise', v_effective_price_paise,
    'target_met', v_current_total >= v_group.target_qty
  );
END;
$$;

-- C. Evaluate Group Orders (Finalize or Refund)
CREATE OR REPLACE FUNCTION public.evaluate_group_orders()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_group RECORD;
  v_listing RECORD;
  v_current_total NUMERIC;
  v_effective_price_paise BIGINT;
  v_tier RECORD;
  v_member RECORD;
  v_order_id UUID;
  v_finalized_count INT := 0;
  v_cancelled_count INT := 0;
BEGIN
  FOR v_group IN
    SELECT * FROM public.group_orders
    WHERE status IN ('open', 'target_met')
  LOOP
    SELECT COALESCE(SUM(quantity), 0) INTO v_current_total
    FROM public.group_order_members
    WHERE group_order_id = v_group.id;

    -- Scenario 1: Target reached or deadline passed with target met
    IF v_current_total >= v_group.target_qty THEN
      SELECT * INTO v_listing
      FROM public.produce_listings
      WHERE id = v_group.listing_id;

      -- Determine final tier
      v_effective_price_paise := v_listing.price_paise;
      IF v_group.price_tiers IS NOT NULL AND jsonb_array_length(v_group.price_tiers) > 0 THEN
        FOR v_tier IN
          SELECT (elem->>'min_qty')::numeric AS min_qty, (elem->>'price_paise')::bigint AS price_paise
          FROM jsonb_array_elements(v_group.price_tiers) elem
          ORDER BY (elem->>'min_qty')::numeric DESC
        LOOP
          IF v_current_total >= v_tier.min_qty THEN
            v_effective_price_paise := v_tier.price_paise;
            EXIT;
          END IF;
        END LOOP;
      END IF;

      -- Mark group order closed
      UPDATE public.group_orders
      SET status = 'closed',
          updated_at = NOW()
      WHERE id = v_group.id;

      -- Create community bulk order
      INSERT INTO public.orders (
        order_code,
        customer_id,
        farmer_id,
        total_paise,
        fee_paise,
        discount_paise,
        status,
        fulfilment,
        protected,
        address_text
      ) VALUES (
        'GRP-' || SUBSTRING(v_group.id::text, 1, 8),
        v_group.organizer_id,
        v_listing.farmer_id,
        (v_current_total * v_effective_price_paise)::bigint,
        0,
        0,
        'accepted',
        'delivery',
        true,
        v_group.community_name || ' (Community Bulk Delivery)'
      ) RETURNING id INTO v_order_id;

      INSERT INTO public.order_items (
        order_id,
        listing_id,
        name,
        unit,
        unit_price_paise,
        quantity,
        subtotal_paise
      ) VALUES (
        v_order_id,
        v_group.listing_id,
        v_listing.name,
        COALESCE(v_listing.unit, 'unit'),
        v_effective_price_paise,
        v_current_total,
        (v_current_total * v_effective_price_paise)::bigint
      );

      v_finalized_count := v_finalized_count + 1;

    -- Scenario 2: Deadline passed and target NOT met -> Cancel and Refund
    ELSIF v_group.deadline < NOW() AND v_current_total < v_group.target_qty THEN
      UPDATE public.group_orders
      SET status = 'cancelled',
          updated_at = NOW()
      WHERE id = v_group.id;

      -- Refund participants
      FOR v_member IN
        SELECT * FROM public.group_order_members
        WHERE group_order_id = v_group.id AND paid = true
      LOOP
        PERFORM public.wallet_credit(
          v_member.user_id,
          v_member.amount_paise,
          'refund',
          'Refund: Group order ' || v_group.community_name || ' target not met'
        );
      END LOOP;

      v_cancelled_count := v_cancelled_count + 1;
    END IF;
  END LOOP;

  RETURN jsonb_build_object(
    'ok', true,
    'finalized_count', v_finalized_count,
    'cancelled_count', v_cancelled_count
  );
END;
$$;

-- D. Get Community Group Orders
CREATE OR REPLACE FUNCTION public.get_community_group_orders()
RETURNS TABLE (
  id UUID,
  organizer_id UUID,
  organizer_name TEXT,
  listing_id UUID,
  listing_name TEXT,
  produce_category TEXT,
  community_name TEXT,
  target_qty NUMERIC,
  current_qty NUMERIC,
  price_tiers JSONB,
  deadline TIMESTAMPTZ,
  status public.group_order_status,
  member_count BIGINT,
  created_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    g.id,
    g.organizer_id,
    COALESCE(p.full_name, 'Community Organiser') AS organizer_name,
    g.listing_id,
    COALESCE(pl.name, 'Organic Produce') AS listing_name,
    COALESCE(pl.category::text, 'vegetable') AS produce_category,
    g.community_name,
    g.target_qty,
    COALESCE(SUM(gom.quantity), 0) AS current_qty,
    g.price_tiers,
    g.deadline,
    g.status,
    COUNT(gom.id) AS member_count,
    g.created_at
  FROM public.group_orders g
  JOIN public.profiles p ON p.id = g.organizer_id
  LEFT JOIN public.produce_listings pl ON pl.id = g.listing_id
  LEFT JOIN public.group_order_members gom ON gom.group_order_id = g.id
  GROUP BY g.id, p.full_name, pl.name, pl.category
  ORDER BY g.created_at DESC;
$$;

-- ============================================================================
-- 6. GET GOVERNMENT SCHEMES RPC
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_government_schemes(
  p_category TEXT DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  slug TEXT,
  name_en TEXT,
  name_kn TEXT,
  name_hi TEXT,
  name_te TEXT,
  name_ta TEXT,
  short_description_en TEXT,
  short_description_kn TEXT,
  short_description_hi TEXT,
  short_description_te TEXT,
  short_description_ta TEXT,
  official_url TEXT,
  category TEXT,
  benefits_summary TEXT,
  documents_required TEXT[]
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    gs.id,
    gs.slug,
    gs.name_en,
    gs.name_kn,
    gs.name_hi,
    gs.name_te,
    gs.name_ta,
    gs.short_description_en,
    gs.short_description_kn,
    gs.short_description_hi,
    gs.short_description_te,
    gs.short_description_ta,
    gs.official_url,
    gs.category,
    gs.benefits_summary,
    gs.documents_required
  FROM public.government_schemes gs
  WHERE p_category IS NULL OR gs.category = p_category
  ORDER BY gs.created_at ASC;
$$;
