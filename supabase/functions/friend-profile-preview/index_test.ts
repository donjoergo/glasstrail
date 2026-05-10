import { publicProfileJson, remoteProfileImageUrl } from './index.ts';

type ProfileRow = {
  id: string;
  display_name: string | null;
  profile_image_path: string | null;
  profile_share_code: string;
};

function expectEqual(actual: unknown, expected: unknown, label: string): void {
  if (actual !== expected) {
    throw new Error(`${label}: expected ${expected}, got ${actual}`);
  }
}

function baseProfile(
  overrides: Partial<ProfileRow> = {},
): ProfileRow {
  return {
    id: 'user-1',
    display_name: 'Friend Owner',
    profile_image_path: null,
    profile_share_code: 'share-code',
    ...overrides,
  };
}

Deno.test('keeps remote https avatar urls in public preview json', () => {
  const profile = baseProfile({
    profile_image_path: 'https://example.com/profile.jpg',
  });

  const json = publicProfileJson(
    profile,
    new Request('https://project-ref.functions.supabase.co/friend-profile-preview/share-code'),
  );

  expectEqual(
    json['profileImageUrl'],
    'https://example.com/profile.jpg',
    'profileImageUrl',
  );
});

Deno.test('upgrades remote http avatar urls to https outside localhost', () => {
  expectEqual(
    remoteProfileImageUrl('http://example.com/profile.jpg'),
    'https://example.com/profile.jpg',
    'remoteProfileImageUrl',
  );
});

Deno.test('keeps localhost http avatar urls unchanged', () => {
  expectEqual(
    remoteProfileImageUrl('http://localhost:54321/profile.jpg'),
    'http://localhost:54321/profile.jpg',
    'remoteProfileImageUrl',
  );
});

Deno.test('keeps storage-backed profile previews on the image endpoint', () => {
  const profile = baseProfile({
    profile_image_path: 'user-1/profiles/avatar.png',
  });

  const json = publicProfileJson(
    profile,
    new Request('https://project-ref.supabase.co/friend-profile-preview/share-code'),
  );

  expectEqual(
    json['profileImageUrl'],
    'https://project-ref.supabase.co/functions/v1/friend-profile-preview/share-code/image',
    'profileImageUrl',
  );
});

Deno.test('suppresses unsupported non-owned storage paths in public preview', () => {
  const profile = baseProfile({
    profile_image_path: 'user-1/entries/avatar.png',
  });

  const json = publicProfileJson(
    profile,
    new Request('https://project-ref.functions.supabase.co/friend-profile-preview/share-code'),
  );

  expectEqual(json['profileImageUrl'], null, 'profileImageUrl');
});
