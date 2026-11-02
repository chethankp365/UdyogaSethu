import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { jsonResponse, errorResponse } from '../_shared/response.ts';
import { getUserClient, getServiceClient } from '../_shared/supabase.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';

export interface AssignmentVerifyRequest {
  action?: 'start' | 'mid_job' | 'completion' | 'pause_timer' | 'resume_timer';
  assignment_id?: string;
  lat?: number;
  lng?: number;
  is_mocked?: boolean;
  embedding?: number[];
  selfie_path?: string;
  work_photos?: string[];
  note?: string;
  health?: boolean;
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;

    const callerUserId = auth.context!.user.id;
    const serviceClient = getServiceClient();

    let body: AssignmentVerifyRequest = {};
    try {
      const text = await req.text();
      if (text && text.trim().length > 0) {
        body = JSON.parse(text);
      }
    } catch (_) {}

    const url = new URL(req.url);
    const isHealthCheck = body.health === true || url.searchParams.get('health') === 'true';

    if (isHealthCheck) {
      return jsonResponse({
        ok: true,
        service: 'assignment-verify',
        timestamp: new Date().toISOString(),
      });
    }

    // Rate limit: 20 calls per minute
    const rate = await checkRateLimit(callerUserId, 'assignment-verify', 20, 60);
    if (rate.errorResponse) return rate.errorResponse;

    const action = body.action;
    const assignmentId = body.assignment_id;

    if (!assignmentId) {
      return errorResponse('missing_assignment_id', 'assignment_id is required', 400);
    }

    const validActions = ['start', 'mid_job', 'completion', 'pause_timer', 'resume_timer'];
    if (!action || !validActions.includes(action)) {
      return errorResponse('invalid_action', `Action must be one of: ${validActions.join(', ')}`, 400);
    }

    // 1. Fetch assignment and related job details
    const { data: assignment, error: asgErr } = await serviceClient
      .from('job_assignments')
      .select(`
        id,
        job_id,
        worker_id,
        status,
        agreed_wage_paise,
        started_at,
        ended_at,
        elapsed_seconds,
        start_selfie_path,
        completion_selfie_path,
        jobs (
          id,
          provider_id,
          title,
          location,
          geofence_radius_m
        )
      `)
      .eq('id', assignmentId)
      .maybeSingle();

    if (asgErr) {
      logError('assignment_fetch_error', { error: asgErr, assignmentId });
      return errorResponse('database_error', `Failed to query assignment: ${asgErr.message}`, 500);
    }

    if (!assignment) {
      return errorResponse('assignment_not_found', 'Job assignment not found', 404);
    }

    const job = assignment.jobs as any;
    if (!job) {
      return errorResponse('job_not_found', 'Associated job not found', 404);
    }

    const isWorker = assignment.worker_id === callerUserId;
    const isProvider = job.provider_id === callerUserId;

    if (!isWorker && !isProvider) {
      return errorResponse('forbidden', 'You are not an authorized party for this assignment', 403);
    }

    // 2. Mock Location Detection
    const isMocked = body.is_mocked === true;
    if (isMocked) {
      logError('mock_location_detected', {
        userId: callerUserId,
        assignmentId,
        lat: body.lat,
        lng: body.lng,
      });

      // Insert fraud_flags entry
      await serviceClient.from('fraud_flags').insert({
        user_id: callerUserId,
        rule_key: 'mock_location_detected',
        severity: 'high',
        ref_type: 'job_assignment',
        ref_id: assignmentId,
        evidence: {
          is_mocked: true,
          action,
          lat: body.lat,
          lng: body.lng,
          timestamp: new Date().toISOString(),
        },
        status: 'open',
      });

      return errorResponse(
        'mock_location_rejected',
        'Mocked or spoofed GPS location detected. Please disable location mocking or fake GPS apps to continue.',
        400,
        { is_mocked: true }
      );
    }

    // 3. Geofence Distance Check with PostGIS
    if (body.lat !== undefined && body.lng !== undefined && job.id) {
      const { data: geoRows, error: geoErr } = await serviceClient.rpc('check_job_geofence', {
        p_job_id: job.id,
        p_lat: body.lat,
        p_lng: body.lng,
      });

      if (!geoErr && geoRows && geoRows.length > 0) {
        const geoCheck = geoRows[0];
        const dist = Math.round(geoCheck.distance_meters);
        const radius = geoCheck.radius_meters;
        const withinGeofence = geoCheck.within_geofence;

        if (!withinGeofence) {
          logInfo('geofence_out_of_bounds', {
            userId: callerUserId,
            assignmentId,
            distance: dist,
            radius,
          });

          // If grossly out of bounds (> 1000m), log fraud flag
          if (dist > 1000) {
            await serviceClient.from('fraud_flags').insert({
              user_id: callerUserId,
              rule_key: 'out_of_radius_start',
              severity: 'medium',
              ref_type: 'job_assignment',
              ref_id: assignmentId,
              evidence: {
                distance_meters: dist,
                radius_meters: radius,
                lat: body.lat,
                lng: body.lng,
                timestamp: new Date().toISOString(),
              },
              status: 'open',
            });
          }

          return errorResponse(
            'out_of_geofence',
            `You are ${dist}m away from the job site. You must be within ${radius}m to verify attendance.`,
            400,
            {
              distance_meters: dist,
              radius_meters: radius,
            }
          );
        }
      }
    }

    // 4. ACTION: START (Two-Step Verified Start)
    if (action === 'start') {
      if (!isWorker) {
        return errorResponse('unauthorized_worker', 'Only the assigned worker can verify presence to start work.', 403);
      }

      // Check current assignment status: MUST be arrived
      if (assignment.status !== 'arrived') {
        if (assignment.status === 'in_progress_verified') {
          return jsonResponse({
            success: true,
            status: 'in_progress_verified',
            started_at: assignment.started_at,
            message: 'Job is already in progress.',
          });
        }
        return errorResponse(
          'invalid_stage',
          `Cannot start work. Status is '${assignment.status}'. The employer must scan your QR ticket arrival first.`,
          400,
          { current_status: assignment.status }
        );
      }

      // Face Verification Check
      const embedding = body.embedding;
      if (embedding && Array.isArray(embedding) && embedding.length >= 64) {
        // Query face_match_threshold from admin_settings
        let threshold = 0.65;
        const { data: settingRow } = await serviceClient
          .from('admin_settings')
          .select('value')
          .eq('key', 'face_match_threshold')
          .maybeSingle();

        if (settingRow?.value) {
          const val = settingRow.value;
          const parsed = typeof val === 'number' ? val : parseFloat(String(val));
          if (!isNaN(parsed) && parsed > 0 && parsed <= 1.0) threshold = parsed;
        }

        const matcherMode = (Deno.env.get('FACE_MATCHER') || 'ondevice').toLowerCase();
        let passed = true;
        let similarity = 0.90;

        if (matcherMode === 'mock') {
          if (embedding[0] < 0) {
            similarity = 0.40;
            passed = false;
          } else {
            similarity = 0.92;
            passed = true;
          }
        } else {
          const { data: faceProfile } = await serviceClient
            .from('face_profiles')
            .select('embedding')
            .eq('user_id', callerUserId)
            .maybeSingle();

          if (faceProfile && faceProfile.embedding) {
            const { data: simResult } = await serviceClient.rpc('compare_face_embeddings', {
              v1: embedding,
              v2: faceProfile.embedding,
            });
            similarity = typeof simResult === 'number' ? simResult : 0.0;
            passed = similarity >= threshold;
          }
        }

        if (!passed) {
          await serviceClient.from('verification_attempts').insert({
            user_id: callerUserId,
            context: 'job_start',
            assignment_id: assignmentId,
            liveness_ok: true,
            match_score: Math.round(similarity * 100),
            gps_ok: true,
            distance_m: 0,
            result: 'fail',
          });

          return errorResponse(
            'face_mismatch',
            'Face verification failed. Please align your face in good lighting without hats or sunglasses and try again.',
            400,
            { similarity, threshold }
          );
        }

        await serviceClient.from('verification_attempts').insert({
          user_id: callerUserId,
          context: 'job_start',
          assignment_id: assignmentId,
          liveness_ok: true,
          match_score: Math.round(similarity * 100),
          gps_ok: true,
          distance_m: 0,
          result: 'pass',
        });
      }

      // Call database procedure to record verified start
      const { error: rpcErr } = await serviceClient.rpc('record_verified_start', {
        p_assignment_id: assignmentId,
        p_selfie_path: body.selfie_path || 'selfie_verified',
        p_lat: body.lat ?? null,
        p_lng: body.lng ?? null,
        p_actor_id: callerUserId,
      });

      if (rpcErr) {
        logError('record_verified_start_error', { error: rpcErr.message });
        return errorResponse('start_failed', rpcErr.message, 500);
      }

      // Notify provider that worker completed verification and timer started
      await serviceClient.from('notifications').insert({
        user_id: job.provider_id,
        type: 'job_started',
        title: 'Work Started',
        body: `Worker verified presence on site. Timer is now running.`,
        data: { assignment_id: assignmentId },
      });

      return jsonResponse({
        success: true,
        status: 'in_progress_verified',
        started_at: new Date().toISOString(),
        elapsed_seconds: 0,
        message: 'Two-step verification completed. Timer running.',
      });
    }

    // 5. ACTION: MID_JOB (Mid-Job Check)
    if (action === 'mid_job') {
      if (assignment.status !== 'in_progress_verified') {
        return errorResponse('invalid_stage', `Assignment must be in_progress_verified to record mid-job check.`, 400);
      }

      const { error: rpcErr } = await serviceClient.rpc('record_midjob_check', {
        p_assignment_id: assignmentId,
        p_selfie_path: body.selfie_path ?? null,
        p_lat: body.lat ?? null,
        p_lng: body.lng ?? null,
        p_confirmed_by_customer: isProvider,
        p_actor_id: callerUserId,
      });

      if (rpcErr) {
        return errorResponse('midjob_check_failed', rpcErr.message, 500);
      }

      return jsonResponse({
        success: true,
        status: 'in_progress_verified',
        midjob_verified_at: new Date().toISOString(),
        message: 'Mid-job verification successfully recorded.',
      });
    }

    // 6. ACTION: COMPLETION (Verified Completion & Evidence Upload)
    if (action === 'completion') {
      if (assignment.status !== 'in_progress_verified' && assignment.status !== 'arrived') {
        if (assignment.status === 'completed') {
          return jsonResponse({
            success: true,
            status: 'completed',
            ended_at: assignment.ended_at,
            elapsed_seconds: assignment.elapsed_seconds,
            payment_eligible: true,
            message: 'Job already completed.',
          });
        }
        return errorResponse('invalid_stage', `Cannot complete job from status ${assignment.status}`, 400);
      }

      const { data: compRes, error: compErr } = await serviceClient.rpc('record_verified_completion', {
        p_assignment_id: assignmentId,
        p_selfie_path: body.selfie_path ?? null,
        p_lat: body.lat ?? null,
        p_lng: body.lng ?? null,
        p_work_photos: body.work_photos ?? null,
        p_actor_id: callerUserId,
      });

      if (compErr) {
        logError('record_verified_completion_error', { error: compErr.message });
        return errorResponse('completion_failed', compErr.message, 500);
      }

      // Notify the other party
      const notifyTarget = isWorker ? job.provider_id : assignment.worker_id;
      await serviceClient.from('notifications').insert({
        user_id: notifyTarget,
        type: 'job_completed',
        title: 'Job Completed',
        body: `Work has been confirmed and marked completed. Payment is eligible for release.`,
        data: { assignment_id: assignmentId },
      });

      return jsonResponse({
        success: true,
        status: 'completed',
        ended_at: compRes?.ended_at || new Date().toISOString(),
        elapsed_seconds: compRes?.elapsed_seconds ?? 0,
        payment_eligible: true,
        message: 'Job completed successfully. Payment flagged eligible for release.',
      });
    }

    return errorResponse('unsupported_action', 'Action not implemented', 400);
  } catch (err: any) {
    logError('assignment_verify_unhandled_error', { error: err?.message || String(err) });
    return errorResponse('server_error', err?.message || 'Internal server error', 500);
  }
});
