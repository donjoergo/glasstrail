import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { env } from './env.js';

export function createAdminClient(): SupabaseClient {
  return createClient(env.supabaseUrl, env.supabaseServiceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}
