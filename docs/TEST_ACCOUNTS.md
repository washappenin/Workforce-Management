# TEST ACCOUNTS

Synthetic staging accounts must be created before Lovable generation begins. Do not use production credentials, real employee data, or personal user accounts. Do not commit real passwords to this repository.

## Staging Backend URL

```text
STAGING_BACKEND_URL=https://workforce-management-production.up.railway.app
```

## Account Status

Staging test accounts were created and smoke-verified on June 7, 2026. Store credentials only in the approved secure password manager or staging secret store; this file records emails, role context, company context, purpose, and storage location only.

| Role | Email | Company | Employee Profile Needed | Purpose | Password Source |
| ---- | ----- | ------- | ----------------------- | ------- | --------------- |
| `SUPER_ADMIN` | `admin@example.com` | Platform | No | Platform admin navigation, company management, plans, subscriptions, manual payment records, platform reports, and company rollups. | Secure password manager / staging secret |
| `COMPANY_ADMIN` | `company-admin-20260607223636-16252@example.test` | `Staging Smoke 20260607223636-16252` | Yes, for employee self-service checks | Company administration, employees, departments, designations, geofences, shifts, leave, OKRs, reviews, notifications, reports, and billing self-view. | Secure password manager / staging secret |
| `HR_ADMIN` | `hr-admin-20260607223636-16252@example.test` | `Staging Smoke 20260607223636-16252` | Yes, for employee self-service checks | HR admin navigation, employee operations, attendance logs, leave setup, review cycles, reports, notifications, and billing self-view. | Secure password manager / staging secret |
| `MANAGER` | `manager-20260607223636-16252@example.test` | `Staging Smoke 20260607223636-16252` | Yes | Direct-report attendance reports, leave review, OKR assignment/approval, performance reviews, and team reports. | Secure password manager / staging secret |
| `EMPLOYEE` | `employee-20260607223636-16252@example.test` | `Staging Smoke 20260607223636-16252` | Yes | Employee dashboard, face verification, clock-in/out, attendance history, shifts, leave, OKRs, reviews, and notifications. | Secure password manager / staging secret |

## Synthetic Company And Relationship Checklist

- Created one staging company named `Staging Smoke 20260607223636-16252`.
- Created one additional cross-company boundary test company named `Staging Smoke Other 20260607223636-16252`.
- Created active employee profiles for `COMPANY_ADMIN`, `HR_ADMIN`, `MANAGER`, and `EMPLOYEE`.
- Set the `EMPLOYEE` test profile's `managerId` to the `MANAGER` test profile.
- Confirmed role boundaries and non-super-admin cross-company denial through `scripts/staging-smoke/02-auth-and-boundaries.sh`.
- Confirmed core employee self-service workflows through `scripts/staging-smoke/03-core-workflow.sh`.
- Do not use real staff names, real phone numbers, real IDs, or real customer data.

## Required Setup Before Lovable Work

1. Deploy the backend to staging.
2. Configure variables from `docs/STAGING_ENV_CHECKLIST.md`.
3. Run `npm run prisma:migrate:deploy` against the staging database.
4. If no staging super-admin exists, create it using the controlled `npm run staging:bootstrap-super-admin` process in `docs/DEPLOYMENT_RUNBOOK.md`.
5. Create the synthetic staging company.
6. Create departments and designations needed for employee profiles.
7. Create all five synthetic users listed above.
8. Create or verify at least one active geofence for the staging company.
9. Create or verify one active shift and assign it to the employee profile.
10. Create or verify one leave type and one leave entitlement for the employee profile.
11. Create or verify one active review cycle.
12. Create or verify one Basic or Premium subscription plan.
13. Create or verify one company subscription for the staging company.
14. Store credentials only in the secure password manager or staging secret store.
15. Update this file with real staging emails and company name only after the accounts exist.

## Per-Role Smoke Checks

| Role | Required Checks |
| ---- | --------------- |
| `SUPER_ADMIN` | Login, `GET /api/auth/me`, company list, platform dashboard, plans list, subscriptions list, manual payment records list. |
| `COMPANY_ADMIN` | Login, `GET /api/auth/me`, admin dashboard, employees list, geofences list, attendance logs, reports, subscription self-view. |
| `HR_ADMIN` | Login, `GET /api/auth/me`, employees list, leave setup, review cycles, reports, payment history self-view. |
| `MANAGER` | Login, `GET /api/auth/me`, team dashboard, team leave list, team OKRs, team reviews, team reports. |
| `EMPLOYEE` | Login, `GET /api/auth/me`, employee profile, dashboard, face verification, clock-in/out, attendance history, shifts, leave, OKRs, reviews, notifications. |

## Post-Creation Fields To Record

Keep this section free of passwords.

| Field | Value |
| ----- | ----- |
| Staging backend URL | `https://workforce-management-production.up.railway.app` |
| Staging company name | `Staging Smoke 20260607223636-16252` |
| Staging company ID | `cmq4d380z0002x9c6kcgkh4ng` |
| Cross-company boundary test company ID | `cmq4d38om0005x9c6kkqtwtbm` |
| Super admin email | `admin@example.com` |
| Company admin email | `company-admin-20260607223636-16252@example.test` |
| HR admin email | `hr-admin-20260607223636-16252@example.test` |
| Manager email | `manager-20260607223636-16252@example.test` |
| Employee email | `employee-20260607223636-16252@example.test` |
| Password storage location | Secure password manager / staging secret |
| Account creation date | June 7, 2026 |

## Rules

- No real passwords are stored here.
- No production credentials are stored here.
- No customer or employee personal data is used.
- No production accounts are used.
- Local seed users are development examples only and are not staging test accounts.
- Rotate staging credentials if they are pasted into docs, prompts, chat, screenshots, or issue trackers.
