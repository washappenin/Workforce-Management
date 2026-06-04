import type { AttendanceEventType, AttendanceStatus, CompanyStatus, EmployeeStatus, Prisma } from "@prisma/client";

import { getPrismaClient } from "../../lib/prisma";

export interface AttendanceEmployeeProfile {
  id: string;
  companyId: string;
  userId: string;
  status: EmployeeStatus;
  companyStatus: CompanyStatus;
}

export interface AttendanceGeofenceRecord {
  id: string;
  companyId: string;
  latitude: number;
  longitude: number;
  radiusMeters: number;
}

export interface AttendanceSessionRecord {
  id: string;
  companyId: string;
  employeeId: string;
  clockInAt: Date;
  clockOutAt: Date | null;
  status: AttendanceStatus;
  clockInFaceVerified: boolean;
  clockInGeofenceId: string | null;
  clockOutGeofenceId: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface AttendanceEventRecord {
  id: string;
  companyId: string;
  employeeId: string;
  attendanceSessionId: string | null;
  type: AttendanceEventType;
  createdAt: Date;
}

export interface AttendanceListFilters {
  employeeId?: string;
  from?: Date;
  to?: Date;
  status?: AttendanceStatus;
}

export interface CreateClockInSessionInput {
  companyId: string;
  employeeId: string;
  clockInAt: Date;
  latitude: number;
  longitude: number;
  geofenceId: string;
  clockInFaceVerified: boolean;
}

export interface CloseAttendanceSessionInput {
  sessionId: string;
  companyId: string;
  employeeId: string;
  clockOutAt: Date;
  latitude: number;
  longitude: number;
  geofenceId: string;
}

export interface CreateAttendanceEventInput {
  companyId: string;
  employeeId: string;
  attendanceSessionId: string;
  type: AttendanceEventType;
  latitude: number;
  longitude: number;
  metadata?: Record<string, unknown>;
}

export interface AttendanceRepository {
  findEmployeeProfileByUserId(userId: string): Promise<AttendanceEmployeeProfile | null>;
  verifyEmployeeBelongsToCompany(employeeId: string, companyId: string): Promise<boolean>;
  findOpenSessionByEmployeeId(employeeId: string): Promise<AttendanceSessionRecord | null>;
  findActiveGeofencesForCompany(companyId: string): Promise<AttendanceGeofenceRecord[]>;
  createClockInSession(input: CreateClockInSessionInput): Promise<AttendanceSessionRecord>;
  closeAttendanceSession(input: CloseAttendanceSessionInput): Promise<AttendanceSessionRecord>;
  createAttendanceEvent(input: CreateAttendanceEventInput): Promise<AttendanceEventRecord>;
  listMyAttendance(employeeId: string, filters: AttendanceListFilters): Promise<AttendanceSessionRecord[]>;
  listCompanyAttendance(companyId: string, filters: AttendanceListFilters): Promise<AttendanceSessionRecord[]>;
}

const decimalToNumber = (value: { toNumber(): number } | number) =>
  typeof value === "number" ? value : value.toNumber();

const mapSession = (session: {
  id: string;
  companyId: string;
  employeeId: string;
  clockInAt: Date;
  clockOutAt: Date | null;
  status: AttendanceStatus;
  clockInFaceVerified: boolean;
  clockInGeofenceId: string | null;
  clockOutGeofenceId: string | null;
  createdAt: Date;
  updatedAt: Date;
}): AttendanceSessionRecord => ({
  id: session.id,
  companyId: session.companyId,
  employeeId: session.employeeId,
  clockInAt: session.clockInAt,
  clockOutAt: session.clockOutAt,
  status: session.status,
  clockInFaceVerified: session.clockInFaceVerified,
  clockInGeofenceId: session.clockInGeofenceId,
  clockOutGeofenceId: session.clockOutGeofenceId,
  createdAt: session.createdAt,
  updatedAt: session.updatedAt
});

const buildDateFilter = (filters: AttendanceListFilters) => {
  if (!filters.from && !filters.to) {
    return undefined;
  }

  return {
    gte: filters.from,
    lte: filters.to
  };
};

const prismaAttendanceRepository: AttendanceRepository = {
  async findEmployeeProfileByUserId(userId) {
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

  async verifyEmployeeBelongsToCompany(employeeId, companyId) {
    const prisma = getPrismaClient();
    const count = await prisma.employeeProfile.count({
      where: {
        id: employeeId,
        companyId
      }
    });

    return count > 0;
  },

  async findOpenSessionByEmployeeId(employeeId) {
    const prisma = getPrismaClient();
    const session = await prisma.attendanceSession.findFirst({
      where: {
        employeeId,
        status: "OPEN"
      },
      orderBy: { clockInAt: "desc" }
    });

    return session ? mapSession(session) : null;
  },

  async findActiveGeofencesForCompany(companyId) {
    const prisma = getPrismaClient();
    const geofences = await prisma.geofence.findMany({
      where: {
        companyId,
        status: "ACTIVE"
      }
    });

    return geofences.map((geofence) => ({
      id: geofence.id,
      companyId: geofence.companyId,
      latitude: decimalToNumber(geofence.latitude),
      longitude: decimalToNumber(geofence.longitude),
      radiusMeters: geofence.radiusMeters
    }));
  },

  async createClockInSession(input) {
    const prisma = getPrismaClient();
    const session = await prisma.attendanceSession.create({
      data: {
        companyId: input.companyId,
        employeeId: input.employeeId,
        clockInAt: input.clockInAt,
        clockInLatitude: input.latitude,
        clockInLongitude: input.longitude,
        clockInGeofenceId: input.geofenceId,
        clockInFaceVerified: input.clockInFaceVerified,
        status: "OPEN"
      }
    });

    return mapSession(session);
  },

  async closeAttendanceSession(input) {
    const prisma = getPrismaClient();

    await prisma.attendanceSession.updateMany({
      where: {
        id: input.sessionId,
        employeeId: input.employeeId,
        companyId: input.companyId,
        status: "OPEN"
      },
      data: {
        clockOutAt: input.clockOutAt,
        clockOutLatitude: input.latitude,
        clockOutLongitude: input.longitude,
        clockOutGeofenceId: input.geofenceId,
        status: "CLOSED"
      }
    });

    const session = await prisma.attendanceSession.findFirst({
      where: {
        id: input.sessionId,
        employeeId: input.employeeId,
        companyId: input.companyId
      }
    });

    if (!session) {
      throw new Error("Attendance session close failed");
    }

    return mapSession(session);
  },

  async createAttendanceEvent(input) {
    const prisma = getPrismaClient();
    const event = await prisma.attendanceEvent.create({
      data: {
        companyId: input.companyId,
        employeeId: input.employeeId,
        attendanceSessionId: input.attendanceSessionId,
        type: input.type,
        latitude: input.latitude,
        longitude: input.longitude,
        metadata: input.metadata as Prisma.InputJsonValue | undefined
      }
    });

    return {
      id: event.id,
      companyId: event.companyId,
      employeeId: event.employeeId,
      attendanceSessionId: event.attendanceSessionId,
      type: event.type,
      createdAt: event.createdAt
    };
  },

  async listMyAttendance(employeeId, filters) {
    const prisma = getPrismaClient();
    const sessions = await prisma.attendanceSession.findMany({
      where: {
        employeeId,
        status: filters.status,
        clockInAt: buildDateFilter(filters)
      },
      orderBy: { clockInAt: "desc" }
    });

    return sessions.map(mapSession);
  },

  async listCompanyAttendance(companyId, filters) {
    const prisma = getPrismaClient();
    const sessions = await prisma.attendanceSession.findMany({
      where: {
        companyId,
        employeeId: filters.employeeId,
        status: filters.status,
        clockInAt: buildDateFilter(filters)
      },
      orderBy: { clockInAt: "desc" }
    });

    return sessions.map(mapSession);
  }
};

let activeAttendanceRepository = prismaAttendanceRepository;

export const getAttendanceRepository = () => activeAttendanceRepository;

export const setAttendanceRepositoryForTests = (repository: AttendanceRepository) => {
  activeAttendanceRepository = repository;
};

export const resetAttendanceRepositoryForTests = () => {
  activeAttendanceRepository = prismaAttendanceRepository;
};
