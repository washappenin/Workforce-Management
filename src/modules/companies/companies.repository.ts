import type { CompanyStatus } from "@prisma/client";

import { getPrismaClient } from "../../lib/prisma";

export interface CompanyRecord {
  id: string;
  name: string;
  status: CompanyStatus;
  contactEmail: string | null;
  contactPhone: string | null;
  billingEmail: string | null;
  address: string | null;
  country: string | null;
  timezone: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateCompanyRepositoryInput {
  name: string;
  status?: CompanyStatus;
  contactEmail?: string | null;
  contactPhone?: string | null;
  billingEmail?: string | null;
  address?: string | null;
  country?: string | null;
  timezone?: string | null;
}

export type UpdateCompanyRepositoryInput = Partial<Omit<CreateCompanyRepositoryInput, "status">>;

export interface CompaniesRepository {
  create(input: CreateCompanyRepositoryInput): Promise<CompanyRecord>;
  list(): Promise<CompanyRecord[]>;
  findById(companyId: string): Promise<CompanyRecord | null>;
  findByName(name: string): Promise<CompanyRecord | null>;
  update(companyId: string, input: UpdateCompanyRepositoryInput): Promise<CompanyRecord>;
  updateStatus(companyId: string, status: CompanyStatus): Promise<CompanyRecord>;
}

const prismaCompaniesRepository: CompaniesRepository = {
  async create(input) {
    const prisma = getPrismaClient();

    return prisma.company.create({
      data: {
        name: input.name,
        status: input.status,
        contactEmail: input.contactEmail ?? null,
        contactPhone: input.contactPhone ?? null,
        billingEmail: input.billingEmail ?? null,
        address: input.address ?? null,
        country: input.country ?? null,
        timezone: input.timezone ?? null
      }
    });
  },

  async list() {
    const prisma = getPrismaClient();

    return prisma.company.findMany({
      orderBy: { createdAt: "desc" }
    });
  },

  async findById(companyId) {
    const prisma = getPrismaClient();

    return prisma.company.findUnique({
      where: { id: companyId }
    });
  },

  async findByName(name) {
    const prisma = getPrismaClient();

    return prisma.company.findUnique({
      where: { name }
    });
  },

  async update(companyId, input) {
    const prisma = getPrismaClient();

    return prisma.company.update({
      where: { id: companyId },
      data: input
    });
  },

  async updateStatus(companyId, status) {
    const prisma = getPrismaClient();

    return prisma.company.update({
      where: { id: companyId },
      data: { status }
    });
  }
};

let activeCompaniesRepository = prismaCompaniesRepository;

export const getCompaniesRepository = () => activeCompaniesRepository;

export const setCompaniesRepositoryForTests = (repository: CompaniesRepository) => {
  activeCompaniesRepository = repository;
};

export const resetCompaniesRepositoryForTests = () => {
  activeCompaniesRepository = prismaCompaniesRepository;
};
