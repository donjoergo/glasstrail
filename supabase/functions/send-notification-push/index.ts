import { createClient } from 'jsr:@supabase/supabase-js@2';

type NotificationRow = {
  id: string;
  recipient_user_id: string;
  actor_user_id: string | null;
  actor_display_name: string;
  type: string;
};

type DeviceTokenRow = {
  token: string;
  platform: string;
};

type FcmConfig = {
  projectId: string;
  clientEmail: string;
  privateKey: string;
};

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, x-glasstrail-push-secret',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

let cachedAccessToken: { token: string; expiresAt: number } | null = null;

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (request.method !== 'POST') {
    return jsonResponse({ error: 'method_not_allowed' }, 405);
  }

  const expectedSecret = Deno.env.get('PUSH_FUNCTION_SECRET')?.trim() ?? '';
  if (expectedSecret.length === 0) {
    return jsonResponse({ ok: true, pushEnabled: false }, 202);
  }
  if (request.headers.get('x-glasstrail-push-secret') !== expectedSecret) {
    return jsonResponse({ error: 'unauthorized' }, 401);
  }

  const notificationId = await notificationIdFromRequest(request);
  if (notificationId == null) {
    return jsonResponse({ error: 'invalid_notification_id' }, 400);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')?.trim() ?? '';
  const serviceRoleKey =
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')?.trim() ?? '';
  if (supabaseUrl.length === 0 || serviceRoleKey.length === 0) {
    return jsonResponse({ ok: true, pushEnabled: false }, 202);
  }

  const fcmConfig = fcmConfigFromEnvironment();
  if (fcmConfig == null) {
    return jsonResponse({ ok: true, pushEnabled: false }, 202);
  }

  const client = createClient(supabaseUrl, serviceRoleKey);
  const notification = await loadNotification(client, notificationId);
  if (notification == null) {
    return jsonResponse({ ok: true, sent: 0 }, 202);
  }

  const tokens = await loadAndroidTokens(client, notification.recipient_user_id);
  if (tokens.length === 0) {
    return jsonResponse({ ok: true, sent: 0 }, 202);
  }

  try {
    const accessToken = await fcmAccessToken(fcmConfig);
    let sent = 0;
    let failed = 0;

    for (const token of tokens) {
      const result = await sendFcmMessage(fcmConfig, accessToken, {
        notification,
        token: token.token,
      });
      if (result.ok) {
        sent++;
      } else {
        failed++;
        await deleteInvalidToken(client, token.token, result.responseText);
      }
    }

    return jsonResponse({ ok: true, sent, failed }, 202);
  } catch (error) {
    console.error(error);
    return jsonResponse({ ok: true, sent: 0, failed: tokens.length }, 202);
  }
});

async function notificationIdFromRequest(
  request: Request,
): Promise<string | null> {
  try {
    const body = await request.json();
    const value = typeof body?.notificationId === 'string'
      ? body.notificationId.trim()
      : '';
    return isUuid(value) ? value : null;
  } catch (_) {
    return null;
  }
}

async function loadNotification(
  client: ReturnType<typeof createClient>,
  notificationId: string,
): Promise<NotificationRow | null> {
  const { data, error } = await client
    .from('notifications')
    .select('id, recipient_user_id, actor_user_id, actor_display_name, type')
    .eq('id', notificationId)
    .maybeSingle();

  if (error != null) {
    throw error;
  }
  return data as NotificationRow | null;
}

async function loadAndroidTokens(
  client: ReturnType<typeof createClient>,
  userId: string,
): Promise<DeviceTokenRow[]> {
  const { data, error } = await client
    .from('notification_device_tokens')
    .select('token, platform')
    .eq('user_id', userId)
    .eq('platform', 'android');

  if (error != null) {
    throw error;
  }
  return (data ?? []) as DeviceTokenRow[];
}

async function sendFcmMessage(
  config: FcmConfig,
  accessToken: string,
  input: { notification: NotificationRow; token: string },
): Promise<{ ok: boolean; responseText: string }> {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${config.projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        authorization: `Bearer ${accessToken}`,
        'content-type': 'application/json; charset=utf-8',
      },
      body: JSON.stringify({
        message: {
          token: input.token,
          notification: {
            title: 'Glass Trail',
            body: pushBody(input.notification),
          },
          data: {
            notification_id: input.notification.id,
            notification_type: input.notification.type,
            actor_user_id: input.notification.actor_user_id ?? '',
            route: '/profile',
          },
          android: {
            priority: 'high',
            notification: {
              default_sound: true,
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
          },
        },
      }),
    },
  );

  const responseText = await response.text();
  if (!response.ok) {
    console.error('FCM send failed', response.status, responseText);
  }
  return { ok: response.ok, responseText };
}

async function deleteInvalidToken(
  client: ReturnType<typeof createClient>,
  token: string,
  responseText: string,
): Promise<void> {
  if (
    !responseText.includes('UNREGISTERED') &&
    !responseText.includes('registration-token-not-registered')
  ) {
    return;
  }

  const { error } = await client
    .from('notification_device_tokens')
    .delete()
    .eq('token', token);
  if (error != null) {
    console.error('Failed to delete invalid FCM token', error);
  }
}

async function fcmAccessToken(config: FcmConfig): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken != null && cachedAccessToken.expiresAt > now + 60) {
    return cachedAccessToken.token;
  }

  const assertion = await serviceAccountJwt(config, now);
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });

  const body = await response.json();
  if (!response.ok || typeof body.access_token !== 'string') {
    throw new Error('Unable to fetch FCM access token.');
  }

  cachedAccessToken = {
    token: body.access_token,
    expiresAt: now + Number(body.expires_in ?? 3600),
  };
  return cachedAccessToken.token;
}

async function serviceAccountJwt(
  config: FcmConfig,
  issuedAt: number,
): Promise<string> {
  const header = base64UrlEncodeJson({ alg: 'RS256', typ: 'JWT' });
  const payload = base64UrlEncodeJson({
    iss: config.clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: issuedAt,
    exp: issuedAt + 3600,
  });
  const signingInput = `${header}.${payload}`;
  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(config.privateKey),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(signingInput),
  );
  return `${signingInput}.${base64UrlEncodeBytes(new Uint8Array(signature))}`;
}

function fcmConfigFromEnvironment(): FcmConfig | null {
  const rawJson = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON')?.trim() ?? '';
  if (rawJson.length > 0) {
    const parsed = JSON.parse(rawJson);
    return normalizeFcmConfig({
      projectId: parsed.project_id,
      clientEmail: parsed.client_email,
      privateKey: parsed.private_key,
    });
  }

  return normalizeFcmConfig({
    projectId: Deno.env.get('FCM_PROJECT_ID'),
    clientEmail: Deno.env.get('FCM_CLIENT_EMAIL'),
    privateKey: Deno.env.get('FCM_PRIVATE_KEY'),
  });
}

function normalizeFcmConfig(input: {
  projectId: unknown;
  clientEmail: unknown;
  privateKey: unknown;
}): FcmConfig | null {
  const projectId = typeof input.projectId === 'string'
    ? input.projectId.trim()
    : '';
  const clientEmail = typeof input.clientEmail === 'string'
    ? input.clientEmail.trim()
    : '';
  const privateKey = typeof input.privateKey === 'string'
    ? input.privateKey.replaceAll('\\n', '\n').trim()
    : '';

  if (projectId.length === 0 || clientEmail.length === 0 ||
      privateKey.length === 0) {
    return null;
  }
  return { projectId, clientEmail, privateKey };
}

function pushBody(notification: NotificationRow): string {
  const name = notification.actor_display_name.trim() || 'Someone';
  switch (notification.type) {
    case 'friend_request_sent':
      return `${name} sent you a friend request.`;
    case 'friend_request_accepted':
      return `${name} accepted your friend request.`;
    case 'friend_request_rejected':
      return `${name} declined your friend request.`;
    case 'friend_removed':
      return `${name} removed you as a friend.`;
    default:
      return 'You have a new notification.';
  }
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '');
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index++) {
    bytes[index] = binary.charCodeAt(index);
  }
  return bytes.buffer;
}

function base64UrlEncodeJson(value: unknown): string {
  return base64UrlEncodeBytes(new TextEncoder().encode(JSON.stringify(value)));
}

function base64UrlEncodeBytes(bytes: Uint8Array): string {
  let binary = '';
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary)
    .replaceAll('+', '-')
    .replaceAll('/', '_')
    .replaceAll('=', '');
}

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(value);
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
    },
  });
}
