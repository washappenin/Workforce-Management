import type { OKRStatus } from "@prisma/client";

import { getRequiredScopedCompanyId, hasAnyRole, hasRole, isSuperAdmin } from "../../lib/authorization";
import { recordAuditLog, type AuditRequestContext } from "../../lib/audit";
import { AuthorizationError, NotFoundError } from "../../lib/errors";
import type { AuthenticatedUser } from "../../types/auth";
import {
  getOkrsRepository,
  type OkrApprovalRecord,
  type OkrEmployeeProfileRecord,
  type OkrRecord,
  type UpdateOkrRepositoryInput
} from "./okrs.repository";
import type {
  AdminOkrsQuery,
  CreateOkrInput,
  CreateOkrProgressInput,
  MyOkrsQuery,
  OkrApprovalInput,
  OkrScopeQuery,
  UpdateOkrInput,
  UpdateOkrStatusInput
} from "./okrs.validation";

const getOkrScope = (actor: AuthenticatedUser, requestedCompanyId?: string | null) =>
  getRequiredScopedCompanyId(actor, requestedCompanyId);

const serializeEmployee = (employee: OkrEmployeeProfileRecord) => ({
  id: employee.id,
  companyId: employee.companyId,
  managerId: employee.managerId,
  status: employee.status
});

const serializeProgressUpdate = (progressUpdate: NonNullable<OkrRecord["progressUpdates"]>[number]) => ({
  id: progressUpdate.id,
  companyId: progressUpdate.companyId,
  okrId: progressUpdate.okrId,
  employeeId: progressUpdate.employeeId,
  progressPercent: progressUpdate.progressPercent,
  note: progressUpdate.note,
  createdAt: progressUpdate.createdAt
});

const serializeApproval = (approval: OkrApprovalRecord) => ({
  id: approval.id,
  companyId: approval.companyId,
  okrId: approval.okrId,
  approverEmployeeId: approval.approverEmployeeId,
  status: approval.status,
  comment: approval.comment,
  createdAt: approval.createdAt,
  updatedAt: approval.updatedAt
});

const serializeOkr = (okr: OkrRecord) => ({
  id: okr.id,
  companyId: okr.companyId,
  employeeId: okr.employeeId,
  assignedById: okr.assignedById,
  title: okr.title,
  description: okr.description,
  status: okr.status,
  dueDate: okr.dueDate,
  createdAt: okr.createdAt,
  updatedAt: okr.updatedAt,
  ...(okr.employee ? { employee: serializeEmployee(okr.employee) } : {}),
  ...(okr.assignedBy ? { assignedBy: serializeEmployee(okr.assignedBy) } : {}),
  ...(okr.progressUpdates ? { progressUpdates: okr.progressUpdates.map(serializeProgressUpdate) } : {}),
  ...(okr.approvals ? { approvals: okr.approvals.map(serializeApproval) } : {})
});

const assertCompanyExists = async (companyId: string) => {
  const company = await getOkrsRepository().findCompanyById(companyId);

  if (!company) {
    throw new NotFoundError("Company not found");
  }
};

const getActorEmployeeInCompany = async (actor: AuthenticatedUser, companyId: string) => {
  const employee = await getOkrsRepository().findEmployeeByUserId(actor.id);

  return employee?.companyId === companyId ? employee : null;
};

const getRequiredActorEmployeeInCompany = async (actor: AuthenticatedUser, companyId: string) => {
  const employee = await getActorEmployeeInCompany(actor, companyId);

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

const getActiveSelfEmployee = async (actor: AuthenticatedUser) => {
  if (isSuperAdmin(actor)) {
    throw new AuthorizationError("Employee profile is required");
  }

  const employee = await getOkrsRepository().findEmployeeByUserId(actor.id);

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

const isDirectReport = (employee: Pick<OkrEmployeeProfileRecord, "managerId">, managerId: string) => employee.managerId === managerId;

const canUseAdminScope = (actor: AuthenticatedUser) => hasAnyRole(actor, ["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN"]);

const findOkrForAnyAllowedRead = async (actor: AuthenticatedUser, okrId: string, query: OkrScopeQuery) => {
  if (canUseAdminScope(actor)) {
    const companyId = getOkrScope(actor, query.companyId);
    const okr = await getOkrsRepository().findOkrByIdInCompany(okrId, companyId);

    if (!okr) {
      throw new NotFoundError("OKR not found");
    }

    return okr;
  }

  const employee = await getActiveSelfEmployee(actor);
  const okr = await getOkrsRepository().findOkrByIdInCompany(okrId, employee.companyId);

  if (!okr) {
    throw new NotFoundError("OKR not found");
  }

  if (okr.employeeId === employee.id || (hasRole(actor, "MANAGER") && okr.employee && isDirectReport(okr.employee, employee.id))) {
    return okr;
  }

  throw new AuthorizationError("OKR is outside your allowed scope");
};

const findOkrForManagerOrAdminWrite = async (actor: AuthenticatedUser, okrId: string, query: OkrScopeQuery) => {
  if (canUseAdminScope(actor)) {
    const companyId = getOkrScope(actor, query.companyId);
    const okr = await getOkrsRepository().findOkrByIdInCompany(okrId, companyId);

    if (!okr) {
      throw new NotFoundError("OKR not found");
    }

    return okr;
  }

  if (!hasRole(actor, "MANAGER")) {
    throw new AuthorizationError();
  }

  const manager = await getActiveSelfEmployee(actor);
  const okr = await getOkrsRepository().findOkrByIdInCompany(okrId, manager.companyId);

  if (!okr) {
    throw new NotFoundError("OKR not found");
  }

  if (!okr.employee || !isDirectReport(okr.employee, manager.id)) {
    throw new AuthorizationError("OKR is outside your direct reports");
  }

  return okr;
};

const syncApprovalStatus = async (okr: OkrRecord) => {
  const approvals = await getOkrsRepository().listApprovalsForOkr(okr.id, okr.companyId);
  const employeeApproved = approvals.some((approval) => approval.approverEmployeeId === okr.employeeId && approval.status === "APPROVED");
  const managerApproved = approvals.some((approval) => approval.approverEmployeeId !== okr.employeeId && approval.status === "APPROVED");

  if (employeeApproved && managerApproved && okr.status !== "APPROVED") {
    return getOkrsRepository().updateOkrStatus(okr.id, okr.companyId, "APPROVED");
  }

  if (employeeApproved && okr.status !== "APPROVED" && okr.status !== "SUBMITTED") {
    return getOkrsRepository().updateOkrStatus(okr.id, okr.companyId, "SUBMITTED");
  }

  return getOkrsRepository().findOkrByIdInCompany(okr.id, okr.companyId);
};

export const createOkr = async (actor: AuthenticatedUser, input: CreateOkrInput, auditContext: AuditRequestContext) => {
  const repository = getOkrsRepository();
  let companyId: string;
  let assigner: OkrEmployeeProfileRecord;

  if (hasRole(actor, "MANAGER") && !canUseAdminScope(actor)) {
    assigner = await getActiveSelfEmployee(actor);
    companyId = getOkrScope(actor, input.companyId);
  } else if (canUseAdminScope(actor)) {
    companyId = getOkrScope(actor, input.companyId);
    await assertCompanyExists(companyId);
    assigner = await getRequiredActorEmployeeInCompany(actor, companyId);
  } else {
    throw new AuthorizationError();
  }

  const employee = await repository.findEmployeeByIdInCompany(input.employeeId, companyId);

  if (!employee) {
    throw new NotFoundError("Employee not found");
  }

  if (employee.status !== "ACTIVE") {
    throw new AuthorizationError("Employee profile is not active");
  }

  if (hasRole(actor, "MANAGER") && !canUseAdminScope(actor) && !isDirectReport(employee, assigner.id)) {
    throw new AuthorizationError("Employee is outside your direct reports");
  }

  const okr = await repository.createOkr({
    companyId,
    employeeId: employee.id,
    assignedById: assigner.id,
    title: input.title,
    description: input.description,
    dueDate: input.dueDate
  });

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "OKR",
    action: "OKR_CREATED",
    targetType: "OKR",
    targetId: okr.id,
    metadata: { employeeId: employee.id, assignedById: assigner.id, status: okr.status },
    ...auditContext
  });

  return serializeOkr(okr);
};

export const listMyOkrs = async (actor: AuthenticatedUser, query: MyOkrsQuery) => {
  const employee = await getActiveSelfEmployee(actor);
  const okrs = await getOkrsRepository().listOkrsForEmployee(employee.id, { status: query.status });

  return okrs.map(serializeOkr);
};

export const listTeamOkrs = async (actor: AuthenticatedUser) => {
  if (!hasRole(actor, "MANAGER")) {
    throw new AuthorizationError();
  }

  const manager = await getActiveSelfEmployee(actor);
  const okrs = await getOkrsRepository().listOkrsForDirectReports(manager.id, manager.companyId);

  return okrs.map(serializeOkr);
};

export const listAdminOkrs = async (actor: AuthenticatedUser, query: AdminOkrsQuery) => {
  const repository = getOkrsRepository();
  const companyId = getOkrScope(actor, query.companyId);

  if (query.employeeId) {
    const employee = await repository.findEmployeeByIdInCompany(query.employeeId, companyId);

    if (!employee) {
      throw new NotFoundError("Employee not found");
    }
  }

  const okrs = await repository.listOkrsForCompany(companyId, {
    employeeId: query.employeeId,
    status: query.status,
    from: query.from,
    to: query.to
  });

  return okrs.map(serializeOkr);
};

export const getOkr = async (actor: AuthenticatedUser, okrId: string, query: OkrScopeQuery) => {
  const okr = await findOkrForAnyAllowedRead(actor, okrId, query);

  return serializeOkr(okr);
};

export const updateOkr = async (
  actor: AuthenticatedUser,
  okrId: string,
  input: UpdateOkrInput,
  query: OkrScopeQuery,
  auditContext: AuditRequestContext
) => {
  const okr = await findOkrForManagerOrAdminWrite(actor, okrId, query);
  const updateInput: UpdateOkrRepositoryInput = {
    title: input.title,
    description: input.description,
    dueDate: input.dueDate
  };
  const updated = await getOkrsRepository().updateOkr(okr.id, okr.companyId, updateInput);

  await recordAuditLog({
    companyId: okr.companyId,
    actorUserId: actor.id,
    category: "OKR",
    action: "OKR_UPDATED",
    targetType: "OKR",
    targetId: okr.id,
    metadata: { updatedFields: Object.keys(input), employeeId: okr.employeeId },
    ...auditContext
  });

  return serializeOkr(updated);
};

export const updateOkrStatus = async (
  actor: AuthenticatedUser,
  okrId: string,
  input: UpdateOkrStatusInput,
  query: OkrScopeQuery,
  auditContext: AuditRequestContext
) => {
  const okr = await findOkrForManagerOrAdminWrite(actor, okrId, query);
  const updated = await getOkrsRepository().updateOkrStatus(okr.id, okr.companyId, input.status);

  await recordAuditLog({
    companyId: okr.companyId,
    actorUserId: actor.id,
    category: "OKR",
    action: "OKR_STATUS_CHANGED",
    targetType: "OKR",
    targetId: okr.id,
    metadata: { previousStatus: okr.status, status: updated.status, employeeId: okr.employeeId },
    ...auditContext
  });

  return serializeOkr(updated);
};

export const createOkrProgress = async (
  actor: AuthenticatedUser,
  okrId: string,
  input: CreateOkrProgressInput,
  auditContext: AuditRequestContext
) => {
  const employee = await getActiveSelfEmployee(actor);
  const okr = await getOkrsRepository().findOkrByIdInCompany(okrId, employee.companyId);

  if (!okr) {
    throw new NotFoundError("OKR not found");
  }

  if (okr.employeeId !== employee.id) {
    throw new AuthorizationError("OKR progress updates are self-service only");
  }

  const progressUpdate = await getOkrsRepository().createProgressUpdate({
    companyId: okr.companyId,
    okrId: okr.id,
    employeeId: employee.id,
    progressPercent: input.progressPercent,
    note: input.note
  });

  let updatedOkr: OkrRecord | null = okr;

  if (okr.status === "ASSIGNED" && input.progressPercent > 0) {
    updatedOkr = await getOkrsRepository().updateOkrStatus(okr.id, okr.companyId, "IN_PROGRESS");
  }

  await recordAuditLog({
    companyId: okr.companyId,
    actorUserId: actor.id,
    category: "OKR",
    action: "OKR_PROGRESS_UPDATED",
    targetType: "OKRProgressUpdate",
    targetId: progressUpdate.id,
    metadata: { okrId: okr.id, employeeId: employee.id, progressPercent: input.progressPercent },
    ...auditContext
  });

  return {
    okr: serializeOkr(updatedOkr ?? okr),
    progressUpdate: serializeProgressUpdate(progressUpdate)
  };
};

export const employeeApproveOkr = async (
  actor: AuthenticatedUser,
  okrId: string,
  input: OkrApprovalInput,
  auditContext: AuditRequestContext
) => {
  const employee = await getActiveSelfEmployee(actor);
  const okr = await getOkrsRepository().findOkrByIdInCompany(okrId, employee.companyId);

  if (!okr) {
    throw new NotFoundError("OKR not found");
  }

  if (okr.employeeId !== employee.id) {
    throw new AuthorizationError("Employee approval is self-service only");
  }

  const approval = await getOkrsRepository().upsertApproval({
    companyId: okr.companyId,
    okrId: okr.id,
    approverEmployeeId: employee.id,
    status: "APPROVED",
    comment: input.comment
  });
  const synced = await syncApprovalStatus(okr);

  await recordAuditLog({
    companyId: okr.companyId,
    actorUserId: actor.id,
    category: "OKR",
    action: "OKR_EMPLOYEE_APPROVAL_SUBMITTED",
    targetType: "OKRApproval",
    targetId: approval.id,
    metadata: { okrId: okr.id, employeeId: employee.id },
    ...auditContext
  });

  return {
    okr: serializeOkr(synced ?? okr),
    approval: serializeApproval(approval)
  };
};

export const managerApproveOkr = async (
  actor: AuthenticatedUser,
  okrId: string,
  input: OkrApprovalInput,
  query: OkrScopeQuery,
  auditContext: AuditRequestContext
) => {
  const okr = await findOkrForManagerOrAdminWrite(actor, okrId, query);
  const approver = await getRequiredActorEmployeeInCompany(actor, okr.companyId);

  if (approver.id === okr.employeeId) {
    throw new AuthorizationError("Employees cannot manager-approve their own OKR");
  }

  const approval = await getOkrsRepository().upsertApproval({
    companyId: okr.companyId,
    okrId: okr.id,
    approverEmployeeId: approver.id,
    status: "APPROVED",
    comment: input.comment
  });
  const synced = await syncApprovalStatus(okr);

  await recordAuditLog({
    companyId: okr.companyId,
    actorUserId: actor.id,
    category: "OKR",
    action: "OKR_MANAGER_APPROVAL_SUBMITTED",
    targetType: "OKRApproval",
    targetId: approval.id,
    metadata: { okrId: okr.id, employeeId: okr.employeeId, approverEmployeeId: approver.id },
    ...auditContext
  });

  return {
    okr: serializeOkr(synced ?? okr),
    approval: serializeApproval(approval)
  };
};
