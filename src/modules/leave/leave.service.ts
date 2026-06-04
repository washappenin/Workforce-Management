import { getRequiredScopedCompanyId, hasAnyRole, hasRole, isSuperAdmin } from "../../lib/authorization";
import { recordAuditLog, type AuditRequestContext } from "../../lib/audit";
import { AuthorizationError, ConflictError, NotFoundError, ValidationError } from "../../lib/errors";
import type { AuthenticatedUser } from "../../types/auth";
import {
  getLeaveRepository,
  type LeaveEntitlementRecord,
  type LeaveRequestRecord,
  type LeaveTypeRecord,
  type UpdateLeaveEntitlementRepositoryInput,
  type UpdateLeaveTypeRepositoryInput
} from "./leave.repository";
import type {
  AdminLeaveRequestsQuery,
  CreateLeaveEntitlementInput,
  CreateLeaveRequestInput,
  CreateLeaveTypeInput,
  LeaveEntitlementsQuery,
  LeaveScopeQuery,
  MyLeaveQuery,
  ReviewLeaveRequestInput,
  UpdateLeaveEntitlementInput,
  UpdateLeaveTypeInput,
  UpdateLeaveTypeStatusInput
} from "./leave.validation";

const millisecondsPerDay = 24 * 60 * 60 * 1000;

const getLeaveScope = (actor: AuthenticatedUser, requestedCompanyId?: string | null) =>
  getRequiredScopedCompanyId(actor, requestedCompanyId);

const getDateYear = (date: Date) => date.getUTCFullYear();

const calculateRequestedDays = (startDate: Date, endDate: Date) => {
  const diff = endDate.getTime() - startDate.getTime();
  return Math.floor(diff / millisecondsPerDay) + 1;
};

const assertDateRange = (startDate: Date, endDate: Date) => {
  if (endDate < startDate) {
    throw new ValidationError("endDate must be on or after startDate", undefined, 400);
  }

  if (getDateYear(startDate) !== getDateYear(endDate)) {
    throw new ValidationError("Leave request must stay within one entitlement year", undefined, 400);
  }
};

const serializeLeaveType = (leaveType: LeaveTypeRecord) => ({
  id: leaveType.id,
  companyId: leaveType.companyId,
  name: leaveType.name,
  status: leaveType.status,
  defaultAnnualAllowance: leaveType.defaultAnnualAllowance,
  createdAt: leaveType.createdAt,
  updatedAt: leaveType.updatedAt
});

const serializeEntitlement = (entitlement: LeaveEntitlementRecord) => ({
  id: entitlement.id,
  companyId: entitlement.companyId,
  employeeId: entitlement.employeeId,
  leaveTypeId: entitlement.leaveTypeId,
  year: entitlement.year,
  totalDays: entitlement.totalDays,
  usedDays: entitlement.usedDays,
  remainingDays: entitlement.totalDays - entitlement.usedDays,
  createdAt: entitlement.createdAt,
  updatedAt: entitlement.updatedAt,
  ...(entitlement.leaveType ? { leaveType: serializeLeaveType(entitlement.leaveType) } : {})
});

const serializeLeaveRequest = (request: LeaveRequestRecord) => ({
  id: request.id,
  companyId: request.companyId,
  employeeId: request.employeeId,
  leaveTypeId: request.leaveTypeId,
  startDate: request.startDate,
  endDate: request.endDate,
  requestedDays: calculateRequestedDays(request.startDate, request.endDate),
  reason: request.reason,
  status: request.status,
  reviewedById: request.reviewedById,
  reviewedAt: request.reviewedAt,
  reviewComment: request.reviewComment,
  createdAt: request.createdAt,
  updatedAt: request.updatedAt,
  ...(request.leaveType ? { leaveType: serializeLeaveType(request.leaveType) } : {})
});

const assertCompanyExists = async (companyId: string) => {
  const company = await getLeaveRepository().findCompanyById(companyId);

  if (!company) {
    throw new NotFoundError("Company not found");
  }
};

const assertEntitlementDays = (totalDays: number, usedDays: number) => {
  if (usedDays > totalDays) {
    throw new ValidationError("usedDays cannot exceed totalDays", undefined, 400);
  }
};

const getActiveSelfEmployee = async (actor: AuthenticatedUser) => {
  if (isSuperAdmin(actor)) {
    throw new AuthorizationError("Employee profile is required");
  }

  const employee = await getLeaveRepository().findEmployeeByUserId(actor.id);

  if (!employee) {
    throw new AuthorizationError("Employee profile is required");
  }

  if (employee.status !== "ACTIVE") {
    throw new AuthorizationError("Employee profile is not active");
  }

  if (employee.companyStatus !== "ACTIVE") {
    throw new AuthorizationError("Company is not active");
  }

  return employee;
};

const getReviewerEmployeeIfAvailable = async (actor: AuthenticatedUser, companyId: string) => {
  const employee = await getLeaveRepository().findEmployeeByUserId(actor.id);

  return employee?.companyId === companyId ? employee : null;
};

const resolveReviewContext = async (actor: AuthenticatedUser, leaveRequestId: string, query: LeaveScopeQuery) => {
  const repository = getLeaveRepository();
  const isAdminReviewer = hasAnyRole(actor, ["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN"]);

  if (isAdminReviewer) {
    const companyId = getLeaveScope(actor, query.companyId);
    const request = await repository.findLeaveRequestByIdInCompany(leaveRequestId, companyId);

    if (!request) {
      throw new NotFoundError("Leave request not found");
    }

    return {
      request,
      reviewerEmployee: await getReviewerEmployeeIfAvailable(actor, companyId)
    };
  }

  if (!hasRole(actor, "MANAGER")) {
    throw new AuthorizationError();
  }

  const reviewerEmployee = await getActiveSelfEmployee(actor);
  const request = await repository.findLeaveRequestByIdInCompany(leaveRequestId, reviewerEmployee.companyId);

  if (!request) {
    throw new NotFoundError("Leave request not found");
  }

  if (request.employee?.managerId !== reviewerEmployee.id) {
    throw new AuthorizationError("Leave request is outside your direct reports");
  }

  return {
    request,
    reviewerEmployee
  };
};

const assertReviewableRequest = (request: LeaveRequestRecord) => {
  if (request.status !== "PENDING") {
    throw new ValidationError("Only pending leave requests can be reviewed", undefined, 400);
  }
};

const getRequestEntitlement = async (request: LeaveRequestRecord) => {
  const entitlement = await getLeaveRepository().findEntitlementByEmployeeTypeYear(
    request.employeeId,
    request.leaveTypeId,
    getDateYear(request.startDate),
    request.companyId
  );

  if (!entitlement) {
    throw new ValidationError("NO_ENTITLEMENT", undefined, 400);
  }

  return entitlement;
};

const assertEnoughBalance = (entitlement: LeaveEntitlementRecord, requestedDays: number) => {
  if (entitlement.totalDays - entitlement.usedDays < requestedDays) {
    throw new ValidationError("INSUFFICIENT_LEAVE_BALANCE", undefined, 400);
  }
};

export const createLeaveType = async (
  actor: AuthenticatedUser,
  input: CreateLeaveTypeInput,
  auditContext: AuditRequestContext
) => {
  const repository = getLeaveRepository();
  const companyId = getLeaveScope(actor, input.companyId);

  await assertCompanyExists(companyId);

  const existing = await repository.findLeaveTypeByNameInCompany(input.name, companyId);

  if (existing) {
    throw new ConflictError("Leave type name already exists in this company");
  }

  const leaveType = await repository.createLeaveType({
    companyId,
    name: input.name,
    defaultAnnualAllowance: input.defaultAnnualAllowance
  });

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "LEAVE",
    action: "LEAVE_TYPE_CREATED",
    targetType: "LeaveType",
    targetId: leaveType.id,
    metadata: { name: leaveType.name, status: leaveType.status, defaultAnnualAllowance: leaveType.defaultAnnualAllowance },
    ...auditContext
  });

  return serializeLeaveType(leaveType);
};

export const listLeaveTypes = async (actor: AuthenticatedUser, query: LeaveScopeQuery) => {
  const companyId = getLeaveScope(actor, query.companyId);
  const leaveTypes = await getLeaveRepository().listLeaveTypes(companyId);

  return leaveTypes.map(serializeLeaveType);
};

export const getLeaveType = async (actor: AuthenticatedUser, leaveTypeId: string, query: LeaveScopeQuery) => {
  const companyId = getLeaveScope(actor, query.companyId);
  const leaveType = await getLeaveRepository().findLeaveTypeByIdInCompany(leaveTypeId, companyId);

  if (!leaveType) {
    throw new NotFoundError("Leave type not found");
  }

  return serializeLeaveType(leaveType);
};

export const updateLeaveType = async (
  actor: AuthenticatedUser,
  leaveTypeId: string,
  input: UpdateLeaveTypeInput,
  query: LeaveScopeQuery,
  auditContext: AuditRequestContext
) => {
  const repository = getLeaveRepository();
  const companyId = getLeaveScope(actor, query.companyId);
  const current = await repository.findLeaveTypeByIdInCompany(leaveTypeId, companyId);

  if (!current) {
    throw new NotFoundError("Leave type not found");
  }

  if (input.name && input.name !== current.name) {
    const existing = await repository.findLeaveTypeByNameInCompany(input.name, companyId);

    if (existing && existing.id !== leaveTypeId) {
      throw new ConflictError("Leave type name already exists in this company");
    }
  }

  const updateInput: UpdateLeaveTypeRepositoryInput = {
    name: input.name,
    defaultAnnualAllowance: input.defaultAnnualAllowance
  };
  const leaveType = await repository.updateLeaveType(leaveTypeId, companyId, updateInput);

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "LEAVE",
    action: "LEAVE_TYPE_UPDATED",
    targetType: "LeaveType",
    targetId: leaveType.id,
    metadata: { updatedFields: Object.keys(input) },
    ...auditContext
  });

  return serializeLeaveType(leaveType);
};

export const updateLeaveTypeStatus = async (
  actor: AuthenticatedUser,
  leaveTypeId: string,
  input: UpdateLeaveTypeStatusInput,
  query: LeaveScopeQuery,
  auditContext: AuditRequestContext
) => {
  const repository = getLeaveRepository();
  const companyId = getLeaveScope(actor, query.companyId);
  const current = await repository.findLeaveTypeByIdInCompany(leaveTypeId, companyId);

  if (!current) {
    throw new NotFoundError("Leave type not found");
  }

  const leaveType = await repository.updateLeaveTypeStatus(leaveTypeId, companyId, input.status);

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "LEAVE",
    action: "LEAVE_TYPE_STATUS_CHANGED",
    targetType: "LeaveType",
    targetId: leaveType.id,
    metadata: { previousStatus: current.status, status: leaveType.status },
    ...auditContext
  });

  return serializeLeaveType(leaveType);
};

export const upsertLeaveEntitlement = async (
  actor: AuthenticatedUser,
  input: CreateLeaveEntitlementInput,
  auditContext: AuditRequestContext
) => {
  const repository = getLeaveRepository();
  const companyId = getLeaveScope(actor, input.companyId);

  assertEntitlementDays(input.totalDays, input.usedDays);

  const employee = await repository.findEmployeeByIdInCompany(input.employeeId, companyId);

  if (!employee) {
    throw new NotFoundError("Employee not found");
  }

  if (employee.status !== "ACTIVE") {
    throw new ValidationError("Employee must be active before leave entitlement assignment", undefined, 400);
  }

  const leaveType = await repository.findLeaveTypeByIdInCompany(input.leaveTypeId, companyId);

  if (!leaveType) {
    throw new NotFoundError("Leave type not found");
  }

  if (leaveType.status !== "ACTIVE") {
    throw new ValidationError("Leave type must be active before entitlement assignment", undefined, 400);
  }

  const result = await repository.upsertEntitlement({
    companyId,
    employeeId: employee.id,
    leaveTypeId: leaveType.id,
    year: input.year,
    totalDays: input.totalDays,
    usedDays: input.usedDays
  });

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "LEAVE",
    action: result.created ? "LEAVE_ENTITLEMENT_CREATED" : "LEAVE_ENTITLEMENT_UPDATED",
    targetType: "LeaveEntitlement",
    targetId: result.entitlement.id,
    metadata: { employeeId: employee.id, leaveTypeId: leaveType.id, year: result.entitlement.year },
    ...auditContext
  });

  return serializeEntitlement(result.entitlement);
};

export const listLeaveEntitlements = async (actor: AuthenticatedUser, query: LeaveEntitlementsQuery) => {
  const repository = getLeaveRepository();
  const companyId = getLeaveScope(actor, query.companyId);

  if (query.employeeId) {
    const employee = await repository.findEmployeeByIdInCompany(query.employeeId, companyId);

    if (!employee) {
      throw new NotFoundError("Employee not found");
    }
  }

  if (query.leaveTypeId) {
    const leaveType = await repository.findLeaveTypeByIdInCompany(query.leaveTypeId, companyId);

    if (!leaveType) {
      throw new NotFoundError("Leave type not found");
    }
  }

  const entitlements = await repository.listEntitlements(companyId, {
    employeeId: query.employeeId,
    leaveTypeId: query.leaveTypeId,
    year: query.year
  });

  return entitlements.map(serializeEntitlement);
};

export const getLeaveEntitlement = async (actor: AuthenticatedUser, entitlementId: string, query: LeaveScopeQuery) => {
  const companyId = getLeaveScope(actor, query.companyId);
  const entitlement = await getLeaveRepository().findEntitlementByIdInCompany(entitlementId, companyId);

  if (!entitlement) {
    throw new NotFoundError("Leave entitlement not found");
  }

  return serializeEntitlement(entitlement);
};

export const updateLeaveEntitlement = async (
  actor: AuthenticatedUser,
  entitlementId: string,
  input: UpdateLeaveEntitlementInput,
  query: LeaveScopeQuery,
  auditContext: AuditRequestContext
) => {
  const repository = getLeaveRepository();
  const companyId = getLeaveScope(actor, query.companyId);
  const current = await repository.findEntitlementByIdInCompany(entitlementId, companyId);

  if (!current) {
    throw new NotFoundError("Leave entitlement not found");
  }

  const totalDays = input.totalDays ?? current.totalDays;
  const usedDays = input.usedDays ?? current.usedDays;

  assertEntitlementDays(totalDays, usedDays);

  const updateInput: UpdateLeaveEntitlementRepositoryInput = {
    totalDays: input.totalDays,
    usedDays: input.usedDays
  };
  const entitlement = await repository.updateEntitlement(entitlementId, companyId, updateInput);

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "LEAVE",
    action: "LEAVE_ENTITLEMENT_UPDATED",
    targetType: "LeaveEntitlement",
    targetId: entitlement.id,
    metadata: { updatedFields: Object.keys(input), employeeId: entitlement.employeeId, leaveTypeId: entitlement.leaveTypeId },
    ...auditContext
  });

  return serializeEntitlement(entitlement);
};

export const submitLeaveRequest = async (
  actor: AuthenticatedUser,
  input: CreateLeaveRequestInput,
  auditContext: AuditRequestContext
) => {
  const repository = getLeaveRepository();
  const employee = await getActiveSelfEmployee(actor);
  const leaveType = await repository.findLeaveTypeByIdInCompany(input.leaveTypeId, employee.companyId);

  if (!leaveType) {
    throw new NotFoundError("Leave type not found");
  }

  if (leaveType.status !== "ACTIVE") {
    throw new ValidationError("Leave type must be active before requesting leave", undefined, 400);
  }

  assertDateRange(input.startDate, input.endDate);

  const requestedDays = calculateRequestedDays(input.startDate, input.endDate);
  const entitlement = await repository.findEntitlementByEmployeeTypeYear(
    employee.id,
    leaveType.id,
    getDateYear(input.startDate),
    employee.companyId
  );

  if (!entitlement) {
    throw new ValidationError("NO_ENTITLEMENT", undefined, 400);
  }

  assertEnoughBalance(entitlement, requestedDays);

  const overlapping = await repository.findOverlappingLeaveRequest({
    companyId: employee.companyId,
    employeeId: employee.id,
    startDate: input.startDate,
    endDate: input.endDate
  });

  if (overlapping) {
    throw new ConflictError("Overlapping pending or approved leave request already exists");
  }

  const leaveRequest = await repository.createLeaveRequest({
    companyId: employee.companyId,
    employeeId: employee.id,
    leaveTypeId: leaveType.id,
    startDate: input.startDate,
    endDate: input.endDate,
    reason: input.reason
  });

  await recordAuditLog({
    companyId: employee.companyId,
    actorUserId: actor.id,
    category: "LEAVE",
    action: "LEAVE_REQUEST_SUBMITTED",
    targetType: "LeaveRequest",
    targetId: leaveRequest.id,
    metadata: { employeeId: employee.id, leaveTypeId: leaveType.id, requestedDays },
    ...auditContext
  });

  return serializeLeaveRequest(leaveRequest);
};

export const listMyLeave = async (actor: AuthenticatedUser, query: MyLeaveQuery) => {
  const employee = await getActiveSelfEmployee(actor);
  const [leaveRequests, entitlements] = await Promise.all([
    getLeaveRepository().listLeaveRequestsForEmployee(employee.id, {
      status: query.status,
      year: query.year
    }),
    getLeaveRepository().listEntitlements(employee.companyId, {
      employeeId: employee.id,
      year: query.year
    })
  ]);

  return {
    leaveRequests: leaveRequests.map(serializeLeaveRequest),
    entitlements: entitlements.map(serializeEntitlement)
  };
};

export const listTeamLeaveRequests = async (actor: AuthenticatedUser) => {
  if (!hasRole(actor, "MANAGER")) {
    throw new AuthorizationError();
  }

  const manager = await getActiveSelfEmployee(actor);
  const leaveRequests = await getLeaveRepository().listLeaveRequestsForDirectReports(manager.id, manager.companyId);

  return leaveRequests.map(serializeLeaveRequest);
};

export const listAdminLeaveRequests = async (actor: AuthenticatedUser, query: AdminLeaveRequestsQuery) => {
  const repository = getLeaveRepository();
  const companyId = getLeaveScope(actor, query.companyId);

  if (query.employeeId) {
    const employee = await repository.findEmployeeByIdInCompany(query.employeeId, companyId);

    if (!employee) {
      throw new NotFoundError("Employee not found");
    }
  }

  if (query.leaveTypeId) {
    const leaveType = await repository.findLeaveTypeByIdInCompany(query.leaveTypeId, companyId);

    if (!leaveType) {
      throw new NotFoundError("Leave type not found");
    }
  }

  const leaveRequests = await repository.listLeaveRequestsForCompany(companyId, {
    employeeId: query.employeeId,
    leaveTypeId: query.leaveTypeId,
    status: query.status,
    from: query.from,
    to: query.to
  });

  return leaveRequests.map(serializeLeaveRequest);
};

export const approveLeaveRequest = async (
  actor: AuthenticatedUser,
  leaveRequestId: string,
  input: ReviewLeaveRequestInput,
  query: LeaveScopeQuery,
  auditContext: AuditRequestContext
) => {
  const repository = getLeaveRepository();
  const { request, reviewerEmployee } = await resolveReviewContext(actor, leaveRequestId, query);

  assertReviewableRequest(request);

  const requestedDays = calculateRequestedDays(request.startDate, request.endDate);
  const entitlement = await getRequestEntitlement(request);

  assertEnoughBalance(entitlement, requestedDays);

  const reviewedAt = new Date();
  const leaveRequest = await repository.updateLeaveRequestReview(request.id, request.companyId, {
    status: "APPROVED",
    reviewedById: reviewerEmployee?.id ?? null,
    reviewedAt,
    reviewComment: input.comment ?? null
  });

  await repository.incrementEntitlementUsedDays(entitlement.id, request.companyId, requestedDays);

  await recordAuditLog({
    companyId: request.companyId,
    actorUserId: actor.id,
    category: "LEAVE",
    action: "LEAVE_REQUEST_APPROVED",
    targetType: "LeaveRequest",
    targetId: leaveRequest.id,
    metadata: { employeeId: request.employeeId, leaveTypeId: request.leaveTypeId, requestedDays },
    ...auditContext
  });

  return serializeLeaveRequest(leaveRequest);
};

export const rejectLeaveRequest = async (
  actor: AuthenticatedUser,
  leaveRequestId: string,
  input: ReviewLeaveRequestInput,
  query: LeaveScopeQuery,
  auditContext: AuditRequestContext
) => {
  const repository = getLeaveRepository();
  const { request, reviewerEmployee } = await resolveReviewContext(actor, leaveRequestId, query);

  assertReviewableRequest(request);

  const reviewedAt = new Date();
  const leaveRequest = await repository.updateLeaveRequestReview(request.id, request.companyId, {
    status: "REJECTED",
    reviewedById: reviewerEmployee?.id ?? null,
    reviewedAt,
    reviewComment: input.comment ?? null
  });

  await recordAuditLog({
    companyId: request.companyId,
    actorUserId: actor.id,
    category: "LEAVE",
    action: "LEAVE_REQUEST_REJECTED",
    targetType: "LeaveRequest",
    targetId: leaveRequest.id,
    metadata: { employeeId: request.employeeId, leaveTypeId: request.leaveTypeId },
    ...auditContext
  });

  return serializeLeaveRequest(leaveRequest);
};
