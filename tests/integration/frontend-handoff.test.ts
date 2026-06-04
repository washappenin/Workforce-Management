import fs from "node:fs";
import path from "node:path";

const readText = (...segments: string[]) => fs.readFileSync(path.join(process.cwd(), ...segments), "utf8");

describe("CP19 frontend handoff package", () => {
  const requiredDocs = [
    "docs/FRONTEND_HANDOFF.md",
    "docs/LOVABLE_FRONTEND_PLAN.md",
    "docs/LOVABLE_PROMPT.md",
    "docs/FRONTEND_ROUTE_MAP.md",
    "docs/SCREEN_API_MATRIX.md",
    "docs/TEST_ACCOUNTS.md",
    "docs/API_CONTRACT.md",
    "docs/ROLE_PERMISSION_MATRIX.md",
    "docs/SMOKE_TEST_CHECKLIST.md"
  ];

  it("keeps all required CP19 handoff docs available", () => {
    for (const relativePath of requiredDocs) {
      expect(fs.existsSync(path.join(process.cwd(), relativePath))).toBe(true);
    }
  });

  it("keeps FRONTEND_HANDOFF.md complete enough for Lovable", () => {
    const handoff = readText("docs", "FRONTEND_HANDOFF.md");

    expect(handoff).toContain("CP19 FRONTEND HANDOFF PACKAGE READY");
    expect(handoff).toContain("STAGING_BACKEND_URL=TBD_AFTER_DEPLOYMENT");
    expect(handoff).toContain("Authorization: Bearer <token>");
    expect(handoff).toContain("## 34. Smoke Test Checklist Reference");
    expect(handoff).not.toMatch(/empty template|template only|not ready for lovable/i);
  });

  it("documents required Lovable prompt guardrails", () => {
    const prompt = readText("docs", "LOVABLE_PROMPT.md");

    expect(prompt).toContain("Do not invent endpoints");
    expect(prompt).toContain("Do not create self-registration");
    expect(prompt).toContain("Authorization: Bearer");
    expect(prompt).toContain("Use the backend API as the source of truth");
  });

  it("maps all required role areas in the frontend route map", () => {
    const routeMap = readText("docs", "FRONTEND_ROUTE_MAP.md");

    for (const area of ["## Public", "## Employee", "## Manager", "## HR/Admin", "## Super Admin"]) {
      expect(routeMap).toContain(area);
    }
  });

  it("maps screens to real implemented endpoint prefixes", () => {
    const matrix = readText("docs", "SCREEN_API_MATRIX.md");

    for (const endpointPrefix of [
      "/health",
      "/ready",
      "/api/auth",
      "/api/employees",
      "/api/admin/employees",
      "/api/geofences",
      "/api/admin/geofences",
      "/api/attendance",
      "/api/admin/attendance",
      "/api/face",
      "/api/admin/shifts",
      "/api/shifts",
      "/api/admin/leave-types",
      "/api/admin/leave-entitlements",
      "/api/admin/leave-requests",
      "/api/leave",
      "/api/okrs",
      "/api/admin/okrs",
      "/api/admin/review-cycles",
      "/api/reviews",
      "/api/admin/reviews",
      "/api/notifications",
      "/api/admin/notifications",
      "/api/admin/reports",
      "/api/reports/team",
      "/api/reports/me",
      "/api/super-admin/companies",
      "/api/super-admin/plans",
      "/api/super-admin/subscriptions",
      "/api/super-admin/payment-records",
      "/api/super-admin/reports",
      "/api/admin/subscription",
      "/api/admin/payment-records"
    ]) {
      expect(matrix).toContain(endpointPrefix);
    }
  });

  it("keeps TEST_ACCOUNTS.md free of obvious stored password values", () => {
    const testAccounts = readText("docs", "TEST_ACCOUNTS.md");

    expect(testAccounts).toContain("TBD_SUPER_ADMIN_EMAIL");
    expect(testAccounts).toContain("Secure password manager / staging secret");
    expect(testAccounts).not.toMatch(/password\s*[:=]\s*\S+/i);
    expect(testAccounts).not.toMatch(/Password123|P@ssw0rd|sk_live|pk_live|prod[_-]?secret|BEGIN PRIVATE KEY/i);
  });
});
