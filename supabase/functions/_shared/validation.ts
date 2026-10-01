import { errorResponse } from './response.ts';

export async function validateBody<T extends object = Record<string, unknown>>(
  req: Request,
  requiredFields: string[] = []
): Promise<{ data?: T; errorResponse?: Response }> {
  try {
    const text = await req.text();
    if (!text || text.trim() === '') {
      if (requiredFields.length > 0) {
        return {
          errorResponse: errorResponse('invalid_body', 'Request body cannot be empty', 400),
        };
      }
      return { data: {} as T };
    }

    const data = JSON.parse(text) as T;
    const recordData = data as Record<string, unknown>;

    const missing = requiredFields.filter((field) => !(field in recordData) || recordData[field] === undefined || recordData[field] === null);
    if (missing.length > 0) {
      return {
        errorResponse: errorResponse('validation_error', `Missing required fields: ${missing.join(', ')}`, 400, { missing }),
      };
    }

    return { data };
  } catch (err) {
    return {
      errorResponse: errorResponse('invalid_json', 'Malformed JSON payload in request body', 400, err instanceof Error ? err.message : String(err)),
    };
  }
}
