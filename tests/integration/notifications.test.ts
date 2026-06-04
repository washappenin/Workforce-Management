import type {
  AuditActionCategory,
  CompanyStatus,
  DeviceSessionStatus,
  EmployeeStatus,
  NotificationStatus,
  NotificationType,
  RoleName,
  UserStatus
} from "@prisma/client";
import request from "supertest";

import { app } from "../../src/app";
import type { AuditLogInput, AuditRepository } from "../../src/lib/audit";
import { resetAuditRepositoryForTests, setAuditRepositoryForTests } from "../../src/lib/audit";
import { hashPassword } from "../../src/lib/password";
import type { AuthDeviceSessionRecord, AuthRepository, AuthUserRecord } from "../../src/modules/auth/auth.repository";
import { resetAuthRepositoryForTests, setAuthRepositoryForTests } from "../../src/modules/auth/auth.repository";
import type {
  CreateNotificationRepositoryInput,
  NotificationCompanyRecord,
  NotificationFilters,
  NotificationRecord,
  NotificationRecipientRecord,
  NotificationsRepository
} from "../../src/modules/notifications/notifications.repository";
import {
  resetNotificationsRepositoryForTests,
  setNotificationsRepositoryForTests
} from "../../src/modules/notifications/notifications.repository";
import { createNotificationForUser, notifyClockInReminder } from "../../src/modules/notifications/notifications.service";
import type { Role } from "../../src/types/auth";

interface MemoryState {
  companies: Map<string, NotificationCompanyRecord & { status: CompanyStatus }>;
  users: Map<string, AuthUserRecord>;
  sessions: Map<string, AuthDeviceSessionRecord>;
  recipients: Map<string, NotificationRecipientRecord>;
  notifications: Map<string, NotificationRecord>;
  audits: AuditLogInput[];
  counters: Record<string, number>;
}

const now = () => new Date("2026-06-03T08:00:00.000Z");

const makeUser = (
  id: string,
  email: string,
  companyId: string | null,
  roles: Role[],
  passwordHash: string,
  status: UserStatus = "ACTIVE" as UserStatus
): AuthUserRecord => ({
  id,
  email,
  passwordHash,
  status,
  companyId,
  roles
});

const makeRecipient = (
  employeeId: string,
  companyId: string,
  userId: string,
  roles: RoleName[],
  employeeStatus: EmployeeStatus = "ACTIVE" as EmployeeStatus,
  userStatus: UserStatus = "ACTIVE" as UserStatus,
  companyStatus: CompanyStatus = "ACTIVE" as CompanyStatus
): NotificationRecipientRecord => ({
  employeeId,
  companyId,
  userId,
  employeeStatus,
  userStatus,
  companyStatus,
  roles
});

const makeNotification = (
  id: string,
  companyId: string | null,
  userId: string,
  type: NotificationType,
  title: string,
  status: NotificationStatus = "UNREAD" as NotificationStatus
): NotificationRecord => ({
  id,
  companyId,
  userId,
  type,
  status,
  title,
  message: "Notification message",
  metadata: null,
  createdAt: now(),
  readAt: status === "READ" ? now() : null
});

const createState = (passwordHash: string): MemoryState => {
  const users = [
    makeUser("user-super-admin", "superadmin@example.test", null, ["SUPER_ADMIN"], passwordHash),
    makeUser("user-company-admin", "companyadmin@example.test", "company-1", ["COMPANY_ADMIN"], passwordHash),
    makeUser("user-hr-admin", "hradmin@example.test", "company-1", ["HR_ADMIN"], passwordHash),
    makeUser("user-manager", "manager@example.test", "company-1", ["MANAGER"], passwordHash),
    makeUser("user-employee", "employee@example.test", "company-1", ["EMPLOYEE"], passwordHash),
    makeUser("user-other-employee", "otheremployee@example.test", "company-1", ["EMPLOYEE"], passwordHash),
    makeUser("user-inactive-employee", "inactiveemployee@example.test", "company-1", ["EMPLOYEE"], passwordHash),
    makeUser("user-disabled-employee", "disabledemployee@example.test", "company-1", ["EMPLOYEE"], passwordHash, "DISABLED" as UserStatus),
    makeUser("user-company2-employee", "company2employee@example.test", "company-2", ["EMPLOYEE"], passwordHash)
  ];
  const recipients = [
    makeRecipient("employee-company-admin", "company-1", "user-company-admin", ["COMPANY_ADMIN"]),
    makeRecipient("employee-hr-admin", "company-1", "user-hr-admin", ["HR_ADMIN"]),
    makeRecipient("employee-manager", "company-1", "user-manager", ["MANAGER"]),
    makeRecipient("employee-self", "company-1", "user-employee", ["EMPLOYEE"]),
    makeRecipient("employee-other", "company-1", "user-other-employee", ["EMPLOYEE"]),
    makeRecipient("employee-inactive", "company-1", "user-inactive-employee", ["EMPLOYEE"], "INACTIVE" as EmployeeStatus),
    makeRecipient("employee-disabled-user", "company-1", "user-disabled-employee", ["EMPLOYEE"], "ACTIVE" as EmployeeStatus, "DISABLED" as UserStatus),
    makeRecipient("employee-company2", "company-2", "user-company2-employee", ["EMPLOYEE"])
  ];
  const notifications = [
    makeNotification("notification-own-unread", "company-1", "user-employee", "OKR", "Update your OKR"),
    makeNotification("notification-own-read", "company-1", "user-employee", "LEAVE", "Leave approved", "READ" as NotificationStatus),
    makeNotification("notification-other", "company-1", "user-other-employee", "SYSTEM", "Other user"),
    makeNotification("notification-company2", "company-2", "user-company2-employee", "SYSTEM", "Other company")
  ];

  return {
    companies: new Map([
      ["company-1", { id: "company-1", status: "ACTIVE" as CompanyStatus }],
      ["company-2", { id: "company-2", status: "ACTIVE" as CompanyStatus }]
    ]),
    users: new Map(users.map((user) => [user.id, user])),
    sessions: new Map(),
    recipients: new Map(recipients.map((recipient) => [recipient.employeeId, recipient])),
    notifications: new Map(notifications.map((notification) => [notification.id, notification])),
    audits: [],
    counters: {
      session: 0,
      notification: 0
    }
  };
};

const createRepositories = (state: MemoryState) => {
  const authRepository: AuthRepository = {
    async findUsersByEmail(email) {
      return Array.from(state.users.values()).filter((user) => user.email === email);
    },

    async findUserById(userId) {
      return state.users.get(userId) ?? null;
    },

    async updateLastLoginAt() {
      return undefined;
    },

    async createDeviceSession(input) {
      state.counters.session += 1;
      const session = {
        id: `auth-session-${state.counters.session}`,
        userId: input.userId,
        companyId: input.companyId ?? null,
        status: "ACTIVE" as DeviceSessionStatus
      };

      state.sessions.set(session.id, session);
      return session;
    },

    async findActiveDeviceSessionById(sessionId) {
      const session = state.sessions.get(sessionId);
      return session?.status === "ACTIVE" ? session : null;
    },

    async revokeDeviceSession(sessionId, userId) {
      const session = state.sessions.get(sessionId);

      if (session?.userId === userId) {
        state.sessions.set(sessionId, { ...session, status: "REVOKED" as DeviceSessionStatus });
      }
    }
  };

  const filterNotification = (notification: NotificationRecord, filters: NotificationFilters) =>
    (!filters.status || notification.status === filters.status) &&
    (!filters.type || notification.type === filters.type) &&
    (!filters.from || notification.createdAt >= filters.from) &&
    (!filters.to || notification.createdAt <= filters.to);

  const activeRecipients = (companyId: string, targetRole?: RoleName) =>
    Array.from(state.recipients.values()).filter(
      (recipient) =>
        recipient.companyId === companyId &&
        recipient.employeeStatus === "ACTIVE" &&
        recipient.userStatus === "ACTIVE" &&
        recipient.companyStatus === "ACTIVE" &&
        (!targetRole || recipient.roles.includes(targetRole))
    );

  const notificationsRepository: NotificationsRepository = {
    async findCompanyById(companyId) {
      return state.companies.get(companyId) ?? null;
    },

    async listNotificationsForUser(userId, filters) {
      return Array.from(state.notifications.values()).filter(
        (notification) => notification.userId === userId && filterNotification(notification, filters)
      );
    },

    async countUnreadForUser(userId) {
      return Array.from(state.notifications.values()).filter(
        (notification) => notification.userId === userId && notification.status === "UNREAD"
      ).length;
    },

    async findNotificationForUser(notificationId, userId) {
      const notification = state.notifications.get(notificationId);
      return notification?.userId === userId ? notification : null;
    },

    async markNotificationRead(notificationId, userId, readAt) {
      const notification = await this.findNotificationForUser(notificationId, userId);

      if (!notification) {
        return null;
      }

      if (notification.status === "READ") {
        return notification;
      }

      const updated = { ...notification, status: "READ" as NotificationStatus, readAt };
      state.notifications.set(notification.id, updated);

      return updated;
    },

    async markAllUnreadReadForUser(userId, readAt) {
      let updatedCount = 0;

      for (const notification of state.notifications.values()) {
        if (notification.userId === userId && notification.status === "UNREAD") {
          state.notifications.set(notification.id, { ...notification, status: "READ" as NotificationStatus, readAt });
          updatedCount += 1;
        }
      }

      return updatedCount;
    },

    async createNotification(input: CreateNotificationRepositoryInput) {
      state.counters.notification += 1;
      const notification = makeNotification(
        `notification-new-${state.counters.notification}`,
        input.companyId ?? null,
        input.userId,
        input.type,
        input.title
      );
      notification.message = input.message;
      notification.metadata = (input.metadata ?? null) as NotificationRecord["metadata"];

      state.notifications.set(notification.id, notification);
      return notification;
    },

    async createNotifications(inputs) {
      const notifications: NotificationRecord[] = [];

      for (const input of inputs) {
        notifications.push(await this.createNotification(input));
      }

      return notifications;
    },

    async listActiveRecipientsForCompany(companyId, targetRole) {
      return activeRecipients(companyId, targetRole);
    },

    async findActiveRecipientsByEmployeeIds(employeeIds, companyId, targetRole) {
      const employeeIdSet = new Set(employeeIds);
      return activeRecipients(companyId, targetRole).filter((recipient) => employeeIdSet.has(recipient.employeeId));
    }
  };

  const auditRepository: AuditRepository = {
    async create(input) {
      state.audits.push(input);
    }
  };

  return { authRepository, notificationsRepository, auditRepository };
};

describe("CP13 notifications and reminders", () => {
  let passwordHash: string;
  let state: MemoryState;

  beforeAll(async () => {
    passwordHash = await hashPassword("Password123!");
  });

  beforeEach(() => {
    state = createState(passwordHash);
    const repositories = createRepositories(state);

    setAuthRepositoryForTests(repositories.authRepository);
    setNotificationsRepositoryForTests(repositories.notificationsRepository);
    setAuditRepositoryForTests(repositories.auditRepository);
  });

  afterEach(() => {
    resetAuthRepositoryForTests();
    resetNotificationsRepositoryForTests();
    resetAuditRepositoryForTests();
  });

  const login = async (email: string) => {
    const response = await request(app).post("/api/auth/login").send({ email, password: "Password123!" }).expect(200);

    return response.body.data.accessToken as string;
  };

  const auditActions = (category?: AuditActionCategory) =>
    state.audits.filter((audit) => !category || audit.category === category).map((audit) => audit.action);

  it("lists only the current user's notifications and validates filters/auth", async () => {
    const token = await login("employee@example.test");

    const response = await request(app).get("/api/notifications/me").set("Authorization", `Bearer ${token}`).expect(200);
    const filteredResponse = await request(app)
      .get("/api/notifications/me?status=UNREAD&type=OKR")
      .set("Authorization", `Bearer ${token}`)
      .expect(200);

    expect(response.body.data.notifications.map((notification: { id: string }) => notification.id).sort()).toEqual([
      "notification-own-read",
      "notification-own-unread"
    ]);
    expect(JSON.stringify(response.body)).not.toContain("notification-other");
    expect(filteredResponse.body.data.notifications).toHaveLength(1);
    expect(filteredResponse.body.data.notifications[0].id).toBe("notification-own-unread");

    await request(app).get("/api/notifications/me").expect(401);
    await request(app).get("/api/notifications/me?status=BAD").set("Authorization", `Bearer ${token}`).expect(400);
    await request(app).get("/api/notifications/me?type=BAD").set("Authorization", `Bearer ${token}`).expect(400);
  });

  it("returns unread count for the current user only", async () => {
    const token = await login("employee@example.test");

    const response = await request(app).get("/api/notifications/me/unread-count").set("Authorization", `Bearer ${token}`).expect(200);

    expect(response.body.data.unreadCount).toBe(1);
  });

  it("marks only the current user's notification as read and handles already-read notifications safely", async () => {
    const token = await login("employee@example.test");

    const response = await request(app)
      .patch("/api/notifications/notification-own-unread/read")
      .set("Authorization", `Bearer ${token}`)
      .expect(200);
    const secondResponse = await request(app)
      .patch("/api/notifications/notification-own-unread/read")
      .set("Authorization", `Bearer ${token}`)
      .expect(200);

    await request(app)
      .patch("/api/notifications/notification-other/read")
      .set("Authorization", `Bearer ${token}`)
      .expect(404);

    expect(response.body.data.notification).toMatchObject({ id: "notification-own-unread", status: "READ" });
    expect(secondResponse.body.data.notification).toMatchObject({ id: "notification-own-unread", status: "READ" });
    expect(state.notifications.get("notification-own-unread")?.readAt).toBeTruthy();
    expect(state.notifications.get("notification-other")?.status).toBe("UNREAD");
  });

  it("marks all unread notifications for the current user without touching other users", async () => {
    state.notifications.set(
      "notification-own-unread-2",
      makeNotification("notification-own-unread-2", "company-1", "user-employee", "PERFORMANCE", "Review reminder")
    );
    const token = await login("employee@example.test");

    const response = await request(app).patch("/api/notifications/read-all").set("Authorization", `Bearer ${token}`).expect(200);

    expect(response.body.data.updatedCount).toBe(2);
    expect(state.notifications.get("notification-own-unread")?.status).toBe("READ");
    expect(state.notifications.get("notification-own-unread-2")?.status).toBe("READ");
    expect(state.notifications.get("notification-other")?.status).toBe("UNREAD");
  });

  it("allows company admins, HR admins, and scoped super admins to broadcast in-app notifications", async () => {
    const companyAdminToken = await login("companyadmin@example.test");
    const hrAdminToken = await login("hradmin@example.test");
    const superAdminToken = await login("superadmin@example.test");

    const companyAdminResponse = await request(app)
      .post("/api/admin/notifications/broadcast")
      .set("Authorization", `Bearer ${companyAdminToken}`)
      .send({ title: "Reminder", message: "Please update your OKRs.", type: "OKR", targetRole: "EMPLOYEE" })
      .expect(201);
    const hrResponse = await request(app)
      .post("/api/admin/notifications/broadcast")
      .set("Authorization", `Bearer ${hrAdminToken}`)
      .send({ title: "Review reminder", message: "Please finish reviews.", type: "PERFORMANCE", employeeIds: ["employee-self"] })
      .expect(201);
    const superResponse = await request(app)
      .post("/api/admin/notifications/broadcast")
      .set("Authorization", `Bearer ${superAdminToken}`)
      .send({ companyId: "company-2", title: "System note", message: "Company scoped.", type: "SYSTEM" })
      .expect(201);

    expect(companyAdminResponse.body.data).toMatchObject({ companyId: "company-1", notificationCount: 2, targetRole: "EMPLOYEE" });
    expect(companyAdminResponse.body.data.recipients.map((recipient: { userId: string }) => recipient.userId).sort()).toEqual([
      "user-employee",
      "user-other-employee"
    ]);
    expect(hrResponse.body.data.notificationCount).toBe(1);
    expect(superResponse.body.data).toMatchObject({ companyId: "company-2", notificationCount: 1 });
    expect(auditActions("NOTIFICATION")).toEqual([
      "NOTIFICATION_BROADCAST_CREATED",
      "NOTIFICATION_BROADCAST_COMPLETED",
      "NOTIFICATION_BROADCAST_CREATED",
      "NOTIFICATION_BROADCAST_COMPLETED",
      "NOTIFICATION_BROADCAST_CREATED",
      "NOTIFICATION_BROADCAST_COMPLETED"
    ]);
    expect(JSON.stringify(state.audits)).not.toContain("Please update your OKRs");
    expect(JSON.stringify(state.audits)).not.toContain("Please finish reviews");
    expect(JSON.stringify(state.audits)).not.toContain("Company scoped");
  });

  it("rejects unauthorized broadcasts and cross-company employee targets", async () => {
    const managerToken = await login("manager@example.test");
    const employeeToken = await login("employee@example.test");
    const companyAdminToken = await login("companyadmin@example.test");

    await request(app)
      .post("/api/admin/notifications/broadcast")
      .set("Authorization", `Bearer ${managerToken}`)
      .send({ title: "Nope", message: "Managers cannot broadcast.", type: "SYSTEM" })
      .expect(403);
    await request(app)
      .post("/api/admin/notifications/broadcast")
      .set("Authorization", `Bearer ${employeeToken}`)
      .send({ title: "Nope", message: "Employees cannot broadcast.", type: "SYSTEM" })
      .expect(403);
    await request(app)
      .post("/api/admin/notifications/broadcast")
      .set("Authorization", `Bearer ${companyAdminToken}`)
      .send({ title: "Cross company", message: "Should fail.", type: "SYSTEM", employeeIds: ["employee-company2"] })
      .expect(404);
    await request(app)
      .post("/api/admin/notifications/broadcast")
      .set("Authorization", `Bearer ${companyAdminToken}`)
      .send({ title: "", message: "Invalid.", type: "SYSTEM" })
      .expect(400);
    await request(app)
      .post("/api/admin/notifications/broadcast")
      .set("Authorization", `Bearer ${companyAdminToken}`)
      .send({ title: "Invalid type", message: "Invalid.", type: "CLOCK_IN_REMINDER" })
      .expect(400);
  });

  it("does not broadcast to inactive employees or inactive users", async () => {
    const companyAdminToken = await login("companyadmin@example.test");

    const response = await request(app)
      .post("/api/admin/notifications/broadcast")
      .set("Authorization", `Bearer ${companyAdminToken}`)
      .send({ title: "Company notice", message: "Visible to active company employees only.", type: "SYSTEM" })
      .expect(201);

    expect(response.body.data.recipients.map((recipient: { userId: string }) => recipient.userId).sort()).toEqual([
      "user-company-admin",
      "user-employee",
      "user-hr-admin",
      "user-manager",
      "user-other-employee"
    ]);
    expect(JSON.stringify(response.body)).not.toContain("user-inactive-employee");
    expect(JSON.stringify(response.body)).not.toContain("user-disabled-employee");
  });

  it("exposes internal helper functions for future modules", async () => {
    const direct = await createNotificationForUser({
      companyId: "company-1",
      userId: "user-employee",
      type: "SYSTEM",
      title: "Helper notification",
      message: "Created by helper.",
      metadata: { source: "test" }
    });
    const reminder = await notifyClockInReminder({ companyId: "company-1", userId: "user-employee" });

    expect(direct).toMatchObject({ userId: "user-employee", type: "SYSTEM", status: "UNREAD" });
    expect(reminder).toMatchObject({ userId: "user-employee", type: "ATTENDANCE", status: "UNREAD" });
    expect(state.notifications.size).toBe(6);
  });
});
