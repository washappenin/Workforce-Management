# DATABASE SCHEMA

> **Status: CP5 IMPLEMENTED ON CP2 SCHEMA.** `prisma/schema.prisma` contains the database foundation for the workforce management backend. CP5 now uses the existing Company, Department, Designation, User, UserRole, EmployeeProfile, and AuditLog models for organization management.
> Multi-tenancy: tenant-owned records carry `companyId`; global/system records do not. `SUPER_ADMIN` support is handled by nullable `companyId` on `User`, `UserRole`, `AuditLog`, `Notification`, and `DeviceSession` where system-level records may exist.

## Prisma Baseline

- Provider: PostgreSQL
- ID strategy: string IDs with `cuid()`
- ORM: Prisma Client
- Seed structure: `prisma/seed.ts`
- Migration status: `prisma/migrations/20260602000000_cp2_schema_foundation/migration.sql` was generated with `prisma migrate diff`; no database migration was applied.

## Enums

The schema defines:

- `UserStatus`
- `CompanyStatus`
- `EmployeeStatus`
- `RoleName`
- `AttendanceStatus`
- `AttendanceEventType`
- `GeofenceStatus`
- `GeofenceBreachType`
- `FaceEnrollmentStatus`
- `ShiftStatus`
- `LeaveRequestStatus`
- `LeaveTypeStatus`
- `OKRStatus`
- `OKRApprovalStatus`
- `ReviewCycleStatus`
- `PerformanceReviewStatus`
- `NotificationType`
- `NotificationStatus`
- `SubscriptionPlanType`
- `SubscriptionStatus`
- `PaymentStatus`
- `AuditActionCategory`
- `DeviceSessionStatus`

## Models

| Model | Purpose | Tenant Scope |
| ----- | ------- | ------------ |
| `User` | Login identity with password hash, status, optional company, and last login timestamp | Optional `companyId` for super-admin support |
| `Company` | Tenant root with contact, billing, address, country, and timezone metadata | Global tenant root |
| `Department` | Company department | Required `companyId` |
| `Designation` | Job title, optionally linked to a department | Required `companyId` |
| `EmployeeProfile` | Employee HR profile linked one-to-one with `User` | Required `companyId` |
| `Role` | Global role name (`SUPER_ADMIN`, `COMPANY_ADMIN`, `HR_ADMIN`, `MANAGER`, `EMPLOYEE`) | Global |
| `Permission` | Permission key foundation for future RBAC expansion | Global |
| `UserRole` | User-role assignment, optionally company-scoped | Optional `companyId` |
| `Geofence` | Circular geofence with latitude, longitude, and radius | Required `companyId` |
| `FaceEnrollment` | Face provider metadata/reference only | Required `companyId` |
| `AttendanceSession` | Clock-in to clock-out session | Required `companyId` |
| `AttendanceEvent` | Clock event, location ping event, breach event, or audit-like attendance marker | Required `companyId` |
| `LocationPing` | Sensitive GPS sample tied to an employee/session | Required `companyId` |
| `GeofenceBreach` | Geofence compliance event | Required `companyId` |
| `Shift` | Shift definition | Required `companyId` |
| `EmployeeShiftAssignment` | Employee-to-shift assignment window | Required `companyId` |
| `LeaveType` | Company leave category | Required `companyId` |
| `LeaveEntitlement` | Employee leave balance by type and year | Required `companyId` |
| `LeaveRequest` | Employee leave request with review fields | Required `companyId` |
| `OKR` | Text-based MVP objective | Required `companyId` |
| `OKRProgressUpdate` | Text note and progress percent | Required `companyId` |
| `OKRApproval` | Manager approval state for an OKR | Required `companyId` |
| `ReviewCycle` | Performance review window | Required `companyId` |
| `PerformanceReview` | Manager review for an employee in a cycle | Required `companyId` |
| `Notification` | In-app notification | Optional `companyId` |
| `SubscriptionPlan` | Global Basic/Premium plan | Global |
| `CompanySubscription` | Company plan assignment | Required `companyId` |
| `PaymentRecord` | Payment provider reference and amount | Required `companyId` |
| `AuditLog` | Append-only audit event foundation | Optional `companyId` |
| `DeviceSession` | Future auth/session tracking | Optional `companyId` |

## Key Constraints

- `User`: unique `(companyId, email)`; indexed by `companyId`, `status`, `createdAt`.
- `Department`: unique `(companyId, name)`.
- `Designation`: unique `(companyId, title)`.
- `EmployeeProfile`: unique `userId`; unique `(companyId, employeeCode)`; self-relation for manager/direct reports.
- `Role`: unique `name`.
- `Permission`: unique `key`.
- `UserRole`: unique `(userId, roleId, companyId)`.
- `Geofence`: unique `(companyId, name)`.
- `FaceEnrollment`: unique `employeeId`.
- `EmployeeShiftAssignment`: unique `(employeeId, shiftId, startsOn)`.
- `LeaveType`: unique `(companyId, name)`.
- `LeaveEntitlement`: unique `(employeeId, leaveTypeId, year)`.
- `OKRApproval`: unique `(okrId, approverEmployeeId)`.
- `ReviewCycle`: unique `(companyId, name)`.
- `PerformanceReview`: unique `(reviewCycleId, employeeId)`.
- `SubscriptionPlan`: unique `name`.

## CP5 Behavior Notes

- Employee creation creates both `User` and `EmployeeProfile`, then assigns roles through `UserRole`.
- `temporaryPassword` is a CP5 development input only; only `User.passwordHash` is stored.
- Although the database unique constraint for users is `(companyId, email)`, CP5 service logic rejects duplicate email addresses globally to preserve the current email-only login flow.
- Employee status changes update `EmployeeProfile.status`. `ACTIVE` and `ON_LEAVE` map the linked `User.status` to `ACTIVE`; `INACTIVE` and `TERMINATED` map it to `DISABLED`.
- Department and designation uniqueness remains company-scoped.
- `AuditLog` is written for CP5 company, department, designation, employee, status, and manager-change actions.

## Indexing Standard

CP2 adds indexes for common lookup and isolation fields:

- `companyId` on tenant-owned and optionally tenant-owned models.
- `userId`, `employeeId`, `roleId`, `departmentId`, `designationId`, `managerId`, `shiftId`, `leaveTypeId`, `okrId`, `reviewCycleId`, and subscription/payment foreign keys.
- Status fields including user, employee, geofence, attendance, leave, OKR, review, notification, subscription, payment, and device session status.
- Time fields including `createdAt`, `clockInAt`, `clockOutAt`, `capturedAt`, `detectedAt`, `startsAt`, `startsOn`, `startDate`, `endDate`, `dueDate`, `paidAt`, and `lastSeenAt`.

## Sensitive Data Rules

| Class | Models / Fields | Rule |
| ----- | --------------- | ---- |
| Credentials | `User.passwordHash`, future session tokens | Hash/encrypt as appropriate; never log |
| Biometric | `FaceEnrollment.providerSubjectId`, `FaceEnrollment.templateReference` | Provider references/templates only; no raw face images or raw biometric vectors |
| Location | `Geofence`, `AttendanceSession` coordinates, `AttendanceEvent`, `LocationPing`, `GeofenceBreach` | Sensitive; minimize exposure; never log raw GPS history |
| HR-sensitive | `LeaveRequest.reason`, `PerformanceReview.summary`, review comments | Restricted visibility; never log content |
| Financial | `PaymentRecord.providerReference` | Provider reference only; no raw payment instrument data |
| Audit | `AuditLog.metadata`, actor, target, IP/user-agent | Append-only usage pattern; restricted access in later checkpoints |

## Geofence Product Decision

The schema allows multiple geofences per company through `Geofence` with unique `(companyId, name)`.

One proposal says the MVP may allow only one company-level geofence. CP2 does **not** enforce that limit at the database level. Until the product decision is finalized, CP6 business logic may restrict each company to one active geofence while preserving the extensible schema.

## Attendance Open Session Note

`AttendanceSession` has `status` and an index on `(employeeId, status)` so CP7 can efficiently prevent multiple open sessions per employee in service logic. Prisma does not express PostgreSQL partial unique indexes directly in the schema; if CP7 requires a hard database-level partial unique constraint for `OPEN` sessions, add it in a migration with an explicit documented SQL constraint.

## Seed Structure

`prisma/seed.ts` is seed-ready and idempotently upserts:

- Core roles: `SUPER_ADMIN`, `COMPANY_ADMIN`, `HR_ADMIN`, `MANAGER`, `EMPLOYEE`
- Subscription plans: `Basic`, `Premium`

It does not create users, companies, employees, credentials, attendance data, biometric data, or GPS data.

## Migration Artifact

CP2 prepared an initial migration SQL file without applying it:

- `prisma/migrations/20260602000000_cp2_schema_foundation/migration.sql`

Apply migrations only in an explicitly configured local/staging database flow. Do not run production migrations from local development.

## CP2 Verification

Expected commands:

```bash
npm run prisma:validate
npm run prisma:generate
npm run typecheck
npm run build
npm test
```
