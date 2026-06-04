# SHIFT RULES

Rules for shift management. Implemented at Checkpoint 9.

## Time Model

- Shifts use simple `HH:mm` strings for `startTime` and `endTime`.
- CP9 does not perform timezone conversion. Company timezone can be used by frontend display flows when available.
- Overnight shifts are allowed by storing an `endTime` earlier than `startTime` (for example `22:00` to `06:00`).
- CP9 does not implement recurring calendars, holiday calendars, payroll, overtime, or automatic attendance violation scoring.

## Shift Management

- Admin shift routes live under `/api/admin/shifts`.
- `COMPANY_ADMIN` and `HR_ADMIN` manage shifts only in their authenticated company.
- `SUPER_ADMIN` must provide explicit safe `companyId`.
- `MANAGER` and `EMPLOYEE` cannot use admin shift management routes.
- Shift names are unique within a company.
- Deactivating a shift does not delete historical assignments.

## Assignment Rules

- Assignments use `startsOn` and optional `endsOn` date-only values.
- `endsOn` cannot be before `startsOn`.
- A shift must belong to the resolved company.
- An employee must belong to the resolved company and be active.
- A shift must be `ACTIVE` before it can be assigned.
- CP9 prevents obvious overlapping duplicate assignments for the same employee and same shift.
- CP9 does not perform complex conflict detection across different shifts.
- Assignment removal uses hard delete because the CP2 schema has no soft-delete field for `EmployeeShiftAssignment`.

## Employee Self-View

- `GET /api/shifts/me` returns current and future assignments for the authenticated user's own `EmployeeProfile`.
- Users without an employee profile are rejected with `403`.
- Employees cannot view another employee's shifts from the self-view endpoint.

## Attendance Relationship

- CP9 does not enforce attendance clock-in/out against shift times.
- Future checkpoints may use assignments to validate attendance timing, lateness, overtime, or scheduling violations.
- Existing attendance, geofence, and face verification rules remain unchanged.

## Privacy and Security

- Shift data is company-scoped.
- Cross-company shift and assignment access is blocked.
- Client-supplied `companyId` cannot override authenticated scope for non-super-admin users.
- Shift create/update/status and assignment create/update/remove actions are audited.
