# API CONTRACT

> **Status: CP19 FRONTEND HANDOFF READY WITH STAGING PLACEHOLDER.** Implemented backend endpoints are documented for Lovable handoff. The real staging URL is not available yet and must be recorded as `STAGING_BACKEND_URL` after deployment.
> This is the binding API contract the frontend (Lovable) consumes. Do not invent endpoints, roles, workflows, or local-only data flows.
> **Current implementation status (2026-06-04):** System, auth, authorization verification, CP5 organization endpoints, CP6 geofence endpoints, CP7 attendance endpoints, CP8 face endpoints, CP9 shift endpoints, CP10 leave endpoints, CP11 OKR endpoints, CP12 performance review endpoints, CP13 notification endpoints, CP14 report endpoints, and CP15 subscription/billing endpoints are live locally. CP16-CP19 add hardening, deployment readiness, security verification, and frontend handoff documentation rather than product endpoints.

## Conventions

- **Base URL:** Local default `http://localhost:4000`; staging `https://workforce-management-production.up.railway.app`.
- **Format:** JSON requests and responses.
- **Auth header:** `Authorization: Bearer <access_token>` on protected routes.
- **Company scope:** Derived from the authenticated user context. Client-supplied `companyId` in params, body, or query is verified against the token-derived company and cannot override it.
- **CORS:** Staging/production must configure an explicit frontend origin through `CORS_ORIGIN` or `CORS_ORIGINS`. Wildcard origins are rejected because credentials are enabled.
- **Production system behavior:** `/api/system/*` internal verification routes return `404` in production. `/health` and `/ready` remain public.

### Success Envelope

```json
{ "data": {}, "meta": {} }
```

### Error Envelope

```json
{
  "error": {
    "code": "STRING_CODE",
    "message": "Human-readable message",
    "requestId": "uuid",
    "details": null
  }
}
```

### Standard Status Codes

| Code | Meaning |
| ---- | ------- |
| 200 | OK |
| 201 | Created |
| 204 | No Content |
| 400 | Bad Request (malformed) |
| 401 | Unauthenticated |
| 403 | Forbidden (authenticated, not allowed) |
| 404 | Not Found |
| 409 | Conflict |
| 422 | Validation error |
| 429 | Rate limited |
| 500 | Server error |

## Endpoint Inventory (by checkpoint)

> Each row is finalized when its checkpoint is implemented. Roles reference `ROLE_PERMISSION_MATRIX.md`.

### Database Foundation (CP2)

Checkpoint 2 adds Prisma schema models, enums, indexes, constraints, and seed-ready structure only. It adds no REST endpoints and does not change the CP1 system endpoint contract.

### System (CP1)
| Method | Path | Auth | Roles | Status |
| ------ | ---- | ---- | ----- | ------ |
| GET | `/health` | None | Public | Implemented CP1 |
| GET | `/ready` | None | Public | Implemented CP1 |

#### `GET /health`

Returns liveness only. It does not check downstream dependencies.

```json
{
  "data": {
    "status": "ok",
    "uptime": 12.34,
    "timestamp": "2026-06-02T00:00:00.000Z",
    "environment": "development"
  },
  "meta": {
    "requestId": "uuid"
  }
}
```

#### `GET /ready`

Returns readiness and dependency status. In local/test environments, an unset `DATABASE_URL` is reported as `not_configured` but does not fail readiness. In production, `DATABASE_URL` is required by environment validation.

```json
{
  "data": {
    "status": "ready",
    "timestamp": "2026-06-02T00:00:00.000Z",
    "checks": {
      "database": {
        "configured": false,
        "status": "not_configured",
        "message": "DATABASE_URL is not configured"
      }
    }
  },
  "meta": {
    "requestId": "uuid"
  }
}
```

### Auth (CP3)
| Method | Path | Auth | Roles | Status |
| ------ | ---- | ---- | ----- | ------ |
| POST | `/api/auth/login` | None | Public | Implemented CP3 |
| GET | `/api/auth/me` | Bearer token | All authenticated users | Implemented CP3 |
| POST | `/api/auth/logout` | Bearer token | All authenticated users | Implemented CP3 |

No public registration endpoint exists. Employees and other users are created by authorized organization users in later checkpoints.

#### `POST /api/auth/login`

Request:

```json
{
  "email": "employee@example.test",
  "password": "Password123!"
}
```

Rules:

- Email is normalized to lowercase.
- Invalid email/password, unknown user, disabled user, or suspended user returns the same generic `401`.
- Login creates an active `DeviceSession`, updates `lastLoginAt`, and returns an access token.
- Response never includes `passwordHash`.

Response:

```json
{
  "data": {
    "user": {
      "id": "user-id",
      "email": "employee@example.test",
      "companyId": "company-id",
      "roles": ["EMPLOYEE"],
      "status": "ACTIVE"
    },
    "accessToken": "jwt",
    "tokenType": "Bearer"
  }
}
```

Auth errors:

```json
{
  "error": {
    "code": "UNAUTHENTICATED",
    "message": "Invalid email or password",
    "requestId": "uuid"
  }
}
```

Validation errors use `400` with code `VALIDATION_ERROR`.

#### `GET /api/auth/me`

Requires:

```http
Authorization: Bearer <access_token>
```

Response:

```json
{
  "data": {
    "user": {
      "id": "user-id",
      "email": "employee@example.test",
      "companyId": "company-id",
      "roles": ["EMPLOYEE"],
      "status": "ACTIVE"
    }
  }
}
```

Missing, invalid, expired, or revoked tokens return `401`.

#### `POST /api/auth/logout`

Requires:

```http
Authorization: Bearer <access_token>
```

Marks the current device session `REVOKED`.

Response:

```json
{
  "data": {
    "success": true
  }
}
```

### Authorization Verification (CP4)

These endpoints are internal CP4 security verification routes. They exist so RBAC and company-scope behavior can be tested before product/business modules are implemented. They are not workforce-management product features.

CP16 locks these routes down so `/api/system/*` verification routes are available only outside production. In `NODE_ENV=production`, `/api/system/*` returns `404 NOT_FOUND`. `GET /health` and `GET /ready` remain public as designed.

| Method | Path | Auth | Roles | Status |
| ------ | ---- | ---- | ----- | ------ |
| GET | `/api/system/auth-check` | Bearer token outside production; disabled in production | All authenticated users | Implemented CP4; production-disabled CP16 |
| GET | `/api/system/role-check/super-admin` | Bearer token outside production; disabled in production | SUPER_ADMIN | Implemented CP4; production-disabled CP16 |
| GET | `/api/system/role-check/company-admin` | Bearer token outside production; disabled in production | COMPANY_ADMIN | Implemented CP4; production-disabled CP16 |
| GET | `/api/system/role-check/hr-admin` | Bearer token outside production; disabled in production | HR_ADMIN | Implemented CP4; production-disabled CP16 |
| GET | `/api/system/role-check/manager` | Bearer token outside production; disabled in production | MANAGER | Implemented CP4; production-disabled CP16 |
| GET | `/api/system/role-check/employee` | Bearer token outside production; disabled in production | EMPLOYEE | Implemented CP4; production-disabled CP16 |
| GET | `/api/system/role-check/admin-or-hr` | Bearer token outside production; disabled in production | COMPANY_ADMIN, HR_ADMIN | Implemented CP4; production-disabled CP16 |
| GET | `/api/system/company-scope/:companyId` | Bearer token outside production; disabled in production | All authenticated users, scoped | Implemented CP4; production-disabled CP16 |
| POST | `/api/system/company-scope/:companyId` | Bearer token outside production; disabled in production | All authenticated users, scoped | Implemented CP4; production-disabled CP16 |
| GET | `/api/system/company-scope-required` | Bearer token outside production; disabled in production | Internal negative/edge verification | Implemented CP4; production-disabled CP16 |

#### `GET /api/system/auth-check`

Returns the authenticated user context without secrets.

```json
{
  "data": {
    "authenticated": true,
    "user": {
      "id": "user-id",
      "email": "employee@example.test",
      "companyId": "company-id",
      "roles": ["EMPLOYEE"],
      "status": "ACTIVE"
    }
  }
}
```

Missing, malformed, invalid, expired, or revoked tokens return `401`.

#### `GET /api/system/role-check/*`

Returns `200` only when the authenticated user has the route's required role or one of the allowed roles. Authenticated users without the required role receive `403`.

```json
{
  "data": {
    "allowed": true,
    "roles": ["COMPANY_ADMIN"]
  }
}
```

#### `GET|POST /api/system/company-scope/:companyId`

Verifies company scope using route params, request body, and query string. Non-super-admin users must match their authenticated `companyId`; `SUPER_ADMIN` may access any requested company scope.

```json
{
  "data": {
    "companyScope": {
      "companyId": "company-id",
      "isSuperAdmin": false,
      "requestedCompanyId": "company-id"
    }
  }
}
```

Company mismatch, spoofed body/query `companyId`, or missing required company scope for non-super-admin users returns `403` and must not expose whether another company's resource exists.

### Companies / Departments / Employees (CP5)

CP5 adds the first real business endpoints. All responses omit `passwordHash`. There is still no public registration endpoint.

| Method | Path | Auth | Roles | Status |
| ------ | ---- | ---- | ----- | ------ |
| POST | `/api/super-admin/companies` | Bearer token | SUPER_ADMIN | Implemented CP5 |
| GET | `/api/super-admin/companies` | Bearer token | SUPER_ADMIN | Implemented CP5 |
| GET | `/api/super-admin/companies/:companyId` | Bearer token | SUPER_ADMIN | Implemented CP5 |
| PATCH | `/api/super-admin/companies/:companyId` | Bearer token | SUPER_ADMIN | Implemented CP5 |
| PATCH | `/api/super-admin/companies/:companyId/status` | Bearer token | SUPER_ADMIN | Implemented CP5 |
| POST | `/api/admin/departments` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP5 |
| GET | `/api/admin/departments` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP5 |
| GET | `/api/admin/departments/:departmentId` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP5 |
| PATCH | `/api/admin/departments/:departmentId` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP5 |
| PATCH | `/api/admin/departments/:departmentId/status` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP5 |
| POST | `/api/admin/designations` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP5 |
| GET | `/api/admin/designations` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP5 |
| GET | `/api/admin/designations/:designationId` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP5 |
| PATCH | `/api/admin/designations/:designationId` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP5 |
| PATCH | `/api/admin/designations/:designationId/status` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP5 |
| POST | `/api/admin/employees` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP5 |
| GET | `/api/admin/employees` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP5 |
| GET | `/api/admin/employees/:employeeId` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP5 |
| PATCH | `/api/admin/employees/:employeeId` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP5 |
| PATCH | `/api/admin/employees/:employeeId/status` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP5 |
| PATCH | `/api/admin/employees/:employeeId/manager` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP5 |
| GET | `/api/employees/me` | Bearer token | All authenticated users with an employee profile | Implemented CP5 |

#### Company Management

`POST /api/super-admin/companies`

```json
{
  "name": "Acme Workforce",
  "contactEmail": "owner@example.test",
  "contactPhone": "+251911111111",
  "billingEmail": "billing@example.test",
  "address": "Addis Ababa",
  "country": "Ethiopia",
  "timezone": "Africa/Addis_Ababa"
}
```

`PATCH /api/super-admin/companies/:companyId/status`

```json
{ "status": "ACTIVE" }
```

Allowed `CompanyStatus` values: `ACTIVE`, `INACTIVE`, `SUSPENDED`.

#### Department Management

`POST /api/admin/departments`

```json
{
  "name": "Operations",
  "companyId": "company-id-for-super-admin-only"
}
```

`PATCH /api/admin/departments/:departmentId/status`

```json
{ "isActive": false }
```

For `COMPANY_ADMIN` and `HR_ADMIN`, `companyId` is resolved from the authenticated user and cannot be overridden. `SUPER_ADMIN` must supply `companyId` in the body for create or in the query string for list/detail/update/status operations.

#### Designation Management

`POST /api/admin/designations`

```json
{
  "title": "Team Lead",
  "departmentId": "department-id",
  "companyId": "company-id-for-super-admin-only"
}
```

If `departmentId` is provided, it must belong to the resolved company scope.

#### Employee Management

`POST /api/admin/employees`

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

Rules:

- `temporaryPassword` is required in CP5 development flow and is hashed before storage.
- Response never includes `passwordHash` or the temporary password.
- Allowed creation roles: `EMPLOYEE`, `MANAGER`, `HR_ADMIN`; `COMPANY_ADMIN` only when the requester is `SUPER_ADMIN` or `COMPANY_ADMIN`.
- `SUPER_ADMIN` cannot be created through these endpoints.
- `departmentId`, `designationId`, and `managerId` must belong to the resolved company.
- `managerId` cannot be the employee's own profile ID.
- `PATCH /api/admin/employees/:employeeId/status` accepts `EmployeeStatus`: `ACTIVE`, `INACTIVE`, `ON_LEAVE`, `TERMINATED`.
- Employee status `ACTIVE` and `ON_LEAVE` map the linked user to `ACTIVE`; `INACTIVE` and `TERMINATED` map the linked user to `DISABLED`.

`GET /api/employees/me`

Returns the authenticated user's own employee profile:

```json
{
  "data": {
    "employee": {
      "id": "employee-profile-id",
      "companyId": "company-id",
      "email": "employee@example.test",
      "roles": ["EMPLOYEE"],
      "employeeCode": "EMP001",
      "firstName": "First",
      "lastName": "Last",
      "status": "ACTIVE"
    }
  }
}
```

CP5 error behavior:

- `401`: missing, malformed, invalid, expired, or revoked token.
- `403`: wrong role, missing required company scope for `SUPER_ADMIN`, or explicit company-scope mismatch.
- `404`: record not found inside the caller's allowed company scope.
- `409`: duplicate company name, department name, designation title, email, or employee code conflict.

### Geofences (CP6)

CP6 supports circular geofences only. The schema allows multiple geofences per company; product policy may later restrict active geofence count in service logic if required. CP6 location validation does not create attendance records, attendance events, or location pings.

| Method | Path | Auth | Roles | Status |
| ------ | ---- | ---- | ----- | ------ |
| POST | `/api/admin/geofences` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP6 |
| GET | `/api/admin/geofences` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP6 |
| GET | `/api/admin/geofences/:geofenceId` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP6 |
| PATCH | `/api/admin/geofences/:geofenceId` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP6 |
| PATCH | `/api/admin/geofences/:geofenceId/status` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP6 |
| POST | `/api/geofences/validate-location` | Bearer token | All authenticated users, scoped | Implemented CP6 |

#### `POST /api/admin/geofences`

```json
{
  "name": "Main Office",
  "latitude": 9.0301,
  "longitude": 38.74,
  "radiusMeters": 100,
  "status": "ACTIVE",
  "companyId": "company-id-for-super-admin-only"
}
```

Rules:

- `latitude` must be between `-90` and `90`.
- `longitude` must be between `-180` and `180`.
- `radiusMeters` must be a positive integer up to `50000`.
- Allowed `GeofenceStatus` values: `ACTIVE`, `INACTIVE`, `ARCHIVED`.
- `COMPANY_ADMIN` and `HR_ADMIN` cannot override their authenticated company scope.
- `SUPER_ADMIN` must supply an explicit safe `companyId`.
- Geofence names are unique within a company.

Response:

```json
{
  "data": {
    "geofence": {
      "id": "geofence-id",
      "companyId": "company-id",
      "name": "Main Office",
      "latitude": 9.0301,
      "longitude": 38.74,
      "radiusMeters": 100,
      "status": "ACTIVE"
    }
  }
}
```

#### `PATCH /api/admin/geofences/:geofenceId`

Updates one or more of `name`, `latitude`, `longitude`, `radiusMeters` inside the resolved company scope.

#### `PATCH /api/admin/geofences/:geofenceId/status`

```json
{ "status": "INACTIVE" }
```

#### `POST /api/geofences/validate-location`

```json
{
  "latitude": 9.0301,
  "longitude": 38.74,
  "companyId": "company-id-for-super-admin-only"
}
```

Inside response:

```json
{
  "data": {
    "isWithinGeofence": true,
    "geofenceId": "geofence-id",
    "distanceMeters": 42.5,
    "radiusMeters": 100
  }
}
```

Outside response:

```json
{
  "data": {
    "isWithinGeofence": false,
    "nearestGeofenceId": "geofence-id",
    "distanceMeters": 250.3,
    "radiusMeters": 100
  }
}
```

No active geofence response:

```json
{
  "data": {
    "isWithinGeofence": false,
    "reason": "NO_ACTIVE_GEOFENCE"
  }
}
```

CP6 returns `nearestGeofenceId` only after the request has been scoped to the authenticated company or explicit `SUPER_ADMIN` company context. It does not expose cross-company geofence existence.

CP6 error behavior:

- `401`: missing, malformed, invalid, expired, or revoked token.
- `403`: wrong role, missing required company scope for `SUPER_ADMIN`, or explicit company-scope mismatch.
- `404`: geofence not found inside the caller's allowed company scope.
- `409`: duplicate geofence name inside a company.
- `400`: invalid latitude, longitude, radius, body, params, or query.

### Attendance (CP7, updated CP8)

CP7 implements self-service clock-in/out with GPS and active geofence enforcement. CP8 adds the required face-verification gate for clock-in. Attendance still does not implement shift logic, continuous GPS tracking, or clocking in/out for other users.

| Method | Path | Auth | Roles | Status |
| ------ | ---- | ---- | ----- | ------ |
| POST | `/api/attendance/clock-in` | Bearer token | Authenticated non-super-admin users with active employee profile | Implemented CP7; face gate CP8 |
| POST | `/api/attendance/clock-out` | Bearer token | Authenticated non-super-admin users with active employee profile | Implemented CP7 |
| GET | `/api/attendance/me` | Bearer token | Authenticated users with employee profile | Implemented CP7 |
| GET | `/api/admin/attendance` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP7 |

#### `POST /api/attendance/clock-in`

```json
{
  "latitude": 9.0301,
  "longitude": 38.74,
  "accuracyMeters": 12.5,
  "faceVerificationReference": "face-verification-reference"
}
```

Rules:

- Requires authentication.
- Caller must have an active `EmployeeProfile`.
- `SUPER_ADMIN` clock-in is rejected in CP7.
- Caller's company must be active.
- Requires a short-lived, unused face verification reference created by `POST /api/face/verify`.
- Face verification reference must belong to the same employee and cannot be expired or reused.
- Coordinates must be inside at least one active company geofence.
- Duplicate open sessions are rejected.
- Creates `AttendanceSession` with status `OPEN`.
- Creates `AttendanceEvent` with type `CLOCK_IN`.
- Sets `clockInFaceVerified` to `true` only after consuming a valid CP8 face verification reference.

Response:

```json
{
  "data": {
    "attendanceSession": {
      "id": "attendance-session-id",
      "companyId": "company-id",
      "employeeId": "employee-profile-id",
      "status": "OPEN",
      "clockInAt": "2026-06-03T08:00:00.000Z",
      "clockOutAt": null,
      "clockInGeofenceId": "geofence-id",
      "clockOutGeofenceId": null,
      "clockInFaceVerified": true
    },
    "geofence": {
      "id": "geofence-id",
      "distanceMeters": 42.5,
      "radiusMeters": 100
    }
  }
}
```

#### `POST /api/attendance/clock-out`

```json
{
  "latitude": 9.0301,
  "longitude": 38.74,
  "accuracyMeters": 12.5
}
```

Rules:

- Requires an open attendance session for the caller's own employee profile.
- Coordinates must be inside at least one active company geofence.
- Outside-geofence clock-out is rejected in CP7.
- Updates the open `AttendanceSession` to `CLOSED`.
- Creates `AttendanceEvent` with type `CLOCK_OUT`.
- CP7 does not create `GeofenceBreach` records for rejected outside-geofence attempts.

#### `GET /api/attendance/me`

Returns the authenticated employee's own attendance sessions. Supports optional query filters:

- `from`
- `to`

#### `GET /api/admin/attendance`

Returns scoped company attendance logs. Supports optional query filters:

- `companyId` for `SUPER_ADMIN` only.
- `employeeId`
- `from`
- `to`
- `status` (`OPEN`, `CLOSED`, `CANCELLED`)

Rules:

- `COMPANY_ADMIN` and `HR_ADMIN` are scoped to their own company.
- `SUPER_ADMIN` must provide explicit safe `companyId`.
- `EMPLOYEE` cannot access admin attendance logs.
- `employeeId` filter must belong to the resolved company scope.

CP7 error behavior:

- `401`: missing, malformed, invalid, expired, or revoked token.
- `403`: wrong role, missing employee profile, inactive employee/company, super-admin self clock-in/out, missing `SUPER_ADMIN` scope, or company mismatch.
- `400`: invalid coordinates, invalid date filters, missing/invalid/expired/reused face verification reference, no active geofence, outside geofence, duplicate open session, or clock-out without open session.
- `404`: future record detail routes only; CP7 list routes hide cross-company data by scope.

### Face Verification (CP8)
| Method | Path | Auth | Roles | Status |
| ------ | ---- | ---- | ----- | ------ |
| POST | `/api/admin/employees/:employeeId/face-enrollment` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP8 |
| GET | `/api/admin/employees/:employeeId/face-status` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP8 |
| PATCH | `/api/admin/employees/:employeeId/face-enrollment/status` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP8 |
| POST | `/api/face/verify` | Bearer token | Authenticated user verifying self | Implemented CP8 |

CP8 uses a vendor-agnostic adapter layer with the development `mock` provider. It stores only provider references and metadata on `FaceEnrollment`; raw face images, raw biometric vectors, and face templates are not accepted by the API and are never returned.

#### `POST /api/admin/employees/:employeeId/face-enrollment`

```json
{
  "provider": "mock",
  "companyId": "company-id-for-super-admin-only",
  "providerSubjectId": "provider-reference-optional",
  "templateReference": "provider-template-reference-optional"
}
```

Rules:

- `COMPANY_ADMIN` and `HR_ADMIN` can enroll employees only inside their authenticated company.
- `SUPER_ADMIN` must supply explicit safe `companyId`.
- `MANAGER` and `EMPLOYEE` are denied.
- Create/update actions write `AuditLog` entries.
- Responses omit `providerSubjectId`, `templateReference`, raw image fields, and biometric payloads.

Response:

```json
{
  "data": {
    "faceEnrollment": {
      "id": "face-enrollment-id",
      "employeeId": "employee-profile-id",
      "companyId": "company-id",
      "provider": "mock",
      "status": "ACTIVE",
      "enrolledAt": "2026-06-03T08:00:00.000Z"
    }
  }
}
```

#### `GET /api/admin/employees/:employeeId/face-status`

Returns the safe enrollment status for an employee in the resolved company scope. If no enrollment exists inside scope, the response is:

```json
{
  "data": {
    "faceEnrollment": {
      "status": "NOT_ENROLLED",
      "enrolledAt": null
    }
  }
}
```

#### `PATCH /api/admin/employees/:employeeId/face-enrollment/status`

```json
{ "status": "DISABLED" }
```

Allowed `FaceEnrollmentStatus` values: `NOT_ENROLLED`, `PENDING`, `ACTIVE`, `DISABLED`, `FAILED`. Status changes write `AuditLog` entries.

#### `POST /api/face/verify`

```json
{
  "provider": "mock",
  "verificationReference": "mock-pass"
}
```

Rules:

- Verification is self-service only. The optional `employeeId`, if sent, must match the authenticated user's employee profile.
- Requires an active `FaceEnrollment`.
- `mock-pass` succeeds; `mock-fail` fails with `FACE_NOT_MATCHED`.
- Successful verification returns a short-lived development `verificationReference` for `POST /api/attendance/clock-in`.
- Verification attempts do not log raw face payloads and do not expose provider enrollment references.

Success response:

```json
{
  "data": {
    "verified": true,
    "employeeId": "employee-profile-id",
    "provider": "mock",
    "verificationReference": "face-verification-reference",
    "expiresAt": "2026-06-03T08:05:00.000Z"
  }
}
```

Failed match response:

```json
{
  "data": {
    "verified": false,
    "reason": "FACE_NOT_MATCHED"
  }
}
```

CP8 error behavior:

- `401`: missing, malformed, invalid, expired, or revoked token.
- `403`: wrong role, missing required `SUPER_ADMIN` scope, company mismatch, missing employee profile, non-self verification, or missing active enrollment.
- `404`: employee or enrollment not found inside the caller's allowed company scope.
- `400`: invalid params, query, body, unsupported provider, raw face payload fields, or mismatched provider.

### Shifts (CP9)
| Method | Path | Auth | Roles | Status |
| ------ | ---- | ---- | ----- | ------ |
| POST | `/api/admin/shifts` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP9 |
| GET | `/api/admin/shifts` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP9 |
| GET | `/api/admin/shifts/:shiftId` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP9 |
| PATCH | `/api/admin/shifts/:shiftId` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP9 |
| PATCH | `/api/admin/shifts/:shiftId/status` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP9 |
| POST | `/api/admin/shifts/:shiftId/assign` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` query | Implemented CP9 |
| GET | `/api/admin/shifts/:shiftId/assignments` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` query | Implemented CP9 |
| PATCH | `/api/admin/shift-assignments/:assignmentId` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` query | Implemented CP9 |
| DELETE | `/api/admin/shift-assignments/:assignmentId` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` query | Implemented CP9 |
| GET | `/api/shifts/me` | Bearer token | Authenticated users with own employee profile | Implemented CP9 |

CP9 implements simple shift definitions and employee assignments. It does not implement payroll, overtime, advanced scheduling, recurring calendars, holiday calendars, or attendance-time enforcement.

#### `POST /api/admin/shifts`

```json
{
  "name": "Morning Shift",
  "startTime": "09:00",
  "endTime": "17:00",
  "companyId": "company-id-for-super-admin-only"
}
```

Rules:

- `name` is required and unique within the resolved company.
- `startTime` and `endTime` must use `HH:mm`.
- Overnight shifts are allowed by storing an end time earlier than the start time.
- `COMPANY_ADMIN` and `HR_ADMIN` are scoped to their company.
- `SUPER_ADMIN` must supply explicit safe `companyId`.
- Create writes an audit log.

Response:

```json
{
  "data": {
    "shift": {
      "id": "shift-id",
      "companyId": "company-id",
      "name": "Morning Shift",
      "startTime": "09:00",
      "endTime": "17:00",
      "status": "ACTIVE"
    }
  }
}
```

#### `GET /api/admin/shifts`

Returns shifts in the resolved company scope. `SUPER_ADMIN` supplies `?companyId=...`.

#### `GET /api/admin/shifts/:shiftId`

Returns one shift only if it belongs to the resolved company scope.

#### `PATCH /api/admin/shifts/:shiftId`

```json
{
  "name": "Morning Shift Updated",
  "startTime": "08:30",
  "endTime": "16:30"
}
```

At least one field is required. Updates write an audit log.

#### `PATCH /api/admin/shifts/:shiftId/status`

```json
{ "status": "INACTIVE" }
```

Allowed `ShiftStatus` values: `ACTIVE`, `INACTIVE`, `ARCHIVED`. Deactivating a shift does not delete historical assignments.

#### `POST /api/admin/shifts/:shiftId/assign`

```json
{
  "employeeId": "employee-profile-id",
  "startsOn": "2026-06-01",
  "endsOn": null
}
```

Rules:

- Shift must belong to the resolved company and be `ACTIVE`.
- Employee must belong to the resolved company and be `ACTIVE`.
- `startsOn` is required as `YYYY-MM-DD`.
- `endsOn` is optional/null and cannot be before `startsOn`.
- CP9 prevents obvious overlapping duplicate assignments for the same employee and same shift.
- Complex conflict detection across different shifts is not implemented.
- Assignment writes an audit log.

Response:

```json
{
  "data": {
    "assignment": {
      "id": "assignment-id",
      "companyId": "company-id",
      "employeeId": "employee-profile-id",
      "shiftId": "shift-id",
      "startsOn": "2026-06-01T00:00:00.000Z",
      "endsOn": null,
      "shift": {
        "id": "shift-id",
        "name": "Morning Shift",
        "startTime": "09:00",
        "endTime": "17:00",
        "status": "ACTIVE"
      }
    }
  }
}
```

#### `GET /api/admin/shifts/:shiftId/assignments`

Lists assignments for a shift inside the resolved company scope.

#### `PATCH /api/admin/shift-assignments/:assignmentId`

```json
{
  "startsOn": "2026-06-01",
  "endsOn": "2026-09-01"
}
```

At least one date field is required. Updates write an audit log.

#### `DELETE /api/admin/shift-assignments/:assignmentId`

Hard-deletes the assignment record because the CP2 schema has no soft-delete field for assignments. It does not delete the employee or shift. Removal writes an audit log.

Response:

```json
{
  "data": {
    "success": true
  }
}
```

#### `GET /api/shifts/me`

Returns current and future assignments for the authenticated user's own `EmployeeProfile`.

```json
{
  "data": {
    "assignments": [
      {
        "id": "assignment-id",
        "employeeId": "employee-profile-id",
        "shiftId": "shift-id",
        "startsOn": "2026-06-01T00:00:00.000Z",
        "endsOn": null,
        "shift": {
          "name": "Morning Shift",
          "startTime": "09:00",
          "endTime": "17:00",
          "status": "ACTIVE"
        }
      }
    ]
  }
}
```

CP9 error behavior:

- `401`: missing, malformed, invalid, expired, or revoked token.
- `403`: wrong role, missing required `SUPER_ADMIN` scope, company mismatch, user without employee profile on self-view, inactive employee profile, or inactive company.
- `404`: shift, employee, or assignment not found inside the caller's allowed company scope.
- `409`: duplicate shift name or overlapping same-employee/same-shift assignment.
- `400`: invalid body, params, query, time format, status, date format, inactive shift assignment, inactive employee assignment, or `endsOn` before `startsOn`.

### Leave (CP10)
| Method | Path | Auth | Roles | Status |
| ------ | ---- | ---- | ----- | ------ |
| POST | `/api/admin/leave-types` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP10 |
| GET | `/api/admin/leave-types` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP10 |
| GET | `/api/admin/leave-types/:leaveTypeId` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP10 |
| PATCH | `/api/admin/leave-types/:leaveTypeId` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP10 |
| PATCH | `/api/admin/leave-types/:leaveTypeId/status` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP10 |
| POST | `/api/admin/leave-entitlements` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP10 |
| GET | `/api/admin/leave-entitlements` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP10 |
| GET | `/api/admin/leave-entitlements/:entitlementId` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP10 |
| PATCH | `/api/admin/leave-entitlements/:entitlementId` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP10 |
| POST | `/api/leave/request` | Bearer token | Authenticated users with own active employee profile | Implemented CP10 |
| GET | `/api/leave/me` | Bearer token | Authenticated users with own active employee profile | Implemented CP10 |
| GET | `/api/leave/team` | Bearer token | MANAGER direct reports only | Implemented CP10 |
| GET | `/api/admin/leave-requests` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP10 |
| PATCH | `/api/leave/:leaveRequestId/approve` | Bearer token | MANAGER direct reports; COMPANY_ADMIN/HR_ADMIN company; SUPER_ADMIN with `companyId` | Implemented CP10 |
| PATCH | `/api/leave/:leaveRequestId/reject` | Bearer token | MANAGER direct reports; COMPANY_ADMIN/HR_ADMIN company; SUPER_ADMIN with `companyId` | Implemented CP10 |

CP10 implements leave types, entitlements, full-day self-service requests, manager direct-report review, and HR/Admin company review. It does not implement payroll, partial-day leave, holiday calendars, complex accruals, carryover, calendar integrations, or automatic payroll deductions.

#### `POST /api/admin/leave-types`

```json
{
  "name": "Annual Leave",
  "defaultAnnualAllowance": 20,
  "companyId": "company-id-for-super-admin-only"
}
```

Rules:

- Leave type names are unique within a company.
- `defaultAnnualAllowance` is optional/null and must be non-negative.
- `COMPANY_ADMIN` and `HR_ADMIN` are scoped to their company.
- `SUPER_ADMIN` must supply explicit safe `companyId`.
- Create writes an audit log.

#### `GET /api/admin/leave-types`

Returns leave types in the resolved company scope. `SUPER_ADMIN` supplies `?companyId=...`.

#### `GET /api/admin/leave-types/:leaveTypeId`

Returns one leave type only if it belongs to the resolved company scope.

#### `PATCH /api/admin/leave-types/:leaveTypeId`

```json
{
  "name": "Annual Leave",
  "defaultAnnualAllowance": 25
}
```

At least one field is required. Updates write an audit log.

#### `PATCH /api/admin/leave-types/:leaveTypeId/status`

```json
{ "status": "INACTIVE" }
```

Allowed `LeaveTypeStatus` values: `ACTIVE`, `INACTIVE`. Deactivation does not delete historical leave requests or entitlements.

#### `POST /api/admin/leave-entitlements`

```json
{
  "employeeId": "employee-profile-id",
  "leaveTypeId": "leave-type-id",
  "year": 2026,
  "totalDays": 20,
  "usedDays": 0,
  "companyId": "company-id-for-super-admin-only"
}
```

Rules:

- Employee and leave type must belong to the resolved company.
- Employee and leave type must be active.
- `totalDays` and `usedDays` must be non-negative.
- `usedDays` cannot exceed `totalDays`.
- Duplicate `employeeId + leaveTypeId + year` uses upsert behavior: existing entitlement is updated.
- Create/update writes an audit log.

#### `GET /api/admin/leave-entitlements`

Supports scoped filters:

- `companyId` for `SUPER_ADMIN` only.
- `employeeId`
- `leaveTypeId`
- `year`

#### `GET /api/admin/leave-entitlements/:entitlementId`

Returns one entitlement only if it belongs to the resolved company scope.

#### `PATCH /api/admin/leave-entitlements/:entitlementId`

```json
{
  "totalDays": 25,
  "usedDays": 5
}
```

At least one field is required. `usedDays` cannot exceed the resulting `totalDays`.

#### `POST /api/leave/request`

```json
{
  "leaveTypeId": "leave-type-id",
  "startDate": "2026-06-10",
  "endDate": "2026-06-12",
  "reason": "Family matter"
}
```

Rules:

- Self-service only; client-supplied `employeeId` is rejected.
- Requires active employee profile and active company.
- Leave type must be active and belong to the caller's company.
- Dates use `YYYY-MM-DD`.
- CP10 counts full days inclusively and does not support partial-day leave.
- Requests must stay within one entitlement year.
- CP10 uses `NO_ENTITLEMENT` policy: no matching entitlement means request creation is rejected.
- Requested days cannot exceed remaining entitlement balance.
- `usedDays` is not updated until approval.
- Overlapping pending or approved leave requests for the same employee are rejected.
- Request starts as `PENDING`.
- Submission writes an audit log without the reason text.

#### `GET /api/leave/me`

Returns the authenticated employee's own leave requests and entitlements. Optional filters:

- `status`
- `year`

#### `GET /api/leave/team`

Returns leave requests for the manager's direct reports only. Direct reports are resolved through `EmployeeProfile.managerId`.

#### `GET /api/admin/leave-requests`

Returns scoped company leave requests. Supports filters:

- `companyId` for `SUPER_ADMIN` only.
- `employeeId`
- `status`
- `leaveTypeId`
- `from`
- `to`

#### `PATCH /api/leave/:leaveRequestId/approve`

```json
{
  "comment": "Approved"
}
```

Rules:

- `MANAGER` can approve only direct-report requests.
- `COMPANY_ADMIN` and `HR_ADMIN` can approve company requests.
- `SUPER_ADMIN` must supply explicit safe `companyId`.
- Request must be `PENDING`.
- Approval sets `APPROVED`, `reviewedById`, `reviewedAt`, and optional `reviewComment`.
- Approval rechecks entitlement balance and increments `usedDays`.
- Approval writes an audit log without review comment text.

#### `PATCH /api/leave/:leaveRequestId/reject`

```json
{
  "comment": "Rejected"
}
```

Rules match approval. Rejection sets `REJECTED`, review metadata, and does not increment `usedDays`.

CP10 response example:

```json
{
  "data": {
    "leaveRequest": {
      "id": "leave-request-id",
      "employeeId": "employee-profile-id",
      "leaveTypeId": "leave-type-id",
      "startDate": "2026-06-10T00:00:00.000Z",
      "endDate": "2026-06-12T00:00:00.000Z",
      "requestedDays": 3,
      "status": "PENDING"
    }
  }
}
```

CP10 error behavior:

- `401`: missing, malformed, invalid, expired, or revoked token.
- `403`: wrong role, missing required `SUPER_ADMIN` scope, company mismatch, missing employee profile, inactive employee/company, or manager access outside direct reports.
- `404`: leave type, entitlement, employee, or leave request not found inside the caller's allowed scope.
- `409`: duplicate leave type name or overlapping pending/approved leave request.
- `400`: invalid body, params, query, status, date range, `NO_ENTITLEMENT`, insufficient balance, inactive leave type, inactive employee, `usedDays > totalDays`, non-pending review, or cross-year request.

### OKRs (CP11)
| Method | Path | Auth | Roles | Status |
| ------ | ---- | ---- | ----- | ------ |
| POST | `/api/okrs` | Bearer token | COMPANY_ADMIN, HR_ADMIN; MANAGER direct reports; SUPER_ADMIN with employee profile + `companyId` | Implemented CP11 |
| GET | `/api/okrs/me` | Bearer token | Authenticated users with own employee profile | Implemented CP11 |
| GET | `/api/okrs/team` | Bearer token | MANAGER direct reports only | Implemented CP11 |
| GET | `/api/admin/okrs` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP11 |
| GET | `/api/okrs/:okrId` | Bearer token | Own, direct-report, company admin/HR, or scoped super-admin | Implemented CP11 |
| PATCH | `/api/okrs/:okrId` | Bearer token | COMPANY_ADMIN, HR_ADMIN, direct manager; SUPER_ADMIN with `companyId` | Implemented CP11 |
| PATCH | `/api/okrs/:okrId/status` | Bearer token | COMPANY_ADMIN, HR_ADMIN, direct manager; SUPER_ADMIN with `companyId` | Implemented CP11 |
| POST | `/api/okrs/:okrId/progress` | Bearer token | OKR owner only | Implemented CP11 |
| PATCH | `/api/okrs/:okrId/employee-approve` | Bearer token | OKR owner only | Implemented CP11 |
| PATCH | `/api/okrs/:okrId/manager-approve` | Bearer token | MANAGER direct reports; COMPANY_ADMIN/HR_ADMIN company; SUPER_ADMIN with employee profile + `companyId` | Implemented CP11 |

CP11 implements text-based OKRs only. It does not implement file uploads, document evidence, AI recommendations, advanced analytics, graph generation, performance reviews, reports, subscriptions, or billing.

#### `POST /api/okrs`

```json
{
  "employeeId": "employee-profile-id",
  "title": "Improve customer response time",
  "description": "Reduce average response time from 3 days to 1 day.",
  "dueDate": "2026-09-30",
  "companyId": "company-id-for-super-admin-only"
}
```

Rules:

- `COMPANY_ADMIN` and `HR_ADMIN` can assign OKRs to active employees in their company.
- `MANAGER` can assign OKRs only to direct reports.
- `SUPER_ADMIN` assignment requires explicit `companyId` and an employee profile in that company because `assignedById` is required by the schema.
- `EMPLOYEE` cannot assign OKRs.
- `title` is required; `description` and `dueDate` are optional.
- Payloads with file/evidence fields are rejected.
- OKRs start as `ASSIGNED`.

#### `GET /api/okrs/me`

Returns the authenticated employee's own OKRs. Supports optional `status`.

#### `GET /api/okrs/team`

Returns direct-report OKRs for managers only.

#### `GET /api/admin/okrs`

Returns scoped company OKRs for `COMPANY_ADMIN`, `HR_ADMIN`, and explicitly scoped `SUPER_ADMIN`. Supports:

- `companyId` for `SUPER_ADMIN` only.
- `employeeId`
- `status`
- `from`
- `to`

#### `GET /api/okrs/:okrId`

Allowed for the OKR owner, direct manager, company admin/HR, or scoped super-admin.

#### `PATCH /api/okrs/:okrId`

```json
{
  "title": "Updated title",
  "description": "Updated description",
  "dueDate": "2026-10-01"
}
```

Managers can update direct-report OKRs. Admins can update company OKRs. Employees cannot update metadata.

#### `PATCH /api/okrs/:okrId/status`

```json
{ "status": "IN_PROGRESS" }
```

Status must match `OKRStatus`: `DRAFT`, `ASSIGNED`, `IN_PROGRESS`, `SUBMITTED`, `APPROVED`, `REJECTED`, `ARCHIVED`.

#### `POST /api/okrs/:okrId/progress`

```json
{
  "progressPercent": 50,
  "note": "Completed first phase."
}
```

Creates an `OKRProgressUpdate`. Employees can update progress only for their own OKR. If status is `ASSIGNED` and progress is greater than `0`, CP11 moves the OKR to `IN_PROGRESS`.

#### `PATCH /api/okrs/:okrId/employee-approve`

```json
{
  "comment": "I confirm completion."
}
```

Creates or updates an `OKRApproval` for the OKR owner. Employee approval alone moves the OKR to `SUBMITTED` unless already `APPROVED`.

#### `PATCH /api/okrs/:okrId/manager-approve`

```json
{
  "comment": "Approved."
}
```

Managers can approve direct-report OKRs. `COMPANY_ADMIN` and `HR_ADMIN` can approve company OKRs. `SUPER_ADMIN` approval requires explicit scope and an employee profile in the target company. Once employee and manager/admin approvals both exist, CP11 moves the OKR to `APPROVED`.

Response example:

```json
{
  "data": {
    "okr": {
      "id": "okr-id",
      "employeeId": "employee-profile-id",
      "assignedById": "manager-employee-profile-id",
      "title": "Improve customer response time",
      "description": "Reduce average response time from 3 days to 1 day.",
      "status": "ASSIGNED",
      "dueDate": "2026-09-30T00:00:00.000Z",
      "progressUpdates": [],
      "approvals": []
    }
  }
}
```

CP11 error behavior:

- `401`: missing, malformed, invalid, expired, or revoked token.
- `403`: wrong role, missing required `SUPER_ADMIN` scope, company mismatch, missing employee profile for assignment/approval, inactive employee/company, direct-report mismatch, or self/manager approval misuse.
- `404`: employee or OKR not found inside the caller's allowed scope.
- `400`: invalid body, params, query, status, title, due date, progress percent, note/comment length, or file/evidence fields.

### Performance Reviews (CP12)
| Method | Path | Auth | Roles | Status |
| ------ | ---- | ---- | ----- | ------ |
| POST | `/api/admin/review-cycles` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP12 |
| GET | `/api/admin/review-cycles` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP12 |
| GET | `/api/admin/review-cycles/:reviewCycleId` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP12 |
| PATCH | `/api/admin/review-cycles/:reviewCycleId` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP12 |
| PATCH | `/api/admin/review-cycles/:reviewCycleId/status` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP12 |
| POST | `/api/reviews/:employeeId/manager-review` | Bearer token | MANAGER direct reports; COMPANY_ADMIN/HR_ADMIN company; SUPER_ADMIN with employee profile + `companyId` | Implemented CP12 |
| GET | `/api/reviews/me` | Bearer token | Authenticated users with own employee profile | Implemented CP12 |
| GET | `/api/reviews/team` | Bearer token | MANAGER direct reports only | Implemented CP12 |
| GET | `/api/admin/reviews` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP12 |
| GET | `/api/reviews/:reviewId` | Bearer token | Own, direct-report, company admin/HR, or scoped super-admin | Implemented CP12 |
| PATCH | `/api/reviews/:reviewId` | Bearer token | COMPANY_ADMIN, HR_ADMIN, direct manager; SUPER_ADMIN with `companyId` | Implemented CP12 |
| PATCH | `/api/reviews/:reviewId/status` | Bearer token | COMPANY_ADMIN, HR_ADMIN, direct manager; SUPER_ADMIN with `companyId` | Implemented CP12 |

CP12 implements simple manager/admin-driven performance reviews only. It does not implement reports, dashboards, graph generation, advanced analytics, AI scoring, AI recommendations, payroll, subscriptions, billing, notifications, external document uploads, calibration workflows, or 360-degree reviews.

#### `POST /api/admin/review-cycles`

```json
{
  "name": "Q3 2026 Review",
  "startDate": "2026-07-01",
  "endDate": "2026-09-30",
  "companyId": "company-id-for-super-admin-only"
}
```

Creates a company-scoped review cycle with status `DRAFT`. `endDate` must be on or after `startDate`. Duplicate cycle names inside one company are rejected.

#### `GET /api/admin/review-cycles`

Lists company-scoped review cycles. `SUPER_ADMIN` must provide `companyId`.

#### `GET /api/admin/review-cycles/:reviewCycleId`

Returns one cycle inside the caller's resolved company scope.

#### `PATCH /api/admin/review-cycles/:reviewCycleId`

```json
{
  "name": "Updated Q3 2026 Review",
  "startDate": "2026-07-01",
  "endDate": "2026-09-30"
}
```

All fields are optional, but at least one field is required. Updated date ranges must remain valid.

#### `PATCH /api/admin/review-cycles/:reviewCycleId/status`

```json
{ "status": "ACTIVE" }
```

Status must match `ReviewCycleStatus`: `DRAFT`, `ACTIVE`, `CLOSED`, `ARCHIVED`. Closing/deactivating a cycle does not delete existing reviews.

#### `POST /api/reviews/:employeeId/manager-review`

```json
{
  "reviewCycleId": "review-cycle-id",
  "summary": "Employee met key goals and improved attendance consistency.",
  "rating": 4
}
```

Creates a `PerformanceReview` with status `SUBMITTED` and `submittedAt` set. `summary` is required. `rating` is optional and must be between `1` and `5` when provided. The review cycle must be `ACTIVE`. One review per employee per cycle is allowed.

Rules:

- `MANAGER` can submit only for direct reports.
- `COMPANY_ADMIN` and `HR_ADMIN` can submit for company employees.
- `SUPER_ADMIN` submission requires explicit `companyId` and an employee profile in that company because `managerId` is required by the schema.
- `EMPLOYEE` cannot submit performance reviews.
- The target employee and review cycle must belong to the resolved company.

#### `GET /api/reviews/me`

Returns the authenticated employee profile's own performance reviews.

#### `GET /api/reviews/team`

Returns direct-report reviews for managers only.

#### `GET /api/admin/reviews`

Returns company-scoped reviews for `COMPANY_ADMIN`, `HR_ADMIN`, and explicitly scoped `SUPER_ADMIN`. Supports:

- `companyId` for `SUPER_ADMIN` only.
- `employeeId`
- `reviewCycleId`
- `status`
- `from`
- `to`

`from` and `to` filter by review `createdAt`.

#### `GET /api/reviews/:reviewId`

Allowed for the reviewed employee, direct manager, company admin/HR, or scoped super-admin.

#### `PATCH /api/reviews/:reviewId`

```json
{
  "summary": "Updated summary",
  "rating": 5
}
```

Managers can update direct-report reviews while they are editable. Admins can update company reviews. Employees cannot update reviews. CP12 does not allow changing `employeeId` or `reviewCycleId`. Reviews with status `ACKNOWLEDGED` or `ARCHIVED` are not editable.

#### `PATCH /api/reviews/:reviewId/status`

```json
{ "status": "SUBMITTED" }
```

Status must match `PerformanceReviewStatus`: `DRAFT`, `SUBMITTED`, `ACKNOWLEDGED`, `ARCHIVED`. When status becomes `SUBMITTED`, `ACKNOWLEDGED`, or `ARCHIVED`, `submittedAt` is set if it was not already set.

Response example:

```json
{
  "data": {
    "review": {
      "id": "performance-review-id",
      "companyId": "company-id",
      "reviewCycleId": "review-cycle-id",
      "employeeId": "employee-profile-id",
      "managerId": "manager-employee-profile-id",
      "summary": "Employee met key goals and improved attendance consistency.",
      "rating": 4,
      "status": "SUBMITTED",
      "submittedAt": "2026-06-03T08:00:00.000Z",
      "createdAt": "2026-06-03T08:00:00.000Z",
      "updatedAt": "2026-06-03T08:00:00.000Z"
    }
  }
}
```

CP12 error behavior:

- `401`: missing, malformed, invalid, expired, or revoked token.
- `403`: wrong role, missing required `SUPER_ADMIN` scope, company mismatch, missing reviewer employee profile, inactive employee/company, or manager access outside direct reports.
- `404`: company, employee, review cycle, or performance review not found inside the caller's allowed scope.
- `409`: duplicate review cycle name or duplicate employee + cycle performance review.
- `400`: invalid body, params, query, date range, status enum, inactive review cycle, missing summary, oversized summary, invalid rating, or non-editable review state.

### Notifications (CP13)
| Method | Path | Auth | Roles | Status |
| ------ | ---- | ---- | ----- | ------ |
| GET | `/api/notifications/me` | Bearer token | Authenticated user self-only | Implemented CP13 |
| GET | `/api/notifications/me/unread-count` | Bearer token | Authenticated user self-only | Implemented CP13 |
| PATCH | `/api/notifications/:notificationId/read` | Bearer token | Notification owner only | Implemented CP13 |
| PATCH | `/api/notifications/read-all` | Bearer token | Authenticated user self-only | Implemented CP13 |
| POST | `/api/admin/notifications/broadcast` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP13 |

CP13 implements in-app notifications only. It does not implement production SMS, email, push notification delivery, Twilio, mobile push tokens, WebSockets, real-time delivery, reports, dashboards, advanced analytics, AI recommendations, subscriptions, billing, or a background cron scheduler.

#### `GET /api/notifications/me`

Returns the current authenticated user's notifications only. Supports optional filters:

- `status`: `UNREAD`, `READ`, `ARCHIVED`
- `type`: `SYSTEM`, `ATTENDANCE`, `LEAVE`, `OKR`, `PERFORMANCE`, `SUBSCRIPTION`, `SECURITY`
- `from`
- `to`

#### `GET /api/notifications/me/unread-count`

Returns:

```json
{
  "data": {
    "unreadCount": 3
  }
}
```

#### `PATCH /api/notifications/:notificationId/read`

Marks the caller's own notification as `READ` and sets `readAt`. If the notification is already read, CP13 returns it safely without error. Notifications owned by another user are not returned.

#### `PATCH /api/notifications/read-all`

Marks all `UNREAD` notifications for the current authenticated user as `READ` and returns the number updated.

```json
{
  "data": {
    "updatedCount": 2
  }
}
```

#### `POST /api/admin/notifications/broadcast`

```json
{
  "title": "Reminder",
  "message": "Please update your OKRs.",
  "type": "OKR",
  "targetRole": "EMPLOYEE",
  "employeeIds": ["employee-profile-id"],
  "companyId": "company-id-for-super-admin-only"
}
```

Rules:

- `COMPANY_ADMIN` and `HR_ADMIN` can broadcast inside their own company.
- `SUPER_ADMIN` broadcast requires explicit `companyId`.
- `MANAGER` and `EMPLOYEE` cannot broadcast.
- `employeeIds`, when provided, must all belong to active employees in the resolved company.
- `targetRole`, when provided, filters recipients by `RoleName`.
- Broadcast recipients are active employee profiles with active users in an active company.
- CP13 creates `Notification` rows only; it does not send SMS/email/push.
- Full notification messages are not written to audit metadata.

Response example:

```json
{
  "data": {
    "companyId": "company-id",
    "type": "OKR",
    "targetRole": "EMPLOYEE",
    "notificationCount": 2,
    "recipients": [
      {
        "employeeId": "employee-profile-id",
        "userId": "user-id",
        "roles": ["EMPLOYEE"]
      }
    ],
    "notifications": [
      {
        "id": "notification-id",
        "companyId": "company-id",
        "userId": "user-id",
        "type": "OKR",
        "status": "UNREAD",
        "title": "Reminder",
        "message": "Please update your OKRs.",
        "metadata": {
          "broadcast": true,
          "targetRole": "EMPLOYEE"
        },
        "createdAt": "2026-06-03T08:00:00.000Z",
        "readAt": null
      }
    ]
  }
}
```

CP13 error behavior:

- `401`: missing, malformed, invalid, expired, or revoked token.
- `403`: wrong role, missing required `SUPER_ADMIN` scope, or company mismatch.
- `404`: notification, company, or employee target not found inside the caller's allowed scope.
- `400`: invalid body, params, query, notification status, notification type, role, date range, title, or message.

### Reports & Dashboards (CP14)
| Method | Path | Auth | Roles | Status |
| ------ | ---- | ---- | ----- | ------ |
| GET | `/api/admin/reports/dashboard` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP14 |
| GET | `/api/admin/reports/attendance` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP14 |
| GET | `/api/admin/reports/leave` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP14 |
| GET | `/api/admin/reports/okrs` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP14 |
| GET | `/api/admin/reports/performance` | Bearer token | COMPANY_ADMIN, HR_ADMIN; SUPER_ADMIN with `companyId` | Implemented CP14 |
| GET | `/api/reports/team/dashboard` | Bearer token | MANAGER direct reports only | Implemented CP14 |
| GET | `/api/reports/team/attendance` | Bearer token | MANAGER direct reports only | Implemented CP14 |
| GET | `/api/reports/team/leave` | Bearer token | MANAGER direct reports only | Implemented CP14 |
| GET | `/api/reports/team/okrs` | Bearer token | MANAGER direct reports only | Implemented CP14 |
| GET | `/api/reports/team/performance` | Bearer token | MANAGER direct reports only | Implemented CP14 |
| GET | `/api/reports/me/dashboard` | Bearer token | Authenticated user with own employee profile | Implemented CP14 |
| GET | `/api/super-admin/reports/dashboard` | Bearer token | SUPER_ADMIN | Implemented CP14 |
| GET | `/api/super-admin/reports/companies` | Bearer token | SUPER_ADMIN | Implemented CP14 |

CP14 implements read-only summary data only. It does not implement advanced analytics, AI recommendations, predictive analytics, backend chart rendering, PDF/CSV export, payroll reporting, billing reporting, WebSocket live dashboards, background jobs, data warehouse logic, or custom report builders.

#### Admin Reports

Admin endpoints are company scoped. `COMPANY_ADMIN` and `HR_ADMIN` use their authenticated company. `SUPER_ADMIN` must provide explicit `companyId`.

- `GET /api/admin/reports/dashboard`
- `GET /api/admin/reports/attendance`
- `GET /api/admin/reports/leave`
- `GET /api/admin/reports/okrs`
- `GET /api/admin/reports/performance`

Supported filters:

- Attendance: `from`, `to`, `employeeId`, `departmentId`
- Leave: `year`, `employeeId`, `departmentId`, `status`
- OKRs: `status`, `employeeId`, `departmentId`
- Performance: `reviewCycleId`, `status`, `employeeId`, `departmentId`

#### Manager Reports

Manager endpoints use `EmployeeProfile.managerId` and return direct-report summaries only.

- `GET /api/reports/team/dashboard`
- `GET /api/reports/team/attendance`
- `GET /api/reports/team/leave`
- `GET /api/reports/team/okrs`
- `GET /api/reports/team/performance`

#### Employee Dashboard

`GET /api/reports/me/dashboard` returns only the authenticated employee profile's own dashboard summary.

#### Super Admin Reports

- `GET /api/super-admin/reports/dashboard`
- `GET /api/super-admin/reports/companies`

Super-admin reports return platform/company rollups only and do not include employee-level sensitive details.

Response examples:

```json
{
  "data": {
    "dashboard": {
      "companyId": "company-id",
      "employees": { "total": 25, "active": 23, "inactive": 2 },
      "departments": { "total": 4 },
      "attendance": { "todayClockIns": 18, "openSessions": 12 },
      "leave": { "pendingRequests": 3 },
      "okrs": { "active": 14 },
      "performance": { "pendingReviews": 5 },
      "notifications": { "unreadCount": 2 }
    }
  }
}
```

```json
{
  "data": {
    "report": {
      "totalSessions": 42,
      "openSessions": 5,
      "closedSessions": 37,
      "clockInsByDay": [{ "date": "2026-06-03", "count": 18 }]
    }
  }
}
```

CP14 error behavior:

- `401`: missing, malformed, invalid, expired, or revoked token.
- `403`: wrong role, missing required `SUPER_ADMIN` scope, company mismatch, missing manager/employee profile, or manager access outside direct reports.
- `404`: company, employee, department, or review cycle not found inside the caller's allowed scope.
- `400`: invalid query, date range, year, or status enum.

CP14 privacy behavior:

- Report responses must not include raw GPS coordinates, raw face/biometric data, leave reasons, leave review comments, performance review summaries, OKR notes/comments, or notification message bodies unless an endpoint explicitly returns the authenticated user's own notification records.

### Subscriptions & Billing (CP15)
| Method | Path | Auth | Roles | Status |
| ------ | ---- | ---- | ----- | ------ |
| POST | `/api/super-admin/plans` | Bearer token | SUPER_ADMIN | Implemented CP15 |
| GET | `/api/super-admin/plans` | Bearer token | SUPER_ADMIN | Implemented CP15 |
| GET | `/api/super-admin/plans/:planId` | Bearer token | SUPER_ADMIN | Implemented CP15 |
| PATCH | `/api/super-admin/plans/:planId` | Bearer token | SUPER_ADMIN | Implemented CP15 |
| PATCH | `/api/super-admin/plans/:planId/status` | Bearer token | SUPER_ADMIN | Implemented CP15 |
| POST | `/api/super-admin/companies/:companyId/subscription` | Bearer token | SUPER_ADMIN | Implemented CP15 |
| GET | `/api/super-admin/subscriptions` | Bearer token | SUPER_ADMIN | Implemented CP15 |
| GET | `/api/super-admin/companies/:companyId/subscription` | Bearer token | SUPER_ADMIN | Implemented CP15 |
| PATCH | `/api/super-admin/subscriptions/:subscriptionId/status` | Bearer token | SUPER_ADMIN | Implemented CP15 |
| POST | `/api/super-admin/payment-records` | Bearer token | SUPER_ADMIN | Implemented CP15 |
| GET | `/api/super-admin/payment-records` | Bearer token | SUPER_ADMIN | Implemented CP15 |
| GET | `/api/super-admin/companies/:companyId/payment-records` | Bearer token | SUPER_ADMIN | Implemented CP15 |
| GET | `/api/admin/subscription` | Bearer token | COMPANY_ADMIN, HR_ADMIN | Implemented CP15 |
| GET | `/api/admin/payment-records` | Bearer token | COMPANY_ADMIN, HR_ADMIN | Implemented CP15 |

CP15 implements the internal subscription and billing foundation only. It does not implement live Stripe charging, payment collection, webhooks, invoice PDFs, tax calculation, refunds, proration, coupons, automated billing jobs, or accounting integrations.

Plan types use `SubscriptionPlanType`: `BASIC`, `PREMIUM`. Subscription statuses use `SubscriptionStatus`: `TRIALING`, `ACTIVE`, `PAST_DUE`, `CANCELLED`, `EXPIRED`. Payment statuses use `PaymentStatus`: `PENDING`, `PAID`, `FAILED`, `REFUNDED`, `CANCELLED`.

#### Plan Management

`POST /api/super-admin/plans`

```json
{
  "name": "Basic",
  "type": "BASIC",
  "pricePerEmployee": 120,
  "currency": "ETB"
}
```

`GET /api/super-admin/plans` supports `isActive` and `type` filters. `PATCH /api/super-admin/plans/:planId` can update `name`, `type`, `pricePerEmployee`, `currency`, and `isActive`. `PATCH /api/super-admin/plans/:planId/status` changes only `isActive`; historical subscriptions remain linked.

#### Company Subscriptions

`POST /api/super-admin/companies/:companyId/subscription`

```json
{
  "planId": "plan-id",
  "startsAt": "2026-06-01",
  "endsAt": null,
  "status": "ACTIVE"
}
```

Rules: company must exist, plan must exist and be active, `endsAt` cannot be before `startsAt`, and creating a second `ACTIVE` subscription for the same company returns `ACTIVE_SUBSCRIPTION_EXISTS`.

`GET /api/super-admin/subscriptions` supports `companyId`, `status`, and `planId`. `GET /api/super-admin/companies/:companyId/subscription` returns the active subscription if present, otherwise the latest subscription, or `null`. `PATCH /api/super-admin/subscriptions/:subscriptionId/status` updates status and optional `endsAt`.

#### Payment Records

`POST /api/super-admin/payment-records`

```json
{
  "companyId": "company-id",
  "subscriptionId": "subscription-id",
  "amount": 5000,
  "currency": "ETB",
  "status": "PAID",
  "provider": "manual",
  "providerReference": "receipt-001",
  "paidAt": "2026-06-01T12:00:00.000Z"
}
```

Payment records are manual CP15 records only. `subscriptionId` is optional, but if provided it must belong to the same company. `GET /api/super-admin/payment-records` supports `companyId`, `status`, `provider`, `from`, and `to` filters. Date filters apply to `paidAt`. `GET /api/super-admin/companies/:companyId/payment-records` returns payment records for one company.

#### Company Admin Billing Self-View

`GET /api/admin/subscription` returns the caller's company active/latest subscription and plan summary. `GET /api/admin/payment-records` returns the caller's company payment records with provider references omitted. `MANAGER` and `EMPLOYEE` are denied.

Response examples:

```json
{
  "data": {
    "plan": {
      "id": "plan-id",
      "name": "Basic",
      "type": "BASIC",
      "pricePerEmployee": 120,
      "currency": "ETB",
      "isActive": true
    }
  }
}
```

```json
{
  "data": {
    "subscription": {
      "id": "subscription-id",
      "companyId": "company-id",
      "planId": "plan-id",
      "status": "ACTIVE",
      "startsAt": "2026-06-01T00:00:00.000Z",
      "endsAt": null,
      "plan": {
        "id": "plan-id",
        "name": "Basic",
        "type": "BASIC",
        "pricePerEmployee": 120,
        "currency": "ETB",
        "isActive": true
      }
    }
  }
}
```

```json
{
  "data": {
    "paymentRecord": {
      "id": "payment-id",
      "companyId": "company-id",
      "subscriptionId": "subscription-id",
      "amount": 5000,
      "currency": "ETB",
      "status": "PAID",
      "provider": "manual",
      "providerReference": "receipt-001",
      "paidAt": "2026-06-01T12:00:00.000Z"
    }
  }
}
```

CP15 error behavior:

- `401`: missing, malformed, invalid, expired, or revoked token.
- `403`: wrong role or non-super-admin company-scope mismatch.
- `404`: company, plan, subscription, or payment-scoped company not found.
- `400`: invalid body/query/params, invalid enum, invalid date range, inactive plan assignment, mismatched subscription/company, or `ACTIVE_SUBSCRIPTION_EXISTS`.

CP15 privacy behavior:

- Do not store card numbers, bank accounts, Stripe secrets, or payment credentials.
- Audit metadata excludes full provider references and sensitive payment data.
- Company admin payment self-view omits `providerReference`.

### Admin / Super Admin (CP16)

CP16 adds hardening and tests rather than new product endpoints. Existing `/api/admin/*`, `/api/super-admin/*`, and internal `/api/system/*` behavior is locked down as follows:

- Every `/api/admin/*` route requires authentication and documented admin roles.
- Every `/api/super-admin/*` route requires authentication and `SUPER_ADMIN`.
- `COMPANY_ADMIN` and `HR_ADMIN` cannot access `/api/super-admin/*`.
- `MANAGER` and `EMPLOYEE` cannot access admin/super-admin surfaces unless a route explicitly documents self/team scope outside `/api/admin/*`.
- Non-super-admin users cannot override `companyId` through params, query, or body.
- `SUPER_ADMIN` company-scoped operations require explicit `companyId` where documented.
- Normal company-admin employee creation cannot assign `SUPER_ADMIN`; super-admin creation remains seed/manual-only.
- Internal `/api/system/*` verification routes are disabled in production.
- Sensitive response rules from CP5-CP15 remain binding.

### Audit Logs, Privacy, and Security Testing (CP17)

CP17 adds hardening and tests rather than product endpoints.

- No audit-log read endpoint is exposed in CP17.
- Sensitive state-changing actions continue to write `AuditLog` records through module services.
- Audit metadata is sanitized before persistence by `src/lib/audit.ts`.
- Reports remain summary-only and must not include raw GPS coordinates, biometric/provider data, leave reasons, review summaries/comments, OKR notes/comments, payment secrets, or unrelated user details.
- `/api/system/*` remains disabled in production; `/health` and `/ready` remain public.
- Audit-log viewing remains unavailable until a future checkpoint explicitly scopes, redacts, documents, and tests it.

## CP19 Frontend Handoff Verification

- Implemented endpoints above are the only backend endpoints Lovable may call.
- No unimplemented endpoint is described as complete.
- Auth and role requirements are documented in each checkpoint section and summarized in `ROLE_PERMISSION_MATRIX.md`.
- Request and response examples use the stable JSON envelopes defined in this contract.
- Error examples use the standard error envelope with request IDs.
- `GET /health` and `GET /ready` are public deploy checks.
- `/api/system/*` is internal verification only and returns `404` in production.
- CORS requires explicit frontend origins in staging/production.
- The verified staging URL is `https://workforce-management-production.up.railway.app`.

No breaking API changes should be introduced after CP19 without updating `API_CONTRACT.md`, `SCREEN_API_MATRIX.md`, `FRONTEND_ROUTE_MAP.md`, and regression tests.
