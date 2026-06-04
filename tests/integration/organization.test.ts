import type { AuditActionCategory, CompanyStatus, DeviceSessionStatus, EmployeeStatus, RoleName, UserStatus } from "@prisma/client";
import request from "supertest";

import { app } from "../../src/app";
import type { AuditLogInput, AuditRepository } from "../../src/lib/audit";
import { resetAuditRepositoryForTests, setAuditRepositoryForTests } from "../../src/lib/audit";
import { hashPassword, verifyPassword } from "../../src/lib/password";
import type { AuthDeviceSessionRecord, AuthRepository, AuthUserRecord } from "../../src/modules/auth/auth.repository";
import { resetAuthRepositoryForTests, setAuthRepositoryForTests } from "../../src/modules/auth/auth.repository";
import type { CompaniesRepository, CompanyRecord } from "../../src/modules/companies/companies.repository";
import { resetCompaniesRepositoryForTests, setCompaniesRepositoryForTests } from "../../src/modules/companies/companies.repository";
import type { DepartmentRecord, DepartmentsRepository } from "../../src/modules/departments/departments.repository";
import {
  resetDepartmentsRepositoryForTests,
  setDepartmentsRepositoryForTests
} from "../../src/modules/departments/departments.repository";
import type { DesignationRecord, DesignationsRepository } from "../../src/modules/designations/designations.repository";
import {
  resetDesignationsRepositoryForTests,
  setDesignationsRepositoryForTests
} from "../../src/modules/designations/designations.repository";
import type {
  EmployeeRecord,
  EmployeesRepository,
  UpdateEmployeeRepositoryInput
} from "../../src/modules/employees/employees.repository";
import { resetEmployeesRepositoryForTests, setEmployeesRepositoryForTests } from "../../src/modules/employees/employees.repository";
import type { Role } from "../../src/types/auth";

type StoredUser = AuthUserRecord;
type StoredEmployee = Omit<EmployeeRecord, "user" | "department" | "designation" | "manager">;

interface MemoryState {
  companies: Map<string, CompanyRecord>;
  departments: Map<string, DepartmentRecord>;
  designations: Map<string, DesignationRecord>;
  employees: Map<string, StoredEmployee>;
  users: Map<string, StoredUser>;
  sessions: Map<string, AuthDeviceSessionRecord>;
  audits: AuditLogInput[];
  counters: Record<string, number>;
}

const now = () => new Date("2026-06-03T00:00:00.000Z");

const compact = <T extends object>(input: T) =>
  Object.fromEntries(Object.entries(input as Record<string, unknown>).filter(([, value]) => value !== undefined)) as Partial<T>;

const makeCompany = (id: string, name: string): CompanyRecord => ({
  id,
  name,
  status: "ACTIVE" as CompanyStatus,
  contactEmail: null,
  contactPhone: null,
  billingEmail: null,
  address: null,
  country: null,
  timezone: "Africa/Addis_Ababa",
  createdAt: now(),
  updatedAt: now()
});

const makeDepartment = (id: string, companyId: string, name: string): DepartmentRecord => ({
  id,
  companyId,
  name,
  isActive: true,
  createdAt: now(),
  updatedAt: now()
});

const makeDesignation = (id: string, companyId: string, title: string, departmentId?: string): DesignationRecord => ({
  id,
  companyId,
  departmentId: departmentId ?? null,
  title,
  isActive: true,
  createdAt: now(),
  updatedAt: now()
});

const makeUser = (
  id: string,
  email: string,
  companyId: string | null,
  roles: Role[],
  passwordHash: string
): StoredUser => ({
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
  employeeCode: string,
  firstName: string,
  lastName: string,
  extra: Partial<StoredEmployee> = {}
): StoredEmployee => ({
  id,
  companyId,
  userId,
  departmentId: extra.departmentId ?? null,
  designationId: extra.designationId ?? null,
  managerId: extra.managerId ?? null,
  employeeCode,
  firstName,
  lastName,
  phone: extra.phone ?? null,
  status: extra.status ?? ("ACTIVE" as EmployeeStatus),
  hireDate: extra.hireDate ?? null,
  createdAt: now(),
  updatedAt: now()
});

const buildEmployeeRecord = (state: MemoryState, employee: StoredEmployee): EmployeeRecord => {
  const user = state.users.get(employee.userId);

  if (!user) {
    throw new Error("Missing user for employee");
  }

  const department = employee.departmentId ? state.departments.get(employee.departmentId) ?? null : null;
  const designation = employee.designationId ? state.designations.get(employee.designationId) ?? null : null;
  const manager = employee.managerId ? state.employees.get(employee.managerId) ?? null : null;

  return {
    ...employee,
    user: {
      id: user.id,
      email: user.email,
      companyId: user.companyId,
      status: user.status,
      roles: user.roles
    },
    department: department ? { id: department.id, name: department.name } : null,
    designation: designation ? { id: designation.id, name: designation.title } : null,
    manager: manager
      ? {
          id: manager.id,
          employeeCode: manager.employeeCode,
          firstName: manager.firstName,
          lastName: manager.lastName
        }
      : null
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
        id: `session-${state.counters.session}`,
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

  const companiesRepository: CompaniesRepository = {
    async create(input) {
      state.counters.company += 1;
      const company = {
        id: `company-new-${state.counters.company}`,
        name: input.name,
        status: input.status ?? ("ACTIVE" as CompanyStatus),
        contactEmail: input.contactEmail ?? null,
        contactPhone: input.contactPhone ?? null,
        billingEmail: input.billingEmail ?? null,
        address: input.address ?? null,
        country: input.country ?? null,
        timezone: input.timezone ?? null,
        createdAt: now(),
        updatedAt: now()
      };

      state.companies.set(company.id, company);
      return company;
    },

    async list() {
      return Array.from(state.companies.values());
    },

    async findById(companyId) {
      return state.companies.get(companyId) ?? null;
    },

    async findByName(name) {
      return Array.from(state.companies.values()).find((company) => company.name === name) ?? null;
    },

    async update(companyId, input) {
      const current = state.companies.get(companyId)!;
      const updated = {
        ...current,
        ...compact(input),
        updatedAt: now()
      };

      state.companies.set(companyId, updated);
      return updated;
    },

    async updateStatus(companyId, status) {
      const current = state.companies.get(companyId)!;
      const updated = { ...current, status, updatedAt: now() };

      state.companies.set(companyId, updated);
      return updated;
    }
  };

  const departmentsRepository: DepartmentsRepository = {
    async create(input) {
      state.counters.department += 1;
      const department = {
        id: `department-new-${state.counters.department}`,
        companyId: input.companyId,
        name: input.name,
        isActive: input.isActive ?? true,
        createdAt: now(),
        updatedAt: now()
      };

      state.departments.set(department.id, department);
      return department;
    },

    async list(companyId) {
      return Array.from(state.departments.values()).filter((department) => department.companyId === companyId);
    },

    async findByIdInCompany(departmentId, companyId) {
      const department = state.departments.get(departmentId);
      return department?.companyId === companyId ? department : null;
    },

    async findByNameInCompany(name, companyId) {
      return Array.from(state.departments.values()).find((department) => department.companyId === companyId && department.name === name) ?? null;
    },

    async update(departmentId, companyId, input) {
      const current = await this.findByIdInCompany(departmentId, companyId);
      const updated = { ...current!, ...compact(input), updatedAt: now() };

      state.departments.set(departmentId, updated);
      return updated;
    },

    async updateStatus(departmentId, companyId, isActive) {
      const current = await this.findByIdInCompany(departmentId, companyId);
      const updated = { ...current!, isActive, updatedAt: now() };

      state.departments.set(departmentId, updated);
      return updated;
    }
  };

  const designationsRepository: DesignationsRepository = {
    async create(input) {
      state.counters.designation += 1;
      const designation = {
        id: `designation-new-${state.counters.designation}`,
        companyId: input.companyId,
        departmentId: input.departmentId ?? null,
        title: input.title,
        isActive: input.isActive ?? true,
        createdAt: now(),
        updatedAt: now()
      };

      state.designations.set(designation.id, designation);
      return designation;
    },

    async list(companyId) {
      return Array.from(state.designations.values()).filter((designation) => designation.companyId === companyId);
    },

    async findByIdInCompany(designationId, companyId) {
      const designation = state.designations.get(designationId);
      return designation?.companyId === companyId ? designation : null;
    },

    async findByTitleInCompany(title, companyId) {
      return Array.from(state.designations.values()).find((designation) => designation.companyId === companyId && designation.title === title) ?? null;
    },

    async update(designationId, companyId, input) {
      const current = await this.findByIdInCompany(designationId, companyId);
      const updated = { ...current!, ...compact(input), updatedAt: now() };

      state.designations.set(designationId, updated);
      return updated;
    },

    async updateStatus(designationId, companyId, isActive) {
      const current = await this.findByIdInCompany(designationId, companyId);
      const updated = { ...current!, isActive, updatedAt: now() };

      state.designations.set(designationId, updated);
      return updated;
    }
  };

  const employeesRepository: EmployeesRepository = {
    async findCompanyById(companyId) {
      const company = state.companies.get(companyId);
      return company ? { id: company.id } : null;
    },

    async findUserByEmail(email) {
      const user = Array.from(state.users.values()).find((candidate) => candidate.email === email);
      return user ? { id: user.id, email: user.email, companyId: user.companyId } : null;
    },

    async findDepartmentByIdInCompany(departmentId, companyId) {
      const department = state.departments.get(departmentId);
      return department?.companyId === companyId ? { id: department.id } : null;
    },

    async findDesignationByIdInCompany(designationId, companyId) {
      const designation = state.designations.get(designationId);
      return designation?.companyId === companyId ? { id: designation.id } : null;
    },

    async findEmployeeCodeInCompany(employeeCode, companyId) {
      const employee = Array.from(state.employees.values()).find(
        (candidate) => candidate.companyId === companyId && candidate.employeeCode === employeeCode
      );

      return employee ? buildEmployeeRecord(state, employee) : null;
    },

    async findByIdInCompany(employeeId, companyId) {
      const employee = state.employees.get(employeeId);
      return employee?.companyId === companyId ? buildEmployeeRecord(state, employee) : null;
    },

    async findByUserId(userId) {
      const employee = Array.from(state.employees.values()).find((candidate) => candidate.userId === userId);
      return employee ? buildEmployeeRecord(state, employee) : null;
    },

    async list(companyId) {
      return Array.from(state.employees.values())
        .filter((employee) => employee.companyId === companyId)
        .map((employee) => buildEmployeeRecord(state, employee));
    },

    async create(input) {
      state.counters.user += 1;
      state.counters.employee += 1;

      const user = makeUser(`user-new-${state.counters.user}`, input.email, input.companyId, input.roles as Role[], input.passwordHash);
      const employee = makeEmployee(
        `employee-new-${state.counters.employee}`,
        input.companyId,
        user.id,
        input.employeeCode,
        input.firstName,
        input.lastName,
        {
          phone: input.phone ?? null,
          departmentId: input.departmentId ?? null,
          designationId: input.designationId ?? null,
          managerId: input.managerId ?? null,
          hireDate: input.hireDate ?? null
        }
      );

      state.users.set(user.id, user);
      state.employees.set(employee.id, employee);
      return buildEmployeeRecord(state, employee);
    },

    async update(employeeId, companyId, input: UpdateEmployeeRepositoryInput) {
      const current = state.employees.get(employeeId)!;
      const updated = { ...current, ...compact(input), updatedAt: now() };

      if (current.companyId !== companyId) {
        throw new Error("Employee update failed");
      }

      state.employees.set(employeeId, updated);
      return buildEmployeeRecord(state, updated);
    },

    async updateStatus(employeeId, companyId, status, userStatus) {
      const current = state.employees.get(employeeId)!;

      if (current.companyId !== companyId) {
        throw new Error("Employee status update failed");
      }

      const updatedEmployee = { ...current, status, updatedAt: now() };
      const currentUser = state.users.get(current.userId)!;

      state.employees.set(employeeId, updatedEmployee);
      state.users.set(currentUser.id, { ...currentUser, status: userStatus });
      return buildEmployeeRecord(state, updatedEmployee);
    },

    async updateManager(employeeId, companyId, managerId) {
      const current = state.employees.get(employeeId)!;

      if (current.companyId !== companyId) {
        throw new Error("Manager update failed");
      }

      const updated = { ...current, managerId, updatedAt: now() };

      state.employees.set(employeeId, updated);
      return buildEmployeeRecord(state, updated);
    }
  };

  const auditRepository: AuditRepository = {
    async create(input) {
      state.audits.push(input);
    }
  };

  return {
    authRepository,
    auditRepository,
    companiesRepository,
    departmentsRepository,
    designationsRepository,
    employeesRepository
  };
};

const createState = (passwordHash: string): MemoryState => {
  const state: MemoryState = {
    companies: new Map([
      ["company-1", makeCompany("company-1", "Demo Workforce Company")],
      ["company-2", makeCompany("company-2", "Second Workforce Company")]
    ]),
    departments: new Map([
      ["department-1", makeDepartment("department-1", "company-1", "Operations")],
      ["department-2", makeDepartment("department-2", "company-2", "Finance")]
    ]),
    designations: new Map([
      ["designation-1", makeDesignation("designation-1", "company-1", "Coordinator", "department-1")],
      ["designation-2", makeDesignation("designation-2", "company-2", "Analyst", "department-2")]
    ]),
    employees: new Map(),
    users: new Map(),
    sessions: new Map(),
    audits: [],
    counters: {
      company: 0,
      department: 0,
      designation: 0,
      employee: 0,
      user: 0,
      session: 0
    }
  };

  const users = [
    makeUser("user-super-admin", "superadmin@example.test", null, ["SUPER_ADMIN"], passwordHash),
    makeUser("user-company-admin", "companyadmin@example.test", "company-1", ["COMPANY_ADMIN"], passwordHash),
    makeUser("user-hr-admin", "hradmin@example.test", "company-1", ["HR_ADMIN"], passwordHash),
    makeUser("user-manager", "manager@example.test", "company-1", ["MANAGER"], passwordHash),
    makeUser("user-employee", "employee@example.test", "company-1", ["EMPLOYEE"], passwordHash),
    makeUser("user-company2-admin", "company2admin@example.test", "company-2", ["COMPANY_ADMIN"], passwordHash),
    makeUser("user-company2-employee", "company2employee@example.test", "company-2", ["EMPLOYEE"], passwordHash)
  ];

  for (const user of users) {
    state.users.set(user.id, user);
  }

  const employees = [
    makeEmployee("employee-manager", "company-1", "user-manager", "MGR001", "Morgan", "Manager", {
      departmentId: "department-1",
      designationId: "designation-1"
    }),
    makeEmployee("employee-self", "company-1", "user-employee", "EMP001", "Eli", "Employee", {
      departmentId: "department-1",
      designationId: "designation-1"
    }),
    makeEmployee("employee-company2", "company-2", "user-company2-employee", "EMP201", "Casey", "Second", {
      departmentId: "department-2",
      designationId: "designation-2"
    })
  ];

  for (const employee of employees) {
    state.employees.set(employee.id, employee);
  }

  return state;
};

describe("CP5 company, department, designation, and employee management", () => {
  let passwordHash: string;
  let state: MemoryState;

  beforeAll(async () => {
    passwordHash = await hashPassword("Password123!");
  });

  beforeEach(() => {
    state = createState(passwordHash);
    const repositories = createRepositories(state);

    setAuthRepositoryForTests(repositories.authRepository);
    setAuditRepositoryForTests(repositories.auditRepository);
    setCompaniesRepositoryForTests(repositories.companiesRepository);
    setDepartmentsRepositoryForTests(repositories.departmentsRepository);
    setDesignationsRepositoryForTests(repositories.designationsRepository);
    setEmployeesRepositoryForTests(repositories.employeesRepository);
  });

  afterEach(() => {
    resetAuthRepositoryForTests();
    resetAuditRepositoryForTests();
    resetCompaniesRepositoryForTests();
    resetDepartmentsRepositoryForTests();
    resetDesignationsRepositoryForTests();
    resetEmployeesRepositoryForTests();
  });

  const login = async (email: string) => {
    const response = await request(app).post("/api/auth/login").send({ email, password: "Password123!" }).expect(200);

    return response.body.data.accessToken as string;
  };

  const actions = (category?: AuditActionCategory) =>
    state.audits.filter((audit) => !category || audit.category === category).map((audit) => audit.action);

  describe("companies", () => {
    it("allows SUPER_ADMIN to create and list companies with audit logging", async () => {
      const token = await login("superadmin@example.test");
      const createResponse = await request(app)
        .post("/api/super-admin/companies")
        .set("Authorization", `Bearer ${token}`)
        .send({ name: "New Company", contactEmail: "owner@example.test" })
        .expect(201);

      expect(createResponse.body.data.company).toMatchObject({
        id: expect.any(String),
        name: "New Company",
        status: "ACTIVE",
        contactEmail: "owner@example.test"
      });

      const listResponse = await request(app)
        .get("/api/super-admin/companies")
        .set("Authorization", `Bearer ${token}`)
        .expect(200);

      expect(listResponse.body.data.companies).toHaveLength(3);
      expect(actions("COMPANY")).toContain("COMPANY_CREATED");
    });

    it("rejects non-super-admin users from company management routes", async () => {
      const companyAdminToken = await login("companyadmin@example.test");
      const employeeToken = await login("employee@example.test");

      await request(app)
        .post("/api/super-admin/companies")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ name: "Blocked Company" })
        .expect(403);
      await request(app).get("/api/super-admin/companies").set("Authorization", `Bearer ${employeeToken}`).expect(403);
    });

    it("validates company status updates", async () => {
      const token = await login("superadmin@example.test");

      await request(app)
        .patch("/api/super-admin/companies/company-1/status")
        .set("Authorization", `Bearer ${token}`)
        .send({ status: "NOT_A_STATUS" })
        .expect(400);

      const response = await request(app)
        .patch("/api/super-admin/companies/company-1/status")
        .set("Authorization", `Bearer ${token}`)
        .send({ status: "SUSPENDED" })
        .expect(200);

      expect(response.body.data.company.status).toBe("SUSPENDED");
      expect(actions("COMPANY")).toContain("COMPANY_STATUS_CHANGED");
    });
  });

  describe("departments", () => {
    it("allows COMPANY_ADMIN and HR_ADMIN to create departments in their own company", async () => {
      const companyAdminToken = await login("companyadmin@example.test");
      const hrAdminToken = await login("hradmin@example.test");

      const companyAdminResponse = await request(app)
        .post("/api/admin/departments")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ name: "People Ops" })
        .expect(201);
      const hrAdminResponse = await request(app)
        .post("/api/admin/departments")
        .set("Authorization", `Bearer ${hrAdminToken}`)
        .send({ name: "HR Services" })
        .expect(201);

      expect(companyAdminResponse.body.data.department.companyId).toBe("company-1");
      expect(hrAdminResponse.body.data.department.companyId).toBe("company-1");
      expect(actions("COMPANY")).toEqual(expect.arrayContaining(["DEPARTMENT_CREATED", "DEPARTMENT_CREATED"]));
    });

    it("rejects employees and cross-company department reads", async () => {
      const employeeToken = await login("employee@example.test");
      const companyAdminToken = await login("companyadmin@example.test");

      await request(app)
        .post("/api/admin/departments")
        .set("Authorization", `Bearer ${employeeToken}`)
        .send({ name: "Blocked" })
        .expect(403);

      await request(app).get("/api/admin/departments/department-2").set("Authorization", `Bearer ${companyAdminToken}`).expect(404);
    });

    it("rejects duplicate department names inside the same company", async () => {
      const token = await login("companyadmin@example.test");

      await request(app)
        .post("/api/admin/departments")
        .set("Authorization", `Bearer ${token}`)
        .send({ name: "Operations" })
        .expect(409);
    });
  });

  describe("designations", () => {
    it("allows COMPANY_ADMIN and HR_ADMIN to create designations", async () => {
      const companyAdminToken = await login("companyadmin@example.test");
      const hrAdminToken = await login("hradmin@example.test");

      const companyAdminResponse = await request(app)
        .post("/api/admin/designations")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ title: "Team Lead", departmentId: "department-1" })
        .expect(201);
      const hrAdminResponse = await request(app)
        .post("/api/admin/designations")
        .set("Authorization", `Bearer ${hrAdminToken}`)
        .send({ title: "People Partner", departmentId: "department-1" })
        .expect(201);

      expect(companyAdminResponse.body.data.designation.companyId).toBe("company-1");
      expect(hrAdminResponse.body.data.designation.companyId).toBe("company-1");
      expect(actions("COMPANY")).toContain("DESIGNATION_CREATED");
    });

    it("rejects cross-company department references and cross-company designation reads", async () => {
      const token = await login("companyadmin@example.test");

      await request(app)
        .post("/api/admin/designations")
        .set("Authorization", `Bearer ${token}`)
        .send({ title: "Wrong Department", departmentId: "department-2" })
        .expect(403);

      await request(app).get("/api/admin/designations/designation-2").set("Authorization", `Bearer ${token}`).expect(404);
    });
  });

  describe("employees", () => {
    const employeePayload = {
      email: "newemployee@example.test",
      temporaryPassword: "Password123!",
      firstName: "New",
      lastName: "Employee",
      employeeCode: "EMP002",
      phone: "+251911111111",
      role: "EMPLOYEE",
      departmentId: "department-1",
      designationId: "designation-1",
      managerId: "employee-manager"
    };

    it("allows COMPANY_ADMIN to create employees with hashed passwords, roles, and no passwordHash response", async () => {
      const token = await login("companyadmin@example.test");
      const response = await request(app)
        .post("/api/admin/employees")
        .set("Authorization", `Bearer ${token}`)
        .send(employeePayload)
        .expect(201);

      const employee = response.body.data.employee;
      const createdUser = Array.from(state.users.values()).find((user) => user.email === "newemployee@example.test");

      expect(employee).toMatchObject({
        companyId: "company-1",
        email: "newemployee@example.test",
        roles: ["EMPLOYEE"],
        employeeCode: "EMP002",
        managerId: "employee-manager"
      });
      expect(JSON.stringify(response.body)).not.toContain("passwordHash");
      expect(createdUser).toBeDefined();
      expect(createdUser?.passwordHash).not.toBe("Password123!");
      await expect(verifyPassword("Password123!", createdUser!.passwordHash)).resolves.toBe(true);
      expect(actions("EMPLOYEE")).toContain("EMPLOYEE_CREATED");
    });

    it("allows HR_ADMIN to create employees in their own company", async () => {
      const token = await login("hradmin@example.test");

      const response = await request(app)
        .post("/api/admin/employees")
        .set("Authorization", `Bearer ${token}`)
        .send({ ...employeePayload, email: "hrcreated@example.test", employeeCode: "EMP003", role: "MANAGER" })
        .expect(201);

      expect(response.body.data.employee).toMatchObject({
        companyId: "company-1",
        roles: ["MANAGER"]
      });
    });

    it("rejects duplicate employeeCode and cross-company related records", async () => {
      const token = await login("companyadmin@example.test");

      await request(app)
        .post("/api/admin/employees")
        .set("Authorization", `Bearer ${token}`)
        .send({ ...employeePayload, email: "duplicatecode@example.test", employeeCode: "EMP001" })
        .expect(409);
      await request(app)
        .post("/api/admin/employees")
        .set("Authorization", `Bearer ${token}`)
        .send({ ...employeePayload, email: "baddept@example.test", employeeCode: "EMP004", departmentId: "department-2" })
        .expect(403);
      await request(app)
        .post("/api/admin/employees")
        .set("Authorization", `Bearer ${token}`)
        .send({ ...employeePayload, email: "baddesig@example.test", employeeCode: "EMP005", designationId: "designation-2" })
        .expect(403);
      await request(app)
        .post("/api/admin/employees")
        .set("Authorization", `Bearer ${token}`)
        .send({ ...employeePayload, email: "badmanager@example.test", employeeCode: "EMP006", managerId: "employee-company2" })
        .expect(403);
    });

    it("keeps admin employee management away from employees while allowing self-profile access", async () => {
      const token = await login("employee@example.test");

      await request(app)
        .post("/api/admin/employees")
        .set("Authorization", `Bearer ${token}`)
        .send(employeePayload)
        .expect(403);
      await request(app).get("/api/admin/employees/employee-manager").set("Authorization", `Bearer ${token}`).expect(403);

      const response = await request(app).get("/api/employees/me").set("Authorization", `Bearer ${token}`).expect(200);

      expect(response.body.data.employee).toMatchObject({
        id: "employee-self",
        email: "employee@example.test",
        employeeCode: "EMP001"
      });
      expect(JSON.stringify(response.body)).not.toContain("passwordHash");
    });

    it("assigns managers in the same company and rejects self-assignment", async () => {
      const token = await login("companyadmin@example.test");

      const response = await request(app)
        .patch("/api/admin/employees/employee-self/manager")
        .set("Authorization", `Bearer ${token}`)
        .send({ managerId: "employee-manager" })
        .expect(200);

      expect(response.body.data.employee.managerId).toBe("employee-manager");
      expect(actions("EMPLOYEE")).toContain("EMPLOYEE_MANAGER_CHANGED");

      await request(app)
        .patch("/api/admin/employees/employee-self/manager")
        .set("Authorization", `Bearer ${token}`)
        .send({ managerId: "employee-self" })
        .expect(400);
    });

    it("updates employee status and intentionally maps inactive profiles to disabled users", async () => {
      const token = await login("companyadmin@example.test");

      const response = await request(app)
        .patch("/api/admin/employees/employee-self/status")
        .set("Authorization", `Bearer ${token}`)
        .send({ status: "INACTIVE" })
        .expect(200);

      expect(response.body.data.employee).toMatchObject({
        status: "INACTIVE",
        userStatus: "DISABLED"
      });
      expect(state.users.get("user-employee")?.status).toBe("DISABLED");
      expect(actions("EMPLOYEE")).toContain("EMPLOYEE_STATUS_CHANGED");
    });

    it("requires a valid companyId for SUPER_ADMIN employee creation", async () => {
      const token = await login("superadmin@example.test");

      await request(app)
        .post("/api/admin/employees")
        .set("Authorization", `Bearer ${token}`)
        .send(employeePayload)
        .expect(403);

      const response = await request(app)
        .post("/api/admin/employees")
        .set("Authorization", `Bearer ${token}`)
        .send({ ...employeePayload, companyId: "company-1", email: "supercreated@example.test", employeeCode: "EMP007" })
        .expect(201);

      expect(response.body.data.employee.companyId).toBe("company-1");
    });
  });
});
