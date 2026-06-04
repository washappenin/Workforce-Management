import { env } from "../config/env";

type LogLevel = "info" | "warn" | "error" | "debug";

const logLevelPriority: Record<LogLevel, number> = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3
};

const sensitiveKeys = new Set(
  [
    "password",
    "passwordHash",
    "temporaryPassword",
    "email",
    "phone",
    "token",
    "accessToken",
    "refreshToken",
    "jwt",
    "authorization",
    "faceData",
    "faceImage",
    "rawFaceImage",
    "biometricData",
    "rawBiometricData",
    "faceVerificationPayload",
    "verificationReference",
    "providerSubjectId",
    "templateReference",
    "gps",
    "rawGps",
    "latitude",
    "longitude",
    "paymentInstrument",
    "providerReference",
    "cardNumber",
    "bankAccountNumber",
    "reason",
    "reviewComment",
    "summary",
    "description",
    "note",
    "comment",
    "message"
  ].map((key) => key.toLowerCase())
);

const redactValue = "[REDACTED]";

export const redactSensitiveData = (value: unknown): unknown => {
  if (Array.isArray(value)) {
    return value.map((item) => redactSensitiveData(item));
  }

  if (value && typeof value === "object") {
    return Object.entries(value as Record<string, unknown>).reduce<Record<string, unknown>>((acc, [key, entry]) => {
      acc[key] = sensitiveKeys.has(key.toLowerCase()) ? redactValue : redactSensitiveData(entry);
      return acc;
    }, {});
  }

  return value;
};

const writeLog = (level: LogLevel, message: string, meta?: Record<string, unknown>) => {
  if (logLevelPriority[level] < logLevelPriority[env.LOG_LEVEL]) {
    return;
  }

  const payload = {
    level,
    message,
    timestamp: new Date().toISOString(),
    ...(meta ? { meta: redactSensitiveData(meta) } : {})
  };

  const serialized = JSON.stringify(payload);

  if (level === "error") {
    console.error(serialized);
    return;
  }

  if (level === "warn") {
    console.warn(serialized);
    return;
  }

  console.log(serialized);
};

export const logger = {
  info: (message: string, meta?: Record<string, unknown>) => writeLog("info", message, meta),
  warn: (message: string, meta?: Record<string, unknown>) => writeLog("warn", message, meta),
  error: (message: string, meta?: Record<string, unknown>) => writeLog("error", message, meta),
  debug: (message: string, meta?: Record<string, unknown>) => writeLog("debug", message, meta)
};
