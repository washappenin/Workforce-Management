import type {
  AuditActionCategory,
  CompanyStatus,
  DeviceSessionStatus,
  EmployeeStatus,
  OKRApprovalStatus,
  OKRStatus,
  UserStatus
} from "@prisma/client";
import request from "supertest";

import { app } from "../../src/app";
import type { AuditLogInput, AuditRepository } from "../../src/lib/audit";
import { resetAuditRepositoryForTests, setAuditRepositoryForTests } from "../../src/lib/audit";
import { hashPassword } from "../../src/lib/password";
import type { AuthDeviceSessionRecord, AuthRepository, AuthUserRecord } from "../../src/modules/auth/auth.repository";
import { resetAuthRepositoryForTests, setAuthRepositoryForTests } from "../../src/modules/auth/auth.repository";
import type {
  CreateOkrProgressRepositoryInput,
  CreateOkrRepositoryInput,
  OkrApprovalRecord,
  OkrCompanyRecord,
  OkrEmployeeProfileRecord,
  OkrListFilters,
  OkrProgressUpdateRecord,
  OkrRecord,
  OkrsRepository,
  UpdateOkrRepositoryInput,
  UpsertOkrApprovalRepositoryInput
} from "../../src/modules/okrs/okrs.repository";
import { resetOkrsRepositoryForTests, setOkrsRepositoryForTests } from "../../src/modules/okrs/okrs.repository";
import type { Role } from "../../src/types/auth";

interface MemoryState {
  companies: Map<string, OkrCompanyRecord & { status: CompanyStatus }>;
  users: Map<string, AuthUserRecord>;
  sessions: Map<string, AuthDeviceSessionRecord>;
  employees: Map<string, OkrEmployeeProfileRecord>;
  okrs: Map<string, OkrRecord>;
  progressUpdates: Map<string, OkrProgressUpdateRecord>;
  approvals: Map<string, OkrApprovalRecord>;
  audits: AuditLogInput[];
  counters: Record<string, number>;
}

const now = () => new Date("2026-06-03T08:00:00.000Z");
const dueDate = () => new Date("2026-09-30T00:00:00.000Z");

const compact = <T extends object>(input: T) =>
  Object.fromEntries(Object.entries(input as Record<string, unknown>).filter(([, value]) => value !== undefined)) as Partial<T>;

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

const makeEmployee = (
  id: string,
  companyId: string,
  userId: string,
  managerId: string | null = null,
  status: EmployeeStatus = "ACTIVE" as EmployeeStatus
): OkrEmployeeProfileRecord => ({
  id,
  companyId,
  userId,
  managerId,
  status,
  companyStatus: "ACTIVE" as CompanyStatus
});

const makeOkr = (
  id: string,
  companyId: string,
  employeeId: string,
  assignedById: string,
  title: string,
  status: OKRStatus = "ASSIGNED" as OKRStatus
): OkrRecord => ({
  id,
  companyId,
  employeeId,
  assignedById,
  title,
  description: "Reduce average response time from 3 days to 1 day.",
  status,
  dueDate: dueDate(),
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
    makeUser("user-other-employee", "otheremployee@example.test", "company-1", ["EMPLOYEE"], passwordHash),
    makeUser("user-company2-employee", "company2employee@example.test", "company-2", ["EMPLOYEE"], passwordHash)
  ];
  const employees = [
    makeEmployee("employee-company-admin", "company-1", "user-company-admin"),
    makeEmployee("employee-hr-admin", "company-1", "user-hr-admin"),
    makeEmployee("employee-manager", "company-1", "user-manager"),
    makeEmployee("employee-self", "company-1", "user-employee", "employee-manager"),
    makeEmployee("employee-other", "company-1", "user-other-employee"),
    makeEmployee("employee-company2", "company-2", "user-company2-employee")
  ];
  const okrs = [
    makeOkr("okr-self", "company-1", "employee-self", "employee-manager", "Improve customer response time"),
    makeOkr("okr-other", "company-1", "employee-other", "employee-company-admin", "Improve onboarding"),
    makeOkr("okr-company2", "company-2", "employee-company2", "employee-company2", "Other company OKR")
  ];

  return {
    companies: new Map([
      ["company-1", { id: "company-1", status: "ACTIVE" as CompanyStatus }],
      ["company-2", { id: "company-2", status: "ACTIVE" as CompanyStatus }]
    ]),
    users: new Map(users.map((user) => [user.id, user])),
    sessions: new Map(),
    employees: new Map(employees.map((employee) => [employee.id, employee])),
    okrs: new Map(okrs.map((okr) => [okr.id, okr])),
    progressUpdates: new Map(),
    approvals: new Map(),
    audits: [],
    counters: {
      session: 0,
      okr: 0,
      progress: 0,
      approval: 0
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

  const withRelations = (okr: OkrRecord): OkrRecord => ({
    ...okr,
    employee: state.employees.get(okr.employeeId),
    assignedBy: state.employees.get(okr.assignedById),
    progressUpdates: Array.from(state.progressUpdates.values()).filter((progressUpdate) => progressUpdate.okrId === okr.id),
    approvals: Array.from(state.approvals.values()).filter((approval) => approval.okrId === okr.id)
  });

  const okrsRepository: OkrsRepository = {
    async findCompanyById(companyId) {
      return state.companies.get(companyId) ?? null;
    },

    async findEmployeeByIdInCompany(employeeId, companyId) {
      const employee = state.employees.get(employeeId);
      return employee?.companyId === companyId ? employee : null;
    },

    async findEmployeeByUserId(userId) {
      return Array.from(state.employees.values()).find((employee) => employee.userId === userId) ?? null;
    },

    async createOkr(input: CreateOkrRepositoryInput) {
      state.counters.okr += 1;
      const okr = makeOkr(`okr-new-${state.counters.okr}`, input.companyId, input.employeeId, input.assignedById, input.title);
      okr.description = input.description ?? null;
      okr.dueDate = input.dueDate ?? null;

      state.okrs.set(okr.id, okr);
      return withRelations(okr);
    },

    async findOkrByIdInCompany(okrId, companyId) {
      const okr = state.okrs.get(okrId);
      return okr?.companyId === companyId ? withRelations(okr) : null;
    },

    async listOkrsForEmployee(employeeId, filters) {
      return Array.from(state.okrs.values())
        .filter((okr) => okr.employeeId === employeeId && (!filters.status || okr.status === filters.status))
        .map(withRelations);
    },

    async listOkrsForDirectReports(managerId, companyId) {
      return Array.from(state.okrs.values())
        .filter((okr) => okr.companyId === companyId && state.employees.get(okr.employeeId)?.managerId === managerId)
        .map(withRelations);
    },

    async listOkrsForCompany(companyId, filters: OkrListFilters) {
      return Array.from(state.okrs.values())
        .filter(
          (okr) =>
            okr.companyId === companyId &&
            (!filters.employeeId || okr.employeeId === filters.employeeId) &&
            (!filters.status || okr.status === filters.status) &&
            (!filters.from || okr.createdAt >= filters.from) &&
            (!filters.to || okr.createdAt <= filters.to)
        )
        .map(withRelations);
    },

    async updateOkr(okrId, companyId, input: UpdateOkrRepositoryInput) {
      const current = await this.findOkrByIdInCompany(okrId, companyId);
      const okr = { ...current!, ...compact(input), employee: undefined, assignedBy: undefined, progressUpdates: undefined, approvals: undefined, updatedAt: now() };

      state.okrs.set(okrId, okr);
      return withRelations(okr);
    },

    async updateOkrStatus(okrId, companyId, status) {
      const current = await this.findOkrByIdInCompany(okrId, companyId);
      const okr = {
        ...current!,
        status,
        employee: undefined,
        assignedBy: undefined,
        progressUpdates: undefined,
        approvals: undefined,
        updatedAt: now()
      };

      state.okrs.set(okrId, okr);
      return withRelations(okr);
    },

    async createProgressUpdate(input: CreateOkrProgressRepositoryInput) {
      state.counters.progress += 1;
      const progressUpdate: OkrProgressUpdateRecord = {
        id: `okr-progress-${state.counters.progress}`,
        companyId: input.companyId,
        okrId: input.okrId,
        employeeId: input.employeeId,
        progressPercent: input.progressPercent,
        note: input.note ?? null,
        createdAt: now()
      };

      state.progressUpdates.set(progressUpdate.id, progressUpdate);
      return progressUpdate;
    },

    async upsertApproval(input: UpsertOkrApprovalRepositoryInput) {
      const current = Array.from(state.approvals.values()).find(
        (approval) => approval.okrId === input.okrId && approval.approverEmployeeId === input.approverEmployeeId
      );
      const approval: OkrApprovalRecord = {
        id: current?.id ?? `okr-approval-${++state.counters.approval}`,
        companyId: input.companyId,
        okrId: input.okrId,
        approverEmployeeId: input.approverEmployeeId,
        status: input.status,
        comment: input.comment ?? null,
        createdAt: current?.createdAt ?? now(),
        updatedAt: now()
      };

      state.approvals.set(approval.id, approval);
      return approval;
    },

    async listApprovalsForOkr(okrId, companyId) {
      return Array.from(state.approvals.values()).filter((approval) => approval.okrId === okrId && approval.companyId === companyId);
    }
  };

  const auditRepository: AuditRepository = {
    async create(input) {
      state.audits.push(input);
    }
  };

  return { authRepository, okrsRepository, auditRepository };
};

describe("CP11 OKR management", () => {
  let passwordHash: string;
  let state: MemoryState;

  beforeAll(async () => {
    passwordHash = await hashPassword("Password123!");
  });

  beforeEach(() => {
    state = createState(passwordHash);
    const repositories = createRepositories(state);

    setAuthRepositoryForTests(repositories.authRepository);
    setOkrsRepositoryForTests(repositories.okrsRepository);
    setAuditRepositoryForTests(repositories.auditRepository);
  });

  afterEach(() => {
    resetAuthRepositoryForTests();
    resetOkrsRepositoryForTests();
    resetAuditRepositoryForTests();
  });

  const login = async (email: string) => {
    const response = await request(app).post("/api/auth/login").send({ email, password: "Password123!" }).expect(200);

    return response.body.data.accessToken as string;
  };

  const auditActions = (category?: AuditActionCategory) =>
    state.audits.filter((audit) => !category || audit.category === category).map((audit) => audit.action);

  describe("assignment", () => {
    it("allows COMPANY_ADMIN, HR_ADMIN, and managers to assign text-only OKRs within scope", async () => {
      const companyAdminToken = await login("companyadmin@example.test");
      const hrAdminToken = await login("hradmin@example.test");
      const managerToken = await login("manager@example.test");

      const companyAdminResponse = await request(app)
        .post("/api/okrs")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ employeeId: "employee-self", title: "Improve customer response time", description: "Text OKR", dueDate: "2026-09-30" })
        .expect(201);
      const hrResponse = await request(app)
        .post("/api/okrs")
        .set("Authorization", `Bearer ${hrAdminToken}`)
        .send({ employeeId: "employee-other", title: "Improve onboarding" })
        .expect(201);
      const managerResponse = await request(app)
        .post("/api/okrs")
        .set("Authorization", `Bearer ${managerToken}`)
        .send({ employeeId: "employee-self", title: "Improve QA handoff" })
        .expect(201);

      expect(companyAdminResponse.body.data.okr).toMatchObject({ employeeId: "employee-self", status: "ASSIGNED" });
      expect(hrResponse.body.data.okr.assignedById).toBe("employee-hr-admin");
      expect(managerResponse.body.data.okr.assignedById).toBe("employee-manager");
      expect(auditActions("OKR")).toEqual(["OKR_CREATED", "OKR_CREATED", "OKR_CREATED"]);
      expect(JSON.stringify(state.audits)).not.toContain("Improve customer response time");
      expect(JSON.stringify(state.audits)).not.toContain("Text OKR");
    });

    it("rejects invalid assignment attempts and file evidence fields", async () => {
      const managerToken = await login("manager@example.test");
      const employeeToken = await login("employee@example.test");
      const companyAdminToken = await login("companyadmin@example.test");

      await request(app)
        .post("/api/okrs")
        .set("Authorization", `Bearer ${managerToken}`)
        .send({ employeeId: "employee-other", title: "Wrong report" })
        .expect(403);
      await request(app)
        .post("/api/okrs")
        .set("Authorization", `Bearer ${employeeToken}`)
        .send({ employeeId: "employee-self", title: "Self assign" })
        .expect(403);
      await request(app)
        .post("/api/okrs")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ employeeId: "employee-company2", title: "Cross company" })
        .expect(404);
      await request(app)
        .post("/api/okrs")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ employeeId: "employee-self", title: "" })
        .expect(400);
      await request(app)
        .post("/api/okrs")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ employeeId: "employee-self", title: "Evidence rejected", evidenceFileUrl: "https://example.test/file.pdf" })
        .expect(400);
    });
  });

  describe("views and metadata updates", () => {
    it("enforces self, team, admin, and super-admin OKR views", async () => {
      const employeeToken = await login("employee@example.test");
      const managerToken = await login("manager@example.test");
      const companyAdminToken = await login("companyadmin@example.test");
      const superAdminToken = await login("superadmin@example.test");

      const selfResponse = await request(app).get("/api/okrs/me").set("Authorization", `Bearer ${employeeToken}`).expect(200);
      const teamResponse = await request(app).get("/api/okrs/team").set("Authorization", `Bearer ${managerToken}`).expect(200);
      const adminResponse = await request(app).get("/api/admin/okrs").set("Authorization", `Bearer ${companyAdminToken}`).expect(200);
      const superResponse = await request(app).get("/api/admin/okrs?companyId=company-2").set("Authorization", `Bearer ${superAdminToken}`).expect(200);

      expect(selfResponse.body.data.okrs.map((okr: { employeeId: string }) => okr.employeeId)).toEqual(["employee-self"]);
      await request(app).get("/api/okrs/okr-other").set("Authorization", `Bearer ${employeeToken}`).expect(403);
      expect(teamResponse.body.data.okrs.map((okr: { employeeId: string }) => okr.employeeId)).toEqual(["employee-self"]);
      expect(JSON.stringify(teamResponse.body)).not.toContain("employee-other");
      expect(adminResponse.body.data.okrs).toHaveLength(2);
      expect(superResponse.body.data.okrs).toHaveLength(1);
      await request(app).get("/api/okrs/okr-company2").set("Authorization", `Bearer ${companyAdminToken}`).expect(404);
    });

    it("allows direct managers and admins to update OKR metadata and status", async () => {
      const managerToken = await login("manager@example.test");
      const companyAdminToken = await login("companyadmin@example.test");
      const employeeToken = await login("employee@example.test");

      const updateResponse = await request(app)
        .patch("/api/okrs/okr-self")
        .set("Authorization", `Bearer ${managerToken}`)
        .send({ title: "Updated OKR", dueDate: "2026-10-01" })
        .expect(200);
      const statusResponse = await request(app)
        .patch("/api/okrs/okr-self/status")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ status: "IN_PROGRESS" })
        .expect(200);

      await request(app)
        .patch("/api/okrs/okr-self")
        .set("Authorization", `Bearer ${employeeToken}`)
        .send({ title: "Employee cannot update metadata" })
        .expect(403);
      await request(app)
        .patch("/api/okrs/okr-other")
        .set("Authorization", `Bearer ${managerToken}`)
        .send({ title: "Non report" })
        .expect(403);

      expect(updateResponse.body.data.okr.title).toBe("Updated OKR");
      expect(statusResponse.body.data.okr.status).toBe("IN_PROGRESS");
      expect(auditActions("OKR")).toEqual(["OKR_UPDATED", "OKR_STATUS_CHANGED"]);
    });
  });

  describe("progress", () => {
    it("allows employees to add progress to their own OKR and moves ASSIGNED to IN_PROGRESS", async () => {
      const token = await login("employee@example.test");

      const response = await request(app)
        .post("/api/okrs/okr-self/progress")
        .set("Authorization", `Bearer ${token}`)
        .send({ progressPercent: 50, note: "Completed first phase." })
        .expect(201);

      expect(response.body.data.progressUpdate).toMatchObject({ okrId: "okr-self", employeeId: "employee-self", progressPercent: 50 });
      expect(response.body.data.okr.status).toBe("IN_PROGRESS");
      expect(state.progressUpdates.size).toBe(1);
      expect(auditActions("OKR")).toEqual(["OKR_PROGRESS_UPDATED"]);
      expect(JSON.stringify(state.audits)).not.toContain("Completed first phase");
    });

    it("rejects invalid progress and progress outside the employee's own OKR", async () => {
      const token = await login("employee@example.test");

      await request(app)
        .post("/api/okrs/okr-self/progress")
        .set("Authorization", `Bearer ${token}`)
        .send({ progressPercent: 101 })
        .expect(400);
      await request(app)
        .post("/api/okrs/okr-other/progress")
        .set("Authorization", `Bearer ${token}`)
        .send({ progressPercent: 20 })
        .expect(403);
      await request(app)
        .post("/api/okrs/okr-company2/progress")
        .set("Authorization", `Bearer ${token}`)
        .send({ progressPercent: 20 })
        .expect(404);
    });
  });

  describe("approvals", () => {
    it("allows employee and manager approvals and marks OKR approved after both approvals exist", async () => {
      const employeeToken = await login("employee@example.test");
      const managerToken = await login("manager@example.test");

      const employeeResponse = await request(app)
        .patch("/api/okrs/okr-self/employee-approve")
        .set("Authorization", `Bearer ${employeeToken}`)
        .send({ comment: "I confirm completion." })
        .expect(200);
      const managerResponse = await request(app)
        .patch("/api/okrs/okr-self/manager-approve")
        .set("Authorization", `Bearer ${managerToken}`)
        .send({ comment: "Approved." })
        .expect(200);

      expect(employeeResponse.body.data.approval).toMatchObject({ approverEmployeeId: "employee-self", status: "APPROVED" });
      expect(employeeResponse.body.data.okr.status).toBe("SUBMITTED");
      expect(managerResponse.body.data.approval).toMatchObject({ approverEmployeeId: "employee-manager", status: "APPROVED" });
      expect(managerResponse.body.data.okr.status).toBe("APPROVED");
      expect(state.approvals.size).toBe(2);
      expect(auditActions("OKR")).toEqual(["OKR_EMPLOYEE_APPROVAL_SUBMITTED", "OKR_MANAGER_APPROVAL_SUBMITTED"]);
      expect(JSON.stringify(state.audits)).not.toContain("I confirm completion");
      expect(JSON.stringify(state.audits)).not.toContain("Approved.");
    });

    it("enforces manager/admin approval scope", async () => {
      const managerToken = await login("manager@example.test");
      const employeeToken = await login("employee@example.test");
      const hrAdminToken = await login("hradmin@example.test");

      await request(app)
        .patch("/api/okrs/okr-other/manager-approve")
        .set("Authorization", `Bearer ${managerToken}`)
        .send({ comment: "Not my report" })
        .expect(403);
      await request(app)
        .patch("/api/okrs/okr-self/manager-approve")
        .set("Authorization", `Bearer ${employeeToken}`)
        .send({ comment: "Nope" })
        .expect(403);

      const hrResponse = await request(app)
        .patch("/api/okrs/okr-other/manager-approve")
        .set("Authorization", `Bearer ${hrAdminToken}`)
        .send({ comment: "Approved by HR" })
        .expect(200);

      expect(hrResponse.body.data.approval).toMatchObject({ approverEmployeeId: "employee-hr-admin", status: "APPROVED" });
    });

    it("rejects employee approval for another employee's OKR", async () => {
      const token = await login("employee@example.test");

      await request(app)
        .patch("/api/okrs/okr-other/employee-approve")
        .set("Authorization", `Bearer ${token}`)
        .send({ comment: "Not mine" })
        .expect(403);
    });
  });
});
