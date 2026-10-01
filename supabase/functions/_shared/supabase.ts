import { createClient, SupabaseClient, User } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { errorResponse } from './response.ts';

export interface UserAuthContext {
  supabase: SupabaseClient;
  user: User;
  token: string;
}

export function getServiceClient(): SupabaseClient {
  const url = Deno.env.get('SUPABASE_URL');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

  if (!url || !serviceKey) {
    throw new Error('SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is missing from environment');
  }

  return createClient(url, serviceKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
}

export async function getUserClient(req: Request): Promise<{ context?: UserAuthContext; errorResponse?: Response }> {
  const authHeader = req.headers.get('Authorization');

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return {
      errorResponse: errorResponse('unauthorized', 'Missing or invalid Authorization header', 401),
    };
  }

  const token = authHeader.replace('Bearer ', '').trim();
  const url = Deno.env.get('SUPABASE_URL') ?? '';
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';

  const supabase = createClient(url, anonKey, {
    global: {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    },
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  const { data: { user }, error } = await supabase.auth.getUser(token);

  if (error || !user) {
    return {
      errorResponse: errorResponse('unauthorized', 'Invalid or expired user JWT', 401, error?.message),
    };
  }

  return {
    context: {
      supabase,
      user,
      token,
    },
  };
}
