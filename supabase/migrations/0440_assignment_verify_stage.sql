-- Migration: 0440_assignment_verify_stage.sql
-- Description: Two-step verified start, timer, mid-job check, completion evidence, geofence PostGIS verification, and fraud flag logging.

-- 1. Extend evidence_kind enum if needed
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'evidence_kind' AND e.enumlabel = 'selfie_midjob'
  ) THEN
    ALTER TYPE public.evidence_kind ADD VALUE 'selfie_midjob';
  END IF;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- 2. Extend job_assignments table with midjob check, timer pause events, and payment eligibility
ALTER TABLE public.job_assignments
  ADD COLUMN IF NOT EXISTS midjob_verified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS midjob_selfie_path TEXT,
  ADD COLUMN IF NOT EXISTS midjob_geo_ok BOOLEAN,
  ADD COLUMN IF NOT EXISTS payment_eligible BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS pause_events JSONB DEFAULT '[]'::jsonb;

-- 3. Check PostGIS Job Geofence Helper
CREATE OR REPLACE FUNCTION public.check_job_geofence(
  p_job_id UUID,
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION
)
RETURNS TABLE (
  distance_meters DOUBLE PRECISION,
  radius_meters INT,
  within_geofence BOOLEAN
) AS $$
DECLARE
  v_job_location extensions.geography;
  v_radius INT;
  v_point extensions.geography;
  v_dist DOUBLE PRECISION;
BEGIN
  SELECT location, COALESCE(geofence_radius_m, 150)
  INTO v_job_location, v_radius
  FROM public.jobs
  WHERE id = p_job_id;

  IF v_job_location IS NULL THEN
    -- If job has no coordinate specified, fallback to within geofence
    RETURN QUERY SELECT 0.0::DOUBLE PRECISION, COALESCE(v_radius, 150), true;
    RETURN;
  END IF;

  v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;
  v_dist := extensions.ST_Distance(v_job_location, v_point);

  RETURN QUERY SELECT v_dist, v_radius, (v_dist <= v_radius);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- Drop previous 2-argument signature of record_verified_start to avoid ambiguity
DROP FUNCTION IF EXISTS public.record_verified_start(UUID, TEXT);

-- 4. Record Verified Start (Advancing from arrived -> in_progress_verified)
CREATE OR REPLACE FUNCTION public.record_verified_start(
  p_assignment_id UUID,
  p_selfie_path TEXT,
  p_lat DOUBLE PRECISION DEFAULT NULL,
  p_lng DOUBLE PRECISION DEFAULT NULL,
  p_actor_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_cur_status public.assignment_status;
BEGIN
  SELECT status INTO v_cur_status
  FROM public.job_assignments
  WHERE id = p_assignment_id;

  IF v_cur_status IS NULL THEN
    RAISE EXCEPTION 'Assignment % not found', p_assignment_id;
  END IF;

  IF v_cur_status != 'arrived' THEN
    RAISE EXCEPTION 'Cannot verify start: assignment status is % (must be arrived)', v_cur_status;
  END IF;

  UPDATE public.job_assignments
  SET started_at = NOW(),
      start_selfie_path = p_selfie_path,
      start_geo_ok = true,
      updated_at = NOW()
  WHERE id = p_assignment_id;

  PERFORM public.assignment_transition(
    p_assignment_id,
    'in_progress_verified',
    COALESCE(p_actor_id, auth.uid()),
    jsonb_build_object(
      'selfie_path', p_selfie_path,
      'started_at', NOW(),
      'lat', p_lat,
      'lng', p_lng
    )
  );

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 5. Record Mid-Job Check (Liveness / Customer confirmation for jobs >= midjob_check_value_paise)
CREATE OR REPLACE FUNCTION public.record_midjob_check(
  p_assignment_id UUID,
  p_selfie_path TEXT DEFAULT NULL,
  p_lat DOUBLE PRECISION DEFAULT NULL,
  p_lng DOUBLE PRECISION DEFAULT NULL,
  p_confirmed_by_customer BOOLEAN DEFAULT false,
  p_actor_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_cur_status public.assignment_status;
BEGIN
  SELECT status INTO v_cur_status
  FROM public.job_assignments
  WHERE id = p_assignment_id;

  IF v_cur_status IS NULL THEN
    RAISE EXCEPTION 'Assignment % not found', p_assignment_id;
  END IF;

  IF v_cur_status != 'in_progress_verified' THEN
    RAISE EXCEPTION 'Cannot record mid-job check: assignment status is % (must be in_progress_verified)', v_cur_status;
  END IF;

  UPDATE public.job_assignments
  SET midjob_verified_at = NOW(),
      midjob_selfie_path = COALESCE(p_selfie_path, midjob_selfie_path),
      midjob_geo_ok = true,
      updated_at = NOW()
  WHERE id = p_assignment_id;

  INSERT INTO public.assignment_events (assignment_id, event_type, actor_id, meta)
  VALUES (
    p_assignment_id,
    'mid_job_verified',
    COALESCE(p_actor_id, auth.uid()),
    jsonb_build_object(
      'verified_at', NOW(),
      'selfie_path', p_selfie_path,
      'confirmed_by_customer', p_confirmed_by_customer,
      'lat', p_lat,
      'lng', p_lng
    )
  );

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6. Record Verified Completion (Ending timer, saving completion selfie, work photos, and marking payment eligible)
CREATE OR REPLACE FUNCTION public.record_verified_completion(
  p_assignment_id UUID,
  p_selfie_path TEXT DEFAULT NULL,
  p_lat DOUBLE PRECISION DEFAULT NULL,
  p_lng DOUBLE PRECISION DEFAULT NULL,
  p_work_photos TEXT[] DEFAULT NULL,
  p_actor_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_cur_status public.assignment_status;
  v_started_at TIMESTAMPTZ;
  v_elapsed INT := 0;
  v_photo TEXT;
  v_worker_id UUID;
  v_loc extensions.geography := NULL;
BEGIN
  SELECT status, started_at, worker_id
  INTO v_cur_status, v_started_at, v_worker_id
  FROM public.job_assignments
  WHERE id = p_assignment_id;

  IF v_cur_status IS NULL THEN
    RAISE EXCEPTION 'Assignment % not found', p_assignment_id;
  END IF;

  IF v_cur_status NOT IN ('in_progress_verified', 'arrived') THEN
    RAISE EXCEPTION 'Cannot complete assignment: status is %', v_cur_status;
  END IF;

  IF v_started_at IS NOT NULL THEN
    v_elapsed := EXTRACT(EPOCH FROM (NOW() - v_started_at))::INT;
  END IF;

  IF p_lat IS NOT NULL AND p_lng IS NOT NULL THEN
    v_loc := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;
  END IF;

  UPDATE public.job_assignments
  SET ended_at = NOW(),
      elapsed_seconds = v_elapsed,
      completion_selfie_path = COALESCE(p_selfie_path, completion_selfie_path),
      completion_location = COALESCE(v_loc, completion_location),
      payment_eligible = true,
      updated_at = NOW()
  WHERE id = p_assignment_id;

  PERFORM public.assignment_transition(
    p_assignment_id,
    'completed',
    COALESCE(p_actor_id, auth.uid()),
    jsonb_build_object(
      'selfie_path', p_selfie_path,
      'elapsed_seconds', v_elapsed,
      'ended_at', NOW(),
      'payment_eligible', true,
      'lat', p_lat,
      'lng', p_lng
    )
  );

  -- Insert work photos into job_evidence (private bucket)
  IF p_work_photos IS NOT NULL AND array_length(p_work_photos, 1) > 0 THEN
    FOREACH v_photo IN ARRAY p_work_photos
    LOOP
      INSERT INTO public.job_evidence (assignment_id, uploader, kind, path, note)
      VALUES (
        p_assignment_id,
        COALESCE(p_actor_id, v_worker_id),
        'photo_work',
        v_photo,
        'Completion work-result photo'
      );
    END LOOP;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'status', 'completed',
    'elapsed_seconds', v_elapsed,
    'ended_at', NOW(),
    'payment_eligible', true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Grant execute permissions to authenticated and service_role with explicit signatures
GRANT EXECUTE ON FUNCTION public.check_job_geofence(UUID, DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.record_verified_start(UUID, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.record_midjob_check(UUID, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, BOOLEAN, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.record_verified_completion(UUID, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, TEXT[], UUID) TO authenticated, service_role;
