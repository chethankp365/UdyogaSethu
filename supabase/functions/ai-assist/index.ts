import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse } from '../_shared/response.ts';
import { getUserClient } from '../_shared/supabase.ts';
import { validateBody } from '../_shared/validation.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';

export interface AiAssistRequest {
  prompt: string;
  context?: Record<string, unknown>;
  language?: string;
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;

    const rate = await checkRateLimit(auth.context!.user.id, 'ai-assist', 20, 60);
    if (rate.errorResponse) return rate.errorResponse;

    const validation = await validateBody<AiAssistRequest>(req, ['prompt']);
    if (validation.errorResponse) return validation.errorResponse;

    logInfo('ai_assist_requested', { userId: auth.context!.user.id, promptLength: validation.data!.prompt.length });

    // Note: Future implementation will use GEMINI_API_KEY and GEMINI_MODEL to invoke Gemini API.
    const _apiKey = Deno.env.get('GEMINI_API_KEY');
    const _model = Deno.env.get('GEMINI_MODEL') ?? 'gemini-1.5-flash';

    return errorResponse('not_implemented', 'AI assist feature with Gemini is not implemented yet', 501);
  } catch (err) {
    logError('ai_assist_failed', err);
    return errorResponse('internal_error', 'Internal server error', 500);
  }
});
