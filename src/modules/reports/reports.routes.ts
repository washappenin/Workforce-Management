import { Router } from "express";

import { asyncHandler } from "../../middleware/asyncHandler";
import { requireAuthentication } from "../../middleware/auth.middleware";
import { requireAnyRole } from "../../middleware/role.middleware";
import { validateRequest } from "../../middleware/validation.middleware";
import {
  getAdminAttendanceReportController,
  getAdminDashboardReportController,
  getAdminLeaveReportController,
  getAdminOkrReportController,
  getAdminPerformanceReportController,
  getMyDashboardReportController,
  getSuperAdminCompanyReportsController,
  getSuperAdminDashboardReportController,
  getTeamAttendanceReportController,
  getTeamDashboardReportController,
  getTeamLeaveReportController,
  getTeamOkrReportController,
  getTeamPerformanceReportController
} from "./reports.controller";
import {
  attendanceReportQuerySchema,
  companyScopeReportQuerySchema,
  leaveReportQuerySchema,
  okrReportQuerySchema,
  performanceReportQuerySchema
} from "./reports.validation";

export const adminReportsRouter = Router();
export const teamReportsRouter = Router();
export const selfReportsRouter = Router();
export const superAdminReportsRouter = Router();

adminReportsRouter.use(requireAuthentication, requireAnyRole(["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN"]));
adminReportsRouter.get(
  "/dashboard",
  validateRequest({ query: companyScopeReportQuerySchema }, { statusCode: 400 }),
  asyncHandler(getAdminDashboardReportController)
);
adminReportsRouter.get(
  "/attendance",
  validateRequest({ query: attendanceReportQuerySchema }, { statusCode: 400 }),
  asyncHandler(getAdminAttendanceReportController)
);
adminReportsRouter.get(
  "/leave",
  validateRequest({ query: leaveReportQuerySchema }, { statusCode: 400 }),
  asyncHandler(getAdminLeaveReportController)
);
adminReportsRouter.get(
  "/okrs",
  validateRequest({ query: okrReportQuerySchema }, { statusCode: 400 }),
  asyncHandler(getAdminOkrReportController)
);
adminReportsRouter.get(
  "/performance",
  validateRequest({ query: performanceReportQuerySchema }, { statusCode: 400 }),
  asyncHandler(getAdminPerformanceReportController)
);

teamReportsRouter.use(requireAuthentication, requireAnyRole(["MANAGER"]));
teamReportsRouter.get(
  "/dashboard",
  validateRequest({ query: companyScopeReportQuerySchema }, { statusCode: 400 }),
  asyncHandler(getTeamDashboardReportController)
);
teamReportsRouter.get(
  "/attendance",
  validateRequest({ query: attendanceReportQuerySchema }, { statusCode: 400 }),
  asyncHandler(getTeamAttendanceReportController)
);
teamReportsRouter.get(
  "/leave",
  validateRequest({ query: leaveReportQuerySchema }, { statusCode: 400 }),
  asyncHandler(getTeamLeaveReportController)
);
teamReportsRouter.get(
  "/okrs",
  validateRequest({ query: okrReportQuerySchema }, { statusCode: 400 }),
  asyncHandler(getTeamOkrReportController)
);
teamReportsRouter.get(
  "/performance",
  validateRequest({ query: performanceReportQuerySchema }, { statusCode: 400 }),
  asyncHandler(getTeamPerformanceReportController)
);

selfReportsRouter.use(requireAuthentication);
selfReportsRouter.get("/dashboard", asyncHandler(getMyDashboardReportController));

superAdminReportsRouter.use(requireAuthentication, requireAnyRole(["SUPER_ADMIN"]));
superAdminReportsRouter.get("/dashboard", asyncHandler(getSuperAdminDashboardReportController));
superAdminReportsRouter.get("/companies", asyncHandler(getSuperAdminCompanyReportsController));
