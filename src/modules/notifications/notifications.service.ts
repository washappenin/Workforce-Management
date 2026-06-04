import type { NotificationType, Prisma } from "@prisma/client";

import { getRequiredScopedCompanyId } from "../../lib/authorization";
import { recordAuditLog, type AuditRequestContext } from "../../lib/audit";
import { NotFoundError } from "../../lib/errors";
import type { AuthenticatedUser } from "../../types/auth";
import {
  getNotificationsRepository,
  type CreateNotificationRepositoryInput,
  type NotificationRecord,
  type NotificationRecipientRecord
} from "./notifications.repository";
import type { BroadcastNotificationInput, MyNotificationsQuery } from "./notifications.validation";

const serializeNotification = (notification: NotificationRecord) => ({
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

const getNotificationScope = (actor: AuthenticatedUser, requestedCompanyId?: string | null) =>
  getRequiredScopedCompanyId(actor, requestedCompanyId);

const assertCompanyExists = async (companyId: string) => {
  const company = await getNotificationsRepository().findCompanyById(companyId);

  if (!company) {
    throw new NotFoundError("Company not found");
  }
};

const uniqueValues = (values: string[]) => Array.from(new Set(values));

const serializeRecipients = (recipients: NotificationRecipientRecord[]) =>
  recipients.map((recipient) => ({
    employeeId: recipient.employeeId,
    userId: recipient.userId,
    roles: recipient.roles
  }));

export interface CreateNotificationForUserInput {
  companyId?: string | null;
  userId: string;
  type: NotificationType;
  title: string;
  message: string;
  metadata?: Prisma.InputJsonValue | null;
}

export interface CreateNotificationsForUsersInput {
  companyId?: string | null;
  userIds: string[];
  type: NotificationType;
  title: string;
  message: string;
  metadata?: Prisma.InputJsonValue | null;
}

export const createNotificationForUser = async (input: CreateNotificationForUserInput) => {
  const notification = await getNotificationsRepository().createNotification({
    companyId: input.companyId,
    userId: input.userId,
    type: input.type,
    title: input.title,
    message: input.message,
    metadata: input.metadata
  });

  return serializeNotification(notification);
};

export const createNotificationsForUsers = async (input: CreateNotificationsForUsersInput) => {
  const userIds = uniqueValues(input.userIds);
  const notifications = await getNotificationsRepository().createNotifications(
    userIds.map((userId): CreateNotificationRepositoryInput => ({
      companyId: input.companyId,
      userId,
      type: input.type,
      title: input.title,
      message: input.message,
      metadata: input.metadata
    }))
  );

  return notifications.map(serializeNotification);
};

export const notifyLeaveStatusChanged = async (input: {
  companyId: string;
  userId: string;
  leaveRequestId: string;
  status: string;
}) =>
  createNotificationForUser({
    companyId: input.companyId,
    userId: input.userId,
    type: "LEAVE",
    title: "Leave request updated",
    message: "Your leave request status has changed.",
    metadata: { leaveRequestId: input.leaveRequestId, status: input.status }
  });

export const notifyOkrPendingUpdate = async (input: { companyId: string; userId: string; okrId?: string }) =>
  createNotificationForUser({
    companyId: input.companyId,
    userId: input.userId,
    type: "OKR",
    title: "OKR update reminder",
    message: "Please update your OKR progress.",
    metadata: input.okrId ? { okrId: input.okrId } : null
  });

export const notifyReviewDeadline = async (input: { companyId: string; userId: string; reviewCycleId?: string }) =>
  createNotificationForUser({
    companyId: input.companyId,
    userId: input.userId,
    type: "PERFORMANCE",
    title: "Review deadline reminder",
    message: "A performance review deadline is approaching.",
    metadata: input.reviewCycleId ? { reviewCycleId: input.reviewCycleId } : null
  });

export const notifyClockInReminder = async (input: { companyId: string; userId: string }) =>
  createNotificationForUser({
    companyId: input.companyId,
    userId: input.userId,
    type: "ATTENDANCE",
    title: "Clock-in reminder",
    message: "Please remember to clock in.",
    metadata: null
  });

export const notifyClockOutReminder = async (input: { companyId: string; userId: string }) =>
  createNotificationForUser({
    companyId: input.companyId,
    userId: input.userId,
    type: "ATTENDANCE",
    title: "Clock-out reminder",
    message: "Please remember to clock out.",
    metadata: null
  });

export const listMyNotifications = async (actor: AuthenticatedUser, query: MyNotificationsQuery) => {
  const notifications = await getNotificationsRepository().listNotificationsForUser(actor.id, {
    status: query.status,
    type: query.type,
    from: query.from,
    to: query.to
  });

  return notifications.map(serializeNotification);
};

export const getMyUnreadNotificationCount = async (actor: AuthenticatedUser) => {
  const unreadCount = await getNotificationsRepository().countUnreadForUser(actor.id);

  return { unreadCount };
};

export const markNotificationRead = async (actor: AuthenticatedUser, notificationId: string) => {
  const notification = await getNotificationsRepository().markNotificationRead(notificationId, actor.id, new Date());

  if (!notification) {
    throw new NotFoundError("Notification not found");
  }

  return serializeNotification(notification);
};

export const markAllMyNotificationsRead = async (actor: AuthenticatedUser) => {
  const updatedCount = await getNotificationsRepository().markAllUnreadReadForUser(actor.id, new Date());

  return { updatedCount };
};

export const broadcastNotifications = async (
  actor: AuthenticatedUser,
  input: BroadcastNotificationInput,
  auditContext: AuditRequestContext
) => {
  const repository = getNotificationsRepository();
  const companyId = getNotificationScope(actor, input.companyId);

  await assertCompanyExists(companyId);

  const uniqueEmployeeIds = input.employeeIds ? uniqueValues(input.employeeIds) : undefined;
  const recipients = uniqueEmployeeIds
    ? await repository.findActiveRecipientsByEmployeeIds(uniqueEmployeeIds, companyId, input.targetRole)
    : await repository.listActiveRecipientsForCompany(companyId, input.targetRole);

  if (uniqueEmployeeIds && recipients.length !== uniqueEmployeeIds.length) {
    throw new NotFoundError("Employee not found");
  }

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "NOTIFICATION",
    action: "NOTIFICATION_BROADCAST_CREATED",
    targetType: "NotificationBroadcast",
    targetId: null,
    metadata: {
      type: input.type,
      targetRole: input.targetRole ?? null,
      requestedEmployeeCount: uniqueEmployeeIds?.length ?? null
    },
    ...auditContext
  });

  const notifications = await repository.createNotifications(
    recipients.map((recipient) => ({
      companyId,
      userId: recipient.userId,
      type: input.type,
      title: input.title,
      message: input.message,
      metadata: {
        broadcast: true,
        targetRole: input.targetRole ?? null
      }
    }))
  );

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "NOTIFICATION",
    action: "NOTIFICATION_BROADCAST_COMPLETED",
    targetType: "NotificationBroadcast",
    targetId: null,
    metadata: {
      type: input.type,
      targetRole: input.targetRole ?? null,
      recipientCount: recipients.length,
      notificationCount: notifications.length
    },
    ...auditContext
  });

  return {
    companyId,
    type: input.type,
    targetRole: input.targetRole ?? null,
    recipients: serializeRecipients(recipients),
    notificationCount: notifications.length,
    notifications: notifications.map(serializeNotification)
  };
};
