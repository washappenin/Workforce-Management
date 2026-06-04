# PERFORMANCE REVIEW RULES

Rules for performance review management. Implemented at Checkpoint 12.

## Scope

- CP12 supports simple manager/admin-driven performance reviews.
- Reviews may reference OKR outcomes in summary text, but CP12 does not calculate OKR scores.
- CP12 does not implement reports, dashboards, graph generation, advanced analytics, AI scoring, AI recommendations, payroll, subscriptions, billing, notifications, external document uploads, calibration workflows, or 360-degree reviews.

## Review Cycles

- Review cycle management uses `/api/admin/review-cycles`.
- `COMPANY_ADMIN` and `HR_ADMIN` can create, list, read, update, and change status for review cycles inside their company.
- `SUPER_ADMIN` can use review cycle routes only with explicit safe `companyId`.
- `MANAGER` and `EMPLOYEE` cannot manage review cycles.
- `name`, `startDate`, and `endDate` are required on create.
- `endDate` must be on or after `startDate`.
- Review cycles are company scoped.
- Review cycle status must use `ReviewCycleStatus`: `DRAFT`, `ACTIVE`, `CLOSED`, `ARCHIVED`.
- Closing or archiving a cycle does not delete existing performance reviews.
- CP12 does not automatically create reviews for every employee.

## Review Submission

- Manager/admin review submission uses `POST /api/reviews/:employeeId/manager-review`.
- `MANAGER` can submit reviews only for direct reports through `EmployeeProfile.managerId`.
- `COMPANY_ADMIN` and `HR_ADMIN` can submit reviews for employees in their company.
- `SUPER_ADMIN` submission requires explicit safe `companyId` and an employee profile in the target company because `PerformanceReview.managerId` is required by the schema.
- `EMPLOYEE` cannot submit manager reviews.
- The target employee must be active and must belong to the resolved company.
- The review cycle must belong to the resolved company and must be `ACTIVE`.
- CP12 rejects duplicate reviews for the same `employeeId` and `reviewCycleId`.
- Submitted manager reviews are created with status `SUBMITTED` and `submittedAt` set.

## Rating Model

- `summary` is required and capped at a sane maximum length.
- `rating` is optional.
- When provided, `rating` must be a simple numeric value from `1` to `5`.
- CP12 does not generate ratings automatically and does not provide AI scoring.

## Visibility

- `GET /api/reviews/me` returns the authenticated employee profile's own reviews.
- `GET /api/reviews/team` returns manager direct-report reviews only.
- `GET /api/admin/reviews` returns company-scoped reviews for `COMPANY_ADMIN`, `HR_ADMIN`, and explicitly scoped `SUPER_ADMIN`.
- `GET /api/reviews/:reviewId` allows the reviewed employee, direct manager, company admin/HR, or scoped super-admin to read the review.
- Cross-company review and employee existence must not be exposed.

## Review Updates and Status

- `PATCH /api/reviews/:reviewId` updates `summary` and `rating` only.
- CP12 does not allow changing `employeeId`, `reviewCycleId`, or `managerId`.
- `MANAGER` can update direct-report reviews while editable.
- `COMPANY_ADMIN` and `HR_ADMIN` can update company reviews.
- `EMPLOYEE` cannot update performance reviews.
- Reviews with status `ACKNOWLEDGED` or `ARCHIVED` are not editable.
- `PATCH /api/reviews/:reviewId/status` changes status using `PerformanceReviewStatus`: `DRAFT`, `SUBMITTED`, `ACKNOWLEDGED`, `ARCHIVED`.
- When status becomes `SUBMITTED`, `ACKNOWLEDGED`, or `ARCHIVED`, `submittedAt` is set if it was not already set.

## Privacy and Audit

- Performance review summaries are HR-sensitive.
- Audit logs are written for review cycle create/update/status changes and performance review submit/update/status changes.
- Audit metadata must contain only minimal references such as `employeeId`, `managerId`, `reviewCycleId`, status, and rating.
- Long review summaries must not be written to audit metadata or logs.
- Review visibility and permissions are enforced by the backend; frontend role guards are not a security boundary.
