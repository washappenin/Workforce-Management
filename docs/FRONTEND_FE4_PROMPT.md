# FE4 FLUTTER PROMPT: ADMIN ORGANIZATION SETUP

Use this prompt for the next Flutter implementation pass.

## Context

The production frontend target is the Flutter mobile app under `mobile/`. The TanStack/Lovable web app is secondary/reference only. Build FE4 in Flutter/Dart and do not modify web app source unless explicitly requested.

Backend base URL:

```text
https://workforce-management-production.up.railway.app
```

Source documents:

- `docs/API_CONTRACT.md`
- `docs/SCREEN_API_MATRIX.md`
- `docs/FRONTEND_ROUTE_MAP.md`
- `docs/ROLE_PERMISSION_MATRIX.md`
- `docs/FRONTEND_CHECKPOINT_LOG.md`
- `docs/FACE_VERIFICATION_RULES.md`
- `mobile/README.md`

Current Flutter state:

- FE0 is passed.
- FE1 auth/shell is implemented.
- Android emulator QA passed for `SUPER_ADMIN` and `EMPLOYEE`.
- `COMPANY_ADMIN`, `HR_ADMIN`, and `MANAGER` role QA is still pending because staging credentials are not available yet.
- Existing app structure uses Riverpod, Dio, GoRouter, `flutter_secure_storage`, and shared state widgets.

## Goal

Implement FE4: admin organization setup workflows in Flutter.

This checkpoint must let `COMPANY_ADMIN` and `HR_ADMIN` manage the company structure needed before employee attendance, shifts, leave, OKRs, reviews, and manager workflows become meaningful.

## Hard Rules

- Do not invent endpoints.
- Do not invent roles.
- Do not use local fake data for successful states.
- Do not add self-registration.
- Do not expose password hashes.
- Do not log temporary passwords, bearer tokens, provider references, biometric values, or GPS values.
- Do not store raw face images, raw biometric vectors, face templates, or provider subject references on device.
- Use the existing API client, auth state, routing patterns, theme, and shared state widgets.
- Handle `{ data, meta }` and `{ error }` envelopes through the existing API client/failure system.
- Keep the design simple, regal, professional, and phone-first.
- Keep this checkpoint scoped to FE4 only. Do not build geofences, shifts, leave, OKRs, reviews, attendance clock-in/out, billing, reports, or super-admin platform management here.

## Routes

Add Flutter routes under the authenticated shell:

- `/admin`
- `/admin/departments`
- `/admin/departments/:departmentId`
- `/admin/designations`
- `/admin/designations/:designationId`
- `/admin/employees`
- `/admin/employees/:employeeId`
- `/admin/employees/:employeeId/face`

Keep `/admin/*` visible to `COMPANY_ADMIN` and `HR_ADMIN`.

For `SUPER_ADMIN`, do not silently expose admin routes without company scope. If a reusable company-scope provider already exists, support scoped super-admin calls by sending `companyId` exactly as the backend contract requires. If no company-scope provider exists, show an access denied or company-scope-required state for `/admin/*` instead of inventing a selector in FE4.

## Navigation

Replace the admin placeholder with a real admin organization hub.

The admin shell should expose a compact mobile navigation path to:

- Departments
- Designations
- Employees
- Account

Use bottom navigation, segmented controls, list rows, sheets, or simple tabbed surfaces as appropriate for phone ergonomics. Avoid dense desktop-only tables.

## API Endpoints

Use only these FE4 endpoints.

Departments:

- `GET /api/admin/departments`
- `POST /api/admin/departments`
- `GET /api/admin/departments/:departmentId`
- `PATCH /api/admin/departments/:departmentId`
- `PATCH /api/admin/departments/:departmentId/status`

Department create body:

```json
{
  "name": "Operations",
  "companyId": "company-id-for-super-admin-only"
}
```

Department status body:

```json
{ "isActive": false }
```

Designations:

- `GET /api/admin/designations`
- `POST /api/admin/designations`
- `GET /api/admin/designations/:designationId`
- `PATCH /api/admin/designations/:designationId`
- `PATCH /api/admin/designations/:designationId/status`

Designation create body:

```json
{
  "title": "Team Lead",
  "departmentId": "department-id",
  "companyId": "company-id-for-super-admin-only"
}
```

Employees:

- `GET /api/admin/employees`
- `POST /api/admin/employees`
- `GET /api/admin/employees/:employeeId`
- `PATCH /api/admin/employees/:employeeId`
- `PATCH /api/admin/employees/:employeeId/status`
- `PATCH /api/admin/employees/:employeeId/manager`

Employee create body:

```json
{
  "email": "employee@example.test",
  "temporaryPassword": "Password123!",
  "firstName": "First",
  "lastName": "Last",
  "employeeCode": "EMP001",
  "phone": "+251911111111",
  "role": "EMPLOYEE",
  "departmentId": "department-id",
  "designationId": "designation-id",
  "managerId": "employee-profile-id"
}
```

Allowed employee creation roles:

- `EMPLOYEE`
- `MANAGER`
- `HR_ADMIN`
- `COMPANY_ADMIN` only when the requester is `SUPER_ADMIN` or `COMPANY_ADMIN`

Do not allow `SUPER_ADMIN` creation through admin employee forms.

Employee status values:

- `ACTIVE`
- `INACTIVE`
- `ON_LEAVE`
- `TERMINATED`

Manager assignment:

- `managerId` must be another employee profile in the same company.
- Do not allow self-manager assignment in the UI.
- Still handle backend validation errors because the backend is the authority.

Face enrollment:

- `GET /api/admin/employees/:employeeId/face-status`
- `POST /api/admin/employees/:employeeId/face-enrollment`
- `PATCH /api/admin/employees/:employeeId/face-enrollment/status`

Face enrollment create body:

```json
{
  "provider": "mock",
  "companyId": "company-id-for-super-admin-only",
  "providerSubjectId": "provider-reference-optional",
  "templateReference": "provider-template-reference-optional"
}
```

Face enrollment status body:

```json
{ "status": "DISABLED" }
```

Allowed face enrollment status values:

- `NOT_ENROLLED`
- `PENDING`
- `ACTIVE`
- `DISABLED`
- `FAILED`

The frontend must never display or persist `providerSubjectId` or `templateReference` after submit. Treat those as write-only optional backend references.

## Required UX

Departments:

- List departments with active/inactive state.
- Empty state: no departments.
- Create department.
- Edit department.
- Activate/deactivate department with confirmation.
- Show duplicate/validation errors from backend.

Designations:

- List designations with active/inactive state.
- Show associated department when returned by backend.
- Create designation with optional department picker from departments.
- Edit designation.
- Activate/deactivate designation with confirmation.
- Handle invalid department and duplicate title/code errors.

Employees:

- List employees with role, status, department/designation, and manager summary when returned.
- Search/filter locally only across already-returned list data. Do not invent server query params unless documented.
- Create employee with temporary password field and clear copy that the password is shown only before submission.
- Role picker must be limited to allowed roles.
- Department/designation pickers should use the real department/designation lists.
- Manager picker should use real employee list data and exclude the current employee.
- Employee detail screen should show profile fields returned by backend.
- Edit employee profile fields using only documented fields.
- Change employee status with confirmation.
- Assign/change/remove manager if backend accepts null removal; if null removal is not documented, do not invent it.

Face enrollment:

- Employee detail should link to face enrollment status.
- Face page should load safe status with `GET /api/admin/employees/:employeeId/face-status`.
- Support creating/updating mock enrollment metadata with provider `mock`.
- Support status change with the documented status values.
- Make the privacy boundary explicit in code and UI: no raw face image capture in FE4, no biometric data storage, no provider reference display after submit.
- Camera capture and employee self face verification belong to FE3, not FE4.

## Error And State Handling

Use existing shared states for:

- loading
- empty
- validation error
- connection issue
- access denied
- not found
- expired session

Handle:

- `401`: existing auth invalidation path.
- `403`: access denied state.
- `404`: resource not found state.
- `422`: field-level validation if details are present.
- `409` or duplicate conflicts if returned by backend.
- `429`: rate-limit messaging.
- network failure: connection issue state.

## Suggested File Shape

Keep files cohesive and small. A reasonable structure:

```text
mobile/lib/features/admin/
  admin_hub_screen.dart
  admin_models.dart
  admin_repository.dart
  admin_controllers.dart
  departments_screen.dart
  designations_screen.dart
  employees_screen.dart
  employee_detail_screen.dart
  face_enrollment_screen.dart
  widgets/
```

Update:

- `mobile/lib/core/routing/router.dart`
- `mobile/lib/features/shell/app_shell.dart`
- `mobile/lib/features/placeholders/role_dashboards.dart` only if the placeholder is replaced or removed.
- `mobile/test/widget_test.dart` or add focused widget/unit tests where practical.

## Verification Required

Run:

```text
cd mobile
dart format lib test
flutter analyze
flutter test
```

If an Android emulator is available, also run:

```text
flutter run -d emulator-5554 --debug --no-resident
```

Then smoke test at least:

- admin hub renders for `COMPANY_ADMIN` or `HR_ADMIN` when credentials exist.
- departments route does not 404.
- designations route does not 404.
- employees route does not 404.
- face enrollment route does not 404 from an employee detail.

If `COMPANY_ADMIN` or `HR_ADMIN` credentials are not available, do not mark FE4 passed. Report it as source-complete and blocked on staging role credentials.

## Response Format

Return a completion report with:

- files changed
- routes added
- endpoints used
- tests run
- emulator/device QA performed
- known gaps
- whether FE4 should be marked `READY_FOR_QA` or remains blocked
