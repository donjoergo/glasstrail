# Screenshot automation

Seeds two demo Supabase accounts with realistic, non-private data and captures
light/dark screenshots of every landing-page feature screen, writing directly
into `landing/assets/screenshots/`. Replaces manual, privacy-risky captures
from a real user's account. Design doc:
[`docs/superpowers/specs/2026-07-11-screenshot-automation-design.md`](../../docs/superpowers/specs/2026-07-11-screenshot-automation-design.md).

## Setup

```bash
cd tool/screenshots
npm install
npx playwright install chromium
cp .env.example .env
```

Fill in `.env`:

- `SUPABASE_SERVICE_ROLE_KEY` — Supabase dashboard → Project Settings → API →
  `service_role` secret. This bypasses Row Level Security — never commit it.
- `DEMO_PRIMARY_PASSWORD` / `DEMO_FRIEND_PASSWORD` — any strong passwords;
  `seed_demo_account.ts` creates the accounts on first run and reuses them
  (updating the password to match `.env`) on every later run.
- `SUPABASE_URL` and `CAPTURE_BASE_URL` can usually stay at their defaults
  (the production project and `https://glasstrail.vercel.app`).

## Running

```bash
npm run seed        # create/refresh the two demo accounts and their data
npm run capture      # log in as the primary demo account and capture all screens
npm run screenshots  # both of the above, in order
npm run typecheck    # type-check without running anything
```

**`npm run seed`** is safe to re-run: accounts, profiles, the friend
relationship, and custom drinks are created once and left alone. Only drink
history (`drink_entries` and the cheers/notifications derived from it) is
wiped and reinserted each run, with every entry's timestamp computed relative
to "now" so the history always ends today.

**`npm run capture`** requires the demo accounts to already be seeded — it
logs into the deployed web app as `demo@glasstrail.app` and overwrites the 10
feature screens (light + dark) plus the two `theme-demo-*` files directly in
`landing/assets/screenshots/`.

## Scope

Both scripts write to the **production** Supabase project
(`lzuxlcfjnekgjukqxoza`) and the **live deployed app**
(`glasstrail.vercel.app`) — there is no staging environment. Every write is
scoped to the two `demo@glasstrail.app` / `demo-friend@glasstrail.app`
accounts; no other user's data is ever touched.

Desktop-mode screenshots and the native Android push-notification screenshots
are out of scope for this script — see the design doc's "Deferred" section.
