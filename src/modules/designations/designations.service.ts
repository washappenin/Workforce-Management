import { getRequiredScopedCompanyId } from "../../lib/authorization";
import { recordAuditLog, type AuditRequestContext } from "../../lib/audit";
import { AuthorizationError, ConflictError, NotFoundError } from "../../lib/errors";
import type { AuthenticatedUser } from "../../types/auth";
import { getDepartmentsRepository } from "../departments/departments.repository";
import {
  getDesignationsRepository,
  type DesignationRecord,
  type UpdateDesignationRepositoryInput
} from "./designations.repository";
import type {
  CreateDesignationInput,
  DesignationScopeQuery,
  UpdateDesignationInput,
  UpdateDesignationStatusInput
} from "./designations.validation";

const getDesignationScope = (actor: AuthenticatedUser, requestedCompanyId?: string | null) =>
  getRequiredScopedCompanyId(actor, requestedCompanyId);

const assertDepartmentInCompany = async (departmentId: string | null | undefined, companyId: string) => {
  if (!departmentId) {
    return;
  }

  const department = await getDepartmentsRepository().findByIdInCompany(departmentId, companyId);

  if (!department) {
    throw new AuthorizationError("Department is outside the resolved company scope");
  }
};

export const serializeDesignation = (designation: DesignationRecord) => ({
  id: designation.id,
  companyId: designation.companyId,
  departmentId: designation.departmentId,
  title: designation.title,
  isActive: designation.isActive,
  createdAt: designation.createdAt,
  updatedAt: designation.updatedAt
});

export const createDesignation = async (
  actor: AuthenticatedUser,
  input: CreateDesignationInput,
  auditContext: AuditRequestContext
) => {
  const repository = getDesignationsRepository();
  const companyId = getDesignationScope(actor, input.companyId);
  const existing = await repository.findByTitleInCompany(input.title, companyId);

  if (existing) {
    throw new ConflictError("Designation title already exists in this company");
  }

  await assertDepartmentInCompany(input.departmentId, companyId);

  const designation = await repository.create({
    companyId,
    title: input.title,
    departmentId: input.departmentId ?? null,
    isActive: input.isActive
  });

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "COMPANY",
    action: "DESIGNATION_CREATED",
    targetType: "Designation",
    targetId: designation.id,
    metadata: { title: designation.title, departmentId: designation.departmentId },
    ...auditContext
  });

  return serializeDesignation(designation);
};

export const listDesignations = async (actor: AuthenticatedUser, query: DesignationScopeQuery) => {
  const companyId = getDesignationScope(actor, query.companyId);
  const designations = await getDesignationsRepository().list(companyId);

  return designations.map(serializeDesignation);
};

export const getDesignation = async (
  actor: AuthenticatedUser,
  designationId: string,
  query: DesignationScopeQuery = {}
) => {
  const companyId = getDesignationScope(actor, query.companyId);
  const designation = await getDesignationsRepository().findByIdInCompany(designationId, companyId);

  if (!designation) {
    throw new NotFoundError("Designation not found");
  }

  return serializeDesignation(designation);
};

export const updateDesignation = async (
  actor: AuthenticatedUser,
  designationId: string,
  input: UpdateDesignationInput,
  query: DesignationScopeQuery,
  auditContext: AuditRequestContext
) => {
  const repository = getDesignationsRepository();
  const companyId = getDesignationScope(actor, query.companyId);
  const current = await repository.findByIdInCompany(designationId, companyId);

  if (!current) {
    throw new NotFoundError("Designation not found");
  }

  if (input.title && input.title !== current.title) {
    const existing = await repository.findByTitleInCompany(input.title, companyId);

    if (existing && existing.id !== designationId) {
      throw new ConflictError("Designation title already exists in this company");
    }
  }

  if (Object.prototype.hasOwnProperty.call(input, "departmentId")) {
    await assertDepartmentInCompany(input.departmentId, companyId);
  }

  const updateInput: UpdateDesignationRepositoryInput = {
    title: input.title,
    departmentId: Object.prototype.hasOwnProperty.call(input, "departmentId") ? input.departmentId ?? null : undefined
  };
  const designation = await repository.update(designationId, companyId, updateInput);

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "COMPANY",
    action: "DESIGNATION_UPDATED",
    targetType: "Designation",
    targetId: designation.id,
    metadata: { updatedFields: Object.keys(input) },
    ...auditContext
  });

  return serializeDesignation(designation);
};

export const updateDesignationStatus = async (
  actor: AuthenticatedUser,
  designationId: string,
  input: UpdateDesignationStatusInput,
  query: DesignationScopeQuery,
  auditContext: AuditRequestContext
) => {
  const repository = getDesignationsRepository();
  const companyId = getDesignationScope(actor, query.companyId);
  const current = await repository.findByIdInCompany(designationId, companyId);

  if (!current) {
    throw new NotFoundError("Designation not found");
  }

  const designation = await repository.updateStatus(designationId, companyId, input.isActive);

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "COMPANY",
    action: "DESIGNATION_STATUS_CHANGED",
    targetType: "Designation",
    targetId: designation.id,
    metadata: { previousIsActive: current.isActive, isActive: designation.isActive },
    ...auditContext
  });

  return serializeDesignation(designation);
};
