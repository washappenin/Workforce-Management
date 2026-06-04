import { getPrismaClient } from "../../lib/prisma";

export interface DepartmentRecord {
  id: string;
  companyId: string;
  name: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateDepartmentRepositoryInput {
  companyId: string;
  name: string;
  isActive?: boolean;
}

export interface UpdateDepartmentRepositoryInput {
  name?: string;
}

export interface DepartmentsRepository {
  create(input: CreateDepartmentRepositoryInput): Promise<DepartmentRecord>;
  list(companyId: string): Promise<DepartmentRecord[]>;
  findByIdInCompany(departmentId: string, companyId: string): Promise<DepartmentRecord | null>;
  findByNameInCompany(name: string, companyId: string): Promise<DepartmentRecord | null>;
  update(departmentId: string, companyId: string, input: UpdateDepartmentRepositoryInput): Promise<DepartmentRecord>;
  updateStatus(departmentId: string, companyId: string, isActive: boolean): Promise<DepartmentRecord>;
}

const prismaDepartmentsRepository: DepartmentsRepository = {
  async create(input) {
    const prisma = getPrismaClient();

    return prisma.department.create({
      data: {
        companyId: input.companyId,
        name: input.name,
        isActive: input.isActive
      }
    });
  },

  async list(companyId) {
    const prisma = getPrismaClient();

    return prisma.department.findMany({
      where: { companyId },
      orderBy: { createdAt: "desc" }
    });
  },

  async findByIdInCompany(departmentId, companyId) {
    const prisma = getPrismaClient();

    return prisma.department.findFirst({
      where: {
        id: departmentId,
        companyId
      }
    });
  },

  async findByNameInCompany(name, companyId) {
    const prisma = getPrismaClient();

    return prisma.department.findFirst({
      where: {
        name,
        companyId
      }
    });
  },

  async update(departmentId, companyId, input) {
    const prisma = getPrismaClient();

    return prisma.department.update({
      where: {
        id: departmentId,
        companyId
      },
      data: input
    });
  },

  async updateStatus(departmentId, companyId, isActive) {
    const prisma = getPrismaClient();

    return prisma.department.update({
      where: {
        id: departmentId,
        companyId
      },
      data: { isActive }
    });
  }
};

let activeDepartmentsRepository = prismaDepartmentsRepository;

export const getDepartmentsRepository = () => activeDepartmentsRepository;

export const setDepartmentsRepositoryForTests = (repository: DepartmentsRepository) => {
  activeDepartmentsRepository = repository;
};

export const resetDepartmentsRepositoryForTests = () => {
  activeDepartmentsRepository = prismaDepartmentsRepository;
};
