# Mobile Flavor Architecture

## Purpose

The current Flutter client is one role-aware app. That was the right shape for
FE0-FE9 delivery and staging QA, but the scalable product shape is multiple
role-specific apps built from one shared Flutter codebase.

This document defines how to split the app into role-specific flavors without
duplicating the API client, auth, routing primitives, models, UI components, or
feature modules.

## Current Architecture Audit

Current mobile structure:

```text
mobile/
  lib/
    main.dart
    main_employee.dart
    main_manager.dart
    main_admin.dart
    main_platform.dart
    app.dart
    core/
      api/
      auth/
      config/
      errors/
      routing/
      theme/
    features/
      auth/
      employee/
      manager/
      admin/
      super_admin/
      notifications/
      shell/
    shared/
      widgets/
```

The existing architecture is already close to flavor-ready:

- `mobile/lib/main.dart` boots the unified development/QA app.
- `mobile/lib/main_employee.dart`, `main_manager.dart`, `main_admin.dart`, and
  `main_platform.dart` boot role-specific Dart targets.
- `mobile/lib/app.dart` owns the `MaterialApp.router` wrapper and
  `runAureliaApp(flavorConfig: ...)` bootstrap.
- `mobile/lib/core/config/app_flavor.dart` owns active flavor configuration.
- `mobile/lib/core/config/app_config.dart` already supports `APP_ENV` and
  `API_BASE_URL` through `--dart-define`.
- `mobile/lib/core/routing/router.dart` owns one global `GoRouter`, all role
  routes, `landingFor(AppRole)`, and `_roleAllowed(...)`.
- `mobile/lib/features/shell/app_shell.dart` owns one shared authenticated shell
  and chooses bottom navigation with `destinationsFor(AppRole)`.
- Role feature folders are already separated: `employee`, `manager`, `admin`,
  and `super_admin`.
- Auth roles are centralized in `mobile/lib/core/auth/models.dart`.

Main limitation:

- Native Android product flavors and iOS schemes/build configurations are
  defined. iOS still needs macOS/Xcode build verification, final icons, release
  signing, and store metadata.

## Target Product Shape

Use one Flutter codebase with multiple app flavors:

| App | Flavor | Initial Route | Allowed Roles | Primary Device Shape |
| --- | ------ | ------------- | ------------- | -------------------- |
| Aurelia Employee | `employee` | `/employee` | `EMPLOYEE` | Phone-first |
| Aurelia Manager | `manager` | `/manager` | `MANAGER` | Phone-first / tablet-friendly |
| Aurelia Admin | `admin` | `/admin` | `COMPANY_ADMIN`, `HR_ADMIN` | Tablet-friendly / phone-capable |
| Aurelia Platform | `platform` | `/super-admin` | `SUPER_ADMIN` | Tablet/web-friendly; mobile app optional |

Long-term optional split:

- Keep `platform` as a Flutter flavor for now.
- If super-admin workflows become too dense for mobile, move Platform to a
  dedicated web/admin console while keeping shared backend contracts unchanged.

## Design Principles

- One repository and one Flutter package.
- Multiple app entrypoints.
- Multiple native bundle IDs.
- Shared `core`, `shared`, API repositories, models, auth, and feature screens.
- Flavor-specific app name, icon, splash, entrypoint, allowed roles, start route,
  and navigation.
- Do not fork feature code per app unless the UX needs to diverge.
- Do not weaken backend authorization. Flavor restrictions are product UX gates;
  backend role checks remain the security boundary.

## Proposed Dart Structure

App-level bootstrap and flavor configuration:

```text
mobile/lib/
  app.dart
  main_employee.dart
  main_manager.dart
  main_admin.dart
  main_platform.dart
  core/
    config/
      app_config.dart
      app_flavor.dart
    routing/
      router.dart
      route_catalog.dart
    shell/
      app_shell.dart
```

Keep current feature folders:

```text
mobile/lib/features/
  auth/
  employee/
  manager/
  admin/
  super_admin/
  notifications/
```

`app_flavor.dart` should define the installed product:

```dart
enum AureliaFlavor { employee, manager, admin, platform }

class FlavorConfig {
  const FlavorConfig({
    required this.flavor,
    required this.appName,
    required this.allowedRoles,
    required this.initialAuthedRoute,
  });

  final AureliaFlavor flavor;
  final String appName;
  final Set<AppRole> allowedRoles;
  final String initialAuthedRoute;
}
```

The active flavor should be provided through Riverpod, not read from global
mutable state. That keeps widget tests and integration tests easy to override.

## Entrypoints

Each entrypoint bootstraps the same app with a different flavor provider:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runAureliaApp(flavor: employeeFlavorConfig);
}
```

Target files:

- `mobile/lib/main_employee.dart`
- `mobile/lib/main_manager.dart`
- `mobile/lib/main_admin.dart`
- `mobile/lib/main_platform.dart`

Keep `mobile/lib/main.dart` as a development and FE2-FE9 QA aggregator during
the migration. Native flavor builds should use the role-specific entrypoints.

## Routing Changes

Current:

- One `routerProvider`.
- One `landingFor(AppRole)`.
- One `_roleAllowed(AppRole, String path)`.
- One route tree containing all role routes.

Implemented Dart target:

- Keep one route catalog so paths and screens are not duplicated.
- Flavor-aware redirects.
- Authenticated users are restricted to the active app's allowed role set.

Rules:

1. Unauthenticated users always go to `/login`.
2. Authenticated users whose role is allowed by the active flavor go to the
   flavor's initial route.
3. Authenticated users whose role is not allowed by the active flavor go to a
   dedicated wrong-app screen.
4. Deep links outside the active flavor show access denied or not found, not a
   blank page.
5. `/account` remains available inside each app.

Wrong-app examples:

- Employee signs into Aurelia Admin:
  "This account belongs in Aurelia Employee."
- Super admin signs into Aurelia Employee:
  "This account belongs in Aurelia Platform."

## Shell And Navigation Changes

Current:

- `AppShell` reads `user.primaryRole`.
- `destinationsFor(AppRole)` returns bottom navigation.

Implemented Dart target:

- Shell should read active `FlavorConfig`.
- Navigation is flavor-first, role-confirmed.
- Role can still be used inside `admin` because `COMPANY_ADMIN` and `HR_ADMIN`
  share the same installed app but may have slightly different permissions.

Suggested function:

```dart
List<NavDestinationSpec> destinationsForFlavor(
  AureliaFlavor flavor,
  AppRole role,
)
```

This keeps future app-specific navigation changes from leaking into unrelated
apps.

## Native Android Flavors

Current Android package:

- `namespace = "com.aurelia.workforce.aurelia_mobile"`
- `applicationId = "com.aurelia.workforce.aurelia_mobile"`
- no product flavors yet

Target Android product flavors in `mobile/android/app/build.gradle.kts`:

```kotlin
flavorDimensions += "app"

productFlavors {
    create("employee") {
        dimension = "app"
        applicationId = "com.aurelia.workforce.employee"
        resValue("string", "app_name", "Aurelia Employee")
    }
    create("manager") {
        dimension = "app"
        applicationId = "com.aurelia.workforce.manager"
        resValue("string", "app_name", "Aurelia Manager")
    }
    create("admin") {
        dimension = "app"
        applicationId = "com.aurelia.workforce.admin"
        resValue("string", "app_name", "Aurelia Admin")
    }
    create("platform") {
        dimension = "app"
        applicationId = "com.aurelia.workforce.platform"
        resValue("string", "app_name", "Aurelia Platform")
    }
}
```

Android build commands:

```bash
flutter build appbundle \
  --flavor employee \
  -t lib/main_employee.dart \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.example.com
```

Repeat for `manager`, `admin`, and `platform`.

## Native iOS Flavors

Current iOS project:

- one `Runner` target
- one `Info.plist`
- one app icon set

Target iOS setup:

- Add schemes:
  - `employee`
  - `manager`
  - `admin`
  - `platform`
- Add build configurations per scheme:
  - `Debug-employee`, `Release-employee`
  - `Debug-manager`, `Release-manager`
  - `Debug-admin`, `Release-admin`
  - `Debug-platform`, `Release-platform`
- Assign bundle identifiers:
  - `com.aurelia.workforce.employee`
  - `com.aurelia.workforce.manager`
  - `com.aurelia.workforce.admin`
  - `com.aurelia.workforce.platform`
- Use per-flavor display names through build settings or per-flavor `Info.plist`
  values.
- Add app icon sets per flavor when brand assets are ready.

iOS build command:

```bash
flutter build ipa \
  --flavor employee \
  -t lib/main_employee.dart \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.example.com
```

## CI Changes

Current CI builds each role-specific Android product flavor.

Current Android flavor CI checks:

```bash
flutter build apk --debug --flavor employee -t lib/main_employee.dart
flutter build apk --debug --flavor manager -t lib/main_manager.dart
flutter build apk --debug --flavor admin -t lib/main_admin.dart
flutter build apk --debug --flavor platform -t lib/main_platform.dart
```

Keep the existing checks:

- `dart format --set-exit-if-changed lib test integration_test`
- `flutter analyze`
- `flutter test`

Add flavor smoke tests:

- each entrypoint renders the correct app title
- wrong-role login lands on wrong-app screen
- correct role lands on the flavor's initial route
- each flavor exposes only its intended visible navigation

## Integration Test Strategy

Keep FE2-FE9 staging tests for contract coverage. Add flavor-specific launch
tests:

| Test | Purpose |
| ---- | ------- |
| `employee_flavor_staging_test.dart` | Employee login, navigation, clock-in route access |
| `manager_flavor_staging_test.dart` | Manager login, team nav, approvals nav |
| `admin_flavor_staging_test.dart` | Company/HR admin login, admin nav |
| `platform_flavor_staging_test.dart` | Super-admin login, platform nav |
| `wrong_app_staging_test.dart` | Role mismatch screen for each app |

Do not delete the existing FE tests until the flavor tests cover the same launch
gate confidence.

## Implementation Phases

### Phase 1: Dart Flavor Layer

- Add `AppFlavor` / `FlavorConfig`.
- Add `runAureliaApp(flavor: ...)`.
- Add four entrypoints.
- Make `AureliaApp` read the flavor for app title and routing.
- Add wrong-app state screen.
- Keep native build as a single app during this phase.

Pass condition:

- `flutter analyze`, `flutter test`, and `flutter build apk --debug` still pass.
- Entrypoint widget tests prove the right flavor config is active.

Status: complete on 2026-07-01.

### Phase 2: Flavor-Aware Routing And Shell

- Refactor router redirects to use active flavor.
- Refactor shell nav to use active flavor.
- Ensure `admin` supports both `COMPANY_ADMIN` and `HR_ADMIN`.
- Ensure `platform` supports only `SUPER_ADMIN`.

Pass condition:

- Correct-role users land in their app.
- Wrong-role users see wrong-app screen.
- Visible navigation matches each app.

Status: complete on 2026-07-01 at the Dart layer.

### Phase 3: Android Product Flavors

- Add Android `productFlavors`.
- Add per-flavor app names.
- Reuse the current launcher icon until final per-app icons are ready.
- Build all four debug APKs.

Pass condition:

- All Android flavor debug builds pass.

Status: complete on 2026-07-02.

Android application IDs:

| Flavor | Application ID | App Name |
| ------ | -------------- | -------- |
| `employee` | `com.aurelia.workforce.employee` | Aurelia Employee |
| `manager` | `com.aurelia.workforce.manager` | Aurelia Manager |
| `admin` | `com.aurelia.workforce.admin` | Aurelia Admin |
| `platform` | `com.aurelia.workforce.platform` | Aurelia Platform |

### Phase 4: iOS Schemes

- Add iOS schemes and build configurations.
- Add bundle identifiers and display names.
- Wire flavor entrypoints in Xcode/Flutter scheme settings.

Pass condition:

- All iOS flavor builds pass on a Mac runner or local Mac.

Status: scaffolded on 2026-07-02; pending macOS/Xcode build verification.

iOS bundle identifiers:

| Scheme | Bundle ID | Display Name |
| ------ | --------- | ------------ |
| `employee` | `com.aurelia.workforce.employee` | Aurelia Employee |
| `manager` | `com.aurelia.workforce.manager` | Aurelia Manager |
| `admin` | `com.aurelia.workforce.admin` | Aurelia Admin |
| `platform` | `com.aurelia.workforce.platform` | Aurelia Platform |

Validation command on macOS:

```bash
flutter build ios --debug --no-codesign --flavor employee -t lib/main_employee.dart
flutter build ios --debug --no-codesign --flavor manager -t lib/main_manager.dart
flutter build ios --debug --no-codesign --flavor admin -t lib/main_admin.dart
flutter build ios --debug --no-codesign --flavor platform -t lib/main_platform.dart
```

### Phase 5: CI And Release Gate

- Update GitHub Actions to build all Android flavors.
- Add optional manual workflow for staging flavor integration tests.
- Document store signing and upload steps per flavor.

Pass condition:

- CI blocks regressions across every app target.

Status: partial. CI builds all Android flavors automatically. A manual macOS
workflow is available for no-signing iOS flavor builds.

## Product Decisions Needed Before Store Release

- Final app names:
  - `Aurelia Employee`
  - `Aurelia Manager`
  - `Aurelia Admin`
  - `Aurelia Platform`
- Whether `platform` ships as mobile, web-only, or both.
- Final bundle IDs.
- Final icons and launch screens per app.
- Whether manager functionality should be included in Employee for users who are
  both manager and employee, or kept as a separate install.
- Whether HR admin and company admin remain one Admin app or split later.

## Recommended Next Checkpoint

Create checkpoint `FE10: Mobile Flavor Split`.

Scope:

- Dart flavor config.
- Four entrypoints.
- Flavor-aware router and shell.
- Wrong-app screen.
- Android product flavors.
- CI build of all Android flavors.

Do not start app-store signing, production face vendor integration, or push
notifications until FE10 is stable.
