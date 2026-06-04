export const roles = ["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN", "MANAGER", "EMPLOYEE"] as const;

export type Role = (typeof roles)[number];

export interface AuthenticatedUser {
  id: string;
  email: string;
  companyId?: string | null;
  roles: Role[];
  status: string;
  sessionId: string;
}

export interface CompanyScope {
  companyId: string | null;
  isSuperAdmin: boolean;
  requestedCompanyId?: string | null;
}
