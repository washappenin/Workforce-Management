# TEST ACCOUNTS

Synthetic staging accounts must be created before Lovable generation begins. Do not use production credentials, real employee data, or personal user accounts. Do not commit real passwords to this repository.

## Staging Backend URL

```text
STAGING_BACKEND_URL=TBD_AFTER_DEPLOYMENT
```

## Account Status

Staging test accounts are not created yet. After staging deployment, create the accounts below, store credentials in the approved secure password manager or staging secret store, then record only email, role, company, purpose, and password source here.

| Role | Email | Company | Employee Profile Needed | Purpose | Password Source |
| ---- | ----- | ------- | ----------------------- | ------- | --------------- |
| `SUPER_ADMIN` | `TBD_SUPER_ADMIN_EMAIL` | Platform | No | Platform admin navigation, company management, plans, subscriptions, manual payment records, platform reports, and company rollups. | Secure password manager / staging secret |
| `COMPANY_ADMIN` | `TBD_COMPANY_ADMIN_EMAIL` | `TBD_STAGING_COMPANY` | Yes, for employee self-service checks | Company administration, employees, departments, designations, geofences, shifts, leave, OKRs, reviews, notifications, reports, and billing self-view. | Secure password manager / staging secret |
| `HR_ADMIN` | `TBD_HR_ADMIN_EMAIL` | `TBD_STAGING_COMPANY` | Yes, for employee self-service checks | HR admin navigation, employee operations, attendance logs, leave setup, review cycles, reports, notifications, and billing self-view. | Secure password manager / staging secret |
| `MANAGER` | `TBD_MANAGER_EMAIL` | `TBD_STAGING_COMPANY` | Yes | Direct-report attendance reports, leave review, OKR assignment/approval, performance reviews, and team reports. | Secure password manager / staging secret |
| `EMPLOYEE` | `TBD_EMPLOYEE_EMAIL` | `TBD_STAGING_COMPANY` | Yes | Employee dashboard, face verification, clock-in/out, attendance history, shifts, leave, OKRs, reviews, and notifications. | Secure password manager / staging secret |

## Synthetic Company And Relationship Checklist

- Create one staging company named with an obvious non-production label, for example `TBD_STAGING_COMPANY`.
- Create at least one department and one designation.
- Create active employee profiles for `COMPANY_ADMIN`, `HR_ADMIN`, `MANAGER`, and `EMPLOYEE` if those users should access employee self-service screens.
- Set the `EMPLOYEE` test profile's `managerId` to the `MANAGER` test profile.
- Confirm the manager can see only direct-report team data.
- Confirm non-super-admin users cannot override `companyId`.
- Do not use real staff names, real phone numbers, real IDs, or real customer data.

## Required Setup Before Lovable Work

1. Deploy the backend to staging.
2. Configure variables from `docs/STAGING_ENV_CHECKLIST.md`.
3. Run `npm run prisma:migrate:deploy` against the staging database.
4. Create the synthetic staging company.
5. Create departments and designations needed for employee profiles.
6. Create all five synthetic users listed above.
7. Create or verify at least one active geofence for the staging company.
8. Create or verify one active shift and assign it to the employee profile.
9. Create or verify one leave type and one leave entitlement for the employee profile.
10. Create or verify one active review cycle.
11. Create or verify one Basic or Premium subscription plan.
12. Create or verify one company subscription for the staging company.
13. Store credentials only in the secure password manager or staging secret store.
14. Update this file with real staging emails and company name only after the accounts exist.

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
| Staging backend URL | `TBD_AFTER_DEPLOYMENT` |
| Staging company name | `TBD_STAGING_COMPANY` |
| Super admin email | `TBD_SUPER_ADMIN_EMAIL` |
| Company admin email | `TBD_COMPANY_ADMIN_EMAIL` |
| HR admin email | `TBD_HR_ADMIN_EMAIL` |
| Manager email | `TBD_MANAGER_EMAIL` |
| Employee email | `TBD_EMPLOYEE_EMAIL` |
| Password storage location | Secure password manager / staging secret |
| Account creation date | `TBD_ACCOUNT_CREATION_DATE` |

## Rules

- No real passwords are stored here.
- No production credentials are stored here.
- No customer or employee personal data is used.
- No production accounts are used.
- Local seed users are development examples only and are not staging test accounts.
- Rotate staging credentials if they are pasted into docs, prompts, chat, screenshots, or issue trackers.
