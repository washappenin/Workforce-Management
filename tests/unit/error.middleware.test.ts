import express from "express";
import request from "supertest";

import { AppError } from "../../src/lib/errors";
import { errorMiddleware } from "../../src/middleware/error.middleware";
import { requestIdMiddleware } from "../../src/middleware/requestId.middleware";

describe("error middleware", () => {
  it("returns standardized error envelopes", async () => {
    const app = express();

    app.use(requestIdMiddleware);
    app.get("/boom", (_req, _res, next) => {
      next(
        new AppError({
          code: "TEST_ERROR",
          message: "Test failure",
          statusCode: 409,
          details: { reason: "conflict" }
        })
      );
    });
    app.use(errorMiddleware);

    const response = await request(app).get("/boom").expect(409);

    expect(response.body).toEqual({
      error: {
        code: "TEST_ERROR",
        message: "Test failure",
        requestId: expect.any(String),
        details: { reason: "conflict" }
      }
    });
  });
});
