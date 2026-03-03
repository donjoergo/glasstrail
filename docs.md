# Drink Tracking App Specification

## 1. Product Vision
A mobile-first Flutter app for logging drink consumption (alcoholic and non-alcoholic), tracking trends over time, and sharing activity with friends.

Core goals:
- Fast drink logging in under 10 seconds.
- Clear personal insights (daily/weekly/monthly trends).
- Social motivation through friend feed, cheers/comments, and badges.
- Cross-platform support for mobile first, desktop second.

## 2. Platforms, Tech, and UX Foundations
- Framework: Flutter
- Design system: Material 3
- Theme modes: `ThemeMode.system`, `ThemeMode.light`, `ThemeMode.dark`
- Languages: English (`en`) and German (`de`)
- Architecture: Multi-tenant (each user sees only own data + permitted friend content)

### 2.1 Global App Shell (Exact Flutter Elements)
- `MaterialApp.router`
- `ThemeData(useMaterial3: true)`
- `ColorScheme` (custom palette, see branding section)
- `Scaffold`
- `NavigationBar` (5 destinations)
- Global `FloatingActionButton` on all main pages except Add Drink page
- `SnackBar` for quick feedback
- `Dialog` / `AlertDialog` for confirmations and errors

## 3. Navigation Structure
Bottom navigation destinations:
1. Feed
2. Map
3. Add Drink (via center action / dedicated route)
4. Statistics
5. Profile

Routes (recommended):
- `/feed`
- `/map`
- `/drink/new`
- `/stats`
- `/profile`
- `/settings`
- `/onboarding/*`

## 4. Page-by-Page Specification

## 4.1 Feed Page
Purpose:
- Show a timeline of user + friends drink activity and badge events.

Main interactions:
- Cheer (like) a post.
- Comment on a post.
- Open user profile from post header.

Exact Flutter elements:
- `Scaffold`
- `RefreshIndicator`
- `CustomScrollView`
- `SliverAppBar` (pinned)
- `SliverList` / `ListView.builder`
- Feed card UI:
  - `Card`
  - `ListTile`
  - `CircleAvatar`
  - `Text`
  - `Wrap` + `Chip` (drink category, with-friends tags)
  - Optional `ClipRRect` + `Image.network` / `Image.file`
  - `Row`
  - `IconButton` (cheer, comment)
  - `Badge` / `Chip` for gamification events
- Empty/loading/error states:
  - `CircularProgressIndicator`
  - `Center`
  - `FilledButton` (retry)

Feed event types:
- Drink logged
- Badge unlocked (multiple badges can be condensed into one feed item)

## 4.2 Map Page
Purpose:
- Display geo-locations of drinks from user and friends.

Main interactions:
- Pan/zoom map.
- Tap markers to view drink details.
- Filter markers (mine/friends/category/date).

Exact Flutter elements:
- `Scaffold`
- `Stack`
- Map widget (package): `FlutterMap`
- Layers:
  - `TileLayer`
  - `MarkerLayer`
  - Optional `CircleLayer` (cluster/heat emphasis)
- Overlays:
  - `Positioned` filter panel (`Card`, `ChoiceChip`, `DropdownMenu`)
  - `FloatingActionButton.small` for recenter
  - Bottom detail sheet: `DraggableScrollableSheet`

Map behavior:
- Own drink logs appear at own location.
- Friends' drink logs appear at friend locations.

## 4.3 Add Drink Page
Purpose:
- Create a new drink entry with optional image, comment, and tagged friends.

Flow:
1. Choose drink (recent first + grouped by category)
2. Optional photo
3. Optional comment
4. Optional friends drinking together
5. Confirm entry

Exact Flutter elements:
- `Scaffold` (no global FAB here)
- `AppBar`
- `Form` + `GlobalKey<FormState>`
- Step UX:
  - Option A: `Stepper` (recommended)
  - Option B: `PageView` with next/back controls
- Drink selection:
  - `SearchAnchor` / `SearchBar`
  - `ListView.separated`
  - `ExpansionTile` for categories
  - `ListTile` for recent drinks
- Media/comment:
  - `OutlinedButton.icon` (pick image)
  - Preview via `ClipRRect` + `Image.file`
  - `TextFormField` (multiline comment)
- Friends tagging:
  - `FilterChip` list or `CheckboxListTile`
- Submit:
  - `FilledButton.icon` (large CTA)
  - `CircularProgressIndicator` during save

Validation rules:
- Required: drink name/category
- Optional: photo/comment/volume/friends

## 4.4 Statistics Page
Purpose:
- Show consumption trends and records.

Sub-pages:
1. Overview
2. Map
3. List

Exact Flutter elements:
- `Scaffold`
- `DefaultTabController`
- `TabBar`
- `TabBarView`

### 4.4.1 Statistics Overview
Content:
- Daily, weekly, monthly totals
- Category distribution
- Trend chart
- Current streak and best streak

Exact Flutter elements:
- `SingleChildScrollView`
- `Card`
- `ListTile`
- `GridView` (summary tiles)
- Chart widgets (package `fl_chart`):
  - `LineChart`
  - `BarChart`
  - `PieChart`
- `LinearProgressIndicator` for streak progress

### 4.4.2 Statistics Map
Content:
- Personal drink history map.

Exact Flutter elements:
- Same base as main map: `FlutterMap`, `TileLayer`, `MarkerLayer`
- Date range controls: `SegmentedButton` + `DateRangePickerDialog`

### 4.4.3 Statistics List
Content:
- Full drink history
- Totals by all drinks and per category
- Streak metrics

Exact Flutter elements:
- `ListView.builder`
- `ExpansionTile` (group by category/month)
- `DataTable` (totals and category breakdown)
- `Card` for streak stats

## 4.5 Profile Page
Purpose:
- User identity, badges, friends, and account actions.

Main interactions:
- Edit profile
- View badges
- Manage friends
- Open settings
- Log out

Exact Flutter elements:
- `Scaffold`
- `CustomScrollView`
- `SliverAppBar` (expanded header)
- Header:
  - `CircleAvatar`
  - `Text`
  - `FilledButton` (edit profile)
- Badges:
  - `Wrap`
  - `Chip` / `Badge`
- Friends:
  - `ListView.builder`
  - `ListTile`
  - `IconButton` (accept/reject/remove)
- Settings/logout:
  - `ListTile`
  - `SwitchListTile` / navigation tiles

## 4.6 Settings Page
Purpose:
- Configure theme/language and handle import.

Exact Flutter elements:
- `Scaffold`
- `ListView`
- Theme selection: `SegmentedButton<ThemeMode>`
- Language selection: `SegmentedButton<Locale>`
- Import section:
  - `ListTile`
  - `FilledButton` (pick file)
  - `AlertDialog` (validation results)
  - Optional `DataTable` (legacy glass-type mapping preview)

## 4.7 Onboarding + Invite Journey
Flow:
1. Open invite link
2. Register with email + password
3. Set nickname, display name, optional profile image
4. Land in feed

Exact Flutter elements:
- `Scaffold`
- `PageView` or route-per-step forms
- `Form`, `TextFormField`, `FilledButton`
- `CircleAvatar` + `OutlinedButton` for optional image
- `LinearProgressIndicator`

## 5. Core Functional Rules

## 5.1 Multi-Tenant and Privacy
- Every user has isolated personal data.
- Feed/map only include friend-authorized content.
- Friend requests must be accepted before shared visibility.

## 5.2 Friends and Social
- Send friend requests.
- Accept/reject requests.
- Activity from friends appears in feed + map.
- Logging with tagged friends sends targeted notifications.

## 5.3 Global and Personal Drink Catalog
Global categories include:
- Beer (Pils, Helles, Weizen, Kellerbier, Koelsch, Alt, IPA, ...)
- Wine (Red, White, Rose, Sparkling, Aperol Spritz, ...)
- Spirits (Vodka, Gin, Rum, Whiskey, Tequila, ...)
- Cocktails (Mojito, Margarita, Martini, ...)
- Non-alcoholic (Water, Juice, Tea, Coffee, Energy Drinks, Soft Drinks, ...)

Drink schema:
- `name` (required)
- `category` (required)
- `image` (required for catalog item)
- `volumeMl` (optional)

Users can:
- Add personal drinks
- Edit personal drinks

## 6. Import from Legacy App (BeeerWithMe)
Requirements:
- Import JSON file from settings.
- Validate structure and required fields.
- Show user-friendly error list.
- Map legacy glass types to default app glass types.

Suggested import pipeline:
1. Pick file
2. Parse JSON
3. Validate schema
4. Transform/match glass types
5. Preview import summary
6. Confirm and persist

## 7. Gamification

Badge categories:
- Total drinks logged
- Drinks with friends
- Special occasions
- Category mastery
- Streak milestones

### 7.1 Badge Name Ideas
Total drinks:
- First Sip (1)
- Social Sipper (10)
- Steady Tracker (50)
- Hydration Hero (100)
- Barrel Counter (200)
- Legend of the Tap (500)
- Mythic Pour (1000)

With friends:
- Cheers Buddy (1)
- Table Starter (10)
- Crew Classic (20)
- Party Anchor (50)
- Social Legend (100)

Category mastery examples:
- Beer: Hop Scholar
- Wine: Cellar Sensei
- Spirits: Barrel Sage
- Cocktails: Mixmaster
- Non-alcoholic: Clear Mind Captain

Streaks:
- 3, 7, 14, 30, 60, 90, 180, 365 days

Behavior:
- On each drink log, evaluate badge rules.
- If unlocked: show in-app animation + notification + profile badge update.

## 8. Notifications
### 8.1 Trigger Events
- Friend logged a drink (highest priority)
- Special occasions
- Friend request received
- Friend request accepted
- Friend request rejected
- Friend invitation events

### 8.2 Delivery Architecture
Pipeline:
1. API stores a domain event (example: `drink.logged`).
2. Worker resolves recipients (accepted friends only, respecting notification preferences).
3. Notification jobs are queued.
4. Push provider sends notifications to devices.
5. Delivery results are saved for retries and analytics.

Recommended provider stack:
- Push provider: Firebase Cloud Messaging (FCM)
- iOS transport: APNs through FCM
- Android transport: native FCM
- Queue/retry: Redis + BullMQ with exponential backoff
- Deep link target: `glasstrail://post/{postId}`

Token handling:
- Client registers token on login and app start.
- Backend stores `device_tokens(user_id, platform, token, last_seen_at, is_active)`.
- Invalid tokens are disabled on provider error responses.

### 8.3 Quick "Cheers" on Drink Notifications
Requirement:
- Friends can answer a drink notification with one tap `Cheers` directly from the notification.

Push payload (example):
```json
{
  "type": "drink_logged",
  "postId": "post_123",
  "actorUserId": "user_42",
  "title": "Alex logged a drink",
  "body": "IPA (0.5 L) at 19:42",
  "deeplink": "glasstrail://post/post_123",
  "actions": [
    { "id": "quick_cheers", "title": "Cheers" }
  ]
}
```

Interaction flow:
1. User A logs a drink.
2. Friends receive a push notification with action `Cheers`.
3. Friend B taps `Cheers` from the notification.
4. Client background handler sends `POST /v1/posts/{postId}/cheers` with `source=push_action`.
5. Backend stores reaction and updates feed counters.
6. User A optionally receives: `Friend B cheered your drink`.

Backend guarantees:
- Idempotent API behavior for `POST /v1/posts/{postId}/cheers`
- Unique DB constraint: `UNIQUE(post_id, user_id)` in `cheers`
- Safe duplicate response: `200` with `alreadyCheered: true`

Flutter implementation notes:
- `firebase_messaging` for foreground/background push handling
- `flutter_local_notifications` for actionable notification buttons
- Register action id `quick_cheers` and map to API call in background isolate

### 8.4 Notification Preferences
Per-user settings:
- Friend drink notifications on/off
- Quiet hours (`start`, `end`)
- Mute selected friends
- Language for push text (`en`, `de`)

### 8.5 Backend Tech Stack (Recommended)
Core services:
- Runtime: Node.js + TypeScript
- Framework: NestJS
- API: REST + WebSocket (for live feed updates)
- Auth: JWT access/refresh + invite-token onboarding

Data and infra:
- PostgreSQL as primary database
- PostGIS extension for map/location queries
- Prisma ORM
- Redis for cache and queueing
- BullMQ for background jobs (notifications, badge evaluation, imports)
- S3-compatible object storage for photos

Observability:
- Sentry for errors
- Prometheus + Grafana for metrics
- Structured logging with pino

### 8.6 Backend Modules and Core Endpoints
Recommended modules:
- `AuthService`
- `UserService`
- `FriendService`
- `DrinkService`
- `FeedService`
- `ReactionService`
- `BadgeService`
- `NotificationService`
- `ImportService`

First endpoints:
- `POST /v1/auth/register`
- `POST /v1/auth/login`
- `POST /v1/friends/requests`
- `POST /v1/friends/requests/{id}/accept`
- `POST /v1/drinks/log`
- `GET /v1/feed`
- `POST /v1/posts/{postId}/cheers`
- `POST /v1/posts/{postId}/comments`
- `POST /v1/devices/register`
- `PATCH /v1/notifications/preferences`

## 9. Localization and Crowdin Setup
Supported locales:
- `en`
- `de`

Flutter localization stack:
- `flutter_localizations`
- `intl`
- ARB files (`app_en.arb`, `app_de.arb`)

Recommended Crowdin steps:
1. Create Crowdin project.
2. Upload source ARB (`app_en.arb`).
3. Add German target language.
4. Configure integration (CLI or GitHub action).
5. Pull translated ARB files into project.
6. Regenerate localization classes.
7. Add localization QA checks in CI.

## 10. Final App Name
- `GlassTrail`

Optional tagline ideas:
- Track every sip.
- Your social drink timeline.
- Better habits, one glass at a time.

## 11. Selected Branding and Concrete ThemeData
Selected direction:
- `A: Fresh and Trustworthy`
- Brand personality: clean, calm, data-focused
- Primary: `#1F7A8C`
- Secondary: `#BFDBF7`
- Accent: `#F4A261`
- Light background: `#F8FAFC`
- Dark background: `#0F172A`
- Typography: Manrope (headlines), Inter (body)

Implementation notes:
- Add dependency: `google_fonts`
- Put this into `lib/theme/app_theme.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _primary = Color(0xFF1F7A8C);
  static const Color _secondary = Color(0xFFBFDBF7);
  static const Color _accent = Color(0xFFF4A261);
  static const Color _lightBackground = Color(0xFFF8FAFC);
  static const Color _darkBackground = Color(0xFF0F172A);
  static const Color _darkSurface = Color(0xFF1E293B);
  static const Color _error = Color(0xFFBA1A1A);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: _primary,
      secondary: _secondary,
      tertiary: _accent,
      error: _error,
      surface: Colors.white,
      onSurface: const Color(0xFF1B1C1E),
      outline: const Color(0xFF74777F),
      outlineVariant: const Color(0xFFC4C7CF),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _lightBackground,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, Brightness.light),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _lightBackground,
        foregroundColor: Color(0xFF1B1C1E),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: scheme.secondaryContainer,
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: _primary);
          }
          return const IconThemeData(color: Color(0xFF5A5E66));
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          final selected = states.contains(MaterialState.selected);
          return TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? _primary : const Color(0xFF5A5E66),
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: scheme.secondaryContainer,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1F2937),
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF8AD1E0),
      secondary: const Color(0xFFA8C7E7),
      tertiary: const Color(0xFFFFBB70),
      surface: _darkSurface,
      onSurface: const Color(0xFFE5E7EB),
      outline: const Color(0xFF8A9099),
      outlineVariant: const Color(0xFF3F4650),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _darkBackground,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, Brightness.dark),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _darkBackground,
        foregroundColor: Color(0xFFE5E7EB),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF111827),
        indicatorColor: scheme.primaryContainer,
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: Color(0xFF8AD1E0));
          }
          return const IconThemeData(color: Color(0xFF9CA3AF));
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          final selected = states.contains(MaterialState.selected);
          return TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color:
                selected ? const Color(0xFF8AD1E0) : const Color(0xFF9CA3AF),
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF8AD1E0),
        foregroundColor: Color(0xFF003640),
      ),
      cardTheme: CardTheme(
        color: _darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: scheme.primaryContainer,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF8AD1E0), width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0B1220),
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, Brightness brightness) {
    final body = GoogleFonts.interTextTheme(base);
    final textColor =
        brightness == Brightness.light ? const Color(0xFF1B1C1E) : Colors.white;

    return body.copyWith(
      displayLarge: GoogleFonts.manrope(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      displayMedium: GoogleFonts.manrope(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineLarge: GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      titleLarge: GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }
}
```

Usage in app root:

```dart
MaterialApp.router(
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  themeMode: ThemeMode.system,
  // routerConfig: ...
)
```

## 12. Suggested First Release Scope (MVP)
Include:
- Onboarding + auth
- Feed
- Add drink
- Basic map markers
- Statistics overview
- Friends + friend requests
- Push notifications for friend drink events
- Quick notification action: `Cheers`
- Theme/language settings

Defer to v1.1+:
- Advanced import mapping UI
- Occasion-specific badge packs
- Deep analytics filters
- Desktop-specific UI optimization
