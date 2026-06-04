import type {
  AuditActionCategory,
  CompanyStatus,
  DeviceSessionStatus,
  EmployeeStatus,
  ShiftStatus,
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
  CreateShiftAssignmentRepositoryInput,
  CreateShiftRepositoryInput,
  ShiftAssignmentOverlapInput,
  ShiftAssignmentRecord,
  ShiftEmployeeProfileRecord,
  ShiftRecord,
  ShiftsRepository,
  UpdateShiftAssignmentRepositoryInput,
  UpdateShiftRepositoryInput
} from "../../src/modules/shifts/shifts.repository";
import { resetShiftsRepositoryForTests, setShiftsRepositoryForTests } from "../../src/modules/shifts/shifts.repository";
import type { Role } from "../../src/types/auth";

interface MemoryState {
  companies: Map<string, { id: string; status: CompanyStatus }>;
  users: Map<string, AuthUserRecord>;
  sessions: Map<string, AuthDeviceSessionRecord>;
  employees: Map<string, ShiftEmployeeProfileRecord>;
  shifts: Map<string, ShiftRecord>;
  assignments: Map<string, ShiftAssignmentRecord>;
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

const makeEmployeeProfile = (
  id: string,
  companyId: string,
  userId: string,
  status: EmployeeStatus = "ACTIVE" as EmployeeStatus
): ShiftEmployeeProfileRecord => ({
  id,
  companyId,
  userId,
  status,
  companyStatus: "ACTIVE" as CompanyStatus
});

const makeShift = (
  id: string,
  companyId: string,
  name: string,
  status: ShiftStatus = "ACTIVE" as ShiftStatus
): ShiftRecord => ({
  id,
  companyId,
  name,
  startTime: "09:00",
  endTime: "17:00",
  status,
  createdAt: now(),
  updatedAt: now()
});

const makeAssignment = (
  id: string,
  companyId: string,
  employeeId: string,
  shiftId: string,
  startsOn = dateOnly("2026-06-01"),
  endsOn: Date | null = null
): ShiftAssignmentRecord => ({
  id,
  companyId,
  employeeId,
  shiftId,
  startsOn,
  endsOn,
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
    makeUser("user-noassignment", "noassignment@example.test", "company-1", ["EMPLOYEE"], passwordHash),
    makeUser("user-noprofile", "noprofile@example.test", "company-1", ["EMPLOYEE"], passwordHash),
    makeUser("user-company2-employee", "company2employee@example.test", "company-2", ["EMPLOYEE"], passwordHash)
  ];
  const employees = [
    makeEmployeeProfile("employee-company-admin", "company-1", "user-company-admin"),
    makeEmployeeProfile("employee-hr-admin", "company-1", "user-hr-admin"),
    makeEmployeeProfile("employee-manager", "company-1", "user-manager"),
    makeEmployeeProfile("employee-self", "company-1", "user-employee"),
    makeEmployeeProfile("employee-noassignment", "company-1", "user-noassignment"),
    makeEmployeeProfile("employee-company2", "company-2", "user-company2-employee")
  ];
  const shifts = [
    makeShift("shift-1", "company-1", "Morning Shift"),
    makeShift("shift-hr", "company-1", "HR Shift"),
    makeShift("shift-inactive", "company-1", "Inactive Shift", "INACTIVE" as ShiftStatus),
    makeShift("shift-2", "company-2", "Other Company Shift")
  ];
  const assignments = [
    makeAssignment("assignment-self", "company-1", "employee-self", "shift-1"),
    makeAssignment("assignment-company2", "company-2", "employee-company2", "shift-2")
  ];

  return {
    companies: new Map([
      ["company-1", { id: "company-1", status: "ACTIVE" as CompanyStatus }],
      ["company-2", { id: "company-2", status: "ACTIVE" as CompanyStatus }]
    ]),
    users: new Map(users.map((user) => [user.id, user])),
    sessions: new Map(),
    employees: new Map(employees.map((employee) => [employee.id, employee])),
    shifts: new Map(shifts.map((shift) => [shift.id, shift])),
    assignments: new Map(assignments.map((assignment) => [assignment.id, assignment])),
    audits: [],
    counters: {
      session: 0,
      shift: 0,
      assignment: 0
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

  const assignmentWithShift = (assignment: ShiftAssignmentRecord): ShiftAssignmentRecord => ({
    ...assignment,
    shift: state.shifts.get(assignment.shiftId)
  });

  const shiftsRepository: ShiftsRepository = {
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

    async createShift(input: CreateShiftRepositoryInput) {
      state.counters.shift += 1;
      const shift: ShiftRecord = {
        id: `shift-new-${state.counters.shift}`,
        companyId: input.companyId,
        name: input.name,
        startTime: input.startTime,
        endTime: input.endTime,
        status: "ACTIVE" as ShiftStatus,
        createdAt: now(),
        updatedAt: now()
      };

      state.shifts.set(shift.id, shift);
      return shift;
    },

    async listShifts(companyId) {
      return Array.from(state.shifts.values()).filter((shift) => shift.companyId === companyId);
    },

    async findShiftByIdInCompany(shiftId, companyId) {
      const shift = state.shifts.get(shiftId);
      return shift?.companyId === companyId ? shift : null;
    },

    async findShiftByNameInCompany(name, companyId) {
      return Array.from(state.shifts.values()).find((shift) => shift.companyId === companyId && shift.name === name) ?? null;
    },

    async updateShift(shiftId, companyId, input: UpdateShiftRepositoryInput) {
      const current = await this.findShiftByIdInCompany(shiftId, companyId);
      const shift = { ...current!, ...compact(input), updatedAt: now() };

      state.shifts.set(shiftId, shift);
      return shift;
    },

    async updateShiftStatus(shiftId, companyId, status) {
      const current = await this.findShiftByIdInCompany(shiftId, companyId);
      const shift = { ...current!, status, updatedAt: now() };

      state.shifts.set(shiftId, shift);
      return shift;
    },

    async createAssignment(input: CreateShiftAssignmentRepositoryInput) {
      state.counters.assignment += 1;
      const assignment: ShiftAssignmentRecord = {
        id: `assignment-new-${state.counters.assignment}`,
        companyId: input.companyId,
        employeeId: input.employeeId,
        shiftId: input.shiftId,
        startsOn: input.startsOn,
        endsOn: input.endsOn ?? null,
        createdAt: now(),
        updatedAt: now()
      };

      state.assignments.set(assignment.id, assignment);
      return assignmentWithShift(assignment);
    },

    async listAssignmentsForShift(shiftId, companyId) {
      return Array.from(state.assignments.values())
        .filter((assignment) => assignment.shiftId === shiftId && assignment.companyId === companyId)
        .map(assignmentWithShift);
    },

    async listAssignmentsForEmployeeCurrentOrFuture(employeeId, companyId, today) {
      return Array.from(state.assignments.values())
        .filter(
          (assignment) =>
            assignment.employeeId === employeeId &&
            assignment.companyId === companyId &&
            (!assignment.endsOn || assignment.endsOn >= today)
        )
        .map(assignmentWithShift);
    },

    async findAssignmentByIdInCompany(assignmentId, companyId) {
      const assignment = state.assignments.get(assignmentId);
      return assignment?.companyId === companyId ? assignmentWithShift(assignment) : null;
    },

    async findOverlappingAssignment(input: ShiftAssignmentOverlapInput) {
      return (
        Array.from(state.assignments.values()).find((assignment) => {
          if (
            assignment.companyId !== input.companyId ||
            assignment.employeeId !== input.employeeId ||
            assignment.shiftId !== input.shiftId ||
            assignment.id === input.excludeAssignmentId
          ) {
            return false;
          }

          const candidateEndsAt = input.endsOn?.getTime();
          const startsBeforeCandidateEnds = !candidateEndsAt || assignment.startsOn.getTime() <= candidateEndsAt;
          const endsAfterCandidateStarts = !assignment.endsOn || assignment.endsOn.getTime() >= input.startsOn.getTime();

          return startsBeforeCandidateEnds && endsAfterCandidateStarts;
        }) ?? null
      );
    },

    async updateAssignment(assignmentId, companyId, input: UpdateShiftAssignmentRepositoryInput) {
      const current = await this.findAssignmentByIdInCompany(assignmentId, companyId);
      const assignment: ShiftAssignmentRecord = {
        ...current!,
        ...(input.startsOn !== undefined ? { startsOn: input.startsOn } : {}),
        ...(input.endsOn !== undefined ? { endsOn: input.endsOn } : {}),
        shift: undefined,
        updatedAt: now()
      };

      state.assignments.set(assignmentId, assignment);
      return assignmentWithShift(assignment);
    },

    async deleteAssignment(assignmentId, companyId) {
      const assignment = state.assignments.get(assignmentId);

      if (assignment?.companyId === companyId) {
        state.assignments.delete(assignmentId);
      }
    }
  };

  const auditRepository: AuditRepository = {
    async create(input) {
      state.audits.push(input);
    }
  };

  return { authRepository, shiftsRepository, auditRepository };
};

describe("CP9 shift management and assignments", () => {
  let passwordHash: string;
  let state: MemoryState;

  beforeAll(async () => {
    passwordHash = await hashPassword("Password123!");
  });

  beforeEach(() => {
    state = createState(passwordHash);
    const repositories = createRepositories(state);

    setAuthRepositoryForTests(repositories.authRepository);
    setShiftsRepositoryForTests(repositories.shiftsRepository);
    setAuditRepositoryForTests(repositories.auditRepository);
  });

  afterEach(() => {
    resetAuthRepositoryForTests();
    resetShiftsRepositoryForTests();
    resetAuditRepositoryForTests();
  });

  const login = async (email: string) => {
    const response = await request(app).post("/api/auth/login").send({ email, password: "Password123!" }).expect(200);

    return response.body.data.accessToken as string;
  };

  const auditActions = (category?: AuditActionCategory) =>
    state.audits.filter((audit) => !category || audit.category === category).map((audit) => audit.action);

  describe("admin shift management", () => {
    it("allows COMPANY_ADMIN, HR_ADMIN, and explicitly scoped SUPER_ADMIN to create shifts", async () => {
      const companyAdminToken = await login("companyadmin@example.test");
      const hrAdminToken = await login("hradmin@example.test");
      const superAdminToken = await login("superadmin@example.test");

      const companyAdminResponse = await request(app)
        .post("/api/admin/shifts")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ name: "Evening Shift", startTime: "13:00", endTime: "21:00" })
        .expect(201);
      const hrAdminResponse = await request(app)
        .post("/api/admin/shifts")
        .set("Authorization", `Bearer ${hrAdminToken}`)
        .send({ name: "Night Shift", startTime: "22:00", endTime: "06:00" })
        .expect(201);

      await request(app)
        .post("/api/admin/shifts")
        .set("Authorization", `Bearer ${superAdminToken}`)
        .send({ name: "Missing Scope", startTime: "09:00", endTime: "17:00" })
        .expect(403);

      const superAdminResponse = await request(app)
        .post("/api/admin/shifts")
        .set("Authorization", `Bearer ${superAdminToken}`)
        .send({ companyId: "company-2", name: "Scoped Shift", startTime: "08:00", endTime: "16:00" })
        .expect(201);

      expect(companyAdminResponse.body.data.shift).toMatchObject({ companyId: "company-1", status: "ACTIVE" });
      expect(hrAdminResponse.body.data.shift).toMatchObject({ companyId: "company-1", name: "Night Shift" });
      expect(superAdminResponse.body.data.shift).toMatchObject({ companyId: "company-2", name: "Scoped Shift" });
      expect(auditActions("SHIFT")).toEqual(["SHIFT_CREATED", "SHIFT_CREATED", "SHIFT_CREATED"]);
    });

    it("rejects MANAGER, EMPLOYEE, invalid time formats, and cross-company scope overrides", async () => {
      const managerToken = await login("manager@example.test");
      const employeeToken = await login("employee@example.test");
      const companyAdminToken = await login("companyadmin@example.test");

      await request(app)
        .post("/api/admin/shifts")
        .set("Authorization", `Bearer ${managerToken}`)
        .send({ name: "Manager Shift", startTime: "09:00", endTime: "17:00" })
        .expect(403);
      await request(app)
        .post("/api/admin/shifts")
        .set("Authorization", `Bearer ${employeeToken}`)
        .send({ name: "Employee Shift", startTime: "09:00", endTime: "17:00" })
        .expect(403);
      await request(app)
        .post("/api/admin/shifts")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ name: "Bad Time", startTime: "9am", endTime: "17:00" })
        .expect(400);
      await request(app)
        .post("/api/admin/shifts")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ companyId: "company-2", name: "Wrong Company", startTime: "09:00", endTime: "17:00" })
        .expect(403);
    });

    it("lists and reads shifts only inside the resolved company scope", async () => {
      const companyAdminToken = await login("companyadmin@example.test");
      const superAdminToken = await login("superadmin@example.test");

      const companyResponse = await request(app).get("/api/admin/shifts").set("Authorization", `Bearer ${companyAdminToken}`).expect(200);
      const superResponse = await request(app)
        .get("/api/admin/shifts?companyId=company-2")
        .set("Authorization", `Bearer ${superAdminToken}`)
        .expect(200);

      expect(companyResponse.body.data.shifts.map((shift: { companyId: string }) => shift.companyId)).toEqual([
        "company-1",
        "company-1",
        "company-1"
      ]);
      expect(superResponse.body.data.shifts).toHaveLength(1);
      await request(app).get("/api/admin/shifts/shift-2").set("Authorization", `Bearer ${companyAdminToken}`).expect(404);
    });

    it("updates shift fields and status within the same company", async () => {
      const token = await login("companyadmin@example.test");

      const updateResponse = await request(app)
        .patch("/api/admin/shifts/shift-1")
        .set("Authorization", `Bearer ${token}`)
        .send({ name: "Morning Shift Updated", startTime: "08:30" })
        .expect(200);
      const statusResponse = await request(app)
        .patch("/api/admin/shifts/shift-1/status")
        .set("Authorization", `Bearer ${token}`)
        .send({ status: "INACTIVE" })
        .expect(200);

      expect(updateResponse.body.data.shift).toMatchObject({ name: "Morning Shift Updated", startTime: "08:30" });
      expect(statusResponse.body.data.shift.status).toBe("INACTIVE");
      expect(state.assignments.has("assignment-self")).toBe(true);
      expect(auditActions("SHIFT")).toEqual(["SHIFT_UPDATED", "SHIFT_STATUS_CHANGED"]);
    });
  });

  describe("shift assignments", () => {
    it("allows COMPANY_ADMIN and HR_ADMIN to assign active shifts to active employees in their company", async () => {
      const companyAdminToken = await login("companyadmin@example.test");
      const hrAdminToken = await login("hradmin@example.test");

      const companyAdminResponse = await request(app)
        .post("/api/admin/shifts/shift-1/assign")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ employeeId: "employee-noassignment", startsOn: "2026-06-10", endsOn: null })
        .expect(201);
      const hrAdminResponse = await request(app)
        .post("/api/admin/shifts/shift-hr/assign")
        .set("Authorization", `Bearer ${hrAdminToken}`)
        .send({ employeeId: "employee-manager", startsOn: "2026-06-01", endsOn: "2026-09-01" })
        .expect(201);

      expect(companyAdminResponse.body.data.assignment).toMatchObject({
        companyId: "company-1",
        employeeId: "employee-noassignment",
        shiftId: "shift-1"
      });
      expect(hrAdminResponse.body.data.assignment.shift).toMatchObject({ name: "HR Shift" });
      expect(auditActions("SHIFT")).toEqual(["SHIFT_ASSIGNED", "SHIFT_ASSIGNED"]);
    });

    it("rejects cross-company employee assignment, cross-company shift assignment, inactive shift, invalid date range, and duplicates", async () => {
      const token = await login("companyadmin@example.test");

      await request(app)
        .post("/api/admin/shifts/shift-1/assign")
        .set("Authorization", `Bearer ${token}`)
        .send({ employeeId: "employee-company2", startsOn: "2026-06-10" })
        .expect(404);
      await request(app)
        .post("/api/admin/shifts/shift-2/assign")
        .set("Authorization", `Bearer ${token}`)
        .send({ employeeId: "employee-self", startsOn: "2026-06-10" })
        .expect(404);
      await request(app)
        .post("/api/admin/shifts/shift-inactive/assign")
        .set("Authorization", `Bearer ${token}`)
        .send({ employeeId: "employee-noassignment", startsOn: "2026-06-10" })
        .expect(400);
      await request(app)
        .post("/api/admin/shifts/shift-1/assign")
        .set("Authorization", `Bearer ${token}`)
        .send({ employeeId: "employee-noassignment", startsOn: "2026-09-01", endsOn: "2026-06-01" })
        .expect(400);
      await request(app)
        .post("/api/admin/shifts/shift-1/assign")
        .set("Authorization", `Bearer ${token}`)
        .send({ employeeId: "employee-self", startsOn: "2026-06-10" })
        .expect(409);
    });

    it("lists, updates, and removes assignments inside the same company with audit logging", async () => {
      const token = await login("companyadmin@example.test");

      const listResponse = await request(app)
        .get("/api/admin/shifts/shift-1/assignments")
        .set("Authorization", `Bearer ${token}`)
        .expect(200);
      const updateResponse = await request(app)
        .patch("/api/admin/shift-assignments/assignment-self")
        .set("Authorization", `Bearer ${token}`)
        .send({ startsOn: "2026-06-02", endsOn: "2026-09-01" })
        .expect(200);
      const deleteResponse = await request(app)
        .delete("/api/admin/shift-assignments/assignment-self")
        .set("Authorization", `Bearer ${token}`)
        .expect(200);

      expect(listResponse.body.data.assignments).toHaveLength(1);
      expect(updateResponse.body.data.assignment).toMatchObject({
        employeeId: "employee-self",
        shiftId: "shift-1"
      });
      expect(deleteResponse.body.data).toEqual({ success: true });
      expect(state.assignments.has("assignment-self")).toBe(false);
      expect(auditActions("SHIFT")).toEqual(["SHIFT_ASSIGNMENT_UPDATED", "SHIFT_ASSIGNMENT_REMOVED"]);
      await request(app).get("/api/admin/shifts/shift-2/assignments").set("Authorization", `Bearer ${token}`).expect(404);
    });
  });

  describe("employee self-view", () => {
    it("allows an employee to view only their own current/future shift assignments", async () => {
      const token = await login("employee@example.test");

      const response = await request(app).get("/api/shifts/me").set("Authorization", `Bearer ${token}`).expect(200);

      expect(response.body.data.assignments).toHaveLength(1);
      expect(response.body.data.assignments[0]).toMatchObject({
        employeeId: "employee-self",
        shiftId: "shift-1",
        shift: {
          name: "Morning Shift"
        }
      });
      expect(JSON.stringify(response.body)).not.toContain("employee-company2");
    });

    it("returns an empty list for an employee with no assignment", async () => {
      const token = await login("noassignment@example.test");

      const response = await request(app).get("/api/shifts/me").set("Authorization", `Bearer ${token}`).expect(200);

      expect(response.body.data.assignments).toEqual([]);
    });

    it("rejects users without an employee profile and missing auth", async () => {
      const token = await login("noprofile@example.test");

      await request(app).get("/api/shifts/me").set("Authorization", `Bearer ${token}`).expect(403);
      await request(app).get("/api/shifts/me").expect(401);
    });
  });
});
