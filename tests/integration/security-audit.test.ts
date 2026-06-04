import fs from "node:fs";
import path from "node:path";

import request from "supertest";

import { app } from "../../src/app";
import type { AuditLogInput, AuditRepository } from "../../src/lib/audit";
import { recordAuditLog, resetAuditRepositoryForTests, setAuditRepositoryForTests } from "../../src/lib/audit";
import { redactSensitiveData } from "../../src/lib/logger";

const readText = (...segments: string[]) => fs.readFileSync(path.join(process.cwd(), ...segments), "utf8");

const readTsFiles = (directory: string): string[] => {
  const entries = fs.readdirSync(directory, { withFileTypes: true });

  return entries.flatMap((entry) => {
    const entryPath = path.join(directory, entry.name);

    if (entry.isDirectory()) {
      return readTsFiles(entryPath);
    }

    return entry.name.endsWith(".ts") ? [fs.readFileSync(entryPath, "utf8")] : [];
  });
};

const moduleSource = () => readTsFiles(path.join(process.cwd(), "src", "modules")).join("\n");

describe("CP17 security audit, privacy, and audit log coverage", () => {
  afterEach(() => {
    resetAuditRepositoryForTests();
  });

  it("keeps required sensitive state-changing actions covered by audit log calls", () => {
    const source = moduleSource();
    const expectedActions = [
      "COMPANY_CREATED",
      "COMPANY_UPDATED",
      "COMPANY_STATUS_CHANGED",
      "DEPARTMENT_CREATED",
      "DEPARTMENT_UPDATED",
      "DEPARTMENT_STATUS_CHANGED",
      "DESIGNATION_CREATED",
      "DESIGNATION_UPDATED",
      "DESIGNATION_STATUS_CHANGED",
      "EMPLOYEE_CREATED",
      "EMPLOYEE_UPDATED",
      "EMPLOYEE_STATUS_CHANGED",
      "EMPLOYEE_MANAGER_CHANGED",
      "GEOFENCE_CREATED",
      "GEOFENCE_UPDATED",
      "GEOFENCE_STATUS_CHANGED",
      "FACE_ENROLLMENT_CREATED",
      "FACE_ENROLLMENT_UPDATED",
      "FACE_ENROLLMENT_STATUS_CHANGED",
      "SHIFT_CREATED",
      "SHIFT_UPDATED",
      "SHIFT_STATUS_CHANGED",
      "SHIFT_ASSIGNED",
      "SHIFT_ASSIGNMENT_UPDATED",
      "SHIFT_ASSIGNMENT_REMOVED",
      "LEAVE_TYPE_CREATED",
      "LEAVE_TYPE_UPDATED",
      "LEAVE_TYPE_STATUS_CHANGED",
      "LEAVE_ENTITLEMENT_CREATED",
      "LEAVE_ENTITLEMENT_UPDATED",
      "LEAVE_REQUEST_SUBMITTED",
      "LEAVE_REQUEST_APPROVED",
      "LEAVE_REQUEST_REJECTED",
      "OKR_CREATED",
      "OKR_UPDATED",
      "OKR_STATUS_CHANGED",
      "OKR_PROGRESS_UPDATED",
      "OKR_EMPLOYEE_APPROVAL_SUBMITTED",
      "OKR_MANAGER_APPROVAL_SUBMITTED",
      "REVIEW_CYCLE_CREATED",
      "REVIEW_CYCLE_UPDATED",
      "REVIEW_CYCLE_STATUS_CHANGED",
      "PERFORMANCE_REVIEW_SUBMITTED",
      "PERFORMANCE_REVIEW_UPDATED",
      "PERFORMANCE_REVIEW_STATUS_CHANGED",
      "NOTIFICATION_BROADCAST_CREATED",
      "NOTIFICATION_BROADCAST_COMPLETED",
      "SUBSCRIPTION_PLAN_CREATED",
      "SUBSCRIPTION_PLAN_UPDATED",
      "SUBSCRIPTION_PLAN_STATUS_CHANGED",
      "COMPANY_SUBSCRIPTION_CREATED",
      "COMPANY_SUBSCRIPTION_STATUS_CHANGED",
      "PAYMENT_RECORD_CREATED"
    ];

    const missingActions = expectedActions.filter((action) => !source.includes(`"${action}"`));

    expect(missingActions).toEqual([]);
  });

  it("stores clock-in and clock-out operational records as attendance events instead of audit logs", () => {
    const attendanceService = readText("src", "modules", "attendance", "attendance.service.ts");

    expect(attendanceService).not.toContain("recordAuditLog");
    expect(attendanceService.match(/createAttendanceEvent/g)?.length ?? 0).toBeGreaterThanOrEqual(2);
  });

  it("sanitizes sensitive audit metadata before persistence", async () => {
    const capturedAudits: AuditLogInput[] = [];
    const auditRepository: AuditRepository = {
      async create(input) {
        capturedAudits.push(input);
      }
    };

    setAuditRepositoryForTests(auditRepository);

    await recordAuditLog({
      companyId: "company-1",
      actorUserId: "actor-1",
      category: "SECURITY",
      action: "CP17_SANITIZER_TEST",
      targetType: "SecurityAudit",
      targetId: "target-1",
      metadata: {
        employeeId: "employee-1",
        email: "private@example.test",
        temporaryPassword: "Password123!",
        passwordHash: "hashed-secret",
        providerSubjectId: "subject-secret",
        templateReference: "template-secret",
        providerReference: "payment-provider-secret",
        latitude: 9.0301,
        longitude: 38.74,
        reason: "leave-reason-secret",
        reviewComment: "leave-review-comment-secret",
        summary: "performance-summary-secret",
        description: "okr-description-secret",
        note: "okr-progress-note-secret",
        comment: "okr-approval-comment-secret",
        message: "notification-message-secret",
        startsAt: new Date("2026-06-04T00:00:00.000Z"),
        nested: {
          allowedId: "allowed-nested-id",
          faceVerificationPayload: "face-payload-secret",
          cardNumber: "4111111111111111"
        },
        approvals: [{ status: "APPROVED", comment: "nested-comment-secret" }]
      }
    });

    expect(capturedAudits).toHaveLength(1);
    expect(capturedAudits[0].metadata).toMatchObject({
      employeeId: "employee-1",
      startsAt: "2026-06-04T00:00:00.000Z",
      nested: { allowedId: "allowed-nested-id" },
      approvals: [{ status: "APPROVED" }]
    });

    const serializedAudit = JSON.stringify(capturedAudits[0]);

    for (const forbiddenValue of [
      "private@example.test",
      "Password123!",
      "hashed-secret",
      "subject-secret",
      "template-secret",
      "payment-provider-secret",
      "9.0301",
      "38.74",
      "leave-reason-secret",
      "leave-review-comment-secret",
      "performance-summary-secret",
      "okr-description-secret",
      "okr-progress-note-secret",
      "okr-approval-comment-secret",
      "notification-message-secret",
      "face-payload-secret",
      "4111111111111111",
      "nested-comment-secret"
    ]) {
      expect(serializedAudit).not.toContain(forbiddenValue);
    }
  });

  it("redacts CP17-sensitive metadata keys from logs case-insensitively", () => {
    const result = redactSensitiveData({
      Authorization: "Bearer token-secret",
      ProviderSubjectId: "subject-secret",
      templateReference: "template-secret",
      ProviderReference: "provider-secret",
      reviewComment: "comment-secret",
      nested: {
        Latitude: 9.0301,
        Longitude: 38.74,
        safeId: "safe-value"
      }
    });

    expect(result).toEqual({
      Authorization: "[REDACTED]",
      ProviderSubjectId: "[REDACTED]",
      templateReference: "[REDACTED]",
      ProviderReference: "[REDACTED]",
      reviewComment: "[REDACTED]",
      nested: {
        Latitude: "[REDACTED]",
        Longitude: "[REDACTED]",
        safeId: "safe-value"
      }
    });
  });

  it("keeps production system verification routes internal while health checks stay public", async () => {
    const previousNodeEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = "production";

    try {
      await request(app).get("/health").expect(200);
      await request(app).get("/ready").expect(200);
      await request(app).get("/api/system/auth-check").expect(404);
      await request(app).get("/api/system/company-scope/company-1").expect(404);
    } finally {
      process.env.NODE_ENV = previousNodeEnv;
    }
  });

  it("keeps CORS and JWT production behavior strict or explicitly documented", () => {
    const corsSource = readText("src", "middleware", "cors.middleware.ts");
    const envSource = readText("src", "config", "env.ts");
    const jwtSource = readText("src", "lib", "jwt.ts");
    const rateLimitSource = readText("src", "middleware", "rateLimit.middleware.ts");

    expect(corsSource).toContain("allowedOrigins.includes(origin)");
    expect(envSource).toContain("JWT_ACCESS_SECRET");
    expect(envSource).toContain("JWT_REFRESH_SECRET");
    expect(envSource).toContain("required in staging/production");
    expect(jwtSource).toContain("JWT_SECRET or JWT_ACCESS_SECRET is required");
    expect(rateLimitSource).toContain("globalRateLimit");
  });

  it("keeps cross-company and role-boundary regression suites present for all company-scoped modules", () => {
    const expectedCrossCompanySuites = [
      "organization.test.ts",
      "geofences.test.ts",
      "attendance.test.ts",
      "face-verification.test.ts",
      "shifts.test.ts",
      "leave.test.ts",
      "okrs.test.ts",
      "performance-reviews.test.ts",
      "notifications.test.ts",
      "reports.test.ts",
      "subscriptions.test.ts",
      "admin-hardening.test.ts"
    ];
    const missingCrossCompanyFixtures = expectedCrossCompanySuites.filter(
      (fileName) => !readText("tests", "integration", fileName).includes("company-2")
    );
    const roleBoundarySource = [
      "authorization.test.ts",
      "admin-hardening.test.ts",
      "reports.test.ts",
      "subscriptions.test.ts"
    ]
      .map((fileName) => readText("tests", "integration", fileName))
      .join("\n");

    expect(missingCrossCompanyFixtures).toEqual([]);
    expect(roleBoundarySource).toContain("EMPLOYEE");
    expect(roleBoundarySource).toContain("MANAGER");
    expect(roleBoundarySource).toContain("HR_ADMIN");
    expect(roleBoundarySource).toContain("COMPANY_ADMIN");
    expect(roleBoundarySource).toContain("SUPER_ADMIN");
  });
});
