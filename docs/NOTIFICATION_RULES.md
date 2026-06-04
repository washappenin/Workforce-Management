# NOTIFICATION RULES

Rules for in-app notifications and reminders. Implemented at Checkpoint 13.

## Scope

- CP13 implements in-app notifications only.
- CP13 stores notification records that future attendance, leave, OKR, performance review, and frontend workflows can use.
- CP13 does not implement production SMS delivery, production email delivery, push notification providers, Twilio, mobile push tokens, WebSockets, real-time delivery, reports, dashboards, advanced analytics, AI recommendations, subscriptions, billing, or a background cron scheduler.

## User Notification Access

- User notification endpoints live under `/api/notifications`.
- All user notification endpoints require authentication.
- `GET /api/notifications/me` returns only the authenticated user's notifications.
- `GET /api/notifications/me/unread-count` returns only the authenticated user's unread count.
- `PATCH /api/notifications/:notificationId/read` marks only the authenticated user's notification as read.
- `PATCH /api/notifications/read-all` marks only the authenticated user's unread notifications as read.
- Admins using `/api/notifications/me` still see only their own notifications.
- Cross-user notification access is blocked.

## Notification Types and Statuses

- CP13 uses the existing `NotificationType` enum: `SYSTEM`, `ATTENDANCE`, `LEAVE`, `OKR`, `PERFORMANCE`, `SUBSCRIPTION`, `SECURITY`.
- CP13 uses the existing `NotificationStatus` enum: `UNREAD`, `READ`, `ARCHIVED`.
- New reminder-specific names such as clock-in reminders or OKR reminders are represented by the broad enum type plus title, message, and safe metadata.

## Read Behavior

- New notifications are created as `UNREAD`.
- Marking a notification as read sets `status` to `READ` and sets `readAt`.
- Marking an already-read notification as read is safe and returns the notification without error.
- `read-all` updates only currently unread notifications for the authenticated user and returns the number updated.

## Admin Broadcast

- Admin broadcast uses `POST /api/admin/notifications/broadcast`.
- `COMPANY_ADMIN` and `HR_ADMIN` can broadcast inside their own company.
- `SUPER_ADMIN` can broadcast only with explicit safe `companyId`.
- `MANAGER` and `EMPLOYEE` cannot broadcast.
- Broadcast is company scoped.
- If `employeeIds` are provided, each employee must belong to the resolved company and be active.
- If `targetRole` is provided, recipients must have that role.
- CP13 broadcasts to active employee profiles with active users in active companies.
- CP13 does not send actual SMS, email, or push notifications.

## Internal Helpers

- `createNotificationForUser` creates one in-app notification.
- `createNotificationsForUsers` creates multiple in-app notifications.
- `notifyLeaveStatusChanged`, `notifyOkrPendingUpdate`, `notifyReviewDeadline`, `notifyClockInReminder`, and `notifyClockOutReminder` are adapter-ready helper functions for future modules.
- Existing CP10, CP11, and CP12 flows are not forced to emit notifications in CP13.

## Privacy and Audit

- Notification message content can contain user-facing operational information and should be treated as sensitive.
- Audit logs are written for admin broadcast creation and completion.
- Audit metadata must not include full notification titles or messages.
- Audit metadata may include minimal references such as notification type, target role, requested employee count, recipient count, and notification count.
- Frontend visibility controls are not a security boundary; backend ownership and company scoping are authoritative.

## Future Adapter Path

- External SMS, email, and push delivery should be added behind adapter interfaces in a later checkpoint.
- Future adapters should consume notification records or explicit delivery jobs without changing user notification ownership rules.
- Real-time delivery can be layered later through polling replacement, WebSockets, server-sent events, or push providers once explicitly scoped.
