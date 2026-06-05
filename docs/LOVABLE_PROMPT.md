# LOVABLE PROMPT

Use this prompt when generating the frontend in Lovable after the backend has been deployed to staging and the staging URL has been confirmed.

## Prompt

Build a role-based web frontend for the AI-powered workforce management platform.

Use the backend API as the source of truth. Use these source documents:

- `docs/API_CONTRACT.md`
- `docs/ROLE_PERMISSION_MATRIX.md`
- `docs/FRONTEND_HANDOFF.md`
- `docs/FRONTEND_ROUTE_MAP.md`
- `docs/SCREEN_API_MATRIX.md`
- `docs/TEST_ACCOUNTS.md`

Backend base URL:

```text
STAGING_BACKEND_URL=https://workforce-management-production.up.railway.app
```

Use this verified staging backend URL. Do not substitute or invent another backend URL.

Hard rules:

- Do not invent endpoints.
- Do not invent roles.
- Do not invent workflows.
- Do not add self-registration.
- Do not create self-registration.
- Do not bypass backend authorization.
- Do not create fake local-only data flows.
- Do not use mock APIs unless the project owner explicitly marks a screen as temporary UI-only scaffolding.
- Do not create routes not backed by `API_CONTRACT.md`.
- Do not store biometric data.
- Do not store GPS data beyond the immediate request needed for clock-in, clock-out, or geofence validation.
- Do not display sensitive data that is not returned by the backend.
- Do not build audit-log, payroll, live Stripe checkout, webhook, AI recommendation, mobile app, or advanced analytics screens.

Authentication:

- Login uses `POST /api/auth/login`.
- Hydrate the authenticated user with `GET /api/auth/me`.
- Logout uses `POST /api/auth/logout`.
- Send protected requests with `Authorization: Bearer <token>`.
- Clear the token on logout or any confirmed invalid-session state.
- Do not put tokens in URLs, logs, analytics events, or visible UI.

Authorization and navigation:

- Support exactly these roles: `SUPER_ADMIN`, `COMPANY_ADMIN`, `HR_ADMIN`, `MANAGER`, and `EMPLOYEE`.
- Hide screens by role, but do not treat frontend hiding as security.
- The backend remains the authorization source of truth.
- Handle backend permission failures gracefully even when a route is hidden in the UI.
- Non-super-admin users must not send arbitrary `companyId` overrides.
- Super-admin workflows must make selected company context explicit when a backend route requires company scope.

Required error handling:

- `401`: clear auth state and route to login with a calm expired-session message.
- `403`: show an access-denied state without exposing unrelated resource details.
- `404`: show a not-found state for the current resource or route.
- `422` or backend validation errors: show field-level messages when details are available; otherwise show the backend message.
- `429`: show retry/backoff messaging.
- Network or CORS error: show a connection issue state and do not replace it with fake data.

Required permission states:

- Camera permission denied or unavailable must be handled before face verification.
- GPS permission denied, unavailable, inaccurate, or outside-geofence states must be handled before clock-in or clock-out.
- Face verification must succeed before calling `POST /api/attendance/clock-in`.
- Attendance screens must handle duplicate clock-in and no-open-session clock-out errors.

Build screens only from the route map and screen/API matrix. Use loading states, empty states, and error states described in those files. Do not add frontend-only business workflows to fill gaps.
