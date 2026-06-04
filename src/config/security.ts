import { isTest } from "./env";

export const securityConfig = {
  jsonBodyLimit: "1mb",
  globalRateLimit: {
    windowMs: 15 * 60 * 1000,
    max: isTest ? 1000 : 300
  }
};
