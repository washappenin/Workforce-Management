# SCREEN API MATRIX

CP19 screen-to-endpoint matrix for Lovable. Every frontend screen must use the implemented backend endpoints listed here and the response/error envelopes defined in `API_CONTRACT.md`.

## Global API Rules

- Base URL: `https://workforce-management-production.up.railway.app`
- Protected requests require `Authorization: Bearer <token>`.
- Success responses use `{ "data": ..., "meta": ... }`.
- Errors use `{ "error": { "code": string, "message": string, "requestId": string, "details"?: unknown } }`.
- Validation errors can return `400` or `422` depending on the route validation path; render field-level details when present.
- Do not invent endpoints or local-only fake data flows.

## Public

| Screen Name | Allowed Roles | Endpoint Method/Path | Request Body If Applicable | Required Auth | Expected Response Shape Summary | Error Handling Notes |
| ----------- | ------------- | -------------------- | -------------------------- | ------------- | ------------------------------- | -------------------- |
| Login | Public | `POST /api/auth/login` | `{ email, password }` | No | `data.user`, `data.accessToken`, `data.tokenType` | `401` generic invalid credentials; validation errors for malformed email/password. |
| Login auth hydration | Public after token | `GET /api/auth/me` | None | Bearer | `data.user` with id, email, companyId, roles, status | `401` clears auth state and returns to login. |

## Employee Screens

| Screen Name | Allowed Roles | Endpoint Method/Path | Request Body If Applicable | Required Auth | Expected Response Shape Summary | Error Handling Notes |
| ----------- | ------------- | -------------------- | -------------------------- | ------------- | ------------------------------- | -------------------- |
| Employee dashboard | `EMPLOYEE`, authenticated users with employee profile | `GET /api/employees/me`; `GET /api/reports/me/dashboard`; `GET /api/notifications/me/unread-count` | None | Bearer | Employee profile, self dashboard summary, unread count | Missing employee profile returns `404`; do not fake profile data. |
| Face verification | `EMPLOYEE`, authenticated users with employee profile | `POST /api/face/verify` | `{ faceScan }` using provider-specific mock/staging capture payload | Bearer | Verification result and short-lived `faceVerificationReference` when successful | Camera denied is a UI state; no enrollment or failed verification must block clock-in. |
| Clock in | `EMPLOYEE`, authenticated users with employee profile | Optional precheck `POST /api/geofences/validate-location`; required write `POST /api/attendance/clock-in` | `{ latitude, longitude, faceVerificationReference }` | Bearer | Open attendance session and clock-in event summary | Requires prior face verification; handle outside geofence, duplicate clock-in, validation, and GPS denied. |
| Clock out | `EMPLOYEE`, authenticated users with employee profile | Optional precheck `POST /api/geofences/validate-location`; required write `POST /api/attendance/clock-out` | `{ latitude, longitude }` | Bearer | Closed attendance session and clock-out event summary | Handle no open session, outside geofence, validation, and GPS denied. |
| Attendance history | `EMPLOYEE`, authenticated users with employee profile | `GET /api/attendance/me` | Query filters only | Bearer | List of own attendance sessions | Empty list means no attendance history. |
| My shifts | `EMPLOYEE`, authenticated users with employee profile | `GET /api/shifts/me` | None | Bearer | List of own current/future shift assignments | Empty list means no upcoming shifts. |
| Leave request | `EMPLOYEE`, authenticated users with employee profile | `GET /api/leave/me`; `POST /api/leave/request` | `{ leaveTypeId, startDate, endDate, reason? }` | Bearer | Own balances/requests, then created leave request | Handle no entitlement, overlap/conflict, validation, and date errors. |
| Leave history/balances | `EMPLOYEE`, authenticated users with employee profile | `GET /api/leave/me` | Query filters only | Bearer | Own leave requests and entitlement balances | Empty list means no leave records yet. |
| My OKRs | `EMPLOYEE`, authenticated users with employee profile | `GET /api/okrs/me`; `GET /api/okrs/:okrId` | Query filters only | Bearer | Own OKR list/detail | Empty list means no assigned OKRs. |
| OKR progress update | `EMPLOYEE`, authenticated users with employee profile | `POST /api/okrs/:okrId/progress`; `PATCH /api/okrs/:okrId/employee-approve` | Progress: `{ progress, note? }`; approval: `{ comment? }` | Bearer | Created progress event or updated OKR approval state | Handle ownership denial, invalid progress, and `404`. |
| My performance reviews | `EMPLOYEE`, authenticated users with employee profile | `GET /api/reviews/me`; `GET /api/reviews/:reviewId` | None | Bearer | Own performance review list/detail | Empty list means no reviews yet. |
| Notifications | All authenticated users | `GET /api/notifications/me`; `GET /api/notifications/me/unread-count`; `PATCH /api/notifications/:notificationId/read`; `PATCH /api/notifications/read-all` | Read actions have no body | Bearer | Notification list, unread count, read-state updates | Only caller-owned notifications can be changed. |

## Manager Screens

| Screen Name | Allowed Roles | Endpoint Method/Path | Request Body If Applicable | Required Auth | Expected Response Shape Summary | Error Handling Notes |
| ----------- | ------------- | -------------------- | -------------------------- | ------------- | ------------------------------- | -------------------- |
| Manager dashboard | `MANAGER` | `GET /api/reports/team/dashboard`; `GET /api/notifications/me/unread-count` | None | Bearer | Direct-report dashboard summary and unread count | `403` for non-managers. |
| Team attendance | `MANAGER` | `GET /api/reports/team/attendance` | Query filters only | Bearer | Direct-report attendance summary | Empty summary means no team attendance records. |
| Team leave requests | `MANAGER` | `GET /api/leave/team`; `GET /api/reports/team/leave` | Query filters only | Bearer | Direct-report leave request list and leave summary | Direct reports only; no admin leave list for managers. |
| Approve/reject leave | `MANAGER` | `PATCH /api/leave/:leaveRequestId/approve`; `PATCH /api/leave/:leaveRequestId/reject` | `{ comment? }` | Bearer | Updated leave request status | `403` if not direct-report manager; `404` if scoped request unavailable. |
| Team OKRs | `MANAGER` | `GET /api/okrs/team`; `GET /api/reports/team/okrs` | Query filters only | Bearer | Direct-report OKR list and OKR summary | Empty list means no team OKRs. |
| Assign OKR | `MANAGER` | `POST /api/okrs` | `{ employeeId, title, description?, startDate?, dueDate?, priority? }` | Bearer | Created OKR | `403` when employee is not a direct report; validation for dates/text. |
| Review/approve OKR | `MANAGER` | `GET /api/okrs/:okrId`; `PATCH /api/okrs/:okrId`; `PATCH /api/okrs/:okrId/status`; `PATCH /api/okrs/:okrId/manager-approve` | Update/status/approval bodies as documented in API contract | Bearer | OKR detail or updated OKR state | Handle direct-report denial, validation, and `404`. |
| Team performance reviews | `MANAGER` | `GET /api/reviews/team`; `GET /api/reports/team/performance` | Query filters only | Bearer | Direct-report review list and performance summary | Empty list means no team reviews. |
| Submit performance review | `MANAGER` | `POST /api/reviews/:employeeId/manager-review` | `{ reviewCycleId, summary, rating?, status? }` | Bearer | Created/submitted performance review | Requires direct report and active review cycle; duplicate review can conflict. |
| Team reports | `MANAGER` | `GET /api/reports/team/dashboard`; `GET /api/reports/team/attendance`; `GET /api/reports/team/leave`; `GET /api/reports/team/okrs`; `GET /api/reports/team/performance` | Query filters where supported | Bearer | Summary JSON reports | Reports are summary JSON only; frontend may chart returned data. |
| Manager notifications | `MANAGER` | Same as notifications self endpoints | None for read actions | Bearer | Own notification list/unread count | Do not create a team-notification endpoint. |

## HR/Admin Screens

| Screen Name | Allowed Roles | Endpoint Method/Path | Request Body If Applicable | Required Auth | Expected Response Shape Summary | Error Handling Notes |
| ----------- | ------------- | -------------------- | -------------------------- | ------------- | ------------------------------- | -------------------- |
| Admin dashboard | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | `GET /api/admin/reports/dashboard` | Optional company-scope query for super-admin | Bearer | Company dashboard summary | Non-super-admin company override is rejected. |
| Employee management | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | `POST /api/admin/employees`; `GET /api/admin/employees`; `GET /api/admin/employees/:employeeId`; `PATCH /api/admin/employees/:employeeId`; `PATCH /api/admin/employees/:employeeId/status`; `PATCH /api/admin/employees/:employeeId/manager` | Create/update/status/manager bodies as documented in API contract | Bearer | Employee profile/user data without password hashes | Normal admins cannot assign `SUPER_ADMIN`; handle duplicate email/code. |
| Department management | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | `POST /api/admin/departments`; `GET /api/admin/departments`; `GET /api/admin/departments/:departmentId`; `PATCH /api/admin/departments/:departmentId`; `PATCH /api/admin/departments/:departmentId/status` | `{ name, code?, description? }`, status update body | Bearer | Department list/detail/update | Scoped by company; handle duplicate names/codes. |
| Designation management | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | `POST /api/admin/designations`; `GET /api/admin/designations`; `GET /api/admin/designations/:designationId`; `PATCH /api/admin/designations/:designationId`; `PATCH /api/admin/designations/:designationId/status` | `{ title, code?, description? }`, status update body | Bearer | Designation list/detail/update | Scoped by company; handle duplicate names/codes. |
| Geofence setup | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | `POST /api/admin/geofences`; `GET /api/admin/geofences`; `GET /api/admin/geofences/:geofenceId`; `PATCH /api/admin/geofences/:geofenceId`; `PATCH /api/admin/geofences/:geofenceId/status` | `{ name, latitude, longitude, radiusMeters }`, update/status bodies | Bearer | Geofence list/detail/update | Do not persist raw GPS outside backend request/response. |
| Face enrollment | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | `GET /api/admin/employees/:employeeId/face-status`; `POST /api/admin/employees/:employeeId/face-enrollment`; `PATCH /api/admin/employees/:employeeId/face-enrollment/status` | Enrollment payload, status body | Bearer | Safe enrollment status without provider subject/template reference | No raw face images or biometric templates in frontend storage. |
| Attendance logs | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | `GET /api/admin/attendance`; `GET /api/admin/reports/attendance` | Query filters only | Bearer | Company attendance sessions and summary | Empty list means no attendance records. |
| Shift management | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | `POST /api/admin/shifts`; `GET /api/admin/shifts`; `GET /api/admin/shifts/:shiftId`; `PATCH /api/admin/shifts/:shiftId`; `PATCH /api/admin/shifts/:shiftId/status`; `POST /api/admin/shifts/:shiftId/assign`; `GET /api/admin/shifts/:shiftId/assignments`; `PATCH /api/admin/shift-assignments/:assignmentId`; `DELETE /api/admin/shift-assignments/:assignmentId` | Shift and assignment bodies as documented | Bearer | Shift and assignment list/detail/update | Handle inactive shift/employee and overlapping assignment errors. |
| Leave types | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | Leave type CRUD/status endpoints under `/api/admin/leave-types` | Leave type create/update/status bodies | Bearer | Leave type list/detail/update | Empty list means no leave types. |
| Leave entitlements | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | Leave entitlement create/list/detail/update under `/api/admin/leave-entitlements` | `{ employeeId, leaveTypeId, year, totalDays }` and update body | Bearer | Entitlement list/detail/update | Upsert behavior for duplicate employee/type/year. |
| Leave approvals | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | `GET /api/admin/leave-requests`; approve/reject routes under `/api/leave/:leaveRequestId/*` | Approval/rejection `{ comment? }` | Bearer | Leave request list and updated review status | Handle pending-only review and scoped access. |
| OKR management | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | `GET /api/admin/okrs`; `POST /api/okrs`; OKR detail/update/status/manager-approve routes | OKR create/update/status/approval bodies | Bearer | Company OKR list/detail/update | Text-only; no file evidence or AI recommendations. |
| Review cycles | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | Review cycle CRUD/status endpoints under `/api/admin/review-cycles` | Review cycle create/update/status bodies | Bearer | Review cycle list/detail/update | Validate cycle dates/status. |
| Company reviews | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | `GET /api/admin/reviews`; `POST /api/reviews/:employeeId/manager-review`; `GET/PATCH /api/reviews/:reviewId`; `PATCH /api/reviews/:reviewId/status` | Review submit/update/status bodies | Bearer | Company review list/detail/update | Requires valid employee/review cycle and scoped reviewer rules. |
| Notification broadcast | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | `POST /api/admin/notifications/broadcast` | `{ title, message, type?, recipientRole? }` | Bearer | Broadcast creation/completion summary | In-app only; no SMS/email/push delivery. |
| Reports | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | `GET /api/admin/reports/dashboard`; `/attendance`; `/leave`; `/okrs`; `/performance` | Query filters where supported | Bearer | Company summary JSON | No export, graph, AI, or advanced analytics endpoints. |
| Subscription view | `COMPANY_ADMIN`, `HR_ADMIN` | `GET /api/admin/subscription` | Optional query filters | Bearer | Current/latest company subscription with plan summary | Managers/employees denied. |
| Payment history view | `COMPANY_ADMIN`, `HR_ADMIN` | `GET /api/admin/payment-records` | Optional query filters | Bearer | Company payment records without provider references | No card entry or payment credential display. |

## Super Admin Screens

| Screen Name | Allowed Roles | Endpoint Method/Path | Request Body If Applicable | Required Auth | Expected Response Shape Summary | Error Handling Notes |
| ----------- | ------------- | -------------------- | -------------------------- | ------------- | ------------------------------- | -------------------- |
| Super admin dashboard | `SUPER_ADMIN` | `GET /api/super-admin/reports/dashboard` | None | Bearer | Platform dashboard summary | `403` for all other roles. |
| Company management | `SUPER_ADMIN` | `POST /api/super-admin/companies`; `GET /api/super-admin/companies`; `GET /api/super-admin/companies/:companyId`; `PATCH /api/super-admin/companies/:companyId`; `PATCH /api/super-admin/companies/:companyId/status` | Company create/update/status bodies | Bearer | Company list/detail/update | Handle duplicate company values and invalid status. |
| Subscription plan management | `SUPER_ADMIN` | `POST /api/super-admin/plans`; `GET /api/super-admin/plans`; `GET /api/super-admin/plans/:planId`; `PATCH /api/super-admin/plans/:planId`; `PATCH /api/super-admin/plans/:planId/status` | Plan create/update/status bodies | Bearer | Plan list/detail/update | No live Stripe; plans are backend records only. |
| Company subscription management | `SUPER_ADMIN` | `POST /api/super-admin/companies/:companyId/subscription`; `GET /api/super-admin/subscriptions`; `GET /api/super-admin/companies/:companyId/subscription`; `PATCH /api/super-admin/subscriptions/:subscriptionId/status` | Subscription assignment/status bodies | Bearer | Company subscription list/current/update | Handle inactive plan and active subscription conflict. |
| Manual payment records | `SUPER_ADMIN` | `POST /api/super-admin/payment-records`; `GET /api/super-admin/payment-records`; `GET /api/super-admin/companies/:companyId/payment-records` | Manual payment record body | Bearer | Payment record list/create response | Manual records only; no card/bank/Stripe credential collection. |
| Platform reports | `SUPER_ADMIN` | `GET /api/super-admin/reports/dashboard`; `GET /api/super-admin/reports/companies` | None | Bearer | Platform summary and company rollups | Summary JSON only. |
| Company rollups | `SUPER_ADMIN` | `GET /api/super-admin/reports/companies` | None | Bearer | Company rollup list, including employee-count context | No usage-metering endpoint exists. |

## Public System Endpoints For Deploy Checks

| Screen Name | Allowed Roles | Endpoint Method/Path | Request Body If Applicable | Required Auth | Expected Response Shape Summary | Error Handling Notes |
| ----------- | ------------- | -------------------- | -------------------------- | ------------- | ------------------------------- | -------------------- |
| Liveness check | Public operational check | `GET /health` | None | No | `data.status = "ok"` and uptime/timestamp | Used by deployment smoke checks, not an app screen. |
| Readiness check | Public operational check | `GET /ready` | None | No | `data.status`, timestamp, database check | `503` means configured dependency is not ready. |

## Disabled Production Internal Routes

`/api/system/*` routes are internal verification routes and must not be used by Lovable. In production they return `404`.
