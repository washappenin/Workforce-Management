# Aurelia Mobile (Flutter)

Production mobile client for the Workforce Management platform on iOS and Android.

> Lovable cannot build or preview Flutter. This directory exists for version
> control and Flutter-capable local/CI builds. The TanStack web app at the repo
> root is unaffected.

## Status

This Flutter app is the primary FE0-FE10 mobile client from
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
- FE10 Dart flavor entrypoints for Employee, Manager, Admin, and Platform apps

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
flutter run --flavor employee -t lib/main_employee.dart \
  --dart-define=APP_ENV=staging \
  --dart-define=API_BASE_URL=https://workforce-management-production.up.railway.app
```

`APP_ENV` defaults to `staging` and `API_BASE_URL` defaults to the current
Railway staging API, so local smoke runs still work without defines. Release
and CI builds should pass both values explicitly.

## Build

```bash
flutter build apk --debug --flavor employee -t lib/main_employee.dart \
  --dart-define=APP_ENV=staging \
  --dart-define=API_BASE_URL=https://workforce-management-production.up.railway.app
```

For production, pass the production API URL:

```bash
flutter build appbundle --release --flavor employee -t lib/main_employee.dart \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.example.com
```

Role-specific Android flavors:

```bash
flutter build apk --debug --flavor employee -t lib/main_employee.dart
flutter build apk --debug --flavor manager -t lib/main_manager.dart
flutter build apk --debug --flavor admin -t lib/main_admin.dart
flutter build apk --debug --flavor platform -t lib/main_platform.dart
```

iOS schemes remain tracked in `docs/MOBILE_FLAVOR_ARCHITECTURE.md`.

Role-specific iOS schemes are also scaffolded:

```bash
flutter build ios --debug --no-codesign --flavor employee -t lib/main_employee.dart
flutter build ios --debug --no-codesign --flavor manager -t lib/main_manager.dart
flutter build ios --debug --no-codesign --flavor admin -t lib/main_admin.dart
flutter build ios --debug --no-codesign --flavor platform -t lib/main_platform.dart
```

These commands require macOS and Xcode. Use the manual
`Mobile iOS Flavor Builds` GitHub Actions workflow for no-signing CI validation.
For the Mac handoff, use `docs/MAC_IOS_FLAVOR_VERIFICATION.md` or run:

```bash
bash scripts/verify_ios_flavors.sh
```

## CI

The repository includes `.github/workflows/mobile-ci.yml`, which runs:

- `dart format --set-exit-if-changed lib test integration_test`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug --flavor employee -t lib/main_employee.dart`
- `flutter build apk --debug --flavor manager -t lib/main_manager.dart`
- `flutter build apk --debug --flavor admin -t lib/main_admin.dart`
- `flutter build apk --debug --flavor platform -t lib/main_platform.dart`

## Architecture

```text
mobile/
  pubspec.yaml
  android/
  ios/
  lib/
    main.dart
    main_employee.dart
    main_manager.dart
    main_admin.dart
    main_platform.dart
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
