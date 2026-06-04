# LEAVE RULES

Rules for leave management. Implemented at Checkpoint 10.

## Leave Types

- Leave types are configured per company under `/api/admin/leave-types`.
- `COMPANY_ADMIN` and `HR_ADMIN` manage leave types only inside their authenticated company.
- `SUPER_ADMIN` must provide explicit safe `companyId`.
- `MANAGER` and `EMPLOYEE` cannot manage leave types.
- Leave type names are unique within a company.
- `defaultAnnualAllowance` is optional and must be non-negative.
- Deactivating a leave type does not delete historical leave requests or entitlements.

## Entitlements

- Entitlements are configured per employee, leave type, and year under `/api/admin/leave-entitlements`.
- Employee and leave type must belong to the resolved company scope.
- Employee must be active.
- Leave type must be active.
- `totalDays` and `usedDays` must be non-negative, and `usedDays` cannot exceed `totalDays`.
- CP10 uses upsert behavior for duplicate `employeeId + leaveTypeId + year`: an existing entitlement is updated.

## Employee Requests

- `POST /api/leave/request` is self-service only.
- Users must have an active `EmployeeProfile` and active company.
- `SUPER_ADMIN` without an employee profile is rejected.
- Leave type must be active and belong to the user's company.
- Dates use `YYYY-MM-DD`.
- CP10 uses full-day inclusive calendar day counting.
- CP10 does not support partial-day leave.
- Requests must stay within one entitlement year.
- CP10 uses a `NO_ENTITLEMENT` policy: if no matching entitlement exists for the request year, request creation is rejected.
- Requested days cannot exceed remaining entitlement balance.
- `usedDays` is not updated until approval.
- Overlapping pending or approved requests for the same employee are rejected.

## Review Flow

- Leave requests start as `PENDING`.
- `MANAGER` may view and review direct-report requests only. Direct reports are determined by `EmployeeProfile.managerId`.
- `HR_ADMIN` and `COMPANY_ADMIN` may review requests inside their company.
- `SUPER_ADMIN` may review with explicit safe `companyId`.
- `EMPLOYEE` cannot approve or reject leave.
- Only `PENDING` requests can be approved or rejected.
- Approval sets `APPROVED`, `reviewedById`, `reviewedAt`, and optional `reviewComment`.
- Approval increments `LeaveEntitlement.usedDays` after checking current remaining balance.
- Rejection sets `REJECTED`, `reviewedById`, `reviewedAt`, and optional `reviewComment`.
- Rejection does not increment `usedDays`.

## Privacy

- Leave reasons and review comments are sensitive HR data.
- Leave reasons and review comments must not be written to audit metadata.
- Leave data is company-scoped and must not expose cross-company records.

## Out of Scope for CP10

- Payroll integration.
- Automatic payroll deductions.
- Holiday calendars.
- Calendar integrations.
- Partial-day leave.
- Complex accrual policies.
- Advanced carryover rules.
- OKRs, performance reviews, reports, subscriptions, and billing.

## Endpoints

- `POST /api/admin/leave-types`
- `GET /api/admin/leave-types`
- `GET /api/admin/leave-types/:leaveTypeId`
- `PATCH /api/admin/leave-types/:leaveTypeId`
- `PATCH /api/admin/leave-types/:leaveTypeId/status`
- `POST /api/admin/leave-entitlements`
- `GET /api/admin/leave-entitlements`
- `GET /api/admin/leave-entitlements/:entitlementId`
- `PATCH /api/admin/leave-entitlements/:entitlementId`
- `POST /api/leave/request`
- `GET /api/leave/me`
- `GET /api/leave/team`
- `GET /api/admin/leave-requests`
- `PATCH /api/leave/:leaveRequestId/approve`
- `PATCH /api/leave/:leaveRequestId/reject`

## Testing

- CP10 integration tests cover leave type management, entitlement upsert/update, self-service request creation, `NO_ENTITLEMENT`, overlap rejection, manager direct-report visibility/review, HR/Admin review, cross-company isolation, audit logging, and regression with earlier suites.
