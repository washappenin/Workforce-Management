# ATTENDANCE RULES

Rules for clock-in and clock-out. Implemented at Checkpoint 7 and updated by Checkpoint 8 face verification.

## Clock-In Requirements (all must pass)

1. Authenticated non-super-admin user clocking themselves.
2. Active `EmployeeProfile`.
3. Active company.
4. **GPS** coordinates provided.
5. **Face verification reference** created by `POST /api/face/verify`.
6. **Valid geofence** validation (inside an active company geofence).

The face verification reference is short-lived and single-use. It must belong to the same employee as the authenticated caller. Missing, invalid, expired, reused, or different-employee references are rejected. `AttendanceSession.clockInFaceVerified` is set to `true` only after CP8 consumes a valid reference.

If any requirement fails, clock-in is rejected with a clear, non-sensitive error. The flow fails closed.

## Clock-Out Requirements

1. Authenticated non-super-admin user with an active employee profile.
2. Open attendance session owned by that employee.
3. **GPS** coordinates provided.
4. **Valid geofence** validation (inside an active company geofence).

Outside-geofence clock-out is rejected in CP7. CP7 does not create `GeofenceBreach` records for rejected outside-geofence attempts.

## Sessions & Events

- A clock-in opens an `AttendanceSession`; clock-out closes it.
- Each action records an `AttendanceEvent` (`CLOCK_IN`, `CLOCK_OUT`).
- Double clock-in (open session already exists) is prevented.
- Clock-out without an open session is rejected.
- CP8 consumes the face verification reference before creating a clock-in session.
- CP7 does not create continuous `LocationPing` tracking.
- CP7 does not allow clock-in or clock-out on behalf of another employee.

## Authorization & Scoping

- Employees clock only themselves.
- `GET /api/attendance/me` returns only the caller's own attendance sessions.
- `GET /api/admin/attendance` is restricted to `COMPANY_ADMIN`, `HR_ADMIN`, and explicitly scoped `SUPER_ADMIN`.
- Manager team attendance is not implemented in CP7.
- No cross-company attendance access.

## Privacy

- GPS coordinates are persisted only as required on `AttendanceSession` and `AttendanceEvent`; continuous GPS tracking is not implemented.
- No raw biometric data is stored. CP8 stores only face provider metadata/references on `FaceEnrollment` and never returns provider template references in attendance responses.
- Sensitive fields never logged. See `PRIVACY_AND_LOGGING_RULES.md`.
- Attendance actions use `AttendanceEvent` as operational records; CP7 does not add `AuditLog` records for every clock-in/out.

## Endpoints

- `POST /api/attendance/clock-in`
- `POST /api/attendance/clock-out`
- `GET /api/attendance/me`
- `GET /api/admin/attendance`
- `POST /api/face/verify` supplies the CP8 clock-in face reference.

`GET /api/attendance/team` is not implemented in CP7.

## Edge Cases

- Clock-out without clock-in.
- Overlapping/duplicate sessions; retries causing duplicates (idempotency considered).
- Timezone handling and clock skew.
- Partial failure mid-flow (session write succeeds but event write fails, etc.).

## Testing

- Successful clock-in/out.
- Missing GPS rejected; outside geofence rejected.
- Missing, invalid, expired, reused, or wrong-employee face verification references rejected.
- Double clock-in prevented.
- Cross-company log access blocked.
- Regression with geofence (CP6) and RBAC (CP4) suites.
