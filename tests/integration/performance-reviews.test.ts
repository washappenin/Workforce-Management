import type {
  AuditActionCategory,
  CompanyStatus,
  DeviceSessionStatus,
  EmployeeStatus,
  PerformanceReviewStatus,
  ReviewCycleStatus,
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
  CreatePerformanceReviewRepositoryInput,
  CreateReviewCycleRepositoryInput,
  PerformanceReviewFilters,
  PerformanceReviewRecord,
  PerformanceReviewsRepository,
  ReviewCompanyRecord,
  ReviewCycleRecord,
  ReviewEmployeeProfileRecord,
  UpdatePerformanceReviewRepositoryInput,
  UpdatePerformanceReviewStatusRepositoryInput,
  UpdateReviewCycleRepositoryInput
} from "../../src/modules/performance-reviews/reviews.repository";
import {
  resetPerformanceReviewsRepositoryForTests,
  setPerformanceReviewsRepositoryForTests
} from "../../src/modules/performance-reviews/reviews.repository";
import type { Role } from "../../src/types/auth";

interface MemoryState {
  companies: Map<string, ReviewCompanyRecord & { status: CompanyStatus }>;
  users: Map<string, AuthUserRecord>;
  sessions: Map<string, AuthDeviceSessionRecord>;
  employees: Map<string, ReviewEmployeeProfileRecord>;
  reviewCycles: Map<string, ReviewCycleRecord>;
  reviews: Map<string, PerformanceReviewRecord>;
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
): ReviewEmployeeProfileRecord => ({
  id,
  companyId,
  userId,
  managerId,
  status,
  companyStatus: "ACTIVE" as CompanyStatus
});

const makeCycle = (
  id: string,
  companyId: string,
  name: string,
  status: ReviewCycleStatus = "DRAFT" as ReviewCycleStatus
): ReviewCycleRecord => ({
  id,
  companyId,
  name,
  startDate: dateOnly("2026-07-01"),
  endDate: dateOnly("2026-09-30"),
  status,
  createdAt: now(),
  updatedAt: now()
});

const makeReview = (
  id: string,
  companyId: string,
  reviewCycleId: string,
  employeeId: string,
  managerId: string,
  status: PerformanceReviewStatus = "SUBMITTED" as PerformanceReviewStatus,
  submittedAt: Date | null = now()
): PerformanceReviewRecord => ({
  id,
  companyId,
  reviewCycleId,
  employeeId,
  managerId,
  summary: "Employee met key goals and improved attendance consistency.",
  rating: 4,
  status,
  submittedAt,
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
    makeUser("user-direct2", "direct2@example.test", "company-1", ["EMPLOYEE"], passwordHash),
    makeUser("user-other-employee", "otheremployee@example.test", "company-1", ["EMPLOYEE"], passwordHash),
    makeUser("user-company2-employee", "company2employee@example.test", "company-2", ["EMPLOYEE"], passwordHash)
  ];
  const employees = [
    makeEmployee("employee-company-admin", "company-1", "user-company-admin"),
    makeEmployee("employee-hr-admin", "company-1", "user-hr-admin"),
    makeEmployee("employee-manager", "company-1", "user-manager"),
    makeEmployee("employee-self", "company-1", "user-employee", "employee-manager"),
    makeEmployee("employee-direct2", "company-1", "user-direct2", "employee-manager"),
    makeEmployee("employee-other", "company-1", "user-other-employee"),
    makeEmployee("employee-company2", "company-2", "user-company2-employee")
  ];
  const reviewCycles = [
    makeCycle("cycle-active", "company-1", "Q3 2026 Review", "ACTIVE" as ReviewCycleStatus),
    makeCycle("cycle-active-secondary", "company-1", "Q4 2026 Review", "ACTIVE" as ReviewCycleStatus),
    makeCycle("cycle-draft", "company-1", "Draft Review", "DRAFT" as ReviewCycleStatus),
    makeCycle("cycle-company2", "company-2", "Other Company Review", "ACTIVE" as ReviewCycleStatus)
  ];
  const reviews = [
    makeReview("review-self", "company-1", "cycle-active", "employee-self", "employee-manager"),
    makeReview("review-draft", "company-1", "cycle-active-secondary", "employee-direct2", "employee-manager", "DRAFT" as PerformanceReviewStatus, null),
    makeReview("review-other", "company-1", "cycle-active", "employee-other", "employee-company-admin"),
    makeReview("review-company2", "company-2", "cycle-company2", "employee-company2", "employee-company2")
  ];

  return {
    companies: new Map([
      ["company-1", { id: "company-1", status: "ACTIVE" as CompanyStatus }],
      ["company-2", { id: "company-2", status: "ACTIVE" as CompanyStatus }]
    ]),
    users: new Map(users.map((user) => [user.id, user])),
    sessions: new Map(),
    employees: new Map(employees.map((employee) => [employee.id, employee])),
    reviewCycles: new Map(reviewCycles.map((reviewCycle) => [reviewCycle.id, reviewCycle])),
    reviews: new Map(reviews.map((review) => [review.id, review])),
    audits: [],
    counters: {
      session: 0,
      cycle: 0,
      review: 0
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

  const withReviewRelations = (review: PerformanceReviewRecord): PerformanceReviewRecord => ({
    ...review,
    reviewCycle: state.reviewCycles.get(review.reviewCycleId),
    employee: state.employees.get(review.employeeId),
    manager: state.employees.get(review.managerId)
  });

  const reviewsRepository: PerformanceReviewsRepository = {
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

    async findReviewCycleByNameInCompany(name, companyId) {
      return Array.from(state.reviewCycles.values()).find((reviewCycle) => reviewCycle.companyId === companyId && reviewCycle.name === name) ?? null;
    },

    async createReviewCycle(input: CreateReviewCycleRepositoryInput) {
      state.counters.cycle += 1;
      const reviewCycle: ReviewCycleRecord = {
        id: `cycle-new-${state.counters.cycle}`,
        companyId: input.companyId,
        name: input.name,
        startDate: input.startDate,
        endDate: input.endDate,
        status: "DRAFT" as ReviewCycleStatus,
        createdAt: now(),
        updatedAt: now()
      };

      state.reviewCycles.set(reviewCycle.id, reviewCycle);
      return reviewCycle;
    },

    async listReviewCyclesForCompany(companyId) {
      return Array.from(state.reviewCycles.values()).filter((reviewCycle) => reviewCycle.companyId === companyId);
    },

    async findReviewCycleByIdInCompany(reviewCycleId, companyId) {
      const reviewCycle = state.reviewCycles.get(reviewCycleId);
      return reviewCycle?.companyId === companyId ? reviewCycle : null;
    },

    async updateReviewCycle(reviewCycleId, companyId, input: UpdateReviewCycleRepositoryInput) {
      const current = await this.findReviewCycleByIdInCompany(reviewCycleId, companyId);
      const reviewCycle = { ...current!, ...compact(input), updatedAt: now() };

      state.reviewCycles.set(reviewCycle.id, reviewCycle);
      return reviewCycle;
    },

    async updateReviewCycleStatus(reviewCycleId, companyId, status) {
      const current = await this.findReviewCycleByIdInCompany(reviewCycleId, companyId);
      const reviewCycle = { ...current!, status, updatedAt: now() };

      state.reviewCycles.set(reviewCycle.id, reviewCycle);
      return reviewCycle;
    },

    async findPerformanceReviewByEmployeeCycle(employeeId, reviewCycleId, companyId) {
      const review = Array.from(state.reviews.values()).find(
        (candidate) => candidate.companyId === companyId && candidate.employeeId === employeeId && candidate.reviewCycleId === reviewCycleId
      );

      return review ? withReviewRelations(review) : null;
    },

    async createPerformanceReview(input: CreatePerformanceReviewRepositoryInput) {
      state.counters.review += 1;
      const review: PerformanceReviewRecord = {
        id: `review-new-${state.counters.review}`,
        companyId: input.companyId,
        reviewCycleId: input.reviewCycleId,
        employeeId: input.employeeId,
        managerId: input.managerId,
        summary: input.summary,
        rating: input.rating ?? null,
        status: input.status,
        submittedAt: input.submittedAt ?? null,
        createdAt: now(),
        updatedAt: now()
      };

      state.reviews.set(review.id, review);
      return withReviewRelations(review);
    },

    async listReviewsForEmployee(employeeId) {
      return Array.from(state.reviews.values())
        .filter((review) => review.employeeId === employeeId)
        .map(withReviewRelations);
    },

    async listReviewsForDirectReports(managerId, companyId) {
      return Array.from(state.reviews.values())
        .filter((review) => review.companyId === companyId && state.employees.get(review.employeeId)?.managerId === managerId)
        .map(withReviewRelations);
    },

    async listReviewsForCompany(companyId, filters: PerformanceReviewFilters) {
      return Array.from(state.reviews.values())
        .filter(
          (review) =>
            review.companyId === companyId &&
            (!filters.employeeId || review.employeeId === filters.employeeId) &&
            (!filters.reviewCycleId || review.reviewCycleId === filters.reviewCycleId) &&
            (!filters.status || review.status === filters.status) &&
            (!filters.from || review.createdAt >= filters.from) &&
            (!filters.to || review.createdAt <= filters.to)
        )
        .map(withReviewRelations);
    },

    async findPerformanceReviewByIdInCompany(reviewId, companyId) {
      const review = state.reviews.get(reviewId);
      return review?.companyId === companyId ? withReviewRelations(review) : null;
    },

    async updatePerformanceReview(reviewId, companyId, input: UpdatePerformanceReviewRepositoryInput) {
      const current = await this.findPerformanceReviewByIdInCompany(reviewId, companyId);
      const review = { ...current!, ...compact(input), reviewCycle: undefined, employee: undefined, manager: undefined, updatedAt: now() };

      state.reviews.set(review.id, review);
      return withReviewRelations(review);
    },

    async updatePerformanceReviewStatus(reviewId, companyId, input: UpdatePerformanceReviewStatusRepositoryInput) {
      const current = await this.findPerformanceReviewByIdInCompany(reviewId, companyId);
      const review = {
        ...current!,
        status: input.status,
        submittedAt: input.submittedAt ?? current!.submittedAt,
        reviewCycle: undefined,
        employee: undefined,
        manager: undefined,
        updatedAt: now()
      };

      state.reviews.set(review.id, review);
      return withReviewRelations(review);
    }
  };

  const auditRepository: AuditRepository = {
    async create(input) {
      state.audits.push(input);
    }
  };

  return { authRepository, reviewsRepository, auditRepository };
};

describe("CP12 performance reviews", () => {
  let passwordHash: string;
  let state: MemoryState;

  beforeAll(async () => {
    passwordHash = await hashPassword("Password123!");
  });

  beforeEach(() => {
    state = createState(passwordHash);
    const repositories = createRepositories(state);

    setAuthRepositoryForTests(repositories.authRepository);
    setPerformanceReviewsRepositoryForTests(repositories.reviewsRepository);
    setAuditRepositoryForTests(repositories.auditRepository);
  });

  afterEach(() => {
    resetAuthRepositoryForTests();
    resetPerformanceReviewsRepositoryForTests();
    resetAuditRepositoryForTests();
  });

  const login = async (email: string) => {
    const response = await request(app).post("/api/auth/login").send({ email, password: "Password123!" }).expect(200);

    return response.body.data.accessToken as string;
  };

  const auditActions = (category?: AuditActionCategory) =>
    state.audits.filter((audit) => !category || audit.category === category).map((audit) => audit.action);

  describe("review cycles", () => {
    it("allows COMPANY_ADMIN, HR_ADMIN, and scoped SUPER_ADMIN to create review cycles", async () => {
      const companyAdminToken = await login("companyadmin@example.test");
      const hrAdminToken = await login("hradmin@example.test");
      const superAdminToken = await login("superadmin@example.test");

      const companyAdminResponse = await request(app)
        .post("/api/admin/review-cycles")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ name: "Company Admin Cycle", startDate: "2026-07-01", endDate: "2026-09-30" })
        .expect(201);
      const hrResponse = await request(app)
        .post("/api/admin/review-cycles")
        .set("Authorization", `Bearer ${hrAdminToken}`)
        .send({ name: "HR Cycle", startDate: "2026-10-01", endDate: "2026-12-31" })
        .expect(201);
      const superResponse = await request(app)
        .post("/api/admin/review-cycles")
        .set("Authorization", `Bearer ${superAdminToken}`)
        .send({ companyId: "company-2", name: "Super Scoped Cycle", startDate: "2026-07-01", endDate: "2026-09-30" })
        .expect(201);

      expect(companyAdminResponse.body.data.reviewCycle).toMatchObject({ companyId: "company-1", status: "DRAFT" });
      expect(hrResponse.body.data.reviewCycle.companyId).toBe("company-1");
      expect(superResponse.body.data.reviewCycle.companyId).toBe("company-2");
      expect(auditActions("PERFORMANCE")).toEqual([
        "REVIEW_CYCLE_CREATED",
        "REVIEW_CYCLE_CREATED",
        "REVIEW_CYCLE_CREATED"
      ]);
    });

    it("rejects unauthorized or invalid review cycle creation", async () => {
      const managerToken = await login("manager@example.test");
      const employeeToken = await login("employee@example.test");
      const companyAdminToken = await login("companyadmin@example.test");

      await request(app)
        .post("/api/admin/review-cycles")
        .set("Authorization", `Bearer ${managerToken}`)
        .send({ name: "Manager Cycle", startDate: "2026-07-01", endDate: "2026-09-30" })
        .expect(403);
      await request(app)
        .post("/api/admin/review-cycles")
        .set("Authorization", `Bearer ${employeeToken}`)
        .send({ name: "Employee Cycle", startDate: "2026-07-01", endDate: "2026-09-30" })
        .expect(403);
      await request(app)
        .post("/api/admin/review-cycles")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ name: "Bad Dates", startDate: "2026-10-01", endDate: "2026-09-30" })
        .expect(400);
    });

    it("keeps review cycle list/detail/update/status company-scoped", async () => {
      const companyAdminToken = await login("companyadmin@example.test");
      const superAdminToken = await login("superadmin@example.test");

      const listResponse = await request(app)
        .get("/api/admin/review-cycles")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .expect(200);
      const superListResponse = await request(app)
        .get("/api/admin/review-cycles?companyId=company-2")
        .set("Authorization", `Bearer ${superAdminToken}`)
        .expect(200);
      const updateResponse = await request(app)
        .patch("/api/admin/review-cycles/cycle-active")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ name: "Updated Q3 Review" })
        .expect(200);
      const statusResponse = await request(app)
        .patch("/api/admin/review-cycles/cycle-active/status")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ status: "CLOSED" })
        .expect(200);

      expect(listResponse.body.data.reviewCycles).toHaveLength(3);
      expect(superListResponse.body.data.reviewCycles).toHaveLength(1);
      expect(updateResponse.body.data.reviewCycle.name).toBe("Updated Q3 Review");
      expect(statusResponse.body.data.reviewCycle.status).toBe("CLOSED");
      await request(app)
        .get("/api/admin/review-cycles/cycle-company2")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .expect(404);
      expect(auditActions("PERFORMANCE")).toEqual(["REVIEW_CYCLE_UPDATED", "REVIEW_CYCLE_STATUS_CHANGED"]);
    });
  });

  describe("review submission", () => {
    it("allows managers and admins to submit reviews within scope", async () => {
      const managerToken = await login("manager@example.test");
      const hrAdminToken = await login("hradmin@example.test");
      const companyAdminToken = await login("companyadmin@example.test");

      const managerResponse = await request(app)
        .post("/api/reviews/employee-direct2/manager-review")
        .set("Authorization", `Bearer ${managerToken}`)
        .send({ reviewCycleId: "cycle-active", summary: "Employee delivered the Q3 goals.", rating: 4 })
        .expect(201);
      const hrResponse = await request(app)
        .post("/api/reviews/employee-other/manager-review")
        .set("Authorization", `Bearer ${hrAdminToken}`)
        .send({ reviewCycleId: "cycle-active-secondary", summary: "HR review summary.", rating: 5 })
        .expect(201);
      const adminResponse = await request(app)
        .post("/api/reviews/employee-self/manager-review")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ reviewCycleId: "cycle-active-secondary", summary: "Admin review summary." })
        .expect(201);

      expect(managerResponse.body.data.review).toMatchObject({
        employeeId: "employee-direct2",
        managerId: "employee-manager",
        status: "SUBMITTED",
        rating: 4
      });
      expect(hrResponse.body.data.review.managerId).toBe("employee-hr-admin");
      expect(adminResponse.body.data.review.managerId).toBe("employee-company-admin");
      expect(managerResponse.body.data.review.submittedAt).toBeTruthy();
      expect(auditActions("PERFORMANCE")).toEqual([
        "PERFORMANCE_REVIEW_SUBMITTED",
        "PERFORMANCE_REVIEW_SUBMITTED",
        "PERFORMANCE_REVIEW_SUBMITTED"
      ]);
      expect(JSON.stringify(state.audits)).not.toContain("Employee delivered the Q3 goals");
      expect(JSON.stringify(state.audits)).not.toContain("HR review summary");
    });

    it("rejects invalid or unauthorized review submissions", async () => {
      const managerToken = await login("manager@example.test");
      const employeeToken = await login("employee@example.test");
      const companyAdminToken = await login("companyadmin@example.test");

      await request(app)
        .post("/api/reviews/employee-other/manager-review")
        .set("Authorization", `Bearer ${managerToken}`)
        .send({ reviewCycleId: "cycle-active-secondary", summary: "Not direct report.", rating: 4 })
        .expect(403);
      await request(app)
        .post("/api/reviews/employee-self/manager-review")
        .set("Authorization", `Bearer ${employeeToken}`)
        .send({ reviewCycleId: "cycle-active-secondary", summary: "Employee cannot submit.", rating: 4 })
        .expect(403);
      await request(app)
        .post("/api/reviews/employee-company2/manager-review")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ reviewCycleId: "cycle-active", summary: "Cross company employee.", rating: 4 })
        .expect(404);
      await request(app)
        .post("/api/reviews/employee-direct2/manager-review")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ reviewCycleId: "cycle-company2", summary: "Cross company cycle.", rating: 4 })
        .expect(404);
      await request(app)
        .post("/api/reviews/employee-self/manager-review")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ reviewCycleId: "cycle-active", summary: "Duplicate.", rating: 4 })
        .expect(409);
      await request(app)
        .post("/api/reviews/employee-direct2/manager-review")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ reviewCycleId: "cycle-draft", summary: "Inactive cycle.", rating: 4 })
        .expect(400);
      await request(app)
        .post("/api/reviews/employee-direct2/manager-review")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ reviewCycleId: "cycle-active", rating: 4 })
        .expect(400);
      await request(app)
        .post("/api/reviews/employee-direct2/manager-review")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ reviewCycleId: "cycle-active", summary: "Bad rating.", rating: 6 })
        .expect(400);
    });
  });

  describe("review views", () => {
    it("enforces self, team, admin, and scoped super-admin review views", async () => {
      const employeeToken = await login("employee@example.test");
      const managerToken = await login("manager@example.test");
      const companyAdminToken = await login("companyadmin@example.test");
      const superAdminToken = await login("superadmin@example.test");

      const selfResponse = await request(app).get("/api/reviews/me").set("Authorization", `Bearer ${employeeToken}`).expect(200);
      const teamResponse = await request(app).get("/api/reviews/team").set("Authorization", `Bearer ${managerToken}`).expect(200);
      const adminResponse = await request(app)
        .get("/api/admin/reviews?status=SUBMITTED")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .expect(200);
      const superResponse = await request(app)
        .get("/api/admin/reviews?companyId=company-2")
        .set("Authorization", `Bearer ${superAdminToken}`)
        .expect(200);

      expect(selfResponse.body.data.reviews.map((review: { employeeId: string }) => review.employeeId)).toEqual(["employee-self"]);
      await request(app).get("/api/reviews/review-other").set("Authorization", `Bearer ${employeeToken}`).expect(403);
      expect(teamResponse.body.data.reviews.map((review: { employeeId: string }) => review.employeeId).sort()).toEqual([
        "employee-direct2",
        "employee-self"
      ]);
      await request(app).get("/api/reviews/review-other").set("Authorization", `Bearer ${managerToken}`).expect(403);
      expect(adminResponse.body.data.reviews.map((review: { status: string }) => review.status)).toEqual(["SUBMITTED", "SUBMITTED"]);
      expect(superResponse.body.data.reviews).toHaveLength(1);
      await request(app).get("/api/reviews/review-company2").set("Authorization", `Bearer ${companyAdminToken}`).expect(404);
    });
  });

  describe("review updates and status", () => {
    it("allows managers and admins to update review summaries and ratings in scope", async () => {
      const managerToken = await login("manager@example.test");
      const hrAdminToken = await login("hradmin@example.test");
      const employeeToken = await login("employee@example.test");

      const managerResponse = await request(app)
        .patch("/api/reviews/review-self")
        .set("Authorization", `Bearer ${managerToken}`)
        .send({ summary: "Updated direct-report summary.", rating: 5 })
        .expect(200);
      const hrResponse = await request(app)
        .patch("/api/reviews/review-other")
        .set("Authorization", `Bearer ${hrAdminToken}`)
        .send({ rating: 3 })
        .expect(200);

      await request(app)
        .patch("/api/reviews/review-self")
        .set("Authorization", `Bearer ${employeeToken}`)
        .send({ summary: "Employee cannot update." })
        .expect(403);
      await request(app)
        .patch("/api/reviews/review-other")
        .set("Authorization", `Bearer ${managerToken}`)
        .send({ summary: "Non-direct report." })
        .expect(403);

      expect(managerResponse.body.data.review).toMatchObject({ summary: "Updated direct-report summary.", rating: 5 });
      expect(hrResponse.body.data.review.rating).toBe(3);
      expect(auditActions("PERFORMANCE")).toEqual(["PERFORMANCE_REVIEW_UPDATED", "PERFORMANCE_REVIEW_UPDATED"]);
      expect(JSON.stringify(state.audits)).not.toContain("Updated direct-report summary");
    });

    it("updates review status, validates enum values, and sets submittedAt when needed", async () => {
      const managerToken = await login("manager@example.test");
      const companyAdminToken = await login("companyadmin@example.test");

      const statusResponse = await request(app)
        .patch("/api/reviews/review-draft/status")
        .set("Authorization", `Bearer ${managerToken}`)
        .send({ status: "SUBMITTED" })
        .expect(200);
      const adminStatusResponse = await request(app)
        .patch("/api/reviews/review-other/status")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ status: "ACKNOWLEDGED" })
        .expect(200);

      await request(app)
        .patch("/api/reviews/review-self/status")
        .set("Authorization", `Bearer ${managerToken}`)
        .send({ status: "FINALIZED" })
        .expect(400);

      expect(statusResponse.body.data.review.status).toBe("SUBMITTED");
      expect(statusResponse.body.data.review.submittedAt).toBeTruthy();
      expect(adminStatusResponse.body.data.review.status).toBe("ACKNOWLEDGED");
      expect(auditActions("PERFORMANCE")).toEqual(["PERFORMANCE_REVIEW_STATUS_CHANGED", "PERFORMANCE_REVIEW_STATUS_CHANGED"]);
    });
  });
});
