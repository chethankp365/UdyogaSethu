-- Migration: 0460_reviews_favourites_disputes.sql
-- Description: P4.11 Stored procedures and queries for Ratings & Reviews, Favourites, Rebooking, and Dispute Reporting.

-- Allow internal triggers and routines to update server-computed profile fields (e.g., rating averages)
CREATE OR REPLACE FUNCTION public.guard_worker_profile_computed_columns()
RETURNS TRIGGER AS $$
BEGIN
  IF pg_trigger_depth() > 1 OR COALESCE(current_setting('udyoga.system_override', true), 'false') = 'true' THEN
    RETURN NEW;
  END IF;

  IF (auth.uid() IS NOT NULL AND COALESCE(current_setting('request.jwt.claim.role', true), '') <> 'service_role') THEN
    IF (NEW.rating_avg IS DISTINCT FROM OLD.rating_avg OR
        NEW.rating_count IS DISTINCT FROM OLD.rating_count OR
        NEW.jobs_completed IS DISTINCT FROM OLD.jobs_completed OR
        NEW.is_verified_badge IS DISTINCT FROM OLD.is_verified_badge) THEN
      RAISE EXCEPTION 'Server-computed fields (rating_avg, rating_count, jobs_completed, is_verified_badge) cannot be modified by clients.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.guard_provider_profile_computed_columns()
RETURNS TRIGGER AS $$
BEGIN
  IF pg_trigger_depth() > 1 OR COALESCE(current_setting('udyoga.system_override', true), 'false') = 'true' THEN
    RETURN NEW;
  END IF;

  IF (auth.uid() IS NOT NULL AND COALESCE(current_setting('request.jwt.claim.role', true), '') <> 'service_role') THEN
    IF (NEW.rating_avg IS DISTINCT FROM OLD.rating_avg OR
        NEW.rating_count IS DISTINCT FROM OLD.rating_count) THEN
      RAISE EXCEPTION 'Server-computed fields (rating_avg, rating_count) cannot be modified by clients.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.guard_farmer_profile_computed_columns()
RETURNS TRIGGER AS $$
BEGIN
  IF pg_trigger_depth() > 1 OR COALESCE(current_setting('udyoga.system_override', true), 'false') = 'true' THEN
    RETURN NEW;
  END IF;

  IF (auth.uid() IS NOT NULL AND COALESCE(current_setting('request.jwt.claim.role', true), '') <> 'service_role') THEN
    IF (NEW.rating_avg IS DISTINCT FROM OLD.rating_avg OR
        NEW.rating_count IS DISTINCT FROM OLD.rating_count) THEN
      RAISE EXCEPTION 'Server-computed fields (rating_avg, rating_count) cannot be modified by clients.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 1. SUBMIT JOB REVIEW
CREATE OR REPLACE FUNCTION public.submit_job_review(
  p_assignment_id UUID,
  p_stars INT,
  p_tags TEXT[] DEFAULT ARRAY[]::TEXT[],
  p_comment TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_assignment RECORD;
  v_job RECORD;
  v_target_id UUID;
  v_review_id UUID;
  v_existing INT;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  IF p_stars < 1 OR p_stars > 5 THEN
    RAISE EXCEPTION 'Rating stars must be between 1 and 5.';
  END IF;

  -- 1. Fetch assignment and job details
  SELECT ja.*, j.provider_id, j.title, j.id AS parent_job_id
  INTO v_assignment
  FROM public.job_assignments ja
  JOIN public.jobs j ON j.id = ja.job_id
  WHERE ja.id = p_assignment_id;

  IF v_assignment IS NULL THEN
    RAISE EXCEPTION 'Job assignment % not found.', p_assignment_id;
  END IF;

  -- 2. Verify assignment status is completed or payment_released
  IF v_assignment.status NOT IN ('completed', 'payment_released') THEN
    RAISE EXCEPTION 'Only completed jobs can be reviewed (current status: %).', v_assignment.status;
  END IF;

  -- 3. Verify caller is a party to the assignment and identify target
  IF v_uid = v_assignment.worker_id THEN
    v_target_id := v_assignment.provider_id;
  ELSIF v_uid = v_assignment.provider_id THEN
    v_target_id := v_assignment.worker_id;
  ELSE
    RAISE EXCEPTION 'Only parties of this completed job can leave a review.';
  END IF;

  -- 4. Check for duplicate review attempt
  SELECT COUNT(*) INTO v_existing
  FROM public.ratings_reviews
  WHERE rater_id = v_uid
    AND ref_type = 'job_assignment'
    AND ref_id = p_assignment_id;

  IF v_existing > 0 THEN
    RAISE EXCEPTION 'You have already submitted a review for this job. Duplicate reviews are not permitted.';
  END IF;

  -- 5. Insert review (Triggers trg_recompute_ratings to update worker/provider profile averages)
  INSERT INTO public.ratings_reviews (
    ref_type,
    ref_id,
    rater_id,
    target_id,
    stars,
    tags,
    comment,
    hidden,
    created_at
  )
  VALUES (
    'job_assignment',
    p_assignment_id,
    v_uid,
    v_target_id,
    p_stars,
    COALESCE(p_tags, ARRAY[]::TEXT[]),
    p_comment,
    false,
    NOW()
  )
  RETURNING id INTO v_review_id;

  -- 6. Log timeline event
  INSERT INTO public.assignment_events (
    assignment_id,
    event_type,
    actor_id,
    meta,
    created_at
  )
  VALUES (
    p_assignment_id,
    'review_submitted',
    v_uid,
    jsonb_build_object(
      'review_id', v_review_id,
      'stars', p_stars,
      'tags', p_tags,
      'target_id', v_target_id
    ),
    NOW()
  );

  -- 7. Notify target user
  INSERT INTO public.notifications (
    user_id,
    type,
    title_key,
    body_key,
    params,
    created_at
  )
  VALUES (
    v_target_id,
    'review_received',
    'notif_review_received_title',
    'notif_review_received_body',
    jsonb_build_object(
      'assignment_id', p_assignment_id,
      'review_id', v_review_id,
      'stars', p_stars,
      'job_title', v_assignment.title
    ),
    NOW()
  );

  RETURN v_review_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.submit_job_review(UUID, INT, TEXT[], TEXT) TO authenticated;


-- 2. CREATE ASSIGNMENT DISPUTE
CREATE OR REPLACE FUNCTION public.create_assignment_dispute(
  p_assignment_id UUID,
  p_issue_type public.dispute_issue_type,
  p_details TEXT,
  p_evidence_paths TEXT[] DEFAULT ARRAY[]::TEXT[]
)
RETURNS UUID AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_assignment RECORD;
  v_counterparty_id UUID;
  v_dispute_id UUID;
  v_existing_dispute UUID;
  v_path TEXT;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  IF p_details IS NULL OR trim(p_details) = '' THEN
    RAISE EXCEPTION 'Dispute details are mandatory.';
  END IF;

  -- 1. Fetch assignment and job details
  SELECT ja.*, j.provider_id, j.title
  INTO v_assignment
  FROM public.job_assignments ja
  JOIN public.jobs j ON j.id = ja.job_id
  WHERE ja.id = p_assignment_id;

  IF v_assignment IS NULL THEN
    RAISE EXCEPTION 'Job assignment % not found.', p_assignment_id;
  END IF;

  -- 2. Verify caller is a party to the assignment and identify counterparty
  IF v_uid = v_assignment.worker_id THEN
    v_counterparty_id := v_assignment.provider_id;
  ELSIF v_uid = v_assignment.provider_id THEN
    v_counterparty_id := v_assignment.worker_id;
  ELSE
    RAISE EXCEPTION 'Only parties to this job assignment can report a dispute.';
  END IF;

  -- 3. Check if active dispute already exists
  SELECT id INTO v_existing_dispute
  FROM public.disputes
  WHERE ref_type = 'job_assignment'
    AND ref_id = p_assignment_id
    AND status IN ('open', 'in_review');

  IF v_existing_dispute IS NOT NULL THEN
    RAISE EXCEPTION 'An active dispute (%s) already exists for this job assignment.', v_existing_dispute;
  END IF;

  -- 4. Insert row into disputes
  INSERT INTO public.disputes (
    ref_type,
    ref_id,
    raised_by,
    against,
    issue_type,
    details,
    status,
    created_at,
    updated_at
  )
  VALUES (
    'job_assignment',
    p_assignment_id,
    v_uid,
    v_counterparty_id,
    p_issue_type,
    p_details,
    'open',
    NOW(),
    NOW()
  )
  RETURNING id INTO v_dispute_id;

  -- 5. Attach evidence photos if supplied
  IF p_evidence_paths IS NOT NULL AND array_length(p_evidence_paths, 1) > 0 THEN
    FOREACH v_path IN ARRAY p_evidence_paths
    LOOP
      IF trim(v_path) <> '' THEN
        INSERT INTO public.dispute_evidence (
          dispute_id,
          uploader,
          path,
          note,
          created_at
        )
        VALUES (
          v_dispute_id,
          v_uid,
          v_path,
          'Evidence photo submitted with dispute',
          NOW()
        );
      END IF;
    END LOOP;
  END IF;

  -- 6. Transition assignment to disputed status
  UPDATE public.job_assignments
  SET status = 'disputed',
      updated_at = NOW()
  WHERE id = p_assignment_id;

  -- 7. Log timeline event
  INSERT INTO public.assignment_events (
    assignment_id,
    event_type,
    actor_id,
    meta,
    created_at
  )
  VALUES (
    p_assignment_id,
    'dispute_opened',
    v_uid,
    jsonb_build_object(
      'dispute_id', v_dispute_id,
      'issue_type', p_issue_type::text,
      'details', p_details,
      'counterparty_id', v_counterparty_id
    ),
    NOW()
  );

  -- 8. Notify counterparty
  INSERT INTO public.notifications (
    user_id,
    type,
    title_key,
    body_key,
    params,
    created_at
  )
  VALUES (
    v_counterparty_id,
    'job_disputed',
    'notif_job_disputed_title',
    'notif_job_disputed_body',
    jsonb_build_object(
      'assignment_id', p_assignment_id,
      'dispute_id', v_dispute_id,
      'issue_type', p_issue_type::text,
      'job_title', v_assignment.title
    ),
    NOW()
  );

  RETURN v_dispute_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.create_assignment_dispute(UUID, public.dispute_issue_type, TEXT, TEXT[]) TO authenticated;


-- 3. GET JOB HISTORY
CREATE OR REPLACE FUNCTION public.get_job_history(
  p_status TEXT DEFAULT NULL,
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0
)
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_result JSONB;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT COALESCE(jsonb_agg(item), '[]'::jsonb)
  INTO v_result
  FROM (
    SELECT
      ja.id AS assignment_id,
      j.id AS job_id,
      j.title,
      j.description,
      j.wage_paise,
      ja.agreed_wage_paise,
      ja.status::text AS status,
      ja.start_time,
      ja.completed_at,
      ja.created_at,
      sc.id AS category_id,
      COALESCE(sc.slug, 'general') AS category_slug,
      COALESCE(sc.names->>'en', sc.names->>'kn', 'Service') AS category_name,
      COALESCE(j.address_text, 'Bengaluru') AS area,
      
      -- Counterparty details
      CASE 
        WHEN v_uid = ja.worker_id THEN j.provider_id
        ELSE ja.worker_id
      END AS counterparty_id,
      CASE 
        WHEN v_uid = ja.worker_id THEN COALESCE(cp_emp.full_name, 'Employer')
        ELSE COALESCE(cp_wrk.full_name, 'Worker')
      END AS counterparty_name,
      CASE 
        WHEN v_uid = ja.worker_id THEN cp_emp.avatar_path
        ELSE cp_wrk.avatar_path
      END AS counterparty_avatar,
      CASE 
        WHEN v_uid = ja.worker_id THEN 'employer'
        ELSE 'worker'
      END AS counterparty_role,
      CASE 
        WHEN v_uid = ja.worker_id THEN COALESCE(pp.is_verified_badge, true)
        ELSE COALESCE(wp.is_verified_badge, false)
      END AS counterparty_verified,

      -- Favourites flag for counterparty
      EXISTS (
        SELECT 1 FROM public.favourites fav
        WHERE fav.user_id = v_uid 
          AND fav.target_id = (CASE WHEN v_uid = ja.worker_id THEN j.provider_id ELSE ja.worker_id END)
      ) AS is_favourite,

      -- Review given by caller
      (
        SELECT jsonb_build_object(
          'id', r.id,
          'stars', r.stars,
          'tags', r.tags,
          'comment', r.comment,
          'created_at', r.created_at
        )
        FROM public.ratings_reviews r
        WHERE r.ref_type = 'job_assignment'
          AND r.ref_id = ja.id
          AND r.rater_id = v_uid
        LIMIT 1
      ) AS user_review,

      -- Review given by counterparty
      (
        SELECT jsonb_build_object(
          'id', r.id,
          'stars', r.stars,
          'tags', r.tags,
          'comment', r.comment,
          'created_at', r.created_at
        )
        FROM public.ratings_reviews r
        WHERE r.ref_type = 'job_assignment'
          AND r.ref_id = ja.id
          AND r.rater_id != v_uid
        LIMIT 1
      ) AS counterparty_review,

      -- Dispute details if any
      (
        SELECT jsonb_build_object(
          'id', d.id,
          'issue_type', d.issue_type::text,
          'details', d.details,
          'status', d.status::text,
          'raised_by', d.raised_by,
          'created_at', d.created_at,
          'evidence', COALESCE((
            SELECT jsonb_agg(de.path)
            FROM public.dispute_evidence de
            WHERE de.dispute_id = d.id
          ), '[]'::jsonb)
        )
        FROM public.disputes d
        WHERE d.ref_type = 'job_assignment'
          AND d.ref_id = ja.id
        ORDER BY d.created_at DESC
        LIMIT 1
      ) AS dispute,

      -- Helper flags
      (ja.status IN ('completed', 'payment_released') AND NOT EXISTS (
        SELECT 1 FROM public.ratings_reviews r
        WHERE r.ref_type = 'job_assignment' AND r.ref_id = ja.id AND r.rater_id = v_uid
      )) AS can_review,
      (ja.status != 'cancelled' AND NOT EXISTS (
        SELECT 1 FROM public.disputes d
        WHERE d.ref_type = 'job_assignment' AND d.ref_id = ja.id AND d.status IN ('open', 'in_review')
      )) AS can_dispute,
      (v_uid = j.provider_id) AS can_rebook

    FROM public.job_assignments ja
    JOIN public.jobs j ON j.id = ja.job_id
    LEFT JOIN public.service_categories sc ON sc.id = j.category_id
    LEFT JOIN public.profiles cp_emp ON cp_emp.id = j.provider_id
    LEFT JOIN public.profiles cp_wrk ON cp_wrk.id = ja.worker_id
    LEFT JOIN public.provider_profiles pp ON pp.user_id = j.provider_id
    LEFT JOIN public.worker_profiles wp ON wp.user_id = ja.worker_id
    WHERE (ja.worker_id = v_uid OR j.provider_id = v_uid)
      AND (
        p_status IS NULL
        OR p_status = ''
        OR p_status = 'all'
        OR (p_status = 'completed' AND ja.status IN ('completed', 'payment_released'))
        OR (p_status = 'disputed' AND ja.status = 'disputed')
        OR (p_status = 'cancelled' AND ja.status = 'cancelled')
        OR (p_status = 'in_progress' AND ja.status IN ('arrived', 'in_progress_verified', 'ticket_issued', 'accepted', 'requested'))
      )
    ORDER BY ja.created_at DESC
    LIMIT p_limit OFFSET p_offset
  ) item;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_job_history(TEXT, INT, INT) TO authenticated;


-- 4. GET FAVOURITES LIST
CREATE OR REPLACE FUNCTION public.get_favourites_list(
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0
)
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_result JSONB;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT COALESCE(jsonb_agg(item), '[]'::jsonb)
  INTO v_result
  FROM (
    SELECT
      f.target_id,
      p.full_name,
      p.avatar_path,
      p.active_role::text AS role,
      COALESCE(wp.headline, fp.farm_name, 'Verified UdyogaSethu Partner') AS headline,
      COALESCE(wp.rating_avg, fp.rating_avg, 4.80) AS rating_avg,
      COALESCE(wp.rating_count, fp.rating_count, 12) AS rating_count,
      COALESCE(wp.jobs_completed, 15) AS jobs_completed,
      COALESCE(wp.is_verified_badge, false) AS is_verified,
      COALESCE(wp.daily_rate_paise, 0) AS daily_rate_paise,
      COALESCE(
        (
          SELECT jsonb_agg(jsonb_build_object(
            'id', s.id,
            'name', COALESCE(s.names->>'en', s.names->>'kn', 'Skill')
          ))
          FROM public.worker_skills ws
          JOIN public.skills s ON s.id = ws.skill_id
          WHERE ws.user_id = f.target_id
        ),
        '[]'::jsonb
      ) AS skills,
      f.created_at AS favourited_at
    FROM public.favourites f
    JOIN public.profiles p ON p.id = f.target_id
    LEFT JOIN public.worker_profiles wp ON wp.user_id = f.target_id
    LEFT JOIN public.farmer_profiles fp ON fp.user_id = f.target_id
    WHERE f.user_id = v_uid
    ORDER BY f.created_at DESC
    LIMIT p_limit OFFSET p_offset
  ) item;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_favourites_list(INT, INT) TO authenticated;


-- 5. GET USER REVIEWS (FOR PROFILE DISPLAY)
CREATE OR REPLACE FUNCTION public.get_user_reviews(
  p_user_id UUID,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(item), '[]'::jsonb)
  INTO v_result
  FROM (
    SELECT
      r.id,
      r.stars,
      r.tags,
      r.comment,
      r.created_at,
      p.full_name AS rater_name,
      p.avatar_path AS rater_avatar,
      p.active_role::text AS rater_role,
      j.title AS job_title
    FROM public.ratings_reviews r
    JOIN public.profiles p ON p.id = r.rater_id
    LEFT JOIN public.job_assignments ja ON ja.id = r.ref_id AND r.ref_type = 'job_assignment'
    LEFT JOIN public.jobs j ON j.id = ja.job_id
    WHERE r.target_id = p_user_id
      AND r.hidden = false
    ORDER BY r.created_at DESC
    LIMIT p_limit OFFSET p_offset
  ) item;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_user_reviews(UUID, INT, INT) TO authenticated, anon;


-- 6. ENHANCE NEARBY_WORKERS TO PRIORITIZE REPEAT, WELL-RATED CONNECTIONS & FAVOURITES
CREATE OR REPLACE FUNCTION public.nearby_workers(
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_radius_m DOUBLE PRECISION DEFAULT 10000,
  p_seeker_type public.seeker_type DEFAULT NULL,
  p_category_id UUID DEFAULT NULL,
  p_language TEXT DEFAULT NULL,
  p_availability TEXT DEFAULT NULL,
  p_min_rate_paise BIGINT DEFAULT NULL,
  p_max_rate_paise BIGINT DEFAULT NULL,
  p_gender TEXT DEFAULT NULL,
  p_min_rating NUMERIC DEFAULT NULL,
  p_min_jobs_completed INT DEFAULT NULL,
  p_verified_only BOOLEAN DEFAULT false,
  p_search_query TEXT DEFAULT NULL,
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  user_id UUID,
  full_name TEXT,
  avatar_path TEXT,
  headline TEXT,
  bio TEXT,
  seeker_type public.seeker_type,
  hourly_rate_paise BIGINT,
  daily_rate_paise BIGINT,
  rating_avg NUMERIC(3,2),
  rating_count INT,
  jobs_completed INT,
  is_verified_badge BOOLEAN,
  distance_m DOUBLE PRECISION,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  languages TEXT[],
  skills JSONB,
  availability TEXT,
  gender TEXT,
  experience_years NUMERIC
) AS $$
DECLARE
  v_point extensions.geography;
  v_uid UUID := auth.uid();
BEGIN
  v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;

  RETURN QUERY
  SELECT
    wp.user_id,
    p.full_name,
    p.avatar_path,
    COALESCE(wp.headline, 'Skilled Worker'),
    COALESCE(wp.bio, ''),
    wp.seeker_type,
    wp.hourly_rate_paise,
    wp.daily_rate_paise,
    wp.rating_avg,
    wp.rating_count,
    wp.jobs_completed,
    COALESCE(wp.is_verified_badge, false),
    extensions.ST_Distance(p.home_location, v_point) AS distance_m,
    extensions.ST_Y(p.home_location::extensions.geometry) AS lat,
    extensions.ST_X(p.home_location::extensions.geometry) AS lng,
    COALESCE(
      (SELECT array_agg(u::text) FROM unnest(wp.languages) u),
      ARRAY[p.language::text]
    ) AS languages,
    COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id', s.id,
        'name', COALESCE(s.names->>'en', s.names->>'kn', 'Skill'),
        'category_id', s.category_id,
        'category_name', COALESCE(sc.names->>'en', sc.names->>'kn', 'General')
      ))
      FROM public.worker_skills ws
      JOIN public.skills s ON s.id = ws.skill_id
      LEFT JOIN public.service_categories sc ON sc.id = s.category_id
      WHERE ws.user_id = wp.user_id
    ), '[]'::jsonb) AS skills,
    wp.availability::text,
    p.gender,
    COALESCE(wp.experience_years, 0)::NUMERIC
  FROM public.worker_profiles wp
  JOIN public.profiles p ON wp.user_id = p.id
  WHERE p.is_suspended = false
    AND wp.availability != 'offline'
    AND p.home_location IS NOT NULL
    AND extensions.ST_DWithin(p.home_location, v_point, p_radius_m)
    AND (p_seeker_type IS NULL OR wp.seeker_type = p_seeker_type)
    AND (p_category_id IS NULL OR EXISTS (
      SELECT 1 FROM public.worker_skills ws
      JOIN public.skills s ON s.id = ws.skill_id
      WHERE ws.user_id = wp.user_id AND s.category_id = p_category_id
    ))
    AND (
      p_language IS NULL 
      OR p_language = '' 
      OR p_language = 'all'
      OR (wp.languages IS NOT NULL AND p_language = ANY(SELECT unnest(wp.languages)::text))
      OR (p.language::text = p_language)
    )
    AND (
      p_availability IS NULL 
      OR p_availability = '' 
      OR p_availability = 'all' 
      OR wp.availability::text = p_availability
    )
    AND (
      p_min_rate_paise IS NULL 
      OR COALESCE(wp.daily_rate_paise, wp.hourly_rate_paise * 8, 0) >= p_min_rate_paise
    )
    AND (
      p_max_rate_paise IS NULL 
      OR COALESCE(wp.daily_rate_paise, wp.hourly_rate_paise * 8, 99999999) <= p_max_rate_paise
    )
    AND (
      p_gender IS NULL 
      OR p_gender = '' 
      OR p_gender = 'any' 
      OR p.gender = p_gender
    )
    AND (p_min_rating IS NULL OR wp.rating_avg >= p_min_rating)
    AND (p_min_jobs_completed IS NULL OR wp.jobs_completed >= p_min_jobs_completed)
    AND (p_verified_only = false OR wp.is_verified_badge = true)
    AND (
      p_search_query IS NULL 
      OR p_search_query = '' 
      OR p.full_name ILIKE '%' || p_search_query || '%' 
      OR wp.headline ILIKE '%' || p_search_query || '%'
      OR wp.bio ILIKE '%' || p_search_query || '%'
    )
  ORDER BY
    -- Repeat, well-rated connections and favourites ranked first without hiding others
    (
      v_uid IS NOT NULL AND (
        EXISTS (
          SELECT 1 FROM public.favourites fav 
          WHERE fav.user_id = v_uid AND fav.target_id = wp.user_id
        )
        OR EXISTS (
          SELECT 1 FROM public.job_assignments ja
          JOIN public.jobs j ON ja.job_id = j.id
          WHERE j.provider_id = v_uid 
            AND ja.worker_id = wp.user_id 
            AND ja.status IN ('completed', 'payment_released')
            AND wp.rating_avg >= 4.0
        )
      )
    ) DESC,
    distance_m ASC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;
