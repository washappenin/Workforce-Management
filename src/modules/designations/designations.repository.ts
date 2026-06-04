import { getPrismaClient } from "../../lib/prisma";

export interface DesignationRecord {
  id: string;
  companyId: string;
  departmentId: string | null;
  title: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateDesignationRepositoryInput {
  companyId: string;
  title: string;
  departmentId?: string | null;
  isActive?: boolean;
}

export interface UpdateDesignationRepositoryInput {
  title?: string;
  departmentId?: string | null;
}

export interface DesignationsRepository {
  create(input: CreateDesignationRepositoryInput): Promise<DesignationRecord>;
  list(companyId: string): Promise<DesignationRecord[]>;
  findByIdInCompany(designationId: string, companyId: string): Promise<DesignationRecord | null>;
  findByTitleInCompany(title: string, companyId: string): Promise<DesignationRecord | null>;
  update(designationId: string, companyId: string, input: UpdateDesignationRepositoryInput): Promise<DesignationRecord>;
  updateStatus(designationId: string, companyId: string, isActive: boolean): Promise<DesignationRecord>;
}

const prismaDesignationsRepository: DesignationsRepository = {
  async create(input) {
    const prisma = getPrismaClient();

    return prisma.designation.create({
      data: {
        companyId: input.companyId,
        title: input.title,
        departmentId: input.departmentId ?? null,
        isActive: input.isActive
      }
    });
  },

  async list(companyId) {
    const prisma = getPrismaClient();

    return prisma.designation.findMany({
      where: { companyId },
      orderBy: { createdAt: "desc" }
    });
  },

  async findByIdInCompany(designationId, companyId) {
    const prisma = getPrismaClient();

    return prisma.designation.findFirst({
      where: {
        id: designationId,
        companyId
      }
    });
  },

  async findByTitleInCompany(title, companyId) {
    const prisma = getPrismaClient();

    return prisma.designation.findFirst({
      where: {
        title,
        companyId
      }
    });
  },

  async update(designationId, companyId, input) {
    const prisma = getPrismaClient();

    return prisma.designation.update({
      where: {
        id: designationId,
        companyId
      },
      data: input
    });
  },

  async updateStatus(designationId, companyId, isActive) {
    const prisma = getPrismaClient();

    return prisma.designation.update({
      where: {
        id: designationId,
        companyId
      },
      data: { isActive }
    });
  }
};

let activeDesignationsRepository = prismaDesignationsRepository;

export const getDesignationsRepository = () => activeDesignationsRepository;

export const setDesignationsRepositoryForTests = (repository: DesignationsRepository) => {
  activeDesignationsRepository = repository;
};

export const resetDesignationsRepositoryForTests = () => {
  activeDesignationsRepository = prismaDesignationsRepository;
};
