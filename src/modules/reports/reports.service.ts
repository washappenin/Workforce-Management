import { getRequiredScopedCompanyId, hasRole, isSuperAdmin } from "../../lib/authorization";
import { AuthorizationError, NotFoundError } from "../../lib/errors";
import type { AuthenticatedUser } from "../../types/auth";
import {
  getReportsRepository,
  type ReportEmployeeRecord,
  type ReportScope
} from "./reports.repository";
import type {
  AttendanceReportQuery,
  CompanyScopeReportQuery,
  LeaveReportQuery,
  OkrReportQuery,
  PerformanceReportQuery
} from "./reports.validation";

const activeOkrStatuses = ["ASSIGNED", "IN_PROGRESS", "SUBMITTED"];

const getTodayRange = () => {
  const now = new Date();
  const start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const end = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 23, 59, 59, 999));

  return { start, end, year: now.getUTCFullYear() };
};

const getReportScopeCompanyId = (actor: AuthenticatedUser, requestedCompanyId?: string | null) =>
  getRequiredScopedCompanyId(actor, requestedCompanyId);

const assertCompanyExists = async (companyId: string) => {
  const company = await getReportsRepository().findCompanyById(companyId);

  if (!company) {
    throw new NotFoundError("Company not found");
  }
};

const assertActiveEmployee = (employee: ReportEmployeeRecord) => {
  if (employee.status !== "ACTIVE") {
    throw new AuthorizationError("Employee profile is not active");
  }

  if (employee.companyStatus !== "ACTIVE") {
    throw new AuthorizationError("Company is not active");
  }
};

const getActiveSelfEmployee = async (actor: AuthenticatedUser) => {
  const employee = await getReportsRepository().findEmployeeByUserId(actor.id);

  if (!employee) {
    throw new AuthorizationError("Employee profile is required");
  }

  assertActiveEmployee(employee);

  return employee;
};

const validateEmployeeFilter = async (companyId: string, employeeId?: string) => {
  if (!employeeId) {
    return null;
  }

  const employee = await getReportsRepository().findEmployeeByIdInCompany(employeeId, companyId);

  if (!employee) {
    throw new NotFoundError("Employee not found");
  }

  return employee;
};

const validateDepartmentFilter = async (companyId: string, departmentId?: string) => {
  if (!departmentId) {
    return;
  }

  const department = await getReportsRepository().findDepartmentByIdInCompany(departmentId, companyId);

  if (!department) {
    throw new NotFoundError("Department not found");
  }
};

const validateReviewCycleFilter = async (companyId: string, reviewCycleId?: string) => {
  if (!reviewCycleId) {
    return;
  }

  const reviewCycle = await getReportsRepository().findReviewCycleByIdInCompany(reviewCycleId, companyId);

  if (!reviewCycle) {
    throw new NotFoundError("Review cycle not found");
  }
};

const validateAdminFilters = async (
  companyId: string,
  filters: { employeeId?: string; departmentId?: string; reviewCycleId?: string }
) => {
  await validateEmployeeFilter(companyId, filters.employeeId);
  await validateDepartmentFilter(companyId, filters.departmentId);
  await validateReviewCycleFilter(companyId, filters.reviewCycleId);
};

const getAdminReportScope = async (actor: AuthenticatedUser, query: CompanyScopeReportQuery): Promise<ReportScope> => {
  const companyId = getReportScopeCompanyId(actor, query.companyId);

  await assertCompanyExists(companyId);

  return { companyId };
};

const getTeamReportScope = async (
  actor: AuthenticatedUser,
  query: { companyId?: string; employeeId?: string; departmentId?: string; reviewCycleId?: string }
): Promise<ReportScope> => {
  if (!hasRole(actor, "MANAGER")) {
    throw new AuthorizationError();
  }

  const manager = await getActiveSelfEmployee(actor);
  const companyId = getReportScopeCompanyId(actor, query.companyId);

  if (companyId !== manager.companyId) {
    throw new AuthorizationError("Company scope mismatch");
  }

  await validateDepartmentFilter(companyId, query.departmentId);
  await validateReviewCycleFilter(companyId, query.reviewCycleId);

  const directReportIds = await getReportsRepository().listDirectReportIds(manager.id, companyId);

  if (query.employeeId) {
    const employee = await validateEmployeeFilter(companyId, query.employeeId);

    if (!employee || !directReportIds.includes(employee.id)) {
      throw new AuthorizationError("Employee is outside your direct reports");
    }

    return { companyId, employeeIds: [employee.id] };
  }

  return { companyId, employeeIds: directReportIds };
};

export const getAdminDashboardReport = async (actor: AuthenticatedUser, query: CompanyScopeReportQuery) => {
  const scope = await getAdminReportScope(actor, query);
  const today = getTodayRange();

  return getReportsRepository().getDashboardSummary(scope, actor.id, today.start, today.end);
};

export const getAdminAttendanceReport = async (actor: AuthenticatedUser, query: AttendanceReportQuery) => {
  const scope = await getAdminReportScope(actor, query);

  await validateAdminFilters(scope.companyId, query);

  return getReportsRepository().getAttendanceSummary(scope, query);
};

export const getAdminLeaveReport = async (actor: AuthenticatedUser, query: LeaveReportQuery) => {
  const scope = await getAdminReportScope(actor, query);

  await validateAdminFilters(scope.companyId, query);

  return getReportsRepository().getLeaveSummary(scope, query);
};

export const getAdminOkrReport = async (actor: AuthenticatedUser, query: OkrReportQuery) => {
  const scope = await getAdminReportScope(actor, query);

  await validateAdminFilters(scope.companyId, query);

  return getReportsRepository().getOkrSummary(scope, query, new Date());
};

export const getAdminPerformanceReport = async (actor: AuthenticatedUser, query: PerformanceReportQuery) => {
  const scope = await getAdminReportScope(actor, query);

  await validateAdminFilters(scope.companyId, query);

  return getReportsRepository().getPerformanceSummary(scope, query);
};

export const getTeamDashboardReport = async (actor: AuthenticatedUser, query: CompanyScopeReportQuery) => {
  const scope = await getTeamReportScope(actor, query);
  const today = getTodayRange();

  return getReportsRepository().getDashboardSummary(scope, actor.id, today.start, today.end);
};

export const getTeamAttendanceReport = async (actor: AuthenticatedUser, query: AttendanceReportQuery) => {
  const scope = await getTeamReportScope(actor, query);

  return getReportsRepository().getAttendanceSummary(scope, query);
};

export const getTeamLeaveReport = async (actor: AuthenticatedUser, query: LeaveReportQuery) => {
  const scope = await getTeamReportScope(actor, query);

  return getReportsRepository().getLeaveSummary(scope, query);
};

export const getTeamOkrReport = async (actor: AuthenticatedUser, query: OkrReportQuery) => {
  const scope = await getTeamReportScope(actor, query);

  return getReportsRepository().getOkrSummary(scope, query, new Date());
};

export const getTeamPerformanceReport = async (actor: AuthenticatedUser, query: PerformanceReportQuery) => {
  const scope = await getTeamReportScope(actor, query);

  return getReportsRepository().getPerformanceSummary(scope, query);
};

export const getMyDashboardReport = async (actor: AuthenticatedUser) => {
  if (isSuperAdmin(actor)) {
    const employee = await getReportsRepository().findEmployeeByUserId(actor.id);

    if (!employee) {
      throw new AuthorizationError("Employee profile is required");
    }
  }

  const employee = await getActiveSelfEmployee(actor);
  const today = getTodayRange();

  return getReportsRepository().getEmployeeDashboard(employee, today.start, today.end, today.year);
};

export const getSuperAdminDashboardReport = async (actor: AuthenticatedUser) => {
  if (!isSuperAdmin(actor)) {
    throw new AuthorizationError();
  }

  return getReportsRepository().getPlatformDashboard(new Date());
};

export const getSuperAdminCompanyReports = async (actor: AuthenticatedUser) => {
  if (!isSuperAdmin(actor)) {
    throw new AuthorizationError();
  }

  return getReportsRepository().getCompanyRollups();
};

export const reportMetadata = {
  activeOkrStatuses
};
