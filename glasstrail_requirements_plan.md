# GlassTrail Requirements Breakdown And Implementation Plan

## Overview

This document turns the raw requirements from `docs_initial_draft.md` into a prioritized, individually implementable backlog for GlassTrail.

## Product Direction Used For Prioritization

- App name: `GlassTrail`
- Frontend: `Flutter`
- Recommended backend for implementation: `Supabase`
- V1 goal: `personal drink-tracking MVP`
- Social features, live map, achievements, import, and invite-only onboarding are planned for later phases

## Backend Options

| Option | Pros | Cons | Recommendation |
| --- | --- | --- | --- |
| Supabase | Postgres, auth, storage, and realtime in one stack; good Flutter support; row-level security fits multi-tenant data well | Push notifications still need extra integration; some custom workflows need Edge Functions | Recommended |
| Firebase | Fast mobile setup, strong auth, messaging, analytics, and storage | Firestore data modeling is less comfortable for relational social features and reporting | Good alternative |
| Custom backend (`NestJS` + `Postgres`) | Maximum flexibility and full control over domain logic | Highest setup and maintenance cost for a first release | Use only if full custom control is required |

## Branding And Design Baseline

- Design style: modern `Material 3`
- Platforms: mobile first, desktop adaptive
- Themes: `light`, `dark`, and `system`
- Languages: `English` and `German`

### Suggested Brand Direction

- Brand idea: social drink tracking with a clean, friendly, premium look
- Tone: modern, social, calm, trustworthy
- Icon direction: glass silhouette plus trail or ripple motif
- UI shape language: rounded cards, clear spacing, strong category color coding

### Suggested Color Palette

| Token | Color | Usage |
| --- | --- | --- |
| Primary | `#2D6A4F` | Main actions, highlights, active states |
| Secondary | `#4D908E` | Supporting accents, filters, secondary buttons |
| Tertiary | `#E9C46A` | Achievements, streaks, celebratory highlights |
| Background Light | `#F6F7F4` | Light mode background |
| Surface Light | `#FFFFFF` | Cards and sheets in light mode |
| Background Dark | `#101418` | Dark mode background |
| Surface Dark | `#182028` | Cards and sheets in dark mode |
| Error | `#C44536` | Validation and destructive actions |

## Priority Model

- `Must have`: required for the first useful release
- `Should have`: important expansion after V1
- `Nice to have`: valuable polish or advanced functionality

## Status Legend

- `✅` implemented
- `⚠️` partially implemented
- `⬜` not implemented yet

## Prioritized Task Backlog

| ID | Status | Task | Priority | Target | Notes |
| --- | --- | --- | --- | --- | --- |
| GT-001 | ✅ | Define release scope, success criteria, and feature cut line for V1 | Must have | V1 | Lock V1 as personal tracker MVP |
| GT-002 | ⚠️ | Create brand kit, color tokens, typography, icon direction, and component style rules | Must have | V1 | Supports consistent Flutter UI implementation |
| GT-003 | ✅ | Bootstrap Flutter app structure with navigation shell and bottom navigation | Must have | V1 | Feed/history, add drink, statistics, profile |
| GT-004 | ✅ | Implement global floating action button behavior on all main screens except add drink | Must have | V1 | Matches app navigation requirement |
| GT-005 | ✅ | Set up light, dark, and system theme modes with persistent preference | Must have | V1 | Settings requirement |
| GT-006 | ✅ | Add English and German localization framework and translated base UI strings | Must have | V1 | Internationalization foundation |
| GT-007 | ✅ | Create responsive layouts for mobile first with desktop-safe adaptations | Must have | V1 | Desktop considered, mobile prioritized |
| GT-008 | ⚠️ | Provision Supabase project, environments, auth, database, and storage | Must have | V1 | Backend foundation |
| GT-009 | ✅ | Design database schema for users, profiles, drinks, drink entries, settings, and stats | Must have | V1 | Core data model |
| GT-010 | ✅ | Implement row-level security and per-user data isolation | Must have | V1 | Multi-tenant requirement |
| GT-011 | ✅ | Implement email and password sign-up, sign-in, sign-out, and session handling | Must have | V1 | Basic onboarding for first release |
| GT-012 | ✅ | Implement profile setup and editing for nickname, display name, picture, and birthday | Must have | V1 | Birthday stays optional |
| GT-013 | ✅ | Seed the global drink catalog with categories and starter drink list | Must have | V1 | Shared default catalog |
| GT-014 | ✅ | Implement user-managed custom drink creation and editing | Must have | V1 | User-specific drink list extension |
| GT-015 | ✅ | Build drink picker with recent drinks first, grouped categories, and easy selection UX | Must have | V1 | Core add-drink usability |
| GT-016 | ✅ | Implement add-drink form with optional photo, optional comment, and confirm action | Must have | V1 | Core logging flow |
| GT-017 | ✅ | Support drink image upload and storage for drink entries | Must have | V1 | Media handling |
| GT-018 | ✅ | Implement personal drink history list as the V1 version of the feed | Must have | V1 | Social feed deferred |
| GT-019 | ✅ | Implement statistics overview with weekly, monthly, and yearly totals | Must have | V1 | Core consumption insight |
| GT-020 | ✅ | Implement current streak and best streak calculation | Must have | V1 | Statistics requirement |
| GT-021 | ✅ | Implement category distribution chart for consumption by category | Must have | V1 | Pie chart requirement |
| GT-022 | ✅ | Implement statistics list view with all drinks and category filtering | Must have | V1 | History analysis |
| GT-023 | ✅ | Implement settings for language, theme, and units (`ml`/`oz`) | Must have | V1 | Required settings |
| GT-024 | ⚠️ | Add validation, empty states, error handling, and loading states across the app | Must have | V1 | Essential UX hardening |
| GT-025 | ⬜ | Add analytics, crash/error logging, and basic release configuration | Must have | V1 | Release readiness |
| GT-026 | ⚠️ | Create automated tests for auth, drink logging, stats, settings, and data isolation | Must have | V1 | Quality gate for first release |
| GT-027 | ⬜ | Implement user discovery and search for adding friends | Should have | Later | Needed before social graph can scale |
| GT-028 | ⬜ | Implement friend requests with send, accept, reject, and pending states | Should have | Later | Social graph foundation |
| GT-029 | ⬜ | Implement friends list management on the profile screen | Should have | Later | Social profile completion |
| GT-030 | ⬜ | Implement social feed with user and friend drink posts | Should have | Later | Expands V1 personal history |
| GT-031 | ⬜ | Add cheers/likes to feed posts | Should have | Later | Feed interaction |
| GT-032 | ⬜ | Add comments on feed posts | Should have | Later | Feed interaction |
| GT-033 | ⬜ | Add push notifications for friend drink logs | Should have | Later | Highest-priority notification feature |
| GT-034 | ⬜ | Add push notifications for friend requests and request responses | Should have | Later | Social notification set |
| GT-035 | ⬜ | Add invite-link onboarding flow | Should have | Later | Deferred from V1 |
| GT-036 | ⬜ | Add notify-friends toggle to the add-drink form | Should have | Later | Only useful once social notifications exist |
| GT-037 | ⬜ | Design achievement definitions, categories, levels, and naming system | Should have | Later | Gamification foundation |
| GT-038 | ⬜ | Implement achievement evaluation when logging drinks | Should have | Later | Unlock logic |
| GT-039 | ⬜ | Show earned and locked achievements in the profile with detail views | Should have | Later | Profile enhancement |
| GT-040 | ⬜ | Show achievement unlocks in the feed and condense multiple unlocks into one entry | Should have | Later | Feed enhancement |
| GT-041 | ⬜ | Add achievement celebration animation and in-app unlock notification | Should have | Later | UX polish tied to achievements |
| GT-042 | ⬜ | Implement BeerWithMe import parser and JSON validation | Should have | Later | Needs sample import file |
| GT-043 | ⬜ | Map BeerWithMe glass types to GlassTrail default glass types | Should have | Later | Import conversion logic |
| GT-044 | ⬜ | Build import UI, progress reporting, and validation error summary | Should have | Later | Settings import feature |
| GT-045 | ⬜ | Add optional import prompt during onboarding | Should have | Later | Depends on import flow |
| GT-046 | ⬜ | Add feedback/report issue form | Should have | Later | Product feedback loop |
| GT-047 | ⬜ | Add suggest-a-feature form | Should have | Later | Product feedback loop |
| GT-048 | ⬜ | Add suggest-a-drink flow for the global drink list | Should have | Later | Content growth |
| GT-049 | ⬜ | Build admin workflow for reviewing suggested global drinks | Should have | Later | Backoffice/content moderation |
| GT-050 | ⬜ | Implement live map with current user location and active drink markers | Nice to have | Later | Requires location permissions |
| GT-051 | ⬜ | Show friend drink markers on the live map | Nice to have | Later | Depends on social graph and privacy rules |
| GT-052 | ⬜ | Fade out and remove map markers after a configured time window | Nice to have | Later | Temporal map behavior |
| GT-053 | ⬜ | Build statistics map with all historical drink locations | Nice to have | Later | Separate from live map |
| GT-054 | ⬜ | Add special-occasion achievements and notifications | Nice to have | Later | Birthday, holidays, seasonal events |
| GT-055 | ⬜ | Add richer desktop layouts beyond responsive safety | Nice to have | Later | Post-mobile polish |

## V1 Scope

The first version should include these tasks:

- `GT-001` through `GT-026`

This gives GlassTrail a usable first release with:

- account creation and profile basics
- private, multi-tenant drink tracking
- global and custom drink lists
- drink logging with photos and comments
- personal history
- useful consumption statistics
- theme, language, and unit settings

## Later Releases

These tasks should be implemented after V1:

- `GT-027` through `GT-055`

This later scope covers:

- the full social layer
- notifications
- invite-based onboarding
- achievements and gamification
- BeerWithMe import
- feedback tooling
- map-based features

## Recommended Implementation Phases

### Phase 1: Foundation

- Complete `GT-001` to `GT-012`
- Deliver the app shell, design system, localization, backend setup, auth, and profile foundation

### Phase 2: Core Drink Tracking

- Complete `GT-013` to `GT-018`
- Deliver the drink catalog, custom drinks, and add-drink flow

### Phase 3: Insights And Release Hardening

- Complete `GT-019` to `GT-026`
- Deliver statistics, settings, validation, tests, and release readiness

### Phase 4: Social Layer

- Complete `GT-027` to `GT-036`
- Deliver friends, social feed, and social notifications

### Phase 5: Engagement Features

- Complete `GT-037` to `GT-049`
- Deliver achievements, import, and feedback systems

### Phase 6: Map And Advanced Polish

- Complete `GT-050` to `GT-055`
- Deliver live map, historical map, event-based achievements, and advanced desktop polish

## Key Technical Notes

- Use Supabase row-level security from the start so the app is correctly multi-tenant.
- Model drink categories and drinks separately so statistics and filtering stay simple.
- Keep the V1 feed as a personal activity history; do not build dead social controls before social features exist.
- Store location only when map features are introduced; do not collect it in V1.
- Keep achievements data-driven so new achievements can be added without rewriting business logic.

## Acceptance Criteria For V1

- A user can create an account, sign in, sign out, and edit profile data.
- A user can browse the default drink catalog and create personal custom drinks.
- A user can log a drink with optional photo and comment.
- A user can view their own history of logged drinks.
- A user can see weekly, monthly, yearly, streak, and category statistics.
- Theme, language, and unit preferences can be changed in settings.
- User data is isolated from other users by backend policy.
- Core flows are covered by automated tests and basic release checks.
