# BACKEND ENGINEERING BIBLE

The authoritative engineering standard for the AI-powered workforce management backend. All checkpoints and modules must comply.

## 1. Stack

- Node.js + Express + TypeScript
- PostgreSQL + Prisma ORM
- Jest + Supertest for testing
- JWT authentication, RBAC, company-level multi-tenancy
- REST APIs with JSON responses

## 2. Architecture

Strict layered flow for every module:

```
Route -> Controller -> Service -> Repository -> Database
```

| Layer | Responsibility | Must NOT |
| ----- | -------------- | -------- |
| Route | Wire HTTP paths, attach middleware | Contain business logic |
| Controller | Parse input, call service, shape HTTP response | Access DB or hold business rules |
| Service | Business logic, orchestration, authorization decisions | Access Prisma directly |
| Repository | All Prisma/Postgres access | Contain business rules |
| Database | Persistence | -- |

## 3. Module File Set

Every module under `src/modules/<name>/` contains:

- `<name>.routes.ts`
- `<name>.controller.ts`
- `<name>.service.ts`
- `<name>.repository.ts`
- `<name>.validation.ts`
- `<name>.test.ts`

## 4. Project Structure

```
workforce-backend/
  prisma/            schema.prisma, migrations/, seed.ts
  src/
    app.ts, server.ts
    config/          env, cors, security, storage, ai
    lib/             prisma, logger, errors, jwt, password, geo, faceMatch, sms, email, audit
    middleware/      auth, role, companyScope, rateLimit, validation, upload, requestId, error
    routes/          index.ts
    modules/         auth, companies, employees, departments, geofences, face-verification,
                     attendance, shifts, leave, okrs, performance-reviews, notifications,
                     reports, subscriptions, admin, super-admin, audit-logs
  tests/             setup.ts, helpers/, factories/, security/
```

## 5. API Response Conventions

- Success: `{ "data": <payload>, "meta"?: <pagination/etc> }`
- Error: `{ "error": { "code": string, "message": string, "requestId": string, "details"?: any } }`
- HTTP status codes used correctly (200/201/204/400/401/403/404/409/422/429/500).
- Consistent, predictable shapes so the frontend connects cleanly.
- No breaking changes after `API_CONTRACT.md` is frozen.

## 6. Validation

- All input validated at the validation layer before reaching services.
- Reject unknown fields where appropriate; never trust client-supplied `companyId` or role.

## 7. Errors

- Centralized error types in `lib/errors.ts`.
- `error.middleware.ts` converts errors to the standard envelope.
- No stack traces or internal details leaked in production responses.

## 8. Security Baseline

- Authentication required on all routes except `GET /health`, `GET /ready`, and `POST /api/auth/login`.
- Deny-by-default authorization; least privilege.
- Company scoping derived from the authenticated token, never the request body.
- Admin/super-admin routes always require auth + explicit role checks.
- Strict CORS allowlist; security headers (helmet); rate limiting.
- Secrets via environment/secret store; never committed.

### CP4 Authorization Foundation

- Protected routes start with `requireAuthentication`.
- Role-restricted routes add `requireRole`, `requireAnyRole`, or one of the named role middleware helpers.
- Company-scoped routes add `requireCompanyScope` or `requireRouteCompanyScope` and consume `req.companyScope`.
- Future business services must pass the resolved company scope into repository calls and filter tenant-owned database queries by that scope.
- Client-provided `companyId`, role, permission, or owner fields are hints to validate, never authority.

### CP5 Organization Foundation

- Company management routes live under `/api/super-admin/companies` and require `SUPER_ADMIN`.
- Department, designation, and employee admin routes live under `/api/admin/*` and require `COMPANY_ADMIN`, `HR_ADMIN`, or explicitly scoped `SUPER_ADMIN`.
- Employee self-profile access lives under `/api/employees/me`.
- Employee creation creates `User`, `EmployeeProfile`, and `UserRole` records together. `temporaryPassword` is hashed immediately and never returned.
- Organization services must write audit logs for create/update/status/manager-change actions.

### CP6 Geofence Foundation

- Geofence setup routes live under `/api/admin/geofences` and require `COMPANY_ADMIN`, `HR_ADMIN`, or explicitly scoped `SUPER_ADMIN`.
- Location validation lives under `/api/geofences/validate-location` and requires authentication.
- Geofence validation uses circular latitude/longitude/radius checks only.
- CP6 validation does not create attendance or location-ping records; CP7 attendance code must decide how to consume validation results.
- Raw GPS coordinates must not be logged or written to audit metadata.

### CP7 Attendance Foundation

- Attendance self-service routes live under `/api/attendance`.
- Admin attendance listing lives under `/api/admin/attendance`.
- Clock-in/out must resolve the caller's active employee profile and company before writing records.
- Clock-in/out require active geofence validation and create `AttendanceEvent` operational records.
- Clock-in requires a CP8 face verification reference and sets `clockInFaceVerified` to `true` only after consuming it.
- CP7 does not implement continuous GPS tracking, manager team attendance, or clock-in/out for another employee.

### CP8 Face Verification Foundation

- Face enrollment/status routes live under `/api/admin/employees/:employeeId/*` and require `COMPANY_ADMIN`, `HR_ADMIN`, or explicitly scoped `SUPER_ADMIN`.
- Self-service verification lives under `/api/face/verify`.
- Provider logic must stay behind the face adapter layer in `src/lib/faceMatch.ts` and `src/lib/face/*`.
- Store only provider references and metadata on `FaceEnrollment`; never store raw face images or raw biometric vectors.
- Face enrollment create/update/status actions are audited without provider template references or raw face payloads.

### CP9 Shift Foundation

- Admin shift routes live under `/api/admin/shifts` and require `COMPANY_ADMIN`, `HR_ADMIN`, or explicitly scoped `SUPER_ADMIN`.
- Admin shift assignment routes live under `/api/admin/shifts/:shiftId/*` and `/api/admin/shift-assignments/:assignmentId`.
- Employee self-view lives under `/api/shifts/me` and returns only the caller's own current/future assignments.
- Shifts use simple `HH:mm` strings. Assignments use date-only `startsOn` and optional `endsOn`.
- Shift services must verify both the shift and employee are inside the resolved company before assignment.
- CP9 does not enforce attendance timing, payroll, overtime, recurring schedules, or holiday calendars.
- Shift create/update/status and assignment create/update/remove actions are audited.

### CP10 Leave Foundation

- Admin leave type routes live under `/api/admin/leave-types`.
- Admin entitlement routes live under `/api/admin/leave-entitlements`.
- Employee self-service leave routes live under `/api/leave/request` and `/api/leave/me`.
- Manager team leave review lives under `/api/leave/team` and must use `EmployeeProfile.managerId` direct-report scope.
- Admin leave request listing lives under `/api/admin/leave-requests`.
- Approve/reject routes live under `/api/leave/:leaveRequestId/approve` and `/api/leave/:leaveRequestId/reject`.
- CP10 uses entitlement-required (`NO_ENTITLEMENT`) policy and full-day inclusive date counting.
- Approval increments `LeaveEntitlement.usedDays`; rejection does not.
- Leave reasons and review comments are HR-sensitive and must not be logged or written to audit metadata.
- CP10 does not implement payroll, partial-day leave, holiday calendars, accruals, carryover, OKRs, reviews, reports, subscriptions, or billing.

### CP11 OKR Foundation

- OKR routes live under `/api/okrs`; admin company listing lives under `/api/admin/okrs`.
- CP11 OKRs are text-only. Do not add file uploads, document evidence, AI recommendations, reports, charts, analytics, or performance-review coupling in this checkpoint.
- OKR assignment, update, and status changes are available to `COMPANY_ADMIN`, `HR_ADMIN`, direct-report `MANAGER`, and explicitly scoped `SUPER_ADMIN` where the actor has an employee profile in the selected company.
- Employee self-view and progress updates must resolve the caller's active employee profile and only operate on the caller's own OKRs.
- Manager team views and manager approval must use `EmployeeProfile.managerId` direct-report scope.
- Admin OKR views must filter by the resolved company scope. `SUPER_ADMIN` access must use explicit company context.
- Employee approval and manager/admin approval create `OKRApproval` records. When employee approval exists, the OKR becomes `SUBMITTED`; when both employee and manager/admin approvals are approved, it becomes `APPROVED`.
- OKR create/update/status/progress/approval actions are audited with sparse metadata only. Titles, descriptions, progress notes, and approval comments must not be logged.

### CP12 Performance Review Foundation

- Review cycle admin routes live under `/api/admin/review-cycles` and require `COMPANY_ADMIN`, `HR_ADMIN`, or explicitly scoped `SUPER_ADMIN`.
- Performance review routes live under `/api/reviews`; admin company listing lives under `/api/admin/reviews`.
- CP12 reviews are simple manager/admin-written summaries with optional 1-5 rating.
- CP12 does not implement reports, dashboards, graphs, advanced analytics, AI scoring, AI recommendations, notifications, external document uploads, calibration workflows, 360-degree reviews, subscriptions, or billing.
- Review cycles are company scoped and use `ReviewCycleStatus`: `DRAFT`, `ACTIVE`, `CLOSED`, `ARCHIVED`.
- Manager review submission requires an `ACTIVE` review cycle and rejects duplicate `employeeId` + `reviewCycleId` reviews.
- `MANAGER` submission, update, and status changes must use `EmployeeProfile.managerId` direct-report scope.
- `COMPANY_ADMIN` and `HR_ADMIN` can submit/update/status company reviews when the reviewer has an employee profile in the company.
- `SUPER_ADMIN` review submission requires explicit company context and an employee profile in the selected company because `PerformanceReview.managerId` is required.
- Employee self-view resolves the caller's active employee profile and returns only the caller's own reviews.
- Performance review summaries are HR-sensitive and must not be logged or written to audit metadata.

### CP13 Notification Foundation

- User notification routes live under `/api/notifications` and require authentication.
- Admin broadcast routes live under `/api/admin/notifications` and require `COMPANY_ADMIN`, `HR_ADMIN`, or explicitly scoped `SUPER_ADMIN`.
- CP13 implements in-app notifications only. Do not add SMS, email, push providers, WebSockets, mobile push tokens, production delivery, reports, analytics, subscriptions, billing, or background cron scheduling in this checkpoint.
- User notification list, unread count, mark-read, and read-all flows are self-only and must filter by `Notification.userId`.
- Admin broadcast resolves company scope and sends only to active employee profiles with active users inside an active company.
- `SUPER_ADMIN` broadcast requires explicit company context.
- Notification helper functions may be called by future modules, but CP13 does not force CP10/CP11/CP12 flows to emit notifications.
- Notification broadcast actions are audited with sparse metadata only. Full titles and messages must not be logged.

### CP14 Reports and Dashboards Foundation

- Admin report routes live under `/api/admin/reports` and require `COMPANY_ADMIN`, `HR_ADMIN`, or explicitly scoped `SUPER_ADMIN`.
- Manager report routes live under `/api/reports/team` and require `MANAGER`.
- Employee self dashboard lives under `/api/reports/me/dashboard` and requires an active employee profile.
- Super-admin platform reports live under `/api/super-admin/reports` and require `SUPER_ADMIN`.
- CP14 reports are read-only summary JSON. Do not add advanced analytics, AI recommendations, predictive analytics, backend graph rendering, exports, payroll reporting, billing reporting, WebSockets, background jobs, data warehouse logic, or custom report builders.
- Manager reports must use `EmployeeProfile.managerId` direct-report scope.
- Admin report filters must resolve inside the scoped company.
- Report rollups must not include raw GPS coordinates, face/biometric data, leave reasons, review comments, performance review summaries, OKR notes/comments, or unrelated employee/user details.
- CP14 does not audit every report view by default.

### CP15 Subscription and Billing Foundation

- Super-admin plan routes live under `/api/super-admin/plans` and require `SUPER_ADMIN`.
- Super-admin subscription routes live under `/api/super-admin/companies/:companyId/subscription` and `/api/super-admin/subscriptions` and require `SUPER_ADMIN`.
- Super-admin payment record routes live under `/api/super-admin/payment-records` and `/api/super-admin/companies/:companyId/payment-records` and require `SUPER_ADMIN`.
- Company-admin billing self-view lives under `/api/admin/subscription` and `/api/admin/payment-records` and requires `COMPANY_ADMIN` or `HR_ADMIN`.
- CP15 uses existing `SubscriptionPlan`, `CompanySubscription`, and `PaymentRecord` models. Do not add a migration unless a later checkpoint explicitly changes billing data shape.
- CP15 is manual/internal billing only. Do not add live Stripe charging, webhooks, invoice PDFs, tax, refunds, proration, coupons, automated billing jobs, accounting integrations, or card-entry flows.
- Company subscriptions must reject creation of a second `ACTIVE` subscription for the same company.
- Payment records must not store card numbers, bank accounts, payment credentials, or provider secrets.
- Audit payment metadata must not include full provider references or sensitive payment data.
- Company-admin payment responses must omit `providerReference`.

### CP16 Admin and Super Admin Hardening

- CP16 is a hardening checkpoint. Do not add new business features, onboarding flows, analytics, frontend code, payment providers, or deployment automation.
- Every `/api/admin/*` route must require authentication and the documented admin role boundary.
- Every `/api/super-admin/*` route must require authentication and `SUPER_ADMIN`.
- Non-super-admin users must not override `companyId` through params, query, or body.
- `SUPER_ADMIN` company-scoped operations must use explicit company context where documented.
- Normal company-admin employee creation must not assign `SUPER_ADMIN`; super-admin creation remains seed/manual-only.
- Manager direct-report access must remain tied to `EmployeeProfile.managerId`.
- Employee self-access must remain tied to the authenticated user's own employee profile.
- Internal `/api/system/*` verification routes must return `404` in production and must not be used as product endpoints.
- Sensitive responses and audit metadata must follow `ADMIN_SUPER_ADMIN_HARDENING.md`.

### CP17 Audit Logs, Privacy, and Security Testing

- CP17 is a hardening/testing checkpoint. Do not add business modules, public audit-log readers, deployment automation, frontend code, live payment processing, analytics, or AI recommendations.
- Sensitive state-changing service operations must write audit logs with sparse metadata only.
- `AttendanceEvent` remains the operational record for clock-in/out; do not add per-clock audit logs unless a future checkpoint explicitly changes that policy.
- All audit metadata must flow through `recordAuditLog`; do not write directly to `AuditLog` from services or repositories.
- `recordAuditLog` sanitizes metadata before persistence. Do not rely on frontend filtering or caller discipline for sensitive audit metadata safety.
- Audit metadata may include IDs, statuses, changed field names, dates, counts, role names assigned during protected employee creation, and non-sensitive configuration values.
- Audit metadata must not include credentials, JWTs, biometric payloads, provider subject/template references, raw GPS coordinate keys, leave reasons/comments, OKR descriptions/notes/comments, performance review summaries/comments, notification message bodies, payment provider references, card/bank data, or unrelated profile data.
- Logger redaction is case-insensitive for CP17-sensitive keys. Do not log request bodies for sensitive routes.
- Reports must remain summary-only and must not expose raw GPS coordinates, biometric/provider data, leave reasons, review summaries/comments, OKR notes/comments, payment secrets, or unrelated user details.
- Cross-company isolation, direct-report boundaries, employee self-scope, admin role boundaries, super-admin boundaries, and production `/api/system/*` behavior must remain covered by tests.
- CP17 intentionally does not expose audit-log read endpoints. Any future audit-log reader must be scoped, sanitized, documented, and heavily tested before exposure.

### CP18 Production Readiness and Deployment

- CP18 is a deployment-preparation checkpoint. Do not add product features, frontend code, live payment processing, webhooks, AI recommendations, advanced analytics, or mobile app code.
- Staging/production must require `DATABASE_URL`, `JWT_SECRET`, `JWT_REFRESH_SECRET`, and explicit CORS origin configuration.
- `JWT_ACCESS_SECRET` may override `JWT_SECRET` for access-token signing when present.
- CORS must be an explicit allowlist. Wildcard origins are not allowed with credentials.
- `GET /health` remains public and lightweight.
- `GET /ready` remains public and checks database connectivity when `DATABASE_URL` is configured.
- `/api/system/*` must return `404` in production.
- Deployment scripts must include build, start, typecheck, test, Prisma validate, Prisma generate, migration deploy, and seed commands.
- Seed is local/development-only unless explicitly approved for a controlled non-production environment.
- Production migrations require review, backup planning, and rollback planning.
- The frontend handoff must map screens to real endpoints only and must not authorize Lovable to invent endpoints or workflows.
- CP18 does not freeze the final Lovable handoff until a staging URL and staging role accounts exist; CP19 records those final deployment-specific values.

## 9. Privacy and Logging

- Never log passwords, password hashes, JWTs, refresh tokens, face/biometric data, or raw GPS history.
- Treat attendance, geofence, GPS, and facial data as sensitive.
- Use audit logs for sensitive actions.
- See `PRIVACY_AND_LOGGING_RULES.md`.

## 10. Testing Standard

- Each checkpoint is independently testable.
- Each checkpoint includes regression testing of prior checkpoints.
- Unit tests for services; integration/HTTP tests via Supertest for routes.
- Security tests live in focused integration/unit suites such as `tests/integration/security-audit.test.ts`, module integration suites, and logger/error unit tests.
- No checkpoint passes with failing or skipped required tests.

## 11. Checkpoint Discipline

- Do not implement business features before governance and foundation are complete.
- Every checkpoint updates `CHECKPOINT_LOG.md` before moving forward.
- Statuses: `NOT_STARTED`, `IN_PROGRESS`, `BLOCKED`, `FAILED`, `PASSED`.

## 12. Documentation Discipline

- Documentation updates are part of every checkpoint's definition of done.
- `API_CONTRACT.md` and `ROLE_PERMISSION_MATRIX.md` are the binding contracts for the frontend.
