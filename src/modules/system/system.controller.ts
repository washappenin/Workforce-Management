import type { Request, Response } from "express";

import { getHealthStatus, getReadinessStatus } from "./system.service";

export const getHealth = (req: Request, res: Response) => {
  res.status(200).json({
    data: getHealthStatus(),
    meta: {
      requestId: req.id
    }
  });
};

export const getReadiness = async (req: Request, res: Response) => {
  const readiness = await getReadinessStatus();

  res.status(readiness.httpStatus).json({
    data: readiness.payload,
    meta: {
      requestId: req.id
    }
  });
};

export const getAuthCheck = (req: Request, res: Response) => {
  res.status(200).json({
    data: {
      authenticated: true,
      user: {
        id: req.user!.id,
        email: req.user!.email,
        companyId: req.user!.companyId,
        roles: req.user!.roles,
        status: req.user!.status
      }
    }
  });
};

export const getRoleCheck = (req: Request, res: Response) => {
  res.status(200).json({
    data: {
      allowed: true,
      roles: req.user!.roles
    }
  });
};

export const getCompanyScopeCheck = (req: Request, res: Response) => {
  res.status(200).json({
    data: {
      companyScope: req.companyScope
    }
  });
};
