# ADMIN AND SUPER ADMIN HARDENING

Checkpoint 16 hardening rules for admin, super-admin, internal verification, sensitive responses, audit metadata, and frontend expectations.

## Admin Route Protection

- Every `/api/admin/*` route requires authentication.
- Every `/api/admin/*` route requires an explicit documented role.
- `COMPANY_ADMIN` and `HR_ADMIN` operate only inside their authenticated company.
- Non-super-admin users cannot override `companyId` through params, query, or body.
- `MANAGER` and `EMPLOYEE` cannot access `/api/admin/*` routes unless a route explicitly documents otherwise.
- Admin routes must return `401` for missing/invalid tokens and `403` for wrong role or company mismatch.

## Super Admin Route Protection

- Every `/api/super-admin/*` route requires authentication and `SUPER_ADMIN`.
- `COMPANY_ADMIN`, `HR_ADMIN`, `MANAGER`, and `EMPLOYEE` cannot access super-admin routes.
- `SUPER_ADMIN` users may have `companyId: null`.
- Platform-level super-admin reads are allowed only where documented.
- Company-scoped super-admin operations require explicit `companyId` where the endpoint contract says so.
- Normal company-admin employee creation cannot assign `SUPER_ADMIN`; super-admin creation remains seed/manual-only.

## Company Admin And HR Restrictions

- `COMPANY_ADMIN` and `HR_ADMIN` cannot access another company's employees, geofences, attendance, leave, OKRs, reviews, notifications, reports, subscriptions, or payment records.
- They cannot create `SUPER_ADMIN`.
- They cannot assign users to another company.
- They cannot access super-admin plan, subscription, payment, company-management, or platform-report endpoints.

## Manager Restrictions

- `MANAGER` direct-report access is enforced through `EmployeeProfile.managerId`.
- Managers cannot access non-direct report leave, OKR, performance review, or team report data.
- Managers cannot create users, configure geofences, configure leave types, configure shifts, manage billing, broadcast notifications, or access admin-wide company records.

## Employee Restrictions

- `EMPLOYEE` self-access is enforced through the authenticated user's employee profile.
- Employees cannot access admin routes, super-admin routes, another employee's records, team routes, company reports, billing, geofence setup, employee management, shift assignment management, leave approval, OKR assignment, or review submission.

## Internal System Routes

- `/health` and `/ready` remain public.
- `/api/system/*` routes are internal verification endpoints, not frontend product screens.
- Outside production, `/api/system/*` routes remain protected by authentication, role checks, and company-scope checks.
- In `NODE_ENV=production`, `/api/system/*` returns `404 NOT_FOUND`.

## Sensitive Responses

Responses must not include:

- `passwordHash`
- JWTs except login response `accessToken`
- Raw face/biometric data
- Raw face template references
- Unnecessary GPS coordinates in reports
- Leave reasons in reports or audit metadata
- Review summaries/comments in reports or audit metadata
- OKR notes/comments in reports or audit metadata
- Provider payment references in audit metadata
- Unrelated user details

## Audit Metadata

- Sensitive admin actions must write audit logs where implemented by CP5-CP15.
- Audit metadata must stay sparse and operational.
- Audit metadata must not include passwords, tokens, raw GPS, biometric payloads, leave reasons, review summaries/comments, OKR notes/comments, notification body text, or payment provider references.

## Seed And Environment Security

- Seeded accounts and `Password123!` are local/development-only.
- Seed credentials must not be used for staging or production.
- `.env.example` must contain placeholders, not real secrets.
- `DATABASE_URL`, `JWT_ACCESS_SECRET`, and `JWT_REFRESH_SECRET` are required in production.
- Passwords and hashes must never be logged.

## Lovable Frontend Expectations

- The frontend may hide screens by role, but backend authorization is the source of truth.
- Hidden UI is not a security boundary.
- Non-super-admin screens should not manually supply `companyId`.
- Super-admin company-scoped screens must supply explicit company context only where the API contract requires it.
- Internal `/api/system/*` verification routes are not frontend product screens and must not be used by Lovable.
- Lovable must not invent fake admin workflows, bypass auth, bypass company scoping, or assume a role from frontend state alone.

## Remaining Production Hardening

- CP17 performs consolidated audit, privacy, and security testing.
- CP18 completes production readiness and deployment hardening.
- More granular per-route rate limits, monitoring, incident response, log-retention policy, and production secrets rotation are finalized in CP18.
