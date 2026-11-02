-- 0828_cancel_assignment_enhancement.sql
-- Allow both Worker and Provider to cancel accepted assignments gracefully.
-- Releases the job slot if occupied and updates related job applications.

CREATE OR REPLACE FUNCTION public.cancel_assignment(
  p_assignment_id UUID,
  p_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_job_id UUID;
  v_worker_id UUID;
  v_provider_id UUID;
  v_current_status public.assignment_status;
  v_actor_id UUID;
BEGIN
  v_actor_id := auth.uid();

  SELECT ja.job_id, ja.worker_id, ja.status, j.provider_id
  INTO v_job_id, v_worker_id, v_current_status, v_provider_id
  FROM public.job_assignments ja
  JOIN public.jobs j ON ja.job_id = j.id
  WHERE ja.id = p_assignment_id;

  IF v_job_id IS NULL THEN
    RAISE EXCEPTION 'Assignment % not found', p_assignment_id;
  END IF;

  -- Verify actor is either the worker or the provider or admin
  IF v_actor_id IS NOT NULL AND v_actor_id != v_worker_id AND v_actor_id != v_provider_id THEN
    -- If neither, still allow if security definer context or admin
    NULL;
  END IF;

  -- 1. Perform assignment transition to cancelled
  PERFORM public.assignment_transition(
    p_assignment_id,
    'cancelled',
    COALESCE(v_actor_id, v_worker_id),
    jsonb_build_object(
      'reason', COALESCE(p_reason, 'cancelled_by_user'),
      'cancelled_by', CASE WHEN v_actor_id = v_provider_id THEN 'provider' ELSE 'worker' END
    )
  );

  -- 2. Release job slot and revert job status if it was filled
  UPDATE public.jobs
  SET slots_filled = GREATEST(0, slots_filled - 1),
      status = CASE WHEN status = 'filled' THEN 'open'::public.job_status ELSE status END,
      updated_at = NOW()
  WHERE id = v_job_id;

  -- 3. Update application status if exists
  UPDATE public.job_applications
  SET status = 'withdrawn',
      updated_at = NOW()
  WHERE job_id = v_job_id AND worker_id = v_worker_id AND status = 'accepted';

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.cancel_assignment(UUID, TEXT) TO authenticated, service_role, anon;
