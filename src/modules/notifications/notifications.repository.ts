import type {
  CompanyStatus,
  EmployeeStatus,
  NotificationStatus,
  NotificationType,
  Prisma,
  RoleName,
  UserStatus
} from "@prisma/client";

import { getPrismaClient } from "../../lib/prisma";

export interface NotificationCompanyRecord {
  id: string;
}

export interface NotificationRecord {
  id: string;
  companyId: string | null;
  userId: string;
  type: NotificationType;
  status: NotificationStatus;
  title: string;
  message: string;
  metadata: Prisma.JsonValue | null;
  createdAt: Date;
  readAt: Date | null;
}

export interface NotificationRecipientRecord {
  employeeId: string;
  companyId: string;
  userId: string;
  employeeStatus: EmployeeStatus;
  userStatus: UserStatus;
  companyStatus: CompanyStatus;
  roles: RoleName[];
}

export interface NotificationFilters {
  status?: NotificationStatus;
  type?: NotificationType;
  from?: Date;
  to?: Date;
}

export interface CreateNotificationRepositoryInput {
  companyId?: string | null;
  userId: string;
  type: NotificationType;
  title: string;
  message: string;
  metadata?: Prisma.InputJsonValue | null;
}

export interface NotificationsRepository {
  findCompanyById(companyId: string): Promise<NotificationCompanyRecord | null>;
  listNotificationsForUser(userId: string, filters: NotificationFilters): Promise<NotificationRecord[]>;
  countUnreadForUser(userId: string): Promise<number>;
  findNotificationForUser(notificationId: string, userId: string): Promise<NotificationRecord | null>;
  markNotificationRead(notificationId: string, userId: string, readAt: Date): Promise<NotificationRecord | null>;
  markAllUnreadReadForUser(userId: string, readAt: Date): Promise<number>;
  createNotification(input: CreateNotificationRepositoryInput): Promise<NotificationRecord>;
  createNotifications(inputs: CreateNotificationRepositoryInput[]): Promise<NotificationRecord[]>;
  listActiveRecipientsForCompany(companyId: string, targetRole?: RoleName): Promise<NotificationRecipientRecord[]>;
  findActiveRecipientsByEmployeeIds(
    employeeIds: string[],
    companyId: string,
    targetRole?: RoleName
  ): Promise<NotificationRecipientRecord[]>;
}

const mapNotification = (notification: NotificationRecord): NotificationRecord => ({
  id: notification.id,
  companyId: notification.companyId,
  userId: notification.userId,
  type: notification.type,
  status: notification.status,
  title: notification.title,
  message: notification.message,
  metadata: notification.metadata,
  createdAt: notification.createdAt,
  readAt: notification.readAt
});

const mapRecipient = (employee: {
  id: string;
  companyId: string;
  userId: string;
  status: EmployeeStatus;
  company: { status: CompanyStatus };
  user: {
    status: UserStatus;
    userRoles: Array<{ role: { name: RoleName } }>;
  };
}): NotificationRecipientRecord => ({
  employeeId: employee.id,
  companyId: employee.companyId,
  userId: employee.userId,
  employeeStatus: employee.status,
  userStatus: employee.user.status,
  companyStatus: employee.company.status,
  roles: employee.user.userRoles.map((userRole) => userRole.role.name)
});

const recipientInclude = {
  company: true,
  user: {
    include: {
      userRoles: {
        include: {
          role: true
        }
      }
    }
  }
};

const activeRecipientWhere = (companyId: string, targetRole?: RoleName) => ({
  companyId,
  status: "ACTIVE" as const,
  company: {
    status: "ACTIVE" as const
  },
  user: {
    status: "ACTIVE" as const,
    ...(targetRole
      ? {
          userRoles: {
            some: {
              role: {
                name: targetRole
              }
            }
          }
        }
      : {})
  }
});

const buildCreatedAtFilter = (filters: NotificationFilters) => {
  if (!filters.from && !filters.to) {
    return undefined;
  }

  return {
    gte: filters.from,
    lte: filters.to
  };
};

const prismaNotificationsRepository: NotificationsRepository = {
  async findCompanyById(companyId) {
    const prisma = getPrismaClient();

    return prisma.company.findUnique({
      where: { id: companyId },
      select: { id: true }
    });
  },

  async listNotificationsForUser(userId, filters) {
    const prisma = getPrismaClient();
    const notifications = await prisma.notification.findMany({
      where: {
        userId,
        status: filters.status,
        type: filters.type,
        createdAt: buildCreatedAtFilter(filters)
      },
      orderBy: { createdAt: "desc" }
    });

    return notifications.map(mapNotification);
  },

  async countUnreadForUser(userId) {
    const prisma = getPrismaClient();

    return prisma.notification.count({
      where: {
        userId,
        status: "UNREAD"
      }
    });
  },

  async findNotificationForUser(notificationId, userId) {
    const prisma = getPrismaClient();
    const notification = await prisma.notification.findFirst({
      where: {
        id: notificationId,
        userId
      }
    });

    return notification ? mapNotification(notification) : null;
  },

  async markNotificationRead(notificationId, userId, readAt) {
    const current = await this.findNotificationForUser(notificationId, userId);

    if (!current) {
      return null;
    }

    if (current.status === "READ") {
      return current;
    }

    const prisma = getPrismaClient();
    const notification = await prisma.notification.update({
      where: { id: notificationId },
      data: {
        status: "READ",
        readAt
      }
    });

    return mapNotification(notification);
  },

  async markAllUnreadReadForUser(userId, readAt) {
    const prisma = getPrismaClient();
    const result = await prisma.notification.updateMany({
      where: {
        userId,
        status: "UNREAD"
      },
      data: {
        status: "READ",
        readAt
      }
    });

    return result.count;
  },

  async createNotification(input) {
    const prisma = getPrismaClient();
    const notification = await prisma.notification.create({
      data: {
        companyId: input.companyId ?? null,
        userId: input.userId,
        type: input.type,
        title: input.title,
        message: input.message,
        metadata: input.metadata ?? undefined
      }
    });

    return mapNotification(notification);
  },

  async createNotifications(inputs) {
    const notifications: NotificationRecord[] = [];

    for (const input of inputs) {
      notifications.push(await this.createNotification(input));
    }

    return notifications;
  },

  async listActiveRecipientsForCompany(companyId, targetRole) {
    const prisma = getPrismaClient();
    const employees = await prisma.employeeProfile.findMany({
      where: activeRecipientWhere(companyId, targetRole),
      include: recipientInclude,
      orderBy: { createdAt: "asc" }
    });

    return employees.map(mapRecipient);
  },

  async findActiveRecipientsByEmployeeIds(employeeIds, companyId, targetRole) {
    const prisma = getPrismaClient();
    const employees = await prisma.employeeProfile.findMany({
      where: {
        ...activeRecipientWhere(companyId, targetRole),
        id: {
          in: employeeIds
        }
      },
      include: recipientInclude,
      orderBy: { createdAt: "asc" }
    });

    return employees.map(mapRecipient);
  }
};

let activeNotificationsRepository = prismaNotificationsRepository;

export const getNotificationsRepository = () => activeNotificationsRepository;

export const setNotificationsRepositoryForTests = (repository: NotificationsRepository) => {
  activeNotificationsRepository = repository;
};

export const resetNotificationsRepositoryForTests = () => {
  activeNotificationsRepository = prismaNotificationsRepository;
};
