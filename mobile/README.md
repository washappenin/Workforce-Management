# Aurelia Mobile (Flutter)

Production mobile client for the Workforce Management platform on iOS and Android.

> Lovable cannot build or preview Flutter. This directory exists for version
> control and Flutter-capable local/CI builds. The TanStack web app at the repo
> root is unaffected.

## Status

This is the FE0 / FE1 scaffold from `docs/FRONTEND_CHECKPOINT_LOG.md`:

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

No FE2+ workflows. No fake data. No invented endpoints. No self-registration.
No biometric or GPS capture in this checkpoint.

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
flutter run
```

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
