import type { EmployeeStatus, FaceEnrollmentStatus } from "@prisma/client";

import { getPrismaClient } from "../../lib/prisma";

export interface FaceEmployeeProfileRecord {
  id: string;
  companyId: string;
  userId: string;
  status: EmployeeStatus;
}

export interface FaceEnrollmentRecord {
  id: string;
  companyId: string;
  employeeId: string;
  provider: string;
  providerSubjectId: string | null;
  templateReference: string | null;
  status: FaceEnrollmentStatus;
  enrolledAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface UpsertFaceEnrollmentRepositoryInput {
  companyId: string;
  employeeId: string;
  provider: string;
  providerSubjectId?: string | null;
  templateReference?: string | null;
  status: FaceEnrollmentStatus;
  enrolledAt?: Date | null;
}

export interface FaceRepository {
  findEmployeeByIdInCompany(employeeId: string, companyId: string): Promise<FaceEmployeeProfileRecord | null>;
  findEmployeeByUserId(userId: string): Promise<FaceEmployeeProfileRecord | null>;
  findEnrollmentByEmployeeInCompany(employeeId: string, companyId: string): Promise<FaceEnrollmentRecord | null>;
  upsertEnrollment(input: UpsertFaceEnrollmentRepositoryInput): Promise<FaceEnrollmentRecord>;
  updateEnrollmentStatus(
    employeeId: string,
    companyId: string,
    status: FaceEnrollmentStatus,
    enrolledAt: Date | null
  ): Promise<FaceEnrollmentRecord>;
}

const mapEnrollment = (enrollment: FaceEnrollmentRecord): FaceEnrollmentRecord => ({
  id: enrollment.id,
  companyId: enrollment.companyId,
  employeeId: enrollment.employeeId,
  provider: enrollment.provider,
  providerSubjectId: enrollment.providerSubjectId,
  templateReference: enrollment.templateReference,
  status: enrollment.status,
  enrolledAt: enrollment.enrolledAt,
  createdAt: enrollment.createdAt,
  updatedAt: enrollment.updatedAt
});

const prismaFaceRepository: FaceRepository = {
  async findEmployeeByIdInCompany(employeeId, companyId) {
    const prisma = getPrismaClient();

    return prisma.employeeProfile.findFirst({
      where: {
        id: employeeId,
        companyId
      },
      select: {
        id: true,
        companyId: true,
        userId: true,
        status: true
      }
    });
  },

  async findEmployeeByUserId(userId) {
    const prisma = getPrismaClient();

    return prisma.employeeProfile.findUnique({
      where: { userId },
      select: {
        id: true,
        companyId: true,
        userId: true,
        status: true
      }
    });
  },

  async findEnrollmentByEmployeeInCompany(employeeId, companyId) {
    const prisma = getPrismaClient();
    const enrollment = await prisma.faceEnrollment.findFirst({
      where: {
        employeeId,
        companyId
      }
    });

    return enrollment ? mapEnrollment(enrollment) : null;
  },

  async upsertEnrollment(input) {
    const prisma = getPrismaClient();
    const enrollment = await prisma.faceEnrollment.upsert({
      where: { employeeId: input.employeeId },
      create: {
        companyId: input.companyId,
        employeeId: input.employeeId,
        provider: input.provider,
        providerSubjectId: input.providerSubjectId ?? null,
        templateReference: input.templateReference ?? null,
        status: input.status,
        enrolledAt: input.enrolledAt ?? null
      },
      update: {
        provider: input.provider,
        providerSubjectId: input.providerSubjectId ?? null,
        templateReference: input.templateReference ?? null,
        status: input.status,
        enrolledAt: input.enrolledAt ?? null
      }
    });

    return mapEnrollment(enrollment);
  },

  async updateEnrollmentStatus(employeeId, companyId, status, enrolledAt) {
    const prisma = getPrismaClient();

    await prisma.faceEnrollment.updateMany({
      where: {
        employeeId,
        companyId
      },
      data: {
        status,
        enrolledAt
      }
    });

    const enrollment = await this.findEnrollmentByEmployeeInCompany(employeeId, companyId);

    if (!enrollment) {
      throw new Error("Face enrollment status update failed");
    }

    return enrollment;
  }
};

let activeFaceRepository = prismaFaceRepository;

export const getFaceRepository = () => activeFaceRepository;

export const setFaceRepositoryForTests = (repository: FaceRepository) => {
  activeFaceRepository = repository;
};

export const resetFaceRepositoryForTests = () => {
  activeFaceRepository = prismaFaceRepository;
};
