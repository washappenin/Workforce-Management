import { Router } from "express";

import { asyncHandler } from "../../middleware/asyncHandler";
import { requireAuthentication } from "../../middleware/auth.middleware";
import { requireAnyRole } from "../../middleware/role.middleware";
import { validateRequest } from "../../middleware/validation.middleware";
import {
  broadcastNotificationsController,
  getMyUnreadNotificationCountController,
  listMyNotificationsController,
  markAllMyNotificationsReadController,
  markNotificationReadController
} from "./notifications.controller";
import {
  broadcastNotificationSchema,
  myNotificationsQuerySchema,
  notificationIdParamsSchema
} from "./notifications.validation";

export const notificationsRouter = Router();
export const notificationsAdminRouter = Router();

notificationsRouter.use(requireAuthentication);
notificationsRouter.get(
  "/me",
  validateRequest({ query: myNotificationsQuerySchema }, { statusCode: 400 }),
  asyncHandler(listMyNotificationsController)
);
notificationsRouter.get("/me/unread-count", asyncHandler(getMyUnreadNotificationCountController));
notificationsRouter.patch("/read-all", asyncHandler(markAllMyNotificationsReadController));
notificationsRouter.patch(
  "/:notificationId/read",
  validateRequest({ params: notificationIdParamsSchema }, { statusCode: 400 }),
  asyncHandler(markNotificationReadController)
);

notificationsAdminRouter.use(requireAuthentication, requireAnyRole(["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN"]));
notificationsAdminRouter.post(
  "/broadcast",
  validateRequest({ body: broadcastNotificationSchema }, { statusCode: 400 }),
  asyncHandler(broadcastNotificationsController)
);
