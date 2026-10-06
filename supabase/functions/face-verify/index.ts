import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse, jsonResponse } from '../_shared/response.ts';
import { getUserClient, getServiceClient } from '../_shared/supabase.ts';
import { validateBody } from '../_shared/validation.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';

export interface FaceVerifyRequest {
  embedding: number[];
  context: 'login' | 'job_start' | 'mid_job' | 'completion';
  assignment_id?: string;
  gps_ok?: boolean;
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;

    const userId = auth.context!.user.id;

    // Rate limit: 10 calls per minute per user
    const rate = await checkRateLimit(userId, 'face-verify', 10, 60);
    if (rate.errorResponse) return rate.errorResponse;

    const validation = await validateBody<FaceVerifyRequest>(req, ['embedding', 'context']);
    if (validation.errorResponse) return validation.errorResponse;

    const { embedding, context, assignment_id, gps_ok } = validation.data!;

    if (!Array.isArray(embedding) || embedding.length < 64) {
      return errorResponse('invalid_embedding', 'Embedding vector must be an array of numbers with length >= 64', 400);
    }

    const validContexts = ['login', 'job_start', 'mid_job', 'completion'];
    if (!validContexts.includes(context)) {
      return errorResponse('invalid_context', `Context must be one of: ${validContexts.join(', ')}`, 400);
    }

    // Determine explicit gps_ok boolean per context:
    // - 'login': true (documented as "not applicable" for login context since no geofence check occurs)
    // - 'job_start', 'mid_job', 'completion': explicit gps_ok from request body (or false if missing)
    let explicitGpsOk = false;
    if (context === 'login') {
      explicitGpsOk = true; // Not applicable for login context
    } else {
      explicitGpsOk = gps_ok ?? false;
    }

    const serviceClient = getServiceClient();

    // 1. Fetch face_match_threshold from admin_settings using real schema (key, value)
    let threshold = 0.65;
    const { data: settingRow } = await serviceClient
      .from('admin_settings')
      .select('key, value')
      .eq('key', 'face_match_threshold')
      .maybeSingle();

    if (settingRow?.value !== undefined && settingRow?.value !== null) {
      const val = settingRow.value;
      if (typeof val === 'number') {
        threshold = val;
      } else if (typeof val === 'string') {
        const parsed = parseFloat(val);
        if (!isNaN(parsed) && parsed > 0 && parsed <= 1.0) threshold = parsed;
      } else if (typeof val === 'object' && val !== null) {
        const parsed = parseFloat(String(val));
        if (!isNaN(parsed) && parsed > 0 && parsed <= 1.0) threshold = parsed;
      }
    }

    const matcherMode = (Deno.env.get('FACE_MATCHER') || 'ondevice').toLowerCase();
    logInfo('face_verify_start', { userId, context, matcherMode, threshold, gpsOk: explicitGpsOk });

    let similarity = 0.0;
    let passed = false;

    if (matcherMode === 'mock') {
      // Mock matcher mode for testing
      // If first element of embedding is negative, simulate a fail
      if (embedding.length > 0 && embedding[0] < 0) {
        similarity = 0.40;
        passed = false;
      } else {
        similarity = 0.92;
        passed = true;
      }
    } else {
      // On-device matcher mode: compare embedding with stored enrolled embedding
      const { data: faceProfile, error: profileErr } = await serviceClient
        .from('face_profiles')
        .select('embedding, status')
        .eq('user_id', userId)
        .maybeSingle();

      if (profileErr || !faceProfile || !faceProfile.embedding) {
        logInfo('face_verify_no_enrolled_profile', { userId });
        // Log attempt as failed with explicit gps_ok
        await serviceClient.from('verification_attempts').insert({
          user_id: userId,
          context: context,
          assignment_id: assignment_id || null,
          liveness_ok: true,
          match_score: 0.00,
          gps_ok: explicitGpsOk,
          result: 'fail',
        });

        return jsonResponse({
          result: 'fail',
          match_score: 0.0,
          similarity: 0.0,
          threshold: threshold,
          message: 'No enrolled face profile found. Please complete face enrollment first.',
          fraud_flag_created: false,
          attempts_count: 1,
          needs_enrollment: true,
        });
      }

      // Call compare_face_embeddings RPC
      const { data: simResult, error: simErr } = await serviceClient.rpc('compare_face_embeddings', {
        v1: embedding,
        v2: faceProfile.embedding,
      });

      if (simErr) {
        logError('face_verify_rpc_error', simErr);
        return errorResponse('database_error', 'Failed to compare face embeddings', 500);
      }

      similarity = typeof simResult === 'number' ? simResult : 0.0;
      passed = similarity >= threshold;
    }

    const matchScorePercent = Math.min(100.0, Math.max(0.0, similarity * 100.0));

    // 2. Query previous recent consecutive fails for user
    const { data: recentAttempts } = await serviceClient
      .from('verification_attempts')
      .select('result, created_at')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(10);

    let consecutiveFails = 0;
    if (recentAttempts && recentAttempts.length > 0) {
      for (const attempt of recentAttempts) {
        if (attempt.result === 'pass') {
          break;
        }
        if (attempt.result === 'fail' || attempt.result === 'manual_review_required') {
          consecutiveFails++;
        }
      }
    }

    const newConsecutiveFails = passed ? 0 : consecutiveFails + 1;

    let result: 'pass' | 'fail' | 'manual_review_required' = 'fail';
    if (passed) {
      result = 'pass';
    } else if (newConsecutiveFails >= 3) {
      result = 'manual_review_required';
    } else {
      result = 'fail';
    }

    // 3. Insert verification_attempts log row with explicit gps_ok
    const { error: insertAttemptErr } = await serviceClient
      .from('verification_attempts')
      .insert({
        user_id: userId,
        context: context,
        assignment_id: assignment_id || null,
        liveness_ok: true,
        match_score: matchScorePercent,
        gps_ok: explicitGpsOk,
        result: result,
      });

    if (insertAttemptErr) {
      logError('verification_attempts_insert_error', insertAttemptErr);
    }

    let fraudFlagCreated = false;

    // 4. Create fraud_flags row on 3 consecutive fails
    if (!passed && newConsecutiveFails >= 3) {
      const { error: fraudErr } = await serviceClient
        .from('fraud_flags')
        .insert({
          user_id: userId,
          rule_key: 'repeated_face_fail',
          severity: 'high',
          ref_type: 'verification_attempt',
          evidence: {
            attempts: newConsecutiveFails,
            last_context: context,
            assignment_id: assignment_id || null,
            similarity: similarity,
            threshold: threshold,
          },
          status: 'open',
        });

      if (fraudErr) {
        logError('fraud_flags_insert_error', fraudErr);
      } else {
        fraudFlagCreated = true;
        logInfo('fraud_flag_created', { userId, ruleKey: 'repeated_face_fail', attempts: newConsecutiveFails });
      }
    }

    logInfo('face_verify_complete', {
      userId,
      passed,
      result,
      similarity,
      threshold,
      consecutiveFails: newConsecutiveFails,
      fraudFlagCreated,
    });

    return jsonResponse({
      result: result,
      match_score: matchScorePercent,
      similarity: similarity,
      threshold: threshold,
      message: passed
        ? 'Face identity verified successfully.'
        : result === 'manual_review_required'
        ? 'Three consecutive verification attempts failed. Account requires manual review.'
        : 'Face match score below threshold. Please try again.',
      fraud_flag_created: fraudFlagCreated,
      attempts_count: newConsecutiveFails,
    });

  } catch (err) {
    logError('face_verify_failed', err);
    return errorResponse('internal_error', 'Internal server error during face verification', 500);
  }
});
