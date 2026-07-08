# Achievements Repository and Deep-Link Contract

This document locks the Dart-side repository additions and route/deep-link shape for the achievements feature.

## New Model Types

Recommended new Dart types:

- `AchievementUnlock`
- `AchievementUnlockGrant`
- `AchievementUnlockRef`
- `SavedPlace`
- `SavedPlaceType`
- `FriendSharedAchievement`
- `FriendSharedAchievementFamily`
- `AchievementDeepLinkTarget`

Recommended enums:

- `SavedPlaceType.home`
- `SavedPlaceType.work`
- `AchievementRouteSource.pushReminder`
- `AchievementRouteSource.inApp`

## `AppRepository` Additions

Add these methods to `lib/src/repository/app_repository.dart`.

```dart
Future<List<AchievementUnlock>> loadAchievementUnlocks(String userId);

Future<List<AchievementUnlock>> upsertAchievementUnlocks({
  required String userId,
  required List<AchievementUnlockGrant> grants,
});

Future<void> markAchievementUnlocksSurfaced({
  required String userId,
  required List<AchievementUnlockRef> unlocks,
});

Future<List<SavedPlace>> loadSavedPlaces({
  required String userId,
  SavedPlaceType? placeType,
});

Future<SavedPlace> replaceActiveSavedPlace({
  required String userId,
  required SavedPlaceType placeType,
  required double latitude,
  required double longitude,
});

Future<void> deleteSavedPlace({
  required String userId,
  required String placeId,
});

Future<List<FriendSharedAchievementFamily>> loadFriendSharedAchievements({
  required String userId,
  required String friendUserId,
});
```

## Existing Method To Extend

Change the notification token registration signature to carry timezone data:

```dart
Future<void> registerNotificationDeviceToken({
  required String userId,
  required String token,
  required String platform,
  required String timeZone,
  required int utcOffsetMinutes,
});
```

Notes:

- `platform` remains `android` in v1 for real push delivery.
- The app should update timezone metadata on startup and foreground refresh.

## Repository Responsibilities

### Repository layer owns

- loading and persisting unlock rows
- persisting surfaced state
- saved place CRUD
- friend shared-achievement fetches
- timezone metadata writes for device tokens

### Repository layer does not own

- achievement rule evaluation
- progress calculation
- grouping catalog families for the UI
- “Earnable today” derivation

Those stay in the achievements evaluator / app-controller layer.

## Friend Shared Achievements Contract

`loadFriendSharedAchievements()` must:

- respect `shareAchievements`
- ignore `shareStatsWithFriends`
- return earned unlocked levels only
- return no progress values
- return no locked future levels

The friend stats screen remains the existing entry point. No separate friend-achievements route is introduced.

## Route Contract

Add to `lib/src/app_routes.dart`:

```dart
static const achievements = '/achievements';
static const achievementDetailPrefix = '/achievements/detail/';
```

Add helpers:

```dart
static String achievementDetailRoute(
  String familyId, {
  int? level,
  String? source,
});

static bool isAchievementDetailRoute(String? routeName);

static String? achievementDetailFamilyId(String? routeName);

static int? achievementDetailLevel(String? routeName);

static String? achievementDetailSource(String? routeName);
```

## Detail Route Shape

Canonical route:

```text
/achievements/detail/<familyId>?level=<int>&source=<string>
```

Examples:

- `/achievements/detail/occasion_oktoberfest?level=1&source=push_reminder`
- `/achievements/detail/type_beer?level=100&source=in_app`

Rules:

- `<familyId>` is the stable catalog family ID.
- `level` is optional.
- `source` is optional.
- `level` uses the stored level integer for ladder and one-off families.

## Restoration and Auth Rules

- `/achievements` is a normal home-shell route.
- `/achievements/detail/...` is a valid explicit post-auth redirect route.
- `/achievements/detail/...` is not a normal restorable route for app restart.
- The deep-link service must accept achievement detail routes the same way it already special-cases friend routes.

Update these route helpers accordingly:

- `normalize()`
- `isExplicitPostAuthRedirectRoute()`
- `postAuthRoute()`
- `isPostAuthRoute()`
- `isRestorable()`
- `homePrimaryRoute()`
- `isHomeShellRoute()`

Expected behavior:

- root Achievements tab restores normally
- detail sheet is reopened from push or explicit redirect only
- post-auth redirect preserves the exact targeted achievement detail

## Deep-Link Payload Contract

For reminder pushes, the canonical payload should include:

```json
{
  "route": "/achievements/detail/occasion_oktoberfest?level=1&source=push_reminder",
  "familyId": "occasion_oktoberfest",
  "level": 1,
  "source": "push_reminder"
}
```

Rules:

- `route` is the canonical field
- `familyId` and `level` are redundant helpers for resilience and debugging
- app code should derive the navigation target from `route` first

## Controller-Level Expectations

The app controller or a dedicated achievements coordinator should:

- load unlock rows
- run evaluation
- persist newly granted rows
- build owner-facing family state
- derive recent unlocks
- open detail sheets from deep-link targets

The repository should not return fully rendered achievement cards.

## Local vs Supabase Behavior

- Both repositories implement the same method surface.
- Local mode stays isolated from Supabase mode.
- No repository method should attempt a local-to-cloud achievement migration.

## Acceptance

- The repository surface is sufficient for the evaluator, UI, saved-place management, and friend sharing.
- The route contract supports in-tab detail sheets, push deep links, and post-auth redirect without becoming a restorable standalone page.
