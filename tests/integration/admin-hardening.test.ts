import type {
  AuditActionCategory,
  CompanyStatus,
  DeviceSessionStatus,
  EmployeeStatus,
  GeofenceStatus,
  LeaveRequestStatus,
  LeaveTypeStatus,
  OKRApprovalStatus,
  OKRStatus,
  PaymentStatus,
  PerformanceReviewStatus,
  ReviewCycleStatus,
  SubscriptionPlanType,
  SubscriptionStatus,
  UserStatus
} from "@prisma/client";
import { readFileSync } from "fs";
import path from "path";
import request from "supertest";

import { app } from "../../src/app";
import type { AuditLogInput, AuditRepository } from "../../src/lib/audit";
import { resetAuditRepositoryForTests, setAuditRepositoryForTests } from "../../src/lib/audit";
import { hashPassword } from "../../src/lib/password";
import type { AttendanceRepository } from "../../src/modules/attendance/attendance.repository";
import { resetAttendanceRepositoryForTests, setAttendanceRepositoryForTests } from "../../src/modules/attendance/attendance.repository";
import type { AuthDeviceSessionRecord, AuthRepository, AuthUserRecord } from "../../src/modules/auth/auth.repository";
import { resetAuthRepositoryForTests, setAuthRepositoryForTests } from "../../src/modules/auth/auth.repository";
import type {
  CreateEmployeeRepositoryInput,
  EmployeeRecord,
  EmployeesRepository,
  UpdateEmployeeRepositoryInput
} from "../../src/modules/employees/employees.repository";
import { resetEmployeesRepositoryForTests, setEmployeesRepositoryForTests } from "../../src/modules/employees/employees.repository";
import type { GeofencesRepository } from "../../src/modules/geofences/geofences.repository";
import { resetGeofencesRepositoryForTests, setGeofencesRepositoryForTests } from "../../src/modules/geofences/geofences.repository";
import type { LeaveRepository, LeaveRequestRecord } from "../../src/modules/leave/leave.repository";
import { resetLeaveRepositoryForTests, setLeaveRepositoryForTests } from "../../src/modules/leave/leave.repository";
import type { OkrRecord, OkrsRepository } from "../../src/modules/okrs/okrs.repository";
import { resetOkrsRepositoryForTests, setOkrsRepositoryForTests } from "../../src/modules/okrs/okrs.repository";
import type {
  PerformanceReviewRecord,
  PerformanceReviewsRepository,
  ReviewCycleRecord
} from "../../src/modules/performance-reviews/reviews.repository";
import {
  resetPerformanceReviewsRepositoryForTests,
  setPerformanceReviewsRepositoryForTests
} from "../../src/modules/performance-reviews/reviews.repository";
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
  ReportEmployeeRecord,
  ReportScope,
  ReportsRepository
} from "../../src/modules/reports/reports.repository";
import { resetReportsRepositoryForTests, setReportsRepositoryForTests } from "../../src/modules/reports/reports.repository";
import type {
  BillingCompanyRecord,
  CompanySubscriptionRecord,
  CreatePaymentRecordRepositoryInput,
  PaymentRecordRecord,
  SubscriptionPlanRecord,
  SubscriptionsRepository
} from "../../src/modules/subscriptions/subscriptions.repository";
import {
  resetSubscriptionsRepositoryForTests,
  setSubscriptionsRepositoryForTests
} from "../../src/modules/subscriptions/subscriptions.repository";
import type { Role } from "../../src/types/auth";

interface MemoryState {
  companies: Map<string, BillingCompanyRecord>;
  users: Map<string, AuthUserRecord>;
  sessions: Map<string, AuthDeviceSessionRecord>;
  employees: Map<string, EmployeeRecord>;
  audits: AuditLogInput[];
  payments: Map<string, PaymentRecordRecord>;
  counters: Record<string, number>;
  sensitiveMarkers: string[];
}

const now = () => new Date("2026-06-04T08:00:00.000Z");
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

const makeEmployeeRecord = (
  id: string,
  companyId: string,
  user: AuthUserRecord,
  managerId: string | null = null
): EmployeeRecord => ({
  id,
  companyId,
  userId: user.id,
  departmentId: null,
  designationId: null,
  managerId,
  employeeCode: id.toUpperCase(),
  firstName: id,
  lastName: "User",
  phone: null,
  status: "ACTIVE" as EmployeeStatus,
  hireDate: null,
  createdAt: now(),
  updatedAt: now(),
  user: {
    id: user.id,
    email: user.email,
    companyId: user.companyId,
    status: user.status,
    roles: user.roles
  },
  department: null,
  designation: null,
  manager: managerId
    ? {
        id: managerId,
        employeeCode: "MANAGER",
        firstName: "Manager",
        lastName: "User"
      }
    : null
});

const reportEmployeeFromEmployee = (employee: EmployeeRecord): ReportEmployeeRecord => ({
  id: employee.id,
  companyId: employee.companyId,
  userId: employee.userId,
  departmentId: employee.departmentId,
  managerId: employee.managerId,
  status: employee.status,
  companyStatus: "ACTIVE" as CompanyStatus
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
  const userMap = new Map(users.map((user) => [user.id, user]));
  const employees = [
    makeEmployeeRecord("employee-company-admin", "company-1", userMap.get("user-company-admin")!),
    makeEmployeeRecord("employee-hr-admin", "company-1", userMap.get("user-hr-admin")!),
    makeEmployeeRecord("employee-manager", "company-1", userMap.get("user-manager")!),
    makeEmployeeRecord("employee-self", "company-1", userMap.get("user-employee")!, "employee-manager"),
    makeEmployeeRecord("employee-other", "company-1", userMap.get("user-other-employee")!),
    makeEmployeeRecord("employee-company2", "company-2", userMap.get("user-company2-employee")!)
  ];

  return {
    companies: new Map([
      ["company-1", { id: "company-1", name: "Demo Company", status: "ACTIVE" as CompanyStatus }],
      ["company-2", { id: "company-2", name: "Other Company", status: "ACTIVE" as CompanyStatus }]
    ]),
    users: userMap,
    sessions: new Map(),
    employees: new Map(employees.map((employee) => [employee.id, employee])),
    audits: [],
    payments: new Map(),
    counters: { session: 0, employee: 0, payment: 0 },
    sensitiveMarkers: [
      "gps-secret-marker",
      "face-secret-marker",
      "leave-reason-secret",
      "review-summary-secret",
      "okr-note-secret",
      "receipt-secret"
    ]
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

  const employeesRepository: EmployeesRepository = {
    async findCompanyById(companyId) {
      return state.companies.has(companyId) ? { id: companyId } : null;
    },

    async findUserByEmail(email) {
      const user = Array.from(state.users.values()).find((candidate) => candidate.email === email);
      return user ? { id: user.id, email: user.email, companyId: user.companyId } : null;
    },

    async findDepartmentByIdInCompany() {
      return null;
    },

    async findDesignationByIdInCompany() {
      return null;
    },

    async findEmployeeCodeInCompany(employeeCode, companyId) {
      return Array.from(state.employees.values()).find((employee) => employee.companyId === companyId && employee.employeeCode === employeeCode) ?? null;
    },

    async findByIdInCompany(employeeId, companyId) {
      const employee = state.employees.get(employeeId);
      return employee?.companyId === companyId ? employee : null;
    },

    async findByUserId(userId) {
      return Array.from(state.employees.values()).find((employee) => employee.userId === userId) ?? null;
    },

    async list(companyId) {
      return Array.from(state.employees.values()).filter((employee) => employee.companyId === companyId);
    },

    async create(input: CreateEmployeeRepositoryInput) {
      state.counters.employee += 1;
      const user = makeUser(`created-user-${state.counters.employee}`, input.email, input.companyId, input.roles as Role[], input.passwordHash);
      const employee = makeEmployeeRecord(`created-employee-${state.counters.employee}`, input.companyId, user, input.managerId ?? null);

      state.users.set(user.id, user);
      state.employees.set(employee.id, {
        ...employee,
        employeeCode: input.employeeCode,
        firstName: input.firstName,
        lastName: input.lastName,
        phone: input.phone ?? null,
        departmentId: input.departmentId ?? null,
        designationId: input.designationId ?? null,
        hireDate: input.hireDate ?? null
      });

      return state.employees.get(employee.id)!;
    },

    async update(employeeId, companyId, input: UpdateEmployeeRepositoryInput) {
      const employee = state.employees.get(employeeId)!;
      const updated = { ...employee, ...input, companyId, updatedAt: now() };
      state.employees.set(employeeId, updated);
      return updated;
    },

    async updateStatus(employeeId, companyId, status, userStatus) {
      const employee = state.employees.get(employeeId)!;
      const updated = {
        ...employee,
        companyId,
        status,
        user: { ...employee.user, status: userStatus },
        updatedAt: now()
      };
      state.employees.set(employeeId, updated);
      return updated;
    },

    async updateManager(employeeId, companyId, managerId) {
      const employee = state.employees.get(employeeId)!;
      const updated = { ...employee, companyId, managerId, updatedAt: now() };
      state.employees.set(employeeId, updated);
      return updated;
    }
  };

  const geofencesRepository: GeofencesRepository = {
    async findCompanyById(companyId) {
      return state.companies.has(companyId) ? { id: companyId } : null;
    },
    async create() {
      throw new Error("Unexpected geofence create");
    },
    async list() {
      return [];
    },
    async listActive() {
      return [];
    },
    async findByIdInCompany() {
      return null;
    },
    async findByNameInCompany() {
      return null;
    },
    async update() {
      throw new Error("Unexpected geofence update");
    },
    async updateStatus() {
      throw new Error("Unexpected geofence status update");
    }
  };

  const attendanceRepository: AttendanceRepository = {
    async findEmployeeProfileByUserId(userId) {
      const employee = Array.from(state.employees.values()).find((record) => record.userId === userId);
      return employee ? { ...reportEmployeeFromEmployee(employee), companyStatus: "ACTIVE" as CompanyStatus } : null;
    },
    async verifyEmployeeBelongsToCompany(employeeId, companyId) {
      return state.employees.get(employeeId)?.companyId === companyId;
    },
    async findOpenSessionByEmployeeId() {
      return null;
    },
    async findActiveGeofencesForCompany() {
      return [];
    },
    async createClockInSession() {
      throw new Error("Unexpected clock-in");
    },
    async closeAttendanceSession() {
      throw new Error("Unexpected clock-out");
    },
    async createAttendanceEvent() {
      throw new Error("Unexpected attendance event");
    },
    async listMyAttendance() {
      return [];
    },
    async listCompanyAttendance() {
      return [];
    }
  };

  const leaveRequest: LeaveRequestRecord = {
    id: "leave-nondirect",
    companyId: "company-1",
    employeeId: "employee-other",
    leaveTypeId: "leave-type-1",
    startDate: dateOnly("2026-06-10"),
    endDate: dateOnly("2026-06-10"),
    reason: "leave-reason-secret",
    status: "PENDING" as LeaveRequestStatus,
    reviewedById: null,
    reviewedAt: null,
    reviewComment: null,
    createdAt: now(),
    updatedAt: now(),
    leaveType: {
      id: "leave-type-1",
      companyId: "company-1",
      name: "Annual",
      status: "ACTIVE" as LeaveTypeStatus,
      defaultAnnualAllowance: 20,
      createdAt: now(),
      updatedAt: now()
    },
    employee: {
      id: "employee-other",
      companyId: "company-1",
      userId: "user-other-employee",
      managerId: null,
      status: "ACTIVE" as EmployeeStatus,
      companyStatus: "ACTIVE" as CompanyStatus
    }
  };

  const leaveRepository: LeaveRepository = {
    async findCompanyById(companyId) {
      return state.companies.has(companyId) ? { id: companyId } : null;
    },
    async findEmployeeByIdInCompany(employeeId, companyId) {
      const employee = state.employees.get(employeeId);
      return employee?.companyId === companyId ? reportEmployeeFromEmployee(employee) : null;
    },
    async findEmployeeByUserId(userId) {
      const employee = Array.from(state.employees.values()).find((record) => record.userId === userId);
      return employee ? reportEmployeeFromEmployee(employee) : null;
    },
    async createLeaveType() {
      throw new Error("Unexpected leave type create");
    },
    async listLeaveTypes() {
      return [];
    },
    async findLeaveTypeByIdInCompany() {
      return null;
    },
    async findLeaveTypeByNameInCompany() {
      return null;
    },
    async updateLeaveType() {
      throw new Error("Unexpected leave type update");
    },
    async updateLeaveTypeStatus() {
      throw new Error("Unexpected leave type status update");
    },
    async upsertEntitlement() {
      throw new Error("Unexpected entitlement upsert");
    },
    async listEntitlements() {
      return [];
    },
    async findEntitlementByIdInCompany() {
      return null;
    },
    async findEntitlementByEmployeeTypeYear() {
      return null;
    },
    async updateEntitlement() {
      throw new Error("Unexpected entitlement update");
    },
    async createLeaveRequest() {
      throw new Error("Unexpected leave request create");
    },
    async findLeaveRequestByIdInCompany(leaveRequestId, companyId) {
      return leaveRequestId === leaveRequest.id && companyId === leaveRequest.companyId ? leaveRequest : null;
    },
    async listLeaveRequestsForEmployee() {
      return [];
    },
    async listLeaveRequestsForDirectReports() {
      return [];
    },
    async listLeaveRequestsForCompany() {
      return [];
    },
    async findOverlappingLeaveRequest() {
      return null;
    },
    async updateLeaveRequestReview() {
      throw new Error("Unexpected leave review");
    },
    async incrementEntitlementUsedDays() {
      throw new Error("Unexpected entitlement increment");
    }
  };

  const okr: OkrRecord = {
    id: "okr-nondirect",
    companyId: "company-1",
    employeeId: "employee-other",
    assignedById: "employee-manager",
    title: "Safe response title",
    description: "okr-note-secret",
    status: "ASSIGNED" as OKRStatus,
    dueDate: null,
    createdAt: now(),
    updatedAt: now(),
    employee: {
      id: "employee-other",
      companyId: "company-1",
      userId: "user-other-employee",
      managerId: null,
      status: "ACTIVE" as EmployeeStatus,
      companyStatus: "ACTIVE" as CompanyStatus
    },
    progressUpdates: [
      {
        id: "progress-1",
        companyId: "company-1",
        okrId: "okr-nondirect",
        employeeId: "employee-other",
        progressPercent: 10,
        note: "okr-note-secret",
        createdAt: now()
      }
    ],
    approvals: []
  };

  const okrsRepository: OkrsRepository = {
    async findCompanyById(companyId) {
      return state.companies.has(companyId) ? { id: companyId } : null;
    },
    async findEmployeeByIdInCompany(employeeId, companyId) {
      const employee = state.employees.get(employeeId);
      return employee?.companyId === companyId ? reportEmployeeFromEmployee(employee) : null;
    },
    async findEmployeeByUserId(userId) {
      const employee = Array.from(state.employees.values()).find((record) => record.userId === userId);
      return employee ? reportEmployeeFromEmployee(employee) : null;
    },
    async createOkr() {
      throw new Error("Unexpected OKR create");
    },
    async findOkrByIdInCompany(okrId, companyId) {
      return okrId === okr.id && companyId === okr.companyId ? okr : null;
    },
    async listOkrsForEmployee() {
      return [];
    },
    async listOkrsForDirectReports() {
      return [];
    },
    async listOkrsForCompany() {
      return [];
    },
    async updateOkr() {
      throw new Error("Unexpected OKR update");
    },
    async updateOkrStatus() {
      throw new Error("Unexpected OKR status update");
    },
    async createProgressUpdate() {
      throw new Error("Unexpected progress update");
    },
    async upsertApproval() {
      throw new Error("Unexpected OKR approval");
    },
    async listApprovalsForOkr() {
      return [];
    }
  };

  const reviewCycle: ReviewCycleRecord = {
    id: "cycle-1",
    companyId: "company-1",
    name: "Q2",
    startDate: dateOnly("2026-04-01"),
    endDate: dateOnly("2026-06-30"),
    status: "ACTIVE" as ReviewCycleStatus,
    createdAt: now(),
    updatedAt: now()
  };
  const review: PerformanceReviewRecord = {
    id: "review-nondirect",
    companyId: "company-1",
    reviewCycleId: reviewCycle.id,
    employeeId: "employee-other",
    managerId: "employee-company-admin",
    summary: "review-summary-secret",
    rating: 4,
    status: "SUBMITTED" as PerformanceReviewStatus,
    submittedAt: now(),
    createdAt: now(),
    updatedAt: now(),
    reviewCycle,
    employee: {
      id: "employee-other",
      companyId: "company-1",
      userId: "user-other-employee",
      managerId: null,
      status: "ACTIVE" as EmployeeStatus,
      companyStatus: "ACTIVE" as CompanyStatus
    }
  };

  const reviewsRepository: PerformanceReviewsRepository = {
    async findCompanyById(companyId) {
      return state.companies.has(companyId) ? { id: companyId } : null;
    },
    async findEmployeeByIdInCompany(employeeId, companyId) {
      const employee = state.employees.get(employeeId);
      return employee?.companyId === companyId ? reportEmployeeFromEmployee(employee) : null;
    },
    async findEmployeeByUserId(userId) {
      const employee = Array.from(state.employees.values()).find((record) => record.userId === userId);
      return employee ? reportEmployeeFromEmployee(employee) : null;
    },
    async findReviewCycleByNameInCompany() {
      return null;
    },
    async createReviewCycle() {
      throw new Error("Unexpected review cycle create");
    },
    async listReviewCyclesForCompany() {
      return [];
    },
    async findReviewCycleByIdInCompany(reviewCycleId, companyId) {
      return reviewCycleId === reviewCycle.id && companyId === reviewCycle.companyId ? reviewCycle : null;
    },
    async updateReviewCycle() {
      throw new Error("Unexpected review cycle update");
    },
    async updateReviewCycleStatus() {
      throw new Error("Unexpected review cycle status update");
    },
    async findPerformanceReviewByEmployeeCycle() {
      return null;
    },
    async createPerformanceReview() {
      throw new Error("Unexpected performance review create");
    },
    async listReviewsForEmployee() {
      return [];
    },
    async listReviewsForDirectReports() {
      return [];
    },
    async listReviewsForCompany() {
      return [];
    },
    async findPerformanceReviewByIdInCompany(reviewId, companyId) {
      return reviewId === review.id && companyId === review.companyId ? review : null;
    },
    async updatePerformanceReview() {
      throw new Error("Unexpected review update");
    },
    async updatePerformanceReviewStatus() {
      throw new Error("Unexpected review status update");
    }
  };

  const reportsRepository: ReportsRepository = {
    async findCompanyById(companyId) {
      return state.companies.has(companyId) ? { id: companyId } : null;
    },
    async findEmployeeByUserId(userId) {
      const employee = Array.from(state.employees.values()).find((record) => record.userId === userId);
      return employee ? reportEmployeeFromEmployee(employee) : null;
    },
    async findEmployeeByIdInCompany(employeeId, companyId) {
      const employee = state.employees.get(employeeId);
      return employee?.companyId === companyId ? reportEmployeeFromEmployee(employee) : null;
    },
    async findDepartmentByIdInCompany() {
      return null;
    },
    async findReviewCycleByIdInCompany() {
      return null;
    },
    async listDirectReportIds(managerId) {
      return Array.from(state.employees.values())
        .filter((employee) => employee.managerId === managerId)
        .map((employee) => employee.id);
    },
    async getDashboardSummary(scope: ReportScope): Promise<CompanyDashboardSummary> {
      return {
        companyId: scope.companyId,
        employees: { total: 2, active: 2, inactive: 0 },
        departments: { total: 0 },
        attendance: { todayClockIns: 1, openSessions: 0 },
        leave: { pendingRequests: 1 },
        okrs: { active: 1 },
        performance: { pendingReviews: 1 },
        notifications: { unreadCount: 0 }
      };
    },
    async getAttendanceSummary(): Promise<AttendanceReportSummary> {
      return { totalSessions: 1, openSessions: 0, closedSessions: 1, clockInsByDay: [{ date: "2026-06-04", count: 1 }] };
    },
    async getLeaveSummary(): Promise<LeaveReportSummary> {
      return {
        totalRequests: 1,
        pendingRequests: 1,
        approvedRequests: 0,
        rejectedRequests: 0,
        leaveUsageByType: [],
        lowRemainingLeave: []
      };
    },
    async getOkrSummary(): Promise<OkrReportSummary> {
      return {
        totalOkrs: 1,
        statusCounts: {
          DRAFT: 0,
          ASSIGNED: 1,
          IN_PROGRESS: 0,
          SUBMITTED: 0,
          APPROVED: 0,
          REJECTED: 0,
          ARCHIVED: 0
        },
        activeCount: 1,
        completedCount: 0,
        averageProgressPercent: 10,
        overdueCount: 0
      };
    },
    async getPerformanceSummary(): Promise<PerformanceReportSummary> {
      return {
        totalReviews: 1,
        statusCounts: { DRAFT: 0, SUBMITTED: 1, ACKNOWLEDGED: 0, ARCHIVED: 0 },
        pendingReviews: 0,
        submittedReviews: 1,
        finalizedReviews: 0,
        averageRating: 4,
        reviewsByCycle: []
      };
    },
    async getEmployeeDashboard(): Promise<EmployeeDashboardSummary> {
      throw new Error("Unexpected employee dashboard");
    },
    async getPlatformDashboard(): Promise<PlatformDashboardSummary> {
      return {
        totalCompanies: 2,
        activeCompanies: 2,
        inactiveCompanies: 0,
        totalUsers: state.users.size,
        activeUsers: state.users.size,
        totalSubscriptions: 0,
        recentCompanyCount: 0
      };
    },
    async getCompanyRollups(): Promise<CompanyRollupSummary[]> {
      return [];
    }
  };

  const subscriptionsRepository: SubscriptionsRepository = {
    async findCompanyById(companyId) {
      return state.companies.get(companyId) ?? null;
    },
    async createPlan() {
      throw new Error("Unexpected plan create");
    },
    async listPlans() {
      return [];
    },
    async findPlanById() {
      return null;
    },
    async findPlanByName() {
      return null;
    },
    async updatePlan() {
      throw new Error("Unexpected plan update");
    },
    async updatePlanStatus() {
      throw new Error("Unexpected plan status update");
    },
    async createCompanySubscription() {
      throw new Error("Unexpected subscription create");
    },
    async listSubscriptions() {
      return [];
    },
    async findSubscriptionById() {
      return null;
    },
    async findActiveSubscriptionForCompany() {
      return null;
    },
    async findCurrentOrLatestSubscriptionForCompany() {
      return null;
    },
    async updateSubscriptionStatus() {
      throw new Error("Unexpected subscription status update");
    },
    async createPaymentRecord(input: CreatePaymentRecordRepositoryInput) {
      state.counters.payment += 1;
      const paymentRecord: PaymentRecordRecord = {
        id: `payment-${state.counters.payment}`,
        companyId: input.companyId,
        subscriptionId: input.subscriptionId ?? null,
        amount: input.amount,
        currency: input.currency,
        status: input.status,
        provider: input.provider ?? null,
        providerReference: input.providerReference ?? null,
        paidAt: input.paidAt ?? null,
        createdAt: now(),
        updatedAt: now()
      };

      state.payments.set(paymentRecord.id, paymentRecord);
      return paymentRecord;
    },
    async listPaymentRecords() {
      return [];
    }
  };

  const auditRepository: AuditRepository = {
    async create(input) {
      state.audits.push(input);
    }
  };

  return {
    authRepository,
    employeesRepository,
    geofencesRepository,
    attendanceRepository,
    leaveRepository,
    okrsRepository,
    reviewsRepository,
    reportsRepository,
    subscriptionsRepository,
    auditRepository
  };
};

describe("CP16 admin and super-admin hardening", () => {
  let passwordHash: string;
  let state: MemoryState;

  beforeAll(async () => {
    passwordHash = await hashPassword("Password123!");
  });

  beforeEach(() => {
    state = createState(passwordHash);
    const repositories = createRepositories(state);

    setAuthRepositoryForTests(repositories.authRepository);
    setEmployeesRepositoryForTests(repositories.employeesRepository);
    setGeofencesRepositoryForTests(repositories.geofencesRepository);
    setAttendanceRepositoryForTests(repositories.attendanceRepository);
    setLeaveRepositoryForTests(repositories.leaveRepository);
    setOkrsRepositoryForTests(repositories.okrsRepository);
    setPerformanceReviewsRepositoryForTests(repositories.reviewsRepository);
    setReportsRepositoryForTests(repositories.reportsRepository);
    setSubscriptionsRepositoryForTests(repositories.subscriptionsRepository);
    setAuditRepositoryForTests(repositories.auditRepository);
  });

  afterEach(() => {
    resetAuthRepositoryForTests();
    resetEmployeesRepositoryForTests();
    resetGeofencesRepositoryForTests();
    resetAttendanceRepositoryForTests();
    resetLeaveRepositoryForTests();
    resetOkrsRepositoryForTests();
    resetPerformanceReviewsRepositoryForTests();
    resetReportsRepositoryForTests();
    resetSubscriptionsRepositoryForTests();
    resetAuditRepositoryForTests();
  });

  const login = async (email: string) => {
    const response = await request(app).post("/api/auth/login").send({ email, password: "Password123!" }).expect(200);

    return response.body.data.accessToken as string;
  };

  const auditActions = (category?: AuditActionCategory) =>
    state.audits.filter((audit) => !category || audit.category === category).map((audit) => audit.action);

  it("keeps admin and super-admin routes behind authentication and the correct roles", async () => {
    const superAdminToken = await login("superadmin@example.test");
    const companyAdminToken = await login("companyadmin@example.test");
    const hrAdminToken = await login("hradmin@example.test");
    const managerToken = await login("manager@example.test");
    const employeeToken = await login("employee@example.test");

    await request(app).get("/api/admin/employees").expect(401);
    await request(app).get("/api/admin/employees").set("Authorization", `Bearer ${employeeToken}`).expect(403);
    await request(app).get("/api/admin/employees").set("Authorization", `Bearer ${managerToken}`).expect(403);
    await request(app).get("/api/admin/geofences").set("Authorization", `Bearer ${managerToken}`).expect(403);
    await request(app).get("/api/super-admin/plans").set("Authorization", `Bearer ${hrAdminToken}`).expect(403);
    await request(app).get("/api/super-admin/plans").set("Authorization", `Bearer ${companyAdminToken}`).expect(403);
    await request(app).get("/api/super-admin/plans").set("Authorization", `Bearer ${superAdminToken}`).expect(200);
    await request(app).get("/api/admin/employees").set("Authorization", `Bearer ${companyAdminToken}`).expect(200);
    await request(app).get("/api/admin/employees").set("Authorization", `Bearer ${hrAdminToken}`).expect(200);
  });

  it("blocks non-super-admin companyId overrides across representative admin modules", async () => {
    const companyAdminToken = await login("companyadmin@example.test");
    const hrAdminToken = await login("hradmin@example.test");

    await request(app)
      .get("/api/admin/employees/employee-company2?companyId=company-2")
      .set("Authorization", `Bearer ${companyAdminToken}`)
      .expect(403);
    await request(app)
      .get("/api/admin/geofences/geofence-company2?companyId=company-2")
      .set("Authorization", `Bearer ${companyAdminToken}`)
      .expect(403);
    await request(app)
      .get("/api/admin/attendance?companyId=company-2")
      .set("Authorization", `Bearer ${companyAdminToken}`)
      .expect(403);
    await request(app)
      .get("/api/admin/reports/attendance?companyId=company-2")
      .set("Authorization", `Bearer ${companyAdminToken}`)
      .expect(403);
    await request(app)
      .get("/api/admin/leave-requests?companyId=company-2")
      .set("Authorization", `Bearer ${hrAdminToken}`)
      .expect(403);
    await request(app).get("/api/admin/okrs?companyId=company-2").set("Authorization", `Bearer ${hrAdminToken}`).expect(403);
    await request(app).get("/api/admin/reviews?companyId=company-2").set("Authorization", `Bearer ${hrAdminToken}`).expect(403);
    await request(app).get("/api/admin/subscription?companyId=company-2").set("Authorization", `Bearer ${companyAdminToken}`).expect(403);
    await request(app).get("/api/admin/payment-records?companyId=company-2").set("Authorization", `Bearer ${hrAdminToken}`).expect(403);
  });

  it("enforces manager direct-report boundaries and employee self-access boundaries", async () => {
    const managerToken = await login("manager@example.test");
    const employeeToken = await login("employee@example.test");

    await request(app)
      .patch("/api/leave/leave-nondirect/approve")
      .set("Authorization", `Bearer ${managerToken}`)
      .send({})
      .expect(403);
    await request(app).get("/api/okrs/okr-nondirect").set("Authorization", `Bearer ${managerToken}`).expect(403);
    await request(app).get("/api/reviews/review-nondirect").set("Authorization", `Bearer ${managerToken}`).expect(403);
    await request(app)
      .get("/api/reports/team/attendance?employeeId=employee-other")
      .set("Authorization", `Bearer ${managerToken}`)
      .expect(403);
    await request(app).get("/api/leave/team").set("Authorization", `Bearer ${employeeToken}`).expect(403);
    await request(app)
      .post("/api/okrs/okr-nondirect/progress")
      .set("Authorization", `Bearer ${employeeToken}`)
      .send({ progressPercent: 25, note: "employee should not update another employee" })
      .expect(403);
    await request(app)
      .post("/api/reviews/employee-other/manager-review")
      .set("Authorization", `Bearer ${employeeToken}`)
      .send({ reviewCycleId: "cycle-1", summary: "not allowed" })
      .expect(403);
  });

  it("prevents normal admin employee creation from assigning SUPER_ADMIN and keeps employee responses free of password hashes", async () => {
    const companyAdminToken = await login("companyadmin@example.test");

    await request(app)
      .post("/api/admin/employees")
      .set("Authorization", `Bearer ${companyAdminToken}`)
      .send({
        email: "not-super@example.test",
        temporaryPassword: "Password123!",
        firstName: "No",
        lastName: "Super",
        employeeCode: "NOSUPER",
        role: "SUPER_ADMIN"
      })
      .expect(403);

    const createResponse = await request(app)
      .post("/api/admin/employees")
      .set("Authorization", `Bearer ${companyAdminToken}`)
      .send({
        email: "created@example.test",
        temporaryPassword: "Password123!",
        firstName: "Created",
        lastName: "Employee",
        employeeCode: "CREATED",
        role: "EMPLOYEE"
      })
      .expect(201);
    const listResponse = await request(app).get("/api/admin/employees").set("Authorization", `Bearer ${companyAdminToken}`).expect(200);
    const detailResponse = await request(app)
      .get(`/api/admin/employees/${createResponse.body.data.employee.id}`)
      .set("Authorization", `Bearer ${companyAdminToken}`)
      .expect(200);
    const meResponse = await request(app).get("/api/auth/me").set("Authorization", `Bearer ${companyAdminToken}`).expect(200);

    expect(JSON.stringify(createResponse.body)).not.toContain("passwordHash");
    expect(JSON.stringify(listResponse.body)).not.toContain("passwordHash");
    expect(JSON.stringify(detailResponse.body)).not.toContain("passwordHash");
    expect(JSON.stringify(meResponse.body)).not.toContain("passwordHash");
    expect(auditActions("EMPLOYEE")).toContain("EMPLOYEE_CREATED");
  });

  it("keeps report responses aggregated and payment audit metadata sanitized", async () => {
    const companyAdminToken = await login("companyadmin@example.test");
    const superAdminToken = await login("superadmin@example.test");

    const reportResponse = await request(app)
      .get("/api/admin/reports/dashboard")
      .set("Authorization", `Bearer ${companyAdminToken}`)
      .expect(200);
    const paymentResponse = await request(app)
      .post("/api/super-admin/payment-records")
      .set("Authorization", `Bearer ${superAdminToken}`)
      .send({
        companyId: "company-1",
        amount: 5000,
        currency: "ETB",
        status: "PAID" as PaymentStatus,
        provider: "manual",
        providerReference: "receipt-secret",
        paidAt: "2026-06-01T12:00:00.000Z"
      })
      .expect(201);

    for (const marker of state.sensitiveMarkers.filter((marker) => marker !== "receipt-secret")) {
      expect(JSON.stringify(reportResponse.body)).not.toContain(marker);
    }

    expect(paymentResponse.body.data.paymentRecord.providerReference).toBe("receipt-secret");
    expect(auditActions("PAYMENT")).toEqual(["PAYMENT_RECORD_CREATED"]);
    expect(JSON.stringify(state.audits)).not.toContain("receipt-secret");
  });

  it("keeps health/readiness public and disables internal verification routes in production", async () => {
    await request(app).get("/health").expect(200);
    await request(app).get("/ready").expect(200);

    const previousNodeEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = "production";

    try {
      await request(app).get("/api/system/auth-check").expect(404);
      await request(app).get("/api/system/role-check/super-admin").expect(404);
      await request(app).get("/health").expect(200);
    } finally {
      process.env.NODE_ENV = previousNodeEnv;
    }
  });

  it("keeps seed and environment examples development-only and free of real secrets", () => {
    const envExample = readFileSync(path.join(process.cwd(), ".env.example"), "utf8");
    const readme = readFileSync(path.join(process.cwd(), "README.md"), "utf8");

    expect(envExample).toContain("replace-with-development-access-secret");
    expect(envExample).toContain("replace-with-development-refresh-secret");
    expect(envExample).not.toContain("sk_live");
    expect(envExample).not.toContain("AKIA");
    expect(envExample).not.toContain("BEGIN PRIVATE KEY");
    expect(readme).toContain("do not use these as production credentials");
  });
});
