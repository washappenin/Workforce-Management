import { Router } from "express";

import { asyncHandler } from "../../middleware/asyncHandler";
import { requireAuthentication } from "../../middleware/auth.middleware";
import { requireAnyRole } from "../../middleware/role.middleware";
import { validateRequest } from "../../middleware/validation.middleware";
import {
  createOkrController,
  createOkrProgressController,
  employeeApproveOkrController,
  getOkrController,
  listAdminOkrsController,
  listMyOkrsController,
  listTeamOkrsController,
  managerApproveOkrController,
  updateOkrController,
  updateOkrStatusController
} from "./okrs.controller";
import {
  adminOkrsQuerySchema,
  createOkrProgressSchema,
  createOkrSchema,
  myOkrsQuerySchema,
  okrApprovalSchema,
  okrIdParamsSchema,
  okrScopeQuerySchema,
  updateOkrSchema,
  updateOkrStatusSchema
} from "./okrs.validation";

export const okrsRouter = Router();
export const okrsAdminRouter = Router();

okrsRouter.post(
  "/",
  requireAuthentication,
  requireAnyRole(["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN", "MANAGER"]),
  validateRequest({ body: createOkrSchema }, { statusCode: 400 }),
  asyncHandler(createOkrController)
);
okrsRouter.get(
  "/me",
  requireAuthentication,
  validateRequest({ query: myOkrsQuerySchema }, { statusCode: 400 }),
  asyncHandler(listMyOkrsController)
);
okrsRouter.get("/team", requireAuthentication, requireAnyRole(["MANAGER"]), asyncHandler(listTeamOkrsController));
okrsRouter.get(
  "/:okrId",
  requireAuthentication,
  validateRequest({ params: okrIdParamsSchema, query: okrScopeQuerySchema }, { statusCode: 400 }),
  asyncHandler(getOkrController)
);
okrsRouter.patch(
  "/:okrId",
  requireAuthentication,
  requireAnyRole(["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN", "MANAGER"]),
  validateRequest({ params: okrIdParamsSchema, query: okrScopeQuerySchema, body: updateOkrSchema }, { statusCode: 400 }),
  asyncHandler(updateOkrController)
);
okrsRouter.patch(
  "/:okrId/status",
  requireAuthentication,
  requireAnyRole(["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN", "MANAGER"]),
  validateRequest({ params: okrIdParamsSchema, query: okrScopeQuerySchema, body: updateOkrStatusSchema }, { statusCode: 400 }),
  asyncHandler(updateOkrStatusController)
);
okrsRouter.post(
  "/:okrId/progress",
  requireAuthentication,
  validateRequest({ params: okrIdParamsSchema, body: createOkrProgressSchema }, { statusCode: 400 }),
  asyncHandler(createOkrProgressController)
);
okrsRouter.patch(
  "/:okrId/employee-approve",
  requireAuthentication,
  validateRequest({ params: okrIdParamsSchema, body: okrApprovalSchema }, { statusCode: 400 }),
  asyncHandler(employeeApproveOkrController)
);
okrsRouter.patch(
  "/:okrId/manager-approve",
  requireAuthentication,
  requireAnyRole(["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN", "MANAGER"]),
  validateRequest({ params: okrIdParamsSchema, query: okrScopeQuerySchema, body: okrApprovalSchema }, { statusCode: 400 }),
  asyncHandler(managerApproveOkrController)
);

okrsAdminRouter.use(requireAuthentication, requireAnyRole(["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN"]));
okrsAdminRouter.get(
  "/",
  validateRequest({ query: adminOkrsQuerySchema }, { statusCode: 400 }),
  asyncHandler(listAdminOkrsController)
);
