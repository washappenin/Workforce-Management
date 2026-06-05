import fs from "node:fs";
import path from "node:path";

const readText = (...segments: string[]) => fs.readFileSync(path.join(process.cwd(), ...segments), "utf8");

describe("staging deployment readiness", () => {
  it("exposes required deploy scripts", () => {
    const packageJson = JSON.parse(readText("package.json")) as { scripts: Record<string, string> };

    expect(packageJson.scripts.build).toBe("tsc -p tsconfig.build.json");
    expect(packageJson.scripts.start).toBe("node dist/server.js");
    expect(packageJson.scripts["prisma:generate"]).toContain("scripts/prisma.cjs generate");
    expect(packageJson.scripts["prisma:migrate"]).toContain("migrate deploy");
    expect(packageJson.scripts["prisma:migrate:deploy"]).toContain("migrate deploy");
    expect(packageJson.scripts.seed).toBe("npm run prisma:seed");
  });

  it("keeps staging environment validation and migration guardrails documented in source", () => {
    const envSource = readText("src", "config", "env.ts");
    const corsSource = readText("src", "config", "cors.ts");
    const prismaScript = readText("scripts", "prisma.cjs");

    expect(envSource).toContain("NODE_ENV");
    expect(envSource).toContain("staging");
    expect(envSource).toContain("DATABASE_URL");
    expect(envSource).toContain("JWT_SECRET");
    expect(envSource).toContain("JWT_REFRESH_SECRET");
    expect(envSource).toContain("CORS_ORIGIN or CORS_ORIGINS is required in staging/production");
    expect(envSource).toContain("Wildcard CORS origins are not allowed with credentials");
    expect(corsSource).toContain("allowedOrigins");
    expect(corsSource).toContain("credentials: true");
    expect(prismaScript).toContain("DATABASE_URL is required for prisma migrate deploy in staging/production.");
  });

  it("documents required staging environment variables without secrets", () => {
    const checklist = readText("docs", "STAGING_ENV_CHECKLIST.md");

    for (const variableName of [
      "NODE_ENV",
      "PORT",
      "DATABASE_URL",
      "JWT_SECRET",
      "JWT_REFRESH_SECRET",
      "CORS_ORIGIN",
      "CORS_ORIGINS",
      "LOG_LEVEL",
      "FACE_PROVIDER",
      "STRIPE_SECRET_KEY",
      "TWILIO_ACCOUNT_SID",
      "TWILIO_AUTH_TOKEN",
      "EMAIL_PROVIDER"
    ]) {
      expect(checklist).toContain(variableName);
    }

    expect(checklist).toContain("STAGING_BACKEND_URL=https://workforce-management-production.up.railway.app");
    expect(checklist).toContain("Do not commit real staging secrets");
    expect(checklist).not.toMatch(/sk_live|pk_live|AKIA|BEGIN PRIVATE KEY|prod[_-]?secret/i);
  });

  it("documents exact staging deployment and smoke-test flow", () => {
    const runbook = readText("docs", "DEPLOYMENT_RUNBOOK.md");
    const smoke = readText("docs", "SMOKE_TEST_CHECKLIST.md");

    for (const expected of [
      "npm ci",
      "npm run prisma:generate",
      "npm run build",
      "npm run prisma:migrate:deploy",
      "npm run start",
      "$STAGING_BACKEND_URL/health",
      "$STAGING_BACKEND_URL/ready",
      "NODE_ENV=staging",
      "NODE_ENV=production"
    ]) {
      expect(runbook).toContain(expected);
    }

    expect(smoke).toContain("docs/STAGING_ENV_CHECKLIST.md");
    expect(smoke).toContain("Login succeeds as `SUPER_ADMIN`");
    expect(smoke).toContain("CORS allows only the intended frontend/Lovable origin");
    expect(smoke).toContain("/api/system/*` returns `404`");
  });

  it("keeps synthetic test accounts as placeholders only", () => {
    const testAccounts = readText("docs", "TEST_ACCOUNTS.md");

    for (const role of ["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN", "MANAGER", "EMPLOYEE"]) {
      expect(testAccounts).toContain(role);
    }

    expect(testAccounts).toContain("TBD_STAGING_COMPANY");
    expect(testAccounts).toContain("Secure password manager / staging secret");
    expect(testAccounts).not.toMatch(/password\s*[:=]\s*\S+/i);
    expect(testAccounts).not.toMatch(/Password123|P@ssw0rd|sk_live|pk_live|prod[_-]?secret|BEGIN PRIVATE KEY/i);
  });
});
