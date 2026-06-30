# FRONTEND CHECKPOINT LOG

## Purpose

This document tracks the frontend/client build separately from the completed backend checkpoints. It is the operational checklist for closing the current client gaps without inventing endpoints, roles, fake data, or unsupported workflows.

The primary production client is now a **Flutter mobile app for iOS and Android**. Mobile is the critical usability surface for clock-in/out, face verification, GPS, employee self-service, manager approvals, notifications, and daily workforce activity. The Lovable web build can still be used as a visual reference or secondary admin/web console, but the FE checkpoints below apply first to the Flutter mobile implementation unless a checkpoint explicitly says web-only.

The backend is already complete through CP19. Frontend work must consume the existing contract:

- `docs/API_CONTRACT.md`
- `docs/ROLE_PERMISSION_MATRIX.md`
- `docs/FRONTEND_HANDOFF.md`
- `docs/FRONTEND_ROUTE_MAP.md`
- `docs/SCREEN_API_MATRIX.md`
- `docs/LOVABLE_PROMPT.md`
- `docs/TEST_ACCOUNTS.md`

## Current Frontend Status

- **Frontend origin:** `https://exact-render-route.lovable.app`
- **Primary client target:** Flutter mobile app for iOS and Android.
- **Secondary/reference client:** Lovable web at `https://exact-render-route.lovable.app`.
- **Backend base URL:** `https://workforce-management-production.up.railway.app`
- **Observed complete/partial work:** login route, auth shell, role-aware dashboard foundation, royal-minimal visual direction. Flutter FE0 source is now imported under `mobile/`, dependencies resolve, static analysis passes, Android emulator smoke QA passes for `SUPER_ADMIN` and `EMPLOYEE`, and FE1 still needs remaining role coverage before final pass.
- **Observed missing work:** most employee/admin/manager/super-admin workflow pages, create/edit flows, detail screens, correct report tabs, admin setup flows, and face/GPS attendance sequence.
- **Known issue pattern:** frontend route `404`s are usually missing Lovable page routes; backend `404`s are usually wrong endpoint paths such as generic report URLs not present in `API_CONTRACT.md`.

## Tooling Decision Log

### 2026-06-20 - Lovable Cannot Build Flutter

Lovable reported that the current project is a TanStack Start web app and its sandbox cannot compile, run, or preview Flutter/Dart. It has no Flutter SDK, iOS/Android toolchain, `pubspec.yaml` build pipeline, or native preview path.

Decision selected: create the Flutter source as a source-controlled `mobile/` folder while keeping Lovable/web as a reference or secondary surface.

- Create the production Flutter client in a source-controlled `mobile/` folder, then build/test with the Flutter SDK locally or in CI.
- Keep Lovable as a web/reference frontend or secondary admin/PWA surface only.
- Do not place unbuildable Dart files into the web app as dead code unless the folder is intentionally treated as a separate Flutter project.

Lovable can generate and store the source, but it cannot run `flutter pub get`, compile, or preview the native app.

### 2026-06-20 - FE0/FE1 Flutter Source Reported Complete

Lovable reported a Flutter scaffold under `mobile/` with:

- `pubspec.yaml`, `analysis_options.yaml`, `.gitignore`, and `README.md`.
- `lib/main.dart`, `lib/app.dart`, theme, API, auth, routing, shell, notification, placeholder dashboard, and shared state modules.
- Riverpod state management, `go_router` routing, Dio HTTP client, `flutter_secure_storage` token storage, and Google Fonts.
- Routes for splash, login, denied, employee, manager, admin, super-admin, account, notifications, and unknown/not-found states.
- Auth wiring for `POST /api/auth/login`, `GET /api/auth/me`, `POST /api/auth/logout`, and `GET /api/notifications/me/unread-count`.
- Typed failure mapping for connection, unauthenticated, forbidden, not found, validation, rate limit, and server failures.

Verification note: this local workspace does not currently contain a `mobile/` folder, so the report is recorded as source-complete pending repo sync and real Flutter toolchain verification.

### 2026-06-20 - FE0/FE1 Source Sync Reported

Lovable reported that the `mobile/` source is present with:

- `mobile/.gitignore`
- `mobile/README.md`
- `mobile/analysis_options.yaml`
- `mobile/pubspec.yaml`
- `mobile/lib/main.dart`
- `mobile/lib/app.dart`
- `mobile/lib/core/api/api_client.dart`
- `mobile/lib/core/auth/auth_controller.dart`
- `mobile/lib/core/auth/models.dart`
- `mobile/lib/core/auth/token_storage.dart`
- `mobile/lib/core/errors/failures.dart`
- `mobile/lib/core/routing/router.dart`
- `mobile/lib/core/theme/aurelia_theme.dart`
- `mobile/lib/features/auth/login_screen.dart`
- `mobile/lib/features/notifications/notifications_controller.dart`
- `mobile/lib/features/placeholders/role_dashboards.dart`
- `mobile/lib/features/shell/app_shell.dart`
- `mobile/lib/shared/widgets/states.dart`

Lovable also reported no TanStack web app changes, setup instructions in `mobile/README.md`, and expected local verification with `flutter pub get`, `flutter analyze`, and `flutter run`.

Local verification note: Flutter is installed on this machine, but `mobile/` is still not visible in this local workspace. FE0/FE1 remain `READY_FOR_QA`, not `PASSED`, until the files are synced here and the Flutter commands run successfully.

### 2026-06-21 - Source Control Verification Failed

Codex verified the accessible repository and remote:

- Local branch: `main`.
- Local commit: `159779f`.
- Remote branch list: only `origin/main`.
- Remote `origin/main` commit: `159779f`.
- `git ls-tree -r --name-only origin/main mobile` returned no files.
- Local `mobile/` check returned `NO_MOBILE_DIR`.

Conclusion: the `mobile/` source has been reported by Lovable but is not present in the local workspace or in the accessible GitHub remote. FE0/FE1 cannot be verified and FE2+ should not begin until the actual Flutter source is delivered through a branch, commit, zip, or direct file sync.

### 2026-06-21 - Mobile Zip Export Reported

Lovable reported a zip/export delivery of the existing FE0/FE1 Flutter `mobile/` source:

- Delivery method: zip/export of the `mobile/` folder.
- Reported contents: 18 FE0/FE1 Flutter source files under `mobile/`.
- Reported checksum: `f4dd019be6a7b84aadd3d89d726449e92543593d43f1926c719c7dd5fb829ace`.

Local verification note: no `.zip` file is present in the local workspace, and no download path/link was included in the report. FE0/FE1 remain blocked until the archive is accessible, checksum verification passes, and the archive is extracted into this repository.

### 2026-06-21 - Mobile Zip Path Inaccessible

Lovable reported the archive at `/dev-server/mobile-fe0-fe1.zip` with matching checksum. Codex checked:

- `/dev-server/mobile-fe0-fe1.zip`
- `mobile-fe0-fe1.zip` in the repo root
- recursive repo search for `mobile-fe0-fe1.zip`
- likely Windows shared/download locations
- MCP resources/attachments

Result: the archive is still not accessible from the Windows workspace at `C:\Users\user\Desktop\Sam Proj\Workforce-Management`. The `/dev-server` path appears to be local to Lovable's sandbox rather than the shared Codex filesystem. FE0/FE1 remain blocked until the zip is placed in the Windows workspace, attached as a downloadable resource Codex can read, or pushed to Git.

### 2026-06-21 - Mobile Source Imported and Analyzer Verified

Codex imported only the `mobile/` folder from the Lovable-created repository `https://github.com/washappenin/exact-render-route.git` at commit `0e2713a`.

Verification performed:

- Confirmed `mobile/` contains the expected FE0/FE1 Flutter scaffold files.
- Ran `flutter --no-version-check --version` outside the sandbox:
  - Flutter `3.41.9`
  - Dart `3.11.5`
- Ran `flutter pub get` successfully.
- Ran `flutter analyze`; first pass found:
  - `CardTheme` type mismatch with modern Flutter.
  - deprecated `withOpacity` usages.
- Patched:
  - `CardTheme` -> `CardThemeData`
  - `withOpacity(...)` -> `withValues(alpha: ...)`
- Reran `flutter analyze` successfully: `No issues found`.
- Static endpoint audit found only the intended FE0/FE1 backend calls:
  - `POST /api/auth/login`
  - `GET /api/auth/me`
  - `POST /api/auth/logout`
  - `GET /api/notifications/me/unread-count`

Follow-up verification performed:

- Generated missing Android and iOS platform folders with `flutter create --platforms=android,ios --project-name aurelia_mobile --org com.aurelia.workforce --no-overwrite --no-pub .`.
- Replaced generated default counter widget test with an Aurelia app-shell smoke test.
- Cleaned export mojibake/Unicode from README and route loading text.
- Ran `dart format lib test` successfully.
- Reran `flutter analyze` successfully: `No issues found`.
- Ran `flutter test` successfully: `All tests passed`.
- Ran `flutter build apk --debug`; command exceeded the shell timeout after Gradle compilation started, but `app-debug.apk` was produced at `mobile/build/app/outputs/flutter-apk/app-debug.apk`, confirming Android debug build output.
- Stopped the Gradle daemon with `gradlew --stop`.

FE0 is now passed at source/analyzer/test/Android-debug-build level. FE1 remains `READY_FOR_QA` until the Flutter app is run on a simulator/device and staging login/session/role redirect behavior is verified manually or through integration tests.

## Flutter Client Rules

- Build mobile-first with Flutter/Dart.
- Use a real routed app structure rather than one-off screens.
- Use secure token storage; do not store bearer tokens in plain local storage.
- Use a central API client with auth interceptors, envelope parsing, request IDs, and typed error mapping.
- Use mobile permission flows for camera, GPS/location, and notification permissions.
- Do not store raw face images, biometric payloads, or GPS history on device.
- Cache only safe, non-sensitive UI state. Treat HR, GPS, biometric, token, and payment data as sensitive.
- Keep employee and manager workflows optimized for phone use.
- Admin and super-admin workflows may be mobile/tablet capable, but dense table-heavy management can remain a secondary web/admin concern if product scope later splits clients.

## Status Legend

| Status | Meaning |
| ------ | ------- |
| `NOT_STARTED` | No usable frontend workflow exists yet. |
| `PARTIAL` | Route or UI exists but workflow is incomplete, incorrectly wired, or missing important states. |
| `BLOCKED` | Cannot proceed without a backend/CORS/account/config change. |
| `READY_FOR_QA` | Implementation is complete enough for role smoke testing. |
| `PASSED` | Workflow has passed role-based frontend QA against staging. |

## Frontend Checkpoint Status Table

| # | Checkpoint | Status | Primary Gap |
| - | ---------- | ------ | ----------- |
| FE0 | Flutter client governance and API contract alignment | `PASSED` | `mobile/` imported, Android/iOS scaffolds generated, dependencies resolved, analyzer/test pass, Android debug APK produced, and endpoint audit matches contract. |
| FE1 | Flutter auth, shell, navigation, and global states | `READY_FOR_QA` | Android emulator verified for `SUPER_ADMIN` and `EMPLOYEE`; `smoke.env` credentials and API login verified for all roles; pending full emulator navigation QA for `COMPANY_ADMIN`, `HR_ADMIN`, and `MANAGER`. |
| FE2 | Employee self-service workflows | `PASSED` | Android staging QA passed for employee dashboard, attendance history, shifts, leave submit, OKR progress, OKR employee approval, reviews, notifications read-all, and FE3-gated clock route placeholders. |
| FE3 | Face verification and GPS attendance | `PASSED` | Android staging QA passed for mock face verification, GPS/geofence precheck, clock-in, dashboard status, clock-out, and final closed attendance state. |
| FE4 | Admin organization setup workflows | `PASSED` | Android staging QA passed for admin setup: departments, designations, employee create/edit/status/manager assignment, employee detail, and face enrollment metadata. |
| FE5 | Admin operations workflows | `PASSED` | Android staging QA passed for geofences/attendance, shifts/assignments, leave, OKRs, reviews, broadcasts, and billing self-view. |
| FE6 | Manager team workflows | `NOT_STARTED` | Team attendance, leave approvals, OKRs, reviews, reports, and notifications need UI. |
| FE7 | Super-admin platform workflows | `NOT_STARTED` | Companies, plans, subscriptions, payments, platform reports, and company rollups need UI. |
| FE8 | Reports and dashboard data rendering | `PARTIAL` | Dashboards must render real summary data and report tabs must call exact implemented endpoints. |
| FE9 | End-to-end frontend QA and launch gate | `NOT_STARTED` | Each role needs browser smoke testing against staging. |

---

## FE0: Flutter Client Governance and API Contract Alignment

**Goal:** Make the Flutter client obey the documented route map and endpoint matrix exactly.

**Scope:**

- Create or align the Flutter project structure for a mobile-first app.
- Establish app layers: routing, auth/session, API client, feature modules, shared UI states, and environment config.
- Confirm every mobile nav item maps to a real route from `FRONTEND_ROUTE_MAP.md`.
- Confirm every API call maps to an implemented endpoint from `SCREEN_API_MATRIX.md`.
- Remove generic or invented endpoints such as `GET /api/admin/reports` or `GET /api/admin/notifications`.
- Centralize API envelopes: success `{ data, meta }`, error `{ error }`.
- Ensure protected calls send `Authorization: Bearer <token>`.
- Use secure token storage on device.
- Preserve the visual direction from `LOVABLE_PROMPT.md` in native Flutter widgets: regal, calm, professional, restrained, and mobile-usable.

**Pass condition:**

- No visible mobile nav link lands on a missing route.
- No screen calls a backend endpoint absent from `API_CONTRACT.md`.
- `401`, `403`, `404`, validation, `429`, and network/CORS errors render consistently.
- Flutter app can point at the staging backend through environment config.

**2026-06-20 tracking update:**

- Status moved to `READY_FOR_QA` based on Lovable's FE0/FE1 Flutter completion report.
- Reported source location: `mobile/`.
- Local workspace check: `mobile/` is not present yet, so source sync into this workspace is still required despite Lovable's source-sync report.
- Required verification once source is available:
  - `cd mobile`
  - `flutter pub get`
  - `flutter analyze`
  - `flutter test` if tests are present
  - `flutter run` against a simulator/device

**2026-06-21 tracking update:**

- Status moved back to `BLOCKED` after local and remote Git verification found no `mobile/` folder.
- Required unblocker: deliver the actual `mobile/` files into this workspace or an accessible branch/commit.

**2026-06-21 verification update:**

- Status moved to `PASSED` after importing `mobile/`, running `flutter pub get`, fixing analyzer issues, rerunning `flutter analyze`, and auditing endpoints.

**2026-06-22 verification update:**

- Generated Android and iOS platform scaffolding around the FE0/FE1 Dart source.
- Added a valid Aurelia app-shell smoke test.
- `flutter analyze` passed.
- `flutter test` passed.
- Android debug APK was produced.

---

## FE1: Flutter Auth, Shell, Navigation, and Global States

**Goal:** Provide a complete authenticated Flutter app frame for all roles.

**Required workflows:**

- Login with `POST /api/auth/login`.
- Session hydration with `GET /api/auth/me`.
- Logout with `POST /api/auth/logout`.
- Role-based primary redirect.
- Role-aware mobile navigation for `SUPER_ADMIN`, `COMPANY_ADMIN`, `HR_ADMIN`, `MANAGER`, and `EMPLOYEE`.
- Notification unread badge from `GET /api/notifications/me/unread-count`.
- Global states: loading, empty, access denied, not found, validation error, network/CORS, expired session.
- Mobile app shell: bottom navigation or compact drawer for phone use, account menu, notification entry point, and role badge.
- Safe session handling on app cold start, resume, logout, and invalid token.

**Pass condition:**

- Each staging role can sign in on the Flutter app and sees only appropriate navigation.
- Reload keeps the session if token is valid.
- `401` clears auth and returns to `/login`.
- Unsupported role actions show access denied rather than blank or broken pages.

**2026-06-20 tracking update:**

- Status moved to `READY_FOR_QA` based on Lovable's FE0/FE1 Flutter completion report.
- Reported complete: login, secure token storage, session hydration, logout, global `401` handling, role redirects, role-aware mobile navigation, unread badge, and shared states.
- Testing gap: Lovable cannot run Flutter, so FE1 cannot be marked `PASSED` until a local/CI Flutter build verifies staging login and role redirects.

**2026-06-21 tracking update:**

- Status moved back to `BLOCKED` because the reported Flutter auth shell source is not present locally or on accessible `origin/main`.

**2026-06-21 verification update:**

- Status moved to `READY_FOR_QA` after source import, dependency resolution, and analyzer pass.
- Remaining pass condition: run the app on a simulator/device and verify staging login, session hydration, logout, role redirects, unauthorized-session handling, and role navigation.
- Available local Flutter targets: Windows desktop, Chrome, and Edge. No Android or iOS simulator/device is currently visible.

**2026-06-22 verification update:**

- FE1 source compiles and passes smoke tests inside the complete Flutter project.
- Android debug APK output exists, but FE1 remains `READY_FOR_QA` because no Android/iOS simulator or physical device was available for staging login validation.

**2026-06-23 Android emulator QA update:**

- Pushed the FE0/FE1 Flutter checkpoint commit to `origin/main`.
- Launched Android emulator `emulator-5554` (`Android 15`, API 35).
- Ran `flutter run -d emulator-5554 --debug --no-resident` successfully.
- Verified `SUPER_ADMIN` staging login redirects into the authenticated super-admin shell.
- Verified `SUPER_ADMIN` token hydration survives app force-stop and relaunch.
- Verified `SUPER_ADMIN` account screen renders email, role, and active status.
- Verified `SUPER_ADMIN` sign out returns to the login screen.
- Verified `EMPLOYEE` staging login redirects into the authenticated employee shell with employee navigation.
- FE1 remains `READY_FOR_QA`, not `PASSED`, until `COMPANY_ADMIN`, `HR_ADMIN`, and `MANAGER` staging credentials are available and tested on the emulator or a device.

**2026-06-23 staging credential update:**

- Confirmed `scripts/staging-smoke/smoke.env` now contains populated email/password values for `SUPER_ADMIN`, `COMPANY_ADMIN`, `HR_ADMIN`, `MANAGER`, and `EMPLOYEE`.
- Verified API login succeeds for all five staging roles without printing secrets or tokens.
- FE1 still needs full emulator navigation QA for `COMPANY_ADMIN`, `HR_ADMIN`, and `MANAGER` before it can move from `READY_FOR_QA` to `PASSED`.

---

## FE2: Employee Self-Service Workflows

**Goal:** Complete all employee routes and self-service screens.

**Required routes and APIs:**

| Screen | Frontend Route | Backend Calls |
| ------ | -------------- | ------------- |
| Dashboard | `/employee/dashboard` | `GET /api/employees/me`, `GET /api/reports/me/dashboard`, unread count |
| Attendance history | `/employee/attendance/history` | `GET /api/attendance/me` |
| My shifts | `/employee/shifts` | `GET /api/shifts/me` |
| Leave | `/employee/leave` | `GET /api/leave/me`, `POST /api/leave/request` |
| OKRs | `/employee/okrs` | `GET /api/okrs/me`, detail/progress/employee approval |
| Reviews | `/employee/reviews` | `GET /api/reviews/me`, `GET /api/reviews/:reviewId` |
| Notifications | `/employee/notifications` | `GET /api/notifications/me`, read/read-all actions |

**UI requirements:**

- Render partial dashboard data instead of one global empty state.
- Provide clear empty states per module.
- Use tables/lists/detail drawers for records.
- Keep request forms tied to real backend fields only.

**Pass condition:**

- Employee can view profile summary, dashboard, attendance, shifts, leave, OKRs, reviews, and notifications without frontend route `404`s.
- Employee can submit leave, update OKR progress, employee-approve OKR, and mark notifications read.

**2026-06-24 implementation update:**

- Added the Flutter employee feature module under `mobile/lib/features/employee/`.
- Added employee routes:
  - `/employee`
  - `/employee/dashboard`
  - `/employee/attendance/history`
  - `/employee/shifts`
  - `/employee/leave`
  - `/employee/okrs`
  - `/employee/reviews`
  - `/employee/notifications`
- Added non-404 FE3 gate screens for:
  - `/employee/attendance/clock-in`
  - `/employee/attendance/clock-out`
  - `/employee/face-verification`
- Implemented documented FE2 endpoints only:
  - `GET /api/employees/me`
  - `GET /api/reports/me/dashboard`
  - `GET /api/attendance/me`
  - `GET /api/shifts/me`
  - `GET /api/leave/me`
  - `POST /api/leave/request`
  - `GET /api/okrs/me`
  - `GET /api/okrs/:okrId`
  - `POST /api/okrs/:okrId/progress`
  - `PATCH /api/okrs/:okrId/employee-approve`
  - `GET /api/reviews/me`
  - `GET /api/reviews/:reviewId`
  - notification list/read/read-all endpoints
- Fixed the employee bottom-navigation route matching so nested employee routes select the most specific tab.
- Verification passed:
  - `dart format lib test integration_test`
  - `flutter analyze`
  - `flutter test`
  - endpoint audit with `rg "/api/" mobile/lib mobile/integration_test`
  - `flutter build apk --debug`
- FE2 moved to `READY_FOR_QA`; it is not `PASSED` until employee emulator staging QA completes.

**2026-06-24 Android staging integration QA update:**

- Added a guarded Flutter integration test at `mobile/integration_test/fe2_employee_staging_test.dart`.
- Prepared minimal staging QA data through documented backend endpoints: one current-year leave entitlement, one employee OKR, and one unread notification for the staging employee account.
- The first staging QA pass exposed a real phone-width leave form bug: duplicate leave entitlements with the same leave type crashed the dropdown. Fixed the form to use entitlement IDs as dropdown values while still submitting the backend-required `leaveTypeId`.
- The same pass exposed a long-label phone overflow in the leave dropdown. Fixed the dropdown with `isExpanded` and ellipsized labels.
- Ran `flutter test integration_test\fe2_employee_staging_test.dart -d emulator-5554 --dart-define=QA_RUN_STAGING_FE2=true` with employee staging credentials loaded locally from `scripts/staging-smoke/smoke.env`.
- Final integration test passed against staging: employee login, dashboard, attendance history, shifts, leave request submission, OKR progress update, OKR employee approval, reviews route, notifications route, and notification read-all.
- Verification also passed:
  - `dart format lib test integration_test`
  - `flutter analyze`
  - `flutter test`
- FE2 status moved to `PASSED`.

---

## FE3: Face Verification and GPS Attendance

**Goal:** Complete the clock-in/out UX with the correct face and geofence sequence.

**Clock-in sequence:**

1. Open `/employee/attendance/clock-in`.
2. Request native camera permission and show camera unavailable/denied states.
3. In staging, call `POST /api/face/verify` with provider `mock` and the mock pass/fail reference.
4. Receive the short-lived `verificationReference`.
5. Request native GPS/location permission.
6. Optionally precheck `POST /api/geofences/validate-location`.
7. Call `POST /api/attendance/clock-in` with `latitude`, `longitude`, `accuracyMeters`, and `faceVerificationReference`.
8. Render duplicate clock-in, no enrollment, face failed, expired/reused reference, GPS denied, outside-geofence, and validation states.

**Clock-out sequence:**

1. Open `/employee/attendance/clock-out`.
2. Request GPS permission.
3. Optionally precheck `POST /api/geofences/validate-location`.
4. Call `POST /api/attendance/clock-out` with `latitude`, `longitude`, and `accuracyMeters`.
5. Render no-open-session, GPS denied, outside-geofence, and validation states.

**Production face path:**

- Keep frontend flow provider-agnostic.
- Do not store raw face images, biometric vectors, templates, or provider references.
- Real provider/liveness support must be added behind the backend face adapter later.
- Production biometric use requires consent and deletion/offboarding workflows before launch.

**Pass condition:**

- Employee can successfully face-verify and clock in/out in staging.
- Frontend never fakes face success or stores biometric/GPS data beyond the immediate request.

**2026-06-28 Android staging integration QA update:**

- Implemented Flutter FE3 screens for face verification, clock in, and clock out.
- Added native Android/iOS camera and location permission declarations.
- Added staging-safe QA coordinate overrides so emulator tests can validate geofenced attendance without a real GPS device.
- Wired only documented backend calls:
  - `POST /api/face/verify`
  - `POST /api/geofences/validate-location`
  - `POST /api/attendance/clock-in`
  - `POST /api/attendance/clock-out`
- Fixed the geofence precheck payload to send only `latitude` and `longitude`; attendance writes still send `accuracyMeters`.
- Removed runtime Google Fonts fetching so emulator/offline runs do not fail on `fonts.gstatic.com` DNS.
- Improved phone UX by keeping clock-in/out primary actions and result/error cards above the sequence details.
- Added guarded staging integration test `mobile/integration_test/fe3_attendance_staging_test.dart`.
- Ran `flutter test integration_test\fe3_attendance_staging_test.dart -d emulator-5554 --dart-define=QA_RUN_STAGING_FE3=true` with employee staging credentials and geofence coordinates loaded locally from ignored `scripts/staging-smoke/smoke.env`.
- Final integration test passed against staging: employee login, clock-in route, mock face verification, geofence precheck, attendance clock-in, dashboard return, clock-out route, geofence precheck, attendance clock-out.
- Post-test API check confirmed the staging employee ended in `CLOCKED_OUT`.
- Verification also passed:
  - `dart format lib test integration_test`
  - `flutter analyze`
  - `flutter test`

---

## FE4: Admin Organization Setup Workflows

**Goal:** Build the company setup screens needed before employee workflows become meaningful.

**2026-06-23 planning update:**

- Added `docs/FRONTEND_FE4_PROMPT.md` as the next implementation packet.
- FE4 should start before FE2/FE3 because departments, designations, employees, managers, and face enrollment metadata are prerequisite data for realistic employee and manager workflows.
- FE4 cannot be marked `PASSED` until `COMPANY_ADMIN` or `HR_ADMIN` staging credentials are available for emulator/device QA.

**2026-06-23 implementation update:**

- Added Flutter admin feature files under `mobile/lib/features/admin/`.
- Replaced the admin placeholder route with a real admin setup hub.
- Added routes:
  - `/admin/departments`
  - `/admin/departments/:departmentId`
  - `/admin/designations`
  - `/admin/designations/:designationId`
  - `/admin/employees`
  - `/admin/employees/:employeeId`
  - `/admin/employees/:employeeId/face`
- Added admin bottom navigation for departments, designations, employees, and account.
- Implemented documented FE4 endpoints only:
  - department list/create/detail/update/status
  - designation list/create/detail/update/status
  - employee list/create/detail/update/status/manager assignment
  - face enrollment status/upsert/status update
- Verification passed:
  - `dart format lib test`
  - `flutter analyze`
  - `flutter test`
  - endpoint audit with `rg "/api/" mobile/lib`
  - `flutter build apk --debug`
- FE4 status moved to `READY_FOR_QA`. It is not `PASSED` because `COMPANY_ADMIN` or `HR_ADMIN` staging credentials are still required for emulator/device workflow QA.

**2026-06-23 Android staging QA update:**

- Confirmed `scripts/staging-smoke/smoke.env` contains populated admin/HR/manager/employee/super-admin credentials, and API login succeeds for every role.
- Launched the Android emulator and signed in as `COMPANY_ADMIN`.
- Verified the admin setup hub renders with departments, designations, employees, and account navigation.
- Verified department empty state and created a department through the Flutter UI.
- Verified designation empty state and created a designation through the Flutter UI.
- Verified the employee list renders staging employees and an API-created employee with department/designation data.
- Verified employee detail renders profile, status, department, designation, manager, and admin action buttons.
- Verified the face enrollment screen opens from employee detail and renders the mock-provider enrollment status without exposing raw biometric data.
- Verified the backend workflow through API using the same staging company-admin credentials: employee creation, manager assignment, employee status update, face enrollment upsert, and face enrollment status update.
- QA caveat: Employee creation through the Flutter UI was attempted, but the manual ADB session expired before submit completed. Do not mark FE4 `PASSED` until employee create/edit/status/manager actions receive a clean emulator/device UI retest.

**2026-06-24 Android staging integration QA update:**

- Added a guarded Flutter integration test at `mobile/integration_test/fe4_admin_staging_test.dart`.
- Added stable `ValueKey`s to FE4 employee controls so emulator QA can target the real mobile UI reliably.
- Ran `flutter test integration_test\fe4_admin_staging_test.dart -d emulator-5554 --dart-define=QA_RUN_STAGING_FE4=true` with company-admin staging credentials loaded locally from `scripts/staging-smoke/smoke.env`.
- The integration test passed against staging: company-admin login, employee create, employee edit, employee status change to `ON_LEAVE`, and manager assignment.
- API detail spot-check confirmed the latest test employee had status `ON_LEAVE` and manager `Staging Manager`.
- Verification also passed:
  - `flutter analyze`
  - `flutter test`
- FE4 status moved to `PASSED`.

**Required workflows:**

- Department list/create/edit/status using `/api/admin/departments`.
- Designation list/create/edit/status using `/api/admin/designations`.
- Employee list/create/detail/edit/status using `/api/admin/employees`.
- Manager assignment using `PATCH /api/admin/employees/:employeeId/manager`.
- Employee role selection limited to supported admin-created roles.
- Face enrollment page using:
  - `GET /api/admin/employees/:employeeId/face-status`
  - `POST /api/admin/employees/:employeeId/face-enrollment`
  - `PATCH /api/admin/employees/:employeeId/face-enrollment/status`

**Pass condition:**

- Admin can create a department, designation, employee, assign manager, change employee status, and enroll face metadata without using backend scripts.

---

## FE5: Admin Operations Workflows

**Goal:** Complete the company-admin/HR operations console.

**Required workflows:**

- Geofence list/create/edit/status using `/api/admin/geofences`.
- Attendance logs using `GET /api/admin/attendance`.
- Shift CRUD/status using `/api/admin/shifts`.
- Shift assignment/list/edit/delete using shift assignment endpoints.
- Leave type CRUD/status using `/api/admin/leave-types`.
- Leave entitlement list/create/edit using `/api/admin/leave-entitlements`.
- Leave approval/rejection using `/api/admin/leave-requests` and `/api/leave/:leaveRequestId/*`.
- OKR list/create/detail/edit/status/approval using `/api/admin/okrs` and `/api/okrs/*`.
- Review cycle CRUD/status using `/api/admin/review-cycles`.
- Company reviews list/submit/update/status using `/api/admin/reviews` and `/api/reviews/*`.
- Notification broadcast using `POST /api/admin/notifications/broadcast`.
- Subscription/payment self-view using `/api/admin/subscription` and `/api/admin/payment-records`.

**Pass condition:**

- Admin can configure the organization, operate daily HR workflows, and view billing self-service without touching scripts or Railway.

**2026-06-28 FE5A Android staging integration QA update:**

- Implemented admin geofence management:
  - list geofences
  - create geofence
  - detail view
  - edit name/latitude/longitude/radius
  - activate/deactivate/archive status actions
- Implemented admin attendance logs:
  - company-scoped attendance session list
  - status filter for all/open/closed/cancelled
  - face-verification and clock-in/out geofence indicators
  - no raw GPS coordinates rendered in attendance logs
- Added admin routes:
  - `/admin/geofences`
  - `/admin/geofences/:geofenceId`
  - `/admin/attendance`
- Updated the admin mobile shell with operations tabs for `Geo` and `Time`; setup pages remain reachable from the admin hub.
- Wired only documented FE5A endpoints:
  - `GET /api/admin/geofences`
  - `POST /api/admin/geofences`
  - `GET /api/admin/geofences/:geofenceId`
  - `PATCH /api/admin/geofences/:geofenceId`
  - `PATCH /api/admin/geofences/:geofenceId/status`
  - `GET /api/admin/attendance`
- Added guarded staging integration test `mobile/integration_test/fe5a_admin_ops_staging_test.dart`.
- Ran `flutter test integration_test\fe5a_admin_ops_staging_test.dart -d emulator-5554 --dart-define=QA_RUN_STAGING_FE5A=true` with company-admin staging credentials loaded locally from ignored `scripts/staging-smoke/smoke.env`.
- Final integration test passed against staging: company-admin login, geofence create, geofence edit, geofence deactivate, attendance route load, and attendance empty-or-session state.
- Verification also passed:
  - `dart format lib test integration_test`
  - `flutter analyze`
  - `flutter test`
  - `flutter build apk --debug`

**2026-06-28 FE5B Android staging integration QA update:**

- Implemented admin shift management:
  - list shifts
  - create shift
  - detail view
  - edit name/start/end time
  - activate/deactivate/archive status actions
- Implemented admin shift assignments:
  - assign an active employee to an active shift
  - list shift assignments
  - edit assignment start/end date range
  - delete assignment
- Added admin routes:
  - `/admin/shifts`
  - `/admin/shifts/:shiftId`
- Added a `Shifts` entry to the admin setup hub; the bottom navigation remains compact for phone use.
- Wired only documented FE5B endpoints:
  - `GET /api/admin/shifts`
  - `POST /api/admin/shifts`
  - `GET /api/admin/shifts/:shiftId`
  - `PATCH /api/admin/shifts/:shiftId`
  - `PATCH /api/admin/shifts/:shiftId/status`
  - `POST /api/admin/shifts/:shiftId/assign`
  - `GET /api/admin/shifts/:shiftId/assignments`
  - `PATCH /api/admin/shift-assignments/:assignmentId`
  - `DELETE /api/admin/shift-assignments/:assignmentId`
- Added guarded staging integration test `mobile/integration_test/fe5b_admin_shifts_staging_test.dart`.
- Ran `flutter test integration_test\fe5b_admin_shifts_staging_test.dart -d emulator-5554 --dart-define=QA_RUN_STAGING_FE5B=true` with company-admin staging credentials loaded locally from ignored `scripts/staging-smoke/smoke.env`.
- Final integration test passed against staging: company-admin login, shift create, shift edit, employee assignment, assignment edit, assignment delete, and shift deactivation.
- Verification also passed:
  - `dart format`
  - `flutter analyze`
  - `flutter test`
  - `flutter build apk --debug`
- At the FE5B checkpoint, FE5 remained `PARTIAL` because leave configuration/approvals, OKRs, reviews, broadcasts, and billing self-view still needed implementation.

**2026-06-28 FE5C Android staging integration QA update:**

- Implemented admin leave operations in Flutter:
  - leave type list/create/edit/status
  - leave entitlement list/create/edit
  - admin leave request list with status filter
  - approve/reject pending leave requests with optional review comments
- Added admin route:
  - `/admin/leave`
- Added a `Leave` entry to the admin setup hub; the bottom navigation remains compact for phone use.
- Wired only documented CP10/FE5C endpoints:
  - `GET /api/admin/leave-types`
  - `POST /api/admin/leave-types`
  - `GET /api/admin/leave-types/:leaveTypeId`
  - `PATCH /api/admin/leave-types/:leaveTypeId`
  - `PATCH /api/admin/leave-types/:leaveTypeId/status`
  - `GET /api/admin/leave-entitlements`
  - `POST /api/admin/leave-entitlements`
  - `GET /api/admin/leave-entitlements/:entitlementId`
  - `PATCH /api/admin/leave-entitlements/:entitlementId`
  - `GET /api/admin/leave-requests`
  - `PATCH /api/leave/:leaveRequestId/approve`
  - `PATCH /api/leave/:leaveRequestId/reject`
- Added guarded staging integration test `mobile/integration_test/fe5c_admin_leave_staging_test.dart`.
- Ran `flutter test integration_test\fe5c_admin_leave_staging_test.dart -d emulator-5554 --dart-define=QA_RUN_STAGING_FE5C=true` with company-admin and employee staging credentials loaded locally from ignored `scripts/staging-smoke/smoke.env`.
- Final integration test passed against staging: company-admin login, leave type creation, employee leave balance assignment, real employee request submission, and admin approval.
- Verification also passed:
  - `dart format`
  - `flutter analyze`
  - `flutter test`
  - `flutter build apk --debug`
- At the FE5C checkpoint, FE5 remained `PARTIAL` because OKRs, reviews, broadcasts, and billing self-view still needed implementation.

**2026-06-28 FE5D Android staging integration QA update:**

- Implemented admin OKR operations in Flutter:
  - company OKR list with status filter
  - OKR create/assign to active employee
  - OKR detail view
  - edit title/description/due date
  - status update
  - admin/manager approval with optional comment
  - progress and approval history display
- Added admin routes:
  - `/admin/okrs`
  - `/admin/okrs/:okrId`
- Added an `OKRs` entry to the admin setup hub; the bottom navigation remains compact for phone use.
- Wired only documented CP11/FE5D endpoints:
  - `POST /api/okrs`
  - `GET /api/admin/okrs`
  - `GET /api/okrs/:okrId`
  - `PATCH /api/okrs/:okrId`
  - `PATCH /api/okrs/:okrId/status`
  - `PATCH /api/okrs/:okrId/manager-approve`
- Added guarded staging integration test `mobile/integration_test/fe5d_admin_okrs_staging_test.dart`.
- Ran `flutter test integration_test\fe5d_admin_okrs_staging_test.dart -d emulator-5554 --dart-define=QA_RUN_STAGING_FE5D=true` with company-admin and employee staging credentials loaded locally from ignored `scripts/staging-smoke/smoke.env`.
- Final integration test passed against staging: company-admin login, OKR create, OKR edit, status update, employee progress/self-approval via real API, and admin approval through the Flutter UI.
- Verification also passed:
  - `dart format`
  - `flutter analyze`
  - `flutter test`
  - `flutter build apk --debug`
- FE5 remains `PARTIAL` until FE5E/FE5F Android UI QA and billing self-view are completed.

**2026-06-29 FE5E implementation and staging API verification update:**

- Implemented admin performance review operations in Flutter:
  - review cycle list/create/edit/status
  - company review list with status filter
  - manager/admin review submission for active employees and active cycles
  - review summary/rating update
  - review status update
- Added admin route:
  - `/admin/reviews`
- Added a `Reviews` entry to the admin setup hub; the bottom navigation remains compact for phone use.
- Wired only documented CP12/FE5E endpoints:
  - `GET /api/admin/review-cycles`
  - `POST /api/admin/review-cycles`
  - `GET /api/admin/review-cycles/:reviewCycleId`
  - `PATCH /api/admin/review-cycles/:reviewCycleId`
  - `PATCH /api/admin/review-cycles/:reviewCycleId/status`
  - `GET /api/admin/reviews`
  - `POST /api/reviews/:employeeId/manager-review`
  - `GET /api/reviews/:reviewId`
  - `PATCH /api/reviews/:reviewId`
  - `PATCH /api/reviews/:reviewId/status`
- Added guarded staging integration test `mobile/integration_test/fe5e_admin_reviews_staging_test.dart`.
- Verification passed:
  - `dart format`
  - `flutter analyze`
  - `flutter test`
  - `flutter build apk --debug`
  - direct staging CP12 API probe with company-admin credentials loaded from ignored `scripts/staging-smoke/smoke.env`: review cycle create, cycle activation, review submission, review update, and review acknowledgement all succeeded.
  - `flutter test integration_test\fe5e_admin_reviews_staging_test.dart -d emulator-5554 --dart-define=QA_RUN_STAGING_FE5E=true`

**2026-06-29 FE5F implementation and staging API verification update:**

- Implemented admin notification broadcast operations in Flutter:
  - broadcast composer for title/message/type
  - optional role filter
  - optional specific active employee recipients
  - broadcast result summary with notification and recipient counts
- Added admin route:
  - `/admin/notifications/broadcast`
- Added a `Broadcasts` entry to the admin setup hub; the bottom navigation remains compact for phone use.
- Wired only documented CP13/FE5F endpoint:
  - `POST /api/admin/notifications/broadcast`
- Added guarded staging integration test `mobile/integration_test/fe5f_admin_broadcasts_staging_test.dart`.
- Verification passed:
  - `dart format`
  - `flutter analyze`
  - `flutter test`
  - direct staging CP13 API probe with company-admin and employee credentials loaded from ignored `scripts/staging-smoke/smoke.env`: targeted employee broadcast created one notification and the employee inbox returned it as `UNREAD`.
  - `flutter test integration_test\fe5f_admin_broadcasts_staging_test.dart -d emulator-5554 --dart-define=QA_RUN_STAGING_FE5F=true`

**2026-06-29 FE5G Android staging integration QA update:**

- Implemented admin billing self-view in Flutter:
  - current/latest company subscription display
  - manual payment history display
  - empty states for missing subscription or payment records
  - no provider reference field modeled or rendered in the admin client
- Added admin routes:
  - `/admin/subscription`
  - `/admin/payment-records`
- Added a `Billing` entry to the admin setup hub.
- Wired only documented CP15/FE5G endpoints:
  - `GET /api/admin/subscription`
  - `GET /api/admin/payment-records`
- Added guarded staging integration test `mobile/integration_test/fe5g_admin_billing_staging_test.dart`.
- Verification passed:
  - `dart format`
  - `flutter analyze`
  - `flutter test`
  - `flutter build apk --debug`
  - direct staging CP15 API probe with company-admin credentials loaded from ignored `scripts/staging-smoke/smoke.env`: subscription returned `ACTIVE`, payment history returned zero records, and `providerReference` did not leak.
  - `flutter test integration_test\fe5g_admin_billing_staging_test.dart -d emulator-5554 --dart-define=QA_RUN_STAGING_FE5G=true`

---

## FE6: Manager Team Workflows

**Goal:** Complete manager screens for direct-report operations.

**Required workflows:**

- Manager dashboard: `GET /api/reports/team/dashboard`.
- Team attendance: `GET /api/reports/team/attendance`.
- Team leave list: `GET /api/leave/team`.
- Approve/reject leave: `PATCH /api/leave/:leaveRequestId/approve` and `/reject`.
- Team OKRs: `GET /api/okrs/team`.
- Assign OKR: `POST /api/okrs`.
- OKR detail/update/status/manager approval: `/api/okrs/:okrId`.
- Team reviews: `GET /api/reviews/team`.
- Submit review: `POST /api/reviews/:employeeId/manager-review`.
- Team reports: `GET /api/reports/team/*`.
- Notifications self-view.

**Pass condition:**

- Manager can handle direct-report leave, OKRs, reviews, and reports without accessing admin-only endpoints.

---

## FE7: Super-Admin Platform Workflows

**Goal:** Complete platform-level setup and subscription administration.

**Required workflows:**

- Company CRUD/status using `/api/super-admin/companies`.
- Company context selection for scoped admin views where required.
- Plan CRUD/status using `/api/super-admin/plans`.
- Assign company subscription using `/api/super-admin/companies/:companyId/subscription`.
- Subscription list/status using `/api/super-admin/subscriptions`.
- Manual payment records using `/api/super-admin/payment-records`.
- Company payment records using `/api/super-admin/companies/:companyId/payment-records`.
- Platform dashboard and company rollups using `/api/super-admin/reports/*`.

**Pass condition:**

- Super admin can onboard a company, configure subscription data, record manual payments, and view platform reports.

---

## FE8: Reports and Dashboard Data Rendering

**Goal:** Render all available summary JSON correctly without fake charts or missing-data collapse.

**Required endpoints:**

- Admin: `GET /api/admin/reports/dashboard`, `/attendance`, `/leave`, `/okrs`, `/performance`.
- Manager: `GET /api/reports/team/dashboard`, `/attendance`, `/leave`, `/okrs`, `/performance`.
- Employee: `GET /api/reports/me/dashboard`.
- Super admin: `GET /api/super-admin/reports/dashboard`, `/companies`.

**Rules:**

- Do not call generic report endpoints that do not exist.
- Charts/tables may be rendered from returned summary JSON only.
- Show per-section empty states rather than replacing the whole dashboard when one section is empty.

**Pass condition:**

- All report tabs load or show legitimate empty states for the current role.
- No report page returns a frontend or backend `404` due to wrong routes.

---

## FE9: End-to-End Frontend QA and Launch Gate

**Goal:** Prove the frontend works across all roles against staging.

**Required QA script:**

1. Confirm `GET /health` and `GET /ready`.
2. Confirm CORS for `https://exact-render-route.lovable.app`.
3. Login as each role.
4. Confirm role navigation.
5. Visit every visible nav route.
6. Complete one happy-path workflow per major module:
   - super admin creates/updates company or plan
   - admin creates department/designation/employee/geofence
   - admin enrolls employee face metadata
   - employee face-verifies and clocks in/out
   - admin creates shift and assigns employee
   - employee views shift
   - admin creates leave type/entitlement
   - employee submits leave
   - manager approves leave
   - manager/admin assigns OKR
   - employee updates/approves OKR
   - manager/admin approves OKR
   - admin creates review cycle
   - manager submits review
   - employee views review
   - admin broadcasts notification
   - employee marks notification read
   - each role views reports
7. Confirm `401`, `403`, `404`, validation, `429`, camera denied, GPS denied, and network/CORS states.

**Pass condition:**

- No visible route is broken.
- No screen uses fake local data.
- No frontend calls undocumented endpoints.
- All major role workflows pass against staging.

---

## Immediate Build Order

1. FE0 Flutter foundation: project structure, typed API client, route map, secure token storage, and endpoint audit.
2. FE1 Flutter auth shell: login, session hydration, logout, role navigation, notification badge, and global states.
3. FE4 admin organization setup: employees, departments, designations, manager assignment, face enrollment.
4. FE2 employee self-service pages.
5. FE3 employee attendance: face verification, GPS, clock-in/out.
6. FE5 admin operations.
7. FE6 manager workflows.
8. FE7 super-admin workflows.
9. FE8 report tabs and dashboard data rendering.
10. FE9 full browser QA.

This order is intentional: admin setup creates the data required for employee and manager workflows to feel real.
