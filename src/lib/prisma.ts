import { PrismaClient } from "@prisma/client";

import { env } from "../config/env";
import { logger } from "./logger";

let client: PrismaClient | undefined;

export const getPrismaClient = () => {
  if (!client) {
    client = new PrismaClient({
      log: env.NODE_ENV === "development" ? ["warn", "error"] : ["error"]
    });
  }

  return client;
};

export const disconnectPrisma = async () => {
  if (client) {
    await client.$disconnect();
    client = undefined;
  }
};

export type DatabaseReadyStatus = "connected" | "not_configured" | "unreachable";

export interface DatabaseReadyCheck {
  configured: boolean;
  status: DatabaseReadyStatus;
  message?: string;
}

export const checkDatabaseReady = async (): Promise<DatabaseReadyCheck> => {
  if (!env.DATABASE_URL) {
    return {
      configured: false,
      status: "not_configured",
      message: "DATABASE_URL is not configured"
    };
  }

  try {
    await getPrismaClient().$queryRaw`SELECT 1`;
    return { configured: true, status: "connected" };
  } catch (error) {
    logger.warn("Database readiness check failed", { error });
    return {
      configured: true,
      status: "unreachable",
      message: "Database connection failed"
    };
  }
};
