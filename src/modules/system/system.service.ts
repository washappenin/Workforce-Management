import { env } from "../../config/env";
import { checkDatabaseReady } from "../../lib/prisma";

export const getHealthStatus = () => ({
  status: "ok",
  uptime: process.uptime(),
  timestamp: new Date().toISOString(),
  environment: env.NODE_ENV
});

export const getReadinessStatus = async () => {
  const database = await checkDatabaseReady();
  const databaseReady = database.status === "connected" || (env.NODE_ENV !== "production" && database.status === "not_configured");
  const ready = databaseReady;

  return {
    httpStatus: ready ? 200 : 503,
    payload: {
      status: ready ? "ready" : "not_ready",
      timestamp: new Date().toISOString(),
      checks: {
        database
      }
    }
  };
};
