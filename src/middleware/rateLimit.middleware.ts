import rateLimit from "express-rate-limit";

import { securityConfig } from "../config/security";

export const globalRateLimitMiddleware = rateLimit({
  windowMs: securityConfig.globalRateLimit.windowMs,
  max: securityConfig.globalRateLimit.max,
  standardHeaders: true,
  legacyHeaders: false
});
