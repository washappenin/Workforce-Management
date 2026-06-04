# PRIVACY AND LOGGING RULES

Binding rules for handling sensitive data and logging. Enforced in `lib/logger.ts` and verified at Checkpoint 17.

## Never Log

- Passwords or password hashes
- JWT access tokens or refresh tokens
- `Authorization` headers (redact)
- Face/biometric data or templates (raw or processed)
- Raw GPS coordinates / unnecessary GPS history
- Payment instrument data
- Card numbers, bank account numbers, payment credentials, payment provider secrets, or full sensitive provider references
- Leave reasons or review comments
- OKR descriptions, progress notes, or approval comments
- Performance review summaries or comments
- Full notification message bodies when used only for audit/log context

## Sensitive Data Classes

| Class | Examples | Rule |
| ----- | -------- | ---- |
| Credentials | passwords, tokens | Hashed/encrypted; never logged |
| Biometric | face templates/references | Reference only, never raw; encrypted at rest; never logged; explicit deletion path |
| Location | GPS pings, geofence coordinates | Minimal retention; not logged; only validation outcome persisted/exposed where possible |
| Financial | payment records | Token/reference only; restricted; not logged |
| HR-sensitive | reviews, leave reasons | Restricted visibility; not logged |

## Logging Standard

- Structured logging with a default redaction list for sensitive fields.
- Redaction is case-insensitive for sensitive field names such as `Authorization`, `providerSubjectId`, `templateReference`, `providerReference`, `latitude`, `longitude`, `reviewComment`, and related variants.
- Log request IDs for traceability, not request bodies on sensitive routes.
- Log authorization outcomes without sensitive payloads.
- Production logs exclude stack traces in responses (server-side only, redacted).
- CP18 deployment guidance requires monitoring logs for redaction failures, readiness failures, auth failures, and rate-limit spikes without storing sensitive request bodies.

## Data Minimization

- Persist the minimum data needed (e.g., geofence validation result, not full GPS trails).
- CP6 validate-location does not persist validation attempts, `LocationPing`, `AttendanceSession`, or `AttendanceEvent` records.
- CP7 clock-in/out persists the submitted GPS coordinates only in `AttendanceSession` and `AttendanceEvent` as operational attendance records.
- CP8 face enrollment persists provider references and metadata only. API responses omit provider subject and template references.
- CP8 verification attempts do not persist raw face payloads, do not audit per-attempt biometric data, and return only a short-lived development reference on a successful match.
- CP10 leave audit metadata excludes leave reasons and review comments. Leave balances/statuses may be returned to authorized users, but reason/comment text is treated as HR-sensitive.
- CP11 OKR audit metadata excludes OKR titles, descriptions, progress notes, and approval comments. OKR content is visible only through authorized OKR endpoints.
- CP12 performance review audit metadata excludes review summaries. Performance review content is visible only through authorized self, direct-report, or company-scoped review endpoints.
- CP13 notification broadcast audit metadata excludes full notification titles and messages. Notification records are visible only to the owning user through self-service endpoints.
- CP14 report endpoints return summary data only. Report rollups exclude raw GPS coordinates, biometric data, leave reasons, review comments, performance review summaries, OKR notes/comments, and unnecessary employee/user details.
- CP15 payment records store manual provider metadata only and must not store card numbers, bank account numbers, raw payment instruments, Stripe secrets, or payment credentials. Payment audit metadata excludes provider references; company-admin payment self-view omits provider references.
- CP16 hardening verifies representative response and audit metadata restrictions: employee/auth responses omit `passwordHash`, reports stay aggregate-only, and payment audit metadata omits provider references.
- CP17 adds a centralized audit metadata sanitizer. Allowed audit metadata is sparse operational context such as IDs, statuses, status transitions, changed field names, dates, counts, roles assigned during employee creation, and non-sensitive configuration values. Disallowed audit metadata is removed before persistence.
- CP7 does not create continuous `LocationPing` tracking or `GeofenceBreach` records for rejected outside-geofence attempts.
- `LocationPing` has a bounded retention policy when persistence is implemented in a later checkpoint.
- Responses return the minimum PII required for the screen.

## CP6 Location Privacy

- `POST /api/geofences/validate-location` accepts raw latitude/longitude but does not write those coordinates to audit logs.
- Geofence setup audit metadata may include name, radius, status, and changed field names, but not raw latitude/longitude.
- Location validation returns only scoped geofence result details and cannot reveal another company's geofences.
- Report endpoints must never return raw GPS coordinates. Attendance self/admin listing may return attendance session IDs, timestamps, status, geofence IDs, and face-verification flags, but not raw session coordinates.

## CP8 Face Privacy

- Raw face images, base64 image payloads, raw biometric vectors, and templates are rejected by validation.
- `providerSubjectId` and `templateReference` may exist only as provider references in storage and must not be logged or returned.
- Face enrollment create/update/status changes are audited without raw biometric payloads.
- Clock-in stores `clockInFaceVerified: true` after a valid reference is consumed; it does not store the verification reference.
- Face verification references are short-lived and single-use for clock-in.

## HR Content Privacy

- Leave reason and leave review comment text is visible only through allowed leave detail/list scopes and is never included in audit metadata or reports.
- OKR descriptions, progress notes, and approval comments are visible only through allowed OKR detail/list scopes and are never included in audit metadata or reports.
- Performance review summaries are visible only through allowed review scopes and are never included in audit metadata or reports.
- Notification titles/messages are returned to the owning user or broadcast response caller where the endpoint allows it, but broadcast audit metadata stores only type, target role, and counts.

## Payment Privacy

- No card, bank account, raw payment instrument, payment credential, Stripe secret, or webhook secret is accepted or stored in CP15/CP17.
- `providerReference` is available only on super-admin payment-management responses and is omitted from company-admin/HR payment self-view and audit metadata.

## Retention & Deletion

- Biometric enrollment deletion/offboarding workflow is deferred until a later checkpoint and must be implemented before production biometric use.
- GPS/location data retention is time-bounded by policy and finalized in CP18 before production.
- Audit logs are retained per policy and are append-only.
- CP18 keeps final log/audit retention windows as an operational deployment decision after staging baseline; no public audit-log reader exists.

## Consent & Compliance

- Production biometric enrollment requires recorded consent before rollout; CP8/CP17 keep provider data minimal but do not implement the final consent workflow.
- Data classification enforced across all modules and verified by tests at Checkpoint 17.
