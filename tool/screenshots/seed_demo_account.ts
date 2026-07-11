import { randomUUID } from 'node:crypto';
import { env } from './lib/env.js';
import { createAdminClient } from './lib/supabase_admin.js';

const admin = createAdminClient();

interface DemoAccountSpec {
  email: string;
  password: string;
  displayName: string;
}

const PRIMARY_ACCOUNT: DemoAccountSpec = {
  email: env.demoPrimaryEmail,
  password: env.demoPrimaryPassword,
  displayName: 'Alex Rivers',
};

const FRIEND_ACCOUNT: DemoAccountSpec = {
  email: env.demoFriendEmail,
  password: env.demoFriendPassword,
  displayName: 'Sam Torres',
};

async function ensureAuthUser(account: DemoAccountSpec): Promise<string> {
  const { data: existing, error: listError } = await admin.auth.admin.listUsers({
    page: 1,
    perPage: 1000,
  });
  if (listError) {
    throw listError;
  }

  const match = existing.users.find(
    (user) => user.email?.toLowerCase() === account.email.toLowerCase(),
  );

  if (match) {
    const { error: updateError } = await admin.auth.admin.updateUserById(match.id, {
      password: account.password,
      user_metadata: { display_name: account.displayName },
    });
    if (updateError) {
      throw updateError;
    }
    return match.id;
  }

  const { data: created, error: createError } = await admin.auth.admin.createUser({
    email: account.email,
    password: account.password,
    email_confirm: true,
    user_metadata: { display_name: account.displayName },
  });
  if (createError || !created.user) {
    throw createError ?? new Error(`Failed to create auth user for ${account.email}`);
  }
  return created.user.id;
}

async function upsertProfile(userId: string, displayName: string): Promise<void> {
  const { error } = await admin
    .from('profiles')
    .update({ display_name: displayName })
    .eq('id', userId);
  if (error) {
    throw error;
  }
}

async function upsertSettings(userId: string): Promise<void> {
  const { error } = await admin
    .from('user_settings')
    .update({
      locale_code: 'en',
      unit: 'ml',
      handedness: 'right',
      share_stats_with_friends: true,
    })
    .eq('user_id', userId);
  if (error) {
    throw error;
  }
}

async function ensureFriendship(primaryId: string, friendId: string): Promise<void> {
  await admin
    .from('friend_relationships')
    .delete()
    .or(
      `and(requester_id.eq.${primaryId},addressee_id.eq.${friendId}),and(requester_id.eq.${friendId},addressee_id.eq.${primaryId})`,
    );

  const { error } = await admin.from('friend_relationships').insert({
    requester_id: primaryId,
    addressee_id: friendId,
    status: 'accepted',
  });
  if (error) {
    throw error;
  }
}

interface CustomDrinkSpec {
  name: string;
  categorySlug: string;
  volumeMl: number;
}

const CUSTOM_DRINKS: CustomDrinkSpec[] = [
  { name: 'House Old Fashioned', categorySlug: 'cocktails', volumeMl: 200 },
  { name: 'Family Mulled Wine', categorySlug: 'wine', volumeMl: 200 },
];

async function ensureCustomDrinks(userId: string): Promise<Map<string, string>> {
  const { data: existingRows, error: selectError } = await admin
    .from('user_drinks')
    .select('id, name')
    .eq('user_id', userId);
  if (selectError) {
    throw selectError;
  }

  const existingByLowerName = new Map<string, string>(
    (existingRows ?? []).map((row: { id: string; name: string }) => [
      row.name.toLowerCase(),
      row.id,
    ]),
  );
  const idByName = new Map<string, string>();

  for (const drink of CUSTOM_DRINKS) {
    const existingId = existingByLowerName.get(drink.name.toLowerCase());
    if (existingId) {
      const { error } = await admin
        .from('user_drinks')
        .update({ category_slug: drink.categorySlug, volume_ml: drink.volumeMl })
        .eq('id', existingId);
      if (error) {
        throw error;
      }
      idByName.set(drink.name, existingId);
      continue;
    }

    const newId = randomUUID();
    const { error } = await admin.from('user_drinks').insert({
      id: newId,
      user_id: userId,
      name: drink.name,
      category_slug: drink.categorySlug,
      volume_ml: drink.volumeMl,
    });
    if (error) {
      throw error;
    }
    idByName.set(drink.name, newId);
  }

  return idByName;
}
