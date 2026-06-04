import "dotenv/config";
import { z } from "zod";

const envSchema = z
  .object({
    NODE_ENV: z.enum(["development", "test", "staging", "production"]).default("development"),
    PORT: z.coerce.number().int().positive().default(4000),
    LOG_LEVEL: z.enum(["debug", "info", "warn", "error"]).default("info"),
    CORS_ORIGIN: z.string().optional(),
    CORS_ORIGINS: z.string().default(""),
    DATABASE_URL: z.string().url().optional(),
    JWT_SECRET: z.string().optional(),
    JWT_ACCESS_SECRET: z.string().optional(),
    JWT_REFRESH_SECRET: z.string().optional(),
    JWT_ACCESS_TTL: z.string().default("15m"),
    JWT_REFRESH_TTL: z.string().default("7d"),
    FACE_PROVIDER: z.string().default("mock"),
    STORAGE_PROVIDER: z.string().default("local"),
    STRIPE_SECRET_KEY: z.string().optional(),
    TWILIO_ACCOUNT_SID: z.string().optional(),
    TWILIO_AUTH_TOKEN: z.string().optional(),
    EMAIL_PROVIDER: z.string().optional()
  })
  .superRefine((value, ctx) => {
    const isDeployedEnvironment = value.NODE_ENV === "staging" || value.NODE_ENV === "production";
    const corsOrigins = [value.CORS_ORIGIN, ...value.CORS_ORIGINS.split(",")]
      .map((origin) => origin?.trim())
      .filter((origin): origin is string => Boolean(origin));

    if (isDeployedEnvironment) {
      for (const key of ["DATABASE_URL", "JWT_SECRET", "JWT_REFRESH_SECRET"] as const) {
        if (!value[key]) {
          ctx.addIssue({
            code: z.ZodIssueCode.custom,
            message: `${key} is required in staging/production`,
            path: [key]
          });
        }
      }

      if (corsOrigins.length === 0) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: "CORS_ORIGIN or CORS_ORIGINS is required in staging/production",
          path: ["CORS_ORIGINS"]
        });
      }
    }

    if (corsOrigins.includes("*")) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "Wildcard CORS origins are not allowed with credentials",
        path: ["CORS_ORIGINS"]
      });
    }
  });

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  const details = parsed.error.issues.map((issue) => `${issue.path.join(".")}: ${issue.message}`).join("; ");
  throw new Error(`Invalid environment configuration: ${details}`);
}

export const env = parsed.data;

export const isProduction = env.NODE_ENV === "production";
export const isDeployedEnvironment = env.NODE_ENV === "staging" || env.NODE_ENV === "production";
export const isTest = env.NODE_ENV === "test";
