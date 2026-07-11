# Screenshot automation design

## Problem

Landing page and README screenshots are currently taken manually from the
author's personal GlassTrail account, risking leaking private drink/photo
data and requiring manual re-capture whenever the UI changes. We want a
repeatable, scriptable pipeline backed by a dedicated demo account instead of
a real user's data.

## Goals

- A demo account (+ a second "friend" demo account) seeded with realistic,
  non-private example data: drink history, photos, custom drinks, a friend
  relationship, notifications.
- A script that captures light/dark screenshots of every landing-page feature
  screen by driving the real deployed web app as the demo account.
- Landing page and README share one set of screenshot assets — no more
  separately-cropped README copies.

## Non-goals

- CI/scheduled automation. This is a local, manually-run pipeline for now.
- Native mobile screenshot capture (Flutter integration_test on
  emulator/simulator). Capture happens against the Flutter web build.

## 1. Demo account & seed data

Location: `tool/seed_demo_account.dart` (or `.ts`, matching whichever the
capture script ends up using — see §2), run manually and re-run whenever
data needs refreshing.

Accounts (created once, reused across reseeds):
- `demo@glasstrail.app` — the primary account, the one screenshots are taken
  as.
- `demo-friend@glasstrail.app` — a second account so the feed, friend
  request/notification, and social screens have something to show.

Seeding, using the Supabase **service-role key**:
- `profiles` / `user_settings` for both accounts — display name, avatar
  (stock photo), reasonable defaults (streak-friendly settings, category
  variety enabled, left-handed mode off).
- `friend_relationships` row linking the two demo accounts.
- `user_drinks` — a couple of custom drinks on the primary account, to
  populate the "your bar" screens.
- `drink_entries` — a spread of ~2–3 weeks of varied-category entries with
  photos uploaded to the `user-media` storage bucket from a small fixed set
  of royalty-free stock images committed to the repo (e.g.
  `tool/seed_assets/stock_photos/`), plus location data for the map screen
  and comments for the feed.
- `notifications` — a few friend-request/new-friend/new-drink notifications
  from the friend account.
- `drink_entry_cheers` — a couple of cheers on feed entries.

**Reseed behavior:** re-running the script deletes and reinserts this
account's own rows (scoped strictly to the two demo user ids — it never
touches any other user's data), with all `drink_entries.consumed_at`
timestamps shifted so the history always ends "today" — i.e. the same
relative pattern (spread over the last ~2–3 weeks), not fixed calendar dates
that go stale. Everything else (accounts, profiles, friend relationship,
custom drinks) stays as-is on reseed; only the entry timestamps advance.

**Secrets:** the Supabase service-role key and demo account credentials live
in a local `.env` file (gitignored, never committed). Documented in a
`.env.example` with placeholder values.

## 2. Screenshot capture script

Location: `tool/screenshots/capture.ts`, a standalone Node + Playwright
script (not wired into any MCP tool — runs via `npm run screenshots` or
similar).

Flow:
1. Launch Chromium, emulate a phone viewport matching the current asset
   aspect ratio (1440×3000-equivalent device pixel ratio).
2. Log into `glasstrail.vercel.app` as `demo@glasstrail.app`.
3. For each of the 10 in-scope feature screens (feed, statistics cards, pie
   chart, map, gallery, history list, add-drink, bar — global, bar — own,
   account settings):
   - Navigate to the screen.
   - Toggle `data-theme` to `light`, wait for content/animations to settle,
     screenshot.
   - Toggle to `dark`, screenshot again.
4. Save raw captures to a scratch directory, named to match the existing
   `landing/assets/screenshots/<feature>-{light,dark}.jpg` convention.

Current state check: nearly every `*-light.jpg` in `landing/assets/screenshots/`
today is actually the same shared placeholder image (not a real capture),
and `account-settings`, `add-drink`, `statistics-list`, and `theme-demo` have
no real screenshot in *either* theme yet. This script replaces all of that
with real captures — including regenerating the dark-mode shots that exist
today, since those came from the author's personal account (the exact
privacy problem this whole pipeline exists to fix).

The interactive theme-slider demo (feature 11) reuses the feed capture: the
script copies the freshly-captured `feed-light.jpg` / `feed-dark.jpg` to
`theme-demo-light.jpg` / `theme-demo-dark.jpg` rather than capturing a
separate screen.

Two features are explicitly out of scope for this script, left untouched:
- **Feature 12 (desktop mode)** — TODO: desktop mode is still being built.
  Keeps its generated placeholder images until the real desktop UI exists,
  then this needs a follow-up capture pass (likely a wider viewport, no
  phone-frame).
- **Notifications** — `notifications-light.png` / `notifications-dark.png`
  depict the native Android push-notification banner (OS chrome), not the
  in-app `#/notifications` screen. Playwright only drives the web page, not
  Android's notification shade, so this can't be captured by this script.
  TODO: deferred to a manual/emulator-based follow-up; existing assets stay
  as-is for now.

## 3. Asset pipeline — single source of truth

`landing/assets/screenshots/` becomes the **only** place screenshots live.
`docs/screenshots/` is deleted entirely.

The capture script writes directly into `landing/assets/screenshots/`,
overwriting the existing files in place (same names, so `landing/index.html`
needs no changes).

README.md's 8 screenshot images switch from `docs/screenshots/<name>.jpg` to
GitHub's supported `<picture>` + `prefers-color-scheme` pattern, reusing the
same light/dark files as the landing page:

```html
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="landing/assets/screenshots/feed-dark.jpg">
  <img src="landing/assets/screenshots/feed-light.jpg" alt="Feed" width="180">
</picture>
```

Mapping (existing README entries → landing asset basenames, all already
present):

| README caption | landing basename |
|---|---|
| Feed | `feed` |
| Statistics | `statistics-cards` |
| Pie Chart | `statistics-piechart` |
| Drink Locations | `statistics-map` |
| Drink Gallery | `statistics-gallery` |
| Global Drinks | `bar-global` |
| Custom Drinks | `bar-own` |
| Notifications | `notifications` |

## Resolved

- Stock photos: a small royalty-free set, committed into the repo (not
  fetched at seed time).
- Login: the web build's auth flow has no CAPTCHA blocking headless
  Playwright login.

## Deferred (tracked as TODOs, not part of this pass)

- Desktop-mode screenshots (feature 12) — desktop mode is still being built;
  add real capture once it exists.
- Native Android push-notification screenshot — OS-level UI, needs a
  manual/emulator-based capture, not Playwright-automatable.
