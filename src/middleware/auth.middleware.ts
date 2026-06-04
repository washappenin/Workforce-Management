import type { NextFunction, Request, Response } from "express";

import { authenticateAccessToken } from "../modules/auth/auth.service";
import { AuthenticationError } from "../lib/errors";

export const requireAuthentication = async (req: Request, _res: Response, next: NextFunction) => {
  const authHeader = req.header("authorization");
  const match = authHeader?.match(/^Bearer\s+(.+)$/i);

  if (!match) {
    return next(new AuthenticationError("Authentication required"));
  }

  try {
    const user = await authenticateAccessToken(match[1]);
    req.user = user;
    req.companyId = user.companyId ?? undefined;
    return next();
  } catch (error) {
    return next(error);
  }
};
