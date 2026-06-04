import type { EmployeeStatus, RoleName, UserStatus } from "@prisma/client";

import { getPrismaClient } from "../../lib/prisma";
import type { Role } from "../../types/auth";

export interface CompanyLookupRecord {
  id: string;
}

export interface UserLookupRecord {
  id: string;
  email: string;
  companyId: string | null;
}

export interface EmployeeUserRecord {
  id: string;
  email: string;
  companyId: string | null;
  status: UserStatus;
  roles: Role[];
}

export interface EmployeeRelationRecord {
  id: string;
  name: string;
}

export interface EmployeeManagerRecord {
  id: string;
  employeeCode: string;
  firstName: string;
  lastName: string;
}

export interface EmployeeRecord {
  id: string;
  companyId: string;
  userId: string;
  departmentId: string | null;
  designationId: string | null;
  managerId: string | null;
  employeeCode: string;
  firstName: string;
  lastName: string;
  phone: string | null;
  status: EmployeeStatus;
  hireDate: Date | null;
  createdAt: Date;
  updatedAt: Date;
  user: EmployeeUserRecord;
  department: EmployeeRelationRecord | null;
  designation: EmployeeRelationRecord | null;
  manager: EmployeeManagerRecord | null;
}

export interface CreateEmployeeRepositoryInput {
  companyId: string;
  email: string;
  passwordHash: string;
  roles: RoleName[];
  employeeCode: string;
  firstName: string;
  lastName: string;
  phone?: string | null;
  departmentId?: string | null;
  designationId?: string | null;
  managerId?: string | null;
  hireDate?: Date | null;
}

export interface UpdateEmployeeRepositoryInput {
  employeeCode?: string;
  firstName?: string;
  lastName?: string;
  phone?: string | null;
  departmentId?: string | null;
  designationId?: string | null;
  hireDate?: Date | null;
}

export interface EmployeesRepository {
  findCompanyById(companyId: string): Promise<CompanyLookupRecord | null>;
  findUserByEmail(email: string): Promise<UserLookupRecord | null>;
  findDepartmentByIdInCompany(departmentId: string, companyId: string): Promise<{ id: string } | null>;
  findDesignationByIdInCompany(designationId: string, companyId: string): Promise<{ id: string } | null>;
  findEmployeeCodeInCompany(employeeCode: string, companyId: string): Promise<EmployeeRecord | null>;
  findByIdInCompany(employeeId: string, companyId: string): Promise<EmployeeRecord | null>;
  findByUserId(userId: string): Promise<EmployeeRecord | null>;
  list(companyId: string): Promise<EmployeeRecord[]>;
  create(input: CreateEmployeeRepositoryInput): Promise<EmployeeRecord>;
  update(employeeId: string, companyId: string, input: UpdateEmployeeRepositoryInput): Promise<EmployeeRecord>;
  updateStatus(
    employeeId: string,
    companyId: string,
    status: EmployeeStatus,
    userStatus: UserStatus
  ): Promise<EmployeeRecord>;
  updateManager(employeeId: string, companyId: string, managerId: string | null): Promise<EmployeeRecord>;
}

const employeeInclude = {
  user: {
    include: {
      userRoles: {
        include: {
          role: true
        }
      }
    }
  },
  department: true,
  designation: true,
  manager: true
};

const mapEmployee = (employee: {
  id: string;
  companyId: string;
  userId: string;
  departmentId: string | null;
  designationId: string | null;
  managerId: string | null;
  employeeCode: string;
  firstName: string;
  lastName: string;
  phone: string | null;
  status: EmployeeStatus;
  hireDate: Date | null;
  createdAt: Date;
  updatedAt: Date;
  user: {
    id: string;
    email: string;
    companyId: string | null;
    status: UserStatus;
    userRoles: Array<{ role: { name: RoleName } }>;
  };
  department: { id: string; name: string } | null;
  designation: { id: string; title: string } | null;
  manager: { id: string; employeeCode: string; firstName: string; lastName: string } | null;
}): EmployeeRecord => ({
  id: employee.id,
  companyId: employee.companyId,
  userId: employee.userId,
  departmentId: employee.departmentId,
  designationId: employee.designationId,
  managerId: employee.managerId,
  employeeCode: employee.employeeCode,
  firstName: employee.firstName,
  lastName: employee.lastName,
  phone: employee.phone,
  status: employee.status,
  hireDate: employee.hireDate,
  createdAt: employee.createdAt,
  updatedAt: employee.updatedAt,
  user: {
    id: employee.user.id,
    email: employee.user.email,
    companyId: employee.user.companyId,
    status: employee.user.status,
    roles: employee.user.userRoles.map((userRole) => userRole.role.name)
  },
  department: employee.department ? { id: employee.department.id, name: employee.department.name } : null,
  designation: employee.designation ? { id: employee.designation.id, name: employee.designation.title } : null,
  manager: employee.manager
    ? {
        id: employee.manager.id,
        employeeCode: employee.manager.employeeCode,
        firstName: employee.manager.firstName,
        lastName: employee.manager.lastName
      }
    : null
});

const prismaEmployeesRepository: EmployeesRepository = {
  async findCompanyById(companyId) {
    const prisma = getPrismaClient();

    return prisma.company.findUnique({
      where: { id: companyId },
      select: { id: true }
    });
  },

  async findUserByEmail(email) {
    const prisma = getPrismaClient();

    return prisma.user.findFirst({
      where: { email },
      select: {
        id: true,
        email: true,
        companyId: true
      }
    });
  },

  async findDepartmentByIdInCompany(departmentId, companyId) {
    const prisma = getPrismaClient();

    return prisma.department.findFirst({
      where: {
        id: departmentId,
        companyId
      },
      select: { id: true }
    });
  },

  async findDesignationByIdInCompany(designationId, companyId) {
    const prisma = getPrismaClient();

    return prisma.designation.findFirst({
      where: {
        id: designationId,
        companyId
      },
      select: { id: true }
    });
  },

  async findEmployeeCodeInCompany(employeeCode, companyId) {
    const prisma = getPrismaClient();
    const employee = await prisma.employeeProfile.findFirst({
      where: {
        employeeCode,
        companyId
      },
      include: employeeInclude
    });

    return employee ? mapEmployee(employee) : null;
  },

  async findByIdInCompany(employeeId, companyId) {
    const prisma = getPrismaClient();
    const employee = await prisma.employeeProfile.findFirst({
      where: {
        id: employeeId,
        companyId
      },
      include: employeeInclude
    });

    return employee ? mapEmployee(employee) : null;
  },

  async findByUserId(userId) {
    const prisma = getPrismaClient();
    const employee = await prisma.employeeProfile.findUnique({
      where: { userId },
      include: employeeInclude
    });

    return employee ? mapEmployee(employee) : null;
  },

  async list(companyId) {
    const prisma = getPrismaClient();
    const employees = await prisma.employeeProfile.findMany({
      where: { companyId },
      include: employeeInclude,
      orderBy: { createdAt: "desc" }
    });

    return employees.map(mapEmployee);
  },

  async create(input) {
    const prisma = getPrismaClient();

    const created = await prisma.$transaction(async (transaction) => {
      const user = await transaction.user.create({
        data: {
          email: input.email,
          passwordHash: input.passwordHash,
          companyId: input.companyId,
          status: "ACTIVE"
        }
      });

      for (const roleName of input.roles) {
        const role = await transaction.role.upsert({
          where: { name: roleName },
          update: {},
          create: { name: roleName }
        });

        await transaction.userRole.create({
          data: {
            userId: user.id,
            roleId: role.id,
            companyId: input.companyId
          }
        });
      }

      const employee = await transaction.employeeProfile.create({
        data: {
          companyId: input.companyId,
          userId: user.id,
          employeeCode: input.employeeCode,
          firstName: input.firstName,
          lastName: input.lastName,
          phone: input.phone ?? null,
          departmentId: input.departmentId ?? null,
          designationId: input.designationId ?? null,
          managerId: input.managerId ?? null,
          hireDate: input.hireDate ?? null,
          status: "ACTIVE"
        }
      });

      return transaction.employeeProfile.findUniqueOrThrow({
        where: { id: employee.id },
        include: employeeInclude
      });
    });

    return mapEmployee(created);
  },

  async update(employeeId, companyId, input) {
    const prisma = getPrismaClient();

    await prisma.employeeProfile.updateMany({
      where: {
        id: employeeId,
        companyId
      },
      data: input
    });

    const employee = await this.findByIdInCompany(employeeId, companyId);

    if (!employee) {
      throw new Error("Employee update failed");
    }

    return employee;
  },

  async updateStatus(employeeId, companyId, status, userStatus) {
    const prisma = getPrismaClient();

    const updated = await prisma.$transaction(async (transaction) => {
      const current = await transaction.employeeProfile.findFirst({
        where: {
          id: employeeId,
          companyId
        },
        select: {
          id: true,
          userId: true
        }
      });

      if (!current) {
        throw new Error("Employee status update failed");
      }

      await transaction.employeeProfile.update({
        where: { id: current.id },
        data: { status }
      });

      await transaction.user.update({
        where: { id: current.userId },
        data: { status: userStatus }
      });

      return transaction.employeeProfile.findUniqueOrThrow({
        where: { id: current.id },
        include: employeeInclude
      });
    });

    return mapEmployee(updated);
  },

  async updateManager(employeeId, companyId, managerId) {
    const prisma = getPrismaClient();

    await prisma.employeeProfile.updateMany({
      where: {
        id: employeeId,
        companyId
      },
      data: { managerId }
    });

    const employee = await this.findByIdInCompany(employeeId, companyId);

    if (!employee) {
      throw new Error("Manager update failed");
    }

    return employee;
  }
};

let activeEmployeesRepository = prismaEmployeesRepository;

export const getEmployeesRepository = () => activeEmployeesRepository;

export const setEmployeesRepositoryForTests = (repository: EmployeesRepository) => {
  activeEmployeesRepository = repository;
};

export const resetEmployeesRepositoryForTests = () => {
  activeEmployeesRepository = prismaEmployeesRepository;
};
