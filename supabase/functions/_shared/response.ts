import { corsHeaders } from './cors.ts';

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
    details?: unknown;
  };
}

export function jsonResponse<T>(data: T, status = 200): Response {
  const body: ApiResponse<T> = {
    success: true,
    data,
  };
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

export function errorResponse(code: string, message: string, status = 400, details?: unknown): Response {
  const body: ApiResponse = {
    success: false,
    error: {
      code,
      message,
      details,
    },
  };
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}
