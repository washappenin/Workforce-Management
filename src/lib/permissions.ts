export const permissions = {
  COMPANY_READ: "company:read",
  COMPANY_MANAGE: "company:manage",
  EMPLOYEE_READ: "employee:read",
  EMPLOYEE_MANAGE: "employee:manage",
  ATTENDANCE_READ: "attendance:read",
  ATTENDANCE_MANAGE: "attendance:manage",
  LEAVE_APPROVE: "leave:approve",
  OKR_MANAGE: "okr:manage",
  REVIEW_MANAGE: "review:manage",
  SUBSCRIPTION_MANAGE: "subscription:manage",
  SYSTEM_ADMIN: "system:admin"
} as const;

export type PermissionKey = keyof typeof permissions;
export type PermissionValue = (typeof permissions)[PermissionKey];
