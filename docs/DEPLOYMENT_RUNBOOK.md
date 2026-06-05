# DEPLOYMENT RUNBOOK

Operational runbook for deploying the workforce management backend to staging or production.

## Environments

| Environment | Purpose | Status |
| ----------- | ------- | ------ |
| Local | Development and test execution | Ready |
| Staging | Pre-production, Lovable integration, role testing | Ready to deploy; CP19 handoff docs use URL placeholder until deployment |
| Production | Live customer traffic | Requires staging validation and operational approval |

## Prerequisites

- Node.js 22.x.
- PostgreSQL database reachable from the backend runtime.
- Secret manager or environment-variable manager.
- Reviewed Prisma migrations in `prisma/migrations`.
- Intended frontend/Lovable origin known before staging frontend integration.
- No production secrets committed to source control.
- CP19 handoff docs available: `FRONTEND_HANDOFF.md`, `FRONTEND_ROUTE_MAP.md`, `SCREEN_API_MATRIX.md`, `LOVABLE_PROMPT.md`, and `TEST_ACCOUNTS.md`.
- Staging environment variables prepared with `STAGING_ENV_CHECKLIST.md`.

## Required Environment Variables

| Variable | Required | Notes |
| -------- | -------- | ----- |
| `NODE_ENV` | Yes | `development`, `test`, `staging`, or `production`. |
| `PORT` | Yes | Defaults to `4000` if omitted. |
| `LOG_LEVEL` | Yes | `debug`, `info`, `warn`, or `error`; defaults to `info`. |
| `DATABASE_URL` | Staging/production | PostgreSQL URL from secret manager. Required outside dev/test deploys. |
| `JWT_SECRET` | Staging/production | Primary access-token secret fallback. Use high-entropy secret-managed value. |
| `JWT_ACCESS_SECRET` | Optional | Overrides `JWT_SECRET` for access-token signing when set. |
| `JWT_REFRESH_SECRET` | Staging/production | Reserved for refresh/session hardening; required in deployed environments. |
| `JWT_ACCESS_TTL` | Optional | Defaults to `15m`. |
| `JWT_REFRESH_TTL` | Optional | Defaults to `7d`; refresh endpoint is not implemented yet. |
| `CORS_ORIGIN` | Staging/production | Single allowed frontend origin. |
| `CORS_ORIGINS` | Optional | Comma-separated additional allowed origins. |
| `FACE_PROVIDER` | Optional | `mock` in local/staging unless a production vendor is implemented. |
| `STORAGE_PROVIDER` | Optional | `local` placeholder. |

Future integration placeholders may exist in `.env.example` but must remain unset until implemented: `STRIPE_SECRET_KEY`, `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, and `EMAIL_PROVIDER`.

## Environment Rules

- `DATABASE_URL`, `JWT_SECRET`, `JWT_REFRESH_SECRET`, and at least one CORS origin are required in `staging` and `production`.
- Wildcard CORS origins are rejected because credentials are enabled.
- Test/dev defaults are unsafe for production.
- Seeded local passwords and example users must never be used in staging or production.
- `npm run prisma:migrate:deploy` requires an explicit `DATABASE_URL` when `NODE_ENV` is `staging` or `production`.

## Local Setup

```bash
npm install
npm run prisma:validate
npm run prisma:generate
npm run typecheck
npm run build
npm test
npm run dev
```

## Build And Start

```bash
npm install
npm run prisma:generate
npm run build
npm run start
```

`npm run start` starts `dist/server.js`. Always run `npm run build` first.

## Exact Staging Deployment Flow

Use the hosting provider's equivalent command flow when it manages install/build/start phases separately.

1. Configure staging environment variables from `docs/STAGING_ENV_CHECKLIST.md`.
2. Install dependencies:

```bash
npm ci
```

Use `npm install` only when the host does not support `npm ci`.

3. Generate Prisma Client:

```bash
npm run prisma:generate
```

4. Build the backend:

```bash
npm run build
```

5. Apply reviewed migrations against the staging database:

```bash
npm run prisma:migrate:deploy
```

`npm run prisma:migrate` is equivalent and also maps to `prisma migrate deploy`.

6. Start the backend:

```bash
npm run start
```

7. Check public health endpoints:

```bash
curl -i "$STAGING_BACKEND_URL/health"
curl -i "$STAGING_BACKEND_URL/ready"
```

8. Verify internal system route behavior:

- `NODE_ENV=staging`: `/api/system/*` verification routes are still available for authenticated staging verification and must not be called by Lovable.
- `NODE_ENV=production`: `/api/system/*` returns `404`.

9. Run the smoke checklist in `docs/SMOKE_TEST_CHECKLIST.md`.
10. Create synthetic role accounts from `docs/TEST_ACCOUNTS.md`.
11. Update handoff docs with the real staging backend URL once `/health`, `/ready`, login, and `GET /api/auth/me` pass.

## Database Migrations

Local review:

```bash
npm run prisma:validate
npm run prisma:generate
```

Staging deploy:

```bash
npm run prisma:migrate
```

Production deploy:

```bash
npm run prisma:migrate
```

Migration rules:

- Review migration SQL before production.
- Back up the production database before applying migrations.
- Do not run destructive migrations without explicit approval.
- Do not run migrations against production from a local workstation unless that is the approved operational process.
- `npm run prisma:migrate` maps to `prisma migrate deploy`.

## Seed Policy

- `npm run prisma:seed` and `npm run seed` are local/development helpers.
- Seed creates development roles, Basic/Premium plans, and local example users.
- Seeded credentials are not staging or production credentials.
- Production super-admin creation must be manual, controlled, and audited through the approved operational path.
- Basic/Premium seed plans are safe examples for local development, not production billing configuration.

## Health Checks

- `GET /health`: public liveness check; lightweight and does not query the database.
- `GET /ready`: public readiness check; queries the database when `DATABASE_URL` is configured.
- `GET /ready` returns `503` when a configured database is unreachable.
- In local/test with no `DATABASE_URL`, readiness returns `ready` with database status `not_configured`.
- In staging/production, `DATABASE_URL` is required by env validation.
- `/api/system/*` remains auth-protected and available in staging for verification only.
- `/api/system/*` returns `404` in production.

## CORS Setup

- Configure `CORS_ORIGIN` or `CORS_ORIGINS` with the exact frontend/Lovable origin.
- Do not use `*`.
- Credentials are enabled, so frontend requests must use the configured origin.
- CORS problems must be fixed by updating the backend allowlist or correcting frontend usage, never by bypassing auth or disabling CORS.

## Logging And Errors

- Structured logs redact sensitive keys through `src/lib/logger.ts`.
- Audit metadata is sanitized by `src/lib/audit.ts`.
- Error responses use the standard JSON envelope and include `requestId`.
- Production responses do not expose stack traces or internal error details.
- Logs must not contain passwords, JWTs, biometric data, raw GPS, payment secrets, leave/review/OKR sensitive text, or notification message bodies.

## Rate Limits

- Global rate limiting applies to all routes, including login and admin writes.
- Route-specific rate limits for login, face verification, attendance, notification broadcast, and other sensitive writes remain future hardening.
- Frontend must handle `429` with retry/backoff UX.

## Post-Deploy Smoke Tests

Run `docs/SMOKE_TEST_CHECKLIST.md` after every staging deployment and before any production cutover.

Minimum smoke:

- `GET /health`
- `GET /ready`
- Login for each role
- `GET /api/auth/me`
- One company-scoped admin read
- One employee self read
- One negative role test
- One negative cross-company test
- Production `/api/system/*` check when applicable
- Staging `/api/system/*` behavior documented and not used by Lovable

Lovable readiness smoke:

- Confirm handoff usage references `https://workforce-management-production.up.railway.app`.
- Confirm synthetic staging test accounts exist for all five roles.
- Confirm the frontend/Lovable origin is configured in `CORS_ORIGIN` or `CORS_ORIGINS`.
- Confirm `docs/SMOKE_TEST_CHECKLIST.md` CP19 checks pass before Lovable generation.

## Rollback Notes

- Keep the previous build artifact available.
- Roll back application code first if the database schema remains compatible.
- If a migration caused the issue, stop writes before attempting database rollback.
- Restore from backup if a destructive migration or data corruption occurred.
- Document the rollback reason, affected migration, and recovery action.

## Common Failure Modes

- Missing `DATABASE_URL` in staging/production: env validation fails at startup.
- Missing `JWT_SECRET` or `JWT_REFRESH_SECRET`: env validation fails at startup.
- Empty or wildcard CORS origins in staging/production: env validation fails at startup.
- `/ready` returns `503`: database is configured but unreachable.
- Login returns `401`: invalid credentials, inactive user, revoked session, or wrong JWT secret.
- Frontend receives CORS error: origin not present in `CORS_ORIGIN`/`CORS_ORIGINS`.
- `/api/system/*` returns `404` in production: expected behavior.

## Monitoring Notes

- Monitor request error rate, `5xx` responses, readiness status, database connectivity, auth failures, and rate-limit spikes.
- Track deployment version, migration version, and request IDs for incident triage.
- Final alerting thresholds and log retention policy are operational tasks after staging baseline.

## Staging URL

- Backend staging URL: `https://workforce-management-production.up.railway.app` (health/readiness verified June 5, 2026).
- Lovable frontend origin: to be assigned after frontend generation and added to `CORS_ORIGIN` or `CORS_ORIGINS`.
