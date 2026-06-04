# GEOFENCING RULES

Rules for geofence setup and location validation. Implemented at Checkpoint 6.

## MVP Model

- **Circular geofences only**: latitude, longitude, and radius (meters).
- Each geofence belongs to a company (`companyId`).
- Polygon/complex geofences are out of scope for the MVP.
- The schema supports multiple geofences per company. CP6 service logic also supports multiple geofences technically.
- The MVP can later restrict companies to one active geofence through business rules if the product owner confirms that interpretation. Do not add a hard database constraint for this without product signoff.

## Validation Logic

- Distance computed via haversine in `lib/geo.ts`.
- A point is "inside" when `distance(point, center) <= radius`.
- Coordinates validated for sane ranges: latitude in [-90, 90], longitude in [-180, 180].
- Radius must be a positive integer and is capped at 50,000 meters in CP6.
- Location validation checks only `ACTIVE` geofences in the resolved company scope.

## Endpoints

- `POST /api/admin/geofences`
- `GET /api/admin/geofences`
- `GET /api/admin/geofences/:geofenceId`
- `PATCH /api/admin/geofences/:geofenceId`
- `PATCH /api/admin/geofences/:geofenceId/status`
- `POST /api/geofences/validate-location`

## Authorization & Scoping

- `COMPANY_ADMIN` and `HR_ADMIN` manage geofences within their own company.
- `SUPER_ADMIN` may manage geofences only with explicit safe `companyId` scoping.
- `MANAGER` and `EMPLOYEE` cannot manage geofence setup.
- Validation is scoped to the caller's company; no cross-company geofence access.
- Non-super-admin users cannot override `companyId`.

## Privacy

- GPS is sensitive. Raw coordinates are not logged.
- CP6 does not persist validate-location attempts.
- Audit logs are written for geofence setup changes only and do not include raw coordinates.
- `LocationPing` retention is bounded when location persistence is implemented in a later checkpoint.

## Attendance Integration

- Clock-in requires valid geofence validation (see `ATTENDANCE_RULES.md`).
- A failed geofence check blocks clock-in.
- CP6 validation does not create `AttendanceSession`, `AttendanceEvent`, or `LocationPing` records.
- CP7 attendance clock-in and clock-out use the same circular active-geofence rule and reject outside-geofence attempts.
- CP7 does not create `GeofenceBreach` records for rejected outside-geofence attempts; that can be added later if product/security policy requires it.

## Edge Cases

- GPS spoofing (mitigations tracked in `THREAT_MODEL.md`).
- Low GPS accuracy near the radius boundary.
- Antimeridian/pole edge cases.
- Zero/near-zero radius.
- Coordinate precision and rounding.

## Testing

- Inside, outside, and edge-of-radius cases.
- Invalid coordinates rejected.
- Cross-company geofence access blocked.
- Distance math accuracy.
