import { config as loadEnv } from 'dotenv';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
loadEnv({ path: path.resolve(__dirname, '..', '.env') });

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value || value.trim() === '') {
    throw new Error(
      `Missing required environment variable: ${name}. Copy tool/screenshots/.env.example to tool/screenshots/.env and fill it in.`,
    );
  }
  return value.trim();
}

export const env = {
  supabaseUrl: requireEnv('SUPABASE_URL'),
  supabaseServiceRoleKey: requireEnv('SUPABASE_SERVICE_ROLE_KEY'),
  demoPrimaryEmail: requireEnv('DEMO_PRIMARY_EMAIL'),
  demoPrimaryPassword: requireEnv('DEMO_PRIMARY_PASSWORD'),
  demoFriendEmail: requireEnv('DEMO_FRIEND_EMAIL'),
  demoFriendPassword: requireEnv('DEMO_FRIEND_PASSWORD'),
  captureBaseUrl: (process.env.CAPTURE_BASE_URL?.trim() || 'https://glasstrail.vercel.app'),
};
