# ROLE PERMISSION MATRIX

Binding source of truth for authorization. The frontend (Lovable) derives route guards and permission-denied states from this document. CP19 freezes this matrix for frontend handoff using staging URL `https://workforce-management-production.up.railway.app`.

## Roles

| Role | Scope | Summary |
| ---- | ----- | ------- |
| `SUPER_ADMIN` | System-wide (cross-company, audited) | Manage companies, plans, subscriptions, system reports, onboarding. |
| `COMPANY_ADMIN` | Single company | Full management within their company. |
| `HR_ADMIN` | Single company | Manage employees, departments, designations, leave config, shifts, geofences, attendance logs, reports. |
| `MANAGER` | Team within company | Team dashboards, approve/reject leave, assign/review OKRs, submit performance reviews. |
| `EMPLOYEE` | Self | Clock in/out, view own attendance, submit leave, update OKR progress, view reviews, notifications. |

## Authorization Principles

- Deny-by-default. Access must be explicitly granted.
- Least privilege per role.
- Company scope derived from the authenticated token, never the request body.
- `SUPER_ADMIN` cross-company access is explicit and audited.
- Employees cannot self-register or create other accounts.
- CP4 enforces endpoint-level RBAC through role middleware and company-scope middleware.
- Authentication middleware refreshes the active user from the repository before protected route handlers use `req.user.roles`, so role checks do not rely only on stale token claims.
- Client-supplied `companyId` in params, body, or query can request a scope but cannot override the authenticated user scope.

## CP4 Implementation Status

Implemented in CP4:

- `requireRole`, `requireAnyRole`, and named role middleware for all five core roles.
- Company scoping middleware that attaches `req.companyScope`.
- Pure authorization helpers for role checks and same-company checks.
- Permission constants for future permission-based middleware and dynamic permission management.
- Internal system/security verification routes under `/api/system/*`.

Not implemented in CP4:

- Dynamic permission assignment APIs.
- Employee, attendance, leave, OKR, face verification, report, subscription, admin dashboard, or audit-log product endpoints.

## CP5 Implementation Status

Implemented in CP5:

- `SUPER_ADMIN` company management under `/api/super-admin/companies`.
- Company-scoped department and designation management under `/api/admin/departments` and `/api/admin/designations`.
- Admin-controlled employee account/profile creation under `/api/admin/employees`.
- Manager assignment through `/api/admin/employees/:employeeId/manager`.
- Employee activation/deactivation through `/api/admin/employees/:employeeId/status`.
- Self employee profile access through `/api/employees/me`.
- Audit log writes for company, department, designation, employee, status, and manager-change actions.

CP5 limitations:

- Managers cannot use admin employee management endpoints yet.
- Employees cannot use admin employee management endpoints and can only read their own profile.
- No public self-registration endpoint exists.
- No CP7+ attendance, leave, OKR, face verification, report, subscription, or billing features are implemented.

## CP6 Implementation Status

Implemented in CP6:

- Company-scoped geofence setup under `/api/admin/geofences`.
- Location validation under `/api/geofences/validate-location`.
- Circular geofence distance checks using latitude, longitude, radius, and the Haversine formula.
- Audit log writes for geofence create, update, and status changes.

CP6 limitations:

- `MANAGER` and `EMPLOYEE` cannot manage geofence setup.
- `EMPLOYEE`, `MANAGER`, `HR_ADMIN`, and `COMPANY_ADMIN` can validate locations only against their authenticated company.
- `SUPER_ADMIN` can manage or validate geofences only with explicit safe `companyId` context.
- CP6 does not create attendance, location ping, or face verification records.

## CP7 Implementation Status

Implemented in CP7:

- Self-service clock-in under `/api/attendance/clock-in`.
- Self-service clock-out under `/api/attendance/clock-out`.
- Own attendance history under `/api/attendance/me`.
- Company attendance listing under `/api/admin/attendance` for `COMPANY_ADMIN`, `HR_ADMIN`, and explicitly scoped `SUPER_ADMIN`.
- `AttendanceEvent` records for `CLOCK_IN` and `CLOCK_OUT`.

CP7 limitations:

- `SUPER_ADMIN` cannot clock in or out in CP7.
- Users cannot clock in or out for another employee.
- Manager team attendance is not implemented in CP7.
- Continuous GPS tracking and geofence breach records are not implemented in CP7.

## CP8 Implementation Status

Implemented in CP8:

- Admin face enrollment create/update/status under `/api/admin/employees/:employeeId/face-*`.
- Self-service face verification under `/api/face/verify`.
- Vendor-agnostic face adapter interfaces with the safe development `mock` provider.
- Short-lived face verification references consumed by `POST /api/attendance/clock-in`.
- Audit log writes for face enrollment create/update/status changes.

CP8 limitations:

- `SUPER_ADMIN` can manage face enrollment only with explicit safe `companyId`.
- `COMPANY_ADMIN` and `HR_ADMIN` manage face enrollment only inside their company.
- `MANAGER` and `EMPLOYEE` cannot manage face enrollment through admin routes.
- Verification is self-service only and requires an active employee profile plus active enrollment.
- Real vendor integration, liveness checks, consent records, and deletion/offboarding workflows are deferred.

## CP9 Implementation Status

Implemented in CP9:

- Company-scoped shift management under `/api/admin/shifts`.
- Shift assignment and assignment removal under `/api/admin/shifts/:shiftId/assign`, `/api/admin/shifts/:shiftId/assignments`, and `/api/admin/shift-assignments/:assignmentId`.
- Employee self-view under `/api/shifts/me`.
- Audit log writes for shift create/update/status and assignment create/update/remove actions.

CP9 limitations:

- `SUPER_ADMIN` must provide explicit safe `companyId` for admin shift and assignment routes.
- `COMPANY_ADMIN` and `HR_ADMIN` manage shifts and assignments only inside their company.
- `MANAGER` and `EMPLOYEE` cannot use admin shift management or assignment routes.
- `GET /api/shifts/me` returns only the authenticated user's own current/future assignments and requires an employee profile.
- Advanced scheduling, recurring calendars, payroll, overtime, and attendance-time enforcement are not implemented in CP9.

## CP10 Implementation Status

Implemented in CP10:

- Company-scoped leave type management under `/api/admin/leave-types`.
- Company-scoped leave entitlement upsert/list/detail/update under `/api/admin/leave-entitlements`.
- Employee self-service request/list under `/api/leave/request` and `/api/leave/me`.
- Manager direct-report leave list under `/api/leave/team`.
- Company admin/HR admin leave request list under `/api/admin/leave-requests`.
- Approve/reject under `/api/leave/:leaveRequestId/approve` and `/api/leave/:leaveRequestId/reject`.
- Audit log writes for leave type, entitlement, request submission, approval, and rejection actions.

CP10 limitations:

- `SUPER_ADMIN` must provide explicit safe `companyId` for admin leave and review routes.
- `MANAGER` review is limited to direct reports through `EmployeeProfile.managerId`.
- `NO_ENTITLEMENT` policy is enforced for self-service requests.
- Approval increments `usedDays`; rejection does not.
- Payroll, partial-day leave, holiday calendars, calendar integrations, accruals, carryover, OKRs, reviews, reports, subscriptions, and billing are not implemented.

## CP11 Implementation Status

Implemented in CP11:

- Text-only OKR assignment under `/api/okrs`.
- Own OKR list under `/api/okrs/me`.
- Manager direct-report OKR list under `/api/okrs/team`.
- Company OKR list under `/api/admin/okrs`.
- OKR detail/update/status/progress/employee approval/manager approval routes under `/api/okrs/:okrId/*`.
- Audit log writes for OKR create/update/status/progress/employee approval/manager approval actions.

CP11 limitations:

- `SUPER_ADMIN` can list/read/update scoped OKRs with explicit safe `companyId`, but assignment and approval require an employee profile in the target company because the schema requires employee-profile references.
- `MANAGER` assignment, updates, status changes, and manager approval are limited to direct reports.
- Employee progress and employee approval are self-service only.
- File uploads, document evidence, AI recommendations, advanced analytics, graph generation, reports, subscriptions, and billing are not implemented.

## CP12 Implementation Status

Implemented in CP12:

- Review cycle create/list/detail/update/status under `/api/admin/review-cycles`.
- Manager/admin performance review submission under `/api/reviews/:employeeId/manager-review`.
- Own review list under `/api/reviews/me`.
- Manager direct-report review list under `/api/reviews/team`.
- Company review list under `/api/admin/reviews`.
- Review detail/update/status routes under `/api/reviews/:reviewId/*`.
- Audit log writes for review cycle create/update/status and performance review submit/update/status actions.

CP12 limitations:

- `SUPER_ADMIN` can list/read/update scoped review data with explicit safe `companyId`, but review submission requires an employee profile in the target company because the schema requires `managerId`.
- `MANAGER` review submission, review updates, and review status changes are limited to direct reports.
- `EMPLOYEE` can read only their own performance reviews.
- Reports, dashboards, graph generation, advanced analytics, AI scoring, AI recommendations, calibration workflows, 360-degree reviews, file/document uploads, subscriptions, and billing are not implemented.

## CP13 Implementation Status

Implemented in CP13:

- Own notification list under `/api/notifications/me`.
- Own unread count under `/api/notifications/me/unread-count`.
- Mark own notification read under `/api/notifications/:notificationId/read`.
- Mark all own unread notifications read under `/api/notifications/read-all`.
- Company-scoped admin broadcast under `/api/admin/notifications/broadcast`.
- Internal helper functions for future attendance, leave, OKR, and performance review notification creation.
- Audit log writes for notification broadcast create/completion actions.

CP13 limitations:

- In-app notifications only.
- `SUPER_ADMIN` broadcast requires explicit safe `companyId`.
- Admin broadcast recipients are active employee profiles with active users in an active company.
- Production SMS, email, push notifications, WebSockets, cron scheduling, mobile push tokens, reports, subscriptions, and billing are not implemented.

## CP14 Implementation Status

Implemented in CP14:

- Company admin/HR dashboard and report summaries under `/api/admin/reports/*`.
- Manager direct-report dashboard and report summaries under `/api/reports/team/*`.
- Employee self dashboard under `/api/reports/me/dashboard`.
- Super-admin platform dashboard and company rollups under `/api/super-admin/reports/*`.
- Read-only summary reports for attendance, leave, OKRs, and performance reviews.

CP14 limitations:

- Reports are summary JSON only.
- The backend does not render graphs or charts.
- Advanced analytics, AI recommendations, predictive analytics, PDF/CSV exports, payroll reporting, billing reporting, WebSockets, background jobs, data warehouse logic, and custom report builders are not implemented.
- Report rollups exclude raw GPS coordinates, biometric data, leave reasons, review comments, performance review summaries, OKR notes/comments, and unrelated employee/user details.

## CP15 Implementation Status

Implemented in CP15:

- Super-admin subscription plan management under `/api/super-admin/plans`.
- Super-admin company subscription assignment/status tracking under `/api/super-admin/companies/:companyId/subscription` and `/api/super-admin/subscriptions`.
- Super-admin manual payment records under `/api/super-admin/payment-records` and `/api/super-admin/companies/:companyId/payment-records`.
- Company admin/HR billing self-view under `/api/admin/subscription` and `/api/admin/payment-records`.

CP15 limitations:

- Live Stripe charging, payment collection, webhooks, invoice PDFs, tax, refunds, proration, coupons, automated billing jobs, and accounting integrations are not implemented.
- Managers and employees cannot view billing endpoints.
- Company-admin payment self-view omits provider references.
- Sensitive payment credentials must not be stored or logged.

## CP16 Hardening Status

Verified in CP16:

- `/api/admin/*` routes require authentication and documented admin roles.
- `/api/super-admin/*` routes require `SUPER_ADMIN`.
- Non-super-admin `companyId` overrides are rejected across representative admin modules.
- Manager direct-report boundaries are enforced across leave, OKR, review, and report access.
- Employee self-access boundaries reject team/admin/super-admin and other-employee actions.
- Normal admin employee creation cannot assign `SUPER_ADMIN`.
- Internal `/api/system/*` verification routes are disabled in production.
- Sensitive response and audit metadata restrictions are tested for representative routes.

## CP17 Security Audit Status

Verified in CP17:

- Sensitive state-changing actions across organization, geofence, face enrollment, shifts, leave, OKR, performance review, notification broadcast, subscriptions, and payment modules have audit write coverage.
- Attendance clock-in/out uses `AttendanceEvent` operational records rather than per-clock audit logs.
- Audit metadata is centrally sanitized before persistence to remove credentials, tokens, provider references, raw GPS keys, biometric fields, leave/review/OKR comments, notification message bodies, and sensitive payment fields.
- Logger redaction is case-insensitive for CP17-sensitive keys.
- Existing company-scoped module suites remain the regression source for cross-company isolation and role-boundary enforcement.
- `/api/system/*` remains production-disabled while `/health` and `/ready` remain public.
- CP17 does not add an audit-log read endpoint. Audit-log viewing remains unavailable until a future checkpoint explicitly scopes, redacts, documents, and tests it.

## Frontend Route Visibility Guidance

- Public users can see only `/login`.
- `EMPLOYEE` users can see employee self-service routes.
- `MANAGER` users can see manager routes plus their own employee self-service routes when they have an employee profile.
- `COMPANY_ADMIN` and `HR_ADMIN` users can see admin routes plus their own employee self-service routes when they have an employee profile.
- `SUPER_ADMIN` users can see super-admin routes and explicitly scoped admin routes when a company context is selected.
- Hiding routes is usability only. Backend auth, RBAC, manager-direct-report checks, and company scoping remain the security boundary.
- Do not create frontend routes outside `FRONTEND_ROUTE_MAP.md` unless `API_CONTRACT.md` is updated first.

## Permission Matrix (CP19 Frozen)

Legend: `ALLOW` allowed; `DENY` denied; `COMPANY` own company only; `SELF` self only; `TEAM` team only.

| Capability | SUPER_ADMIN | COMPANY_ADMIN | HR_ADMIN | MANAGER | EMPLOYEE |
| ---------- | :---------: | :-----------: | :------: | :-----: | :------: |
| Manage companies | ALLOW | DENY | DENY | DENY | DENY |
| Company onboarding | ALLOW | DENY | DENY | DENY | DENY |
| Manage subscription plans | ALLOW | DENY | DENY | DENY | DENY |
| Assign company subscription | ALLOW | DENY | DENY | DENY | DENY |
| View own company subscription | ALLOW | COMPANY | COMPANY | DENY | DENY |
| Manage payment records | ALLOW | DENY | DENY | DENY | DENY |
| View own company payment records | ALLOW | COMPANY | COMPANY | DENY | DENY |
| System-level reports | ALLOW | DENY | DENY | DENY | DENY |
| Create/manage employees | ALLOW | COMPANY | COMPANY | DENY | DENY |
| Manage departments/designations | ALLOW | COMPANY | COMPANY | DENY | DENY |
| Assign roles | ALLOW | COMPANY | COMPANY | DENY | DENY |
| Assign managers | ALLOW | COMPANY | COMPANY | DENY | DENY |
| View own employee profile | SELF | SELF | SELF | SELF | SELF |
| Manage geofences | ALLOW | COMPANY | COMPANY | DENY | DENY |
| Validate own company location | COMPANY | COMPANY | COMPANY | COMPANY | COMPANY |
| Manage shifts / assign shifts | ALLOW | COMPANY | COMPANY | DENY | DENY |
| View own shift | SELF | SELF | SELF | SELF | SELF |
| Configure leave types/entitlements | ALLOW | COMPANY | COMPANY | DENY | DENY |
| Submit leave request | DENY | SELF | SELF | SELF | SELF |
| Approve/reject leave | ALLOW | COMPANY | COMPANY | TEAM | DENY |
| Clock in/out | DENY | SELF | SELF | SELF | SELF |
| View own attendance | DENY | SELF | SELF | SELF | SELF |
| View attendance logs (others) | ALLOW | COMPANY | COMPANY | DENY | DENY |
| Manage face enrollment | ALLOW | COMPANY | COMPANY | DENY | DENY |
| Verify own face | DENY | SELF | SELF | SELF | SELF |
| Assign OKRs | ALLOW | COMPANY | COMPANY | TEAM | DENY |
| Update OKR progress | DENY | DENY | DENY | SELF | SELF |
| Employee-approve own OKRs | DENY | SELF | SELF | SELF | SELF |
| Manager/admin approve OKRs | ALLOW | COMPANY | COMPANY | TEAM | DENY |
| Configure review cycles | ALLOW | COMPANY | COMPANY | DENY | DENY |
| Submit performance reviews | ALLOW | COMPANY | COMPANY | TEAM | DENY |
| View own performance review | SELF | SELF | SELF | SELF | SELF |
| View team/company performance reviews | ALLOW | COMPANY | COMPANY | TEAM | DENY |
| Update performance reviews | ALLOW | COMPANY | COMPANY | TEAM | DENY |
| View notifications | SELF | SELF | SELF | SELF | SELF |
| Broadcast notifications | ALLOW | COMPANY | COMPANY | DENY | DENY |
| Core reports / admin dashboard | ALLOW | COMPANY | COMPANY | TEAM | DENY |
| View own dashboard report | SELF | SELF | SELF | SELF | SELF |
| Super-admin platform reports | ALLOW | DENY | DENY | DENY | DENY |
| Read audit logs | DENY | DENY | DENY | DENY | DENY |

> Notes: Cells marked `COMPANY`, `TEAM`, or `SELF` are still subject to deny-by-default and tenant scoping. Audit-log read access is `DENY` for all roles because no audit-log read endpoint exists. Exact endpoint-level enforcement is documented in `API_CONTRACT.md`; Lovable route mapping is documented in `FRONTEND_ROUTE_MAP.md` and `SCREEN_API_MATRIX.md`. Backend authorization remains the source of truth.
