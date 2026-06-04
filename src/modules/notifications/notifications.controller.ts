import type { Request, Response } from "express";

import { getAuditRequestContext } from "../../lib/audit";
import {
  broadcastNotifications,
  getMyUnreadNotificationCount,
  listMyNotifications,
  markAllMyNotificationsRead,
  markNotificationRead
} from "./notifications.service";
import type { BroadcastNotificationInput, MyNotificationsQuery } from "./notifications.validation";

export const listMyNotificationsController = async (req: Request, res: Response) => {
  const notifications = await listMyNotifications(req.user!, req.query as MyNotificationsQuery);

  res.status(200).json({ data: { notifications } });
};

export const getMyUnreadNotificationCountController = async (req: Request, res: Response) => {
  const result = await getMyUnreadNotificationCount(req.user!);

  res.status(200).json({ data: result });
};

export const markNotificationReadController = async (req: Request, res: Response) => {
  const notification = await markNotificationRead(req.user!, req.params.notificationId);

  res.status(200).json({ data: { notification } });
};

export const markAllMyNotificationsReadController = async (req: Request, res: Response) => {
  const result = await markAllMyNotificationsRead(req.user!);

  res.status(200).json({ data: result });
};

export const broadcastNotificationsController = async (req: Request, res: Response) => {
  const result = await broadcastNotifications(req.user!, req.body as BroadcastNotificationInput, getAuditRequestContext(req));

  res.status(201).json({ data: result });
};
