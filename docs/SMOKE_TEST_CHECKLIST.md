# SMOKE TEST CHECKLIST

Use this checklist after a local build, staging deploy, migration deploy, or production deploy. Do not use production personal data or production credentials for smoke testing.

Runnable Bash checks are available in `scripts/staging-smoke/`. Configure the gitignored `scripts/staging-smoke/smoke.env` from `smoke.env.example`, then run the infrastructure, authentication/boundary, or explicitly enabled core-workflow script documented in `scripts/staging-smoke/README.md`.

## Public Checks

- `GET /health` returns `200` with `data.status = "ok"`.
- `GET /ready` returns `200` when the database is configured and reachable.
- `GET /ready` returns `503` if the configured database is unreachable.

## Auth Checks

- Login succeeds as `SUPER_ADMIN`.
- Login succeeds as `COMPANY_ADMIN`.
- Login succeeds as `HR_ADMIN`.
- Login succeeds as `MANAGER`.
- Login succeeds as `EMPLOYEE`.
- `GET /api/auth/me` returns the authenticated user and roles.
- `POST /api/auth/logout` revokes the current session.

## Role And Security Checks

- `EMPLOYEE` cannot access an admin route such as `GET /api/admin/employees`.
- `COMPANY_ADMIN` cannot access a super-admin route such as `GET /api/super-admin/plans`.
- A non-super-admin cross-company request returns `403` or `404` without leaking resource existence.
- In `NODE_ENV=production`, `/api/system/*` returns `404`.

## Core Workflow Checks

- Super admin creates a company.
- Admin creates an employee.
- Admin creates a geofence.
- Admin enrolls a face profile.
- Employee verifies face.
- Employee clocks in.
- Employee clocks out.
- Admin creates a shift.
- Admin assigns a shift.
- Employee views own shift.
- Admin creates a leave type and entitlement.
- Employee submits leave.
- Manager approves leave.
- Manager assigns an OKR.
- Employee updates OKR progress.
- Employee approves OKR.
- Manager approves OKR.
- Admin creates a review cycle.
- Manager submits a performance review.
- Employee views own review.
- Admin broadcasts a notification.
- Employee reads the notification.
- Admin views reports.
- Super admin manages a subscription plan.
- Super admin assigns a subscription.
- Company admin views own subscription and payment history.

## Privacy Checks

- No response contains `passwordHash`.
- No response contains `temporaryPassword`.
- No response contains raw biometric data or raw face images.
- Face enrollment/status responses do not include `providerSubjectId` or `templateReference`.
- Company-admin payment history does not include `providerReference`.
- Report/dashboard rollups do not include raw GPS coordinates, leave reasons, review summaries/comments, OKR notes/comments, or biometric/provider data.
- Logs redact passwords, JWTs, biometric/provider references, raw GPS coordinates, payment references, leave/review/OKR comments, and notification message bodies.

## Deployment Checks

- `docs/STAGING_ENV_CHECKLIST.md` has been followed for staging deploys.
- `npm run prisma:validate` passes before deploy.
- `npm run prisma:generate` runs during build or release.
- `npm run prisma:migrate:deploy` or `npm run prisma:migrate` runs against the target database only after migration review.
- `npm run build` passes.
- `npm run start` starts `dist/server.js`.
- CORS allows only the intended frontend/Lovable origin.
- Request IDs appear in response headers and error bodies.
- In `NODE_ENV=staging`, `/api/system/*` is auth-protected verification-only behavior and must not be called by Lovable.
- In `NODE_ENV=production`, `/api/system/*` returns `404`.

## CP19 Lovable Readiness Checks

- Staging URL is confirmed as `https://workforce-management-production.up.railway.app`.
- `GET /health` passes against the staging backend.
- `GET /ready` passes against the staging backend.
- Login works for `SUPER_ADMIN`.
- Login works for `COMPANY_ADMIN`.
- Login works for `HR_ADMIN`.
- Login works for `MANAGER`.
- Login works for `EMPLOYEE`.
- `GET /api/auth/me` works for each role.
- CORS is configured for the frontend/Lovable origin.
- Synthetic staging test accounts are available or documented in `docs/TEST_ACCOUNTS.md` as pending setup.
- Synthetic staging account passwords are stored only in the approved password manager or staging secret store.
- `docs/API_CONTRACT.md` is complete for implemented endpoints.
- `docs/FRONTEND_HANDOFF.md` is complete.
- `docs/FRONTEND_ROUTE_MAP.md` is complete.
- `docs/SCREEN_API_MATRIX.md` is complete.
- `docs/LOVABLE_PROMPT.md` is complete.
- `docs/STAGING_ENV_CHECKLIST.md` is complete.

## First Lovable Connection Tests

- Login from Lovable succeeds against the staging backend.
- Auth token is stored according to frontend token guidance and sent as `Authorization: Bearer <token>`.
- Employee dashboard loads from `GET /api/employees/me` and `GET /api/reports/me/dashboard`.
- Admin dashboard loads from `GET /api/admin/reports/dashboard`.
- Super admin dashboard loads from `GET /api/super-admin/reports/dashboard`.
- `401` is handled by clearing auth state and returning to login.
- `403` is handled with a permission-denied state.
- CORS errors are checked against backend allowlist configuration.

## Staging Smoke Test Result

| Field | Result |
| ----- | ------ |
| Date tested | June 5, 2026 |
| Staging URL | `https://workforce-management-production.up.railway.app` |
| Health result | `PASS` - HTTP `200`, `data.status = "ok"`, environment `staging`, no sensitive data observed. |
| Ready result | `PASS` - HTTP `200`, `data.status = "ready"`, database configured and `connected`, no sensitive data observed. |
| Internal route result | `PASS` for documented staging behavior - unauthenticated `GET /api/system/auth-check` returned HTTP `401 UNAUTHENTICATED`; route is not public. |
| Migration deploy status | Pending confirmation from staging deployment: `npm run prisma:migrate:deploy` or configured equivalent. |
| Auth result | Pending login, `GET /api/auth/me`, and logout for all five roles. |
| Role boundary result | Pending employee/admin, company-admin/super-admin, HR/super-admin, manager/admin, super-admin, and cross-company checks. |
| Core workflow result | Pending completion of the workflow checks above. |
| CORS status | Pending real Lovable/frontend origin. `CORS_ORIGIN` or `CORS_ORIGINS` must be updated once available. |
| Synthetic account status | Pending creation/confirmation in `docs/TEST_ACCOUNTS.md`; passwords must stay in secure password manager / staging secret. |
| Remaining issues | Migration deploy confirmation, synthetic accounts, auth/role/core-workflow smoke tests, and Lovable frontend CORS origin. |

Lovable generation is not cleared until this result section is updated with passing auth, role-boundary, and core workflow results, plus synthetic accounts and the frontend CORS origin.
