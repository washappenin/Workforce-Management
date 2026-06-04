import type { DeviceSession, RoleName, UserStatus } from "@prisma/client";

import { getPrismaClient } from "../../lib/prisma";
import type { Role } from "../../types/auth";

export interface AuthUserRecord {
  id: string;
  email: string;
  passwordHash: string;
  status: UserStatus;
  companyId: string | null;
  roles: Role[];
}

export interface CreateDeviceSessionInput {
  userId: string;
  companyId?: string | null;
  deviceId?: string | null;
  platform?: string | null;
}

export interface AuthDeviceSessionRecord {
  id: string;
  userId: string;
  companyId: string | null;
  status: DeviceSession["status"];
}

export interface AuthRepository {
  findUsersByEmail(email: string): Promise<AuthUserRecord[]>;
  findUserById(userId: string): Promise<AuthUserRecord | null>;
  updateLastLoginAt(userId: string, lastLoginAt: Date): Promise<void>;
  createDeviceSession(input: CreateDeviceSessionInput): Promise<AuthDeviceSessionRecord>;
  findActiveDeviceSessionById(sessionId: string): Promise<AuthDeviceSessionRecord | null>;
  revokeDeviceSession(sessionId: string, userId: string): Promise<void>;
}

const mapUser = (user: {
  id: string;
  email: string;
  passwordHash: string;
  status: UserStatus;
  companyId: string | null;
  userRoles: Array<{ role: { name: RoleName } }>;
}): AuthUserRecord => ({
  id: user.id,
  email: user.email,
  passwordHash: user.passwordHash,
  status: user.status,
  companyId: user.companyId,
  roles: user.userRoles.map((userRole) => userRole.role.name)
});

const prismaAuthRepository: AuthRepository = {
  async findUsersByEmail(email) {
    const prisma = getPrismaClient();
    const users = await prisma.user.findMany({
      where: { email },
      include: {
        userRoles: {
          include: {
            role: true
          }
        }
      }
    });

    return users.map(mapUser);
  },

  async findUserById(userId) {
    const prisma = getPrismaClient();
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        userRoles: {
          include: {
            role: true
          }
        }
      }
    });

    return user ? mapUser(user) : null;
  },

  async updateLastLoginAt(userId, lastLoginAt) {
    const prisma = getPrismaClient();
    await prisma.user.update({
      where: { id: userId },
      data: { lastLoginAt }
    });
  },

  async createDeviceSession(input) {
    const prisma = getPrismaClient();
    const session = await prisma.deviceSession.create({
      data: {
        userId: input.userId,
        companyId: input.companyId ?? null,
        deviceId: input.deviceId ?? null,
        platform: input.platform ?? null,
        status: "ACTIVE",
        lastSeenAt: new Date()
      }
    });

    return {
      id: session.id,
      userId: session.userId,
      companyId: session.companyId,
      status: session.status
    };
  },

  async findActiveDeviceSessionById(sessionId) {
    const prisma = getPrismaClient();
    const session = await prisma.deviceSession.findFirst({
      where: {
        id: sessionId,
        status: "ACTIVE"
      }
    });

    if (!session) {
      return null;
    }

    return {
      id: session.id,
      userId: session.userId,
      companyId: session.companyId,
      status: session.status
    };
  },

  async revokeDeviceSession(sessionId, userId) {
    const prisma = getPrismaClient();
    await prisma.deviceSession.updateMany({
      where: {
        id: sessionId,
        userId,
        status: "ACTIVE"
      },
      data: {
        status: "REVOKED"
      }
    });
  }
};

let activeRepository = prismaAuthRepository;

export const getAuthRepository = () => activeRepository;

export const setAuthRepositoryForTests = (repository: AuthRepository) => {
  activeRepository = repository;
};

export const resetAuthRepositoryForTests = () => {
  activeRepository = prismaAuthRepository;
};
