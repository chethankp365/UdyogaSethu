import { getServiceClient } from './supabase.ts';
import { errorResponse } from './response.ts';
import { logWarn } from './logger.ts';

// In-memory fallback map when DB rate limiting is unavailable or for local dev
const memoryStore = new Map<string, { count: number; resetTime: number }>();

export async function checkRateLimit(
  identifier: string,
  action: string,
  limit = 30,
  windowSeconds = 60
): Promise<{ allowed: boolean; errorResponse?: Response }> {
  const key = `${action}:${identifier}`;
  const now = Date.now();

  try {
    const supabase = getServiceClient();
    const windowStart = new Date(now - windowSeconds * 1000).toISOString();

    // Query rate_limits table if present
    const { count, error } = await supabase
      .from('rate_limits')
      .select('id', { count: 'exact', head: true })
      .eq('key', key)
      .gte('created_at', windowStart);

    if (!error && count !== null) {
      if (count >= limit) {
        logWarn('rate_limit_exceeded', { key, count, limit });
        return {
          allowed: false,
          errorResponse: errorResponse('rate_limit_exceeded', 'Too many requests. Please try again later.', 429),
        };
      }

      // Record request entry
      await supabase.from('rate_limits').insert({ key, created_at: new Date().toISOString() });
      return { allowed: true };
    }
  } catch (_dbErr) {
    // Fallback to in-memory rate limiting
  }

  // Fallback in-memory rate limiter
  const record = memoryStore.get(key);
  if (!record || now > record.resetTime) {
    memoryStore.set(key, { count: 1, resetTime: now + windowSeconds * 1000 });
    return { allowed: true };
  }

  if (record.count >= limit) {
    logWarn('rate_limit_exceeded_memory', { key, count: record.count, limit });
    return {
      allowed: false,
      errorResponse: errorResponse('rate_limit_exceeded', 'Too many requests. Please try again later.', 429),
    };
  }

  record.count += 1;
  return { allowed: true };
}
