import type { CompanyStatus, EmployeeStatus, PerformanceReviewStatus, Prisma, ReviewCycleStatus } from "@prisma/client";

import { getPrismaClient } from "../../lib/prisma";

export interface ReviewCompanyRecord {
  id: string;
}

export interface ReviewEmployeeProfileRecord {
  id: string;
  companyId: string;
  userId: string;
  managerId: string | null;
  status: EmployeeStatus;
  companyStatus: CompanyStatus;
}

export interface ReviewCycleRecord {
  id: string;
  companyId: string;
  name: string;
  startDate: Date;
  endDate: Date;
  status: ReviewCycleStatus;
  createdAt: Date;
  updatedAt: Date;
}

export interface PerformanceReviewRecord {
  id: string;
  companyId: string;
  reviewCycleId: string;
  employeeId: string;
  managerId: string;
  summary: string;
  rating: number | null;
  status: PerformanceReviewStatus;
  submittedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
  reviewCycle?: ReviewCycleRecord;
  employee?: ReviewEmployeeProfileRecord;
  manager?: ReviewEmployeeProfileRecord;
}

export interface CreateReviewCycleRepositoryInput {
  companyId: string;
  name: string;
  startDate: Date;
  endDate: Date;
}

export interface UpdateReviewCycleRepositoryInput {
  name?: string;
  startDate?: Date;
  endDate?: Date;
}

export interface CreatePerformanceReviewRepositoryInput {
  companyId: string;
  reviewCycleId: string;
  employeeId: string;
  managerId: string;
  summary: string;
  rating?: number | null;
  status: PerformanceReviewStatus;
  submittedAt?: Date | null;
}

export interface UpdatePerformanceReviewRepositoryInput {
  summary?: string;
  rating?: number | null;
}

export interface PerformanceReviewFilters {
  employeeId?: string;
  reviewCycleId?: string;
  status?: PerformanceReviewStatus;
  from?: Date;
  to?: Date;
}

export interface UpdatePerformanceReviewStatusRepositoryInput {
  status: PerformanceReviewStatus;
  submittedAt?: Date | null;
}

export interface PerformanceReviewsRepository {
  findCompanyById(companyId: string): Promise<ReviewCompanyRecord | null>;
  findEmployeeByIdInCompany(employeeId: string, companyId: string): Promise<ReviewEmployeeProfileRecord | null>;
  findEmployeeByUserId(userId: string): Promise<ReviewEmployeeProfileRecord | null>;
  findReviewCycleByNameInCompany(name: string, companyId: string): Promise<ReviewCycleRecord | null>;
  createReviewCycle(input: CreateReviewCycleRepositoryInput): Promise<ReviewCycleRecord>;
  listReviewCyclesForCompany(companyId: string): Promise<ReviewCycleRecord[]>;
  findReviewCycleByIdInCompany(reviewCycleId: string, companyId: string): Promise<ReviewCycleRecord | null>;
  updateReviewCycle(reviewCycleId: string, companyId: string, input: UpdateReviewCycleRepositoryInput): Promise<ReviewCycleRecord>;
  updateReviewCycleStatus(reviewCycleId: string, companyId: string, status: ReviewCycleStatus): Promise<ReviewCycleRecord>;
  findPerformanceReviewByEmployeeCycle(
    employeeId: string,
    reviewCycleId: string,
    companyId: string
  ): Promise<PerformanceReviewRecord | null>;
  createPerformanceReview(input: CreatePerformanceReviewRepositoryInput): Promise<PerformanceReviewRecord>;
  listReviewsForEmployee(employeeId: string): Promise<PerformanceReviewRecord[]>;
  listReviewsForDirectReports(managerId: string, companyId: string): Promise<PerformanceReviewRecord[]>;
  listReviewsForCompany(companyId: string, filters: PerformanceReviewFilters): Promise<PerformanceReviewRecord[]>;
  findPerformanceReviewByIdInCompany(reviewId: string, companyId: string): Promise<PerformanceReviewRecord | null>;
  updatePerformanceReview(
    reviewId: string,
    companyId: string,
    input: UpdatePerformanceReviewRepositoryInput
  ): Promise<PerformanceReviewRecord>;
  updatePerformanceReviewStatus(
    reviewId: string,
    companyId: string,
    input: UpdatePerformanceReviewStatusRepositoryInput
  ): Promise<PerformanceReviewRecord>;
}

const mapEmployee = (employee: {
  id: string;
  companyId: string;
  userId: string;
  managerId: string | null;
  status: EmployeeStatus;
  company: { status: CompanyStatus };
}): ReviewEmployeeProfileRecord => ({
  id: employee.id,
  companyId: employee.companyId,
  userId: employee.userId,
  managerId: employee.managerId,
  status: employee.status,
  companyStatus: employee.company.status
});

const mapReviewCycle = (reviewCycle: ReviewCycleRecord): ReviewCycleRecord => ({
  id: reviewCycle.id,
  companyId: reviewCycle.companyId,
  name: reviewCycle.name,
  startDate: reviewCycle.startDate,
  endDate: reviewCycle.endDate,
  status: reviewCycle.status,
  createdAt: reviewCycle.createdAt,
  updatedAt: reviewCycle.updatedAt
});

const decimalToNumber = (value: Prisma.Decimal | number | null): number | null => (value === null ? null : Number(value));

const mapPerformanceReview = (review: {
  id: string;
  companyId: string;
  reviewCycleId: string;
  employeeId: string;
  managerId: string;
  summary: string;
  rating: Prisma.Decimal | number | null;
  status: PerformanceReviewStatus;
  submittedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
  reviewCycle?: ReviewCycleRecord;
  employee?: {
    id: string;
    companyId: string;
    userId: string;
    managerId: string | null;
    status: EmployeeStatus;
    company: { status: CompanyStatus };
  };
  manager?: {
    id: string;
    companyId: string;
    userId: string;
    managerId: string | null;
    status: EmployeeStatus;
    company: { status: CompanyStatus };
  };
}): PerformanceReviewRecord => ({
  id: review.id,
  companyId: review.companyId,
  reviewCycleId: review.reviewCycleId,
  employeeId: review.employeeId,
  managerId: review.managerId,
  summary: review.summary,
  rating: decimalToNumber(review.rating),
  status: review.status,
  submittedAt: review.submittedAt,
  createdAt: review.createdAt,
  updatedAt: review.updatedAt,
  ...(review.reviewCycle ? { reviewCycle: mapReviewCycle(review.reviewCycle) } : {}),
  ...(review.employee ? { employee: mapEmployee(review.employee) } : {}),
  ...(review.manager ? { manager: mapEmployee(review.manager) } : {})
});

const performanceReviewInclude = {
  reviewCycle: true,
  employee: {
    include: {
      company: true
    }
  },
  manager: {
    include: {
      company: true
    }
  }
};

const buildCreatedAtFilter = (filters: PerformanceReviewFilters) => {
  if (!filters.from && !filters.to) {
    return undefined;
  }

  return {
    gte: filters.from,
    lte: filters.to
  };
};

const prismaPerformanceReviewsRepository: PerformanceReviewsRepository = {
  async findCompanyById(companyId) {
    const prisma = getPrismaClient();

    return prisma.company.findUnique({
      where: { id: companyId },
      select: { id: true }
    });
  },

  async findEmployeeByIdInCompany(employeeId, companyId) {
    const prisma = getPrismaClient();
    const employee = await prisma.employeeProfile.findFirst({
      where: {
        id: employeeId,
        companyId
      },
      include: {
        company: true
      }
    });

    return employee ? mapEmployee(employee) : null;
  },

  async findEmployeeByUserId(userId) {
    const prisma = getPrismaClient();
    const employee = await prisma.employeeProfile.findUnique({
      where: { userId },
      include: {
        company: true
      }
    });

    return employee ? mapEmployee(employee) : null;
  },

  async findReviewCycleByNameInCompany(name, companyId) {
    const prisma = getPrismaClient();
    const reviewCycle = await prisma.reviewCycle.findUnique({
      where: {
        companyId_name: {
          companyId,
          name
        }
      }
    });

    return reviewCycle ? mapReviewCycle(reviewCycle) : null;
  },

  async createReviewCycle(input) {
    const prisma = getPrismaClient();
    const reviewCycle = await prisma.reviewCycle.create({
      data: {
        companyId: input.companyId,
        name: input.name,
        startDate: input.startDate,
        endDate: input.endDate
      }
    });

    return mapReviewCycle(reviewCycle);
  },

  async listReviewCyclesForCompany(companyId) {
    const prisma = getPrismaClient();
    const reviewCycles = await prisma.reviewCycle.findMany({
      where: { companyId },
      orderBy: { createdAt: "desc" }
    });

    return reviewCycles.map(mapReviewCycle);
  },

  async findReviewCycleByIdInCompany(reviewCycleId, companyId) {
    const prisma = getPrismaClient();
    const reviewCycle = await prisma.reviewCycle.findFirst({
      where: {
        id: reviewCycleId,
        companyId
      }
    });

    return reviewCycle ? mapReviewCycle(reviewCycle) : null;
  },

  async updateReviewCycle(reviewCycleId, companyId, input) {
    const prisma = getPrismaClient();

    await prisma.reviewCycle.updateMany({
      where: {
        id: reviewCycleId,
        companyId
      },
      data: input
    });

    const reviewCycle = await this.findReviewCycleByIdInCompany(reviewCycleId, companyId);

    if (!reviewCycle) {
      throw new Error("Review cycle update failed");
    }

    return reviewCycle;
  },

  async updateReviewCycleStatus(reviewCycleId, companyId, status) {
    const prisma = getPrismaClient();

    await prisma.reviewCycle.updateMany({
      where: {
        id: reviewCycleId,
        companyId
      },
      data: { status }
    });

    const reviewCycle = await this.findReviewCycleByIdInCompany(reviewCycleId, companyId);

    if (!reviewCycle) {
      throw new Error("Review cycle status update failed");
    }

    return reviewCycle;
  },

  async findPerformanceReviewByEmployeeCycle(employeeId, reviewCycleId, companyId) {
    const prisma = getPrismaClient();
    const review = await prisma.performanceReview.findFirst({
      where: {
        companyId,
        employeeId,
        reviewCycleId
      },
      include: performanceReviewInclude
    });

    return review ? mapPerformanceReview(review) : null;
  },

  async createPerformanceReview(input) {
    const prisma = getPrismaClient();
    const review = await prisma.performanceReview.create({
      data: {
        companyId: input.companyId,
        reviewCycleId: input.reviewCycleId,
        employeeId: input.employeeId,
        managerId: input.managerId,
        summary: input.summary,
        rating: input.rating ?? null,
        status: input.status,
        submittedAt: input.submittedAt ?? null
      },
      include: performanceReviewInclude
    });

    return mapPerformanceReview(review);
  },

  async listReviewsForEmployee(employeeId) {
    const prisma = getPrismaClient();
    const reviews = await prisma.performanceReview.findMany({
      where: { employeeId },
      include: performanceReviewInclude,
      orderBy: { createdAt: "desc" }
    });

    return reviews.map(mapPerformanceReview);
  },

  async listReviewsForDirectReports(managerId, companyId) {
    const prisma = getPrismaClient();
    const reviews = await prisma.performanceReview.findMany({
      where: {
        companyId,
        employee: {
          managerId
        }
      },
      include: performanceReviewInclude,
      orderBy: { createdAt: "desc" }
    });

    return reviews.map(mapPerformanceReview);
  },

  async listReviewsForCompany(companyId, filters) {
    const prisma = getPrismaClient();
    const reviews = await prisma.performanceReview.findMany({
      where: {
        companyId,
        employeeId: filters.employeeId,
        reviewCycleId: filters.reviewCycleId,
        status: filters.status,
        createdAt: buildCreatedAtFilter(filters)
      },
      include: performanceReviewInclude,
      orderBy: { createdAt: "desc" }
    });

    return reviews.map(mapPerformanceReview);
  },

  async findPerformanceReviewByIdInCompany(reviewId, companyId) {
    const prisma = getPrismaClient();
    const review = await prisma.performanceReview.findFirst({
      where: {
        id: reviewId,
        companyId
      },
      include: performanceReviewInclude
    });

    return review ? mapPerformanceReview(review) : null;
  },

  async updatePerformanceReview(reviewId, companyId, input) {
    const prisma = getPrismaClient();

    await prisma.performanceReview.updateMany({
      where: {
        id: reviewId,
        companyId
      },
      data: input
    });

    const review = await this.findPerformanceReviewByIdInCompany(reviewId, companyId);

    if (!review) {
      throw new Error("Performance review update failed");
    }

    return review;
  },

  async updatePerformanceReviewStatus(reviewId, companyId, input) {
    const prisma = getPrismaClient();

    await prisma.performanceReview.updateMany({
      where: {
        id: reviewId,
        companyId
      },
      data: input
    });

    const review = await this.findPerformanceReviewByIdInCompany(reviewId, companyId);

    if (!review) {
      throw new Error("Performance review status update failed");
    }

    return review;
  }
};

let activePerformanceReviewsRepository = prismaPerformanceReviewsRepository;

export const getPerformanceReviewsRepository = () => activePerformanceReviewsRepository;

export const setPerformanceReviewsRepositoryForTests = (repository: PerformanceReviewsRepository) => {
  activePerformanceReviewsRepository = repository;
};

export const resetPerformanceReviewsRepositoryForTests = () => {
  activePerformanceReviewsRepository = prismaPerformanceReviewsRepository;
};
