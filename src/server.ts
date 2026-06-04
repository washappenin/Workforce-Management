import { app } from "./app";
import { env } from "./config/env";
import { disconnectPrisma } from "./lib/prisma";
import { logger } from "./lib/logger";

const server = app.listen(env.PORT, () => {
  logger.info("Workforce backend listening", {
    port: env.PORT,
    environment: env.NODE_ENV
  });
});

const shutdown = async (signal: string) => {
  logger.info("Shutdown signal received", { signal });
  server.close(async () => {
    await disconnectPrisma();
    process.exit(0);
  });
};

process.on("SIGINT", () => void shutdown("SIGINT"));
process.on("SIGTERM", () => void shutdown("SIGTERM"));
