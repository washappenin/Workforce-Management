import type {
  AuditActionCategory,
  CompanyStatus,
  DeviceSessionStatus,
  EmployeeStatus,
  LeaveRequestStatus,
  LeaveTypeStatus,
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
  CreateLeaveRequestRepositoryInput,
  CreateLeaveTypeRepositoryInput,
  LeaveEmployeeProfileRecord,
  LeaveEntitlementFilters,
  LeaveEntitlementRecord,
  LeaveRepository,
  LeaveRequestFilters,
  LeaveRequestRecord,
  LeaveTypeRecord,
  MyLeaveRequestFilters,
  ReviewLeaveRequestRepositoryInput,
  UpdateLeaveEntitlementRepositoryInput,
  UpdateLeaveTypeRepositoryInput,
  UpsertLeaveEntitlementRepositoryInput
} from "../../src/modules/leave/leave.repository";
import { resetLeaveRepositoryForTests, setLeaveRepositoryForTests } from "../../src/modules/leave/leave.repository";
import type { Role } from "../../src/types/auth";

interface MemoryState {
  companies: Map<string, { id: string; status: CompanyStatus }>;
  users: Map<string, AuthUserRecord>;
  sessions: Map<string, AuthDeviceSessionRecord>;
  employees: Map<string, LeaveEmployeeProfileRecord>;
  leaveTypes: Map<string, LeaveTypeRecord>;
  entitlements: Map<string, LeaveEntitlementRecord>;
  leaveRequests: Map<string, LeaveRequestRecord>;
  audits: AuditLogInput[];
  counters: Record<string, number>;
}

const now = () => new Date("2026-06-03T08:00:00.000Z");
const dateOnly = (value: string) => new Date(`${value}T00:00:00.000Z`);

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
): LeaveEmployeeProfileRecord => ({
  id,
  companyId,
  userId,
  managerId,
  status,
  companyStatus: "ACTIVE" as CompanyStatus
});

const makeLeaveType = (
  id: string,
  companyId: string,
  name: string,
  status: LeaveTypeStatus = "ACTIVE" as LeaveTypeStatus,
  defaultAnnualAllowance: number | null = 20
): LeaveTypeRecord => ({
  id,
  companyId,
  name,
  status,
  defaultAnnualAllowance,
  createdAt: now(),
  updatedAt: now()
});

const makeEntitlement = (
  id: string,
  companyId: string,
  employeeId: string,
  leaveTypeId: string,
  totalDays = 20,
  usedDays = 0,
  year = 2026
): LeaveEntitlementRecord => ({
  id,
  companyId,
  employeeId,
  leaveTypeId,
  year,
  totalDays,
  usedDays,
  createdAt: now(),
  updatedAt: now()
});

const makeLeaveRequest = (
  id: string,
  companyId: string,
  employeeId: string,
  leaveTypeId: string,
  startDate: Date,
  endDate: Date,
  status: LeaveRequestStatus = "PENDING" as LeaveRequestStatus
): LeaveRequestRecord => ({
  id,
  companyId,
  employeeId,
  leaveTypeId,
  startDate,
  endDate,
  reason: "Family matter",
  status,
  reviewedById: null,
  reviewedAt: null,
  reviewComment: null,
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
    makeUser("user-nonentitled", "nonentitled@example.test", "company-1", ["EMPLOYEE"], passwordHash),
    makeUser("user-other-employee", "otheremployee@example.test", "company-1", ["EMPLOYEE"], passwordHash),
    makeUser("user-noprofile", "noprofile@example.test", "company-1", ["EMPLOYEE"], passwordHash),
    makeUser("user-company2-employee", "company2employee@example.test", "company-2", ["EMPLOYEE"], passwordHash)
  ];
  const employees = [
    makeEmployee("employee-company-admin", "company-1", "user-company-admin"),
    makeEmployee("employee-hr-admin", "company-1", "user-hr-admin"),
    makeEmployee("employee-manager", "company-1", "user-manager"),
    makeEmployee("employee-self", "company-1", "user-employee", "employee-manager"),
    makeEmployee("employee-nonentitled", "company-1", "user-nonentitled", "employee-manager"),
    makeEmployee("employee-other", "company-1", "user-other-employee"),
    makeEmployee("employee-company2", "company-2", "user-company2-employee")
  ];
  const leaveTypes = [
    makeLeaveType("leave-type-annual", "company-1", "Annual Leave"),
    makeLeaveType("leave-type-sick", "company-1", "Sick Leave", "INACTIVE" as LeaveTypeStatus),
    makeLeaveType("leave-type-company2", "company-2", "Other Company Annual")
  ];
  const entitlements = [
    makeEntitlement("entitlement-self", "company-1", "employee-self", "leave-type-annual", 20, 5),
    makeEntitlement("entitlement-direct", "company-1", "employee-self", "leave-type-sick", 10, 0),
    makeEntitlement("entitlement-manager-report", "company-1", "employee-nonentitled", "leave-type-sick", 8, 0),
    makeEntitlement("entitlement-other", "company-1", "employee-other", "leave-type-annual", 15, 0),
    makeEntitlement("entitlement-company2", "company-2", "employee-company2", "leave-type-company2", 20, 0)
  ];
  const leaveRequests = [
    makeLeaveRequest("request-self-old", "company-1", "employee-self", "leave-type-annual", dateOnly("2026-05-01"), dateOnly("2026-05-02")),
    makeLeaveRequest("request-direct", "company-1", "employee-self", "leave-type-annual", dateOnly("2026-07-01"), dateOnly("2026-07-02")),
    makeLeaveRequest("request-other", "company-1", "employee-other", "leave-type-annual", dateOnly("2026-08-01"), dateOnly("2026-08-02")),
    makeLeaveRequest("request-approved", "company-1", "employee-self", "leave-type-annual", dateOnly("2026-04-01"), dateOnly("2026-04-01"), "APPROVED" as LeaveRequestStatus),
    makeLeaveRequest("request-company2", "company-2", "employee-company2", "leave-type-company2", dateOnly("2026-07-01"), dateOnly("2026-07-02"))
  ];

  return {
    companies: new Map([
      ["company-1", { id: "company-1", status: "ACTIVE" as CompanyStatus }],
      ["company-2", { id: "company-2", status: "ACTIVE" as CompanyStatus }]
    ]),
    users: new Map(users.map((user) => [user.id, user])),
    sessions: new Map(),
    employees: new Map(employees.map((employee) => [employee.id, employee])),
    leaveTypes: new Map(leaveTypes.map((leaveType) => [leaveType.id, leaveType])),
    entitlements: new Map(entitlements.map((entitlement) => [entitlement.id, entitlement])),
    leaveRequests: new Map(leaveRequests.map((leaveRequest) => [leaveRequest.id, leaveRequest])),
    audits: [],
    counters: {
      session: 0,
      leaveType: 0,
      entitlement: 0,
      leaveRequest: 0
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

  const withLeaveType = (entitlement: LeaveEntitlementRecord): LeaveEntitlementRecord => ({
    ...entitlement,
    leaveType: state.leaveTypes.get(entitlement.leaveTypeId)
  });
  const withRelations = (leaveRequest: LeaveRequestRecord): LeaveRequestRecord => ({
    ...leaveRequest,
    leaveType: state.leaveTypes.get(leaveRequest.leaveTypeId),
    employee: state.employees.get(leaveRequest.employeeId)
  });

  const leaveRepository: LeaveRepository = {
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

    async createLeaveType(input: CreateLeaveTypeRepositoryInput) {
      state.counters.leaveType += 1;
      const leaveType = makeLeaveType(
        `leave-type-new-${state.counters.leaveType}`,
        input.companyId,
        input.name,
        "ACTIVE" as LeaveTypeStatus,
        input.defaultAnnualAllowance ?? null
      );

      state.leaveTypes.set(leaveType.id, leaveType);
      return leaveType;
    },

    async listLeaveTypes(companyId) {
      return Array.from(state.leaveTypes.values()).filter((leaveType) => leaveType.companyId === companyId);
    },

    async findLeaveTypeByIdInCompany(leaveTypeId, companyId) {
      const leaveType = state.leaveTypes.get(leaveTypeId);
      return leaveType?.companyId === companyId ? leaveType : null;
    },

    async findLeaveTypeByNameInCompany(name, companyId) {
      return Array.from(state.leaveTypes.values()).find((leaveType) => leaveType.companyId === companyId && leaveType.name === name) ?? null;
    },

    async updateLeaveType(leaveTypeId, companyId, input: UpdateLeaveTypeRepositoryInput) {
      const current = await this.findLeaveTypeByIdInCompany(leaveTypeId, companyId);
      const leaveType = { ...current!, ...compact(input), updatedAt: now() };

      state.leaveTypes.set(leaveTypeId, leaveType);
      return leaveType;
    },

    async updateLeaveTypeStatus(leaveTypeId, companyId, status) {
      const current = await this.findLeaveTypeByIdInCompany(leaveTypeId, companyId);
      const leaveType = { ...current!, status, updatedAt: now() };

      state.leaveTypes.set(leaveTypeId, leaveType);
      return leaveType;
    },

    async upsertEntitlement(input: UpsertLeaveEntitlementRepositoryInput) {
      const current = await this.findEntitlementByEmployeeTypeYear(input.employeeId, input.leaveTypeId, input.year, input.companyId);
      const entitlement: LeaveEntitlementRecord = {
        id: current?.id ?? `entitlement-new-${++state.counters.entitlement}`,
        companyId: input.companyId,
        employeeId: input.employeeId,
        leaveTypeId: input.leaveTypeId,
        year: input.year,
        totalDays: input.totalDays,
        usedDays: input.usedDays,
        createdAt: current?.createdAt ?? now(),
        updatedAt: now()
      };

      state.entitlements.set(entitlement.id, entitlement);

      return {
        entitlement: withLeaveType(entitlement),
        created: !current
      };
    },

    async listEntitlements(companyId, filters: LeaveEntitlementFilters) {
      return Array.from(state.entitlements.values())
        .filter(
          (entitlement) =>
            entitlement.companyId === companyId &&
            (!filters.employeeId || entitlement.employeeId === filters.employeeId) &&
            (!filters.leaveTypeId || entitlement.leaveTypeId === filters.leaveTypeId) &&
            (!filters.year || entitlement.year === filters.year)
        )
        .map(withLeaveType);
    },

    async findEntitlementByIdInCompany(entitlementId, companyId) {
      const entitlement = state.entitlements.get(entitlementId);
      return entitlement?.companyId === companyId ? withLeaveType(entitlement) : null;
    },

    async findEntitlementByEmployeeTypeYear(employeeId, leaveTypeId, year, companyId) {
      const entitlement =
        Array.from(state.entitlements.values()).find(
          (candidate) =>
            candidate.employeeId === employeeId &&
            candidate.leaveTypeId === leaveTypeId &&
            candidate.year === year &&
            candidate.companyId === companyId
        ) ?? null;

      return entitlement ? withLeaveType(entitlement) : null;
    },

    async updateEntitlement(entitlementId, companyId, input: UpdateLeaveEntitlementRepositoryInput) {
      const current = await this.findEntitlementByIdInCompany(entitlementId, companyId);
      const entitlement: LeaveEntitlementRecord = {
        ...current!,
        ...compact(input),
        leaveType: undefined,
        updatedAt: now()
      };

      state.entitlements.set(entitlementId, entitlement);
      return withLeaveType(entitlement);
    },

    async createLeaveRequest(input: CreateLeaveRequestRepositoryInput) {
      state.counters.leaveRequest += 1;
      const leaveRequest = makeLeaveRequest(
        `request-new-${state.counters.leaveRequest}`,
        input.companyId,
        input.employeeId,
        input.leaveTypeId,
        input.startDate,
        input.endDate
      );
      leaveRequest.reason = input.reason ?? null;

      state.leaveRequests.set(leaveRequest.id, leaveRequest);
      return withRelations(leaveRequest);
    },

    async findLeaveRequestByIdInCompany(leaveRequestId, companyId) {
      const leaveRequest = state.leaveRequests.get(leaveRequestId);
      return leaveRequest?.companyId === companyId ? withRelations(leaveRequest) : null;
    },

    async listLeaveRequestsForEmployee(employeeId, filters: MyLeaveRequestFilters) {
      return Array.from(state.leaveRequests.values())
        .filter(
          (leaveRequest) =>
            leaveRequest.employeeId === employeeId &&
            (!filters.status || leaveRequest.status === filters.status) &&
            (!filters.year || leaveRequest.startDate.getUTCFullYear() === filters.year)
        )
        .map(withRelations);
    },

    async listLeaveRequestsForDirectReports(managerId, companyId) {
      return Array.from(state.leaveRequests.values())
        .filter((leaveRequest) => leaveRequest.companyId === companyId && state.employees.get(leaveRequest.employeeId)?.managerId === managerId)
        .map(withRelations);
    },

    async listLeaveRequestsForCompany(companyId, filters: LeaveRequestFilters) {
      return Array.from(state.leaveRequests.values())
        .filter(
          (leaveRequest) =>
            leaveRequest.companyId === companyId &&
            (!filters.employeeId || leaveRequest.employeeId === filters.employeeId) &&
            (!filters.leaveTypeId || leaveRequest.leaveTypeId === filters.leaveTypeId) &&
            (!filters.status || leaveRequest.status === filters.status) &&
            (!filters.from || leaveRequest.startDate >= filters.from) &&
            (!filters.to || leaveRequest.startDate <= filters.to)
        )
        .map(withRelations);
    },

    async findOverlappingLeaveRequest(input) {
      return (
        Array.from(state.leaveRequests.values()).find(
          (leaveRequest) =>
            leaveRequest.companyId === input.companyId &&
            leaveRequest.employeeId === input.employeeId &&
            ["PENDING", "APPROVED"].includes(leaveRequest.status) &&
            leaveRequest.startDate <= input.endDate &&
            leaveRequest.endDate >= input.startDate
        ) ?? null
      );
    },

    async updateLeaveRequestReview(leaveRequestId, companyId, input: ReviewLeaveRequestRepositoryInput) {
      const current = await this.findLeaveRequestByIdInCompany(leaveRequestId, companyId);
      const leaveRequest: LeaveRequestRecord = {
        ...current!,
        status: input.status,
        reviewedById: input.reviewedById ?? null,
        reviewedAt: input.reviewedAt,
        reviewComment: input.reviewComment ?? null,
        leaveType: undefined,
        employee: undefined,
        updatedAt: now()
      };

      state.leaveRequests.set(leaveRequestId, leaveRequest);
      return withRelations(leaveRequest);
    },

    async incrementEntitlementUsedDays(entitlementId, companyId, days) {
      const current = await this.findEntitlementByIdInCompany(entitlementId, companyId);
      const entitlement: LeaveEntitlementRecord = {
        ...current!,
        usedDays: current!.usedDays + days,
        leaveType: undefined,
        updatedAt: now()
      };

      state.entitlements.set(entitlementId, entitlement);
      return withLeaveType(entitlement);
    }
  };

  const auditRepository: AuditRepository = {
    async create(input) {
      state.audits.push(input);
    }
  };

  return { authRepository, leaveRepository, auditRepository };
};

describe("CP10 leave management", () => {
  let passwordHash: string;
  let state: MemoryState;

  beforeAll(async () => {
    passwordHash = await hashPassword("Password123!");
  });

  beforeEach(() => {
    state = createState(passwordHash);
    const repositories = createRepositories(state);

    setAuthRepositoryForTests(repositories.authRepository);
    setLeaveRepositoryForTests(repositories.leaveRepository);
    setAuditRepositoryForTests(repositories.auditRepository);
  });

  afterEach(() => {
    resetAuthRepositoryForTests();
    resetLeaveRepositoryForTests();
    resetAuditRepositoryForTests();
  });

  const login = async (email: string) => {
    const response = await request(app).post("/api/auth/login").send({ email, password: "Password123!" }).expect(200);

    return response.body.data.accessToken as string;
  };

  const auditActions = (category?: AuditActionCategory) =>
    state.audits.filter((audit) => !category || audit.category === category).map((audit) => audit.action);

  describe("leave type management", () => {
    it("allows COMPANY_ADMIN, HR_ADMIN, and explicitly scoped SUPER_ADMIN to create leave types", async () => {
      const companyAdminToken = await login("companyadmin@example.test");
      const hrAdminToken = await login("hradmin@example.test");
      const superAdminToken = await login("superadmin@example.test");

      const companyAdminResponse = await request(app)
        .post("/api/admin/leave-types")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ name: "Compassionate Leave", defaultAnnualAllowance: 5 })
        .expect(201);
      const hrAdminResponse = await request(app)
        .post("/api/admin/leave-types")
        .set("Authorization", `Bearer ${hrAdminToken}`)
        .send({ name: "Study Leave", defaultAnnualAllowance: 10 })
        .expect(201);

      await request(app)
        .post("/api/admin/leave-types")
        .set("Authorization", `Bearer ${superAdminToken}`)
        .send({ name: "Missing Scope", defaultAnnualAllowance: 3 })
        .expect(403);

      const superAdminResponse = await request(app)
        .post("/api/admin/leave-types")
        .set("Authorization", `Bearer ${superAdminToken}`)
        .send({ companyId: "company-2", name: "Company 2 Leave", defaultAnnualAllowance: 12 })
        .expect(201);

      expect(companyAdminResponse.body.data.leaveType).toMatchObject({ companyId: "company-1", status: "ACTIVE" });
      expect(hrAdminResponse.body.data.leaveType.name).toBe("Study Leave");
      expect(superAdminResponse.body.data.leaveType).toMatchObject({ companyId: "company-2", name: "Company 2 Leave" });
      expect(auditActions("LEAVE")).toEqual(["LEAVE_TYPE_CREATED", "LEAVE_TYPE_CREATED", "LEAVE_TYPE_CREATED"]);
    });

    it("rejects manager, employee, duplicate names, invalid allowance, and cross-company access", async () => {
      const managerToken = await login("manager@example.test");
      const employeeToken = await login("employee@example.test");
      const companyAdminToken = await login("companyadmin@example.test");

      await request(app)
        .post("/api/admin/leave-types")
        .set("Authorization", `Bearer ${managerToken}`)
        .send({ name: "Manager Leave", defaultAnnualAllowance: 1 })
        .expect(403);
      await request(app)
        .post("/api/admin/leave-types")
        .set("Authorization", `Bearer ${employeeToken}`)
        .send({ name: "Employee Leave", defaultAnnualAllowance: 1 })
        .expect(403);
      await request(app)
        .post("/api/admin/leave-types")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ name: "Annual Leave", defaultAnnualAllowance: 20 })
        .expect(409);
      await request(app)
        .post("/api/admin/leave-types")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ name: "Bad Allowance", defaultAnnualAllowance: -1 })
        .expect(400);
      await request(app).get("/api/admin/leave-types/leave-type-company2").set("Authorization", `Bearer ${companyAdminToken}`).expect(404);
    });

    it("lists leave types company-scoped and updates status within the same company", async () => {
      const token = await login("companyadmin@example.test");

      const listResponse = await request(app).get("/api/admin/leave-types").set("Authorization", `Bearer ${token}`).expect(200);
      const statusResponse = await request(app)
        .patch("/api/admin/leave-types/leave-type-annual/status")
        .set("Authorization", `Bearer ${token}`)
        .send({ status: "INACTIVE" })
        .expect(200);

      expect(listResponse.body.data.leaveTypes.map((leaveType: { companyId: string }) => leaveType.companyId)).toEqual([
        "company-1",
        "company-1"
      ]);
      expect(statusResponse.body.data.leaveType.status).toBe("INACTIVE");
      expect(state.entitlements.has("entitlement-self")).toBe(true);
      expect(state.leaveRequests.has("request-direct")).toBe(true);
      expect(auditActions("LEAVE")).toEqual(["LEAVE_TYPE_STATUS_CHANGED"]);
    });
  });

  describe("leave entitlement management", () => {
    it("allows COMPANY_ADMIN and HR_ADMIN to create entitlements for active employees and active leave types", async () => {
      const companyAdminToken = await login("companyadmin@example.test");
      const hrAdminToken = await login("hradmin@example.test");

      const companyAdminResponse = await request(app)
        .post("/api/admin/leave-entitlements")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ employeeId: "employee-nonentitled", leaveTypeId: "leave-type-annual", year: 2026, totalDays: 12, usedDays: 0 })
        .expect(201);
      const hrAdminResponse = await request(app)
        .post("/api/admin/leave-entitlements")
        .set("Authorization", `Bearer ${hrAdminToken}`)
        .send({ employeeId: "employee-other", leaveTypeId: "leave-type-annual", year: 2027, totalDays: 18, usedDays: 1 })
        .expect(201);

      expect(companyAdminResponse.body.data.entitlement).toMatchObject({
        employeeId: "employee-nonentitled",
        leaveTypeId: "leave-type-annual",
        remainingDays: 12
      });
      expect(hrAdminResponse.body.data.entitlement.remainingDays).toBe(17);
      expect(auditActions("LEAVE")).toEqual(["LEAVE_ENTITLEMENT_CREATED", "LEAVE_ENTITLEMENT_CREATED"]);
    });

    it("rejects cross-company employee/type, usedDays over totalDays, and inactive leave type entitlements", async () => {
      const token = await login("companyadmin@example.test");

      await request(app)
        .post("/api/admin/leave-entitlements")
        .set("Authorization", `Bearer ${token}`)
        .send({ employeeId: "employee-company2", leaveTypeId: "leave-type-annual", year: 2026, totalDays: 10, usedDays: 0 })
        .expect(404);
      await request(app)
        .post("/api/admin/leave-entitlements")
        .set("Authorization", `Bearer ${token}`)
        .send({ employeeId: "employee-self", leaveTypeId: "leave-type-company2", year: 2026, totalDays: 10, usedDays: 0 })
        .expect(404);
      await request(app)
        .post("/api/admin/leave-entitlements")
        .set("Authorization", `Bearer ${token}`)
        .send({ employeeId: "employee-self", leaveTypeId: "leave-type-annual", year: 2026, totalDays: 5, usedDays: 6 })
        .expect(400);
      await request(app)
        .post("/api/admin/leave-entitlements")
        .set("Authorization", `Bearer ${token}`)
        .send({ employeeId: "employee-self", leaveTypeId: "leave-type-sick", year: 2026, totalDays: 5, usedDays: 0 })
        .expect(400);
    });

    it("updates duplicate entitlements and supports scoped entitlement update", async () => {
      const token = await login("companyadmin@example.test");

      const duplicateResponse = await request(app)
        .post("/api/admin/leave-entitlements")
        .set("Authorization", `Bearer ${token}`)
        .send({ employeeId: "employee-self", leaveTypeId: "leave-type-annual", year: 2026, totalDays: 25, usedDays: 5 })
        .expect(201);
      const updateResponse = await request(app)
        .patch("/api/admin/leave-entitlements/entitlement-self")
        .set("Authorization", `Bearer ${token}`)
        .send({ totalDays: 30, usedDays: 6 })
        .expect(200);

      expect(duplicateResponse.body.data.entitlement).toMatchObject({
        id: "entitlement-self",
        totalDays: 25
      });
      expect(updateResponse.body.data.entitlement.remainingDays).toBe(24);
      expect(auditActions("LEAVE")).toEqual(["LEAVE_ENTITLEMENT_UPDATED", "LEAVE_ENTITLEMENT_UPDATED"]);
    });
  });

  describe("employee leave requests", () => {
    it("allows an employee to submit a self leave request and list only their own leave", async () => {
      const token = await login("employee@example.test");

      const createResponse = await request(app)
        .post("/api/leave/request")
        .set("Authorization", `Bearer ${token}`)
        .send({ leaveTypeId: "leave-type-annual", startDate: "2026-09-10", endDate: "2026-09-12", reason: "Family matter" })
        .expect(201);
      const listResponse = await request(app).get("/api/leave/me?year=2026").set("Authorization", `Bearer ${token}`).expect(200);

      expect(createResponse.body.data.leaveRequest).toMatchObject({
        employeeId: "employee-self",
        status: "PENDING",
        requestedDays: 3
      });
      expect(JSON.stringify(listResponse.body)).not.toContain("employee-other");
      expect(listResponse.body.data.entitlements[0]).toHaveProperty("remainingDays");
      expect(auditActions("LEAVE")).toEqual(["LEAVE_REQUEST_SUBMITTED"]);
      expect(JSON.stringify(state.audits)).not.toContain("Family matter");
    });

    it("rejects no entitlement, attempting another employee payload, inactive type, invalid dates, overlap, and missing auth", async () => {
      const employeeToken = await login("employee@example.test");
      const noEntitlementToken = await login("nonentitled@example.test");

      await request(app)
        .post("/api/leave/request")
        .set("Authorization", `Bearer ${noEntitlementToken}`)
        .send({ leaveTypeId: "leave-type-annual", startDate: "2026-09-10", endDate: "2026-09-11" })
        .expect(400);
      await request(app)
        .post("/api/leave/request")
        .set("Authorization", `Bearer ${employeeToken}`)
        .send({ employeeId: "employee-other", leaveTypeId: "leave-type-annual", startDate: "2026-09-10", endDate: "2026-09-11" })
        .expect(400);
      await request(app)
        .post("/api/leave/request")
        .set("Authorization", `Bearer ${employeeToken}`)
        .send({ leaveTypeId: "leave-type-sick", startDate: "2026-09-10", endDate: "2026-09-11" })
        .expect(400);
      await request(app)
        .post("/api/leave/request")
        .set("Authorization", `Bearer ${employeeToken}`)
        .send({ leaveTypeId: "leave-type-annual", startDate: "2026-09-12", endDate: "2026-09-10" })
        .expect(400);
      await request(app)
        .post("/api/leave/request")
        .set("Authorization", `Bearer ${employeeToken}`)
        .send({ leaveTypeId: "leave-type-annual", startDate: "2026-07-01", endDate: "2026-07-02" })
        .expect(409);
      await request(app)
        .post("/api/leave/request")
        .send({ leaveTypeId: "leave-type-annual", startDate: "2026-09-10", endDate: "2026-09-11" })
        .expect(401);
    });
  });

  describe("manager, HR, and admin review", () => {
    it("allows a manager to view and approve direct-report leave but not non-direct reports", async () => {
      const token = await login("manager@example.test");

      const teamResponse = await request(app).get("/api/leave/team").set("Authorization", `Bearer ${token}`).expect(200);
      const approveResponse = await request(app)
        .patch("/api/leave/request-direct/approve")
        .set("Authorization", `Bearer ${token}`)
        .send({ comment: "Approved" })
        .expect(200);

      expect(teamResponse.body.data.leaveRequests.map((leaveRequest: { employeeId: string }) => leaveRequest.employeeId)).toEqual([
        "employee-self",
        "employee-self",
        "employee-self"
      ]);
      expect(JSON.stringify(teamResponse.body)).not.toContain("employee-other");
      expect(approveResponse.body.data.leaveRequest).toMatchObject({
        status: "APPROVED",
        reviewedById: "employee-manager"
      });
      expect(state.entitlements.get("entitlement-self")?.usedDays).toBe(7);
      await request(app)
        .patch("/api/leave/request-other/approve")
        .set("Authorization", `Bearer ${token}`)
        .send({ comment: "Nope" })
        .expect(403);
    });

    it("allows HR_ADMIN and COMPANY_ADMIN to approve company leave requests and rejects employees", async () => {
      const hrToken = await login("hradmin@example.test");
      const companyAdminToken = await login("companyadmin@example.test");
      const employeeToken = await login("employee@example.test");

      await request(app)
        .patch("/api/leave/request-direct/approve")
        .set("Authorization", `Bearer ${employeeToken}`)
        .send({ comment: "Not allowed" })
        .expect(403);
      const hrResponse = await request(app)
        .patch("/api/leave/request-other/approve")
        .set("Authorization", `Bearer ${hrToken}`)
        .send({ comment: "Approved" })
        .expect(200);

      state.leaveRequests.set(
        "request-admin-review",
        makeLeaveRequest("request-admin-review", "company-1", "employee-self", "leave-type-annual", dateOnly("2026-10-01"), dateOnly("2026-10-01"))
      );
      const adminResponse = await request(app)
        .patch("/api/leave/request-admin-review/approve")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ comment: "Approved" })
        .expect(200);

      expect(hrResponse.body.data.leaveRequest.status).toBe("APPROVED");
      expect(adminResponse.body.data.leaveRequest.status).toBe("APPROVED");
    });

    it("rejects non-pending review and cross-company approval, and rejection does not increment usedDays", async () => {
      const companyAdminToken = await login("companyadmin@example.test");
      const superAdminToken = await login("superadmin@example.test");

      await request(app)
        .patch("/api/leave/request-approved/approve")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ comment: "Again" })
        .expect(400);
      await request(app)
        .patch("/api/leave/request-company2/approve")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ comment: "Wrong company" })
        .expect(404);
      await request(app)
        .patch("/api/leave/request-company2/approve")
        .set("Authorization", `Bearer ${superAdminToken}`)
        .send({ comment: "Missing scope" })
        .expect(403);

      const beforeUsedDays = state.entitlements.get("entitlement-self")!.usedDays;
      const rejectResponse = await request(app)
        .patch("/api/leave/request-direct/reject")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ comment: "Rejected" })
        .expect(200);

      expect(rejectResponse.body.data.leaveRequest.status).toBe("REJECTED");
      expect(state.entitlements.get("entitlement-self")?.usedDays).toBe(beforeUsedDays);
      expect(auditActions("LEAVE")).toEqual(["LEAVE_REQUEST_REJECTED"]);
    });

    it("allows admin leave request list with scoped filters", async () => {
      const token = await login("companyadmin@example.test");

      const response = await request(app)
        .get("/api/admin/leave-requests?employeeId=employee-self&status=PENDING")
        .set("Authorization", `Bearer ${token}`)
        .expect(200);

      expect(response.body.data.leaveRequests.every((leaveRequest: { employeeId: string; status: string }) => leaveRequest.employeeId === "employee-self" && leaveRequest.status === "PENDING")).toBe(true);
      await request(app)
        .get("/api/admin/leave-requests?employeeId=employee-company2")
        .set("Authorization", `Bearer ${token}`)
        .expect(404);
    });
  });
});
