import type { CompanyStatus, EmployeeStatus, OKRApprovalStatus, OKRStatus } from "@prisma/client";

import { getPrismaClient } from "../../lib/prisma";

export interface OkrCompanyRecord {
  id: string;
}

export interface OkrEmployeeProfileRecord {
  id: string;
  companyId: string;
  userId: string;
  managerId: string | null;
  status: EmployeeStatus;
  companyStatus: CompanyStatus;
}

export interface OkrProgressUpdateRecord {
  id: string;
  companyId: string;
  okrId: string;
  employeeId: string;
  progressPercent: number;
  note: string | null;
  createdAt: Date;
}

export interface OkrApprovalRecord {
  id: string;
  companyId: string;
  okrId: string;
  approverEmployeeId: string;
  status: OKRApprovalStatus;
  comment: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface OkrRecord {
  id: string;
  companyId: string;
  employeeId: string;
  assignedById: string;
  title: string;
  description: string | null;
  status: OKRStatus;
  dueDate: Date | null;
  createdAt: Date;
  updatedAt: Date;
  employee?: OkrEmployeeProfileRecord;
  assignedBy?: OkrEmployeeProfileRecord;
  progressUpdates?: OkrProgressUpdateRecord[];
  approvals?: OkrApprovalRecord[];
}

export interface CreateOkrRepositoryInput {
  companyId: string;
  employeeId: string;
  assignedById: string;
  title: string;
  description?: string | null;
  dueDate?: Date | null;
}

export interface UpdateOkrRepositoryInput {
  title?: string;
  description?: string | null;
  dueDate?: Date | null;
}

export interface OkrListFilters {
  employeeId?: string;
  status?: OKRStatus;
  from?: Date;
  to?: Date;
}

export interface CreateOkrProgressRepositoryInput {
  companyId: string;
  okrId: string;
  employeeId: string;
  progressPercent: number;
  note?: string | null;
}

export interface UpsertOkrApprovalRepositoryInput {
  companyId: string;
  okrId: string;
  approverEmployeeId: string;
  status: OKRApprovalStatus;
  comment?: string | null;
}

export interface OkrsRepository {
  findCompanyById(companyId: string): Promise<OkrCompanyRecord | null>;
  findEmployeeByIdInCompany(employeeId: string, companyId: string): Promise<OkrEmployeeProfileRecord | null>;
  findEmployeeByUserId(userId: string): Promise<OkrEmployeeProfileRecord | null>;
  createOkr(input: CreateOkrRepositoryInput): Promise<OkrRecord>;
  findOkrByIdInCompany(okrId: string, companyId: string): Promise<OkrRecord | null>;
  listOkrsForEmployee(employeeId: string, filters: Pick<OkrListFilters, "status">): Promise<OkrRecord[]>;
  listOkrsForDirectReports(managerId: string, companyId: string): Promise<OkrRecord[]>;
  listOkrsForCompany(companyId: string, filters: OkrListFilters): Promise<OkrRecord[]>;
  updateOkr(okrId: string, companyId: string, input: UpdateOkrRepositoryInput): Promise<OkrRecord>;
  updateOkrStatus(okrId: string, companyId: string, status: OKRStatus): Promise<OkrRecord>;
  createProgressUpdate(input: CreateOkrProgressRepositoryInput): Promise<OkrProgressUpdateRecord>;
  upsertApproval(input: UpsertOkrApprovalRepositoryInput): Promise<OkrApprovalRecord>;
  listApprovalsForOkr(okrId: string, companyId: string): Promise<OkrApprovalRecord[]>;
}

const mapEmployee = (employee: {
  id: string;
  companyId: string;
  userId: string;
  managerId: string | null;
  status: EmployeeStatus;
  company: { status: CompanyStatus };
}): OkrEmployeeProfileRecord => ({
  id: employee.id,
  companyId: employee.companyId,
  userId: employee.userId,
  managerId: employee.managerId,
  status: employee.status,
  companyStatus: employee.company.status
});

const mapProgressUpdate = (progressUpdate: OkrProgressUpdateRecord): OkrProgressUpdateRecord => ({
  id: progressUpdate.id,
  companyId: progressUpdate.companyId,
  okrId: progressUpdate.okrId,
  employeeId: progressUpdate.employeeId,
  progressPercent: progressUpdate.progressPercent,
  note: progressUpdate.note,
  createdAt: progressUpdate.createdAt
});

const mapApproval = (approval: OkrApprovalRecord): OkrApprovalRecord => ({
  id: approval.id,
  companyId: approval.companyId,
  okrId: approval.okrId,
  approverEmployeeId: approval.approverEmployeeId,
  status: approval.status,
  comment: approval.comment,
  createdAt: approval.createdAt,
  updatedAt: approval.updatedAt
});

const mapOkr = (okr: {
  id: string;
  companyId: string;
  employeeId: string;
  assignedById: string;
  title: string;
  description: string | null;
  status: OKRStatus;
  dueDate: Date | null;
  createdAt: Date;
  updatedAt: Date;
  employee?: {
    id: string;
    companyId: string;
    userId: string;
    managerId: string | null;
    status: EmployeeStatus;
    company: { status: CompanyStatus };
  };
  assignedBy?: {
    id: string;
    companyId: string;
    userId: string;
    managerId: string | null;
    status: EmployeeStatus;
    company: { status: CompanyStatus };
  };
  progressUpdates?: OkrProgressUpdateRecord[];
  approvals?: OkrApprovalRecord[];
}): OkrRecord => ({
  id: okr.id,
  companyId: okr.companyId,
  employeeId: okr.employeeId,
  assignedById: okr.assignedById,
  title: okr.title,
  description: okr.description,
  status: okr.status,
  dueDate: okr.dueDate,
  createdAt: okr.createdAt,
  updatedAt: okr.updatedAt,
  ...(okr.employee ? { employee: mapEmployee(okr.employee) } : {}),
  ...(okr.assignedBy ? { assignedBy: mapEmployee(okr.assignedBy) } : {}),
  ...(okr.progressUpdates ? { progressUpdates: okr.progressUpdates.map(mapProgressUpdate) } : {}),
  ...(okr.approvals ? { approvals: okr.approvals.map(mapApproval) } : {})
});

const okrInclude = {
  employee: {
    include: {
      company: true
    }
  },
  assignedBy: {
    include: {
      company: true
    }
  },
  progressUpdates: {
    orderBy: {
      createdAt: "desc" as const
    }
  },
  approvals: {
    orderBy: {
      createdAt: "desc" as const
    }
  }
};

const buildCreatedAtFilter = (filters: OkrListFilters) => {
  if (!filters.from && !filters.to) {
    return undefined;
  }

  return {
    gte: filters.from,
    lte: filters.to
  };
};

const prismaOkrsRepository: OkrsRepository = {
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

  async createOkr(input) {
    const prisma = getPrismaClient();
    const okr = await prisma.oKR.create({
      data: {
        companyId: input.companyId,
        employeeId: input.employeeId,
        assignedById: input.assignedById,
        title: input.title,
        description: input.description ?? null,
        dueDate: input.dueDate ?? null,
        status: "ASSIGNED"
      },
      include: okrInclude
    });

    return mapOkr(okr);
  },

  async findOkrByIdInCompany(okrId, companyId) {
    const prisma = getPrismaClient();
    const okr = await prisma.oKR.findFirst({
      where: {
        id: okrId,
        companyId
      },
      include: okrInclude
    });

    return okr ? mapOkr(okr) : null;
  },

  async listOkrsForEmployee(employeeId, filters) {
    const prisma = getPrismaClient();
    const okrs = await prisma.oKR.findMany({
      where: {
        employeeId,
        status: filters.status
      },
      include: okrInclude,
      orderBy: { createdAt: "desc" }
    });

    return okrs.map(mapOkr);
  },

  async listOkrsForDirectReports(managerId, companyId) {
    const prisma = getPrismaClient();
    const okrs = await prisma.oKR.findMany({
      where: {
        companyId,
        employee: {
          managerId
        }
      },
      include: okrInclude,
      orderBy: { createdAt: "desc" }
    });

    return okrs.map(mapOkr);
  },

  async listOkrsForCompany(companyId, filters) {
    const prisma = getPrismaClient();
    const okrs = await prisma.oKR.findMany({
      where: {
        companyId,
        employeeId: filters.employeeId,
        status: filters.status,
        createdAt: buildCreatedAtFilter(filters)
      },
      include: okrInclude,
      orderBy: { createdAt: "desc" }
    });

    return okrs.map(mapOkr);
  },

  async updateOkr(okrId, companyId, input) {
    const prisma = getPrismaClient();

    await prisma.oKR.updateMany({
      where: {
        id: okrId,
        companyId
      },
      data: input
    });

    const okr = await this.findOkrByIdInCompany(okrId, companyId);

    if (!okr) {
      throw new Error("OKR update failed");
    }

    return okr;
  },

  async updateOkrStatus(okrId, companyId, status) {
    const prisma = getPrismaClient();

    await prisma.oKR.updateMany({
      where: {
        id: okrId,
        companyId
      },
      data: { status }
    });

    const okr = await this.findOkrByIdInCompany(okrId, companyId);

    if (!okr) {
      throw new Error("OKR status update failed");
    }

    return okr;
  },

  async createProgressUpdate(input) {
    const prisma = getPrismaClient();
    const progressUpdate = await prisma.oKRProgressUpdate.create({
      data: {
        companyId: input.companyId,
        okrId: input.okrId,
        employeeId: input.employeeId,
        progressPercent: input.progressPercent,
        note: input.note ?? null
      }
    });

    return mapProgressUpdate(progressUpdate);
  },

  async upsertApproval(input) {
    const prisma = getPrismaClient();
    const approval = await prisma.oKRApproval.upsert({
      where: {
        okrId_approverEmployeeId: {
          okrId: input.okrId,
          approverEmployeeId: input.approverEmployeeId
        }
      },
      create: {
        companyId: input.companyId,
        okrId: input.okrId,
        approverEmployeeId: input.approverEmployeeId,
        status: input.status,
        comment: input.comment ?? null
      },
      update: {
        status: input.status,
        comment: input.comment ?? null
      }
    });

    return mapApproval(approval);
  },

  async listApprovalsForOkr(okrId, companyId) {
    const prisma = getPrismaClient();
    const approvals = await prisma.oKRApproval.findMany({
      where: {
        okrId,
        companyId
      }
    });

    return approvals.map(mapApproval);
  }
};

let activeOkrsRepository = prismaOkrsRepository;

export const getOkrsRepository = () => activeOkrsRepository;

export const setOkrsRepositoryForTests = (repository: OkrsRepository) => {
  activeOkrsRepository = repository;
};

export const resetOkrsRepositoryForTests = () => {
  activeOkrsRepository = prismaOkrsRepository;
};
