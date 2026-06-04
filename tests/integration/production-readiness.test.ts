import fs from "node:fs";
import path from "node:path";

import request from "supertest";

import { app } from "../../src/app";

const readText = (...segments: string[]) => fs.readFileSync(path.join(process.cwd(), ...segments), "utf8");

describe("CP18 production readiness and deployment preparation", () => {
  it("keeps health and readiness public", async () => {
    await request(app).get("/health").expect(200);
    await request(app).get("/ready").expect(200);
  });

  it("keeps internal system verification routes unavailable in production", async () => {
    const previousNodeEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = "production";

    try {
      await request(app).get("/api/system/auth-check").expect(404);
      await request(app).get("/api/system/company-scope/company-1").expect(404);
    } finally {
      process.env.NODE_ENV = previousNodeEnv;
    }
  });

  it("returns stable error envelopes without stack traces", async () => {
    const response = await request(app).get("/missing-production-readiness-route").expect(404);

    expect(response.body).toEqual({
      error: {
        code: "NOT_FOUND",
        message: "Route GET /missing-production-readiness-route not found",
        requestId: expect.any(String)
      }
    });
    expect(JSON.stringify(response.body)).not.toContain("stack");
  });

  it("documents strict production environment and CORS guardrails in source", () => {
    const envSource = readText("src", "config", "env.ts");
    const corsSource = readText("src", "config", "cors.ts");
    const corsMiddlewareSource = readText("src", "middleware", "cors.middleware.ts");

    expect(envSource).toContain("staging");
    expect(envSource).toContain("production");
    expect(envSource).toContain("DATABASE_URL");
    expect(envSource).toContain("JWT_SECRET");
    expect(envSource).toContain("CORS_ORIGIN or CORS_ORIGINS is required in staging/production");
    expect(envSource).toContain("Wildcard CORS origins are not allowed with credentials");
    expect(corsSource).toContain("allowRequestsWithoutOrigin: !isProduction");
    expect(corsMiddlewareSource).toContain("allowedOrigins.includes(origin)");
  });

  it("keeps the example environment free of production credentials", () => {
    const envExample = readText(".env.example");

    expect(envExample).toContain("Local development example only");
    expect(envExample).toContain("replace-with-development-jwt-secret");
    expect(envExample).not.toMatch(/sk_live|pk_live|AKIA|BEGIN PRIVATE KEY|prod[_-]?secret/i);
    expect(envExample).not.toContain("example.com");
    expect(envExample).not.toContain("*");
  });

  it("exposes required deployment scripts", () => {
    const packageJson = JSON.parse(readText("package.json")) as { scripts: Record<string, string> };

    for (const scriptName of [
      "build",
      "start",
      "typecheck",
      "test",
      "prisma:validate",
      "prisma:generate",
      "prisma:migrate",
      "prisma:migrate:deploy",
      "prisma:seed",
      "seed"
    ]) {
      expect(packageJson.scripts).toHaveProperty(scriptName);
    }

    expect(packageJson.scripts["prisma:migrate"]).toContain("migrate deploy");
  });

  it("keeps the final backend handoff and smoke-test docs available", () => {
    const requiredDocs = [
      "docs/API_CONTRACT.md",
      "docs/FRONTEND_HANDOFF.md",
      "docs/LOVABLE_FRONTEND_PLAN.md",
      "docs/DEPLOYMENT_RUNBOOK.md",
      "docs/SMOKE_TEST_CHECKLIST.md",
      "docs/BACKEND_COMPLETION_SUMMARY.md"
    ];

    for (const relativePath of requiredDocs) {
      expect(fs.existsSync(path.join(process.cwd(), relativePath))).toBe(true);
    }
  });
});
