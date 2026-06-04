import type { NextFunction, Request, Response } from "express";

import { getScopedCompanyId, isSuperAdmin } from "../lib/authorization";
import { AuthenticationError, AuthorizationError } from "../lib/errors";

interface CompanyScopeOptions {
  required?: boolean;
}

const getStringCompanyId = (value: unknown) => {
  if (typeof value === "string" && value.trim().length > 0) {
    return value.trim();
  }

  return undefined;
};

const collectRequestedCompanyIds = (req: Request) =>
  [
    getStringCompanyId(req.params.companyId),
    getStringCompanyId(req.body?.companyId),
    getStringCompanyId(req.query.companyId)
  ].filter((companyId): companyId is string => Boolean(companyId));

export const requireCompanyScope =
  (options: CompanyScopeOptions = {}) =>
  (req: Request, _res: Response, next: NextFunction) => {
    if (!req.user) {
      return next(new AuthenticationError());
    }

    const requestedCompanyIds = collectRequestedCompanyIds(req);
    const uniqueRequestedCompanyIds = Array.from(new Set(requestedCompanyIds));

    if (uniqueRequestedCompanyIds.length > 1) {
      return next(new AuthorizationError("Company scope mismatch"));
    }

    const requestedCompanyId = uniqueRequestedCompanyIds[0] ?? null;

    if (options.required && !requestedCompanyId && !isSuperAdmin(req.user)) {
      return next(new AuthorizationError("Company scope is required"));
    }

    try {
      const scopedCompanyId = getScopedCompanyId(req.user, requestedCompanyId);

      req.companyScope = {
        companyId: scopedCompanyId,
        isSuperAdmin: isSuperAdmin(req.user),
        requestedCompanyId
      };
      req.companyId = scopedCompanyId ?? undefined;

      return next();
    } catch (error) {
      return next(error);
    }
  };

export const attachCompanyScope = requireCompanyScope();

export const requireRouteCompanyScope = requireCompanyScope({ required: true });
