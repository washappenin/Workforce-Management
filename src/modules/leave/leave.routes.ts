import { Router } from "express";

import { asyncHandler } from "../../middleware/asyncHandler";
import { requireAuthentication } from "../../middleware/auth.middleware";
import { requireAnyRole } from "../../middleware/role.middleware";
import { validateRequest } from "../../middleware/validation.middleware";
import {
  approveLeaveRequestController,
  createLeaveTypeController,
  getLeaveEntitlementController,
  getLeaveTypeController,
  listAdminLeaveRequestsController,
  listLeaveEntitlementsController,
  listLeaveTypesController,
  listMyLeaveController,
  listTeamLeaveRequestsController,
  rejectLeaveRequestController,
  submitLeaveRequestController,
  updateLeaveEntitlementController,
  updateLeaveTypeController,
  updateLeaveTypeStatusController,
  upsertLeaveEntitlementController
} from "./leave.controller";
import {
  adminLeaveRequestsQuerySchema,
  createLeaveEntitlementSchema,
  createLeaveRequestSchema,
  createLeaveTypeSchema,
  leaveEntitlementIdParamsSchema,
  leaveEntitlementsQuerySchema,
  leaveRequestIdParamsSchema,
  leaveScopeQuerySchema,
  leaveTypeIdParamsSchema,
  myLeaveQuerySchema,
  reviewLeaveRequestSchema,
  updateLeaveEntitlementSchema,
  updateLeaveTypeSchema,
  updateLeaveTypeStatusSchema
} from "./leave.validation";

export const leaveTypesAdminRouter = Router();
export const leaveEntitlementsAdminRouter = Router();
export const leaveRequestsAdminRouter = Router();
export const leaveRouter = Router();

leaveTypesAdminRouter.use(requireAuthentication, requireAnyRole(["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN"]));
leaveEntitlementsAdminRouter.use(requireAuthentication, requireAnyRole(["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN"]));
leaveRequestsAdminRouter.use(requireAuthentication, requireAnyRole(["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN"]));

leaveTypesAdminRouter.post(
  "/",
  validateRequest({ body: createLeaveTypeSchema }, { statusCode: 400 }),
  asyncHandler(createLeaveTypeController)
);
leaveTypesAdminRouter.get(
  "/",
  validateRequest({ query: leaveScopeQuerySchema }, { statusCode: 400 }),
  asyncHandler(listLeaveTypesController)
);
leaveTypesAdminRouter.get(
  "/:leaveTypeId",
  validateRequest({ params: leaveTypeIdParamsSchema, query: leaveScopeQuerySchema }, { statusCode: 400 }),
  asyncHandler(getLeaveTypeController)
);
leaveTypesAdminRouter.patch(
  "/:leaveTypeId",
  validateRequest({ params: leaveTypeIdParamsSchema, query: leaveScopeQuerySchema, body: updateLeaveTypeSchema }, { statusCode: 400 }),
  asyncHandler(updateLeaveTypeController)
);
leaveTypesAdminRouter.patch(
  "/:leaveTypeId/status",
  validateRequest(
    { params: leaveTypeIdParamsSchema, query: leaveScopeQuerySchema, body: updateLeaveTypeStatusSchema },
    { statusCode: 400 }
  ),
  asyncHandler(updateLeaveTypeStatusController)
);

leaveEntitlementsAdminRouter.post(
  "/",
  validateRequest({ body: createLeaveEntitlementSchema }, { statusCode: 400 }),
  asyncHandler(upsertLeaveEntitlementController)
);
leaveEntitlementsAdminRouter.get(
  "/",
  validateRequest({ query: leaveEntitlementsQuerySchema }, { statusCode: 400 }),
  asyncHandler(listLeaveEntitlementsController)
);
leaveEntitlementsAdminRouter.get(
  "/:entitlementId",
  validateRequest({ params: leaveEntitlementIdParamsSchema, query: leaveScopeQuerySchema }, { statusCode: 400 }),
  asyncHandler(getLeaveEntitlementController)
);
leaveEntitlementsAdminRouter.patch(
  "/:entitlementId",
  validateRequest(
    { params: leaveEntitlementIdParamsSchema, query: leaveScopeQuerySchema, body: updateLeaveEntitlementSchema },
    { statusCode: 400 }
  ),
  asyncHandler(updateLeaveEntitlementController)
);

leaveRequestsAdminRouter.get(
  "/",
  validateRequest({ query: adminLeaveRequestsQuerySchema }, { statusCode: 400 }),
  asyncHandler(listAdminLeaveRequestsController)
);

leaveRouter.post(
  "/request",
  requireAuthentication,
  validateRequest({ body: createLeaveRequestSchema }, { statusCode: 400 }),
  asyncHandler(submitLeaveRequestController)
);
leaveRouter.get(
  "/me",
  requireAuthentication,
  validateRequest({ query: myLeaveQuerySchema }, { statusCode: 400 }),
  asyncHandler(listMyLeaveController)
);
leaveRouter.get("/team", requireAuthentication, requireAnyRole(["MANAGER"]), asyncHandler(listTeamLeaveRequestsController));
leaveRouter.patch(
  "/:leaveRequestId/approve",
  requireAuthentication,
  requireAnyRole(["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN", "MANAGER"]),
  validateRequest({ params: leaveRequestIdParamsSchema, query: leaveScopeQuerySchema, body: reviewLeaveRequestSchema }, { statusCode: 400 }),
  asyncHandler(approveLeaveRequestController)
);
leaveRouter.patch(
  "/:leaveRequestId/reject",
  requireAuthentication,
  requireAnyRole(["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN", "MANAGER"]),
  validateRequest({ params: leaveRequestIdParamsSchema, query: leaveScopeQuerySchema, body: reviewLeaveRequestSchema }, { statusCode: 400 }),
  asyncHandler(rejectLeaveRequestController)
);
