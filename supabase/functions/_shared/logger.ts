// Structured logging helper with sensitive data scrubbing

function redact(obj: unknown): unknown {
  if (typeof obj === 'string') {
    return obj
      .replace(/Bearer\s+[A-Za-z0-9-_=.]+/g, 'Bearer [REDACTED]')
      .replace(/\b\d{12}\b/g, '[AADHAAR_REDACTED]')
      .replace(/\b[A-Z]{5}\d{4}[A-Z]\b/g, '[PAN_REDACTED]')
      .replace(/\b\+?91[6-9]\d{9}\b/g, '[PHONE_REDACTED]')
      .replace(/\b[6-9]\d{9}\b/g, '[PHONE_REDACTED]');
  }

  if (Array.isArray(obj)) {
    return obj.map(redact);
  }

  if (obj !== null && typeof obj === 'object') {
    const cleansed: Record<string, unknown> = {};
    for (const [key, value] of Object.entries(obj as Record<string, unknown>)) {
      const lowerKey = key.toLowerCase();
      if (
        lowerKey.includes('token') ||
        lowerKey.includes('secret') ||
        lowerKey.includes('password') ||
        lowerKey.includes('auth') ||
        lowerKey.includes('aadhaar') ||
        lowerKey.includes('pan') ||
        lowerKey.includes('phone')
      ) {
        cleansed[key] = '[REDACTED]';
      } else {
        cleansed[key] = redact(value);
      }
    }
    return cleansed;
  }

  return obj;
}

export function logInfo(action: string, context?: Record<string, unknown>): void {
  console.log(JSON.stringify({
    level: 'INFO',
    timestamp: new Date().toISOString(),
    action,
    context: redact(context),
  }));
}

export function logWarn(action: string, context?: Record<string, unknown>): void {
  console.warn(JSON.stringify({
    level: 'WARN',
    timestamp: new Date().toISOString(),
    action,
    context: redact(context),
  }));
}

export function logError(action: string, error: unknown, context?: Record<string, unknown>): void {
  console.error(JSON.stringify({
    level: 'ERROR',
    timestamp: new Date().toISOString(),
    action,
    error: error instanceof Error ? { message: error.message, stack: error.stack } : redact(error),
    context: redact(context),
  }));
}
