import { NotificationStatus, NotificationType, RoleName } from "@prisma/client";
import { z } from "zod";

const idSchema = z.string().trim().min(1);
const textSchema = z.string().trim().min(1);

export const notificationIdParamsSchema = z.object({
  notificationId: idSchema
});

export const myNotificationsQuerySchema = z
  .object({
    status: z.nativeEnum(NotificationStatus).optional(),
    type: z.nativeEnum(NotificationType).optional(),
    from: z.coerce.date().optional(),
    to: z.coerce.date().optional()
  })
  .strict()
  .refine((value) => !value.from || !value.to || value.to >= value.from, {
    message: "to must be on or after from",
    path: ["to"]
  });

export const broadcastNotificationSchema = z
  .object({
    companyId: idSchema.optional(),
    title: textSchema.max(200),
    message: textSchema.max(1000),
    type: z.nativeEnum(NotificationType),
    targetRole: z.nativeEnum(RoleName).optional(),
    employeeIds: z.array(idSchema).min(1).optional()
  })
  .strict();

export type MyNotificationsQuery = z.infer<typeof myNotificationsQuerySchema>;
export type BroadcastNotificationInput = z.infer<typeof broadcastNotificationSchema>;
