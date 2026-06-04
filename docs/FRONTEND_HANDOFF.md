# FRONTEND HANDOFF

> **Status: CP19 FRONTEND HANDOFF PACKAGE READY WITH STAGING PLACEHOLDER.**
> The backend API, role matrix, route map, screen/API matrix, Lovable prompt, smoke checklist, and test-account placeholders are prepared for Lovable. The real staging backend URL is not available yet and must be recorded as soon as staging is deployed.

## 1. App Overview

The product is an AI-powered workforce management platform backend for multi-company HR operations, employee self-service, attendance with geofence and face verification, shifts, leave, OKRs, performance reviews, notifications, reports, and subscription/billing administration.

The backend is the source of truth. Lovable must not invent endpoints, roles, screens, workflows, fake local data flows, self-registration, live Stripe checkout, webhooks, audit-log screens, payroll, AI recommendations, advanced analytics, or mobile-app behavior.

## 2. Staging Backend URL

```text
STAGING_BACKEND_URL=TBD_AFTER_DEPLOYMENT
```

Use this placeholder until the backend is deployed to staging. Replace it only with the real staging URL provided by the project owner.

## 3. API Base URL

- Local backend URL: `http://localhost:4000`
- Staging backend URL: `TBD_AFTER_DEPLOYMENT`
- API versioning: no version prefix exists yet.
- Format: JSON requests and JSON responses.
- Source contract: `docs/API_CONTRACT.md`

## 4. Auth Flow

1. Submit credentials to `POST /api/auth/login`.
2. Store the returned access token according to the token storage guidance below.
3. Send protected requests with `Authorization: Bearer <token>`.
4. Load `GET /api/auth/me` after login or app reload to hydrate user state.
5. Call `POST /api/auth/logout` on logout.
6. Clear frontend auth state on logout or confirmed invalid session.

There is no public registration endpoint.

## 5. Token Storage Guidance

- Do not place tokens in URLs.
- Do not log tokens.
- Do not expose tokens in visible UI.
- Clear tokens on logout and `401` invalid-session behavior.
- Prefer the final frontend framework's safest practical storage pattern for the deployment model.
- The backend currently issues access tokens; no refresh-token endpoint is implemented.

## 6. Role List

- `SUPER_ADMIN`
- `COMPANY_ADMIN`
- `HR_ADMIN`
- `MANAGER`
- `EMPLOYEE`

Do not add roles.

## 7. Role-Based Navigation Rules

- Use `docs/ROLE_PERMISSION_MATRIX.md` and `docs/FRONTEND_ROUTE_MAP.md`.
- Hide screens the current role cannot use, but do not treat hidden UI as security.
- Backend authorization remains authoritative.
- Non-super-admin users must not send arbitrary `companyId` overrides.
- Super-admin workflows must make selected company context explicit where backend routes require company scope.

## 8. Error Format

Errors use this envelope:

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

Use `requestId` when showing support/debug context.

## 9. 401 Behavior

`401` means unauthenticated, invalid credentials, missing bearer token, invalid token, expired token, or revoked session. Clear auth state and route to `/login`. Do not keep showing protected data after `401`.

## 10. 403 Behavior

`403` means authenticated but not allowed. Show an access-denied state. Do not reveal unrelated company or resource details.

## 11. 404 Behavior

`404` means the route or scoped resource is unavailable. Show a not-found state. For cross-company or unauthorized resource lookups, do not infer or display whether the resource exists elsewhere.

## 12. Validation Error Behavior

Render field-level messages when backend details are present. Otherwise render the backend `message`. Do not silently retry invalid writes.

## 13. Login Flow

- Screen route: `/login`
- Endpoint: `POST /api/auth/login`
- Body: `{ "email": string, "password": string }`
- After success: call `GET /api/auth/me`, then route by role.
- Failure: show generic invalid-credential or validation state.

## 14. Logout Flow

- Endpoint: `POST /api/auth/logout`
- Auth: bearer token required.
- On success or confirmed invalid session: clear local auth state and return to `/login`.

## 15. Employee Clock-In Flow

- Screen route: `/employee/attendance/clock-in`
- Required sequence: camera permission -> `POST /api/face/verify` -> GPS permission -> `POST /api/attendance/clock-in`.
- Clock-in body includes latitude, longitude, and the successful face verification reference.
- Handle duplicate clock-in, expired/reused face reference, no active face enrollment, camera denied, GPS denied, and outside-geofence states.

## 16. Face Verification Flow

- Employee endpoint: `POST /api/face/verify`
- Admin endpoints: `POST /api/admin/employees/:employeeId/face-enrollment`, `GET /api/admin/employees/:employeeId/face-status`, `PATCH /api/admin/employees/:employeeId/face-enrollment/status`
- Do not store raw face images, biometric vectors, templates, or provider references in frontend state.
- Staging can use the backend mock provider behavior documented in `API_CONTRACT.md`.

## 17. Geofence/Location Flow

- Admin geofence setup: `/api/admin/geofences`
- Location validation: `POST /api/geofences/validate-location`
- Attendance requests also validate location through backend service logic.
- Use GPS only for the immediate request. Do not persist raw GPS in frontend storage.

## 18. Clock-Out Flow

- Screen route: `/employee/attendance/clock-out`
- Endpoint: `POST /api/attendance/clock-out`
- Body includes latitude and longitude.
- Handle no-open-session, GPS denied, outside-geofence, validation, and backend error states.

## 19. Leave Flow

- Employee submit: `POST /api/leave/request`
- Employee history/balances: `GET /api/leave/me`
- Manager team list: `GET /api/leave/team`
- Admin list: `GET /api/admin/leave-requests`
- Approval/rejection: `PATCH /api/leave/:leaveRequestId/approve`, `PATCH /api/leave/:leaveRequestId/reject`
- Admin configuration: `/api/admin/leave-types`, `/api/admin/leave-entitlements`
- Handle overlap, no entitlement, invalid dates, pending-only review, and role denial.

## 20. OKR Flow

- Create/assign: `POST /api/okrs`
- Self list: `GET /api/okrs/me`
- Team list: `GET /api/okrs/team`
- Admin list: `GET /api/admin/okrs`
- Detail/update/status/progress/approval: `/api/okrs/:okrId`
- OKRs are text-only. Do not add file evidence, AI recommendations, or advanced analytics.

## 21. Performance Review Flow

- Review cycles: `/api/admin/review-cycles`
- Submit review: `POST /api/reviews/:employeeId/manager-review`
- Self reviews: `GET /api/reviews/me`
- Team reviews: `GET /api/reviews/team`
- Admin reviews: `GET /api/admin/reviews`
- Detail/update/status: `/api/reviews/:reviewId`
- Do not add 360 reviews, calibration, AI scoring, file uploads, or advanced analytics.

## 22. Notification Flow

- List: `GET /api/notifications/me`
- Unread count: `GET /api/notifications/me/unread-count`
- Mark read: `PATCH /api/notifications/:notificationId/read`
- Mark all read: `PATCH /api/notifications/read-all`
- Admin broadcast: `POST /api/admin/notifications/broadcast`
- In-app notifications only. Do not add SMS, email, push, WebSockets, or cron UI.

## 23. Admin Employee Management Flow

- Employee CRUD/status/manager routes live under `/api/admin/employees`.
- Department routes live under `/api/admin/departments`.
- Designation routes live under `/api/admin/designations`.
- Admin-created employees receive credentials through the approved operational process; there is no public registration.
- Normal admins cannot assign `SUPER_ADMIN`.

## 24. Admin Geofence Flow

- Routes: `POST/GET/GET:id/PATCH /api/admin/geofences`, `PATCH /api/admin/geofences/:geofenceId/status`
- Use map inputs for latitude, longitude, and radius, but rely on backend validation.
- Do not store raw GPS beyond the immediate request lifecycle.

## 25. Admin Shift Flow

- Shift CRUD/status: `/api/admin/shifts`
- Assignment create/list: `/api/admin/shifts/:shiftId/assign`, `/api/admin/shifts/:shiftId/assignments`
- Assignment update/delete: `/api/admin/shift-assignments/:assignmentId`
- Employee self-view: `GET /api/shifts/me`
- No payroll, overtime, recurring calendars, or holiday calendars are implemented.

## 26. Admin Leave Management Flow

- Leave types: `/api/admin/leave-types`
- Leave entitlements: `/api/admin/leave-entitlements`
- Leave requests: `GET /api/admin/leave-requests`
- Review actions: `PATCH /api/leave/:leaveRequestId/approve` and `/reject`
- No partial-day leave, accrual engine, carryover automation, payroll, or calendar integration is implemented.

## 27. Admin Review Cycle Flow

- Review cycles: `/api/admin/review-cycles`
- Company reviews: `GET /api/admin/reviews`
- Review submission and update routes use `/api/reviews/*`.
- Validate active cycles and date ranges through backend responses.

## 28. Admin Reports Flow

- Admin reports: `GET /api/admin/reports/dashboard`, `/attendance`, `/leave`, `/okrs`, `/performance`
- Manager reports: `GET /api/reports/team/dashboard`, `/attendance`, `/leave`, `/okrs`, `/performance`
- Employee dashboard report: `GET /api/reports/me/dashboard`
- Reports return summary JSON only. Frontend may chart returned summaries but must not invent data.

## 29. Super Admin Company Flow

- Company management: `/api/super-admin/companies`
- Platform reports: `/api/super-admin/reports/dashboard`, `/api/super-admin/reports/companies`
- Company rollups come from reports only. No usage-metering endpoint exists.

## 30. Super Admin Subscription/Billing Flow

- Plan management: `/api/super-admin/plans`
- Company subscription assignment/current view: `/api/super-admin/companies/:companyId/subscription`
- Subscription list/status: `/api/super-admin/subscriptions`
- Manual payment records: `/api/super-admin/payment-records`, `/api/super-admin/companies/:companyId/payment-records`
- Company admin/HR self-view: `/api/admin/subscription`, `/api/admin/payment-records`
- Do not build Stripe checkout, card entry, bank entry, webhooks, invoice PDFs, refunds, tax, proration, coupons, or automated billing jobs.

## 31. Known Backend Limitations

- No self-registration.
- No refresh-token endpoint.
- No audit-log read endpoint.
- No live Stripe charging or webhooks.
- No production face vendor, liveness, consent workflow, or biometric deletion workflow.
- No SMS/email/push delivery, WebSockets, cron reminders, payroll, overtime, report exports, AI recommendations, or advanced analytics.
- Route-specific rate limits remain future hardening; global rate limiting is active.
- Staging URL and staging synthetic account emails remain placeholders until deployment.

## 32. Lovable Build Rules

- Use `docs/LOVABLE_PROMPT.md` exactly as the generation prompt.
- Use `docs/API_CONTRACT.md`, `docs/ROLE_PERMISSION_MATRIX.md`, `docs/FRONTEND_ROUTE_MAP.md`, and `docs/SCREEN_API_MATRIX.md`.
- Do not invent endpoints, roles, workflows, fake local data, or self-registration.
- Do not bypass backend authorization or company scoping.
- Handle `401`, `403`, `404`, validation errors, `429`, camera permission, GPS permission, and CORS/network failures.

## 33. Test Account Placeholders

Use `docs/TEST_ACCOUNTS.md`.

Required synthetic staging roles:

- `SUPER_ADMIN`
- `COMPANY_ADMIN`
- `HR_ADMIN`
- `MANAGER`
- `EMPLOYEE`

No real passwords are stored in repository docs.

## 34. Smoke Test Checklist Reference

Use `docs/SMOKE_TEST_CHECKLIST.md`.

Before Lovable connects:

- Confirm staging URL.
- Confirm `/health` and `/ready`.
- Confirm login and `/api/auth/me` for every role.
- Confirm CORS allowlist includes the Lovable/frontend origin.
- Confirm route map, screen/API matrix, Lovable prompt, and test accounts are complete.
