import type { CompanyStatus, EmployeeStatus, ShiftStatus } from "@prisma/client";

import { getPrismaClient } from "../../lib/prisma";

export interface ShiftCompanyRecord {
  id: string;
}

export interface ShiftEmployeeProfileRecord {
  id: string;
  companyId: string;
  userId: string;
  status: EmployeeStatus;
  companyStatus: CompanyStatus;
}

export interface ShiftRecord {
  id: string;
  companyId: string;
  name: string;
  startTime: string;
  endTime: string;
  status: ShiftStatus;
  createdAt: Date;
  updatedAt: Date;
}

export interface ShiftAssignmentRecord {
  id: string;
  companyId: string;
  employeeId: string;
  shiftId: string;
  startsOn: Date;
  endsOn: Date | null;
  createdAt: Date;
  updatedAt: Date;
  shift?: ShiftRecord;
}

export interface CreateShiftRepositoryInput {
  companyId: string;
  name: string;
  startTime: string;
  endTime: string;
}

export interface UpdateShiftRepositoryInput {
  name?: string;
  startTime?: string;
  endTime?: string;
}

export interface CreateShiftAssignmentRepositoryInput {
  companyId: string;
  employeeId: string;
  shiftId: string;
  startsOn: Date;
  endsOn?: Date | null;
}

export interface UpdateShiftAssignmentRepositoryInput {
  startsOn?: Date;
  endsOn?: Date | null;
}

export interface ShiftAssignmentOverlapInput {
  companyId: string;
  employeeId: string;
  shiftId: string;
  startsOn: Date;
  endsOn?: Date | null;
  excludeAssignmentId?: string;
}

export interface ShiftsRepository {
  findCompanyById(companyId: string): Promise<ShiftCompanyRecord | null>;
  findEmployeeByIdInCompany(employeeId: string, companyId: string): Promise<ShiftEmployeeProfileRecord | null>;
  findEmployeeByUserId(userId: string): Promise<ShiftEmployeeProfileRecord | null>;
  createShift(input: CreateShiftRepositoryInput): Promise<ShiftRecord>;
  listShifts(companyId: string): Promise<ShiftRecord[]>;
  findShiftByIdInCompany(shiftId: string, companyId: string): Promise<ShiftRecord | null>;
  findShiftByNameInCompany(name: string, companyId: string): Promise<ShiftRecord | null>;
  updateShift(shiftId: string, companyId: string, input: UpdateShiftRepositoryInput): Promise<ShiftRecord>;
  updateShiftStatus(shiftId: string, companyId: string, status: ShiftStatus): Promise<ShiftRecord>;
  createAssignment(input: CreateShiftAssignmentRepositoryInput): Promise<ShiftAssignmentRecord>;
  listAssignmentsForShift(shiftId: string, companyId: string): Promise<ShiftAssignmentRecord[]>;
  listAssignmentsForEmployeeCurrentOrFuture(employeeId: string, companyId: string, today: Date): Promise<ShiftAssignmentRecord[]>;
  findAssignmentByIdInCompany(assignmentId: string, companyId: string): Promise<ShiftAssignmentRecord | null>;
  findOverlappingAssignment(input: ShiftAssignmentOverlapInput): Promise<ShiftAssignmentRecord | null>;
  updateAssignment(
    assignmentId: string,
    companyId: string,
    input: UpdateShiftAssignmentRepositoryInput
  ): Promise<ShiftAssignmentRecord>;
  deleteAssignment(assignmentId: string, companyId: string): Promise<void>;
}

const mapShift = (shift: ShiftRecord): ShiftRecord => ({
  id: shift.id,
  companyId: shift.companyId,
  name: shift.name,
  startTime: shift.startTime,
  endTime: shift.endTime,
  status: shift.status,
  createdAt: shift.createdAt,
  updatedAt: shift.updatedAt
});

const mapAssignment = (
  assignment: {
    id: string;
    companyId: string;
    employeeId: string;
    shiftId: string;
    startsOn: Date;
    endsOn: Date | null;
    createdAt: Date;
    updatedAt: Date;
    shift?: ShiftRecord;
  }
): ShiftAssignmentRecord => ({
  id: assignment.id,
  companyId: assignment.companyId,
  employeeId: assignment.employeeId,
  shiftId: assignment.shiftId,
  startsOn: assignment.startsOn,
  endsOn: assignment.endsOn,
  createdAt: assignment.createdAt,
  updatedAt: assignment.updatedAt,
  ...(assignment.shift ? { shift: mapShift(assignment.shift) } : {})
});

const prismaShiftsRepository: ShiftsRepository = {
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

    if (!employee) {
      return null;
    }

    return {
      id: employee.id,
      companyId: employee.companyId,
      userId: employee.userId,
      status: employee.status,
      companyStatus: employee.company.status
    };
  },

  async findEmployeeByUserId(userId) {
    const prisma = getPrismaClient();
    const employee = await prisma.employeeProfile.findUnique({
      where: { userId },
      include: {
        company: true
      }
    });

    if (!employee) {
      return null;
    }

    return {
      id: employee.id,
      companyId: employee.companyId,
      userId: employee.userId,
      status: employee.status,
      companyStatus: employee.company.status
    };
  },

  async createShift(input) {
    const prisma = getPrismaClient();
    const shift = await prisma.shift.create({
      data: {
        companyId: input.companyId,
        name: input.name,
        startTime: input.startTime,
        endTime: input.endTime
      }
    });

    return mapShift(shift);
  },

  async listShifts(companyId) {
    const prisma = getPrismaClient();
    const shifts = await prisma.shift.findMany({
      where: { companyId },
      orderBy: { createdAt: "desc" }
    });

    return shifts.map(mapShift);
  },

  async findShiftByIdInCompany(shiftId, companyId) {
    const prisma = getPrismaClient();
    const shift = await prisma.shift.findFirst({
      where: {
        id: shiftId,
        companyId
      }
    });

    return shift ? mapShift(shift) : null;
  },

  async findShiftByNameInCompany(name, companyId) {
    const prisma = getPrismaClient();
    const shift = await prisma.shift.findFirst({
      where: {
        name,
        companyId
      }
    });

    return shift ? mapShift(shift) : null;
  },

  async updateShift(shiftId, companyId, input) {
    const prisma = getPrismaClient();

    await prisma.shift.updateMany({
      where: {
        id: shiftId,
        companyId
      },
      data: input
    });

    const shift = await this.findShiftByIdInCompany(shiftId, companyId);

    if (!shift) {
      throw new Error("Shift update failed");
    }

    return shift;
  },

  async updateShiftStatus(shiftId, companyId, status) {
    const prisma = getPrismaClient();

    await prisma.shift.updateMany({
      where: {
        id: shiftId,
        companyId
      },
      data: { status }
    });

    const shift = await this.findShiftByIdInCompany(shiftId, companyId);

    if (!shift) {
      throw new Error("Shift status update failed");
    }

    return shift;
  },

  async createAssignment(input) {
    const prisma = getPrismaClient();
    const assignment = await prisma.employeeShiftAssignment.create({
      data: {
        companyId: input.companyId,
        employeeId: input.employeeId,
        shiftId: input.shiftId,
        startsOn: input.startsOn,
        endsOn: input.endsOn ?? null
      },
      include: {
        shift: true
      }
    });

    return mapAssignment(assignment);
  },

  async listAssignmentsForShift(shiftId, companyId) {
    const prisma = getPrismaClient();
    const assignments = await prisma.employeeShiftAssignment.findMany({
      where: {
        shiftId,
        companyId
      },
      include: {
        shift: true
      },
      orderBy: { startsOn: "desc" }
    });

    return assignments.map(mapAssignment);
  },

  async listAssignmentsForEmployeeCurrentOrFuture(employeeId, companyId, today) {
    const prisma = getPrismaClient();
    const assignments = await prisma.employeeShiftAssignment.findMany({
      where: {
        employeeId,
        companyId,
        OR: [{ endsOn: null }, { endsOn: { gte: today } }]
      },
      include: {
        shift: true
      },
      orderBy: { startsOn: "asc" }
    });

    return assignments.map(mapAssignment);
  },

  async findAssignmentByIdInCompany(assignmentId, companyId) {
    const prisma = getPrismaClient();
    const assignment = await prisma.employeeShiftAssignment.findFirst({
      where: {
        id: assignmentId,
        companyId
      },
      include: {
        shift: true
      }
    });

    return assignment ? mapAssignment(assignment) : null;
  },

  async findOverlappingAssignment(input) {
    const prisma = getPrismaClient();
    const assignment = await prisma.employeeShiftAssignment.findFirst({
      where: {
        companyId: input.companyId,
        employeeId: input.employeeId,
        shiftId: input.shiftId,
        ...(input.excludeAssignmentId ? { id: { not: input.excludeAssignmentId } } : {}),
        ...(input.endsOn ? { startsOn: { lte: input.endsOn } } : {}),
        OR: [{ endsOn: null }, { endsOn: { gte: input.startsOn } }]
      },
      include: {
        shift: true
      }
    });

    return assignment ? mapAssignment(assignment) : null;
  },

  async updateAssignment(assignmentId, companyId, input) {
    const prisma = getPrismaClient();

    await prisma.employeeShiftAssignment.updateMany({
      where: {
        id: assignmentId,
        companyId
      },
      data: {
        ...(input.startsOn !== undefined ? { startsOn: input.startsOn } : {}),
        ...(input.endsOn !== undefined ? { endsOn: input.endsOn } : {})
      }
    });

    const assignment = await this.findAssignmentByIdInCompany(assignmentId, companyId);

    if (!assignment) {
      throw new Error("Shift assignment update failed");
    }

    return assignment;
  },

  async deleteAssignment(assignmentId, companyId) {
    const prisma = getPrismaClient();

    await prisma.employeeShiftAssignment.deleteMany({
      where: {
        id: assignmentId,
        companyId
      }
    });
  }
};

let activeShiftsRepository = prismaShiftsRepository;

export const getShiftsRepository = () => activeShiftsRepository;

export const setShiftsRepositoryForTests = (repository: ShiftsRepository) => {
  activeShiftsRepository = repository;
};

export const resetShiftsRepositoryForTests = () => {
  activeShiftsRepository = prismaShiftsRepository;
};
