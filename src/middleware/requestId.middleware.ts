import { randomUUID } from "crypto";
import type { NextFunction, Request, Response } from "express";

export const requestIdMiddleware = (req: Request, res: Response, next: NextFunction) => {
  const incomingRequestId = req.header("x-request-id");
  const requestId = incomingRequestId && incomingRequestId.trim().length > 0 ? incomingRequestId : randomUUID();

  req.id = requestId;
  res.setHeader("x-request-id", requestId);

  next();
};
