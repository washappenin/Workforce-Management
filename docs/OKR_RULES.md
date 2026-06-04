# OKR RULES

Rules for OKR management. Implemented at Checkpoint 11.

## MVP Scope

- OKRs are text-based only.
- CP11 does not support file uploads, document submissions, or evidence attachments.
- CP11 does not implement AI OKR recommendations, advanced analytics, graph generation, performance reviews, reports, subscriptions, or billing.

## Assignment Rules

- OKR assignment uses `POST /api/okrs`.
- `COMPANY_ADMIN` and `HR_ADMIN` can assign OKRs to active employees inside their company.
- `MANAGER` can assign OKRs only to direct reports through `EmployeeProfile.managerId`.
- `SUPER_ADMIN` can participate only with explicit safe company scope and an employee profile in the target company, because the CP2 schema requires `assignedById`.
- `EMPLOYEE` cannot assign OKRs.
- OKRs start with status `ASSIGNED`.

## Visibility

- `GET /api/okrs/me` returns the authenticated employee's own OKRs.
- `GET /api/okrs/team` returns manager direct-report OKRs only.
- `GET /api/admin/okrs` returns company-scoped OKRs for `COMPANY_ADMIN`, `HR_ADMIN`, and explicitly scoped `SUPER_ADMIN`.
- `GET /api/okrs/:okrId` allows own, direct-report, company admin/HR, and scoped super-admin reads.
- Cross-company visibility is blocked.

## Progress Updates

- Progress updates use `POST /api/okrs/:okrId/progress`.
- Employees update progress only for their own OKRs.
- `progressPercent` must be from `0` to `100`.
- `note` is optional.
- CP11 creates an `OKRProgressUpdate` record for each update.
- If an OKR is `ASSIGNED` and progress is greater than `0`, CP11 changes status to `IN_PROGRESS`.
- Progress updates do not accept file evidence or document uploads.

## Approval Flow

- Employee confirmation uses `PATCH /api/okrs/:okrId/employee-approve`.
- Employee approval is self-service only for the OKR owner.
- Manager/admin approval uses `PATCH /api/okrs/:okrId/manager-approve`.
- `MANAGER` can manager-approve only direct-report OKRs.
- `COMPANY_ADMIN` and `HR_ADMIN` can manager-approve company OKRs.
- `SUPER_ADMIN` approval requires explicit company scope and an employee profile in the target company because `OKRApproval.approverEmployeeId` is required.
- `EMPLOYEE` cannot manager-approve.
- Approvals create or update `OKRApproval` records with status `APPROVED`.
- Employee approval alone moves the OKR to `SUBMITTED` unless it is already `APPROVED`.
- Once both employee approval and a manager/admin approval exist, CP11 moves the OKR to `APPROVED`.

## Metadata and Status Control

- `PATCH /api/okrs/:okrId` updates title, description, and due date.
- `PATCH /api/okrs/:okrId/status` updates status using the `OKRStatus` enum.
- `COMPANY_ADMIN`, `HR_ADMIN`, and direct manager can update metadata/status.
- Employees cannot update OKR metadata or manager-controlled status.
- CP11 does not allow changing `employeeId`.

## Privacy and Audit

- OKR titles, descriptions, progress notes, and approval comments are not written to audit metadata.
- Audit logs record only action, target IDs, employee IDs, status, progress percent, and minimal references.

## Endpoints

- `POST /api/okrs`
- `GET /api/okrs/me`
- `GET /api/okrs/team`
- `GET /api/admin/okrs`
- `GET /api/okrs/:okrId`
- `PATCH /api/okrs/:okrId`
- `PATCH /api/okrs/:okrId/status`
- `POST /api/okrs/:okrId/progress`
- `PATCH /api/okrs/:okrId/employee-approve`
- `PATCH /api/okrs/:okrId/manager-approve`

## Testing

- CP11 integration tests cover assignment authorization, direct-report restrictions, company-scoped reads, self/team/admin visibility, text-only payload validation, progress updates, employee approval, manager/admin approval, final status sync, cross-company blocking, and regression with earlier suites.
