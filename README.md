# GlassTrail

Flutter app for drink tracking, feed, map, stats, friends, onboarding, and settings.

## Run Locally

```bash
flutter pub get
flutter run -d chrome
```

By default the app runs with local mock data.

## Enable Backend API Wiring

API integration is implemented in `lib/api/backend_api.dart` and consumed by
`lib/state/app_controller.dart`.

Enable remote backend calls with Dart defines:

```bash
flutter run -d chrome \
  --dart-define=USE_REMOTE_API=true \
  --dart-define=API_BASE_URL=http://localhost:3000
```

Optional invite token for onboarding/register:

```bash
--dart-define=INVITE_TOKEN=<token>
```

## Wired Endpoints

- `POST /v1/auth/register`
- `POST /v1/auth/login`
- `GET /v1/feed`
- `POST /v1/drinks/log`
- `POST /v1/posts/{postId}/cheers`
- `POST /v1/posts/{postId}/comments`
- `GET /v1/friends`
- `POST /v1/friends/requests`
- `POST /v1/friends/requests/{id}/accept`
- `POST /v1/friends/requests/{id}/reject`
- `DELETE /v1/friends/{id}`
- `PATCH /v1/notifications/preferences`
- `POST /v1/devices/register`
