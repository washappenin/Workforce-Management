import { Router } from "express";
import type { NextFunction, Request, Response } from "express";

import { NotFoundError } from "../../lib/errors";
import { requireAuthentication } from "../../middleware/auth.middleware";
import { requireRouteCompanyScope } from "../../middleware/companyScope.middleware";
import {
  requireAnyRole,
  requireCompanyAdmin,
  requireEmployee,
  requireHrAdmin,
  requireManager,
  requireSuperAdmin
} from "../../middleware/role.middleware";
import { getAuthCheck, getCompanyScopeCheck, getHealth, getReadiness, getRoleCheck } from "./system.controller";

export const systemRouter = Router();

const internalVerificationRouteGuard = (req: Request, _res: Response, next: NextFunction) => {
  if (process.env.NODE_ENV === "production") {
    return next(new NotFoundError(`Route ${req.method} ${req.originalUrl} not found`));
  }

  return next();
};

systemRouter.get("/health", getHealth);
systemRouter.get("/ready", getReadiness);

// CP4 internal verification routes. These are not product features.
systemRouter.use("/api/system", internalVerificationRouteGuard);
systemRouter.get("/api/system/auth-check", requireAuthentication, getAuthCheck);
systemRouter.get("/api/system/role-check/super-admin", requireAuthentication, requireSuperAdmin, getRoleCheck);
systemRouter.get("/api/system/role-check/company-admin", requireAuthentication, requireCompanyAdmin, getRoleCheck);
systemRouter.get("/api/system/role-check/hr-admin", requireAuthentication, requireHrAdmin, getRoleCheck);
systemRouter.get("/api/system/role-check/manager", requireAuthentication, requireManager, getRoleCheck);
systemRouter.get("/api/system/role-check/employee", requireAuthentication, requireEmployee, getRoleCheck);
systemRouter.get(
  "/api/system/role-check/admin-or-hr",
  requireAuthentication,
  requireAnyRole(["COMPANY_ADMIN", "HR_ADMIN"]),
  getRoleCheck
);
systemRouter.get(
  "/api/system/company-scope-required",
  requireAuthentication,
  requireRouteCompanyScope,
  getCompanyScopeCheck
);
systemRouter.get(
  "/api/system/company-scope/:companyId",
  requireAuthentication,
  requireRouteCompanyScope,
  getCompanyScopeCheck
);
systemRouter.post(
  "/api/system/company-scope/:companyId",
  requireAuthentication,
  requireRouteCompanyScope,
  getCompanyScopeCheck
);
