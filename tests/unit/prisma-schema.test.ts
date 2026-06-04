import { readFileSync } from "fs";
import { join } from "path";

const schema = readFileSync(join(__dirname, "..", "..", "prisma", "schema.prisma"), "utf8");

const requiredEnums = [
  "UserStatus",
  "CompanyStatus",
  "EmployeeStatus",
  "RoleName",
  "AttendanceStatus",
  "AttendanceEventType",
  "GeofenceStatus",
  "GeofenceBreachType",
  "FaceEnrollmentStatus",
  "ShiftStatus",
  "LeaveRequestStatus",
  "LeaveTypeStatus",
  "OKRStatus",
  "OKRApprovalStatus",
  "ReviewCycleStatus",
  "PerformanceReviewStatus",
  "NotificationType",
  "NotificationStatus",
  "SubscriptionPlanType",
  "SubscriptionStatus",
  "PaymentStatus",
  "AuditActionCategory",
  "DeviceSessionStatus"
];

const requiredModels = [
  "User",
  "Company",
  "Department",
  "Designation",
  "EmployeeProfile",
  "Role",
  "Permission",
  "UserRole",
  "Geofence",
  "FaceEnrollment",
  "AttendanceSession",
  "AttendanceEvent",
  "LocationPing",
  "GeofenceBreach",
  "Shift",
  "EmployeeShiftAssignment",
  "LeaveType",
  "LeaveEntitlement",
  "LeaveRequest",
  "OKR",
  "OKRProgressUpdate",
  "OKRApproval",
  "ReviewCycle",
  "PerformanceReview",
  "Notification",
  "SubscriptionPlan",
  "CompanySubscription",
  "PaymentRecord",
  "AuditLog",
  "DeviceSession"
];

const companyScopedModels = [
  "User",
  "Department",
  "Designation",
  "EmployeeProfile",
  "UserRole",
  "Geofence",
  "FaceEnrollment",
  "AttendanceSession",
  "AttendanceEvent",
  "LocationPing",
  "GeofenceBreach",
  "Shift",
  "EmployeeShiftAssignment",
  "LeaveType",
  "LeaveEntitlement",
  "LeaveRequest",
  "OKR",
  "OKRProgressUpdate",
  "OKRApproval",
  "ReviewCycle",
  "PerformanceReview",
  "Notification",
  "CompanySubscription",
  "PaymentRecord",
  "AuditLog",
  "DeviceSession"
];

const getBlock = (kind: "model" | "enum", name: string) => {
  const match = schema.match(new RegExp(`${kind}\\s+${name}\\s+\\{([\\s\\S]*?)\\n\\}`));
  return match?.[1] ?? "";
};

describe("Prisma CP2 schema", () => {
  it("defines all required enums", () => {
    for (const enumName of requiredEnums) {
      expect(getBlock("enum", enumName)).not.toEqual("");
    }
  });

  it("defines all required models", () => {
    for (const modelName of requiredModels) {
      expect(getBlock("model", modelName)).not.toEqual("");
    }
  });

  it("keeps tenant-owned records company-scoped and indexed", () => {
    for (const modelName of companyScopedModels) {
      const block = getBlock("model", modelName);

      expect(block).toMatch(/companyId\s+String\??/);
      expect(block).toContain("@@index([companyId]");
    }
  });

  it("does not store raw biometric images or vectors in FaceEnrollment", () => {
    const block = getBlock("model", "FaceEnrollment");

    expect(block).toContain("providerSubjectId String?");
    expect(block).toContain("templateReference String?");
    expect(block).not.toMatch(/raw|image|vector/i);
  });

  it("allows multiple geofences per company while indexing geofence status", () => {
    const block = getBlock("model", "Geofence");

    expect(block).toContain("@@unique([companyId, name])");
    expect(block).not.toContain("@@unique([companyId, status])");
    expect(block).toContain("@@index([status])");
  });

  it("supports open-session lookup for attendance service enforcement", () => {
    const block = getBlock("model", "AttendanceSession");

    expect(block).toContain("status              AttendanceStatus   @default(OPEN)");
    expect(block).toContain("@@index([employeeId, status])");
  });
});
