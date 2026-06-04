import { env, isProduction } from "./env";

export const allowedOrigins = [env.CORS_ORIGIN, ...env.CORS_ORIGINS.split(",")]
  .map((origin) => origin?.trim() ?? "")
  .filter(Boolean);

export const corsConfig = {
  allowedOrigins,
  credentials: true,
  allowRequestsWithoutOrigin: !isProduction
};
