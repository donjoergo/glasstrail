const defaultDataBaseUrl =
  'https://lzuxlcfjnekgjukqxoza.functions.supabase.co/friend-profile-preview';
const previewAvatarSize = 160;

module.exports = async function handler(request, response) {
  if (request.method !== 'GET') {
    sendJson(response, { error: 'method_not_allowed' }, 405);
    return;
  }

  const code = profileCodeFromRequest(request);
  if (code.length === 0) {
    sendHtml(response, invalidHtml(), 404, 'no-store');
    return;
  }

  try {
    const profile = await loadPublicProfile(code);
    if (profile == null) {
      sendHtml(response, invalidHtml(), 404, 'no-store');
      return;
    }

    sendHtml(response, profileHtml(profile, request), 200, 'public, max-age=300');
  } catch (error) {
    console.error(error);
    sendHtml(response, serverErrorHtml(), 500, 'no-store');
  }
};

function profileCodeFromRequest(request) {
  const query = request.query ?? {};
  const rawCode = Array.isArray(query.code) ? query.code[0] : query.code;
  if (typeof rawCode === 'string') {
    return safeDecode(rawCode).trim();
  }

  const url = new URL(request.url ?? '/', requestOrigin(request));
  return safeDecode(url.searchParams.get('code') ?? '').trim();
}

async function loadPublicProfile(code) {
  const url = `${dataBaseUrl()}/${encodeURIComponent(code)}?format=json`;
  const response = await fetch(url, {
    headers: {
      accept: 'application/json',
    },
  });

  if (response.status === 404) {
    return null;
  }
  if (!response.ok) {
    throw new Error(`Profile preview data request failed: ${response.status}`);
  }

  const contentType = response.headers.get('content-type') ?? '';
  if (!contentType.toLowerCase().includes('application/json')) {
    throw new Error(`Unexpected profile preview content type: ${contentType}`);
  }

  return response.json();
}

function profileHtml(profile, request) {
  const language = preferredLanguage(request);
  const name = displayName(profile);
  const title = language === 'de'
    ? `${name} möchte dein Freund in Glass Trail sein`
    : `${name} wants to be your friend on Glass Trail`;
  const description = language === 'de'
    ? 'Melde dich an, um die Freundschaftsanfrage in Glass Trail anzusehen.'
    : 'Sign in to view the friend request in Glass Trail.';
  const cta = language === 'de' ? 'Anmelden' : 'Sign in';
  const origin = requestOrigin(request);
  const profileUrl = publicProfileUrl(profile.profileShareCode, origin);
  const appUrl = appProfileUrl(profile.profileShareCode, origin);
  const imageUrl = profileImageUrl(profile);
  const faviconUrl = publicAssetUrl('/favicon.png', origin);
  const touchIconUrl = publicAssetUrl('/icons/Icon-192.png', origin);

  return `<!doctype html>
<html lang="${language}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="robots" content="noindex,nofollow">
  <title>${escapeHtml(title)}</title>
  <meta name="description" content="${escapeAttribute(description)}">
  <link rel="canonical" href="${escapeAttribute(profileUrl)}">
  <link rel="icon" type="image/png" href="${escapeAttribute(faviconUrl)}">
  <link rel="apple-touch-icon" href="${escapeAttribute(touchIconUrl)}">
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="Glass Trail">
  <meta property="og:title" content="${escapeAttribute(title)}">
  <meta property="og:description" content="${escapeAttribute(description)}">
  <meta property="og:url" content="${escapeAttribute(profileUrl)}">
  <meta property="og:image" content="${escapeAttribute(imageUrl)}">
  <meta property="og:image:width" content="512">
  <meta property="og:image:height" content="512">
  <meta property="og:image:alt" content="${escapeAttribute(title)}">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${escapeAttribute(title)}">
  <meta name="twitter:description" content="${escapeAttribute(description)}">
  <meta name="twitter:image" content="${escapeAttribute(imageUrl)}">
  <meta name="twitter:image:alt" content="${escapeAttribute(title)}">
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
      height: ${previewAvatarSize}px;
      object-fit: cover;
      width: ${previewAvatarSize}px;
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
      background: #2d6a4f;
      border-radius: 20px;
      color: #ffffff;
      display: inline-flex;
      font-weight: 700;
      min-height: 48px;
      padding: 0 22px;
      text-decoration: none;
    }
    a:focus-visible {
      outline: 3px solid #e9c46a;
      outline-offset: 3px;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        background: #151b18;
        color: #f4f7f3;
      }
      p {
        color: #b9c7bd;
      }
      a {
        background: #82cca5;
        color: #0d1210;
      }
    }
  </style>
</head>
<body>
  <main>
    <img src="${escapeAttribute(imageUrl)}" alt="" width="${previewAvatarSize}" height="${previewAvatarSize}">
    <h1>${escapeHtml(title)}</h1>
    <p>${escapeHtml(description)}</p>
    <a href="${escapeAttribute(appUrl)}">${escapeHtml(cta)}</a>
  </main>
</body>
</html>`;
}

function invalidHtml() {
  const faviconUrl = publicAssetUrl('/favicon.png');
  return `<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="robots" content="noindex,nofollow">
  <title>Profillink nicht verfügbar</title>
  <link rel="icon" type="image/png" href="${escapeAttribute(faviconUrl)}">
</head>
<body>
  <main>
    <h1>Profillink nicht verfügbar</h1>
    <p>Dieser Glass Trail Profillink ist ungültig oder nicht mehr verfügbar.</p>
  </main>
</body>
</html>`;
}

function serverErrorHtml() {
  const faviconUrl = publicAssetUrl('/favicon.png');
  return `<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="robots" content="noindex,nofollow">
  <title>Vorschau nicht verfügbar</title>
  <link rel="icon" type="image/png" href="${escapeAttribute(faviconUrl)}">
</head>
<body>
  <main>
    <h1>Vorschau nicht verfügbar</h1>
    <p>Die Glass Trail Profilvorschau kann gerade nicht geladen werden.</p>
  </main>
</body>
</html>`;
}

function sendHtml(response, body, status, cacheControl) {
  response.statusCode = status;
  response.setHeader('Content-Type', 'text/html; charset=utf-8');
  response.setHeader('Cache-Control', cacheControl);
  response.end(body);
}

function sendJson(response, body, status) {
  response.statusCode = status;
  response.setHeader('Content-Type', 'application/json; charset=utf-8');
  response.setHeader('Cache-Control', 'no-store');
  response.end(JSON.stringify(body));
}

function displayName(profile) {
  const value = typeof profile.displayName === 'string'
    ? profile.displayName.trim()
    : '';
  return value.length === 0 ? 'Glass Trail User' : value;
}

function preferredLanguage(request) {
  const header = String(request.headers['accept-language'] ?? '').toLowerCase();
  return header.startsWith('en') ? 'en' : 'de';
}

function dataBaseUrl() {
  const configured = process.env.FRIEND_PROFILE_DATA_BASE_URL?.trim() ?? '';
  return trimTrailingSlash(configured.length === 0
    ? defaultDataBaseUrl
    : configured);
}

function requestOrigin(request) {
  const host = firstHeaderValue(request, 'x-forwarded-host') ??
    firstHeaderValue(request, 'host');
  if (host != null && host.length > 0) {
    const proto = firstHeaderValue(request, 'x-forwarded-proto') ?? 'https';
    return `${proto}://${host}`;
  }

  const url = new URL(request.url ?? '/', 'http://localhost');
  return url.origin;
}

function firstHeaderValue(request, name) {
  const value = request.headers?.[name] ?? request.headers?.[name.toLowerCase()];
  const normalized = Array.isArray(value) ? value[0] : value;
  if (typeof normalized !== 'string') {
    return null;
  }
  return normalized.split(',')[0].trim();
}

function publicProfileUrl(code, origin) {
  return `${trimTrailingSlash(origin)}${friendProfilePath(code)}`;
}

function appProfileUrl(code, origin) {
  const path = friendProfilePath(code);
  return `${trimTrailingSlash(origin)}/?route=${encodeURIComponent(path)}#${path}`;
}

function profileImageUrl(profile) {
  return `${dataBaseUrl()}/${encodeURIComponent(profile.profileShareCode)}/image`;
}

function publicAssetUrl(path, origin = 'https://glasstrail.vercel.app') {
  return `${trimTrailingSlash(origin)}${path.startsWith('/') ? '' : '/'}${path}`;
}

function friendProfilePath(code) {
  return `/friends/profile/${encodeURIComponent(code)}`;
}

function safeDecode(value) {
  try {
    return decodeURIComponent(value);
  } catch (_) {
    return '';
  }
}

function trimTrailingSlash(value) {
  let result = value;
  while (result.endsWith('/')) {
    result = result.slice(0, -1);
  }
  return result;
}

function escapeHtml(value) {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function escapeAttribute(value) {
  return escapeHtml(value);
}
