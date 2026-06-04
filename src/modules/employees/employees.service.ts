import type { EmployeeStatus, RoleName, UserStatus } from "@prisma/client";

import { getRequiredScopedCompanyId, hasRole, isSuperAdmin } from "../../lib/authorization";
import { recordAuditLog, type AuditRequestContext } from "../../lib/audit";
import { hashPassword } from "../../lib/password";
import { AuthorizationError, ConflictError, NotFoundError, ValidationError } from "../../lib/errors";
import type { AuthenticatedUser, Role } from "../../types/auth";
import {
  getEmployeesRepository,
  type EmployeeRecord,
  type UpdateEmployeeRepositoryInput
} from "./employees.repository";
import type {
  CreateEmployeeInput,
  EmployeeScopeQuery,
  UpdateEmployeeInput,
  UpdateEmployeeManagerInput,
  UpdateEmployeeStatusInput
} from "./employees.validation";

const allowedEmployeeCreationRoles = new Set<RoleName>(["EMPLOYEE", "MANAGER", "HR_ADMIN", "COMPANY_ADMIN"]);

const getEmployeeScope = (actor: AuthenticatedUser, requestedCompanyId?: string | null) =>
  getRequiredScopedCompanyId(actor, requestedCompanyId);

const normalizeRoles = (input: Pick<CreateEmployeeInput, "role" | "roles">): RoleName[] => [
  ...new Set(input.roles ?? (input.role ? [input.role] : []))
];

const assertRolesCanBeAssigned = (actor: AuthenticatedUser, roles: RoleName[]) => {
  for (const role of roles) {
    if (!allowedEmployeeCreationRoles.has(role)) {
      throw new AuthorizationError("Role assignment is not allowed");
    }

    if (role === "COMPANY_ADMIN" && !isSuperAdmin(actor) && !hasRole(actor, "COMPANY_ADMIN")) {
      throw new AuthorizationError("Role assignment is not allowed");
    }
  }
};

const employeeStatusToUserStatus = (status: EmployeeStatus): UserStatus => {
  if (status === "ACTIVE" || status === "ON_LEAVE") {
    return "ACTIVE";
  }

  return "DISABLED";
};

const assertCompanyExists = async (companyId: string) => {
  const company = await getEmployeesRepository().findCompanyById(companyId);

  if (!company) {
    throw new NotFoundError("Company not found");
  }
};

const assertDepartmentInCompany = async (departmentId: string | null | undefined, companyId: string) => {
  if (!departmentId) {
    return;
  }

  const department = await getEmployeesRepository().findDepartmentByIdInCompany(departmentId, companyId);

  if (!department) {
    throw new AuthorizationError("Department is outside the resolved company scope");
  }
};

const assertDesignationInCompany = async (designationId: string | null | undefined, companyId: string) => {
  if (!designationId) {
    return;
  }

  const designation = await getEmployeesRepository().findDesignationByIdInCompany(designationId, companyId);

  if (!designation) {
    throw new AuthorizationError("Designation is outside the resolved company scope");
  }
};

const assertManagerInCompany = async (managerId: string | null | undefined, companyId: string, employeeId?: string) => {
  if (!managerId) {
    return;
  }

  if (employeeId && managerId === employeeId) {
    throw new ValidationError("Manager cannot be the employee itself", undefined, 400);
  }

  const manager = await getEmployeesRepository().findByIdInCompany(managerId, companyId);

  if (!manager) {
    throw new AuthorizationError("Manager is outside the resolved company scope");
  }
};

export const serializeEmployee = (employee: EmployeeRecord) => ({
  id: employee.id,
  companyId: employee.companyId,
  userId: employee.userId,
  email: employee.user.email,
  roles: employee.user.roles,
  userStatus: employee.user.status,
  departmentId: employee.departmentId,
  designationId: employee.designationId,
  managerId: employee.managerId,
  employeeCode: employee.employeeCode,
  firstName: employee.firstName,
  lastName: employee.lastName,
  phone: employee.phone,
  status: employee.status,
  hireDate: employee.hireDate,
  department: employee.department,
  designation: employee.designation,
  manager: employee.manager,
  createdAt: employee.createdAt,
  updatedAt: employee.updatedAt
});

export const createEmployee = async (
  actor: AuthenticatedUser,
  input: CreateEmployeeInput,
  auditContext: AuditRequestContext
) => {
  const repository = getEmployeesRepository();
  const companyId = getEmployeeScope(actor, input.companyId);
  const roles = normalizeRoles(input);

  assertRolesCanBeAssigned(actor, roles);
  await assertCompanyExists(companyId);
  await assertDepartmentInCompany(input.departmentId, companyId);
  await assertDesignationInCompany(input.designationId, companyId);
  await assertManagerInCompany(input.managerId, companyId);

  const existingUser = await repository.findUserByEmail(input.email);

  if (existingUser) {
    throw new ConflictError("Email already exists");
  }

  const existingEmployeeCode = await repository.findEmployeeCodeInCompany(input.employeeCode, companyId);

  if (existingEmployeeCode) {
    throw new ConflictError("Employee code already exists in this company");
  }

  const passwordHash = await hashPassword(input.temporaryPassword);
  const employee = await repository.create({
    companyId,
    email: input.email,
    passwordHash,
    roles,
    employeeCode: input.employeeCode,
    firstName: input.firstName,
    lastName: input.lastName,
    phone: input.phone ?? null,
    departmentId: input.departmentId ?? null,
    designationId: input.designationId ?? null,
    managerId: input.managerId ?? null,
    hireDate: input.hireDate ?? null
  });

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "EMPLOYEE",
    action: "EMPLOYEE_CREATED",
    targetType: "EmployeeProfile",
    targetId: employee.id,
    metadata: {
      employeeCode: employee.employeeCode,
      email: employee.user.email,
      roles
    },
    ...auditContext
  });

  return serializeEmployee(employee);
};

export const listEmployees = async (actor: AuthenticatedUser, query: EmployeeScopeQuery) => {
  const companyId = getEmployeeScope(actor, query.companyId);
  const employees = await getEmployeesRepository().list(companyId);

  return employees.map(serializeEmployee);
};

export const getEmployee = async (actor: AuthenticatedUser, employeeId: string, query: EmployeeScopeQuery = {}) => {
  const companyId = getEmployeeScope(actor, query.companyId);
  const employee = await getEmployeesRepository().findByIdInCompany(employeeId, companyId);

  if (!employee) {
    throw new NotFoundError("Employee not found");
  }

  return serializeEmployee(employee);
};

export const getMyEmployeeProfile = async (actor: AuthenticatedUser) => {
  const employee = await getEmployeesRepository().findByUserId(actor.id);

  if (!employee) {
    throw new NotFoundError("Employee profile not found");
  }

  return serializeEmployee(employee);
};

export const updateEmployee = async (
  actor: AuthenticatedUser,
  employeeId: string,
  input: UpdateEmployeeInput,
  query: EmployeeScopeQuery,
  auditContext: AuditRequestContext
) => {
  const repository = getEmployeesRepository();
  const companyId = getEmployeeScope(actor, query.companyId);
  const current = await repository.findByIdInCompany(employeeId, companyId);

  if (!current) {
    throw new NotFoundError("Employee not found");
  }

  if (input.employeeCode && input.employeeCode !== current.employeeCode) {
    const existingEmployeeCode = await repository.findEmployeeCodeInCompany(input.employeeCode, companyId);

    if (existingEmployeeCode && existingEmployeeCode.id !== employeeId) {
      throw new ConflictError("Employee code already exists in this company");
    }
  }

  if (Object.prototype.hasOwnProperty.call(input, "departmentId")) {
    await assertDepartmentInCompany(input.departmentId, companyId);
  }

  if (Object.prototype.hasOwnProperty.call(input, "designationId")) {
    await assertDesignationInCompany(input.designationId, companyId);
  }

  const updateInput: UpdateEmployeeRepositoryInput = {
    employeeCode: input.employeeCode,
    firstName: input.firstName,
    lastName: input.lastName,
    phone: Object.prototype.hasOwnProperty.call(input, "phone") ? input.phone ?? null : undefined,
    departmentId: Object.prototype.hasOwnProperty.call(input, "departmentId") ? input.departmentId ?? null : undefined,
    designationId: Object.prototype.hasOwnProperty.call(input, "designationId")
      ? input.designationId ?? null
      : undefined,
    hireDate: Object.prototype.hasOwnProperty.call(input, "hireDate") ? input.hireDate ?? null : undefined
  };
  const employee = await repository.update(employeeId, companyId, updateInput);

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "EMPLOYEE",
    action: "EMPLOYEE_UPDATED",
    targetType: "EmployeeProfile",
    targetId: employee.id,
    metadata: { updatedFields: Object.keys(input) },
    ...auditContext
  });

  return serializeEmployee(employee);
};

export const updateEmployeeStatus = async (
  actor: AuthenticatedUser,
  employeeId: string,
  input: UpdateEmployeeStatusInput,
  query: EmployeeScopeQuery,
  auditContext: AuditRequestContext
) => {
  const repository = getEmployeesRepository();
  const companyId = getEmployeeScope(actor, query.companyId);
  const current = await repository.findByIdInCompany(employeeId, companyId);

  if (!current) {
    throw new NotFoundError("Employee not found");
  }

  const userStatus = employeeStatusToUserStatus(input.status);
  const employee = await repository.updateStatus(employeeId, companyId, input.status, userStatus);

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "EMPLOYEE",
    action: "EMPLOYEE_STATUS_CHANGED",
    targetType: "EmployeeProfile",
    targetId: employee.id,
    metadata: {
      previousStatus: current.status,
      status: employee.status,
      userStatus: employee.user.status
    },
    ...auditContext
  });

  return serializeEmployee(employee);
};

export const updateEmployeeManager = async (
  actor: AuthenticatedUser,
  employeeId: string,
  input: UpdateEmployeeManagerInput,
  query: EmployeeScopeQuery,
  auditContext: AuditRequestContext
) => {
  const repository = getEmployeesRepository();
  const companyId = getEmployeeScope(actor, query.companyId);
  const current = await repository.findByIdInCompany(employeeId, companyId);

  if (!current) {
    throw new NotFoundError("Employee not found");
  }

  await assertManagerInCompany(input.managerId, companyId, employeeId);

  const employee = await repository.updateManager(employeeId, companyId, input.managerId ?? null);

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "EMPLOYEE",
    action: "EMPLOYEE_MANAGER_CHANGED",
    targetType: "EmployeeProfile",
    targetId: employee.id,
    metadata: {
      previousManagerId: current.managerId,
      managerId: employee.managerId
    },
    ...auditContext
  });

  return serializeEmployee(employee);
};
