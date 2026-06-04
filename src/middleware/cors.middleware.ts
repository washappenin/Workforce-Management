import cors from "cors";

import { corsConfig } from "../config/cors";

export const corsMiddleware = cors({
  credentials: corsConfig.credentials,
  origin: (origin, callback) => {
    if (!origin && corsConfig.allowRequestsWithoutOrigin) {
      callback(null, true);
      return;
    }

    if (origin && corsConfig.allowedOrigins.includes(origin)) {
      callback(null, true);
      return;
    }

    callback(new Error("Origin is not allowed by CORS"));
  }
});
