# FACE VERIFICATION RULES

Rules for the facial verification integration layer. Implemented at Checkpoint 8.

## Design Principle

- Facial verification is built as a vendor-agnostic adapter (`src/lib/faceMatch.ts`) so the provider can be changed later.
- Provider-specific behavior stays behind `src/lib/face/faceProvider.ts`.
- CP8 includes only the safe development `mock` provider in `src/lib/face/mockFaceProvider.ts`.
- No real vendor integration, liveness workflow, or biometric scoring is implemented in CP8.

## Mock Provider

- Enrollment accepts only provider reference fields and returns mock provider references.
- Verification succeeds when `verificationReference` is `mock-pass`.
- Verification fails when `verificationReference` is `mock-fail` or any other value.
- Successful verification creates a short-lived, single-use development reference consumed by `POST /api/attendance/clock-in`.

## Data Handling

- `FaceEnrollment` stores provider, provider subject reference, template reference, status, and timestamps only.
- The API does not accept raw face images, base64 image fields, or raw biometric vectors.
- API responses omit `providerSubjectId` and `templateReference`.
- Audit metadata records action context only: employee ID, provider, and status. It does not include raw face payloads or provider template references.
- Production replacement must encrypt any sensitive provider references at rest and use secrets for provider credentials.

## Authorization

- Admin enrollment/status endpoints are under `/api/admin/employees/:employeeId/*`.
- `COMPANY_ADMIN` and `HR_ADMIN` may manage face enrollments only inside their authenticated company.
- `SUPER_ADMIN` must provide explicit safe `companyId`.
- `MANAGER` and `EMPLOYEE` cannot use admin enrollment/status endpoints.
- `POST /api/face/verify` is self-service only and requires the caller's active employee profile.

## Flow Integration

- Clock-in requires a passing face verification before geofence/session creation.
- `POST /api/face/verify` returns a short-lived verification reference on success.
- `POST /api/attendance/clock-in` requires that reference and rejects missing, invalid, expired, reused, or different-employee references.
- `AttendanceSession.clockInFaceVerified` is set to `true` only after the reference is consumed.

## Failure Handling

- Missing active enrollment fails closed.
- Provider mismatch fails with validation.
- Mock no-match returns `{ "verified": false, "reason": "FACE_NOT_MATCHED" }`.
- Clock-in never accepts frontend-faked face success.

## Endpoints

- `POST /api/admin/employees/:employeeId/face-enrollment`
- `GET /api/admin/employees/:employeeId/face-status`
- `PATCH /api/admin/employees/:employeeId/face-enrollment/status`
- `POST /api/face/verify`

## Testing

- CP8 integration tests cover admin enrollment/status, role denial, company scoping, raw payload rejection, mock pass/fail behavior, missing enrollment, self-service enforcement, sensitive response redaction, audit logging, and attendance clock-in reference validation.
- Regression includes the CP7 attendance suite.

## Threat Considerations

- Spoofing/liveness, enrollment drift, and vendor compromise remain production concerns tracked in `THREAT_MODEL.md`.
