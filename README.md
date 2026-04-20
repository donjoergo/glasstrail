# GlassTrail

[![Android Release](https://github.com/donjoergo/glasstrail/actions/workflows/android-release.yml/badge.svg)](https://github.com/donjoergo/glasstrail/actions/workflows/android-release.yml)
[![CI](https://github.com/donjoergo/glasstrail/actions/workflows/ci.yml/badge.svg)](https://github.com/donjoergo/glasstrail/actions/workflows/ci.yml)
[![Crowdin](https://badges.crowdin.net/glasstrail/localized.svg)](https://crowdin.com/project/glasstrail)

[Web App](https://glasstrail.vercel.app/) | [Android App](https://github.com/donjoergo/glasstrail/releases)

GlassTrail is a Flutter app for tracking drinks, reviewing personal habits in statistics, and sharing the drinks and cheering with friends. The initial idea was to make a worthy successor to [Beer With Me](https://play.google.com/store/apps/details?id=se.dagsappar.beer&hl=de) with modern design and a few extra perks.

## Features

- Intuitive drink logging with photo, location and comment
- Feed view for past entries
- Statistics with streaks, category breakdown, map, and gallery
- Global drink catalog plus user-defined custom drinks
- Bar management with drink sorting, visibility controls, and custom drinks
- Email/password sign-up and sign-in (as usual)
- Personal profile with display name, profile photo and birthday
- Left-handed mode
- Multi device support: See your drinks, statistics, and profile on multiple devices
- Multi platform support: Android and Web
- Multi language support: English and German

## App Pages

The app exposes one route per visible page. On Flutter Web, in-app routing currently uses hash URLs, so bookmarks look like `/#/feed`. Public friend profile shares use non-hash URLs so messengers can render link previews.

| Page         | Route           | Purpose                                             |
| ------------ | --------------- | --------------------------------------------------- |
| Auth         | `/auth`         | Sign in and sign up                                 |
| Feed         | `/feed`         | Main history/feed view                              |
| Statistics   | `/statistics`   | Trends, streaks, and category breakdown             |
| Bar          | `/bar`          | Organize the drink catalog and manage custom drinks |
| Profile      | `/profile`      | Profile summary and app settings                    |
| Edit Profile | `/profile/edit` | Dedicated profile editing page                      |
| Friend Profile | `/friends/profile/<code>` | In-app friend profile route for sending requests |
| Add Drink    | `/add-drink`    | Log a drink from recent, global, or custom options  |

Additional routing behavior:

- `/` redirects to `/feed`
- Protected routes show the auth flow when the user is signed out
- After successful authentication, the app returns to the originally requested protected route
- Public friend profile links use `https://glasstrail.vercel.app/friends/profile/<code>` for previews
- In-app friend profile links use `https://glasstrail.vercel.app/#/friends/profile/<code>` for Flutter routing
- Friend profile links are reusable; signed-out viewers see a public invitation with a sign-in CTA
- On Flutter Web, a full browser reload restores the last visited page
- After an explicit logout, the next login lands on `/feed`

## Navigation Map

```mermaid
flowchart TD
    Root["/"] --> Feed["/feed"]

    Feed <--> Statistics["/statistics"]
    Statistics <--> Bar["/bar"]
    Bar <--> Profile["/profile"]
    Profile <--> Feed

    Feed --> AddDrink["/add-drink"]
    Statistics --> AddDrink
    Bar --> AddDrink
    Profile --> AddDrink

    Profile --> EditProfile["/profile/edit"]

    Auth["/auth"] --> Requested["requested protected route"]
    Auth --> Feed
```

## App Architecture

The UI is driven by `GlassTrailApp`, coordinated by `AppController`, and backed by an `AppRepository` implementation chosen at bootstrap time.

```mermaid
flowchart LR
    App["GlassTrailApp"] --> Scope["AppScope"]
    Scope --> Controller["AppController"]
    Controller --> Stats["StatsCalculator"]
    Controller --> Repo["AppRepository"]

    Repo --> SupabaseRepo["SupabaseAppRepository"]
    Repo --> LocalRepo["LocalAppRepository"]

    SupabaseRepo --> Auth["Supabase Auth"]
    SupabaseRepo --> Postgres["Postgres + RLS"]
    SupabaseRepo --> Storage["Storage bucket: user-media"]

    LocalRepo --> Prefs["SharedPreferences"]
```

## Main User Flows

```mermaid
sequenceDiagram
    participant U as User
    participant UI as Flutter UI
    participant C as AppController
    participant R as Repository
    participant B as Backend

    U->>UI: Sign in / sign up
    UI->>C: signIn() / signUp()
    C->>R: authenticate user
    R->>B: auth request
    B-->>R: session + profile
    R-->>C: current user
    C->>R: load settings, drinks, entries
    R->>B: fetch user scope
    B-->>R: data
    R-->>C: hydrated state
    C-->>UI: rebuild visible route

    U->>UI: Add drink
    UI->>C: addDrinkEntry(...)
    C->>R: persist entry
    R->>B: insert drink entry
    B-->>R: saved entry
    R-->>C: saved entry
    C-->>UI: feed + statistics update
```

## Development

Install dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

### Environment Variables

Override flutter environment variables if needed:

| Variable            | Purpose                              |
| ------------------- | ------------------------------------ |
| SUPABASE_URL        | Supabase URL                         |
| SUPABASE_ANON_KEY   | Supabase anon key                    |
| FORCE_UPDATE_NOTICE | Force update/changlog notice in feed |
| FRIEND_PROFILE_BASE_URL | Base URL for public reusable friend profile links |

Example:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY \
  --dart-define=FORCE_UPDATE_NOTICE=true
```

### Public Friend Profile Previews

Messenger link previews are served by the Vercel Serverless Function in `api/friend-profile-preview.js`, because Supabase Edge Functions rewrite `text/html` responses to `text/plain` for `GET` requests. The production Vercel rewrite in `vercel.json` maps `https://glasstrail.vercel.app/friends/profile/<code>` to that Vercel Function while keeping the Glass Trail URL visible.

The Supabase Edge Function in `supabase/functions/friend-profile-preview` serves public preview JSON and redirects profile image requests. The Flutter app and the Vercel Function both use that JSON endpoint.

Configure these Supabase function secrets before deployment:

| Secret | Purpose |
| ------ | ------- |
| SUPABASE_URL | Supabase project URL |
| SUPABASE_SERVICE_ROLE_KEY | Server-only key for reading limited profile preview data and signing profile images |
| FRIEND_PROFILE_PUBLIC_BASE_URL | Public Glass Trail base URL, defaults to `https://glasstrail.vercel.app` |
| FRIEND_PROFILE_APP_ICON_PATH | Optional fallback preview image path, defaults to `/icons/Icon-512.png` |

The Supabase function is configured as public in `supabase/config.toml`:

```bash
npx supabase functions deploy friend-profile-preview
```

Configure these Vercel environment variables if the defaults are not correct:

| Variable | Purpose |
| -------- | ------- |
| FRIEND_PROFILE_DATA_BASE_URL | Supabase preview data endpoint, defaults to the production `friend-profile-preview` function URL |
| FRIEND_PROFILE_PUBLIC_BASE_URL | Public Glass Trail base URL, defaults to `https://glasstrail.vercel.app` |

### Verification

Static analysis:

```bash
flutter analyze
```

Format all files:

```bash
dart format .
```

Unit and widget tests:

```bash
flutter test
```

Integration tests:

```bash
flutter test integration_test
```

### Changelog

Use [cider](https://pub.dev/packages/cider) to create a changelog.

Examples:

```bash
cider log added "new feature"
```

or 

```bash
cider log fixed "a bug"
```

## Deployment and releases

### Creating a Release

1. Update `pubspec.yaml` with the app version you want to ship.
2. Update the changelog with the command `cider release`
3. Commit and push that change to `main`.
4. Create and push a tag such as `1.0.0`.
5. Merge `main` into `release` branch

```bash
git tag 1.0.0
git push origin 1.0.0
```

When the tag reaches GitHub, the workflow builds `app-release.apk` and attaches it to the matching release as `glasstrail-v1.0.0.apk`.

### Vercel

GlassTrail is connected to Vercel for web deployment.

`release` branch is CD deployed to [glasstrail.vercel.app](https://glasstrail.vercel.app/).

`main` branch is CD deployed to [glasstrailtest.vercel.app](https://glasstrailtest.vercel.app/).

### Android Releases

On every newly created tag, a CD workflow builds an APK and creates a release on GitHub.

#### Keystore

The workflow expects a real Android release keystore. `android/app/build.gradle.kts` reads `android/key.properties` when it exists and uses that release signing config. If the file is absent, local release builds still fall back to the debug key.

Create an upload keystore locally:

```bash
keytool -genkeypair \
  -v \
  -keystore upload-keystore.jks \
  -alias upload \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

Base64-encode it for GitHub Actions:

```bash
base64 -w 0 upload-keystore.jks
```

Add these repository secrets in GitHub:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

No extra Supabase secrets are required for the current production build because the app already has production defaults in `lib/src/backend_config.dart`.
