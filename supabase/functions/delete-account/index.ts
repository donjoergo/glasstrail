import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const mediaBucket = "user-media";
const storageListPageSize = 100;

type StorageBucketLike = {
  list: (
    path?: string,
    options?: {
      limit?: number;
      offset?: number;
      sortBy?: { column: string; order: string };
    },
  ) => Promise<{
    data: Array<{ name: string; id: string | null }> | null;
    error: { message: string } | null;
  }>;
  remove: (
    paths: string[],
  ) => Promise<{ data: unknown; error: { message: string } | null }>;
};

type DeleteAccountDependencies = {
  authenticate: (accessToken: string) => Promise<string | null>;
  deleteSenderNotifications: (userId: string) => Promise<void>;
  deleteUserMedia: (userId: string) => Promise<void>;
  deleteAuthUser: (userId: string) => Promise<void>;
  logger?: Pick<Console, "error">;
};

if (import.meta.main) {
  Deno.serve(async (request) => {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim() ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim() ??
      "";
    if (supabaseUrl.length === 0 || serviceRoleKey.length === 0) {
      return serverErrorResponse();
    }

    const client = createClient(supabaseUrl, serviceRoleKey);
    return buildDeleteAccountResponse(request, {
      authenticate: (accessToken) => authenticateUser(client, accessToken),
      deleteSenderNotifications: (userId) =>
        deleteSenderNotifications(client, userId),
      deleteUserMedia: (userId) => deleteUserMedia(client, userId),
      deleteAuthUser: (userId) => deleteAuthUser(client, userId),
      logger: console,
    });
  });
}

export async function buildDeleteAccountResponse(
  request: Request,
  dependencies: DeleteAccountDependencies,
): Promise<Response> {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  const accessToken = bearerToken(request);
  if (accessToken == null) {
    return unauthorizedResponse();
  }

  try {
    const userId = await dependencies.authenticate(accessToken);
    if (userId == null) {
      return unauthorizedResponse();
    }

    await dependencies.deleteSenderNotifications(userId);
    await dependencies.deleteUserMedia(userId);
    await dependencies.deleteAuthUser(userId);
    return jsonResponse({ success: true }, 200);
  } catch (error) {
    dependencies.logger?.error(error);
    return serverErrorResponse();
  }
}

export async function listStoragePathsRecursively(
  bucket: StorageBucketLike,
  prefix: string,
): Promise<string[]> {
  const normalizedPrefix = normalizeStoragePrefix(prefix);
  if (normalizedPrefix.length == 0) {
    return [];
  }

  const paths: string[] = [];

  async function collect(path: string): Promise<void> {
    let offset = 0;

    while (true) {
      const { data, error } = await bucket.list(path, {
        limit: storageListPageSize,
        offset,
        sortBy: { column: "name", order: "asc" },
      });
      if (error != null) {
        throw new Error(error.message);
      }

      const items = data ?? [];
      for (const item of items) {
        const name = item.name.trim();
        if (name.length == 0) {
          continue;
        }

        const itemPath = `${path}/${name}`;
        if (item.id == null) {
          await collect(itemPath);
        } else {
          paths.push(itemPath);
        }
      }

      if (items.length < storageListPageSize) {
        return;
      }
      offset += storageListPageSize;
    }
  }

  await collect(normalizedPrefix);
  return paths;
}

export async function deleteStoragePrefix(
  bucket: StorageBucketLike,
  prefix: string,
): Promise<void> {
  const paths = await listStoragePathsRecursively(bucket, prefix);
  if (paths.length === 0) {
    return;
  }

  for (let index = 0; index < paths.length; index += storageListPageSize) {
    const batch = paths.slice(index, index + storageListPageSize);
    const { error } = await bucket.remove(batch);
    if (error != null) {
      throw new Error(error.message);
    }
  }
}

async function authenticateUser(
  client: SupabaseClient,
  accessToken: string,
): Promise<string | null> {
  const {
    data: { user },
    error,
  } = await client.auth.getUser(accessToken);
  if (error != null || user == null) {
    return null;
  }
  return user.id;
}

async function deleteSenderNotifications(
  client: SupabaseClient,
  userId: string,
): Promise<void> {
  const { error } = await client
    .from("notifications")
    .delete()
    .eq("sender_user_id", userId);
  if (error != null) {
    throw error;
  }
}

async function deleteUserMedia(
  client: SupabaseClient,
  userId: string,
): Promise<void> {
  await deleteStoragePrefix(client.storage.from(mediaBucket), userId);
}

async function deleteAuthUser(
  client: SupabaseClient,
  userId: string,
): Promise<void> {
  const { error } = await client.auth.admin.deleteUser(userId);
  if (error != null) {
    throw error;
  }
}

function bearerToken(request: Request): string | null {
  const value = request.headers.get("authorization")?.trim() ?? "";
  if (!value.toLowerCase().startsWith("bearer ")) {
    return null;
  }
  const token = value.substring(7).trim();
  return token.length === 0 ? null : token;
}

function normalizeStoragePrefix(prefix: string): string {
  let normalized = prefix.trim();
  while (normalized.endsWith("/")) {
    normalized = normalized.slice(0, -1);
  }
  return normalized;
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
    },
  });
}

function unauthorizedResponse(): Response {
  return jsonResponse({ error: "unauthorized" }, 401);
}

function serverErrorResponse(): Response {
  return jsonResponse({ error: "delete_account_failed" }, 500);
}
