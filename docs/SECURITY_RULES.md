# SECURITY RULES

Binding security baseline for the backend. Enforced and tested progressively; consolidated security pass at Checkpoint 17.

## Authentication

- JWT-based authentication. CP3 issues short-lived access tokens; refresh-token rotation is deferred until explicitly implemented.
- Passwords hashed with bcryptjs. Never stored or logged in plaintext.
- Public routes only: `GET /health`, `GET /ready`, and `POST /api/auth/login`. All others require a valid token unless documented otherwise.
- `GET /health` is lightweight and public; `GET /ready` is public and checks database connectivity when `DATABASE_URL` is configured.
- No employee self-registration. Accounts created by HR/Admin or Company Admin.
- CP5 workforce account creation is admin-controlled through `/api/admin/employees`. The development flow requires `temporaryPassword`, hashes it immediately, and never returns or logs it.
- Generic authentication error messages (no user-enumeration).
- Brute-force protection via the global rate limiter, which applies to login and all other routes.
- Logout revokes the current `DeviceSession`; tokens tied to revoked sessions are rejected by auth middleware.

## Authorization (RBAC)

- Deny-by-default. Access explicitly granted per role.
- Least privilege. Roles: `SUPER_ADMIN`, `COMPANY_ADMIN`, `HR_ADMIN`, `MANAGER`, `EMPLOYEE`.
- Admin and Super Admin routes always require authentication AND explicit role checks.
- CP4 route middleware enforces role checks server-side. Future business services must also preserve ownership and company-scope checks before repository calls.
- Role middleware uses `req.user.roles` after auth middleware verifies the token, validates the active device session, and refreshes the active user from the repository.
- Frontend route guards are only usability controls. They are never a security boundary.

### Authentication vs Authorization Failures

- Missing, malformed, expired, invalid, or revoked bearer tokens return `401` with code `UNAUTHENTICATED`.
- Authenticated users without the required role return `403` with code `FORBIDDEN`.
- Company-scope mismatch returns `403` with code `FORBIDDEN`.
- Authorization errors must not reveal whether a cross-company resource exists.

## Multi-Tenancy / Company Scoping

- `companyId` is derived from the authenticated token, never from request body or query.
- Every company-scoped query filters by the caller's `companyId`.
- Cross-company access is impossible except for `SUPER_ADMIN`, and such access must be explicit through documented company context.
- `SUPER_ADMIN` may pass company-scope checks across companies only where the route documents an explicit company context; state-changing module operations write audit logs.
- Non-super-admin users must have a `companyId` before they access company-scoped routes.
- If `:companyId`, body `companyId`, or query `companyId` is present, it must match the authenticated user's `companyId` unless the caller is `SUPER_ADMIN`.
- `req.companyScope` is the safe resolved scope for downstream controllers/services.
- Tenant isolation is verified by dedicated integration/security tests.
- CP5 services resolve company scope before reading or writing company-owned records, and repositories expose scoped lookup/update methods for tenant-owned data.
- CP6 geofence services resolve company scope before reading or writing geofences and before validating coordinates against active geofences.
- CP7 attendance services enforce self-service clock-in/out only, require active employee profile and active company, and resolve company scope before admin attendance listing.
- CP8 face enrollment/status services resolve company scope before reading or writing enrollments. `SUPER_ADMIN` requires explicit safe `companyId`; non-super-admin overrides are rejected.
- CP9 shift services resolve company scope before reading or writing shifts and assignments. Shift assignment verifies both shift and employee belong to the resolved company.
- CP10 leave services resolve company scope before reading or writing leave types, entitlements, and admin leave requests. Manager review is limited to direct reports through `EmployeeProfile.managerId`.
- CP11 OKR services resolve company scope before admin OKR reads/writes. Manager assignment/update/approval is limited to direct reports, while employee progress and employee approval are self-service only.
- CP12 performance review services resolve company scope before review cycle and admin review reads/writes. Manager review submission/update/status is limited to direct reports, and employee review access is self-service only.
- CP13 notification services enforce self-only user notification reads/updates. Admin broadcast resolves company scope before recipient lookup and sends only to active employees with active users in the scoped company.
- CP14 report services are read-only and resolve company scope before admin report aggregation. Manager report aggregation is limited to direct reports, employee dashboards are self-only, and super-admin reports are platform rollups only.
- CP15 billing services restrict plan/subscription/payment management to `SUPER_ADMIN`. Company-admin billing self-view resolves company scope from the authenticated user, rejects cross-company overrides, and omits provider references from payment self-view responses.
- CP16 hardening keeps every `/api/admin/*` route authenticated and role-gated, every `/api/super-admin/*` route `SUPER_ADMIN`-only, and internal `/api/system/*` verification routes disabled in production.

## Transport & Headers

- HTTPS in staging/production.
- Security headers via helmet (HSTS, no-sniff, frame options, etc.).
- Strict CORS allowlist; only the intended frontend origin(s) permitted. See `FRONTEND_HANDOFF.md` Section 19.
- Staging/production require explicit `CORS_ORIGIN` or `CORS_ORIGINS`; wildcard origins are rejected because credentials are enabled.

## Input Handling

- All input validated at the validation layer before service logic.
- Reject/ignore client-supplied `companyId`, `role`, and ownership fields.
- Do not trust frontend-provided roles, permissions, company IDs, or ownership fields.
- Parameterized queries via Prisma; no raw string SQL concatenation.

## Secrets

- Secrets (JWT keys, DB credentials, vendor keys) via environment/secret store.
- Never committed to source control. `.env` excluded.
- `DATABASE_URL`, `JWT_SECRET`, `JWT_REFRESH_SECRET`, and an explicit CORS origin are required in staging/production.
- `JWT_ACCESS_SECRET` may override `JWT_SECRET` for access-token signing when set.
- Rotation procedure and deployment environment rules are documented in `DEPLOYMENT_RUNBOOK.md`.

## Error Handling

- Standard JSON error envelope (see `API_CONTRACT.md`).
- No stack traces or internal details in production responses.
- No sensitive data in error messages.

## Auditing

- Sensitive actions (auth events, role/permission changes, approvals, subscription/payment changes, cross-company access, biometric enrollment) recorded in `AuditLog`.
- Audit log is append-only and access-restricted.
- CP17 adds a centralized audit metadata sanitizer in `src/lib/audit.ts`. Sensitive keys are removed before persistence even if a future module passes them accidentally.
- CP5 writes `AuditLog` records for company, department, designation, employee, employee status, and manager assignment changes.
- CP6 writes `AuditLog` records for geofence create, update, and status changes. CP6 does not audit every validate-location request to avoid unnecessary sensitive GPS logging.
- CP8 writes `AuditLog` records for face enrollment create/update/status changes. CP8 does not audit every face verification attempt and never logs raw face payloads or provider template references.
- CP9 writes `AuditLog` records for shift create, update, status changes, assignment create/update, and assignment removal.
- CP10 writes `AuditLog` records for leave type create/update/status, entitlement create/update, leave request submission, approval, and rejection. CP10 audit metadata must not include leave reasons or review comments.
- CP11 writes `AuditLog` records for OKR create/update/status/progress/employee approval/manager approval actions. CP11 audit metadata must not include OKR titles, descriptions, progress notes, or approval comments.
- CP12 writes `AuditLog` records for review cycle create/update/status and performance review submit/update/status actions. CP12 audit metadata must not include performance review summaries.
- CP13 writes `AuditLog` records for notification broadcast creation and completion. CP13 audit metadata must not include full notification titles or messages.
- CP15 writes `AuditLog` records for subscription plan create/update/status, company subscription create/status, and payment record create actions. CP15 audit metadata must not include full provider references, card numbers, bank account numbers, payment credentials, or payment secrets.
- CP16 verifies representative audit metadata restrictions.
- CP17 verifies audit write coverage and metadata safety across the implemented modules. CP17 does not expose a public/product audit-log read endpoint.

## Rate Limiting

- CP1 applies a global rate limit to all routes, including login and admin writes.
- More granular login/admin-write/per-route limits remain future hardening for CP18. See `RATE_LIMITING_RULES.md`.
- CP18 documents route-specific limits for login, face verification, attendance, notification broadcast, and sensitive admin writes as remaining production hardening; the current implemented control is global rate limiting.

## Sensitive Data

- See `PRIVACY_AND_LOGGING_RULES.md`. Never log passwords, JWTs, biometric data, or raw GPS history.
- Logger redaction is case-insensitive and covers credentials, tokens, biometric/provider references, GPS coordinates, payment references, leave/review/OKR comments, notification message text, and related sensitive fields.
- Validate-location requests contain sensitive GPS coordinates. Do not log request bodies or raw latitude/longitude values for these endpoints.
- Attendance clock-in/out requests contain sensitive GPS coordinates. Do not log request bodies or raw latitude/longitude values for these endpoints.
- Face enrollment and verification requests are biometric-sensitive. Do not log request bodies, provider references, verification references, raw image fields, or template references.
- Attendance clock-in requires a valid CP8 face verification reference. Missing, invalid, expired, reused, or different-employee references fail closed.
- Leave reasons and review comments are HR-sensitive. Do not log request bodies, leave reason text, or review comment text for leave endpoints.
- OKR text, progress notes, and approval comments are HR/performance-sensitive. Do not log request bodies or long OKR content for OKR endpoints.
- Performance review summaries are HR-sensitive. Do not log request bodies or summary text for performance review endpoints.
- Notification titles and messages may contain user-facing operational details. Do not log request bodies or full notification content for notification broadcast endpoints.
- Report responses must not include raw GPS coordinates, raw face/biometric data, leave reasons, leave review comments, performance review summaries, OKR notes/comments, or unrelated employee/user details.

## Verification

- Security regression suite runs each checkpoint.
- Consolidated security testing at Checkpoint 17 covers authz, isolation, input validation, rate limits, and sensitive-data leakage.
- CP18 production-readiness tests verify deployment scripts, env-template safety, strict CORS guardrails, production-disabled system routes, public health/readiness, and required deployment docs.
