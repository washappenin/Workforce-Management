import { getRequiredScopedCompanyId } from "../../lib/authorization";
import { recordAuditLog, type AuditRequestContext } from "../../lib/audit";
import { AuthorizationError, ConflictError, NotFoundError, ValidationError } from "../../lib/errors";
import type { AuthenticatedUser } from "../../types/auth";
import {
  getShiftsRepository,
  type ShiftAssignmentRecord,
  type ShiftRecord,
  type UpdateShiftAssignmentRepositoryInput,
  type UpdateShiftRepositoryInput
} from "./shifts.repository";
import type {
  AssignShiftInput,
  CreateShiftInput,
  ShiftScopeQuery,
  UpdateShiftAssignmentInput,
  UpdateShiftInput,
  UpdateShiftStatusInput
} from "./shifts.validation";

const getShiftScope = (actor: AuthenticatedUser, requestedCompanyId?: string | null) =>
  getRequiredScopedCompanyId(actor, requestedCompanyId);

const startOfTodayUtc = () => {
  const now = new Date();
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
};

const serializeShift = (shift: ShiftRecord) => ({
  id: shift.id,
  companyId: shift.companyId,
  name: shift.name,
  startTime: shift.startTime,
  endTime: shift.endTime,
  status: shift.status,
  createdAt: shift.createdAt,
  updatedAt: shift.updatedAt
});

const serializeAssignment = (assignment: ShiftAssignmentRecord) => ({
  id: assignment.id,
  companyId: assignment.companyId,
  employeeId: assignment.employeeId,
  shiftId: assignment.shiftId,
  startsOn: assignment.startsOn,
  endsOn: assignment.endsOn,
  createdAt: assignment.createdAt,
  updatedAt: assignment.updatedAt,
  ...(assignment.shift ? { shift: serializeShift(assignment.shift) } : {})
});

const assertCompanyExists = async (companyId: string) => {
  const company = await getShiftsRepository().findCompanyById(companyId);

  if (!company) {
    throw new NotFoundError("Company not found");
  }
};

const assertAssignmentDates = (startsOn: Date, endsOn: Date | null | undefined) => {
  if (endsOn && endsOn < startsOn) {
    throw new ValidationError("endsOn must be on or after startsOn", undefined, 400);
  }
};

const assertNoOverlappingAssignment = async (input: {
  companyId: string;
  employeeId: string;
  shiftId: string;
  startsOn: Date;
  endsOn?: Date | null;
  excludeAssignmentId?: string;
}) => {
  const overlapping = await getShiftsRepository().findOverlappingAssignment(input);

  if (overlapping) {
    throw new ConflictError("Overlapping shift assignment already exists for this employee and shift");
  }
};

export const createShift = async (
  actor: AuthenticatedUser,
  input: CreateShiftInput,
  auditContext: AuditRequestContext
) => {
  const repository = getShiftsRepository();
  const companyId = getShiftScope(actor, input.companyId);

  await assertCompanyExists(companyId);

  const existing = await repository.findShiftByNameInCompany(input.name, companyId);

  if (existing) {
    throw new ConflictError("Shift name already exists in this company");
  }

  const shift = await repository.createShift({
    companyId,
    name: input.name,
    startTime: input.startTime,
    endTime: input.endTime
  });

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "SHIFT",
    action: "SHIFT_CREATED",
    targetType: "Shift",
    targetId: shift.id,
    metadata: { name: shift.name, startTime: shift.startTime, endTime: shift.endTime, status: shift.status },
    ...auditContext
  });

  return serializeShift(shift);
};

export const listShifts = async (actor: AuthenticatedUser, query: ShiftScopeQuery) => {
  const companyId = getShiftScope(actor, query.companyId);
  const shifts = await getShiftsRepository().listShifts(companyId);

  return shifts.map(serializeShift);
};

export const getShift = async (actor: AuthenticatedUser, shiftId: string, query: ShiftScopeQuery) => {
  const companyId = getShiftScope(actor, query.companyId);
  const shift = await getShiftsRepository().findShiftByIdInCompany(shiftId, companyId);

  if (!shift) {
    throw new NotFoundError("Shift not found");
  }

  return serializeShift(shift);
};

export const updateShift = async (
  actor: AuthenticatedUser,
  shiftId: string,
  input: UpdateShiftInput,
  query: ShiftScopeQuery,
  auditContext: AuditRequestContext
) => {
  const repository = getShiftsRepository();
  const companyId = getShiftScope(actor, query.companyId);
  const current = await repository.findShiftByIdInCompany(shiftId, companyId);

  if (!current) {
    throw new NotFoundError("Shift not found");
  }

  if (input.name && input.name !== current.name) {
    const existing = await repository.findShiftByNameInCompany(input.name, companyId);

    if (existing && existing.id !== shiftId) {
      throw new ConflictError("Shift name already exists in this company");
    }
  }

  const updateInput: UpdateShiftRepositoryInput = {
    name: input.name,
    startTime: input.startTime,
    endTime: input.endTime
  };
  const shift = await repository.updateShift(shiftId, companyId, updateInput);

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "SHIFT",
    action: "SHIFT_UPDATED",
    targetType: "Shift",
    targetId: shift.id,
    metadata: { updatedFields: Object.keys(input) },
    ...auditContext
  });

  return serializeShift(shift);
};

export const updateShiftStatus = async (
  actor: AuthenticatedUser,
  shiftId: string,
  input: UpdateShiftStatusInput,
  query: ShiftScopeQuery,
  auditContext: AuditRequestContext
) => {
  const repository = getShiftsRepository();
  const companyId = getShiftScope(actor, query.companyId);
  const current = await repository.findShiftByIdInCompany(shiftId, companyId);

  if (!current) {
    throw new NotFoundError("Shift not found");
  }

  const shift = await repository.updateShiftStatus(shiftId, companyId, input.status);

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "SHIFT",
    action: "SHIFT_STATUS_CHANGED",
    targetType: "Shift",
    targetId: shift.id,
    metadata: { previousStatus: current.status, status: shift.status },
    ...auditContext
  });

  return serializeShift(shift);
};

export const assignShift = async (
  actor: AuthenticatedUser,
  shiftId: string,
  input: AssignShiftInput,
  query: ShiftScopeQuery,
  auditContext: AuditRequestContext
) => {
  const repository = getShiftsRepository();
  const companyId = getShiftScope(actor, query.companyId);
  const shift = await repository.findShiftByIdInCompany(shiftId, companyId);

  if (!shift) {
    throw new NotFoundError("Shift not found");
  }

  if (shift.status !== "ACTIVE") {
    throw new ValidationError("Shift must be active before assignment", undefined, 400);
  }

  const employee = await repository.findEmployeeByIdInCompany(input.employeeId, companyId);

  if (!employee) {
    throw new NotFoundError("Employee not found");
  }

  if (employee.status !== "ACTIVE") {
    throw new ValidationError("Employee must be active before shift assignment", undefined, 400);
  }

  if (employee.companyStatus !== "ACTIVE") {
    throw new AuthorizationError("Company is not active");
  }

  assertAssignmentDates(input.startsOn, input.endsOn);
  await assertNoOverlappingAssignment({
    companyId,
    employeeId: employee.id,
    shiftId: shift.id,
    startsOn: input.startsOn,
    endsOn: input.endsOn
  });

  const assignment = await repository.createAssignment({
    companyId,
    employeeId: employee.id,
    shiftId: shift.id,
    startsOn: input.startsOn,
    endsOn: input.endsOn
  });

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "SHIFT",
    action: "SHIFT_ASSIGNED",
    targetType: "EmployeeShiftAssignment",
    targetId: assignment.id,
    metadata: { employeeId: employee.id, shiftId: shift.id, startsOn: assignment.startsOn, endsOn: assignment.endsOn },
    ...auditContext
  });

  return serializeAssignment(assignment);
};

export const listShiftAssignments = async (actor: AuthenticatedUser, shiftId: string, query: ShiftScopeQuery) => {
  const companyId = getShiftScope(actor, query.companyId);
  const shift = await getShiftsRepository().findShiftByIdInCompany(shiftId, companyId);

  if (!shift) {
    throw new NotFoundError("Shift not found");
  }

  const assignments = await getShiftsRepository().listAssignmentsForShift(shift.id, companyId);

  return assignments.map(serializeAssignment);
};

export const updateShiftAssignment = async (
  actor: AuthenticatedUser,
  assignmentId: string,
  input: UpdateShiftAssignmentInput,
  query: ShiftScopeQuery,
  auditContext: AuditRequestContext
) => {
  const repository = getShiftsRepository();
  const companyId = getShiftScope(actor, query.companyId);
  const current = await repository.findAssignmentByIdInCompany(assignmentId, companyId);

  if (!current) {
    throw new NotFoundError("Shift assignment not found");
  }

  const startsOn = input.startsOn ?? current.startsOn;
  const endsOn = input.endsOn !== undefined ? input.endsOn : current.endsOn;

  assertAssignmentDates(startsOn, endsOn);
  await assertNoOverlappingAssignment({
    companyId,
    employeeId: current.employeeId,
    shiftId: current.shiftId,
    startsOn,
    endsOn,
    excludeAssignmentId: current.id
  });

  const updateInput: UpdateShiftAssignmentRepositoryInput = {
    startsOn: input.startsOn,
    endsOn: input.endsOn
  };
  const assignment = await repository.updateAssignment(assignmentId, companyId, updateInput);

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "SHIFT",
    action: "SHIFT_ASSIGNMENT_UPDATED",
    targetType: "EmployeeShiftAssignment",
    targetId: assignment.id,
    metadata: { updatedFields: Object.keys(input), employeeId: assignment.employeeId, shiftId: assignment.shiftId },
    ...auditContext
  });

  return serializeAssignment(assignment);
};

export const deleteShiftAssignment = async (
  actor: AuthenticatedUser,
  assignmentId: string,
  query: ShiftScopeQuery,
  auditContext: AuditRequestContext
) => {
  const repository = getShiftsRepository();
  const companyId = getShiftScope(actor, query.companyId);
  const current = await repository.findAssignmentByIdInCompany(assignmentId, companyId);

  if (!current) {
    throw new NotFoundError("Shift assignment not found");
  }

  await repository.deleteAssignment(assignmentId, companyId);

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "SHIFT",
    action: "SHIFT_ASSIGNMENT_REMOVED",
    targetType: "EmployeeShiftAssignment",
    targetId: current.id,
    metadata: { employeeId: current.employeeId, shiftId: current.shiftId },
    ...auditContext
  });

  return { success: true };
};

export const listMyShiftAssignments = async (actor: AuthenticatedUser) => {
  const employee = await getShiftsRepository().findEmployeeByUserId(actor.id);

  if (!employee) {
    throw new AuthorizationError("Employee profile is required");
  }

  if (employee.status !== "ACTIVE") {
    throw new AuthorizationError("Employee profile is not active");
  }

  if (employee.companyStatus !== "ACTIVE") {
    throw new AuthorizationError("Company is not active");
  }

  const assignments = await getShiftsRepository().listAssignmentsForEmployeeCurrentOrFuture(
    employee.id,
    employee.companyId,
    startOfTodayUtc()
  );

  return assignments.map(serializeAssignment);
};
