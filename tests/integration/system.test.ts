import request from "supertest";

import { app } from "../../src/app";

describe("system endpoints", () => {
  it("returns health status with the standard success envelope", async () => {
    const response = await request(app).get("/health").expect(200);

    expect(response.body).toEqual({
      data: {
        status: "ok",
        uptime: expect.any(Number),
        timestamp: expect.any(String),
        environment: "test"
      },
      meta: {
        requestId: expect.any(String)
      }
    });
    expect(response.headers["x-request-id"]).toEqual(response.body.meta.requestId);
  });

  it("returns readiness status with database configuration details", async () => {
    const response = await request(app).get("/ready").expect(200);

    expect(response.body.data).toEqual({
      status: "ready",
      timestamp: expect.any(String),
      checks: {
        database: {
          configured: false,
          status: "not_configured",
          message: "DATABASE_URL is not configured"
        }
      }
    });
    expect(response.body.meta.requestId).toEqual(expect.any(String));
  });

  it("returns the standard error envelope for unknown routes", async () => {
    const response = await request(app).get("/missing").expect(404);

    expect(response.body).toEqual({
      error: {
        code: "NOT_FOUND",
        message: "Route GET /missing not found",
        requestId: expect.any(String)
      }
    });
  });
});
