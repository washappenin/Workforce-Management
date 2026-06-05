# FRONTEND ROUTE MAP

CP19 frontend route structure for Lovable. The backend API is the source of truth. Frontend route visibility is usability guidance only; backend authorization remains authoritative.

## Staging Backend URL

```text
STAGING_BACKEND_URL=https://workforce-management-production.up.railway.app
```

## Common State Rules

- Primary loading state: show a scoped page skeleton or compact spinner while the listed backend dependencies are loading.
- Empty state: show the role-specific empty state listed for the screen without creating local fake data.
- Common error states: handle `401`, `403`, `404`, validation errors, `429`, and network/CORS failures. A `401` clears auth and returns to `/login`; a `403` shows access denied.

## Public

| Screen | Route Path | Allowed Roles | Backend Endpoint Dependencies | Primary Loading State | Empty State | Common Error States |
| ------ | ---------- | ------------- | ----------------------------- | --------------------- | ----------- | ------------------- |
| Login | `/login` | Public | `POST /api/auth/login`, `GET /api/auth/me` after token | Submitting credentials | No empty state | `401` invalid credentials, validation error, network/CORS |

## Employee

| Screen | Route Path | Allowed Roles | Backend Endpoint Dependencies | Primary Loading State | Empty State | Common Error States |
| ------ | ---------- | ------------- | ----------------------------- | --------------------- | ----------- | ------------------- |
| Employee dashboard | `/employee/dashboard` | `EMPLOYEE`, plus authenticated users with employee profiles | `GET /api/auth/me`, `GET /api/employees/me`, `GET /api/reports/me/dashboard`, `GET /api/notifications/me/unread-count` | Loading dashboard summary | No employee dashboard data yet | `401`, `403`, `404` missing employee profile, network/CORS |
| Clock in | `/employee/attendance/clock-in` | `EMPLOYEE`, plus authenticated users with employee profiles | `POST /api/face/verify`, `POST /api/attendance/clock-in`, optional `POST /api/geofences/validate-location` | Waiting for camera/GPS and backend response | No open clock-in action available | `401`, `403`, `409` already clocked in, validation, camera/GPS denied |
| Clock out | `/employee/attendance/clock-out` | `EMPLOYEE`, plus authenticated users with employee profiles | `POST /api/attendance/clock-out`, optional `POST /api/geofences/validate-location` | Waiting for GPS and backend response | No open attendance session | `401`, `403`, `404` no open session, validation, GPS denied |
| Face verification | `/employee/face-verification` | `EMPLOYEE`, plus authenticated users with employee profiles | `POST /api/face/verify` | Verifying camera capture | No active face enrollment | `401`, `403`, `404` no enrollment, validation, camera denied |
| Attendance history | `/employee/attendance/history` | `EMPLOYEE`, plus authenticated users with employee profiles | `GET /api/attendance/me` | Loading attendance history | No attendance records | `401`, `403`, validation, network/CORS |
| My shifts | `/employee/shifts` | `EMPLOYEE`, plus authenticated users with employee profiles | `GET /api/shifts/me` | Loading shifts | No upcoming shifts | `401`, `403`, network/CORS |
| Leave request | `/employee/leave/request` | `EMPLOYEE`, plus authenticated users with employee profiles | `POST /api/leave/request`, `GET /api/leave/me` for balances/context | Loading leave balances | No leave balances available | `401`, `403`, validation, overlap/conflict |
| Leave history/balances | `/employee/leave` | `EMPLOYEE`, plus authenticated users with employee profiles | `GET /api/leave/me` | Loading leave records | No leave requests or balances | `401`, `403`, validation, network/CORS |
| My OKRs | `/employee/okrs` | `EMPLOYEE`, plus authenticated users with employee profiles | `GET /api/okrs/me`, `GET /api/okrs/:okrId` | Loading OKRs | No OKRs assigned | `401`, `403`, `404`, validation |
| OKR progress update | `/employee/okrs/:okrId/progress` | `EMPLOYEE`, plus authenticated users with employee profiles | `GET /api/okrs/:okrId`, `POST /api/okrs/:okrId/progress`, `PATCH /api/okrs/:okrId/employee-approve` | Loading OKR detail | OKR not found or no progress yet | `401`, `403`, `404`, validation |
| My performance reviews | `/employee/reviews` | `EMPLOYEE`, plus authenticated users with employee profiles | `GET /api/reviews/me`, `GET /api/reviews/:reviewId` | Loading reviews | No performance reviews yet | `401`, `403`, `404`, network/CORS |
| Notifications | `/employee/notifications` | All authenticated users | `GET /api/notifications/me`, `GET /api/notifications/me/unread-count`, `PATCH /api/notifications/:notificationId/read`, `PATCH /api/notifications/read-all` | Loading notifications | No notifications | `401`, `403`, `404`, validation |

## Manager

| Screen | Route Path | Allowed Roles | Backend Endpoint Dependencies | Primary Loading State | Empty State | Common Error States |
| ------ | ---------- | ------------- | ----------------------------- | --------------------- | ----------- | ------------------- |
| Manager dashboard | `/manager/dashboard` | `MANAGER` | `GET /api/reports/team/dashboard`, `GET /api/notifications/me/unread-count` | Loading team dashboard | No direct-report summary yet | `401`, `403`, network/CORS |
| Team attendance | `/manager/attendance` | `MANAGER` | `GET /api/reports/team/attendance` | Loading team attendance | No team attendance data | `401`, `403`, validation |
| Team leave requests | `/manager/leave` | `MANAGER` | `GET /api/leave/team`, `GET /api/reports/team/leave` | Loading leave requests | No team leave requests | `401`, `403`, network/CORS |
| Approve/reject leave | `/manager/leave/:leaveRequestId` | `MANAGER` | `GET /api/leave/team`, `PATCH /api/leave/:leaveRequestId/approve`, `PATCH /api/leave/:leaveRequestId/reject` | Loading leave request context | Leave request not found | `401`, `403`, `404`, validation |
| Team OKRs | `/manager/okrs` | `MANAGER` | `GET /api/okrs/team`, `GET /api/reports/team/okrs` | Loading team OKRs | No team OKRs | `401`, `403`, network/CORS |
| Assign OKR | `/manager/okrs/new` | `MANAGER` | `POST /api/okrs` | Saving OKR | No direct reports available | `401`, `403`, validation |
| Review/approve OKR | `/manager/okrs/:okrId` | `MANAGER` | `GET /api/okrs/:okrId`, `PATCH /api/okrs/:okrId`, `PATCH /api/okrs/:okrId/status`, `PATCH /api/okrs/:okrId/manager-approve` | Loading OKR detail | OKR not found | `401`, `403`, `404`, validation |
| Team performance reviews | `/manager/reviews` | `MANAGER` | `GET /api/reviews/team`, `GET /api/reports/team/performance` | Loading team reviews | No team reviews | `401`, `403`, network/CORS |
| Submit performance review | `/manager/reviews/:employeeId/new` | `MANAGER` | `POST /api/reviews/:employeeId/manager-review` | Saving review | No active review cycle or employee unavailable | `401`, `403`, `404`, validation/conflict |
| Team reports | `/manager/reports` | `MANAGER` | `GET /api/reports/team/dashboard`, `/attendance`, `/leave`, `/okrs`, `/performance` | Loading team reports | No team report data | `401`, `403`, validation |
| Notifications | `/manager/notifications` | `MANAGER` | `GET /api/notifications/me`, `GET /api/notifications/me/unread-count`, read actions | Loading notifications | No notifications | `401`, `403`, validation |

## HR/Admin

| Screen | Route Path | Allowed Roles | Backend Endpoint Dependencies | Primary Loading State | Empty State | Common Error States |
| ------ | ---------- | ------------- | ----------------------------- | --------------------- | ----------- | ------------------- |
| Admin dashboard | `/admin/dashboard` | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | `GET /api/admin/reports/dashboard` | Loading admin dashboard | No company report data | `401`, `403`, validation |
| Employee management | `/admin/employees` | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | `POST /api/admin/employees`, `GET /api/admin/employees`, `GET /api/admin/employees/:employeeId`, `PATCH /api/admin/employees/:employeeId`, status and manager routes | Loading employees | No employees found | `401`, `403`, `404`, validation/conflict |
| Department management | `/admin/departments` | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | `POST /api/admin/departments`, `GET /api/admin/departments`, detail/update/status routes | Loading departments | No departments | `401`, `403`, `404`, validation |
| Designation management | `/admin/designations` | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | `POST /api/admin/designations`, `GET /api/admin/designations`, detail/update/status routes | Loading designations | No designations | `401`, `403`, `404`, validation |
| Geofence setup | `/admin/geofences` | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | `POST /api/admin/geofences`, `GET /api/admin/geofences`, detail/update/status routes | Loading geofences | No geofences configured | `401`, `403`, `404`, validation |
| Face enrollment | `/admin/employees/:employeeId/face` | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | `GET /api/admin/employees/:employeeId/face-status`, `POST /api/admin/employees/:employeeId/face-enrollment`, `PATCH /api/admin/employees/:employeeId/face-enrollment/status` | Loading face status | No face enrollment | `401`, `403`, `404`, validation, camera unavailable |
| Attendance logs | `/admin/attendance` | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | `GET /api/admin/attendance`, `GET /api/admin/reports/attendance` | Loading attendance logs | No attendance records | `401`, `403`, validation |
| Shift management | `/admin/shifts` | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | Shift CRUD/status, assign/list assignments, update/delete assignments | Loading shifts | No shifts configured | `401`, `403`, `404`, validation |
| Leave types | `/admin/leave/types` | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | Leave type CRUD/status | Loading leave types | No leave types | `401`, `403`, `404`, validation |
| Leave entitlements | `/admin/leave/entitlements` | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | Leave entitlement create/list/detail/update | Loading entitlements | No leave entitlements | `401`, `403`, `404`, validation |
| Leave approvals | `/admin/leave/requests` | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | `GET /api/admin/leave-requests`, approve/reject routes | Loading leave requests | No leave requests | `401`, `403`, `404`, validation |
| OKR management | `/admin/okrs` | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | `GET /api/admin/okrs`, `POST /api/okrs`, OKR detail/update/status/approval routes | Loading OKRs | No company OKRs | `401`, `403`, `404`, validation |
| Review cycles | `/admin/review-cycles` | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | Review cycle CRUD/status | Loading review cycles | No review cycles | `401`, `403`, `404`, validation |
| Company reviews | `/admin/reviews` | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | `GET /api/admin/reviews`, review submit/detail/update/status routes | Loading company reviews | No company reviews | `401`, `403`, `404`, validation |
| Notification broadcast | `/admin/notifications/broadcast` | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | `POST /api/admin/notifications/broadcast` | Sending broadcast | No eligible recipients | `401`, `403`, validation |
| Reports | `/admin/reports` | `COMPANY_ADMIN`, `HR_ADMIN`, scoped `SUPER_ADMIN` | `GET /api/admin/reports/dashboard`, `/attendance`, `/leave`, `/okrs`, `/performance` | Loading reports | No report data | `401`, `403`, validation |
| Subscription view | `/admin/subscription` | `COMPANY_ADMIN`, `HR_ADMIN` | `GET /api/admin/subscription` | Loading subscription | No subscription found | `401`, `403`, `404`, validation |
| Payment history view | `/admin/payment-records` | `COMPANY_ADMIN`, `HR_ADMIN` | `GET /api/admin/payment-records` | Loading payment history | No payment records | `401`, `403`, validation |

## Super Admin

| Screen | Route Path | Allowed Roles | Backend Endpoint Dependencies | Primary Loading State | Empty State | Common Error States |
| ------ | ---------- | ------------- | ----------------------------- | --------------------- | ----------- | ------------------- |
| Super admin dashboard | `/super-admin/dashboard` | `SUPER_ADMIN` | `GET /api/super-admin/reports/dashboard` | Loading platform dashboard | No platform report data | `401`, `403`, network/CORS |
| Company management | `/super-admin/companies` | `SUPER_ADMIN` | `POST /api/super-admin/companies`, `GET /api/super-admin/companies`, detail/update/status routes | Loading companies | No companies | `401`, `403`, `404`, validation |
| Subscription plan management | `/super-admin/plans` | `SUPER_ADMIN` | `POST /api/super-admin/plans`, `GET /api/super-admin/plans`, detail/update/status routes | Loading plans | No subscription plans | `401`, `403`, `404`, validation |
| Company subscription management | `/super-admin/subscriptions` | `SUPER_ADMIN` | `POST /api/super-admin/companies/:companyId/subscription`, `GET /api/super-admin/subscriptions`, `GET /api/super-admin/companies/:companyId/subscription`, `PATCH /api/super-admin/subscriptions/:subscriptionId/status` | Loading subscriptions | No company subscriptions | `401`, `403`, `404`, validation/conflict |
| Manual payment records | `/super-admin/payment-records` | `SUPER_ADMIN` | `POST /api/super-admin/payment-records`, `GET /api/super-admin/payment-records`, `GET /api/super-admin/companies/:companyId/payment-records` | Loading payment records | No payment records | `401`, `403`, `404`, validation |
| Platform reports | `/super-admin/reports` | `SUPER_ADMIN` | `GET /api/super-admin/reports/dashboard`, `GET /api/super-admin/reports/companies` | Loading platform reports | No platform report data | `401`, `403`, network/CORS |
| Company rollups | `/super-admin/company-rollups` | `SUPER_ADMIN` | `GET /api/super-admin/reports/companies` | Loading company rollups | No company rollups | `401`, `403`, network/CORS |
