import { randomUUID } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { env } from './lib/env.js';
import { createAdminClient } from './lib/supabase_admin.js';

const admin = createAdminClient();

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const STOCK_PHOTOS_DIR = path.join(__dirname, 'seed_assets', 'stock_photos');

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

const STOCK_PHOTOS = {
  beer: 'beer.jpg',
  wine: 'wine.jpg',
  margarita: 'margarita.jpg',
  whiskey: 'whiskey.jpg',
  softDrinks: 'soft-drinks.jpg',
  coffee: 'coffee.jpg',
  cider: 'cider.jpg',
  clubMate: 'club-mate.jpg',
  tomatoJuice: 'tomato-juice.jpg',
  caipirinha: 'caipirinha.jpg',
  tea: 'tea.jpg',
  cubaLibre: 'cuba-libre.jpg',
} as const;

type StockPhotoKey = keyof typeof STOCK_PHOTOS;

async function uploadStockPhoto(
  userId: string,
  photoKey: StockPhotoKey,
  entryId: string,
): Promise<string> {
  const fileName = STOCK_PHOTOS[photoKey];
  const bytes = await readFile(path.join(STOCK_PHOTOS_DIR, fileName));
  const storagePath = `${userId}/entries/${entryId}-${fileName}`;
  const { error } = await admin.storage.from('user-media').upload(storagePath, bytes, {
    contentType: 'image/jpeg',
    upsert: true,
  });
  if (error) {
    throw error;
  }
  return storagePath;
}

interface EntryLocation {
  latitude: number;
  longitude: number;
  address: string;
}

const LOCATIONS: Record<string, EntryLocation> = {
  munich: { latitude: 48.1351, longitude: 11.582, address: 'Munich, Germany' },
  vienna: { latitude: 48.2082, longitude: 16.3738, address: 'Vienna, Austria' },
  barcelona: { latitude: 41.3851, longitude: 2.1734, address: 'Barcelona, Spain' },
  berlin: { latitude: 52.52, longitude: 13.405, address: 'Berlin, Germany' },
  hamburg: { latitude: 53.5511, longitude: 9.9937, address: 'Hamburg, Germany' },
  lisbon: { latitude: 38.7223, longitude: -9.1393, address: 'Lisbon, Portugal' },
  paris: { latitude: 48.8566, longitude: 2.3522, address: 'Paris, France' },
  london: { latitude: 51.5074, longitude: -0.1278, address: 'London, United Kingdom' },
  amsterdam: { latitude: 52.3676, longitude: 4.9041, address: 'Amsterdam, Netherlands' },
  edinburgh: { latitude: 55.9533, longitude: -3.1883, address: 'Edinburgh, United Kingdom' },
  copenhagen: { latitude: 55.6761, longitude: 12.5683, address: 'Copenhagen, Denmark' },
  prague: { latitude: 50.0755, longitude: 14.4378, address: 'Prague, Czechia' },
  bordeaux: { latitude: 44.8378, longitude: -0.5792, address: 'Bordeaux, France' },
  dublin: { latitude: 53.3498, longitude: -6.2603, address: 'Dublin, Ireland' },
  madrid: { latitude: 40.4168, longitude: -3.7038, address: 'Madrid, Spain' },
  zurich: { latitude: 47.3769, longitude: 8.5417, address: 'Zurich, Switzerland' },
  warsaw: { latitude: 52.2297, longitude: 21.0122, address: 'Warsaw, Poland' },
  porto: { latitude: 41.1579, longitude: -8.6291, address: 'Porto, Portugal' },
  stockholm: { latitude: 59.3293, longitude: 18.0686, address: 'Stockholm, Sweden' },
  budapest: { latitude: 47.4979, longitude: 19.0402, address: 'Budapest, Hungary' },
  milan: { latitude: 45.4642, longitude: 9.19, address: 'Milan, Italy' },
  brussels: { latitude: 50.8503, longitude: 4.3517, address: 'Brussels, Belgium' },
  nice: { latitude: 43.7102, longitude: 7.262, address: 'Nice, France' },
};

interface EntrySpec {
  offsetHours: number;
  sourceType: 'global' | 'custom';
  sourceDrinkId: string;
  drinkName: string;
  categorySlug: string;
  volumeMl: number;
  comment?: string;
  photoKey?: StockPhotoKey;
  location?: EntryLocation;
}

function buildPrimaryEntries(customDrinkIds: Map<string, string>): EntrySpec[] {
  const oldFashionedId = customDrinkIds.get('House Old Fashioned');
  const mulledWineId = customDrinkIds.get('Family Mulled Wine');
  if (!oldFashionedId || !mulledWineId) {
    throw new Error('Custom drink ids missing — ensureCustomDrinks() must run first.');
  }

  return [
    { offsetHours: 4, sourceType: 'global', sourceDrinkId: 'beer-ipa', drinkName: 'IPA', categorySlug: 'beer', volumeMl: 330, comment: 'Friday wind-down.', photoKey: 'beer', location: LOCATIONS.munich },
    { offsetHours: 22, sourceType: 'global', sourceDrinkId: 'nonAlcoholic-coffee', drinkName: 'Coffee', categorySlug: 'nonAlcoholic', volumeMl: 200, photoKey: 'coffee', location: LOCATIONS.paris },
    { offsetHours: 30, sourceType: 'global', sourceDrinkId: 'wine-red-wine', drinkName: 'Red Wine', categorySlug: 'wine', volumeMl: 150, comment: 'Paired with dinner.', photoKey: 'wine', location: LOCATIONS.vienna },
    { offsetHours: 50, sourceType: 'global', sourceDrinkId: 'cocktails-margarita', drinkName: 'Margarita', categorySlug: 'cocktails', volumeMl: 180, photoKey: 'margarita', location: LOCATIONS.barcelona },
    { offsetHours: 70, sourceType: 'global', sourceDrinkId: 'spirits-whiskey', drinkName: 'Whiskey', categorySlug: 'spirits', volumeMl: 40, comment: 'Slow evening.', photoKey: 'whiskey', location: LOCATIONS.edinburgh },
    { offsetHours: 95, sourceType: 'global', sourceDrinkId: 'nonAlcoholic-cola', drinkName: 'Cola', categorySlug: 'nonAlcoholic', volumeMl: 330, photoKey: 'softDrinks', location: LOCATIONS.amsterdam },
    { offsetHours: 118, sourceType: 'global', sourceDrinkId: 'beer-weizen', drinkName: 'Weizen', categorySlug: 'beer', volumeMl: 500, location: LOCATIONS.munich },
    { offsetHours: 140, sourceType: 'global', sourceDrinkId: 'longdrinks-gin-tonic', drinkName: 'Gin & Tonic', categorySlug: 'longdrinks', volumeMl: 250, comment: 'Catching up with friends.', location: LOCATIONS.berlin },
    { offsetHours: 160, sourceType: 'global', sourceDrinkId: 'shots-jaegermeister', drinkName: 'Jägermeister', categorySlug: 'shots', volumeMl: 20, location: LOCATIONS.copenhagen },
    { offsetHours: 185, sourceType: 'global', sourceDrinkId: 'sparklingWines-champagne', drinkName: 'Champagne', categorySlug: 'sparklingWines', volumeMl: 120, comment: 'Celebrating a promotion.', location: LOCATIONS.hamburg },
    { offsetHours: 205, sourceType: 'custom', sourceDrinkId: oldFashionedId, drinkName: 'House Old Fashioned', categorySlug: 'cocktails', volumeMl: 200, location: LOCATIONS.london },
    { offsetHours: 230, sourceType: 'global', sourceDrinkId: 'appleWines-cider', drinkName: 'Cider', categorySlug: 'appleWines', volumeMl: 330, photoKey: 'cider', location: LOCATIONS.dublin },
    { offsetHours: 255, sourceType: 'global', sourceDrinkId: 'wine-white-wine', drinkName: 'White Wine', categorySlug: 'wine', volumeMl: 150, location: LOCATIONS.bordeaux },
    { offsetHours: 280, sourceType: 'global', sourceDrinkId: 'beer-pils', drinkName: 'Pils', categorySlug: 'beer', volumeMl: 330, location: LOCATIONS.prague },
    { offsetHours: 305, sourceType: 'custom', sourceDrinkId: mulledWineId, drinkName: 'Family Mulled Wine', categorySlug: 'wine', volumeMl: 200, comment: 'Christmas market.', location: LOCATIONS.vienna },
    { offsetHours: 330, sourceType: 'global', sourceDrinkId: 'nonAlcoholic-tea', drinkName: 'Tea', categorySlug: 'nonAlcoholic', volumeMl: 300, photoKey: 'tea', location: LOCATIONS.dublin },
    { offsetHours: 360, sourceType: 'global', sourceDrinkId: 'cocktails-mojito', drinkName: 'Mojito', categorySlug: 'cocktails', volumeMl: 250, location: LOCATIONS.madrid },
    { offsetHours: 400, sourceType: 'global', sourceDrinkId: 'beer-radler', drinkName: 'Radler', categorySlug: 'beer', volumeMl: 500, comment: 'Hot day, needed something light.', location: LOCATIONS.zurich },
    { offsetHours: 420, sourceType: 'global', sourceDrinkId: 'nonAlcoholic-club-mate', drinkName: 'Club-Mate', categorySlug: 'nonAlcoholic', volumeMl: 500, photoKey: 'clubMate', location: LOCATIONS.berlin },
    { offsetHours: 440, sourceType: 'global', sourceDrinkId: 'nonAlcoholic-juice', drinkName: 'Tomato Juice', categorySlug: 'nonAlcoholic', volumeMl: 250, photoKey: 'tomatoJuice', location: LOCATIONS.warsaw },
    { offsetHours: 460, sourceType: 'global', sourceDrinkId: 'cocktails-caipirinha', drinkName: 'Caipirinha', categorySlug: 'cocktails', volumeMl: 250, comment: 'Brazilian night at the bar.', photoKey: 'caipirinha', location: LOCATIONS.porto },
    { offsetHours: 480, sourceType: 'global', sourceDrinkId: 'longdrinks-cuba-libre', drinkName: 'Cuba Libre', categorySlug: 'longdrinks', volumeMl: 250, photoKey: 'cubaLibre', location: LOCATIONS.stockholm },
  ];
}

function buildFriendEntries(): EntrySpec[] {
  return [
    { offsetHours: 10, sourceType: 'global', sourceDrinkId: 'beer-classic', drinkName: 'Beer', categorySlug: 'beer', volumeMl: 500, comment: 'Cheers!', location: LOCATIONS.budapest },
    { offsetHours: 60, sourceType: 'global', sourceDrinkId: 'cocktails-cocktail', drinkName: 'Cocktail', categorySlug: 'cocktails', volumeMl: 250, location: LOCATIONS.lisbon },
    { offsetHours: 130, sourceType: 'global', sourceDrinkId: 'wine-rosé-wine', drinkName: 'Rosé Wine', categorySlug: 'wine', volumeMl: 150, location: LOCATIONS.nice },
    { offsetHours: 200, sourceType: 'global', sourceDrinkId: 'nonAlcoholic-lemonade', drinkName: 'Lemonade', categorySlug: 'nonAlcoholic', volumeMl: 330, location: LOCATIONS.milan },
    { offsetHours: 270, sourceType: 'global', sourceDrinkId: 'spirits-gin', drinkName: 'Gin', categorySlug: 'spirits', volumeMl: 40, comment: 'New favorite.', location: LOCATIONS.brussels },
  ];
}

async function reseedEntries(userId: string, specs: EntrySpec[]): Promise<string[]> {
  const { error: deleteError } = await admin.from('drink_entries').delete().eq('user_id', userId);
  if (deleteError) {
    throw deleteError;
  }

  const insertedIds: string[] = [];
  for (const spec of specs) {
    const entryId = randomUUID();
    const consumedAt = new Date(Date.now() - spec.offsetHours * 3600 * 1000).toISOString();
    const imagePath = spec.photoKey
      ? await uploadStockPhoto(userId, spec.photoKey, entryId)
      : null;

    const { error } = await admin.from('drink_entries').insert({
      id: entryId,
      user_id: userId,
      source_type: spec.sourceType,
      source_drink_id: spec.sourceDrinkId,
      drink_name: spec.drinkName,
      category_slug: spec.categorySlug,
      volume_ml: spec.volumeMl,
      is_alcohol_free: spec.categorySlug === 'nonAlcoholic',
      comment: spec.comment ?? null,
      image_path: imagePath,
      location_latitude: spec.location?.latitude ?? null,
      location_longitude: spec.location?.longitude ?? null,
      location_address: spec.location?.address ?? null,
      consumed_at: consumedAt,
    });
    if (error) {
      throw error;
    }
    insertedIds.push(entryId);
  }
  return insertedIds;
}

async function reseedSocialActivity(
  primaryId: string,
  friendId: string,
  friendDisplayName: string,
  primaryEntryIds: string[],
  friendEntryIds: string[],
): Promise<void> {
  const { error: deleteError } = await admin
    .from('notifications')
    .delete()
    .in('recipient_user_id', [primaryId, friendId]);
  if (deleteError) {
    throw deleteError;
  }
  // drink_entry_cheers rows tied to the entries reseedEntries() just deleted were
  // already removed by the "on delete cascade" FK — see 202605060001_add_feed_entry_cheers.sql.

  const cheeredPrimaryEntryId = primaryEntryIds[0];
  const cheeredFriendEntryId = friendEntryIds[0];

  const { error: cheersError } = await admin.from('drink_entry_cheers').insert([
    { entry_id: cheeredPrimaryEntryId, user_id: friendId },
    { entry_id: cheeredFriendEntryId, user_id: primaryId },
  ]);
  if (cheersError) {
    throw cheersError;
  }

  const { error: notificationsError } = await admin.from('notifications').insert([
    {
      recipient_user_id: primaryId,
      sender_user_id: friendId,
      sender_display_name: friendDisplayName,
      type: 'friend_request_accepted',
      template_args: { senderDisplayName: friendDisplayName },
      image_path: 'https://glasstrail.vercel.app/notification-assets/request_accepted.png',
      metadata: {},
    },
    {
      recipient_user_id: primaryId,
      sender_user_id: friendId,
      sender_display_name: friendDisplayName,
      type: 'friend_drink_logged',
      template_args: { senderDisplayName: friendDisplayName },
      image_path: 'https://glasstrail.vercel.app/notification-assets/app-icon.png',
      metadata: { entryId: friendEntryIds[0], route: '/feed' },
    },
    {
      recipient_user_id: primaryId,
      sender_user_id: friendId,
      sender_display_name: friendDisplayName,
      type: 'friend_drink_cheered',
      template_args: { senderDisplayName: friendDisplayName },
      image_path: 'https://glasstrail.vercel.app/notification-assets/cheers.png',
      metadata: { entryId: cheeredPrimaryEntryId, route: '/feed' },
    },
  ]);
  if (notificationsError) {
    throw notificationsError;
  }
}

async function main(): Promise<void> {
  const primaryId = await ensureAuthUser(PRIMARY_ACCOUNT);
  const friendId = await ensureAuthUser(FRIEND_ACCOUNT);

  await upsertProfile(primaryId, PRIMARY_ACCOUNT.displayName);
  await upsertProfile(friendId, FRIEND_ACCOUNT.displayName);
  await upsertSettings(primaryId);
  await upsertSettings(friendId);
  await ensureFriendship(primaryId, friendId);

  const customDrinkIds = await ensureCustomDrinks(primaryId);

  const primaryEntryIds = await reseedEntries(primaryId, buildPrimaryEntries(customDrinkIds));
  const friendEntryIds = await reseedEntries(friendId, buildFriendEntries());

  await reseedSocialActivity(
    primaryId,
    friendId,
    FRIEND_ACCOUNT.displayName,
    primaryEntryIds,
    friendEntryIds,
  );

  console.log('Demo accounts seeded:');
  console.log(`  ${PRIMARY_ACCOUNT.email} (${primaryId}): ${primaryEntryIds.length} entries`);
  console.log(`  ${FRIEND_ACCOUNT.email} (${friendId}): ${friendEntryIds.length} entries`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
