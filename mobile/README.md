# Aurelia Mobile (Flutter)

Production mobile client for the Workforce Management platform on iOS and Android.

> Lovable cannot build or preview Flutter. This directory exists for version
> control and Flutter-capable local/CI builds. The TanStack web app at the repo
> root is unaffected.

## Status

This Flutter app is the primary FE0-FE9 mobile client from
`docs/FRONTEND_CHECKPOINT_LOG.md`:

- Project structure, theme, and routing
- Android and iOS platform project folders
- Central API client (`https://workforce-management-production.up.railway.app`)
- Secure token storage (`flutter_secure_storage`)
- Login -> `POST /api/auth/login`
- Session hydration -> `GET /api/auth/me`
- Logout -> `POST /api/auth/logout`
- Role-based redirects (`SUPER_ADMIN`, `COMPANY_ADMIN`, `HR_ADMIN`, `MANAGER`, `EMPLOYEE`)
- Mobile app shell with bottom navigation
- Notification unread count via `GET /api/notifications/me/unread-count`
- Shared loading, empty, access-denied, not-found, validation, connection, and expired-session states
- Employee self-service, face/GPS attendance, admin setup/operations, manager workflows, super-admin workflows, reports, and launch-gate staging QA

No fake data. No invented endpoints. No self-registration.

## Prerequisites

- Flutter 3.24+ (Dart 3.5+)
- Xcode 15+ for iOS builds
- Android Studio with SDK 34+ for Android builds

## Run

```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run \
  --dart-define=APP_ENV=staging \
  --dart-define=API_BASE_URL=https://workforce-management-production.up.railway.app
```

`APP_ENV` defaults to `staging` and `API_BASE_URL` defaults to the current
Railway staging API, so local smoke runs still work without defines. Release
and CI builds should pass both values explicitly.

## Build

```bash
flutter build apk --debug \
  --dart-define=APP_ENV=staging \
  --dart-define=API_BASE_URL=https://workforce-management-production.up.railway.app
```

For production, pass the production API URL:

```bash
flutter build appbundle --release \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.example.com
```

## CI

The repository includes `.github/workflows/mobile-ci.yml`, which runs:

- `dart format --set-exit-if-changed lib test integration_test`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`

## Architecture

```text
mobile/
  pubspec.yaml
  android/
  ios/
  lib/
    main.dart
    app.dart
    core/
      api/        Dio client, interceptors, API failures
      auth/       AuthController, session models, secure storage
      routing/    go_router and auth-aware redirects
      config/     APP_ENV and API_BASE_URL dart-define config
      theme/      Aurelia royal-minimal theme
      errors/     Typed failures
    features/
      auth/       Login screen
      shell/      Bottom navigation app shell
      employee/   Dashboard placeholder
      manager/    Dashboard placeholder
      admin/      Dashboard placeholder
      super_admin/Dashboard placeholder
      notifications/ Unread count and inbox placeholder
    shared/
      widgets/    Loading, empty, error, access-denied, and related states
```

State management: `flutter_riverpod`.
Routing: `go_router`.
HTTP: `dio`.
Secure storage: `flutter_secure_storage` using Keychain / Keystore where available.
