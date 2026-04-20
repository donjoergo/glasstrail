import { createClient } from 'jsr:@supabase/supabase-js@2';

type ProfileRow = {
  id: string;
  display_name: string | null;
  profile_image_path: string | null;
  profile_share_code: string;
};

const mediaBucket = 'user-media';
const defaultPublicBaseUrl = 'https://glasstrail.vercel.app';
const defaultIconPath = '/icons/Icon-512.png';
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
};

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (request.method !== 'GET') {
    return jsonResponse({ error: 'method_not_allowed' }, 405);
  }

  const url = new URL(request.url);
  const route = parseRoute(url);
  if (route.code.length === 0) {
    return invalidResponse(url);
  }

  try {
    const profile = await loadProfile(route.code);
    if (profile == null) {
      return invalidResponse(url);
    }

    if (route.isImage) {
      return imageResponse(profile);
    }

    if (url.searchParams.get('format') === 'json') {
      return jsonResponse(publicProfileJson(profile), 200);
    }

    return htmlResponse(profile, request);
  } catch (error) {
    console.error(error);
    return serverErrorResponse(url);
  }
});

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
  const serviceRoleKey =
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')?.trim() ?? '';
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

function publicProfileJson(profile: ProfileRow): Record<string, string | null> {
  return {
    id: profile.id,
    displayName: displayName(profile),
    profileImageUrl: profileImageUrl(profile),
    profileShareCode: profile.profile_share_code,
  };
}

async function imageResponse(profile: ProfileRow): Promise<Response> {
  const fallbackUrl = iconUrl();
  const imagePath = profile.profile_image_path?.trim();
  if (imagePath == null || !isSafeProfileImagePath(profile, imagePath)) {
    return redirectResponse(fallbackUrl);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')?.trim() ?? '';
  const serviceRoleKey =
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')?.trim() ?? '';
  const client = createClient(supabaseUrl, serviceRoleKey);
  const { data, error } = await client.storage
    .from(mediaBucket)
    .createSignedUrl(imagePath, 60 * 10);

  if (error != null || data?.signedUrl == null) {
    return redirectResponse(fallbackUrl);
  }
  return redirectResponse(data.signedUrl);
}

function htmlResponse(profile: ProfileRow, request: Request): Response {
  const language = preferredLanguage(request);
  const name = displayName(profile);
  const title = language === 'de'
    ? `${name} möchte dein Freund in Glass Trail sein`
    : `${name} wants to be your friend on Glass Trail`;
  const description = language === 'de'
    ? 'Melde dich an, um die Freundschaftsanfrage in Glass Trail anzusehen.'
    : 'Sign in to view the friend request in Glass Trail.';
  const cta = language === 'de' ? 'Anmelden' : 'Sign in';
  const profileUrl = publicProfileUrl(profile.profile_share_code);
  const appUrl = appProfileUrl(profile.profile_share_code);
  const imageUrl = profileImageUrl(profile);
  const html = `<!doctype html>
<html lang="${language}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="robots" content="noindex,nofollow">
  <title>${escapeHtml(title)}</title>
  <meta name="description" content="${escapeAttribute(description)}">
  <link rel="canonical" href="${escapeAttribute(profileUrl)}">
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="Glass Trail">
  <meta property="og:title" content="${escapeAttribute(title)}">
  <meta property="og:description" content="${escapeAttribute(description)}">
  <meta property="og:url" content="${escapeAttribute(profileUrl)}">
  <meta property="og:image" content="${escapeAttribute(imageUrl)}">
  <meta property="og:image:alt" content="${escapeAttribute(title)}">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${escapeAttribute(title)}">
  <meta name="twitter:description" content="${escapeAttribute(description)}">
  <meta name="twitter:image" content="${escapeAttribute(imageUrl)}">
  <style>
    :root {
      color-scheme: light dark;
      font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: #fffcf8;
      color: #17201b;
    }
    body {
      align-items: center;
      display: flex;
      justify-content: center;
      margin: 0;
      min-height: 100vh;
      padding: 24px;
    }
    main {
      max-width: 420px;
      text-align: center;
    }
    img {
      border-radius: 50%;
      box-shadow: 0 18px 40px rgb(23 32 27 / 18%);
      height: 112px;
      object-fit: cover;
      width: 112px;
    }
    h1 {
      font-size: 30px;
      line-height: 1.15;
      margin: 24px 0 12px;
    }
    p {
      color: #526158;
      font-size: 16px;
      line-height: 1.5;
      margin: 0 0 24px;
    }
    a {
      align-items: center;
      background: #1f7a8c;
      border-radius: 8px;
      color: white;
      display: inline-flex;
      font-weight: 700;
      min-height: 48px;
      padding: 0 22px;
      text-decoration: none;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        background: #151b18;
        color: #f4f7f3;
      }
      p {
        color: #b9c7bd;
      }
    }
  </style>
</head>
<body>
  <main>
    <img src="${escapeAttribute(imageUrl)}" alt="" width="112" height="112">
    <h1>${escapeHtml(title)}</h1>
    <p>${escapeHtml(description)}</p>
    <a href="${escapeAttribute(appUrl)}">${escapeHtml(cta)}</a>
  </main>
</body>
</html>`;

  return new Response(html, {
    status: 200,
    headers: {
      ...corsHeaders,
      'content-type': 'text/html; charset=utf-8',
      'cache-control': 'public, max-age=300',
    },
  });
}

function invalidResponse(url: URL): Response {
  if (url.searchParams.get('format') === 'json') {
    return jsonResponse({ error: 'profile_not_found' }, 404);
  }
  const title = 'Profillink nicht verfügbar';
  const body = `<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="robots" content="noindex,nofollow">
  <title>${title}</title>
</head>
<body>
  <main>
    <h1>${title}</h1>
    <p>Dieser Glass Trail Profillink ist ungültig oder nicht mehr verfügbar.</p>
  </main>
</body>
</html>`;
  return new Response(body, {
    status: 404,
    headers: {
      ...corsHeaders,
      'content-type': 'text/html; charset=utf-8',
      'cache-control': 'no-store',
    },
  });
}

function serverErrorResponse(url: URL): Response {
  if (url.searchParams.get('format') === 'json') {
    return jsonResponse({ error: 'preview_unavailable' }, 500);
  }
  const body = `<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="robots" content="noindex,nofollow">
  <title>Vorschau nicht verfügbar</title>
</head>
<body>
  <main>
    <h1>Vorschau nicht verfügbar</h1>
    <p>Die Glass Trail Profilvorschau kann gerade nicht geladen werden.</p>
  </main>
</body>
</html>`;
  return new Response(body, {
    status: 500,
    headers: {
      ...corsHeaders,
      'content-type': 'text/html; charset=utf-8',
      'cache-control': 'no-store',
    },
  });
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

function preferredLanguage(request: Request): 'de' | 'en' {
  const header = request.headers.get('accept-language')?.toLowerCase() ?? '';
  if (header.startsWith('en')) {
    return 'en';
  }
  return 'de';
}

function publicProfileUrl(code: string): string {
  return `${publicBaseUrl()}${friendProfilePath(code)}`;
}

function appProfileUrl(code: string): string {
  return `${publicBaseUrl()}/#${friendProfilePath(code)}`;
}

function profileImageUrl(profile: ProfileRow): string {
  return `${publicProfileUrl(profile.profile_share_code)}/image`;
}

function iconUrl(): string {
  const iconPath = Deno.env.get('FRIEND_PROFILE_APP_ICON_PATH')?.trim() ??
    defaultIconPath;
  if (iconPath.startsWith('http://') || iconPath.startsWith('https://')) {
    return iconPath;
  }
  return `${publicBaseUrl()}${iconPath.startsWith('/') ? '' : '/'}${iconPath}`;
}

function publicBaseUrl(): string {
  const configured = Deno.env.get('FRIEND_PROFILE_PUBLIC_BASE_URL')?.trim() ??
    defaultPublicBaseUrl;
  return trimTrailingSlash(configured.length === 0
    ? defaultPublicBaseUrl
    : configured);
}

function friendProfilePath(code: string): string {
  return `/friends/profile/${encodeURIComponent(code)}`;
}

function isSafeProfileImagePath(profile: ProfileRow, imagePath: string): boolean {
  return imagePath.startsWith(`${profile.id}/profiles/`) &&
    !imagePath.includes('..') &&
    !imagePath.startsWith('/');
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

function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function escapeAttribute(value: string): string {
  return escapeHtml(value);
}
