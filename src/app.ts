import express from "express";
import helmet from "helmet";

import { securityConfig } from "./config/security";
import { corsMiddleware } from "./middleware/cors.middleware";
import { errorMiddleware, notFoundMiddleware } from "./middleware/error.middleware";
import { globalRateLimitMiddleware } from "./middleware/rateLimit.middleware";
import { requestIdMiddleware } from "./middleware/requestId.middleware";
import { router } from "./routes";

export const createApp = () => {
  const app = express();

  app.disable("x-powered-by");
  app.use(helmet());
  app.use(requestIdMiddleware);
  app.use(corsMiddleware);
  app.use(express.json({ limit: securityConfig.jsonBodyLimit }));
  app.use(globalRateLimitMiddleware);
  app.use(router);
  app.use(notFoundMiddleware);
  app.use(errorMiddleware);

  return app;
};

export const app = createApp();
