import { buildDeleteAccountResponse, deleteStoragePrefix } from "./index.ts";

type FakeStorageItem = {
  name: string;
  id: string | null;
};

class FakeStorageBucket {
  constructor(
    private readonly itemsByPath: Record<string, FakeStorageItem[]>,
  ) {}

  readonly removedBatches: string[][] = [];

  async list(path = ""): Promise<{
    data: FakeStorageItem[] | null;
    error: { message: string } | null;
  }> {
    return {
      data: this.itemsByPath[path] ?? [],
      error: null,
    };
  }

  async remove(paths: string[]): Promise<{
    data: unknown;
    error: { message: string } | null;
  }> {
    this.removedBatches.push(paths);
    return { data: null, error: null };
  }
}

function expectEqual(actual: unknown, expected: unknown, label: string): void {
  const actualJson = JSON.stringify(actual);
  const expectedJson = JSON.stringify(expected);
  if (actualJson !== expectedJson) {
    throw new Error(`${label}: expected ${expectedJson}, got ${actualJson}`);
  }
}

async function responseJson(response: Response): Promise<unknown> {
  return JSON.parse(await response.text());
}

Deno.test("rejects unauthenticated delete-account requests", async () => {
  let authenticateCalled = false;

  const response = await buildDeleteAccountResponse(
    new Request("https://example.com/delete-account", { method: "POST" }),
    {
      authenticate: async () => {
        authenticateCalled = true;
        return null;
      },
      deleteSenderNotifications: async () => {},
      deleteUserMedia: async () => {},
      deleteAuthUser: async () => {},
    },
  );

  expectEqual(response.status, 401, "status");
  expectEqual(await responseJson(response), { error: "unauthorized" }, "body");
  expectEqual(authenticateCalled, false, "authenticateCalled");
});

Deno.test(
  "deleteStoragePrefix removes recursive bucket objects under the user prefix",
  async () => {
    const bucket = new FakeStorageBucket({
      "user-1": [
        { name: "profiles", id: null },
        { name: "entries", id: null },
        { name: "avatar-root.png", id: "root-file" },
      ],
      "user-1/profiles": [{ name: "avatar.png", id: "profile-file" }],
      "user-1/entries": [{ name: "2026", id: null }],
      "user-1/entries/2026": [{ name: "entry.jpg", id: "entry-file" }],
      "user-2": [{ name: "other.png", id: "other-file" }],
    });

    await deleteStoragePrefix(bucket, "user-1");

    expectEqual(bucket.removedBatches, [[
      "user-1/profiles/avatar.png",
      "user-1/entries/2026/entry.jpg",
      "user-1/avatar-root.png",
    ]], "removedBatches");
  },
);

Deno.test(
  "deletes sender notifications, then storage, and only then the auth user",
  async () => {
    const calls: string[] = [];

    const response = await buildDeleteAccountResponse(
      new Request("https://example.com/delete-account", {
        method: "POST",
        headers: { authorization: "Bearer test-token" },
      }),
      {
        authenticate: async () => "user-1",
        deleteSenderNotifications: async () => {
          calls.push("notifications");
        },
        deleteUserMedia: async () => {
          calls.push("media");
        },
        deleteAuthUser: async () => {
          calls.push("auth");
        },
      },
    );

    expectEqual(response.status, 200, "status");
    expectEqual(await responseJson(response), { success: true }, "body");
    expectEqual(calls, ["notifications", "media", "auth"], "calls");
  },
);

Deno.test(
  "returns an error without deleting the auth user when storage cleanup fails",
  async () => {
    const calls: string[] = [];

    const response = await buildDeleteAccountResponse(
      new Request("https://example.com/delete-account", {
        method: "POST",
        headers: { authorization: "Bearer test-token" },
      }),
      {
        authenticate: async () => "user-1",
        deleteSenderNotifications: async () => {
          calls.push("notifications");
        },
        deleteUserMedia: async () => {
          calls.push("media");
          throw new Error("storage_cleanup_failed");
        },
        deleteAuthUser: async () => {
          calls.push("auth");
        },
        logger: { error: () => {} },
      },
    );

    expectEqual(response.status, 500, "status");
    expectEqual(
      await responseJson(response),
      { error: "delete_account_failed" },
      "body",
    );
    expectEqual(calls, ["notifications", "media"], "calls");
  },
);
