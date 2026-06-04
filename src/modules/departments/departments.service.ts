import { getRequiredScopedCompanyId } from "../../lib/authorization";
import { recordAuditLog, type AuditRequestContext } from "../../lib/audit";
import { ConflictError, NotFoundError } from "../../lib/errors";
import type { AuthenticatedUser } from "../../types/auth";
import {
  getDepartmentsRepository,
  type DepartmentRecord,
  type UpdateDepartmentRepositoryInput
} from "./departments.repository";
import type {
  CreateDepartmentInput,
  DepartmentScopeQuery,
  UpdateDepartmentInput,
  UpdateDepartmentStatusInput
} from "./departments.validation";

const getDepartmentScope = (actor: AuthenticatedUser, requestedCompanyId?: string | null) =>
  getRequiredScopedCompanyId(actor, requestedCompanyId);

export const serializeDepartment = (department: DepartmentRecord) => ({
  id: department.id,
  companyId: department.companyId,
  name: department.name,
  isActive: department.isActive,
  createdAt: department.createdAt,
  updatedAt: department.updatedAt
});

export const createDepartment = async (
  actor: AuthenticatedUser,
  input: CreateDepartmentInput,
  auditContext: AuditRequestContext
) => {
  const repository = getDepartmentsRepository();
  const companyId = getDepartmentScope(actor, input.companyId);
  const existing = await repository.findByNameInCompany(input.name, companyId);

  if (existing) {
    throw new ConflictError("Department name already exists in this company");
  }

  const department = await repository.create({
    companyId,
    name: input.name,
    isActive: input.isActive
  });

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "COMPANY",
    action: "DEPARTMENT_CREATED",
    targetType: "Department",
    targetId: department.id,
    metadata: { name: department.name },
    ...auditContext
  });

  return serializeDepartment(department);
};

export const listDepartments = async (actor: AuthenticatedUser, query: DepartmentScopeQuery) => {
  const companyId = getDepartmentScope(actor, query.companyId);
  const departments = await getDepartmentsRepository().list(companyId);

  return departments.map(serializeDepartment);
};

export const getDepartment = async (
  actor: AuthenticatedUser,
  departmentId: string,
  query: DepartmentScopeQuery = {}
) => {
  const companyId = getDepartmentScope(actor, query.companyId);
  const department = await getDepartmentsRepository().findByIdInCompany(departmentId, companyId);

  if (!department) {
    throw new NotFoundError("Department not found");
  }

  return serializeDepartment(department);
};

export const updateDepartment = async (
  actor: AuthenticatedUser,
  departmentId: string,
  input: UpdateDepartmentInput,
  query: DepartmentScopeQuery,
  auditContext: AuditRequestContext
) => {
  const repository = getDepartmentsRepository();
  const companyId = getDepartmentScope(actor, query.companyId);
  const current = await repository.findByIdInCompany(departmentId, companyId);

  if (!current) {
    throw new NotFoundError("Department not found");
  }

  if (input.name && input.name !== current.name) {
    const existing = await repository.findByNameInCompany(input.name, companyId);

    if (existing && existing.id !== departmentId) {
      throw new ConflictError("Department name already exists in this company");
    }
  }

  const updateInput: UpdateDepartmentRepositoryInput = { name: input.name };
  const department = await repository.update(departmentId, companyId, updateInput);

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "COMPANY",
    action: "DEPARTMENT_UPDATED",
    targetType: "Department",
    targetId: department.id,
    metadata: { updatedFields: Object.keys(input) },
    ...auditContext
  });

  return serializeDepartment(department);
};

export const updateDepartmentStatus = async (
  actor: AuthenticatedUser,
  departmentId: string,
  input: UpdateDepartmentStatusInput,
  query: DepartmentScopeQuery,
  auditContext: AuditRequestContext
) => {
  const repository = getDepartmentsRepository();
  const companyId = getDepartmentScope(actor, query.companyId);
  const current = await repository.findByIdInCompany(departmentId, companyId);

  if (!current) {
    throw new NotFoundError("Department not found");
  }

  const department = await repository.updateStatus(departmentId, companyId, input.isActive);

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "COMPANY",
    action: "DEPARTMENT_STATUS_CHANGED",
    targetType: "Department",
    targetId: department.id,
    metadata: { previousIsActive: current.isActive, isActive: department.isActive },
    ...auditContext
  });

  return serializeDepartment(department);
};
