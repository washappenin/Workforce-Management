# THREAT MODEL

Living threat model for the backend. Refined as modules are implemented; consolidated at Checkpoint 17.

## Assets

- User credentials and sessions (JWT/refresh tokens).
- Biometric enrollment references (face).
- Location/GPS data and geofence configuration.
- Attendance records.
- HR-sensitive data (reviews, leave reasons).
- Financial/subscription data.
- Cross-tenant data isolation (company boundaries).
- Audit logs.

## Trust Boundaries

- Public internet -> API (auth boundary).
- API -> database (repository layer only).
- API -> external vendors (face provider, SMS, email) via adapters.
- Tenant boundary between companies.

## Threats (STRIDE-oriented)

| Category | Threat | Mitigation |
| -------- | ------ | ---------- |
| Spoofing | Credential theft, token replay | Short-lived tokens, refresh rotation, rate limiting, generic auth errors |
| Spoofing | GPS spoofing | Geofence validation + server-side checks; flagged as residual risk |
| Spoofing | Face spoofing / liveness bypass | CP8 mock provider is development-only; production vendor liveness, thresholds, and audit remain required |
| Spoofing | Reused or stolen face verification reference | Short-lived, single-use references scoped to the employee and consumed by clock-in |
| Tampering | Client-supplied `companyId`/role | Token-derived scope; ignore client ownership fields |
| Tampering | Audit log alteration | Append-only, access-restricted |
| Tampering | Weak or incomplete audit logs | CP17 verifies audit action coverage for sensitive state-changing module operations |
| Repudiation | Disputed sensitive actions | Audit logging of sensitive actions |
| Info Disclosure | Cross-company data leak | Tenant scoping + isolation tests |
| Info Disclosure | Frontend-only authorization bypass | Backend auth, RBAC, company scoping, direct-report checks, and self-scope checks are authoritative; hidden UI is usability only |
| Info Disclosure | Internal authorization diagnostics exposed in production | CP16 disables `/api/system/*` verification routes in production |
| Info Disclosure | Sensitive data in logs | CP17 case-insensitive logger redaction for credential, token, GPS, biometric/provider, payment, leave, OKR, review, and notification fields |
| Info Disclosure | Sensitive data in audit metadata | CP17 centralized audit metadata sanitizer removes forbidden sensitive keys before persistence |
| Info Disclosure | Raw biometric or provider template exposure | CP8 rejects raw face payload fields; CP17 verifies provider subject/template references are not returned or persisted in audit metadata |
| Info Disclosure | GPS/location privacy abuse | Validate-location does not persist GPS attempts; attendance stores only required operational clock-in/out coordinates; reports omit raw GPS |
| Info Disclosure | Billing provider references exposed through company-admin views or audit metadata | CP15/CP16 omit provider references from company-admin payment responses; CP17 audit sanitizer blocks provider references in metadata |
| Info Disclosure | Verbose errors | Standard envelope, no stack traces in prod |
| DoS | Brute force / floods | Global rate limiting covers all routes, including login; route-specific limits remain CP18 hardening |
| Elevation | Privilege escalation | Deny-by-default RBAC, explicit role checks, escalation tests |
| Elevation | Admin-created super-admin accounts | CP16 verifies normal employee creation cannot assign `SUPER_ADMIN`; super-admin creation remains seed/manual-only |
| Elevation | Self-approval (leave/OKR) | Server-side workflow checks |

## Vendor / Supply Chain

- Face/SMS/email providers behind adapters; credentials as secrets; failure modes defined (fail closed for clock-in face check).
- CP8 includes only the mock face provider. Real face provider onboarding must update this threat model with liveness, data residency, encryption, retention, and incident-response controls.
- Dependency review as part of production readiness (CP18).

## Residual Risks

- GPS spoofing and biometric spoofing are partially mitigated, not eliminated; documented and revisited.
- Online-first assumption: no offline clock-in in the MVP.

## Verification

- Security regression runs each checkpoint; consolidated security testing is implemented in CP17.
- CP17 threat coverage is mapped to `tests/integration/security-audit.test.ts` plus the existing module integration suites for cross-company isolation and role boundaries.
