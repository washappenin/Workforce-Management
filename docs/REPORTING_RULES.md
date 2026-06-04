# REPORTING RULES

Rules for reports and dashboard summaries. Implemented at Checkpoint 14.

## Scope

- CP14 report endpoints are read-only.
- CP14 returns summary JSON for frontend dashboards.
- The backend does not render charts or graphs.
- CP14 does not implement advanced analytics, AI recommendations, predictive analytics, PDF export, CSV export, payroll reporting, billing reporting, WebSocket live dashboards, background jobs, data warehouse logic, or custom report builders.

## Admin Company Reports

- Admin report endpoints live under `/api/admin/reports`.
- `COMPANY_ADMIN` and `HR_ADMIN` can view reports for their own company.
- `SUPER_ADMIN` can view admin report endpoints only with explicit safe `companyId`.
- `MANAGER` and `EMPLOYEE` cannot access admin report endpoints.
- Admin report filters such as `employeeId`, `departmentId`, and `reviewCycleId` must resolve inside the scoped company.
- Non-super-admin company overrides are rejected.

## Manager Team Reports

- Manager report endpoints live under `/api/reports/team`.
- `MANAGER` access requires an active employee profile.
- Manager reports use `EmployeeProfile.managerId` and include direct reports only.
- Managers cannot view non-direct-report data.
- Cross-company and cross-team report access is blocked.

## Employee Self Dashboard

- Employee dashboard endpoint lives at `/api/reports/me/dashboard`.
- The endpoint requires authentication and an active employee profile.
- It returns only the authenticated employee's own dashboard summary.
- It does not expose other employees.
- `SUPER_ADMIN` without an employee profile is rejected.

## Super Admin Reports

- Super-admin report endpoints live under `/api/super-admin/reports`.
- `SUPER_ADMIN` can view platform-level counts and company rollups.
- Super-admin rollups do not include raw employee-level sensitive records.
- CP14 company rollups may include company status, employee counts, active employee counts, latest subscription status if available, and `createdAt`.

## Privacy

- Reports must not include raw GPS coordinates.
- Reports must not include raw face images, biometric vectors, provider template references, or face verification payloads.
- Reports must not include leave reasons or review comments.
- Reports must not include performance review summaries.
- Reports must not include OKR progress notes or approval comments.
- Attendance reports return counts and day buckets only.
- Performance reports return summary counts and rating aggregates only.

## Frontend Responsibilities

- Frontend may render charts from summary JSON.
- Frontend must not request raw GPS or biometric data for report screens.
- Frontend must treat backend role checks and scope checks as authoritative.
- Frontend must not infer company-wide or team-wide access from local role labels alone.
