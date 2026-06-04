import { AuthorizationError } from "./errors";
import type { AuthenticatedUser, Role } from "../types/auth";

export const hasRole = (user: Pick<AuthenticatedUser, "roles">, role: Role) => user.roles.includes(role);

export const hasAnyRole = (user: Pick<AuthenticatedUser, "roles">, allowedRoles: Role[]) =>
  allowedRoles.some((role) => hasRole(user, role));

export const isSuperAdmin = (user: Pick<AuthenticatedUser, "roles">) => hasRole(user, "SUPER_ADMIN");

export const assertSameCompany = (user: Pick<AuthenticatedUser, "companyId" | "roles">, companyId: string) => {
  if (isSuperAdmin(user)) {
    return;
  }

  if (!user.companyId || user.companyId !== companyId) {
    throw new AuthorizationError("Company scope mismatch");
  }
};

export const getScopedCompanyId = (
  user: Pick<AuthenticatedUser, "companyId" | "roles">,
  requestedCompanyId?: string | null
) => {
  if (isSuperAdmin(user)) {
    return requestedCompanyId ?? null;
  }

  if (!user.companyId) {
    throw new AuthorizationError("Company scope is required");
  }

  if (requestedCompanyId && requestedCompanyId !== user.companyId) {
    throw new AuthorizationError("Company scope mismatch");
  }

  return user.companyId;
};

export const getRequiredScopedCompanyId = (
  user: Pick<AuthenticatedUser, "companyId" | "roles">,
  requestedCompanyId?: string | null
) => {
  const companyId = getScopedCompanyId(user, requestedCompanyId);

  if (!companyId) {
    throw new AuthorizationError("Company scope is required");
  }

  return companyId;
};
