# RATE LIMITING RULES

Rules for request rate limiting. Scaffolded at Checkpoint 1, reviewed at Checkpoint 17, and finalized for CP18 staging readiness with global limiting only.

## Goals

- Protect against brute-force, abuse, and accidental floods.
- Keep limits predictable so the frontend can handle `429` cleanly.

## Layers

| Scope | Target | Intent |
| ----- | ------ | ------ |
| Global | All routes | Baseline protection per IP |
| Auth | `POST /api/auth/login` | Future stricter brute-force protection |
| Sensitive | clock-in, face verify, approvals | Future tighter limits on sensitive actions |
| Write | mutating routes | Future moderate limits |
| Read | GET routes | Future looser limits |

> CP18 confirms the implemented middleware is global only. Exact route-specific thresholds are future hardening after staging traffic baselines are observed.

Recommended future route-specific targets:

- `POST /api/auth/login`
- `POST /api/face/verify`
- `POST /api/attendance/clock-in`
- `POST /api/attendance/clock-out`
- `POST /api/admin/notifications/broadcast`
- Sensitive `/api/admin/*` and `/api/super-admin/*` write routes

## Behavior

- Exceeding a limit returns `429` with the standard error envelope.
- Responses include rate-limit headers where applicable.
- Current limits are keyed by IP. Authenticated-identity-aware limits are future hardening.

## Identity & Tenancy

- Future per-user limits should use the authenticated subject and must not leak cross-tenant information.

## Testing

- Global limit behavior is covered by the middleware and CP17 documentation/security audit.
- Auth-specific and sensitive-route limits are future hardening after staging baseline data.
- `429` returns the standard error envelope.

## Frontend Impact

- The frontend must handle `429` with a retry/backoff and a clear message.
- Documented in `FRONTEND_HANDOFF.md` (loading/error states).
