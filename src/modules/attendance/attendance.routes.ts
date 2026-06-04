import { Router } from "express";

import { asyncHandler } from "../../middleware/asyncHandler";
import { requireAuthentication } from "../../middleware/auth.middleware";
import { requireAnyRole } from "../../middleware/role.middleware";
import { validateRequest } from "../../middleware/validation.middleware";
import {
  clockInController,
  clockOutController,
  listCompanyAttendanceController,
  listMyAttendanceController
} from "./attendance.controller";
import { adminAttendanceQuerySchema, clockInLocationSchema, clockOutLocationSchema, myAttendanceQuerySchema } from "./attendance.validation";

export const attendanceRouter = Router();
export const attendanceAdminRouter = Router();

attendanceRouter.use(requireAuthentication);

attendanceRouter.post(
  "/clock-in",
  validateRequest({ body: clockInLocationSchema }, { statusCode: 400 }),
  asyncHandler(clockInController)
);
attendanceRouter.post(
  "/clock-out",
  validateRequest({ body: clockOutLocationSchema }, { statusCode: 400 }),
  asyncHandler(clockOutController)
);
attendanceRouter.get(
  "/me",
  validateRequest({ query: myAttendanceQuerySchema }, { statusCode: 400 }),
  asyncHandler(listMyAttendanceController)
);

attendanceAdminRouter.use(requireAuthentication, requireAnyRole(["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN"]));

attendanceAdminRouter.get(
  "/",
  validateRequest({ query: adminAttendanceQuerySchema }, { statusCode: 400 }),
  asyncHandler(listCompanyAttendanceController)
);
