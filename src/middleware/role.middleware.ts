import type { NextFunction, Request, Response } from "express";

import { hasAnyRole } from "../lib/authorization";
import { AuthenticationError, AuthorizationError } from "../lib/errors";
import type { Role } from "../types/auth";

export const requireAnyRole =
  (allowedRoles: Role[]) =>
  (req: Request, _res: Response, next: NextFunction) => {
    if (!req.user) {
      return next(new AuthenticationError());
    }

    if (!hasAnyRole(req.user, allowedRoles)) {
      return next(new AuthorizationError());
    }

    return next();
  };

export const requireRole = (role: Role) => requireAnyRole([role]);

export const requireRoles = (...allowedRoles: Role[]) => requireAnyRole(allowedRoles);

export const requireSuperAdmin = requireRole("SUPER_ADMIN");
export const requireCompanyAdmin = requireRole("COMPANY_ADMIN");
export const requireHrAdmin = requireRole("HR_ADMIN");
export const requireManager = requireRole("MANAGER");
export const requireEmployee = requireRole("EMPLOYEE");
