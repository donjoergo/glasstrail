import { createClient } from 'jsr:@supabase/supabase-js@2';

type ProfileRow = {
  id: string;
  display_name: string | null;
  profile_image_path: string | null;
  profile_share_code: string;
};

const mediaBucket = 'user-media';
const defaultIconUrl = 'https://glasstrail.vercel.app/icons/Icon-512.png';
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
};

if (import.meta.main) {
  Deno.serve(async (request) => {
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    if (request.method !== 'GET' && request.method !== 'HEAD') {
      return jsonResponse({ error: 'method_not_allowed' }, 405);
    }

    const url = new URL(request.url);
    const route = parseRoute(url);
    if (route.code.length === 0) {
      return invalidResponse();
    }

    try {
      const profile = await loadProfile(route.code);
      if (profile == null) {
        return invalidResponse();
      }

      if (route.isImage) {
        return imageResponse(profile);
      }

      return jsonResponse(publicProfileJson(profile, request), 200);
    } catch (error) {
      console.error(error);
      return serverErrorResponse();
    }
  });
}

function parseRoute(url: URL): { code: string; isImage: boolean } {
  const parts = url.pathname.split('/').filter((part) => part.length > 0);
  const functionIndex = parts.lastIndexOf('friend-profile-preview');
  const relativeParts = functionIndex === -1
    ? parts
    : parts.slice(functionIndex + 1);
  const rawCode = relativeParts[0] ?? '';
  return {
    code: safeDecode(rawCode).trim(),
    isImage: relativeParts[1] === 'image',
  };
}

async function loadProfile(code: string): Promise<ProfileRow | null> {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')?.trim() ?? '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')?.trim() ??
    '';
  if (supabaseUrl.length === 0 || serviceRoleKey.length === 0) {
    throw new Error('Missing Supabase Edge Function configuration.');
  }

  const client = createClient(supabaseUrl, serviceRoleKey);
  const { data, error } = await client
    .from('profiles')
    .select('id, display_name, profile_image_path, profile_share_code')
    .eq('profile_share_code', code)
    .maybeSingle();

  if (error != null) {
    throw error;
  }
  return data as ProfileRow | null;
}

export function publicProfileJson(
  profile: ProfileRow,
  request: Request,
): Record<string, string | null> {
  return {
    id: profile.id,
    displayName: displayName(profile),
    profileImageUrl: publicProfileImageUrl(profile, request),
    profileShareCode: profile.profile_share_code,
  };
}

async function imageResponse(profile: ProfileRow): Promise<Response> {
  const fallbackUrl = iconUrl();
  const imagePath = profile.profile_image_path?.trim();
  if (imagePath == null) {
    return redirectResponse(fallbackUrl);
  }

  const remoteUrl = remoteProfileImageUrl(imagePath);
  if (remoteUrl != null) {
    return redirectResponse(remoteUrl);
  }

  if (!isSafeProfileImagePath(profile, imagePath)) {
    return redirectResponse(fallbackUrl);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')?.trim() ?? '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')?.trim() ??
    '';
  const client = createClient(supabaseUrl, serviceRoleKey);
  const { data, error } = await client.storage
    .from(mediaBucket)
    .createSignedUrl(imagePath, 60 * 10);

  if (error != null || data?.signedUrl == null) {
    return redirectResponse(fallbackUrl);
  }
  return redirectResponse(data.signedUrl);
}

function invalidResponse(): Response {
  return jsonResponse({ error: 'profile_not_found' }, 404);
}

function serverErrorResponse(): Response {
  return jsonResponse({ error: 'preview_unavailable' }, 500);
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'content-type': 'application/json; charset=utf-8',
      'cache-control': status === 200 ? 'public, max-age=300' : 'no-store',
    },
  });
}

function redirectResponse(location: string): Response {
  return new Response(null, {
    status: 302,
    headers: {
      ...corsHeaders,
      location,
      'cache-control': 'public, max-age=300',
    },
  });
}

function displayName(profile: ProfileRow): string {
  const value = profile.display_name?.trim() ?? '';
  return value.length === 0 ? 'Glass Trail User' : value;
}

function publicProfileImageUrl(
  profile: ProfileRow,
  request: Request,
): string | null {
  const imagePath = profile.profile_image_path?.trim() ?? '';
  if (imagePath.length === 0) {
    return null;
  }

  const remoteUrl = remoteProfileImageUrl(imagePath);
  if (remoteUrl != null) {
    return remoteUrl;
  }

  if (!isSafeProfileImagePath(profile, imagePath)) {
    return null;
  }

  return profileImageUrl(request);
}

function profileImageUrl(request: Request): string {
  const url = new URL(request.url);
  url.search = '';
  url.hash = '';
  if (url.protocol === 'http:' && !isLocalHost(url.hostname)) {
    url.protocol = 'https:';
  }
  if (
    isSupabaseRestHost(url.hostname) &&
    !url.pathname.startsWith('/functions/v1/')
  ) {
    url.pathname = `/functions/v1${url.pathname}`;
  }
  url.pathname = `${trimTrailingSlash(url.pathname)}/image`;
  return url.toString();
}

function iconUrl(): string {
  const configured = Deno.env.get('FRIEND_PROFILE_APP_ICON_URL')?.trim() ??
    Deno.env.get('FRIEND_PROFILE_APP_ICON_PATH')?.trim() ??
    '';
  if (configured.startsWith('http://') || configured.startsWith('https://')) {
    return configured;
  }
  return defaultIconUrl;
}

export function remoteProfileImageUrl(imagePath: string): string | null {
  try {
    const url = new URL(imagePath);
    if (url.protocol !== 'http:' && url.protocol !== 'https:') {
      return null;
    }
    if (url.protocol === 'http:' && !isLocalHost(url.hostname)) {
      url.protocol = 'https:';
    }
    return url.toString();
  } catch (_) {
    return null;
  }
}

function isSafeProfileImagePath(
  profile: ProfileRow,
  imagePath: string,
): boolean {
  return imagePath.startsWith(`${profile.id}/profiles/`) &&
    !imagePath.includes('..') &&
    !imagePath.startsWith('/');
}

function isLocalHost(hostname: string): boolean {
  return hostname === 'localhost' ||
    hostname === '127.0.0.1' ||
    hostname === '::1' ||
    hostname.endsWith('.localhost');
}

function isSupabaseRestHost(hostname: string): boolean {
  return (hostname === 'supabase.co' || hostname.endsWith('.supabase.co')) &&
    hostname !== 'functions.supabase.co' &&
    !hostname.endsWith('.functions.supabase.co');
}

function safeDecode(value: string): string {
  try {
    return decodeURIComponent(value);
  } catch (_) {
    return '';
  }
}

function trimTrailingSlash(value: string): string {
  let result = value;
  while (result.endsWith('/')) {
    result = result.slice(0, -1);
  }
  return result;
}
