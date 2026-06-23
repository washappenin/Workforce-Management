# LOVABLE FRONTEND PLAN

## Purpose

This document governs how Lovable should generate the web/reference frontend for the AI-powered workforce management platform after the backend handoff package is complete.

The production-critical client target is now a Flutter mobile app for iOS and Android. Lovable remains useful as a visual reference, secondary admin/web console, or rapid validation surface, but employee and manager daily-use workflows must be designed and implemented mobile-first in Flutter.

## Staging Gate

Lovable starts only after the staging backend is deployed, health/readiness pass, synthetic role test accounts are available, and CORS is configured for the frontend origin used by the generated app.

Current staging backend:

```text
STAGING_BACKEND_URL=https://workforce-management-production.up.railway.app
```

This staging URL is verified for health, database readiness, five-role auth/boundary/logout checks, and the full core workflow smoke test. First Lovable connection testing must still wait for frontend CORS configuration after the generated frontend origin is known.

## Source Documents

Lovable must use these documents as the source of truth:

- `docs/API_CONTRACT.md`
- `docs/ROLE_PERMISSION_MATRIX.md`
- `docs/FRONTEND_HANDOFF.md`
- `docs/FRONTEND_ROUTE_MAP.md`
- `docs/SCREEN_API_MATRIX.md`
- `docs/TEST_ACCOUNTS.md`
- `docs/LOVABLE_PROMPT.md`
- `docs/FRONTEND_CHECKPOINT_LOG.md`

## Required Rules

1. Lovable starts only after staging backend is deployed.
2. Lovable must use the staging backend URL.
3. Lovable must not use mock APIs unless explicitly marked as temporary UI-only scaffolding by the project owner.
4. Lovable must not create self-registration.
5. Lovable must not create routes not backed by `API_CONTRACT.md`.
6. Lovable must respect role-based navigation from `ROLE_PERMISSION_MATRIX.md` and `FRONTEND_ROUTE_MAP.md`.
7. Lovable must handle camera and GPS permission states.
8. Lovable must support face verification before clock-in.
9. Lovable must not store biometric data.
10. Lovable must not store GPS data beyond the immediate request.
11. Lovable must not display sensitive data not returned by backend.
12. Lovable must not treat hidden UI as security.
13. All backend permission failures must be handled gracefully.

## Hard Prohibitions

- Do not invent endpoints.
- Do not invent roles.
- Do not invent business workflows.
- Do not bypass backend authorization.
- Do not bypass company scoping.
- Do not create fake local-only data flows.
- Do not build audit-log screens.
- Do not build live Stripe checkout, card entry, webhooks, payroll, AI recommendation, mobile app, or advanced analytics screens.

## Role Areas

- Public: login only.
- Employee: dashboard, attendance, face verification, shifts, leave, OKRs, reviews, notifications. This is mobile-first in Flutter.
- Manager: team dashboards, team attendance, leave approvals, OKRs, reviews, reports, notifications. This is mobile-first in Flutter.
- HR/Admin: company operations, employees, departments, designations, geofences, face enrollment, attendance logs, shifts, leave config, OKRs, reviews, notifications, reports, subscription/payment self-view.
- Super Admin: companies, plans, company subscriptions, manual payment records, platform reports, company rollups.

## Integration Test Flow

1. Confirm `GET /health` returns `200`.
2. Confirm `GET /ready` returns `200`.
3. Login as each role from `docs/TEST_ACCOUNTS.md`.
4. Confirm `GET /api/auth/me` returns the expected role.
5. Confirm role navigation hides unsupported screens.
6. Confirm unsupported backend calls return graceful `403` UI states.
7. Confirm employee face verification precedes clock-in.
8. Confirm camera and GPS permission failures render cleanly.
9. Confirm CORS errors are fixed by backend allowlist configuration, not by frontend bypasses.
10. Run `docs/SMOKE_TEST_CHECKLIST.md`.

## Issue Resolution Policy

When Lovable hits CORS, authentication, validation, permission, or route errors:

- Check `API_CONTRACT.md` and `SCREEN_API_MATRIX.md`.
- Fix frontend request method/path/body/header if it differs from the contract.
- Fix backend CORS allowlist when the frontend origin is valid but blocked.
- Do not replace failures with mock data.
- Do not weaken auth, RBAC, company scoping, logging, privacy, audit, or admin hardening.
