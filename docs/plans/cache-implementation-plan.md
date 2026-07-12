# Cache Implementation Plan

## Goals

- Faster app startup for returning signed-in users
- Smoother UX by rendering from local state first and reconciling in the background
- Lower backend traffic by skipping unnecessary reads for fresh data
- Persistent media caching for drink log images, profile images, and custom drink images

## Agreed Scope

- Use stale-while-revalidate as the default startup contract
- Optimize returning signed-in launches first
- Keep `LocalAppRepository` as the full offline fallback mode
- Put cache logic in a repository decorator, not directly in `AppController`
- Use per-domain freshness windows, not one global TTL
- Cache the bootstrap payload:
  - global catalog
  - custom drinks
  - full entries
  - first feed page
  - settings
  - friend connections
  - notifications
- Recompute derived statistics from cached entries instead of caching statistics separately
- Use write-through cache updates after successful mutations
- Use targeted invalidation per domain after writes
- Enter the signed-in shell from local auth session plus cached user snapshot without waiting for remote profile bootstrap
- Keep notifications boot-cacheable, then revalidate them immediately after launch
- Revalidate hot domains on app resume if they are stale
- Ship data cache and persistent media cache in one implementation stream
- Use a file-backed data cache
- Use a custom persistent media cache keyed by canonical Supabase storage path, not signed URL
- Cache current-user and friend-owned media that was legitimately viewed in-session
- Purge user-scoped data and media caches on sign out
- Use schema-versioned cache manifests and automatic hard drops on incompatibility
- Add developer-facing cache observability

## Default Freshness Windows

| Domain | Freshness window |
| --- | --- |
| Global catalog | 7 days |
| Settings | 1 hour |
| Custom drinks | 10 minutes |
| Friend connections | 10 minutes |
| Entries | 2 minutes |
| First feed page | 2 minutes |
| Notifications | Boot cache only, then immediate refresh |

## Proposed Files

### Data cache

- `lib/src/cache/cache_manifest.dart`
- `lib/src/cache/bootstrap_snapshot.dart`
- `lib/src/cache/bootstrap_cache_store.dart`
- `lib/src/cache/cache_policy.dart`
- `lib/src/repository/cached_app_repository.dart`
- `lib/src/bootstrap/app_bootstrap_loader.dart`
- `lib/src/cache/cache_debug_report.dart`

### Media cache

- `lib/src/cache/media_cache_manifest.dart`
- `lib/src/cache/media_cache_entry.dart`
- `lib/src/cache/media_cache_store.dart`

### Tests

- `test/bootstrap_cache_store_test.dart`
- `test/cached_app_repository_test.dart`
- `test/media_cache_store_test.dart`

## Implementation Plan

1. Add cache DTOs, manifests, schema versioning, and cache policy constants.
2. Add file-backed bootstrap snapshot storage with atomic writes and safe reads.
3. Add a `CachedAppRepository` that wraps `SupabaseAppRepository`.
4. Refactor repository creation so the Supabase path uses the cache decorator.
5. Add an `AppBootstrapLoader` that can hydrate from local auth state plus cached bootstrap state.
6. Refactor startup in `app.dart` and `app_controller.dart` to use cached bootstrap first and background reconciliation second.
7. Remove blocking remote profile bootstrap work from the returning-user critical path.
8. Add lifecycle-based revalidation for hot domains.
9. Add a persistent disk media cache with canonical-path keys, schema versioning, and LRU eviction.
10. Integrate the media cache into `AppMediaResolver`.
11. Add small targeted media warming for above-the-fold assets only.
12. Add purge logic for user-scoped data and media caches on sign out.
13. Add developer-facing cache reporting.
14. Add focused data-cache, media-cache, and startup tests.
15. Run final formatting, analysis, and test verification.

## Task Checklist With Acceptance Criteria

- [ ] Define cache models and versioning.
  AC: Typed cache models exist for the bootstrap snapshot and per-domain metadata. A single schema version constant exists. Feed posts and feed cursor state can be serialized and restored without losing ordering or pagination state.

- [ ] Add file-backed bootstrap cache storage.
  AC: Snapshot and manifest can be written and read from disk. Cache reads never crash the app on missing, corrupt, or outdated files. Partial writes do not replace the last valid snapshot.

- [ ] Add cache policy rules.
  AC: Freshness is decided per domain through one centralized policy. All agreed TTLs are encoded in code and tested independently of network calls.

- [ ] Implement `CachedAppRepository`.
  AC: Fresh reads can skip backend calls. Stale reads can still serve cached startup data when appropriate. Successful mutations update or invalidate only affected cached domains.

- [ ] Refactor repository creation.
  AC: The Supabase-backed path is wrapped in `CachedAppRepository`. `LocalAppRepository` remains unchanged and keeps its current semantics.

- [ ] Introduce `AppBootstrapLoader`.
  AC: Returning signed-in startup can obtain local auth session state, cached `AppUser`, and cached bootstrap data without requiring remote profile bootstrap before rendering the shell.

- [ ] Refactor app startup to use cached bootstrap.
  AC: The signed-in shell can render from cached bootstrap data before remote reconciliation finishes. Background reconciliation updates state without wiping the visible shell back to a loading screen.

- [ ] Remove remote profile work from the critical path.
  AC: Returning signed-in launches do not block on `_ensureProfile()` or settings-row creation before rendering. Sign-in and sign-up still reconcile authoritative server state correctly.

- [ ] Add lifecycle revalidation.
  AC: Notifications refresh immediately after boot. Hot domains refresh on foreground resume only when stale. Explicit pull-to-refresh still forces authoritative reloads.

- [ ] Add persistent media cache storage.
  AC: Media files are stored on disk by canonical storage path, not signed URL. The cache has a schema version, a hard size budget, and LRU eviction behavior.

- [ ] Integrate media cache into image resolution.
  AC: Canonical Supabase storage paths resolve through disk cache first, then signed download, then cached reuse. Signed URL rotation still produces cache hits for the same asset. Public remote URLs are not persistently cached in v1.

- [ ] Add targeted media warming.
  AC: Only immediately visible assets from initial feed, notifications, current profile, and visible custom drinks are warmed. App startup does not eagerly download the full media corpus.

- [ ] Add purge and privacy handling.
  AC: Signing out removes user-scoped bootstrap cache and user-scoped persistent media, including friend-owned media viewed in-session. Incompatible cache schema versions are dropped automatically.

- [ ] Add debug visibility.
  AC: A developer-facing report or log can show per-domain hit or miss state, cache age, last refresh result, media cache size, item count, and eviction stats.

- [ ] Add data-cache tests.
  AC: Tests cover snapshot storage, schema invalidation, per-domain TTL decisions, cached repository read behavior, write-through updates, atomic writes, and sign-out purge.

- [ ] Add media-cache tests.
  AC: Tests cover canonical-path keying, signed URL churn, persistence across restart, LRU eviction, unsupported public URL behavior, and sign-out purge.

- [ ] Add startup and widget verification.
  AC: Widget or app tests demonstrate that a returning signed-in user can see usable shell UI from cache before background reconciliation completes.

- [ ] Run final verification.
  AC: Formatting passes, analysis passes, targeted tests pass, and the full repository test run is green.

## Verification Notes

- Documentation-only change: no runtime verification is required for this note itself.
- When implementation starts, verification should follow the repository flow:
  - format
  - analyze
  - targeted tests for changed cache areas
  - final full test run
