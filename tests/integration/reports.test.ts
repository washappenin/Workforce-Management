import type {
  CompanyStatus,
  DeviceSessionStatus,
  EmployeeStatus,
  LeaveRequestStatus,
  OKRStatus,
  PerformanceReviewStatus,
  SubscriptionStatus,
  UserStatus
} from "@prisma/client";
import request from "supertest";

import { app } from "../../src/app";
import { hashPassword } from "../../src/lib/password";
import type { AuthDeviceSessionRecord, AuthRepository, AuthUserRecord } from "../../src/modules/auth/auth.repository";
import { resetAuthRepositoryForTests, setAuthRepositoryForTests } from "../../src/modules/auth/auth.repository";
import type {
  AttendanceReportFilters,
  AttendanceReportSummary,
  CompanyDashboardSummary,
  CompanyRollupSummary,
  EmployeeDashboardSummary,
  LeaveReportFilters,
  LeaveReportSummary,
  OkrReportFilters,
  OkrReportSummary,
  PerformanceReportFilters,
  PerformanceReportSummary,
  PlatformDashboardSummary,
  ReportCompanyRecord,
  ReportEmployeeRecord,
  ReportScope,
  ReportsRepository
} from "../../src/modules/reports/reports.repository";
import { resetReportsRepositoryForTests, setReportsRepositoryForTests } from "../../src/modules/reports/reports.repository";
import type { Role } from "../../src/types/auth";

interface AttendanceRecord {
  id: string;
  companyId: string;
  employeeId: string;
  status: "OPEN" | "CLOSED";
  clockInAt: Date;
}

interface LeaveRecord {
  companyId: string;
  employeeId: string;
  leaveTypeId: string;
  leaveTypeName: string;
  status: LeaveRequestStatus;
  startDate: Date;
}

interface EntitlementRecord {
  companyId: string;
  employeeId: string;
  leaveTypeId: string;
  leaveTypeName: string;
  year: number;
  totalDays: number;
  usedDays: number;
}

interface OkrRecord {
  companyId: string;
  employeeId: string;
  status: OKRStatus;
  dueDate: Date | null;
  progressPercent: number | null;
}

interface PerformanceRecord {
  id: string;
  companyId: string;
  employeeId: string;
  reviewCycleId: string;
  reviewCycleName: string;
  status: PerformanceReviewStatus;
  rating: number | null;
  submittedAt: Date | null;
  createdAt: Date;
}

interface MemoryState {
  companies: Map<string, ReportCompanyRecord & { name: string; status: CompanyStatus; createdAt: Date; subscriptionStatus: SubscriptionStatus | null }>;
  departments: Map<string, { id: string; companyId: string }>;
  users: Map<string, AuthUserRecord>;
  sessions: Map<string, AuthDeviceSessionRecord>;
  employees: Map<string, ReportEmployeeRecord>;
  attendance: AttendanceRecord[];
  leaveRequests: LeaveRecord[];
  entitlements: EntitlementRecord[];
  okrs: OkrRecord[];
  performanceReviews: PerformanceRecord[];
  notifications: Array<{ userId: string; status: "UNREAD" | "READ" }>;
  shifts: EmployeeDashboardSummary["shift"]["currentAssignments"];
  counters: Record<string, number>;
}

const now = () => new Date("2026-06-03T08:00:00.000Z");
const dateOnly = (value: string) => new Date(`${value}T00:00:00.000Z`);

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
  departmentId: string | null,
  managerId: string | null = null,
  status: EmployeeStatus = "ACTIVE" as EmployeeStatus
): ReportEmployeeRecord => ({
  id,
  companyId,
  userId,
  departmentId,
  managerId,
  status,
  companyStatus: "ACTIVE" as CompanyStatus
});

const createState = (passwordHash: string): MemoryState => {
  const users = [
    makeUser("user-super-admin", "superadmin@example.test", null, ["SUPER_ADMIN"], passwordHash),
    makeUser("user-company-admin", "companyadmin@example.test", "company-1", ["COMPANY_ADMIN"], passwordHash),
    makeUser("user-hr-admin", "hradmin@example.test", "company-1", ["HR_ADMIN"], passwordHash),
    makeUser("user-manager", "manager@example.test", "company-1", ["MANAGER"], passwordHash),
    makeUser("user-manager-no-profile", "manager-noprofile@example.test", "company-1", ["MANAGER"], passwordHash),
    makeUser("user-employee", "employee@example.test", "company-1", ["EMPLOYEE"], passwordHash),
    makeUser("user-other-employee", "otheremployee@example.test", "company-1", ["EMPLOYEE"], passwordHash),
    makeUser("user-company2-employee", "company2employee@example.test", "company-2", ["EMPLOYEE"], passwordHash)
  ];
  const employees = [
    makeEmployee("employee-company-admin", "company-1", "user-company-admin", "department-1"),
    makeEmployee("employee-hr-admin", "company-1", "user-hr-admin", "department-1"),
    makeEmployee("employee-manager", "company-1", "user-manager", "department-1"),
    makeEmployee("employee-self", "company-1", "user-employee", "department-1", "employee-manager"),
    makeEmployee("employee-other", "company-1", "user-other-employee", "department-1"),
    makeEmployee("employee-company2", "company-2", "user-company2-employee", "department-2")
  ];

  return {
    companies: new Map([
      ["company-1", { id: "company-1", name: "Demo Company", status: "ACTIVE" as CompanyStatus, createdAt: dateOnly("2026-01-01"), subscriptionStatus: "ACTIVE" as SubscriptionStatus }],
      ["company-2", { id: "company-2", name: "Other Company", status: "INACTIVE" as CompanyStatus, createdAt: dateOnly("2026-05-20"), subscriptionStatus: null }]
    ]),
    departments: new Map([
      ["department-1", { id: "department-1", companyId: "company-1" }],
      ["department-2", { id: "department-2", companyId: "company-2" }]
    ]),
    users: new Map(users.map((user) => [user.id, user])),
    sessions: new Map(),
    employees: new Map(employees.map((employee) => [employee.id, employee])),
    attendance: [
      { id: "attendance-self-open", companyId: "company-1", employeeId: "employee-self", status: "OPEN", clockInAt: now() },
      { id: "attendance-other-closed", companyId: "company-1", employeeId: "employee-other", status: "CLOSED", clockInAt: now() },
      { id: "attendance-company2", companyId: "company-2", employeeId: "employee-company2", status: "OPEN", clockInAt: now() }
    ],
    leaveRequests: [
      { companyId: "company-1", employeeId: "employee-self", leaveTypeId: "leave-type-annual", leaveTypeName: "Annual", status: "PENDING" as LeaveRequestStatus, startDate: dateOnly("2026-06-10") },
      { companyId: "company-1", employeeId: "employee-other", leaveTypeId: "leave-type-annual", leaveTypeName: "Annual", status: "APPROVED" as LeaveRequestStatus, startDate: dateOnly("2026-07-01") },
      { companyId: "company-2", employeeId: "employee-company2", leaveTypeId: "leave-type-company2", leaveTypeName: "Other", status: "PENDING" as LeaveRequestStatus, startDate: dateOnly("2026-06-10") }
    ],
    entitlements: [
      { companyId: "company-1", employeeId: "employee-self", leaveTypeId: "leave-type-annual", leaveTypeName: "Annual", year: 2026, totalDays: 20, usedDays: 18 },
      { companyId: "company-1", employeeId: "employee-other", leaveTypeId: "leave-type-annual", leaveTypeName: "Annual", year: 2026, totalDays: 20, usedDays: 5 },
      { companyId: "company-2", employeeId: "employee-company2", leaveTypeId: "leave-type-company2", leaveTypeName: "Other", year: 2026, totalDays: 20, usedDays: 0 }
    ],
    okrs: [
      { companyId: "company-1", employeeId: "employee-self", status: "IN_PROGRESS" as OKRStatus, dueDate: dateOnly("2026-09-30"), progressPercent: 50 },
      { companyId: "company-1", employeeId: "employee-other", status: "APPROVED" as OKRStatus, dueDate: dateOnly("2026-05-01"), progressPercent: 100 },
      { companyId: "company-2", employeeId: "employee-company2", status: "ASSIGNED" as OKRStatus, dueDate: dateOnly("2026-05-01"), progressPercent: null }
    ],
    performanceReviews: [
      { id: "review-self", companyId: "company-1", employeeId: "employee-self", reviewCycleId: "cycle-1", reviewCycleName: "Q3 Review", status: "DRAFT" as PerformanceReviewStatus, rating: null, submittedAt: null, createdAt: dateOnly("2026-06-01") },
      { id: "review-other", companyId: "company-1", employeeId: "employee-other", reviewCycleId: "cycle-1", reviewCycleName: "Q3 Review", status: "ACKNOWLEDGED" as PerformanceReviewStatus, rating: 4, submittedAt: now(), createdAt: dateOnly("2026-06-02") },
      { id: "review-company2", companyId: "company-2", employeeId: "employee-company2", reviewCycleId: "cycle-2", reviewCycleName: "Other Review", status: "SUBMITTED" as PerformanceReviewStatus, rating: 3, submittedAt: now(), createdAt: dateOnly("2026-06-02") }
    ],
    notifications: [
      { userId: "user-company-admin", status: "UNREAD" },
      { userId: "user-employee", status: "UNREAD" },
      { userId: "user-employee", status: "READ" }
    ],
    shifts: [
      {
        assignmentId: "shift-assignment-self",
        shiftId: "shift-1",
        name: "Morning",
        startTime: "09:00",
        endTime: "17:00",
        startsOn: dateOnly("2026-06-01"),
        endsOn: null
      }
    ],
    counters: { session: 0 }
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

  const employeeInScope = (scope: ReportScope, employeeId: string, departmentId?: string) => {
    const employee = state.employees.get(employeeId);

    return (
      Boolean(employee) &&
      employee!.companyId === scope.companyId &&
      (!scope.employeeIds || scope.employeeIds.includes(employeeId)) &&
      (!departmentId || employee!.departmentId === departmentId)
    );
  };

  const scopedEmployees = (scope: ReportScope) =>
    Array.from(state.employees.values()).filter((employee) => employeeInScope(scope, employee.id));

  const filterEmployee = <T extends { employeeId: string }>(
    records: T[],
    scope: ReportScope,
    filters: { employeeId?: string; departmentId?: string }
  ) =>
    records.filter(
      (record) =>
        employeeInScope(scope, record.employeeId, filters.departmentId) &&
        (!filters.employeeId || record.employeeId === filters.employeeId)
    );

  const reportsRepository: ReportsRepository = {
    async findCompanyById(companyId) {
      return state.companies.get(companyId) ?? null;
    },

    async findEmployeeByUserId(userId) {
      return Array.from(state.employees.values()).find((employee) => employee.userId === userId) ?? null;
    },

    async findEmployeeByIdInCompany(employeeId, companyId) {
      const employee = state.employees.get(employeeId);
      return employee?.companyId === companyId ? employee : null;
    },

    async findDepartmentByIdInCompany(departmentId, companyId) {
      const department = state.departments.get(departmentId);
      return department?.companyId === companyId ? { id: department.id } : null;
    },

    async findReviewCycleByIdInCompany(reviewCycleId, companyId) {
      const review = state.performanceReviews.find((performanceReview) => performanceReview.reviewCycleId === reviewCycleId && performanceReview.companyId === companyId);
      return review ? { id: review.reviewCycleId } : null;
    },

    async listDirectReportIds(managerId, companyId) {
      return Array.from(state.employees.values())
        .filter((employee) => employee.companyId === companyId && employee.managerId === managerId && employee.status === "ACTIVE")
        .map((employee) => employee.id);
    },

    async getDashboardSummary(scope, actorUserId): Promise<CompanyDashboardSummary> {
      const employees = scopedEmployees(scope);
      const attendance = filterEmployee(state.attendance, scope, {});
      const leave = filterEmployee(state.leaveRequests, scope, {});
      const okrs = filterEmployee(state.okrs, scope, {});
      const performance = filterEmployee(state.performanceReviews, scope, {});

      return {
        companyId: scope.companyId,
        employees: {
          total: employees.length,
          active: employees.filter((employee) => employee.status === "ACTIVE").length,
          inactive: employees.filter((employee) => employee.status !== "ACTIVE").length
        },
        departments: {
          total: new Set(employees.map((employee) => employee.departmentId).filter(Boolean)).size
        },
        attendance: {
          todayClockIns: attendance.length,
          openSessions: attendance.filter((session) => session.status === "OPEN").length
        },
        leave: {
          pendingRequests: leave.filter((request) => request.status === "PENDING").length
        },
        okrs: {
          active: okrs.filter((okr) => ["ASSIGNED", "IN_PROGRESS", "SUBMITTED"].includes(okr.status)).length
        },
        performance: {
          pendingReviews: performance.filter((review) => review.status === "DRAFT").length
        },
        notifications: {
          unreadCount: state.notifications.filter((notification) => notification.userId === actorUserId && notification.status === "UNREAD").length
        }
      };
    },

    async getAttendanceSummary(scope, filters): Promise<AttendanceReportSummary> {
      const attendance = filterEmployee(state.attendance, scope, filters).filter(
        (session) => (!filters.from || session.clockInAt >= filters.from) && (!filters.to || session.clockInAt <= filters.to)
      );
      const byDay = new Map<string, number>();

      for (const session of attendance) {
        const day = session.clockInAt.toISOString().slice(0, 10);
        byDay.set(day, (byDay.get(day) ?? 0) + 1);
      }

      return {
        totalSessions: attendance.length,
        openSessions: attendance.filter((session) => session.status === "OPEN").length,
        closedSessions: attendance.filter((session) => session.status === "CLOSED").length,
        clockInsByDay: Array.from(byDay.entries()).map(([date, count]) => ({ date, count }))
      };
    },

    async getLeaveSummary(scope, filters: LeaveReportFilters): Promise<LeaveReportSummary> {
      const requests = filterEmployee(state.leaveRequests, scope, filters).filter(
        (request) => (!filters.status || request.status === filters.status) && (!filters.year || request.startDate.getUTCFullYear() === filters.year)
      );
      const entitlements = filterEmployee(state.entitlements, scope, filters).filter((entitlement) => !filters.year || entitlement.year === filters.year);
      const usage = new Map<string, { leaveTypeId: string; leaveTypeName: string; usedDays: number; totalDays: number }>();

      for (const entitlement of entitlements) {
        const current = usage.get(entitlement.leaveTypeId) ?? {
          leaveTypeId: entitlement.leaveTypeId,
          leaveTypeName: entitlement.leaveTypeName,
          usedDays: 0,
          totalDays: 0
        };
        current.usedDays += entitlement.usedDays;
        current.totalDays += entitlement.totalDays;
        usage.set(entitlement.leaveTypeId, current);
      }

      return {
        totalRequests: requests.length,
        pendingRequests: requests.filter((request) => request.status === "PENDING").length,
        approvedRequests: requests.filter((request) => request.status === "APPROVED").length,
        rejectedRequests: requests.filter((request) => request.status === "REJECTED").length,
        leaveUsageByType: Array.from(usage.values()),
        lowRemainingLeave: entitlements
          .filter((entitlement) => entitlement.totalDays - entitlement.usedDays <= 2)
          .map((entitlement) => ({
            employeeId: entitlement.employeeId,
            leaveTypeId: entitlement.leaveTypeId,
            leaveTypeName: entitlement.leaveTypeName,
            remainingDays: entitlement.totalDays - entitlement.usedDays
          }))
      };
    },

    async getOkrSummary(scope, filters: OkrReportFilters): Promise<OkrReportSummary> {
      const okrs = filterEmployee(state.okrs, scope, filters).filter((okr) => !filters.status || okr.status === filters.status);
      const statusCounts: OkrReportSummary["statusCounts"] = {
        DRAFT: 0,
        ASSIGNED: 0,
        IN_PROGRESS: 0,
        SUBMITTED: 0,
        APPROVED: 0,
        REJECTED: 0,
        ARCHIVED: 0
      };
      const progress = okrs.map((okr) => okr.progressPercent).filter((value): value is number => value !== null);

      for (const okr of okrs) {
        statusCounts[okr.status] += 1;
      }

      return {
        totalOkrs: okrs.length,
        statusCounts,
        activeCount: okrs.filter((okr) => ["ASSIGNED", "IN_PROGRESS", "SUBMITTED"].includes(okr.status)).length,
        completedCount: statusCounts.APPROVED,
        averageProgressPercent: progress.length ? progress.reduce((sum, value) => sum + value, 0) / progress.length : null,
        overdueCount: okrs.filter((okr) => okr.dueDate && okr.dueDate < now() && okr.status !== "APPROVED" && okr.status !== "ARCHIVED").length
      };
    },

    async getPerformanceSummary(scope, filters: PerformanceReportFilters): Promise<PerformanceReportSummary> {
      const reviews = filterEmployee(state.performanceReviews, scope, filters).filter(
        (review) =>
          (!filters.status || review.status === filters.status) && (!filters.reviewCycleId || review.reviewCycleId === filters.reviewCycleId)
      );
      const statusCounts: PerformanceReportSummary["statusCounts"] = { DRAFT: 0, SUBMITTED: 0, ACKNOWLEDGED: 0, ARCHIVED: 0 };
      const ratings = reviews.map((review) => review.rating).filter((value): value is number => value !== null);
      const byCycle = new Map<string, { reviewCycleId: string; reviewCycleName: string; count: number }>();

      for (const review of reviews) {
        statusCounts[review.status] += 1;
        const current = byCycle.get(review.reviewCycleId) ?? { reviewCycleId: review.reviewCycleId, reviewCycleName: review.reviewCycleName, count: 0 };
        current.count += 1;
        byCycle.set(review.reviewCycleId, current);
      }

      return {
        totalReviews: reviews.length,
        statusCounts,
        pendingReviews: statusCounts.DRAFT,
        submittedReviews: statusCounts.SUBMITTED,
        finalizedReviews: statusCounts.ACKNOWLEDGED,
        averageRating: ratings.length ? ratings.reduce((sum, value) => sum + value, 0) / ratings.length : null,
        reviewsByCycle: Array.from(byCycle.values())
      };
    },

    async getEmployeeDashboard(employee): Promise<EmployeeDashboardSummary> {
      const attendance = state.attendance.filter((session) => session.employeeId === employee.id);
      const openSession = attendance.find((session) => session.status === "OPEN") ?? null;
      const entitlements = state.entitlements.filter((entitlement) => entitlement.employeeId === employee.id);
      const latestReview = state.performanceReviews
        .filter((review) => review.employeeId === employee.id)
        .sort((left, right) => right.createdAt.getTime() - left.createdAt.getTime())[0];

      return {
        employeeId: employee.id,
        companyId: employee.companyId,
        attendance: {
          todayStatus: openSession ? "CLOCKED_IN" : attendance.length ? "CLOCKED_OUT" : "NOT_CLOCKED_IN",
          openSession: openSession ? { id: openSession.id, clockInAt: openSession.clockInAt, status: openSession.status } : null
        },
        shift: {
          currentAssignments: employee.id === "employee-self" ? state.shifts : []
        },
        leave: {
          pendingRequestsCount: state.leaveRequests.filter((request) => request.employeeId === employee.id && request.status === "PENDING").length,
          balances: entitlements.map((entitlement) => ({
            leaveTypeId: entitlement.leaveTypeId,
            leaveTypeName: entitlement.leaveTypeName,
            year: entitlement.year,
            totalDays: entitlement.totalDays,
            usedDays: entitlement.usedDays,
            remainingDays: entitlement.totalDays - entitlement.usedDays
          }))
        },
        okrs: {
          activeCount: state.okrs.filter((okr) => okr.employeeId === employee.id && ["ASSIGNED", "IN_PROGRESS", "SUBMITTED"].includes(okr.status)).length
        },
        performance: {
          latestReview: latestReview
            ? {
                id: latestReview.id,
                reviewCycleId: latestReview.reviewCycleId,
                status: latestReview.status,
                rating: latestReview.rating,
                submittedAt: latestReview.submittedAt,
                createdAt: latestReview.createdAt
              }
            : null
        },
        notifications: {
          unreadCount: state.notifications.filter((notification) => notification.userId === employee.userId && notification.status === "UNREAD").length
        }
      };
    },

    async getPlatformDashboard(): Promise<PlatformDashboardSummary> {
      const companies = Array.from(state.companies.values());
      const users = Array.from(state.users.values());

      return {
        totalCompanies: companies.length,
        activeCompanies: companies.filter((company) => company.status === "ACTIVE").length,
        inactiveCompanies: companies.filter((company) => company.status !== "ACTIVE").length,
        totalUsers: users.length,
        activeUsers: users.filter((user) => user.status === "ACTIVE").length,
        totalSubscriptions: companies.filter((company) => company.subscriptionStatus).length,
        recentCompanyCount: 1
      };
    },

    async getCompanyRollups(): Promise<CompanyRollupSummary[]> {
      return Array.from(state.companies.values()).map((company) => {
        const employees = Array.from(state.employees.values()).filter((employee) => employee.companyId === company.id);

        return {
          companyId: company.id,
          name: company.name,
          status: company.status,
          employeeCount: employees.length,
          activeEmployeeCount: employees.filter((employee) => employee.status === "ACTIVE").length,
          subscriptionStatus: company.subscriptionStatus,
          createdAt: company.createdAt
        };
      });
    }
  };

  return { authRepository, reportsRepository };
};

describe("CP14 reports and dashboards", () => {
  let passwordHash: string;
  let state: MemoryState;

  beforeAll(async () => {
    passwordHash = await hashPassword("Password123!");
  });

  beforeEach(() => {
    state = createState(passwordHash);
    const repositories = createRepositories(state);

    setAuthRepositoryForTests(repositories.authRepository);
    setReportsRepositoryForTests(repositories.reportsRepository);
  });

  afterEach(() => {
    resetAuthRepositoryForTests();
    resetReportsRepositoryForTests();
  });

  const login = async (email: string) => {
    const response = await request(app).post("/api/auth/login").send({ email, password: "Password123!" }).expect(200);

    return response.body.data.accessToken as string;
  };

  describe("admin reports", () => {
    it("allows company admins, HR admins, and scoped super admins to view company dashboard summaries", async () => {
      const companyAdminToken = await login("companyadmin@example.test");
      const hrAdminToken = await login("hradmin@example.test");
      const superAdminToken = await login("superadmin@example.test");

      const companyAdminResponse = await request(app)
        .get("/api/admin/reports/dashboard")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .expect(200);
      const hrResponse = await request(app).get("/api/admin/reports/dashboard").set("Authorization", `Bearer ${hrAdminToken}`).expect(200);
      const superResponse = await request(app)
        .get("/api/admin/reports/dashboard?companyId=company-2")
        .set("Authorization", `Bearer ${superAdminToken}`)
        .expect(200);

      expect(companyAdminResponse.body.data.dashboard).toMatchObject({
        companyId: "company-1",
        employees: { total: 5, active: 5, inactive: 0 },
        attendance: { todayClockIns: 2, openSessions: 1 },
        leave: { pendingRequests: 1 },
        okrs: { active: 1 },
        performance: { pendingReviews: 1 },
        notifications: { unreadCount: 1 }
      });
      expect(hrResponse.body.data.dashboard.companyId).toBe("company-1");
      expect(superResponse.body.data.dashboard).toMatchObject({ companyId: "company-2", employees: { total: 1, active: 1 } });
    });

    it("rejects admin dashboard access for managers, employees, and non-super company overrides", async () => {
      const managerToken = await login("manager@example.test");
      const employeeToken = await login("employee@example.test");
      const companyAdminToken = await login("companyadmin@example.test");

      await request(app).get("/api/admin/reports/dashboard").set("Authorization", `Bearer ${managerToken}`).expect(403);
      await request(app).get("/api/admin/reports/dashboard").set("Authorization", `Bearer ${employeeToken}`).expect(403);
      await request(app)
        .get("/api/admin/reports/dashboard?companyId=company-2")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .expect(403);
    });

    it("returns company-scoped attendance, leave, OKR, and performance summaries", async () => {
      const companyAdminToken = await login("companyadmin@example.test");

      const attendanceResponse = await request(app)
        .get("/api/admin/reports/attendance?from=2026-06-01&to=2026-06-30")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .expect(200);
      const leaveResponse = await request(app)
        .get("/api/admin/reports/leave?year=2026")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .expect(200);
      const okrResponse = await request(app).get("/api/admin/reports/okrs").set("Authorization", `Bearer ${companyAdminToken}`).expect(200);
      const performanceResponse = await request(app)
        .get("/api/admin/reports/performance")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .expect(200);

      expect(attendanceResponse.body.data.report).toMatchObject({ totalSessions: 2, openSessions: 1, closedSessions: 1 });
      expect(JSON.stringify(attendanceResponse.body)).not.toContain("latitude");
      expect(leaveResponse.body.data.report).toMatchObject({ totalRequests: 2, pendingRequests: 1, approvedRequests: 1 });
      expect(JSON.stringify(leaveResponse.body)).not.toContain("Family matter");
      expect(okrResponse.body.data.report).toMatchObject({ totalOkrs: 2, activeCount: 1, completedCount: 1, averageProgressPercent: 75 });
      expect(performanceResponse.body.data.report).toMatchObject({ totalReviews: 2, pendingReviews: 1, finalizedReviews: 1, averageRating: 4 });
      expect(JSON.stringify(performanceResponse.body)).not.toContain("summary");
    });

    it("rejects invalid and cross-company admin report filters", async () => {
      const companyAdminToken = await login("companyadmin@example.test");

      await request(app)
        .get("/api/admin/reports/attendance?from=2026-07-01&to=2026-06-01")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .expect(400);
      await request(app)
        .get("/api/admin/reports/attendance?employeeId=employee-company2")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .expect(404);
      await request(app)
        .get("/api/admin/reports/leave?departmentId=department-2")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .expect(404);
    });
  });

  describe("manager reports", () => {
    it("allows managers to view direct-report dashboard and report summaries only", async () => {
      const managerToken = await login("manager@example.test");

      const dashboardResponse = await request(app).get("/api/reports/team/dashboard").set("Authorization", `Bearer ${managerToken}`).expect(200);
      const attendanceResponse = await request(app).get("/api/reports/team/attendance").set("Authorization", `Bearer ${managerToken}`).expect(200);
      const leaveResponse = await request(app).get("/api/reports/team/leave").set("Authorization", `Bearer ${managerToken}`).expect(200);
      const okrResponse = await request(app).get("/api/reports/team/okrs").set("Authorization", `Bearer ${managerToken}`).expect(200);
      const performanceResponse = await request(app).get("/api/reports/team/performance").set("Authorization", `Bearer ${managerToken}`).expect(200);

      expect(dashboardResponse.body.data.dashboard.employees.total).toBe(1);
      expect(attendanceResponse.body.data.report.totalSessions).toBe(1);
      expect(leaveResponse.body.data.report.totalRequests).toBe(1);
      expect(okrResponse.body.data.report.totalOkrs).toBe(1);
      expect(performanceResponse.body.data.report.totalReviews).toBe(1);
      expect(JSON.stringify(dashboardResponse.body)).not.toContain("employee-other");
    });

    it("rejects manager non-direct report filters and managers without employee profiles", async () => {
      const managerToken = await login("manager@example.test");
      const noProfileToken = await login("manager-noprofile@example.test");

      await request(app)
        .get("/api/reports/team/attendance?employeeId=employee-other")
        .set("Authorization", `Bearer ${managerToken}`)
        .expect(403);
      await request(app)
        .get("/api/reports/team/dashboard")
        .set("Authorization", `Bearer ${noProfileToken}`)
        .expect(403);
    });
  });

  describe("employee dashboard", () => {
    it("allows employees to view only their own dashboard", async () => {
      const employeeToken = await login("employee@example.test");

      const response = await request(app).get("/api/reports/me/dashboard").set("Authorization", `Bearer ${employeeToken}`).expect(200);

      expect(response.body.data.dashboard).toMatchObject({
        employeeId: "employee-self",
        attendance: { todayStatus: "CLOCKED_IN" },
        leave: { pendingRequestsCount: 1 },
        okrs: { activeCount: 1 },
        notifications: { unreadCount: 1 }
      });
      expect(response.body.data.dashboard.performance.latestReview).toMatchObject({ id: "review-self", status: "DRAFT" });
      expect(JSON.stringify(response.body)).not.toContain("employee-other");
      expect(JSON.stringify(response.body)).not.toContain("summary");
      expect(JSON.stringify(response.body)).not.toContain("latitude");
    });

    it("rejects users without employee profiles", async () => {
      const superAdminToken = await login("superadmin@example.test");

      await request(app).get("/api/reports/me/dashboard").set("Authorization", `Bearer ${superAdminToken}`).expect(403);
    });
  });

  describe("super-admin reports", () => {
    it("allows super admins to view platform dashboard and company rollups", async () => {
      const superAdminToken = await login("superadmin@example.test");

      const dashboardResponse = await request(app)
        .get("/api/super-admin/reports/dashboard")
        .set("Authorization", `Bearer ${superAdminToken}`)
        .expect(200);
      const companiesResponse = await request(app)
        .get("/api/super-admin/reports/companies")
        .set("Authorization", `Bearer ${superAdminToken}`)
        .expect(200);

      expect(dashboardResponse.body.data.dashboard).toMatchObject({
        totalCompanies: 2,
        activeCompanies: 1,
        inactiveCompanies: 1,
        totalSubscriptions: 1
      });
      expect(companiesResponse.body.data.companies).toHaveLength(2);
      expect(companiesResponse.body.data.companies[0]).toHaveProperty("employeeCount");
      expect(JSON.stringify(companiesResponse.body)).not.toContain("latitude");
      expect(JSON.stringify(companiesResponse.body)).not.toContain("summary");
    });

    it("rejects non-super-admin platform reports", async () => {
      const companyAdminToken = await login("companyadmin@example.test");

      await request(app).get("/api/super-admin/reports/dashboard").set("Authorization", `Bearer ${companyAdminToken}`).expect(403);
      await request(app).get("/api/super-admin/reports/companies").set("Authorization", `Bearer ${companyAdminToken}`).expect(403);
    });
  });
});
