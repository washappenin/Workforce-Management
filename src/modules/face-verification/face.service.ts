import type { FaceEnrollmentStatus } from "@prisma/client";

import { getRequiredScopedCompanyId, isSuperAdmin } from "../../lib/authorization";
import { recordAuditLog, type AuditRequestContext } from "../../lib/audit";
import { createFaceVerificationReference, getFaceProvider } from "../../lib/faceMatch";
import { AuthorizationError, NotFoundError, ValidationError } from "../../lib/errors";
import type { AuthenticatedUser } from "../../types/auth";
import {
  getFaceRepository,
  type FaceEmployeeProfileRecord,
  type FaceEnrollmentRecord
} from "./face.repository";
import type {
  FaceScopeQuery,
  UpdateFaceEnrollmentStatusInput,
  UpsertFaceEnrollmentInput,
  VerifyFaceInput
} from "./face.validation";

const getFaceScope = (actor: AuthenticatedUser, requestedCompanyId?: string | null) =>
  getRequiredScopedCompanyId(actor, requestedCompanyId);

const enrolledAtForStatus = (status: FaceEnrollmentStatus) => (status === "ACTIVE" ? new Date() : null);

const serializeFaceEnrollmentStatus = (enrollment: FaceEnrollmentRecord | null) => {
  if (!enrollment) {
    return {
      status: "NOT_ENROLLED" as const,
      enrolledAt: null
    };
  }

  return {
    id: enrollment.id,
    employeeId: enrollment.employeeId,
    companyId: enrollment.companyId,
    provider: enrollment.provider,
    status: enrollment.status,
    enrolledAt: enrollment.enrolledAt,
    createdAt: enrollment.createdAt,
    updatedAt: enrollment.updatedAt
  };
};

const getAdminEmployee = async (actor: AuthenticatedUser, employeeId: string, requestedCompanyId?: string | null) => {
  const companyId = getFaceScope(actor, requestedCompanyId);
  const employee = await getFaceRepository().findEmployeeByIdInCompany(employeeId, companyId);

  if (!employee) {
    throw new NotFoundError("Employee not found");
  }

  return employee;
};

const getSelfEmployee = async (actor: AuthenticatedUser): Promise<FaceEmployeeProfileRecord> => {
  if (isSuperAdmin(actor)) {
    throw new AuthorizationError("Employee profile is required");
  }

  const employee = await getFaceRepository().findEmployeeByUserId(actor.id);

  if (!employee) {
    throw new AuthorizationError("Employee profile is required");
  }

  if (employee.status !== "ACTIVE") {
    throw new AuthorizationError("Employee profile is not active");
  }

  return employee;
};

export const upsertFaceEnrollment = async (
  actor: AuthenticatedUser,
  employeeId: string,
  input: UpsertFaceEnrollmentInput,
  auditContext: AuditRequestContext
) => {
  const repository = getFaceRepository();
  const employee = await getAdminEmployee(actor, employeeId, input.companyId);
  const existing = await repository.findEnrollmentByEmployeeInCompany(employee.id, employee.companyId);
  const provider = getFaceProvider(input.provider);
  const providerResult = await provider.enroll({
    employeeId: employee.id,
    providerSubjectId: input.providerSubjectId ?? null,
    templateReference: input.templateReference ?? null
  });
  const enrollment = await repository.upsertEnrollment({
    companyId: employee.companyId,
    employeeId: employee.id,
    provider: provider.name,
    providerSubjectId: providerResult.providerSubjectId,
    templateReference: providerResult.templateReference,
    status: "ACTIVE",
    enrolledAt: new Date()
  });

  await recordAuditLog({
    companyId: employee.companyId,
    actorUserId: actor.id,
    category: "FACE_VERIFICATION",
    action: existing ? "FACE_ENROLLMENT_UPDATED" : "FACE_ENROLLMENT_CREATED",
    targetType: "FaceEnrollment",
    targetId: enrollment.id,
    metadata: {
      employeeId: employee.id,
      provider: provider.name,
      status: enrollment.status
    },
    ...auditContext
  });

  return serializeFaceEnrollmentStatus(enrollment);
};

export const getFaceStatus = async (actor: AuthenticatedUser, employeeId: string, query: FaceScopeQuery) => {
  const employee = await getAdminEmployee(actor, employeeId, query.companyId);
  const enrollment = await getFaceRepository().findEnrollmentByEmployeeInCompany(employee.id, employee.companyId);

  return serializeFaceEnrollmentStatus(enrollment);
};

export const updateFaceEnrollmentStatus = async (
  actor: AuthenticatedUser,
  employeeId: string,
  input: UpdateFaceEnrollmentStatusInput,
  query: FaceScopeQuery,
  auditContext: AuditRequestContext
) => {
  const repository = getFaceRepository();
  const employee = await getAdminEmployee(actor, employeeId, query.companyId);
  const current = await repository.findEnrollmentByEmployeeInCompany(employee.id, employee.companyId);

  if (!current) {
    throw new NotFoundError("Face enrollment not found");
  }

  const enrollment = await repository.updateEnrollmentStatus(
    employee.id,
    employee.companyId,
    input.status,
    enrolledAtForStatus(input.status)
  );

  await recordAuditLog({
    companyId: employee.companyId,
    actorUserId: actor.id,
    category: "FACE_VERIFICATION",
    action: "FACE_ENROLLMENT_STATUS_CHANGED",
    targetType: "FaceEnrollment",
    targetId: enrollment.id,
    metadata: {
      employeeId: employee.id,
      previousStatus: current.status,
      status: enrollment.status
    },
    ...auditContext
  });

  return serializeFaceEnrollmentStatus(enrollment);
};

export const verifyFace = async (actor: AuthenticatedUser, input: VerifyFaceInput) => {
  const employee = await getSelfEmployee(actor);

  if (input.employeeId && input.employeeId !== employee.id) {
    throw new AuthorizationError("Face verification is self-service only");
  }

  const enrollment = await getFaceRepository().findEnrollmentByEmployeeInCompany(employee.id, employee.companyId);

  if (!enrollment || enrollment.status !== "ACTIVE") {
    throw new AuthorizationError("Active face enrollment is required");
  }

  if (enrollment.provider !== input.provider) {
    throw new ValidationError("Provider does not match active enrollment", undefined, 400);
  }

  const provider = getFaceProvider(input.provider);
  const result = await provider.verify({
    employeeId: employee.id,
    providerSubjectId: enrollment.providerSubjectId,
    templateReference: enrollment.templateReference,
    verificationReference: input.verificationReference
  });

  if (!result.verified) {
    return {
      verified: false,
      reason: result.reason ?? "FACE_NOT_MATCHED"
    };
  }

  const reference = createFaceVerificationReference({
    employeeId: employee.id,
    provider: provider.name
  });

  return {
    verified: true,
    employeeId: employee.id,
    provider: provider.name,
    verificationReference: reference.reference,
    expiresAt: reference.expiresAt
  };
};
