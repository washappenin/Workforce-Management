import type { NextFunction, Request, Response } from "express";
import type { ZodSchema } from "zod";

import { ValidationError } from "../lib/errors";

interface ValidationSchemas {
  body?: ZodSchema;
  query?: ZodSchema;
  params?: ZodSchema;
}

interface ValidationOptions {
  statusCode?: 400 | 422;
}

export const validateRequest =
  (schemas: ValidationSchemas, options: ValidationOptions = {}) =>
  (req: Request, _res: Response, next: NextFunction) => {
    for (const [location, schema] of Object.entries(schemas) as [keyof ValidationSchemas, ZodSchema][]) {
      if (!schema) {
        continue;
      }

      const result = schema.safeParse(req[location]);

      if (!result.success) {
        return next(new ValidationError(`Invalid ${location}`, result.error.issues, options.statusCode));
      }

      req[location] = result.data;
    }

    return next();
  };
