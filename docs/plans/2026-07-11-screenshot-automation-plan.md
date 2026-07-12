# Screenshot Automation Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace manually-captured, privacy-risky screenshots with a repeatable pipeline: a seed script populates two dedicated demo Supabase accounts with realistic non-private data, and a Playwright script logs in as the primary demo account and captures light/dark screenshots of every landing-page feature screen directly into `landing/assets/screenshots/`, which becomes the single source of truth for both the landing page and the README.

**Architecture:** Two standalone Node/TypeScript scripts under `tool/screenshots/`, sharing one small `package.json` and two shared library modules (env loading, Supabase admin client). `seed_demo_account.ts` uses the Supabase **service-role key** to create/update two auth accounts and their data. `capture.ts` drives headless Chromium via Playwright against the deployed web build (`https://glasstrail.vercel.app`), using Flutter web's built-in accessibility/semantics bridge to interact with the login form, and the app's hash-based router to jump directly between screens.

**Tech Stack:** Node.js + TypeScript (run via `tsx`, no build step), `@supabase/supabase-js` (admin client), `playwright` (Chromium), `dotenv`.

## Global Constraints

- Scripts live under `tool/screenshots/` as a self-contained Node project (own `package.json`, own `node_modules/`) — this repo has no other Node tooling and the Flutter app is unaffected.
- Secrets (`SUPABASE_SERVICE_ROLE_KEY`, demo account passwords) load from `tool/screenshots/.env`, which is gitignored; `tool/screenshots/.env.example` documents every key with a placeholder value.
- Production Supabase project: `SUPABASE_URL=https://lzuxlcfjnekgjukqxoza.supabase.co` (`lib/src/backend_config.dart:7`) — this is the **live production project**, so every step that writes to it is scoped strictly to the two demo user ids and is called out for manual, supervised execution.
- Demo accounts: `demo@glasstrail.app` (primary, screenshots are taken as this account) and `demo-friend@glasstrail.app` (friend, exists to populate feed/social/notification screens).
- Reseed behavior (verified against `supabase/migrations/`): accounts, `profiles`, `user_settings`, `friend_relationships`, and `user_drinks` (custom drinks) are created once and left alone on every subsequent run (idempotent upsert). Only `drink_entries` — plus the `drink_entry_cheers` and `notifications` rows derived from them — are deleted and reinserted on every run, with every `consumed_at` computed as an offset from `Date.now()` so the history always ends "today".
- Capture viewport: `480×1000` CSS pixels at `deviceScaleFactor: 3` (⇒ `1440×3000` physical pixels), matching the aspect ratio of every existing file in `landing/assets/screenshots/` (verified: `feed-light.jpg` is `480×1000`).
- Theming: `user_settings.theme_preference` defaults to `'system'` (`supabase/migrations/202603180001_initial_schema.sql`) and `MaterialApp.themeMode` reads exactly that (`lib/src/app.dart:383`, resolving `ThemeMode.system` via `MediaQuery.platformBrightnessOf` at `lib/src/app.dart:591`). The demo accounts are left on `'system'`, so Playwright's `page.emulateMedia({ colorScheme })` alone drives light/dark — no in-app theme toggle needs to be clicked.
- Locale: `AppLocaleCatalog.fallbackCode` is `'en'` (`lib/src/app_locale_catalog.dart:11`) and a fresh browser profile with no stored `glasstrail.last_locale` falls back to it; after sign-in the UI locale converges to the account's `user_settings.locale_code`, which the seed script sets to `'en'`. No extra locale-forcing hack is required beyond that.
- Navigation: this app uses Flutter's default `HashUrlStrategy` (no `usePathUrlStrategy()` call anywhere in `lib/`), so every screen is directly addressable as `<baseUrl>/#<route>` (e.g. `/#/statistics/map`), confirmed by the design spec's own reference to the in-app `#/notifications` screen. `capture.ts` navigates between screens by setting `location.hash` inside the already-authenticated page (no full reload, no re-login, no semantics re-activation needed).
- Flutter web renders to `<canvas>` (CanvasKit); real interactive DOM only exists once the semantics/accessibility tree is activated. This is done once, right after the first page load, by clicking the `flt-semantics-placeholder` element that Flutter's web engine injects automatically — this is the standard, documented technique for driving Flutter web apps with tools like Playwright/Selenium, not anything custom to this app.
- Confirmed exact selectors for the sign-in form (`lib/src/screens/auth_screen.dart`): email field label `l10n.email` = `"Email"` (`lib/l10n/app_en.arb:15`), password field label `l10n.password` = `"Password"` (`:16`), submit button label `l10n.signIn` = `"Sign in"` (`:13`), sign-in is the default `_AuthMode` on load (no mode toggle needed).
- `landing/assets/screenshots/` becomes the only screenshot location; `docs/screenshots/` is deleted entirely; README switches to GitHub's `<picture>` + `prefers-color-scheme` pattern reusing the same files.
- Stock photos: 6 real photographs sourced from Wikimedia Commons under verified CC0/Public-Domain/CC-BY licenses (not synthetic, not fetched blind) — see Task 2 for the exact files, sources, and required attributions.
- Out of scope, left untouched: desktop-mode screenshots (feature 12) and the native Android push-notification screenshots — both already called out as deferred TODOs in the design spec.

---

## Task 1: Node/TypeScript project scaffold

**Files:**
- Create: `tool/screenshots/package.json`
- Create: `tool/screenshots/tsconfig.json`
- Create: `tool/screenshots/.env.example`
- Create: `tool/screenshots/.gitignore`
- Modify: `.gitignore:56` (end of file) — add a blank-line-separated section ignoring the tool's local state at the repo-root level too, as a second safety net

**Interfaces:**
- Produces: an `npm install`-able project at `tool/screenshots/` with `npm run seed`, `npm run capture`, `npm run screenshots`, and `npm run typecheck` scripts, ready for later tasks to add real source files to.

- [ ] **Step 1: Create `tool/screenshots/package.json`**

```json
{
  "name": "glasstrail-screenshot-tooling",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "seed": "tsx seed_demo_account.ts",
    "capture": "tsx capture.ts",
    "screenshots": "npm run seed && npm run capture",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "@supabase/supabase-js": "^2.45.4",
    "dotenv": "^16.4.5"
  },
  "devDependencies": {
    "@types/node": "^22.7.4",
    "playwright": "^1.48.0",
    "tsx": "^4.19.1",
    "typescript": "^5.6.2"
  }
}
```

- [ ] **Step 2: Create `tool/screenshots/tsconfig.json`**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "moduleResolution": "bundler",
    "strict": false,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "resolveJsonModule": true,
    "noEmit": true
  },
  "include": ["**/*.ts"]
}
```

- [ ] **Step 3: Create `tool/screenshots/.env.example`**

```
# Supabase service-role key (Project Settings > API > service_role secret).
# NEVER commit the real value — this bypasses all Row Level Security.
SUPABASE_URL=https://lzuxlcfjnekgjukqxoza.supabase.co
SUPABASE_SERVICE_ROLE_KEY=replace-with-service-role-key

# Demo account credentials — created and kept in sync by seed_demo_account.ts.
DEMO_PRIMARY_EMAIL=demo@glasstrail.app
DEMO_PRIMARY_PASSWORD=replace-with-a-strong-password
DEMO_FRIEND_EMAIL=demo-friend@glasstrail.app
DEMO_FRIEND_PASSWORD=replace-with-a-strong-password

# Base URL capture.ts drives the browser against.
CAPTURE_BASE_URL=https://glasstrail.vercel.app
```

- [ ] **Step 4: Create `tool/screenshots/.gitignore`**

```
node_modules/
.env
```

- [ ] **Step 5: Add a root-level safety net in `.gitignore`**

Append to the end of `/home/joerg/Dokumente/_Code/glasstrail/main.landing-page/.gitignore`:

```

# Screenshot automation tooling (tool/screenshots/)
tool/screenshots/node_modules/
tool/screenshots/.env
```

- [ ] **Step 6: Install dependencies and verify**

Run:
```bash
cd tool/screenshots && npm install && npx playwright install --with-deps chromium
```
Expected: installs succeed, `tool/screenshots/node_modules/` and `tool/screenshots/package-lock.json` exist.

Run: `cd tool/screenshots && npm run typecheck`
Expected: succeeds trivially (no `.ts` files yet, so nothing to check — this just proves `tsc` is wired up). If `tsc` errors because there are zero input files, that's fine at this stage; re-verify typecheck for real once Task 3 adds source files.

- [ ] **Step 7: Commit**

```bash
git add tool/screenshots/package.json tool/screenshots/tsconfig.json tool/screenshots/.env.example tool/screenshots/.gitignore .gitignore
git commit -m "chore(screenshots): scaffold Node/Playwright tooling project"
```

---

## Task 2: Curate and commit stock photo assets

**Files:**
- Create: `tool/screenshots/seed_assets/stock_photos/beer.jpg`
- Create: `tool/screenshots/seed_assets/stock_photos/wine.jpg`
- Create: `tool/screenshots/seed_assets/stock_photos/margarita.jpg`
- Create: `tool/screenshots/seed_assets/stock_photos/whiskey.jpg`
- Create: `tool/screenshots/seed_assets/stock_photos/soft-drinks.jpg`
- Create: `tool/screenshots/seed_assets/stock_photos/coffee.jpg`
- Create: `tool/screenshots/seed_assets/stock_photos/CREDITS.md`

**Interfaces:**
- Produces: 6 real JPEG files that `seed_demo_account.ts` (Task 4/5) reads by exact filename and uploads as drink-entry photos.

These 6 files were individually verified (license + author) via their Wikimedia Commons file pages before being selected — see the table below. `Special:FilePath/<name>` is Wikimedia's stable redirect to the original full-resolution file, safe to `curl` directly (verified working during planning: returns a real `966×966` JPEG, not an HTML page).

| Local filename | Source file page | License | Author |
|---|---|---|---|
| `beer.jpg` | [File:Beer_in_glasses_and_steins.jpg](https://commons.wikimedia.org/wiki/File:Beer_in_glasses_and_steins.jpg) | CC BY 2.0 | Personal Creations |
| `wine.jpg` | [File:Bottle_and_glass_of_red_wine.jpg](https://commons.wikimedia.org/wiki/File:Bottle_and_glass_of_red_wine.jpg) | CC0 1.0 | congerdesign |
| `margarita.jpg` | [File:Margarita.jpg](https://commons.wikimedia.org/wiki/File:Margarita.jpg) | Public Domain | Jon Sullivan (PDPhoto.org) |
| `whiskey.jpg` | [File:A_Glass_of_Whiskey_on_the_Rocks.jpg](https://commons.wikimedia.org/wiki/File:A_Glass_of_Whiskey_on_the_Rocks.jpg) | CC BY 3.0 | Benjamin Thompson (Wonderstruk) |
| `soft-drinks.jpg` | [File:Soft_drinks_800x600.jpg](https://commons.wikimedia.org/wiki/File:Soft_drinks_800x600.jpg) | Public Domain | Rfc1394 |
| `coffee.jpg` | [File:Public_Domain_Coffee.jpg](https://commons.wikimedia.org/wiki/File:Public_Domain_Coffee.jpg) | CC BY-SA 3.0 | Visitor7 |

No avatar/portrait photos are included: using a real, identifiable person's photo as a fictional demo account's avatar is a likeness concern independent of copyright licensing, so `profiles.profile_image_path` is deliberately left `null` for both demo accounts (Task 4) — the app's normal initials-based fallback avatar is itself a realistic look for the account-settings screenshot, since not every real user uploads a photo.

- [ ] **Step 1: Create the directory and download the 6 files**

```bash
mkdir -p tool/screenshots/seed_assets/stock_photos
cd tool/screenshots/seed_assets/stock_photos

curl -sL -o beer.jpg          "https://commons.wikimedia.org/wiki/Special:FilePath/Beer%20in%20glasses%20and%20steins.jpg"
curl -sL -o wine.jpg          "https://commons.wikimedia.org/wiki/Special:FilePath/Bottle%20and%20glass%20of%20red%20wine.jpg"
curl -sL -o margarita.jpg     "https://commons.wikimedia.org/wiki/Special:FilePath/Margarita.jpg"
curl -sL -o whiskey.jpg       "https://commons.wikimedia.org/wiki/Special:FilePath/A%20Glass%20of%20Whiskey%20on%20the%20Rocks.jpg"
curl -sL -o soft-drinks.jpg   "https://commons.wikimedia.org/wiki/Special:FilePath/Soft%20drinks%20800x600.jpg"
curl -sL -o coffee.jpg        "https://commons.wikimedia.org/wiki/Special:FilePath/Public%20Domain%20Coffee.jpg"

cd -
```

- [ ] **Step 2: Verify all 6 downloaded as real JPEGs**

Run: `file tool/screenshots/seed_assets/stock_photos/*.jpg`
Expected: 6 lines, each reading `JPEG image data, ...` (not `HTML document` — that would mean the redirect failed and an error page was saved instead).

- [ ] **Step 3: Create `tool/screenshots/seed_assets/stock_photos/CREDITS.md`**

```markdown
# Stock photo credits

Photos used as seed data for the demo Supabase accounts (`tool/screenshots/seed_demo_account.ts`).
All sourced from Wikimedia Commons; license verified on each file's page before inclusion.

| File | Source | License | Author |
|---|---|---|---|
| `beer.jpg` | https://commons.wikimedia.org/wiki/File:Beer_in_glasses_and_steins.jpg | CC BY 2.0 | Personal Creations |
| `wine.jpg` | https://commons.wikimedia.org/wiki/File:Bottle_and_glass_of_red_wine.jpg | CC0 1.0 | congerdesign |
| `margarita.jpg` | https://commons.wikimedia.org/wiki/File:Margarita.jpg | Public Domain | Jon Sullivan (PDPhoto.org) |
| `whiskey.jpg` | https://commons.wikimedia.org/wiki/File:A_Glass_of_Whiskey_on_the_Rocks.jpg | CC BY 3.0 | Benjamin Thompson (Wonderstruk) |
| `soft-drinks.jpg` | https://commons.wikimedia.org/wiki/File:Soft_drinks_800x600.jpg | Public Domain | Rfc1394 |
| `coffee.jpg` | https://commons.wikimedia.org/wiki/File:Public_Domain_Coffee.jpg | CC BY-SA 3.0 | Visitor7 |

These images never appear in the shipped app or landing page — they exist only as
private demo-account drink-entry photos on the demo Supabase project, used to make
the screenshot pipeline's feed/gallery/map captures look realistic.
```

- [ ] **Step 4: Commit**

```bash
git add tool/screenshots/seed_assets
git commit -m "chore(screenshots): add licensed stock photos for demo seed data"
```

---

## Task 3: Shared env loading and Supabase admin client

**Files:**
- Create: `tool/screenshots/lib/env.ts`
- Create: `tool/screenshots/lib/supabase_admin.ts`

**Interfaces:**
- Produces: `env` (typed object with every required/optional variable, throws with a clear message if a required one is missing) and `createAdminClient()` (returns a `SupabaseClient` authenticated with the service-role key, no session persistence). Both `seed_demo_account.ts` (Task 4/5) and `capture.ts` (Task 6/7) import from here.

- [ ] **Step 1: Create `tool/screenshots/lib/env.ts`**

```typescript
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
```

- [ ] **Step 2: Create `tool/screenshots/lib/supabase_admin.ts`**

```typescript
import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { env } from './env.js';

export function createAdminClient(): SupabaseClient {
  return createClient(env.supabaseUrl, env.supabaseServiceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}
```

- [ ] **Step 3: Verify it type-checks and fails loudly without a `.env`**

Run: `cd tool/screenshots && npm run typecheck`
Expected: no errors.

Run: `cd tool/screenshots && node --input-type=module -e "import('./lib/env.js').catch(e => { console.log('ERROR:', e.message); process.exit(0); })"`

(This runs the compiled-at-runtime `.ts` via Node's `--experimental-strip-types`... actually simpler: use `npx tsx -e`.)

Run instead: `cd tool/screenshots && npx tsx -e "import('./lib/env.ts')" 2>&1 | tail -5`
Expected: exits with `Error: Missing required environment variable: SUPABASE_URL. ...` (no `.env` file exists yet at this point in the plan, so this proves the guard rail works).

- [ ] **Step 4: Commit**

```bash
git add tool/screenshots/lib
git commit -m "chore(screenshots): add shared env loader and Supabase admin client"
```

---

## Task 4: Seed script — demo account identities

**Files:**
- Create: `tool/screenshots/seed_demo_account.ts` (this task writes the identity portion; Task 5 appends the content portion to the same file)

**Interfaces:**
- Consumes: `env` and `createAdminClient()` from `lib/env.ts` / `lib/supabase_admin.ts` (Task 3).
- Produces (for Task 5 to consume in the same file): `admin` (module-level `SupabaseClient`), `PRIMARY_ACCOUNT` / `FRIEND_ACCOUNT` (`{ email, password, displayName }`), `ensureAuthUser()`, `upsertProfile()`, `upsertSettings()`, `ensureFriendship()`, `ensureCustomDrinks()` (returns `Map<string, string>` of custom-drink name → id).

- [ ] **Step 1: Write the identity portion of `tool/screenshots/seed_demo_account.ts`**

```typescript
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
```

- [ ] **Step 2: Verify it type-checks**

Run: `cd tool/screenshots && npm run typecheck`
Expected: no errors. (No `main()` yet, so nothing runs — Task 5 adds that.)

- [ ] **Step 3: Commit**

```bash
git add tool/screenshots/seed_demo_account.ts
git commit -m "feat(screenshots): seed demo account identities and custom drinks"
```

---

## Task 5: Seed script — content, reseed logic, and local-stack verification

**Files:**
- Modify: `tool/screenshots/seed_demo_account.ts` (append content portion + `main()`)

**Interfaces:**
- Consumes: everything Task 4 defined in the same file (`admin`, `PRIMARY_ACCOUNT`, `FRIEND_ACCOUNT`, `ensureAuthUser`, `upsertProfile`, `upsertSettings`, `ensureFriendship`, `ensureCustomDrinks`), plus the 6 files from `seed_assets/stock_photos/` (Task 2).
- Produces: a runnable `npm run seed` that is idempotent for identities and destructively-refreshes `drink_entries` / `drink_entry_cheers` / `notifications` on every run.

- [ ] **Step 1: Append the content portion to `tool/screenshots/seed_demo_account.ts`**

Add these imports to the top of the file (alongside the existing ones from Task 4):

```typescript
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
```

Add this near the top, after the imports:

```typescript
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const STOCK_PHOTOS_DIR = path.join(__dirname, 'seed_assets', 'stock_photos');
```

Append the rest to the end of the file:

```typescript
const STOCK_PHOTOS = {
  beer: 'beer.jpg',
  wine: 'wine.jpg',
  margarita: 'margarita.jpg',
  whiskey: 'whiskey.jpg',
  softDrinks: 'soft-drinks.jpg',
  coffee: 'coffee.jpg',
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
    { offsetHours: 22, sourceType: 'global', sourceDrinkId: 'nonAlcoholic-coffee', drinkName: 'Coffee', categorySlug: 'nonAlcoholic', volumeMl: 200, photoKey: 'coffee' },
    { offsetHours: 30, sourceType: 'global', sourceDrinkId: 'wine-red-wine', drinkName: 'Red Wine', categorySlug: 'wine', volumeMl: 150, comment: 'Paired with dinner.', photoKey: 'wine', location: LOCATIONS.vienna },
    { offsetHours: 50, sourceType: 'global', sourceDrinkId: 'cocktails-margarita', drinkName: 'Margarita', categorySlug: 'cocktails', volumeMl: 180, photoKey: 'margarita', location: LOCATIONS.barcelona },
    { offsetHours: 70, sourceType: 'global', sourceDrinkId: 'spirits-whiskey', drinkName: 'Whiskey', categorySlug: 'spirits', volumeMl: 40, comment: 'Slow evening.', photoKey: 'whiskey' },
    { offsetHours: 95, sourceType: 'global', sourceDrinkId: 'nonAlcoholic-cola', drinkName: 'Cola', categorySlug: 'nonAlcoholic', volumeMl: 330, photoKey: 'softDrinks' },
    { offsetHours: 118, sourceType: 'global', sourceDrinkId: 'beer-weizen', drinkName: 'Weizen', categorySlug: 'beer', volumeMl: 500, location: LOCATIONS.munich },
    { offsetHours: 140, sourceType: 'global', sourceDrinkId: 'longdrinks-gin-tonic', drinkName: 'Gin & Tonic', categorySlug: 'longdrinks', volumeMl: 250, comment: 'Catching up with friends.', location: LOCATIONS.berlin },
    { offsetHours: 160, sourceType: 'global', sourceDrinkId: 'shots-jaegermeister', drinkName: 'Jägermeister', categorySlug: 'shots', volumeMl: 20 },
    { offsetHours: 185, sourceType: 'global', sourceDrinkId: 'sparklingWines-champagne', drinkName: 'Champagne', categorySlug: 'sparklingWines', volumeMl: 120, comment: 'Celebrating a promotion.', location: LOCATIONS.hamburg },
    { offsetHours: 205, sourceType: 'custom', sourceDrinkId: oldFashionedId, drinkName: 'House Old Fashioned', categorySlug: 'cocktails', volumeMl: 200 },
    { offsetHours: 230, sourceType: 'global', sourceDrinkId: 'appleWines-cider', drinkName: 'Cider', categorySlug: 'appleWines', volumeMl: 330 },
    { offsetHours: 255, sourceType: 'global', sourceDrinkId: 'wine-white-wine', drinkName: 'White Wine', categorySlug: 'wine', volumeMl: 150 },
    { offsetHours: 280, sourceType: 'global', sourceDrinkId: 'beer-pils', drinkName: 'Pils', categorySlug: 'beer', volumeMl: 330 },
    { offsetHours: 305, sourceType: 'custom', sourceDrinkId: mulledWineId, drinkName: 'Family Mulled Wine', categorySlug: 'wine', volumeMl: 200, comment: 'Christmas market.', location: LOCATIONS.vienna },
    { offsetHours: 330, sourceType: 'global', sourceDrinkId: 'nonAlcoholic-tea', drinkName: 'Tea', categorySlug: 'nonAlcoholic', volumeMl: 300 },
    { offsetHours: 360, sourceType: 'global', sourceDrinkId: 'cocktails-mojito', drinkName: 'Mojito', categorySlug: 'cocktails', volumeMl: 250 },
    { offsetHours: 400, sourceType: 'global', sourceDrinkId: 'beer-radler', drinkName: 'Radler', categorySlug: 'beer', volumeMl: 500, comment: 'Hot day, needed something light.' },
  ];
}

function buildFriendEntries(): EntrySpec[] {
  return [
    { offsetHours: 10, sourceType: 'global', sourceDrinkId: 'beer-classic', drinkName: 'Beer', categorySlug: 'beer', volumeMl: 500, comment: 'Cheers!' },
    { offsetHours: 60, sourceType: 'global', sourceDrinkId: 'cocktails-cocktail', drinkName: 'Cocktail', categorySlug: 'cocktails', volumeMl: 250, location: LOCATIONS.lisbon },
    { offsetHours: 130, sourceType: 'global', sourceDrinkId: 'wine-rosé-wine', drinkName: 'Rosé Wine', categorySlug: 'wine', volumeMl: 150 },
    { offsetHours: 200, sourceType: 'global', sourceDrinkId: 'nonAlcoholic-lemonade', drinkName: 'Lemonade', categorySlug: 'nonAlcoholic', volumeMl: 330 },
    { offsetHours: 270, sourceType: 'global', sourceDrinkId: 'spirits-gin', drinkName: 'Gin', categorySlug: 'spirits', volumeMl: 40, comment: 'New favorite.' },
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
```

- [ ] **Step 2: Verify it type-checks**

Run: `cd tool/screenshots && npm run typecheck`
Expected: no errors.

- [ ] **Step 3: Verify end-to-end against a local Supabase stack (not production)**

This proves the script's logic (auth, RLS-bypassing writes, FK ordering, storage upload) is correct without touching the live demo accounts or production data.

```bash
cd /home/joerg/Dokumente/_Code/glasstrail/main.landing-page
npx -y supabase@latest start
npx -y supabase@latest status -o env > /tmp/glasstrail-local-supabase.env
cat /tmp/glasstrail-local-supabase.env
```
Expected: `supabase start` finishes with local API/Studio URLs printed; the status file contains `API_URL`, `SERVICE_ROLE_KEY`, etc.

Create a throwaway `tool/screenshots/.env` (do not commit) pointing at the local stack, using the printed `API_URL` as `SUPABASE_URL` and the printed `SERVICE_ROLE_KEY` (exact variable names as emitted by this CLI version's `status -o env` — read the actual output, since these have historically been stable but are worth confirming against what's printed), with any values for the demo passwords, e.g.:
```
SUPABASE_URL=<API_URL from status>
SUPABASE_SERVICE_ROLE_KEY=<SERVICE_ROLE_KEY from status>
DEMO_PRIMARY_EMAIL=demo@glasstrail.app
DEMO_PRIMARY_PASSWORD=local-test-password-1
DEMO_FRIEND_EMAIL=demo-friend@glasstrail.app
DEMO_FRIEND_PASSWORD=local-test-password-2
CAPTURE_BASE_URL=http://127.0.0.1:54321
```

Run: `cd tool/screenshots && npm run seed`
Expected: prints `Demo accounts seeded:` with `18 entries` for the primary account and `5 entries` for the friend account, no thrown errors.

Run it a second time to verify idempotency: `cd tool/screenshots && npm run seed`
Expected: succeeds again with the same counts (proves `ensureAuthUser`/`ensureCustomDrinks`/`ensureFriendship` don't duplicate rows, and `drink_entries` cleanly wipes and reinserts).

Verify row counts directly against the local database:
```bash
npx -y supabase@latest db query --local "
  select
    (select count(*) from auth.users where email like 'demo%@glasstrail.app') as demo_users,
    (select count(*) from public.friend_relationships) as friendships,
    (select count(*) from public.user_drinks) as custom_drinks,
    (select count(*) from public.drink_entries) as entries,
    (select count(*) from public.drink_entry_cheers) as cheers,
    (select count(*) from public.notifications) as notifications;
"
```
Expected: `demo_users=2`, `friendships=1`, `custom_drinks=2`, `entries=23` (18+5), `cheers=2`, `notifications=3`.

Tear down: `npx -y supabase@latest stop`

Delete the throwaway local `.env`: `rm tool/screenshots/.env`

- [ ] **Step 4: Commit**

```bash
git add tool/screenshots/seed_demo_account.ts
git commit -m "feat(screenshots): seed demo drink history, social activity, and reseed logic"
```

---

## Task 6: Capture script — bootstrap, semantics activation, login

**Files:**
- Create: `tool/screenshots/capture.ts` (this task writes bootstrap + login; Task 7 appends the capture loop to the same file)

**Interfaces:**
- Consumes: `env` from `lib/env.ts` (Task 3).
- Produces (for Task 7 to consume in the same file): `VIEWPORT`, `DEVICE_SCALE_FACTOR`, `OUTPUT_DIR`, `enableFlutterSemantics(page)`, `login(page)`.

- [ ] **Step 1: Write the bootstrap and login portion of `tool/screenshots/capture.ts`**

```typescript
import { chromium, type Page } from 'playwright';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { env } from './lib/env.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUTPUT_DIR = path.resolve(__dirname, '..', '..', 'landing', 'assets', 'screenshots');

const VIEWPORT = { width: 480, height: 1000 };
const DEVICE_SCALE_FACTOR = 3;

export async function enableFlutterSemantics(page: Page): Promise<void> {
  const placeholder = page.locator('flt-semantics-placeholder');
  await placeholder.waitFor({ state: 'attached', timeout: 30000 });
  await placeholder.click({ force: true });
  await page.locator('flt-semantics').first().waitFor({ state: 'attached', timeout: 15000 });
}

export async function login(page: Page): Promise<void> {
  await page.goto(env.captureBaseUrl, { waitUntil: 'networkidle' });
  await enableFlutterSemantics(page);

  await page.getByLabel('Email').fill(env.demoPrimaryEmail);
  await page.getByLabel('Password').fill(env.demoPrimaryPassword);
  await page.getByRole('button', { name: 'Sign in' }).click();

  await page.waitForFunction(
    () => location.hash === '#/feed' || location.hash === '' || location.hash === '#/',
    undefined,
    { timeout: 30000 },
  );
  await page.waitForTimeout(2000);
}
```

- [ ] **Step 2: Verify it type-checks**

Run: `cd tool/screenshots && npm run typecheck`
Expected: no errors.

- [ ] **Step 3: Manually verify login works against production, headed, before trusting it in the full pipeline**

This is the first real interaction with the deployed app and the one step in this plan with genuine external uncertainty (exact DOM shape of Flutter's semantics bridge on this specific build) — verify it headed and visually before Task 7 builds 20 unattended screenshots on top of it.

Requires a real `tool/screenshots/.env` with production credentials for demo accounts that Task 9 will have created — if Task 9 hasn't run yet, skip this manual check for now and come back to it after Task 9's account-creation step, before proceeding to Task 7.

Run:
```bash
cd tool/screenshots && npx tsx -e "
import { chromium } from 'playwright';
import { login } from './capture.ts';
const browser = await chromium.launch({ headless: false });
const context = await browser.newContext({ viewport: { width: 480, height: 1000 }, deviceScaleFactor: 3 });
const page = await context.newPage();
await login(page);
console.log('Logged in, current hash:', await page.evaluate(() => location.hash));
await page.waitForTimeout(5000);
await browser.close();
"
```
Expected: a visible Chromium window shows the auth screen, gets filled in, submits, and lands on the feed with `location.hash` printed as `#/feed` (or empty/`#/`, both acceptable per `login()`'s wait condition). If the email/password fields aren't found, this is the point to inspect `flt-semantics-placeholder` interaction manually in the opened browser and adjust `enableFlutterSemantics`/selectors before continuing.

- [ ] **Step 4: Commit**

```bash
git add tool/screenshots/capture.ts
git commit -m "feat(screenshots): capture script bootstrap and login flow"
```

---

## Task 7: Capture script — screen loop, npm wiring

**Files:**
- Modify: `tool/screenshots/capture.ts` (append screen list, capture loop, `main()`)

**Interfaces:**
- Consumes: everything Task 6 defined in the same file.
- Produces: a runnable `npm run capture` that writes 22 files (10 screens × 2 themes + 2 theme-demo copies) into `landing/assets/screenshots/`.

- [ ] **Step 1: Append the capture loop to `tool/screenshots/capture.ts`**

```typescript
import { promises as fs } from 'node:fs';

interface ScreenSpec {
  name: string;
  hashRoute: string;
  afterNavigate?: (page: Page) => Promise<void>;
}

async function scrollToPieChart(page: Page): Promise<void> {
  await page.mouse.move(VIEWPORT.width / 2, VIEWPORT.height / 2);
  await page.mouse.wheel(0, 700);
  await page.waitForTimeout(500);
}

const SCREENS: ScreenSpec[] = [
  { name: 'feed', hashRoute: '/feed' },
  { name: 'statistics-cards', hashRoute: '/statistics/overview' },
  { name: 'statistics-piechart', hashRoute: '/statistics/overview', afterNavigate: scrollToPieChart },
  { name: 'statistics-map', hashRoute: '/statistics/map' },
  { name: 'statistics-gallery', hashRoute: '/statistics/gallery' },
  { name: 'statistics-list', hashRoute: '/statistics/history' },
  { name: 'add-drink', hashRoute: '/add-drink' },
  { name: 'bar-global', hashRoute: '/bar/sorting' },
  { name: 'bar-own', hashRoute: '/bar/custom' },
  { name: 'account-settings', hashRoute: '/profile' },
];

async function goToScreen(page: Page, hashRoute: string): Promise<void> {
  await page.evaluate((route) => {
    location.hash = route;
  }, hashRoute);
  await page.waitForTimeout(1500);
}

async function captureTheme(
  page: Page,
  colorScheme: 'light' | 'dark',
  filePath: string,
): Promise<void> {
  await page.emulateMedia({ colorScheme });
  await page.waitForTimeout(800);
  await page.screenshot({ path: filePath });
}

async function main(): Promise<void> {
  await fs.mkdir(OUTPUT_DIR, { recursive: true });

  const browser = await chromium.launch();
  const context = await browser.newContext({
    viewport: VIEWPORT,
    deviceScaleFactor: DEVICE_SCALE_FACTOR,
    locale: 'en-US',
  });
  const page = await context.newPage();

  await login(page);

  for (const screen of SCREENS) {
    await goToScreen(page, screen.hashRoute);
    if (screen.afterNavigate) {
      await screen.afterNavigate(page);
    }
    await captureTheme(page, 'light', path.join(OUTPUT_DIR, `${screen.name}-light.jpg`));
    await captureTheme(page, 'dark', path.join(OUTPUT_DIR, `${screen.name}-dark.jpg`));
  }

  await browser.close();

  await fs.copyFile(
    path.join(OUTPUT_DIR, 'feed-light.jpg'),
    path.join(OUTPUT_DIR, 'theme-demo-light.jpg'),
  );
  await fs.copyFile(
    path.join(OUTPUT_DIR, 'feed-dark.jpg'),
    path.join(OUTPUT_DIR, 'theme-demo-dark.jpg'),
  );

  console.log(`Captured ${SCREENS.length} screens (light + dark) into ${OUTPUT_DIR}`);
}

const isMainModule = path.resolve(process.argv[1] ?? '') === fileURLToPath(import.meta.url);
if (isMainModule) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
```

The `isMainModule` guard means `capture.ts` only runs its pipeline when executed directly (`npm run capture`), not when another script (e.g. Task 6 Step 3's ad hoc login check) imports `login`/`enableFlutterSemantics` from it.

Note: `statistics-cards` and `statistics-piechart` share the hash route `/statistics/overview` and are listed adjacently on purpose — since the hash doesn't change between them, `goToScreen` doesn't trigger a Flutter route rebuild the second time, so the scroll position from `scrollToPieChart` lands on top of the already-rendered cards screen instead of a freshly-reset one. Every other screen has a distinct hash route, so it remounts (and resets scroll to top) naturally on navigation.

- [ ] **Step 2: Verify it type-checks**

Run: `cd tool/screenshots && npm run typecheck`
Expected: no errors.

- [ ] **Step 3: Run the full capture against production and inspect the output**

Requires the real `tool/screenshots/.env` (production demo credentials, created in Task 9) and the demo accounts to already be seeded (Task 9's seed step must run first).

Run: `cd tool/screenshots && npm run capture`
Expected: prints `Captured 10 screens (light + dark) into .../landing/assets/screenshots`, exits 0.

Run: `ls -la landing/assets/screenshots/*.jpg | wc -l`
Expected: `22` (10 screens × 2 themes + 2 theme-demo copies), all with a recent mtime.

Spot-check visually: open `landing/assets/screenshots/feed-light.jpg`, `landing/assets/screenshots/statistics-piechart-light.jpg`, and `landing/assets/screenshots/statistics-map-dark.jpg` and confirm they show real demo content (not a blank/loading/error screen) in the correct theme.

- [ ] **Step 4: Commit the capture script (not the generated screenshots yet — Task 8 handles those together with the README/docs cutover)**

```bash
git add tool/screenshots/capture.ts
git commit -m "feat(screenshots): capture loop for all 10 feature screens"
```

---

## Task 8: Asset pipeline cutover — single source of truth

**Files:**
- Delete: `docs/screenshots/` (entire directory: `bar_global_drinks.jpg`, `bar_own drinks.jpg`, `feed.jpg`, `gallery.jpg`, `map.jpg`, `notifications.png`, `statistics_cards.jpg`, `statistics_piechart.jpg`)
- Modify: `README.md:15-24`
- Modify: `landing/assets/screenshots/*.jpg` (the 22 files Task 7 wrote — commit them here, alongside the README change, so the cutover is one reviewable unit)

**Interfaces:**
- None — this is a pure content/asset change with no code to consume it.

- [ ] **Step 1: Delete `docs/screenshots/`**

```bash
git rm -r docs/screenshots
```

- [ ] **Step 2: Rewrite the README screenshot table to use `<picture>` + `prefers-color-scheme`**

Read `README.md:15-24` first to get the exact current row structure, then replace those 2 `<tr>` rows with:

```html
    <td align="center"><strong>Feed</strong><br>
      <picture>
        <source media="(prefers-color-scheme: dark)" srcset="landing/assets/screenshots/feed-dark.jpg">
        <img src="landing/assets/screenshots/feed-light.jpg" alt="Feed" width="180">
      </picture>
    </td>
    <td align="center"><strong>Statistics</strong><br>
      <picture>
        <source media="(prefers-color-scheme: dark)" srcset="landing/assets/screenshots/statistics-cards-dark.jpg">
        <img src="landing/assets/screenshots/statistics-cards-light.jpg" alt="Statistics cards" width="180">
      </picture>
    </td>
    <td align="center"><strong>Pie Chart</strong><br>
      <picture>
        <source media="(prefers-color-scheme: dark)" srcset="landing/assets/screenshots/statistics-piechart-dark.jpg">
        <img src="landing/assets/screenshots/statistics-piechart-light.jpg" alt="Pie chart" width="180">
      </picture>
    </td>
    <td align="center"><strong>Drink Locations</strong><br>
      <picture>
        <source media="(prefers-color-scheme: dark)" srcset="landing/assets/screenshots/statistics-map-dark.jpg">
        <img src="landing/assets/screenshots/statistics-map-light.jpg" alt="Drink locations" width="180">
      </picture>
    </td>
```
```html
    <td align="center"><strong>Drink Gallery</strong><br>
      <picture>
        <source media="(prefers-color-scheme: dark)" srcset="landing/assets/screenshots/statistics-gallery-dark.jpg">
        <img src="landing/assets/screenshots/statistics-gallery-light.jpg" alt="Drink gallery" width="180">
      </picture>
    </td>
    <td align="center"><strong>Global Drinks</strong><br>
      <picture>
        <source media="(prefers-color-scheme: dark)" srcset="landing/assets/screenshots/bar-global-dark.jpg">
        <img src="landing/assets/screenshots/bar-global-light.jpg" alt="Global drinks" width="180">
      </picture>
    </td>
    <td align="center"><strong>Custom Drinks</strong><br>
      <picture>
        <source media="(prefers-color-scheme: dark)" srcset="landing/assets/screenshots/bar-own-dark.jpg">
        <img src="landing/assets/screenshots/bar-own-light.jpg" alt="Own drinks" width="180">
      </picture>
    </td>
    <td align="center"><strong>Notifications</strong><br>
      <picture>
        <source media="(prefers-color-scheme: dark)" srcset="landing/assets/screenshots/notifications-dark.png">
        <img src="landing/assets/screenshots/notifications-light.png" alt="Notifications" width="180">
      </picture>
    </td>
```

Preserve the exact surrounding `<table>`/`<tr>` structure from the current file — only the `<td>` inner contents change (from a single `<img>` to a `<picture>` block). `notifications-{light,dark}` are intentionally left pointing at their existing pre-pipeline files (Task 7 doesn't touch them — out of scope per the design spec).

- [ ] **Step 3: Verify the README renders sensibly**

Run: `grep -c "landing/assets/screenshots" README.md`
Expected: `16` (8 captions × 2 `<picture>` sources each: one `srcset`, one `src`).

Run: `grep -c "docs/screenshots" README.md`
Expected: `0`.

- [ ] **Step 4: Stage the generated screenshots from Task 7 alongside this change**

```bash
git add landing/assets/screenshots README.md docs/screenshots
git status
```
Expected: shows the 8 `docs/screenshots/*` files as deleted, `README.md` as modified, and all 22 `landing/assets/screenshots/*.jpg` as modified (overwritten in place with real captures — same filenames, so `landing/index.html` needs no changes).

- [ ] **Step 5: Commit**

```bash
git commit -m "docs: make landing/assets/screenshots the single screenshot source of truth"
```

---

## Task 9: Production seed run and final capture (manual, supervised)

This task writes real data to the **production** Supabase project and is the reason Tasks 5's and 7's verification steps used a local stack instead. Do not run this unattended — confirm with the user immediately before the first sub-step, since it creates two new permanent auth accounts on the live project.

**Files:** none (operational task only).

- [ ] **Step 1: Confirm with the user before proceeding**

State plainly: "About to create `demo@glasstrail.app` and `demo-friend@glasstrail.app` as real accounts on the production Supabase project (`lzuxlcfjnekgjukqxoza`) and seed drink history for both. Proceed?" Wait for explicit go-ahead.

- [ ] **Step 2: Create the real `tool/screenshots/.env`**

```bash
cp tool/screenshots/.env.example tool/screenshots/.env
```
Fill in `SUPABASE_SERVICE_ROLE_KEY` (Supabase dashboard → Project Settings → API → `service_role` secret) and strong passwords for both demo accounts. Leave `SUPABASE_URL` and `CAPTURE_BASE_URL` at their defaults.

- [ ] **Step 3: Run the seed script against production**

Run: `cd tool/screenshots && npm run seed`
Expected: `Demo accounts seeded:` with `18 entries` (primary) and `5 entries` (friend), no errors.

- [ ] **Step 4: Spot-check in the Supabase dashboard**

Confirm in the Supabase Studio (Table Editor) that `auth.users` has exactly the 2 new demo accounts, `public.drink_entries` has 23 rows across the 2 demo user ids only, and `storage.objects` under bucket `user-media` has 6 new objects under `<primary-user-id>/entries/`.

- [ ] **Step 5: Now run Task 6 Step 3 (the headed login smoke-check) for real**, then run Task 7 Step 3 (the full capture), then Task 8 (asset cutover), if not already done earlier in the branch.

- [ ] **Step 6: Re-run the seed script once more to prove reseeding is safe**

Run: `cd tool/screenshots && npm run seed`
Expected: same success output; entry `consumed_at` timestamps have shifted forward relative to the previous run but the identities, friendship, and custom drinks are unchanged (spot-check one `user_drinks` row's `id` is identical to Step 4's).

- [ ] **Step 7: Final commit if anything changed since Task 8**

If re-running capture in Step 5/6 produced different bytes than what Task 8 committed, `git add landing/assets/screenshots && git commit -m "docs: refresh screenshots from production demo accounts"`. Otherwise, nothing to do — Task 8's commit already stands.
