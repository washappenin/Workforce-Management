import type {
  CompanyStatus,
  EmployeeStatus,
  LeaveRequestStatus,
  OKRStatus,
  PerformanceReviewStatus,
  Prisma,
  SubscriptionStatus,
  UserStatus
} from "@prisma/client";

import { getPrismaClient } from "../../lib/prisma";

export interface ReportCompanyRecord {
  id: string;
}

export interface ReportEmployeeRecord {
  id: string;
  companyId: string;
  userId: string;
  departmentId: string | null;
  managerId: string | null;
  status: EmployeeStatus;
  companyStatus: CompanyStatus;
}

export interface ReportScope {
  companyId: string;
  employeeIds?: string[];
}

export interface AttendanceReportFilters {
  from?: Date;
  to?: Date;
  employeeId?: string;
  departmentId?: string;
}

export interface LeaveReportFilters {
  year?: number;
  employeeId?: string;
  departmentId?: string;
  status?: LeaveRequestStatus;
}

export interface OkrReportFilters {
  employeeId?: string;
  departmentId?: string;
  status?: OKRStatus;
}

export interface PerformanceReportFilters {
  reviewCycleId?: string;
  employeeId?: string;
  departmentId?: string;
  status?: PerformanceReviewStatus;
}

export interface CompanyDashboardSummary {
  companyId: string;
  employees: {
    total: number;
    active: number;
    inactive: number;
  };
  departments: {
    total: number;
  };
  attendance: {
    todayClockIns: number;
    openSessions: number;
  };
  leave: {
    pendingRequests: number;
  };
  okrs: {
    active: number;
  };
  performance: {
    pendingReviews: number;
  };
  notifications: {
    unreadCount: number;
  };
}

export interface AttendanceReportSummary {
  totalSessions: number;
  openSessions: number;
  closedSessions: number;
  clockInsByDay: Array<{ date: string; count: number }>;
}

export interface LeaveReportSummary {
  totalRequests: number;
  pendingRequests: number;
  approvedRequests: number;
  rejectedRequests: number;
  leaveUsageByType: Array<{ leaveTypeId: string; leaveTypeName: string; usedDays: number; totalDays: number }>;
  lowRemainingLeave: Array<{ employeeId: string; leaveTypeId: string; leaveTypeName: string; remainingDays: number }>;
}

export interface OkrReportSummary {
  totalOkrs: number;
  statusCounts: Record<OKRStatus, number>;
  activeCount: number;
  completedCount: number;
  averageProgressPercent: number | null;
  overdueCount: number;
}

export interface PerformanceReportSummary {
  totalReviews: number;
  statusCounts: Record<PerformanceReviewStatus, number>;
  pendingReviews: number;
  submittedReviews: number;
  finalizedReviews: number;
  averageRating: number | null;
  reviewsByCycle: Array<{ reviewCycleId: string; reviewCycleName: string; count: number }>;
}

export interface EmployeeDashboardSummary {
  employeeId: string;
  companyId: string;
  attendance: {
    todayStatus: "CLOCKED_IN" | "CLOCKED_OUT" | "NOT_CLOCKED_IN";
    openSession: { id: string; clockInAt: Date; status: string } | null;
  };
  shift: {
    currentAssignments: Array<{
      assignmentId: string;
      shiftId: string;
      name: string;
      startTime: string;
      endTime: string;
      startsOn: Date;
      endsOn: Date | null;
    }>;
  };
  leave: {
    pendingRequestsCount: number;
    balances: Array<{ leaveTypeId: string; leaveTypeName: string; year: number; totalDays: number; usedDays: number; remainingDays: number }>;
  };
  okrs: {
    activeCount: number;
  };
  performance: {
    latestReview: { id: string; reviewCycleId: string; status: PerformanceReviewStatus; rating: number | null; submittedAt: Date | null; createdAt: Date } | null;
  };
  notifications: {
    unreadCount: number;
  };
}

export interface PlatformDashboardSummary {
  totalCompanies: number;
  activeCompanies: number;
  inactiveCompanies: number;
  totalUsers: number;
  activeUsers: number;
  totalSubscriptions: number;
  recentCompanyCount: number;
}

export interface CompanyRollupSummary {
  companyId: string;
  name: string;
  status: CompanyStatus;
  employeeCount: number;
  activeEmployeeCount: number;
  subscriptionStatus: SubscriptionStatus | null;
  createdAt: Date;
}

export interface ReportsRepository {
  findCompanyById(companyId: string): Promise<ReportCompanyRecord | null>;
  findEmployeeByUserId(userId: string): Promise<ReportEmployeeRecord | null>;
  findEmployeeByIdInCompany(employeeId: string, companyId: string): Promise<ReportEmployeeRecord | null>;
  findDepartmentByIdInCompany(departmentId: string, companyId: string): Promise<{ id: string } | null>;
  findReviewCycleByIdInCompany(reviewCycleId: string, companyId: string): Promise<{ id: string } | null>;
  listDirectReportIds(managerId: string, companyId: string): Promise<string[]>;
  getDashboardSummary(scope: ReportScope, actorUserId: string, todayStart: Date, todayEnd: Date): Promise<CompanyDashboardSummary>;
  getAttendanceSummary(scope: ReportScope, filters: AttendanceReportFilters): Promise<AttendanceReportSummary>;
  getLeaveSummary(scope: ReportScope, filters: LeaveReportFilters): Promise<LeaveReportSummary>;
  getOkrSummary(scope: ReportScope, filters: OkrReportFilters, now: Date): Promise<OkrReportSummary>;
  getPerformanceSummary(scope: ReportScope, filters: PerformanceReportFilters): Promise<PerformanceReportSummary>;
  getEmployeeDashboard(employee: ReportEmployeeRecord, todayStart: Date, todayEnd: Date, year: number): Promise<EmployeeDashboardSummary>;
  getPlatformDashboard(now: Date): Promise<PlatformDashboardSummary>;
  getCompanyRollups(): Promise<CompanyRollupSummary[]>;
}

const decimalToNumber = (value: Prisma.Decimal | number | null | undefined): number => (value == null ? 0 : Number(value));

const mapEmployee = (employee: {
  id: string;
  companyId: string;
  userId: string;
  departmentId: string | null;
  managerId: string | null;
  status: EmployeeStatus;
  company: { status: CompanyStatus };
}): ReportEmployeeRecord => ({
  id: employee.id,
  companyId: employee.companyId,
  userId: employee.userId,
  departmentId: employee.departmentId,
  managerId: employee.managerId,
  status: employee.status,
  companyStatus: employee.company.status
});

const emptyEmployeeScope = (scope: ReportScope) => Array.isArray(scope.employeeIds) && scope.employeeIds.length === 0;

const employeeIdWhere = (scope: ReportScope, employeeId?: string) => {
  if (employeeId) {
    return employeeId;
  }

  if (scope.employeeIds) {
    return { in: scope.employeeIds };
  }

  return undefined;
};

const employeeRelationWhere = (
  scope: ReportScope,
  filters: { employeeId?: string; departmentId?: string }
): Prisma.EmployeeProfileWhereInput | undefined => {
  const where: Prisma.EmployeeProfileWhereInput = {};

  if (filters.departmentId) {
    where.departmentId = filters.departmentId;
  }

  if (!filters.employeeId && scope.employeeIds) {
    where.id = { in: scope.employeeIds };
  }

  return Object.keys(where).length > 0 ? where : undefined;
};

const dateRangeWhere = (from?: Date, to?: Date) => {
  if (!from && !to) {
    return undefined;
  }

  return {
    gte: from,
    lte: to
  };
};

const increment = <T extends string>(counts: Record<T, number>, key: T) => {
  counts[key] += 1;
};

const okrStatusCounts = (): Record<OKRStatus, number> => ({
  DRAFT: 0,
  ASSIGNED: 0,
  IN_PROGRESS: 0,
  SUBMITTED: 0,
  APPROVED: 0,
  REJECTED: 0,
  ARCHIVED: 0
});

const performanceStatusCounts = (): Record<PerformanceReviewStatus, number> => ({
  DRAFT: 0,
  SUBMITTED: 0,
  ACKNOWLEDGED: 0,
  ARCHIVED: 0
});

const prismaReportsRepository: ReportsRepository = {
  async findCompanyById(companyId) {
    const prisma = getPrismaClient();
    return prisma.company.findUnique({ where: { id: companyId }, select: { id: true } });
  },

  async findEmployeeByUserId(userId) {
    const prisma = getPrismaClient();
    const employee = await prisma.employeeProfile.findUnique({
      where: { userId },
      include: { company: true }
    });

    return employee ? mapEmployee(employee) : null;
  },

  async findEmployeeByIdInCompany(employeeId, companyId) {
    const prisma = getPrismaClient();
    const employee = await prisma.employeeProfile.findFirst({
      where: { id: employeeId, companyId },
      include: { company: true }
    });

    return employee ? mapEmployee(employee) : null;
  },

  async findDepartmentByIdInCompany(departmentId, companyId) {
    const prisma = getPrismaClient();
    return prisma.department.findFirst({
      where: { id: departmentId, companyId },
      select: { id: true }
    });
  },

  async findReviewCycleByIdInCompany(reviewCycleId, companyId) {
    const prisma = getPrismaClient();
    return prisma.reviewCycle.findFirst({
      where: { id: reviewCycleId, companyId },
      select: { id: true }
    });
  },

  async listDirectReportIds(managerId, companyId) {
    const prisma = getPrismaClient();
    const reports = await prisma.employeeProfile.findMany({
      where: {
        companyId,
        managerId,
        status: "ACTIVE"
      },
      select: { id: true }
    });

    return reports.map((report) => report.id);
  },

  async getDashboardSummary(scope, actorUserId, todayStart, todayEnd) {
    const prisma = getPrismaClient();
    const employeeFilter = scope.employeeIds ? { id: { in: scope.employeeIds } } : {};
    const scopedEmployeeId = employeeIdWhere(scope);
    const departmentsTotal = scope.employeeIds
      ? new Set(
          (
            await prisma.employeeProfile.findMany({
              where: { companyId: scope.companyId, ...employeeFilter },
              select: { departmentId: true }
            })
          )
            .map((employee) => employee.departmentId)
            .filter((departmentId): departmentId is string => Boolean(departmentId))
        ).size
      : await prisma.department.count({ where: { companyId: scope.companyId } });

    const [
      totalEmployees,
      activeEmployees,
      todayClockIns,
      openSessions,
      pendingLeaveRequests,
      activeOkrs,
      pendingReviews,
      unreadNotifications
    ] = await Promise.all([
      prisma.employeeProfile.count({ where: { companyId: scope.companyId, ...employeeFilter } }),
      prisma.employeeProfile.count({ where: { companyId: scope.companyId, status: "ACTIVE", ...employeeFilter } }),
      prisma.attendanceSession.count({
        where: {
          companyId: scope.companyId,
          employeeId: scopedEmployeeId,
          clockInAt: { gte: todayStart, lte: todayEnd }
        }
      }),
      prisma.attendanceSession.count({
        where: {
          companyId: scope.companyId,
          employeeId: scopedEmployeeId,
          status: "OPEN"
        }
      }),
      prisma.leaveRequest.count({
        where: {
          companyId: scope.companyId,
          employeeId: scopedEmployeeId,
          status: "PENDING"
        }
      }),
      prisma.oKR.count({
        where: {
          companyId: scope.companyId,
          employeeId: scopedEmployeeId,
          status: { in: ["ASSIGNED", "IN_PROGRESS", "SUBMITTED"] }
        }
      }),
      prisma.performanceReview.count({
        where: {
          companyId: scope.companyId,
          employeeId: scopedEmployeeId,
          status: "DRAFT"
        }
      }),
      prisma.notification.count({
        where: {
          userId: actorUserId,
          status: "UNREAD"
        }
      })
    ]);

    return {
      companyId: scope.companyId,
      employees: {
        total: totalEmployees,
        active: activeEmployees,
        inactive: totalEmployees - activeEmployees
      },
      departments: { total: departmentsTotal },
      attendance: {
        todayClockIns,
        openSessions
      },
      leave: {
        pendingRequests: pendingLeaveRequests
      },
      okrs: {
        active: activeOkrs
      },
      performance: {
        pendingReviews
      },
      notifications: {
        unreadCount: unreadNotifications
      }
    };
  },

  async getAttendanceSummary(scope, filters) {
    if (emptyEmployeeScope(scope)) {
      return { totalSessions: 0, openSessions: 0, closedSessions: 0, clockInsByDay: [] };
    }

    const prisma = getPrismaClient();
    const sessions = await prisma.attendanceSession.findMany({
      where: {
        companyId: scope.companyId,
        employeeId: employeeIdWhere(scope, filters.employeeId),
        employee: employeeRelationWhere(scope, filters),
        clockInAt: dateRangeWhere(filters.from, filters.to)
      },
      select: {
        status: true,
        clockInAt: true
      }
    });
    const byDay = new Map<string, number>();

    for (const session of sessions) {
      const day = session.clockInAt.toISOString().slice(0, 10);
      byDay.set(day, (byDay.get(day) ?? 0) + 1);
    }

    return {
      totalSessions: sessions.length,
      openSessions: sessions.filter((session) => session.status === "OPEN").length,
      closedSessions: sessions.filter((session) => session.status === "CLOSED").length,
      clockInsByDay: Array.from(byDay.entries())
        .sort(([left], [right]) => left.localeCompare(right))
        .map(([date, count]) => ({ date, count }))
    };
  },

  async getLeaveSummary(scope, filters) {
    if (emptyEmployeeScope(scope)) {
      return { totalRequests: 0, pendingRequests: 0, approvedRequests: 0, rejectedRequests: 0, leaveUsageByType: [], lowRemainingLeave: [] };
    }

    const prisma = getPrismaClient();
    const requestWhere: Prisma.LeaveRequestWhereInput = {
      companyId: scope.companyId,
      employeeId: employeeIdWhere(scope, filters.employeeId),
      employee: employeeRelationWhere(scope, filters),
      status: filters.status
    };

    if (filters.year) {
      requestWhere.startDate = {
        gte: new Date(Date.UTC(filters.year, 0, 1)),
        lte: new Date(Date.UTC(filters.year, 11, 31, 23, 59, 59, 999))
      };
    }

    const [requests, entitlements] = await Promise.all([
      prisma.leaveRequest.findMany({
        where: requestWhere,
        select: { status: true }
      }),
      prisma.leaveEntitlement.findMany({
        where: {
          companyId: scope.companyId,
          employeeId: employeeIdWhere(scope, filters.employeeId),
          employee: employeeRelationWhere(scope, filters),
          year: filters.year
        },
        include: { leaveType: true }
      })
    ]);
    const usageByType = new Map<string, { leaveTypeId: string; leaveTypeName: string; usedDays: number; totalDays: number }>();
    const lowRemainingLeave: LeaveReportSummary["lowRemainingLeave"] = [];

    for (const entitlement of entitlements) {
      const usedDays = decimalToNumber(entitlement.usedDays);
      const totalDays = decimalToNumber(entitlement.totalDays);
      const existing = usageByType.get(entitlement.leaveTypeId) ?? {
        leaveTypeId: entitlement.leaveTypeId,
        leaveTypeName: entitlement.leaveType.name,
        usedDays: 0,
        totalDays: 0
      };
      existing.usedDays += usedDays;
      existing.totalDays += totalDays;
      usageByType.set(entitlement.leaveTypeId, existing);

      const remainingDays = totalDays - usedDays;
      if (remainingDays <= 2) {
        lowRemainingLeave.push({
          employeeId: entitlement.employeeId,
          leaveTypeId: entitlement.leaveTypeId,
          leaveTypeName: entitlement.leaveType.name,
          remainingDays
        });
      }
    }

    return {
      totalRequests: requests.length,
      pendingRequests: requests.filter((request) => request.status === "PENDING").length,
      approvedRequests: requests.filter((request) => request.status === "APPROVED").length,
      rejectedRequests: requests.filter((request) => request.status === "REJECTED").length,
      leaveUsageByType: Array.from(usageByType.values()),
      lowRemainingLeave
    };
  },

  async getOkrSummary(scope, filters, now) {
    if (emptyEmployeeScope(scope)) {
      return { totalOkrs: 0, statusCounts: okrStatusCounts(), activeCount: 0, completedCount: 0, averageProgressPercent: null, overdueCount: 0 };
    }

    const prisma = getPrismaClient();
    const okrs = await prisma.oKR.findMany({
      where: {
        companyId: scope.companyId,
        employeeId: employeeIdWhere(scope, filters.employeeId),
        employee: employeeRelationWhere(scope, filters),
        status: filters.status
      },
      include: {
        progressUpdates: {
          orderBy: { createdAt: "desc" },
          take: 1
        }
      }
    });
    const statusCounts = okrStatusCounts();
    const progressValues: number[] = [];

    for (const okr of okrs) {
      increment(statusCounts, okr.status);
      const latestProgress = okr.progressUpdates[0]?.progressPercent;
      if (latestProgress !== undefined) {
        progressValues.push(latestProgress);
      }
    }

    return {
      totalOkrs: okrs.length,
      statusCounts,
      activeCount: okrs.filter((okr) => ["ASSIGNED", "IN_PROGRESS", "SUBMITTED"].includes(okr.status)).length,
      completedCount: statusCounts.APPROVED,
      averageProgressPercent: progressValues.length
        ? Math.round((progressValues.reduce((total, value) => total + value, 0) / progressValues.length) * 100) / 100
        : null,
      overdueCount: okrs.filter((okr) => okr.dueDate && okr.dueDate < now && okr.status !== "APPROVED" && okr.status !== "ARCHIVED").length
    };
  },

  async getPerformanceSummary(scope, filters) {
    if (emptyEmployeeScope(scope)) {
      return {
        totalReviews: 0,
        statusCounts: performanceStatusCounts(),
        pendingReviews: 0,
        submittedReviews: 0,
        finalizedReviews: 0,
        averageRating: null,
        reviewsByCycle: []
      };
    }

    const prisma = getPrismaClient();
    const reviews = await prisma.performanceReview.findMany({
      where: {
        companyId: scope.companyId,
        employeeId: employeeIdWhere(scope, filters.employeeId),
        employee: employeeRelationWhere(scope, filters),
        reviewCycleId: filters.reviewCycleId,
        status: filters.status
      },
      include: { reviewCycle: true }
    });
    const statusCounts = performanceStatusCounts();
    const ratings: number[] = [];
    const cycleMap = new Map<string, { reviewCycleId: string; reviewCycleName: string; count: number }>();

    for (const review of reviews) {
      increment(statusCounts, review.status);

      if (review.rating !== null) {
        ratings.push(decimalToNumber(review.rating));
      }

      const existing = cycleMap.get(review.reviewCycleId) ?? {
        reviewCycleId: review.reviewCycleId,
        reviewCycleName: review.reviewCycle.name,
        count: 0
      };
      existing.count += 1;
      cycleMap.set(review.reviewCycleId, existing);
    }

    return {
      totalReviews: reviews.length,
      statusCounts,
      pendingReviews: statusCounts.DRAFT,
      submittedReviews: statusCounts.SUBMITTED,
      finalizedReviews: statusCounts.ACKNOWLEDGED,
      averageRating: ratings.length ? Math.round((ratings.reduce((total, value) => total + value, 0) / ratings.length) * 100) / 100 : null,
      reviewsByCycle: Array.from(cycleMap.values())
    };
  },

  async getEmployeeDashboard(employee, todayStart, todayEnd, year) {
    const prisma = getPrismaClient();
    const today = todayStart;
    const [todaySessions, openSession, shiftAssignments, entitlements, pendingLeaveRequests, activeOkrs, latestReview, unreadNotifications] =
      await Promise.all([
        prisma.attendanceSession.findMany({
          where: {
            companyId: employee.companyId,
            employeeId: employee.id,
            clockInAt: { gte: todayStart, lte: todayEnd }
          },
          select: {
            id: true,
            status: true,
            clockInAt: true
          },
          orderBy: { clockInAt: "desc" }
        }),
        prisma.attendanceSession.findFirst({
          where: {
            companyId: employee.companyId,
            employeeId: employee.id,
            status: "OPEN"
          },
          select: {
            id: true,
            status: true,
            clockInAt: true
          },
          orderBy: { clockInAt: "desc" }
        }),
        prisma.employeeShiftAssignment.findMany({
          where: {
            companyId: employee.companyId,
            employeeId: employee.id,
            startsOn: { lte: today },
            OR: [{ endsOn: null }, { endsOn: { gte: today } }]
          },
          include: { shift: true },
          orderBy: { startsOn: "desc" }
        }),
        prisma.leaveEntitlement.findMany({
          where: {
            companyId: employee.companyId,
            employeeId: employee.id,
            year
          },
          include: { leaveType: true }
        }),
        prisma.leaveRequest.count({
          where: {
            companyId: employee.companyId,
            employeeId: employee.id,
            status: "PENDING"
          }
        }),
        prisma.oKR.count({
          where: {
            companyId: employee.companyId,
            employeeId: employee.id,
            status: { in: ["ASSIGNED", "IN_PROGRESS", "SUBMITTED"] }
          }
        }),
        prisma.performanceReview.findFirst({
          where: {
            companyId: employee.companyId,
            employeeId: employee.id
          },
          select: {
            id: true,
            reviewCycleId: true,
            status: true,
            rating: true,
            submittedAt: true,
            createdAt: true
          },
          orderBy: { createdAt: "desc" }
        }),
        prisma.notification.count({
          where: {
            userId: employee.userId,
            status: "UNREAD"
          }
        })
      ]);

    return {
      employeeId: employee.id,
      companyId: employee.companyId,
      attendance: {
        todayStatus: openSession ? "CLOCKED_IN" : todaySessions.length > 0 ? "CLOCKED_OUT" : "NOT_CLOCKED_IN",
        openSession: openSession ? { id: openSession.id, clockInAt: openSession.clockInAt, status: openSession.status } : null
      },
      shift: {
        currentAssignments: shiftAssignments.map((assignment) => ({
          assignmentId: assignment.id,
          shiftId: assignment.shiftId,
          name: assignment.shift.name,
          startTime: assignment.shift.startTime,
          endTime: assignment.shift.endTime,
          startsOn: assignment.startsOn,
          endsOn: assignment.endsOn
        }))
      },
      leave: {
        pendingRequestsCount: pendingLeaveRequests,
        balances: entitlements.map((entitlement) => {
          const totalDays = decimalToNumber(entitlement.totalDays);
          const usedDays = decimalToNumber(entitlement.usedDays);

          return {
            leaveTypeId: entitlement.leaveTypeId,
            leaveTypeName: entitlement.leaveType.name,
            year: entitlement.year,
            totalDays,
            usedDays,
            remainingDays: totalDays - usedDays
          };
        })
      },
      okrs: {
        activeCount: activeOkrs
      },
      performance: {
        latestReview: latestReview
          ? {
              id: latestReview.id,
              reviewCycleId: latestReview.reviewCycleId,
              status: latestReview.status,
              rating: latestReview.rating === null ? null : decimalToNumber(latestReview.rating),
              submittedAt: latestReview.submittedAt,
              createdAt: latestReview.createdAt
            }
          : null
      },
      notifications: {
        unreadCount: unreadNotifications
      }
    };
  },

  async getPlatformDashboard(now) {
    const prisma = getPrismaClient();
    const recentThreshold = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    const [totalCompanies, activeCompanies, totalUsers, activeUsers, totalSubscriptions, recentCompanyCount] = await Promise.all([
      prisma.company.count(),
      prisma.company.count({ where: { status: "ACTIVE" } }),
      prisma.user.count(),
      prisma.user.count({ where: { status: "ACTIVE" } }),
      prisma.companySubscription.count(),
      prisma.company.count({ where: { createdAt: { gte: recentThreshold } } })
    ]);

    return {
      totalCompanies,
      activeCompanies,
      inactiveCompanies: totalCompanies - activeCompanies,
      totalUsers,
      activeUsers,
      totalSubscriptions,
      recentCompanyCount
    };
  },

  async getCompanyRollups() {
    const prisma = getPrismaClient();
    const companies = await prisma.company.findMany({
      select: {
        id: true,
        name: true,
        status: true,
        createdAt: true,
        subscriptions: {
          select: { status: true, createdAt: true },
          orderBy: { createdAt: "desc" },
          take: 1
        }
      },
      orderBy: { createdAt: "desc" }
    });

    return Promise.all(
      companies.map(async (company) => {
        const [employeeCount, activeEmployeeCount] = await Promise.all([
          prisma.employeeProfile.count({ where: { companyId: company.id } }),
          prisma.employeeProfile.count({ where: { companyId: company.id, status: "ACTIVE" } })
        ]);

        return {
          companyId: company.id,
          name: company.name,
          status: company.status,
          employeeCount,
          activeEmployeeCount,
          subscriptionStatus: company.subscriptions[0]?.status ?? null,
          createdAt: company.createdAt
        };
      })
    );
  }
};

let activeReportsRepository = prismaReportsRepository;

export const getReportsRepository = () => activeReportsRepository;

export const setReportsRepositoryForTests = (repository: ReportsRepository) => {
  activeReportsRepository = repository;
};

export const resetReportsRepositoryForTests = () => {
  activeReportsRepository = prismaReportsRepository;
};
