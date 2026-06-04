import type {
  AuditActionCategory,
  DeviceSessionStatus,
  EmployeeStatus,
  FaceEnrollmentStatus,
  UserStatus
} from "@prisma/client";
import request from "supertest";

import { app } from "../../src/app";
import type { AuditLogInput, AuditRepository } from "../../src/lib/audit";
import { resetAuditRepositoryForTests, setAuditRepositoryForTests } from "../../src/lib/audit";
import { resetFaceVerificationReferencesForTests } from "../../src/lib/faceMatch";
import { hashPassword } from "../../src/lib/password";
import type { AuthDeviceSessionRecord, AuthRepository, AuthUserRecord } from "../../src/modules/auth/auth.repository";
import { resetAuthRepositoryForTests, setAuthRepositoryForTests } from "../../src/modules/auth/auth.repository";
import type {
  FaceEmployeeProfileRecord,
  FaceEnrollmentRecord,
  FaceRepository,
  UpsertFaceEnrollmentRepositoryInput
} from "../../src/modules/face-verification/face.repository";
import { resetFaceRepositoryForTests, setFaceRepositoryForTests } from "../../src/modules/face-verification/face.repository";
import type { Role } from "../../src/types/auth";

interface MemoryState {
  users: Map<string, AuthUserRecord>;
  sessions: Map<string, AuthDeviceSessionRecord>;
  employees: Map<string, FaceEmployeeProfileRecord>;
  enrollments: Map<string, FaceEnrollmentRecord>;
  audits: AuditLogInput[];
  counters: Record<string, number>;
}

const now = () => new Date("2026-06-03T08:00:00.000Z");

const makeUser = (
  id: string,
  email: string,
  companyId: string | null,
  roles: Role[],
  passwordHash: string
): AuthUserRecord => ({
  id,
  email,
  passwordHash,
  status: "ACTIVE" as UserStatus,
  companyId,
  roles
});

const makeEmployeeProfile = (
  id: string,
  companyId: string,
  userId: string,
  status: EmployeeStatus = "ACTIVE" as EmployeeStatus
): FaceEmployeeProfileRecord => ({
  id,
  companyId,
  userId,
  status
});

const makeEnrollment = (
  id: string,
  companyId: string,
  employeeId: string,
  status: FaceEnrollmentStatus = "ACTIVE" as FaceEnrollmentStatus
): FaceEnrollmentRecord => ({
  id,
  companyId,
  employeeId,
  provider: "mock",
  providerSubjectId: `mock-subject-${employeeId}`,
  templateReference: `mock-template-${employeeId}`,
  status,
  enrolledAt: status === "ACTIVE" ? now() : null,
  createdAt: now(),
  updatedAt: now()
});

const createState = (passwordHash: string): MemoryState => {
  const users = [
    makeUser("user-super-admin", "superadmin@example.test", null, ["SUPER_ADMIN"], passwordHash),
    makeUser("user-company-admin", "companyadmin@example.test", "company-1", ["COMPANY_ADMIN"], passwordHash),
    makeUser("user-hr-admin", "hradmin@example.test", "company-1", ["HR_ADMIN"], passwordHash),
    makeUser("user-manager", "manager@example.test", "company-1", ["MANAGER"], passwordHash),
    makeUser("user-employee", "employee@example.test", "company-1", ["EMPLOYEE"], passwordHash),
    makeUser("user-company2-employee", "company2employee@example.test", "company-2", ["EMPLOYEE"], passwordHash)
  ];
  const employees = [
    makeEmployeeProfile("employee-company-admin", "company-1", "user-company-admin"),
    makeEmployeeProfile("employee-hr-admin", "company-1", "user-hr-admin"),
    makeEmployeeProfile("employee-manager", "company-1", "user-manager"),
    makeEmployeeProfile("employee-self", "company-1", "user-employee"),
    makeEmployeeProfile("employee-company2", "company-2", "user-company2-employee")
  ];
  const enrollments = [
    makeEnrollment("enrollment-self", "company-1", "employee-self"),
    makeEnrollment("enrollment-company2", "company-2", "employee-company2")
  ];

  return {
    users: new Map(users.map((user) => [user.id, user])),
    sessions: new Map(),
    employees: new Map(employees.map((employee) => [employee.id, employee])),
    enrollments: new Map(enrollments.map((enrollment) => [enrollment.employeeId, enrollment])),
    audits: [],
    counters: {
      session: 0,
      enrollment: 0
    }
  };
};

const createRepositories = (state: MemoryState) => {
  const authRepository: AuthRepository = {
    async findUsersByEmail(email) {
      return Array.from(state.users.values()).filter((user) => user.email === email);
    },

    async findUserById(userId) {
      return state.users.get(userId) ?? null;
    },

    async updateLastLoginAt() {
      return undefined;
    },

    async createDeviceSession(input) {
      state.counters.session += 1;
      const session = {
        id: `auth-session-${state.counters.session}`,
        userId: input.userId,
        companyId: input.companyId ?? null,
        status: "ACTIVE" as DeviceSessionStatus
      };

      state.sessions.set(session.id, session);
      return session;
    },

    async findActiveDeviceSessionById(sessionId) {
      const session = state.sessions.get(sessionId);
      return session?.status === "ACTIVE" ? session : null;
    },

    async revokeDeviceSession(sessionId, userId) {
      const session = state.sessions.get(sessionId);

      if (session?.userId === userId) {
        state.sessions.set(sessionId, { ...session, status: "REVOKED" as DeviceSessionStatus });
      }
    }
  };

  const faceRepository: FaceRepository = {
    async findEmployeeByIdInCompany(employeeId, companyId) {
      const employee = state.employees.get(employeeId);
      return employee?.companyId === companyId ? employee : null;
    },

    async findEmployeeByUserId(userId) {
      return Array.from(state.employees.values()).find((employee) => employee.userId === userId) ?? null;
    },

    async findEnrollmentByEmployeeInCompany(employeeId, companyId) {
      const enrollment = state.enrollments.get(employeeId);
      return enrollment?.companyId === companyId ? enrollment : null;
    },

    async upsertEnrollment(input: UpsertFaceEnrollmentRepositoryInput) {
      const current = state.enrollments.get(input.employeeId);
      state.counters.enrollment += current ? 0 : 1;
      const enrollment: FaceEnrollmentRecord = {
        id: current?.id ?? `face-enrollment-${state.counters.enrollment}`,
        companyId: input.companyId,
        employeeId: input.employeeId,
        provider: input.provider,
        providerSubjectId: input.providerSubjectId ?? null,
        templateReference: input.templateReference ?? null,
        status: input.status,
        enrolledAt: input.enrolledAt ?? null,
        createdAt: current?.createdAt ?? now(),
        updatedAt: now()
      };

      state.enrollments.set(enrollment.employeeId, enrollment);
      return enrollment;
    },

    async updateEnrollmentStatus(employeeId, companyId, status, enrolledAt) {
      const current = await this.findEnrollmentByEmployeeInCompany(employeeId, companyId);
      const enrollment = {
        ...current!,
        status,
        enrolledAt,
        updatedAt: now()
      };

      state.enrollments.set(employeeId, enrollment);
      return enrollment;
    }
  };

  const auditRepository: AuditRepository = {
    async create(input) {
      state.audits.push(input);
    }
  };

  return { authRepository, faceRepository, auditRepository };
};

describe("CP8 face verification integration layer", () => {
  let passwordHash: string;
  let state: MemoryState;

  beforeAll(async () => {
    passwordHash = await hashPassword("Password123!");
  });

  beforeEach(() => {
    state = createState(passwordHash);
    const repositories = createRepositories(state);

    setAuthRepositoryForTests(repositories.authRepository);
    setFaceRepositoryForTests(repositories.faceRepository);
    setAuditRepositoryForTests(repositories.auditRepository);
  });

  afterEach(() => {
    resetAuthRepositoryForTests();
    resetFaceRepositoryForTests();
    resetAuditRepositoryForTests();
    resetFaceVerificationReferencesForTests();
  });

  const login = async (email: string) => {
    const response = await request(app).post("/api/auth/login").send({ email, password: "Password123!" }).expect(200);

    return response.body.data.accessToken as string;
  };

  const auditActions = (category?: AuditActionCategory) =>
    state.audits.filter((audit) => !category || audit.category === category).map((audit) => audit.action);

  describe("admin enrollment and status", () => {
    it("allows COMPANY_ADMIN and HR_ADMIN to manage own-company enrollments without exposing provider references", async () => {
      const companyAdminToken = await login("companyadmin@example.test");
      const hrAdminToken = await login("hradmin@example.test");

      const createResponse = await request(app)
        .post("/api/admin/employees/employee-manager/face-enrollment")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ provider: "mock", providerSubjectId: "subject-safe-ref", templateReference: "template-safe-ref" })
        .expect(201);
      const statusResponse = await request(app)
        .get("/api/admin/employees/employee-manager/face-status")
        .set("Authorization", `Bearer ${hrAdminToken}`)
        .expect(200);

      expect(createResponse.body.data.faceEnrollment).toMatchObject({
        employeeId: "employee-manager",
        companyId: "company-1",
        provider: "mock",
        status: "ACTIVE"
      });
      expect(statusResponse.body.data.faceEnrollment).toMatchObject({
        employeeId: "employee-manager",
        status: "ACTIVE"
      });
      expect(JSON.stringify(createResponse.body)).not.toContain("subject-safe-ref");
      expect(JSON.stringify(createResponse.body)).not.toContain("template-safe-ref");
      expect(JSON.stringify(statusResponse.body)).not.toContain("providerSubjectId");
      expect(JSON.stringify(statusResponse.body)).not.toContain("templateReference");
      expect(auditActions("FACE_VERIFICATION")).toEqual(["FACE_ENROLLMENT_CREATED"]);
      expect(JSON.stringify(state.audits)).not.toContain("subject-safe-ref");
      expect(JSON.stringify(state.audits)).not.toContain("template-safe-ref");
    });

    it("allows SUPER_ADMIN enrollment only with explicit company scope", async () => {
      const token = await login("superadmin@example.test");

      await request(app)
        .post("/api/admin/employees/employee-company2/face-enrollment")
        .set("Authorization", `Bearer ${token}`)
        .send({ provider: "mock" })
        .expect(403);

      const response = await request(app)
        .post("/api/admin/employees/employee-company2/face-enrollment")
        .set("Authorization", `Bearer ${token}`)
        .send({ companyId: "company-2", provider: "mock" })
        .expect(201);

      expect(response.body.data.faceEnrollment).toMatchObject({
        employeeId: "employee-company2",
        companyId: "company-2",
        status: "ACTIVE"
      });
    });

    it("rejects employees, managers, cross-company enrollment, and raw face payload fields", async () => {
      const employeeToken = await login("employee@example.test");
      const managerToken = await login("manager@example.test");
      const companyAdminToken = await login("companyadmin@example.test");

      await request(app)
        .post("/api/admin/employees/employee-self/face-enrollment")
        .set("Authorization", `Bearer ${employeeToken}`)
        .send({ provider: "mock" })
        .expect(403);
      await request(app)
        .post("/api/admin/employees/employee-self/face-enrollment")
        .set("Authorization", `Bearer ${managerToken}`)
        .send({ provider: "mock" })
        .expect(403);
      await request(app)
        .post("/api/admin/employees/employee-company2/face-enrollment")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ provider: "mock" })
        .expect(404);
      await request(app)
        .post("/api/admin/employees/employee-manager/face-enrollment")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ provider: "mock", rawImage: "base64-image-data" })
        .expect(400);
    });

    it("updates enrollment status with audit logging and keeps admin reads company scoped", async () => {
      const companyAdminToken = await login("companyadmin@example.test");
      const employeeToken = await login("employee@example.test");

      const response = await request(app)
        .patch("/api/admin/employees/employee-self/face-enrollment/status")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ status: "DISABLED" })
        .expect(200);

      expect(response.body.data.faceEnrollment).toMatchObject({
        employeeId: "employee-self",
        status: "DISABLED",
        enrolledAt: null
      });
      expect(auditActions("FACE_VERIFICATION")).toEqual(["FACE_ENROLLMENT_STATUS_CHANGED"]);
      await request(app)
        .get("/api/admin/employees/employee-company2/face-status")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .expect(404);
      await request(app)
        .get("/api/admin/employees/employee-self/face-status")
        .set("Authorization", `Bearer ${employeeToken}`)
        .expect(403);
    });
  });

  describe("self-service verification", () => {
    it("verifies an active enrollment with mock-pass and returns only a short-lived reference", async () => {
      const token = await login("employee@example.test");

      const response = await request(app)
        .post("/api/face/verify")
        .set("Authorization", `Bearer ${token}`)
        .send({ provider: "mock", verificationReference: "mock-pass" })
        .expect(200);

      expect(response.body.data).toMatchObject({
        verified: true,
        employeeId: "employee-self",
        provider: "mock"
      });
      expect(response.body.data.verificationReference).toEqual(expect.stringContaining("face-verification-"));
      expect(response.body.data.expiresAt).toBeTruthy();
      expect(JSON.stringify(response.body)).not.toContain("providerSubjectId");
      expect(JSON.stringify(response.body)).not.toContain("templateReference");
      expect(state.audits).toHaveLength(0);
    });

    it("returns a failed verification result for mock-fail without issuing a clock-in reference", async () => {
      const token = await login("employee@example.test");

      const response = await request(app)
        .post("/api/face/verify")
        .set("Authorization", `Bearer ${token}`)
        .send({ provider: "mock", verificationReference: "mock-fail" })
        .expect(200);

      expect(response.body.data).toEqual({
        verified: false,
        reason: "FACE_NOT_MATCHED"
      });
    });

    it("rejects missing active enrollment, another employee target, SUPER_ADMIN, missing auth, and invalid payloads", async () => {
      const managerToken = await login("manager@example.test");
      const employeeToken = await login("employee@example.test");
      const superAdminToken = await login("superadmin@example.test");

      await request(app)
        .post("/api/face/verify")
        .set("Authorization", `Bearer ${managerToken}`)
        .send({ provider: "mock", verificationReference: "mock-pass" })
        .expect(403);
      await request(app)
        .post("/api/face/verify")
        .set("Authorization", `Bearer ${employeeToken}`)
        .send({ employeeId: "employee-manager", provider: "mock", verificationReference: "mock-pass" })
        .expect(403);
      await request(app)
        .post("/api/face/verify")
        .set("Authorization", `Bearer ${superAdminToken}`)
        .send({ provider: "mock", verificationReference: "mock-pass" })
        .expect(403);
      await request(app).post("/api/face/verify").send({ provider: "mock", verificationReference: "mock-pass" }).expect(401);
      await request(app)
        .post("/api/face/verify")
        .set("Authorization", `Bearer ${employeeToken}`)
        .send({ provider: "real-vendor", verificationReference: "mock-pass" })
        .expect(400);
    });
  });
});
