import type { CompanyStatus, EmployeeStatus, LeaveRequestStatus, LeaveTypeStatus } from "@prisma/client";

import { getPrismaClient } from "../../lib/prisma";

export interface LeaveCompanyRecord {
  id: string;
}

export interface LeaveEmployeeProfileRecord {
  id: string;
  companyId: string;
  userId: string;
  managerId: string | null;
  status: EmployeeStatus;
  companyStatus: CompanyStatus;
}

export interface LeaveTypeRecord {
  id: string;
  companyId: string;
  name: string;
  status: LeaveTypeStatus;
  defaultAnnualAllowance: number | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface LeaveEntitlementRecord {
  id: string;
  companyId: string;
  employeeId: string;
  leaveTypeId: string;
  year: number;
  totalDays: number;
  usedDays: number;
  createdAt: Date;
  updatedAt: Date;
  leaveType?: LeaveTypeRecord;
}

export interface LeaveRequestRecord {
  id: string;
  companyId: string;
  employeeId: string;
  leaveTypeId: string;
  startDate: Date;
  endDate: Date;
  reason: string | null;
  status: LeaveRequestStatus;
  reviewedById: string | null;
  reviewedAt: Date | null;
  reviewComment: string | null;
  createdAt: Date;
  updatedAt: Date;
  leaveType?: LeaveTypeRecord;
  employee?: LeaveEmployeeProfileRecord;
}

export interface UpsertLeaveEntitlementResult {
  entitlement: LeaveEntitlementRecord;
  created: boolean;
}

export interface CreateLeaveTypeRepositoryInput {
  companyId: string;
  name: string;
  defaultAnnualAllowance?: number | null;
}

export interface UpdateLeaveTypeRepositoryInput {
  name?: string;
  defaultAnnualAllowance?: number | null;
}

export interface UpsertLeaveEntitlementRepositoryInput {
  companyId: string;
  employeeId: string;
  leaveTypeId: string;
  year: number;
  totalDays: number;
  usedDays: number;
}

export interface LeaveEntitlementFilters {
  employeeId?: string;
  leaveTypeId?: string;
  year?: number;
}

export interface UpdateLeaveEntitlementRepositoryInput {
  totalDays?: number;
  usedDays?: number;
}

export interface CreateLeaveRequestRepositoryInput {
  companyId: string;
  employeeId: string;
  leaveTypeId: string;
  startDate: Date;
  endDate: Date;
  reason?: string | null;
}

export interface LeaveRequestFilters {
  employeeId?: string;
  leaveTypeId?: string;
  status?: LeaveRequestStatus;
  from?: Date;
  to?: Date;
}

export interface MyLeaveRequestFilters {
  status?: LeaveRequestStatus;
  year?: number;
}

export interface ReviewLeaveRequestRepositoryInput {
  status: Extract<LeaveRequestStatus, "APPROVED" | "REJECTED">;
  reviewedById?: string | null;
  reviewedAt: Date;
  reviewComment?: string | null;
}

export interface LeaveRepository {
  findCompanyById(companyId: string): Promise<LeaveCompanyRecord | null>;
  findEmployeeByIdInCompany(employeeId: string, companyId: string): Promise<LeaveEmployeeProfileRecord | null>;
  findEmployeeByUserId(userId: string): Promise<LeaveEmployeeProfileRecord | null>;
  createLeaveType(input: CreateLeaveTypeRepositoryInput): Promise<LeaveTypeRecord>;
  listLeaveTypes(companyId: string): Promise<LeaveTypeRecord[]>;
  findLeaveTypeByIdInCompany(leaveTypeId: string, companyId: string): Promise<LeaveTypeRecord | null>;
  findLeaveTypeByNameInCompany(name: string, companyId: string): Promise<LeaveTypeRecord | null>;
  updateLeaveType(leaveTypeId: string, companyId: string, input: UpdateLeaveTypeRepositoryInput): Promise<LeaveTypeRecord>;
  updateLeaveTypeStatus(leaveTypeId: string, companyId: string, status: LeaveTypeStatus): Promise<LeaveTypeRecord>;
  upsertEntitlement(input: UpsertLeaveEntitlementRepositoryInput): Promise<UpsertLeaveEntitlementResult>;
  listEntitlements(companyId: string, filters: LeaveEntitlementFilters): Promise<LeaveEntitlementRecord[]>;
  findEntitlementByIdInCompany(entitlementId: string, companyId: string): Promise<LeaveEntitlementRecord | null>;
  findEntitlementByEmployeeTypeYear(
    employeeId: string,
    leaveTypeId: string,
    year: number,
    companyId: string
  ): Promise<LeaveEntitlementRecord | null>;
  updateEntitlement(
    entitlementId: string,
    companyId: string,
    input: UpdateLeaveEntitlementRepositoryInput
  ): Promise<LeaveEntitlementRecord>;
  createLeaveRequest(input: CreateLeaveRequestRepositoryInput): Promise<LeaveRequestRecord>;
  findLeaveRequestByIdInCompany(leaveRequestId: string, companyId: string): Promise<LeaveRequestRecord | null>;
  listLeaveRequestsForEmployee(employeeId: string, filters: MyLeaveRequestFilters): Promise<LeaveRequestRecord[]>;
  listLeaveRequestsForDirectReports(managerId: string, companyId: string): Promise<LeaveRequestRecord[]>;
  listLeaveRequestsForCompany(companyId: string, filters: LeaveRequestFilters): Promise<LeaveRequestRecord[]>;
  findOverlappingLeaveRequest(input: {
    companyId: string;
    employeeId: string;
    startDate: Date;
    endDate: Date;
  }): Promise<LeaveRequestRecord | null>;
  updateLeaveRequestReview(
    leaveRequestId: string,
    companyId: string,
    input: ReviewLeaveRequestRepositoryInput
  ): Promise<LeaveRequestRecord>;
  incrementEntitlementUsedDays(entitlementId: string, companyId: string, days: number): Promise<LeaveEntitlementRecord>;
}

const decimalToNumber = (value: { toNumber(): number } | number | string | null) => {
  if (value === null) {
    return null;
  }

  if (typeof value === "number") {
    return value;
  }

  if (typeof value === "string") {
    return Number(value);
  }

  return value.toNumber();
};

const mapEmployee = (employee: {
  id: string;
  companyId: string;
  userId: string;
  managerId: string | null;
  status: EmployeeStatus;
  company: { status: CompanyStatus };
}): LeaveEmployeeProfileRecord => ({
  id: employee.id,
  companyId: employee.companyId,
  userId: employee.userId,
  managerId: employee.managerId,
  status: employee.status,
  companyStatus: employee.company.status
});

const mapLeaveType = (leaveType: {
  id: string;
  companyId: string;
  name: string;
  status: LeaveTypeStatus;
  defaultAnnualAllowance: { toNumber(): number } | number | string | null;
  createdAt: Date;
  updatedAt: Date;
}): LeaveTypeRecord => ({
  id: leaveType.id,
  companyId: leaveType.companyId,
  name: leaveType.name,
  status: leaveType.status,
  defaultAnnualAllowance: decimalToNumber(leaveType.defaultAnnualAllowance),
  createdAt: leaveType.createdAt,
  updatedAt: leaveType.updatedAt
});

const mapEntitlement = (entitlement: {
  id: string;
  companyId: string;
  employeeId: string;
  leaveTypeId: string;
  year: number;
  totalDays: { toNumber(): number } | number | string;
  usedDays: { toNumber(): number } | number | string;
  createdAt: Date;
  updatedAt: Date;
  leaveType?: {
    id: string;
    companyId: string;
    name: string;
    status: LeaveTypeStatus;
    defaultAnnualAllowance: { toNumber(): number } | number | string | null;
    createdAt: Date;
    updatedAt: Date;
  };
}): LeaveEntitlementRecord => ({
  id: entitlement.id,
  companyId: entitlement.companyId,
  employeeId: entitlement.employeeId,
  leaveTypeId: entitlement.leaveTypeId,
  year: entitlement.year,
  totalDays: decimalToNumber(entitlement.totalDays) ?? 0,
  usedDays: decimalToNumber(entitlement.usedDays) ?? 0,
  createdAt: entitlement.createdAt,
  updatedAt: entitlement.updatedAt,
  ...(entitlement.leaveType ? { leaveType: mapLeaveType(entitlement.leaveType) } : {})
});

const mapLeaveRequest = (request: {
  id: string;
  companyId: string;
  employeeId: string;
  leaveTypeId: string;
  startDate: Date;
  endDate: Date;
  reason: string | null;
  status: LeaveRequestStatus;
  reviewedById: string | null;
  reviewedAt: Date | null;
  reviewComment: string | null;
  createdAt: Date;
  updatedAt: Date;
  leaveType?: {
    id: string;
    companyId: string;
    name: string;
    status: LeaveTypeStatus;
    defaultAnnualAllowance: { toNumber(): number } | number | string | null;
    createdAt: Date;
    updatedAt: Date;
  };
  employee?: {
    id: string;
    companyId: string;
    userId: string;
    managerId: string | null;
    status: EmployeeStatus;
    company: { status: CompanyStatus };
  };
}): LeaveRequestRecord => ({
  id: request.id,
  companyId: request.companyId,
  employeeId: request.employeeId,
  leaveTypeId: request.leaveTypeId,
  startDate: request.startDate,
  endDate: request.endDate,
  reason: request.reason,
  status: request.status,
  reviewedById: request.reviewedById,
  reviewedAt: request.reviewedAt,
  reviewComment: request.reviewComment,
  createdAt: request.createdAt,
  updatedAt: request.updatedAt,
  ...(request.leaveType ? { leaveType: mapLeaveType(request.leaveType) } : {}),
  ...(request.employee ? { employee: mapEmployee(request.employee) } : {})
});

const buildMyLeaveDateFilter = (filters: MyLeaveRequestFilters) => {
  if (!filters.year) {
    return undefined;
  }

  return {
    gte: new Date(Date.UTC(filters.year, 0, 1)),
    lte: new Date(Date.UTC(filters.year, 11, 31, 23, 59, 59, 999))
  };
};

const buildAdminLeaveDateFilter = (filters: LeaveRequestFilters) => {
  if (!filters.from && !filters.to) {
    return undefined;
  }

  return {
    gte: filters.from,
    lte: filters.to
  };
};

const leaveRequestInclude = {
  leaveType: true,
  employee: {
    include: {
      company: true
    }
  }
};

const prismaLeaveRepository: LeaveRepository = {
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

  async createLeaveType(input) {
    const prisma = getPrismaClient();
    const leaveType = await prisma.leaveType.create({
      data: {
        companyId: input.companyId,
        name: input.name,
        defaultAnnualAllowance: input.defaultAnnualAllowance ?? null
      }
    });

    return mapLeaveType(leaveType);
  },

  async listLeaveTypes(companyId) {
    const prisma = getPrismaClient();
    const leaveTypes = await prisma.leaveType.findMany({
      where: { companyId },
      orderBy: { createdAt: "desc" }
    });

    return leaveTypes.map(mapLeaveType);
  },

  async findLeaveTypeByIdInCompany(leaveTypeId, companyId) {
    const prisma = getPrismaClient();
    const leaveType = await prisma.leaveType.findFirst({
      where: {
        id: leaveTypeId,
        companyId
      }
    });

    return leaveType ? mapLeaveType(leaveType) : null;
  },

  async findLeaveTypeByNameInCompany(name, companyId) {
    const prisma = getPrismaClient();
    const leaveType = await prisma.leaveType.findFirst({
      where: {
        name,
        companyId
      }
    });

    return leaveType ? mapLeaveType(leaveType) : null;
  },

  async updateLeaveType(leaveTypeId, companyId, input) {
    const prisma = getPrismaClient();

    await prisma.leaveType.updateMany({
      where: {
        id: leaveTypeId,
        companyId
      },
      data: input
    });

    const leaveType = await this.findLeaveTypeByIdInCompany(leaveTypeId, companyId);

    if (!leaveType) {
      throw new Error("Leave type update failed");
    }

    return leaveType;
  },

  async updateLeaveTypeStatus(leaveTypeId, companyId, status) {
    const prisma = getPrismaClient();

    await prisma.leaveType.updateMany({
      where: {
        id: leaveTypeId,
        companyId
      },
      data: { status }
    });

    const leaveType = await this.findLeaveTypeByIdInCompany(leaveTypeId, companyId);

    if (!leaveType) {
      throw new Error("Leave type status update failed");
    }

    return leaveType;
  },

  async upsertEntitlement(input) {
    const prisma = getPrismaClient();
    const current = await this.findEntitlementByEmployeeTypeYear(input.employeeId, input.leaveTypeId, input.year, input.companyId);
    const entitlement = await prisma.leaveEntitlement.upsert({
      where: {
        employeeId_leaveTypeId_year: {
          employeeId: input.employeeId,
          leaveTypeId: input.leaveTypeId,
          year: input.year
        }
      },
      create: input,
      update: {
        totalDays: input.totalDays,
        usedDays: input.usedDays
      },
      include: {
        leaveType: true
      }
    });

    return {
      entitlement: mapEntitlement(entitlement),
      created: !current
    };
  },

  async listEntitlements(companyId, filters) {
    const prisma = getPrismaClient();
    const entitlements = await prisma.leaveEntitlement.findMany({
      where: {
        companyId,
        employeeId: filters.employeeId,
        leaveTypeId: filters.leaveTypeId,
        year: filters.year
      },
      include: {
        leaveType: true
      },
      orderBy: { createdAt: "desc" }
    });

    return entitlements.map(mapEntitlement);
  },

  async findEntitlementByIdInCompany(entitlementId, companyId) {
    const prisma = getPrismaClient();
    const entitlement = await prisma.leaveEntitlement.findFirst({
      where: {
        id: entitlementId,
        companyId
      },
      include: {
        leaveType: true
      }
    });

    return entitlement ? mapEntitlement(entitlement) : null;
  },

  async findEntitlementByEmployeeTypeYear(employeeId, leaveTypeId, year, companyId) {
    const prisma = getPrismaClient();
    const entitlement = await prisma.leaveEntitlement.findFirst({
      where: {
        employeeId,
        leaveTypeId,
        year,
        companyId
      },
      include: {
        leaveType: true
      }
    });

    return entitlement ? mapEntitlement(entitlement) : null;
  },

  async updateEntitlement(entitlementId, companyId, input) {
    const prisma = getPrismaClient();

    await prisma.leaveEntitlement.updateMany({
      where: {
        id: entitlementId,
        companyId
      },
      data: input
    });

    const entitlement = await this.findEntitlementByIdInCompany(entitlementId, companyId);

    if (!entitlement) {
      throw new Error("Leave entitlement update failed");
    }

    return entitlement;
  },

  async createLeaveRequest(input) {
    const prisma = getPrismaClient();
    const request = await prisma.leaveRequest.create({
      data: {
        companyId: input.companyId,
        employeeId: input.employeeId,
        leaveTypeId: input.leaveTypeId,
        startDate: input.startDate,
        endDate: input.endDate,
        reason: input.reason ?? null,
        status: "PENDING"
      },
      include: leaveRequestInclude
    });

    return mapLeaveRequest(request);
  },

  async findLeaveRequestByIdInCompany(leaveRequestId, companyId) {
    const prisma = getPrismaClient();
    const request = await prisma.leaveRequest.findFirst({
      where: {
        id: leaveRequestId,
        companyId
      },
      include: leaveRequestInclude
    });

    return request ? mapLeaveRequest(request) : null;
  },

  async listLeaveRequestsForEmployee(employeeId, filters) {
    const prisma = getPrismaClient();
    const requests = await prisma.leaveRequest.findMany({
      where: {
        employeeId,
        status: filters.status,
        startDate: buildMyLeaveDateFilter(filters)
      },
      include: leaveRequestInclude,
      orderBy: { createdAt: "desc" }
    });

    return requests.map(mapLeaveRequest);
  },

  async listLeaveRequestsForDirectReports(managerId, companyId) {
    const prisma = getPrismaClient();
    const requests = await prisma.leaveRequest.findMany({
      where: {
        companyId,
        employee: {
          managerId
        }
      },
      include: leaveRequestInclude,
      orderBy: { createdAt: "desc" }
    });

    return requests.map(mapLeaveRequest);
  },

  async listLeaveRequestsForCompany(companyId, filters) {
    const prisma = getPrismaClient();
    const requests = await prisma.leaveRequest.findMany({
      where: {
        companyId,
        employeeId: filters.employeeId,
        leaveTypeId: filters.leaveTypeId,
        status: filters.status,
        startDate: buildAdminLeaveDateFilter(filters)
      },
      include: leaveRequestInclude,
      orderBy: { createdAt: "desc" }
    });

    return requests.map(mapLeaveRequest);
  },

  async findOverlappingLeaveRequest(input) {
    const prisma = getPrismaClient();
    const request = await prisma.leaveRequest.findFirst({
      where: {
        companyId: input.companyId,
        employeeId: input.employeeId,
        status: { in: ["PENDING", "APPROVED"] },
        startDate: { lte: input.endDate },
        endDate: { gte: input.startDate }
      },
      include: leaveRequestInclude
    });

    return request ? mapLeaveRequest(request) : null;
  },

  async updateLeaveRequestReview(leaveRequestId, companyId, input) {
    const prisma = getPrismaClient();

    await prisma.leaveRequest.updateMany({
      where: {
        id: leaveRequestId,
        companyId
      },
      data: input
    });

    const request = await this.findLeaveRequestByIdInCompany(leaveRequestId, companyId);

    if (!request) {
      throw new Error("Leave request review update failed");
    }

    return request;
  },

  async incrementEntitlementUsedDays(entitlementId, companyId, days) {
    const prisma = getPrismaClient();

    await prisma.leaveEntitlement.updateMany({
      where: {
        id: entitlementId,
        companyId
      },
      data: {
        usedDays: {
          increment: days
        }
      }
    });

    const entitlement = await this.findEntitlementByIdInCompany(entitlementId, companyId);

    if (!entitlement) {
      throw new Error("Leave entitlement increment failed");
    }

    return entitlement;
  }
};

let activeLeaveRepository = prismaLeaveRepository;

export const getLeaveRepository = () => activeLeaveRepository;

export const setLeaveRepositoryForTests = (repository: LeaveRepository) => {
  activeLeaveRepository = repository;
};

export const resetLeaveRepositoryForTests = () => {
  activeLeaveRepository = prismaLeaveRepository;
};
