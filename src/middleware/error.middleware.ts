import type { NextFunction, Request, Response } from "express";

import { isProduction } from "../config/env";
import { AppError, NotFoundError, isAppError } from "../lib/errors";
import { logger } from "../lib/logger";

export const notFoundMiddleware = (req: Request, _res: Response, next: NextFunction) => {
  next(new NotFoundError(`Route ${req.method} ${req.originalUrl} not found`));
};

export const errorMiddleware = (error: unknown, req: Request, res: Response, _next: NextFunction) => {
  const appError = isAppError(error)
    ? error
    : new AppError({
        code: "INTERNAL_SERVER_ERROR",
        message: "Internal server error",
        statusCode: 500,
        expose: false
      });

  if (appError.statusCode >= 500) {
    logger.error("Unhandled request error", {
      requestId: req.id,
      code: appError.code,
      message: appError.message,
      stack: error instanceof Error ? error.stack : undefined
    });
  }

  const message = appError.expose || !isProduction ? appError.message : "Internal server error";

  res.status(appError.statusCode).json({
    error: {
      code: appError.code,
      message,
      requestId: req.id ?? req.header("x-request-id") ?? "unknown",
      ...(appError.details !== undefined ? { details: appError.details } : {})
    }
  });
};
