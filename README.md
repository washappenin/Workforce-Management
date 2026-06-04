# Workforce Management Backend

This workspace contains the backend foundation for the AI-powered workforce management backend.

## Current State

- Checkpoint 0 is complete.
- Checkpoint 1 is complete.
- Checkpoint 2 is complete.
- Checkpoint 3 is complete.
- Checkpoint 4 is complete.
- Checkpoint 5 is complete.
- Checkpoint 6 is complete.
- Checkpoint 7 is complete.
- Checkpoint 8 is complete.
- Checkpoint 9 is complete.
- Checkpoint 10 is complete.
- Checkpoint 11 is complete.
- Checkpoint 12 is complete.
- Checkpoint 13 is complete.
- Checkpoint 14 is complete.
- Checkpoint 15 is complete.
- Checkpoint 16 is complete.
- Checkpoint 17 is complete.
- Checkpoint 18 is complete.
- Checkpoint 19 is complete.
- The backend shell includes Express, TypeScript, Prisma-ready config, Jest, Supertest, middleware scaffolding, and health/readiness endpoints.
- The Prisma schema includes the CP2 domain model foundation.
- Authentication endpoints are implemented under `/api/auth`.
- RBAC and company-scoping middleware foundations are implemented and tested.
- Company, department, designation, and employee management endpoints are implemented under CP5.
- Geofence setup and location validation endpoints are implemented under CP6.
- Attendance clock-in/out and attendance listing endpoints are implemented under CP7.
- Face verification enrollment/status, mock adapter verification, and clock-in face-reference enforcement are implemented under CP8.
- Shift management, shift assignment, and employee shift self-view endpoints are implemented under CP9.
- Leave type management, leave entitlement management, employee leave requests, manager/team leave review, and admin leave review are implemented under CP10.
- Text-only OKR assignment, scoped OKR views, progress updates, employee approval, and manager/admin approval are implemented under CP11.
- Review cycle management, manager/admin review submission, scoped review views, update/status flows, and employee review self-view are implemented under CP12.
- In-app notification list/count/read flows, admin broadcast, and notification helper functions are implemented under CP13.
- Read-only admin, manager, employee, and super-admin report/dashboard summaries are implemented under CP14.
- Subscription plan management, company subscription assignment/status tracking, manual payment records, and company-admin billing self-view are implemented under CP15.
- Admin/super-admin route hardening, production-disabled internal verification routes, sensitive response checks, and audit metadata hardening are implemented under CP16.
- Audit log coverage verification, centralized audit metadata sanitization, expanded log redaction, privacy/security regression tests, and security audit documentation are implemented under CP17.
- Production-readiness preparation, deployment scripts/docs, strict deployed-environment validation, smoke checklist, backend completion summary, and frontend/Lovable handoff preparation are implemented under CP18.
- Final frontend handoff package for Lovable, including prompt, route map, screen/API matrix, test-account placeholders, and handoff verification tests, is implemented under CP19.
- No audit-log read API, Lovable frontend code, mobile app, live payment processing, webhooks, AI recommendations, advanced analytics, real staging URL, or production credentials are implemented or stored in this repository.
- The next safe step after CP19 is staging backend deployment, synthetic staging account creation, and Lovable frontend generation against the real staging backend URL.

## Local Commands

```bash
npm install
npm run prisma:validate
npm run prisma:generate
npm run typecheck
npm run build
npm test
npm run dev
```

Run `npm run prisma:migrate` for reviewed staging/production migration deploys only. Run `npm run seed` for local/development seed data only.

## Checkpoint 2 Notes

- `prisma/schema.prisma` defines the core domain models, enums, relations, indexes, and constraints.
- `prisma/seed.ts` is seed-ready for core roles and Basic/Premium subscription plans.
- `prisma/migrations/20260602000000_cp2_schema_foundation/migration.sql` is prepared but not applied.
- Multiple geofences per company are allowed in the schema; CP6 business logic may restrict the MVP to one active company geofence until the product decision is finalized.
- No production migration is forced by CP2.

## Checkpoint 3 Notes

- `POST /api/auth/login` issues a JWT access token and creates a device session.
- `GET /api/auth/me` returns the authenticated user and roles.
- `POST /api/auth/logout` revokes the current device session.
- There is no public registration endpoint.
- `prisma/seed.ts` includes safe local-only example users with password `Password123!`; do not use these as production credentials.

## Checkpoint 4 Notes

- `src/middleware/role.middleware.ts` provides `requireRole`, `requireAnyRole`, and named middleware for all five core roles.
- `src/middleware/companyScope.middleware.ts` validates params, body, and query `companyId` values against the authenticated user and attaches `req.companyScope`.
- `src/lib/authorization.ts` provides role and same-company helper utilities.
- `src/lib/permissions.ts` provides permission constants for future permission-based authorization.
- CP4 adds internal `/api/system/*` authorization verification routes only; these are not product/business endpoints.

## Checkpoint 5 Notes

- `POST/GET/GET:id/PATCH /api/super-admin/companies` manages companies for `SUPER_ADMIN`.
- `POST/GET/GET:id/PATCH /api/admin/departments` and `/api/admin/designations` manage organization structure inside a resolved company scope.
- `POST/GET/GET:id/PATCH /api/admin/employees`, `/status`, and `/manager` manage workforce accounts and employee profiles for `COMPANY_ADMIN`, `HR_ADMIN`, and scoped `SUPER_ADMIN`.
- `GET /api/employees/me` returns the authenticated user's own employee profile.
- Employee creation uses a required CP5 development `temporaryPassword`, stores only a bcrypt hash, and never returns `passwordHash`.
- CP5 writes audit logs for organization-management changes.

## Checkpoint 6 Notes

- `POST/GET/GET:id/PATCH /api/admin/geofences` manages circular geofences for `COMPANY_ADMIN`, `HR_ADMIN`, and explicitly scoped `SUPER_ADMIN`.
- `PATCH /api/admin/geofences/:geofenceId/status` changes geofence status using the existing `GeofenceStatus` enum.
- `POST /api/geofences/validate-location` validates a coordinate against active geofences in the resolved company scope.
- CP6 supports multiple geofences per company in service logic; product policy may later restrict one active geofence without adding a database constraint.
- CP6 does not create `AttendanceSession`, `AttendanceEvent`, or `LocationPing` records.
- Raw GPS coordinates are not written to audit logs.

## Checkpoint 7 Notes

- `POST /api/attendance/clock-in` opens a self-service attendance session after active geofence validation and CP8 face verification reference validation.
- `POST /api/attendance/clock-out` closes the caller's open attendance session after active geofence validation.
- `GET /api/attendance/me` returns the caller's own attendance sessions.
- `GET /api/admin/attendance` returns company-scoped attendance logs for `COMPANY_ADMIN`, `HR_ADMIN`, and explicitly scoped `SUPER_ADMIN`.
- CP7 creates `AttendanceEvent` records for `CLOCK_IN` and `CLOCK_OUT`.
- `clockInFaceVerified` is `true` only after a CP8 face verification reference is consumed.
- CP7 does not create continuous `LocationPing` records or `GeofenceBreach` records for rejected outside-geofence attempts.

## Checkpoint 8 Notes

- `POST /api/admin/employees/:employeeId/face-enrollment` creates or updates mock-provider face enrollment metadata for scoped admins.
- `GET /api/admin/employees/:employeeId/face-status` returns safe enrollment status without provider subject or template references.
- `PATCH /api/admin/employees/:employeeId/face-enrollment/status` changes enrollment status and writes audit logs.
- `POST /api/face/verify` verifies the authenticated employee against an active enrollment using the safe mock provider.
- The CP8 mock provider succeeds with `mock-pass` and fails with `mock-fail`.
- Successful verification returns a short-lived, single-use reference required by clock-in.
- CP8 stores no raw face images, no raw biometric vectors, and no face templates.

## Checkpoint 9 Notes

- `POST/GET/GET:id/PATCH /api/admin/shifts` manages simple company-scoped shifts for `COMPANY_ADMIN`, `HR_ADMIN`, and explicitly scoped `SUPER_ADMIN`.
- `PATCH /api/admin/shifts/:shiftId/status` changes shift status without deleting historical assignments.
- `POST /api/admin/shifts/:shiftId/assign` assigns active shifts to active employees in the resolved company scope.
- `GET /api/admin/shifts/:shiftId/assignments` lists assignments for a scoped shift.
- `PATCH/DELETE /api/admin/shift-assignments/:assignmentId` updates or hard-deletes assignment records.
- `GET /api/shifts/me` returns the authenticated employee's own current/future shift assignments.
- CP9 uses simple `HH:mm` shift times and does not implement payroll, overtime, recurring calendars, holiday calendars, or attendance-time enforcement.

## Checkpoint 10 Notes

- `POST/GET/GET:id/PATCH /api/admin/leave-types` manages company-scoped leave types.
- `PATCH /api/admin/leave-types/:leaveTypeId/status` changes leave type status without deleting historical requests or entitlements.
- `POST/GET/GET:id/PATCH /api/admin/leave-entitlements` manages employee leave balances with upsert behavior for duplicate employee/type/year records.
- `POST /api/leave/request` creates self-service full-day leave requests using the CP10 `NO_ENTITLEMENT` policy.
- `GET /api/leave/me` returns the authenticated employee's own leave requests and balances.
- `GET /api/leave/team` returns manager direct-report leave requests only.
- `GET /api/admin/leave-requests` returns company-scoped admin leave requests.
- `PATCH /api/leave/:leaveRequestId/approve` approves pending requests and increments entitlement `usedDays`.
- `PATCH /api/leave/:leaveRequestId/reject` rejects pending requests without incrementing `usedDays`.
- CP10 does not implement payroll, partial-day leave, holiday calendars, accrual policies, carryover, reviews, reports, subscriptions, or billing.

## Checkpoint 11 Notes

- `POST /api/okrs` creates text-only OKRs for scoped admins and direct-report managers.
- `GET /api/okrs/me` returns the authenticated employee's own OKRs.
- `GET /api/okrs/team` returns manager direct-report OKRs only.
- `GET /api/admin/okrs` returns company-scoped OKRs for HR/Admin, Company Admin, and explicitly scoped Super Admin.
- `GET /api/okrs/:okrId` returns an OKR when the caller is the owner, direct manager, or scoped admin.
- `PATCH /api/okrs/:okrId` and `PATCH /api/okrs/:okrId/status` update OKR metadata/status for scoped admins and direct-report managers.
- `POST /api/okrs/:okrId/progress` lets employees update progress on their own OKRs.
- `PATCH /api/okrs/:okrId/employee-approve` and `PATCH /api/okrs/:okrId/manager-approve` record employee and manager/admin approval. When both approvals exist, the OKR becomes `APPROVED`.
- CP11 is text-only and does not implement file evidence, document uploads, AI OKR recommendations, reports, analytics, subscriptions, or billing.

## Checkpoint 12 Notes

- `POST/GET/GET:id/PATCH /api/admin/review-cycles` manages company-scoped review cycles for `COMPANY_ADMIN`, `HR_ADMIN`, and explicitly scoped `SUPER_ADMIN`.
- `PATCH /api/admin/review-cycles/:reviewCycleId/status` changes review cycle status without deleting existing reviews.
- `POST /api/reviews/:employeeId/manager-review` creates submitted performance reviews for direct-report managers and scoped admins.
- `GET /api/reviews/me` returns the authenticated employee's own performance reviews.
- `GET /api/reviews/team` returns manager direct-report performance reviews only.
- `GET /api/admin/reviews` returns company-scoped admin performance reviews with optional filters.
- `GET /api/reviews/:reviewId`, `PATCH /api/reviews/:reviewId`, and `PATCH /api/reviews/:reviewId/status` enforce own, direct-report, or company-scoped access.
- CP12 uses simple written summaries and optional 1-5 ratings. It does not implement reports, dashboards, graphs, advanced analytics, AI scoring, AI recommendations, calibration workflows, 360-degree reviews, file/document uploads, subscriptions, or billing.

## Checkpoint 13 Notes

- `GET /api/notifications/me` returns the authenticated user's own notifications with optional status/type/date filters.
- `GET /api/notifications/me/unread-count` returns the authenticated user's unread count.
- `PATCH /api/notifications/:notificationId/read` marks only the authenticated user's notification as read.
- `PATCH /api/notifications/read-all` marks all unread notifications for the authenticated user as read.
- `POST /api/admin/notifications/broadcast` creates in-app notifications for active scoped company recipients for `COMPANY_ADMIN`, `HR_ADMIN`, and explicitly scoped `SUPER_ADMIN`.
- CP13 adds helper functions for future attendance, leave, OKR, and performance review notification creation.
- CP13 is in-app only and does not implement production SMS/email/push delivery, WebSockets, mobile push tokens, cron scheduling, reports, analytics, subscriptions, or billing.

## Checkpoint 14 Notes

- `GET /api/admin/reports/dashboard`, `/attendance`, `/leave`, `/okrs`, and `/performance` return company-scoped admin summaries.
- `GET /api/reports/team/dashboard`, `/attendance`, `/leave`, `/okrs`, and `/performance` return manager direct-report summaries only.
- `GET /api/reports/me/dashboard` returns the authenticated employee's own dashboard summary.
- `GET /api/super-admin/reports/dashboard` and `/companies` return super-admin-only platform and company rollup summaries.
- CP14 is read-only and returns summary JSON only. It does not implement advanced analytics, AI recommendations, report exports, graph generation, WebSockets, background jobs, or custom report builders.
- CP14 report responses do not expose raw GPS coordinates, face/biometric data, leave reasons, performance review summaries/comments, OKR notes/comments, or unrelated employee/user details.

## Checkpoint 15 Notes

- `POST/GET/GET:id/PATCH /api/super-admin/plans` and `PATCH /api/super-admin/plans/:planId/status` manage Basic/Premium subscription plans for `SUPER_ADMIN`.
- `POST /api/super-admin/companies/:companyId/subscription`, `GET /api/super-admin/subscriptions`, `GET /api/super-admin/companies/:companyId/subscription`, and `PATCH /api/super-admin/subscriptions/:subscriptionId/status` manage company subscriptions for `SUPER_ADMIN`.
- `POST/GET /api/super-admin/payment-records` and `GET /api/super-admin/companies/:companyId/payment-records` manage manual payment records for `SUPER_ADMIN`.
- `GET /api/admin/subscription` and `GET /api/admin/payment-records` provide company-scoped billing self-view for `COMPANY_ADMIN` and `HR_ADMIN`.
- CP15 rejects duplicate active company subscriptions with `ACTIVE_SUBSCRIPTION_EXISTS`.
- CP15 does not implement live Stripe charging, webhooks, invoice PDFs, tax, refunds, proration, coupons, automated billing jobs, accounting integrations, card entry, or payment credential storage.

## Checkpoint 16 Notes

- `/api/admin/*` routes remain authenticated and role-gated to documented admin roles.
- `/api/super-admin/*` routes remain `SUPER_ADMIN` only.
- `/api/system/*` internal verification routes remain available only outside production; in `NODE_ENV=production`, they return `404`.
- Normal admin employee creation cannot assign `SUPER_ADMIN`; super-admin creation remains seed/manual-only.
- CP16 verifies representative cross-company, manager direct-report, employee self-access, sensitive response, and audit metadata boundaries.
- CP16 does not add new business modules, frontend code, deployment automation, live payment processing, analytics, or AI recommendations.

## Checkpoint 17 Notes

- CP17 verifies audit write coverage for sensitive state-changing actions across implemented modules.
- `src/lib/audit.ts` sanitizes audit metadata before persistence.
- `src/lib/logger.ts` redacts CP17-sensitive keys case-insensitively.
- `tests/integration/security-audit.test.ts` covers audit coverage, metadata sanitization, log redaction, production internal-route behavior, CORS/JWT/rate-limit guardrails, and regression-suite presence for cross-company/role-boundary coverage.
- CP17 does not expose audit-log read endpoints.
- CP17 does not add new business modules, frontend code, deployment automation, live payment processing, analytics, or AI recommendations.

## Checkpoint 18 Notes

- CP18 adds deploy-ready scripts for Prisma migration deploy and seed aliases.
- Staging/production env validation requires `DATABASE_URL`, `JWT_SECRET`, `JWT_REFRESH_SECRET`, and explicit CORS origins.
- CORS rejects wildcard origins with credentials.
- `/health` remains public and lightweight; `/ready` checks database connectivity when configured.
- `docs/DEPLOYMENT_RUNBOOK.md`, `docs/SMOKE_TEST_CHECKLIST.md`, and `docs/BACKEND_COMPLETION_SUMMARY.md` document staging deployment preparation.
- `docs/FRONTEND_HANDOFF.md` is upgraded from template to CP18 backend handoff, while staging URL and staging accounts remain CP19 values.
- CP18 does not deploy the backend, create Lovable frontend code, add product features, or expose audit-log readers.

## Checkpoint 19 Notes

- CP19 finalizes the backend-to-frontend handoff package for Lovable.
- `docs/LOVABLE_PROMPT.md` contains the prompt to paste into Lovable.
- `docs/FRONTEND_ROUTE_MAP.md` defines frontend screen routes, allowed roles, backend dependencies, loading states, empty states, and common errors.
- `docs/SCREEN_API_MATRIX.md` maps screens to implemented backend endpoints, request-body summaries, auth requirements, response summaries, and error notes.
- `docs/TEST_ACCOUNTS.md` records synthetic staging account placeholders without storing passwords.
- The staging backend URL remains `STAGING_BACKEND_URL=TBD_AFTER_DEPLOYMENT` until deployment supplies the real value.
- CP19 does not add backend product features, frontend code, Lovable-generated screens, mobile code, live Stripe, webhooks, AI recommendations, or advanced analytics.

## Source of Truth

- Product and engineering rules live in `docs/`.
- `docs/CHECKPOINT_LOG.md` controls checkpoint status and pass/fail tracking.
- `docs/API_CONTRACT.md` is the CP19 backend API source of truth for Lovable.
- `docs/ROLE_PERMISSION_MATRIX.md` is the CP19 authorization source of truth.
- `docs/FRONTEND_HANDOFF.md`, `docs/FRONTEND_ROUTE_MAP.md`, `docs/SCREEN_API_MATRIX.md`, `docs/LOVABLE_PROMPT.md`, and `docs/TEST_ACCOUNTS.md` form the Lovable handoff package.
- Lovable generation must wait until the backend is deployed to staging, the real staging URL replaces `STAGING_BACKEND_URL=TBD_AFTER_DEPLOYMENT`, and synthetic staging accounts are created.

## Checkpoint Workflow

1. Read the checkpoint scope and related governance docs.
2. Mark only the active checkpoint `IN_PROGRESS`.
3. Implement only the active checkpoint scope.
4. Run the checkpoint tests plus regression tests.
5. Update the API contract, role matrix, database docs, and handoff docs when applicable.
6. Update `docs/CHECKPOINT_LOG.md` with notes, tests, security review, documentation review, frontend handoff impact, and final signoff.
7. Mark the checkpoint `PASSED`, `FAILED`, or `BLOCKED`.

Do not build business modules before the backend shell, database foundation, authentication, RBAC, and company scoping checkpoints are in place.
