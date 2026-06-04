import { Router } from "express";

import { asyncHandler } from "../../middleware/asyncHandler";
import { requireAuthentication } from "../../middleware/auth.middleware";
import { requireAnyRole } from "../../middleware/role.middleware";
import { validateRequest } from "../../middleware/validation.middleware";
import {
  assignShiftController,
  createShiftController,
  deleteShiftAssignmentController,
  getShiftController,
  listMyShiftAssignmentsController,
  listShiftAssignmentsController,
  listShiftsController,
  updateShiftAssignmentController,
  updateShiftController,
  updateShiftStatusController
} from "./shifts.controller";
import {
  assignShiftSchema,
  createShiftSchema,
  shiftAssignmentIdParamsSchema,
  shiftIdParamsSchema,
  shiftScopeQuerySchema,
  updateShiftAssignmentSchema,
  updateShiftSchema,
  updateShiftStatusSchema
} from "./shifts.validation";

export const shiftsAdminRouter = Router();
export const shiftAssignmentsAdminRouter = Router();
export const shiftsSelfRouter = Router();

shiftsAdminRouter.use(requireAuthentication, requireAnyRole(["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN"]));
shiftAssignmentsAdminRouter.use(requireAuthentication, requireAnyRole(["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN"]));

shiftsAdminRouter.post(
  "/",
  validateRequest({ body: createShiftSchema }, { statusCode: 400 }),
  asyncHandler(createShiftController)
);
shiftsAdminRouter.get(
  "/",
  validateRequest({ query: shiftScopeQuerySchema }, { statusCode: 400 }),
  asyncHandler(listShiftsController)
);
shiftsAdminRouter.get(
  "/:shiftId",
  validateRequest({ params: shiftIdParamsSchema, query: shiftScopeQuerySchema }, { statusCode: 400 }),
  asyncHandler(getShiftController)
);
shiftsAdminRouter.patch(
  "/:shiftId",
  validateRequest({ params: shiftIdParamsSchema, query: shiftScopeQuerySchema, body: updateShiftSchema }, { statusCode: 400 }),
  asyncHandler(updateShiftController)
);
shiftsAdminRouter.patch(
  "/:shiftId/status",
  validateRequest({ params: shiftIdParamsSchema, query: shiftScopeQuerySchema, body: updateShiftStatusSchema }, { statusCode: 400 }),
  asyncHandler(updateShiftStatusController)
);
shiftsAdminRouter.post(
  "/:shiftId/assign",
  validateRequest({ params: shiftIdParamsSchema, query: shiftScopeQuerySchema, body: assignShiftSchema }, { statusCode: 400 }),
  asyncHandler(assignShiftController)
);
shiftsAdminRouter.get(
  "/:shiftId/assignments",
  validateRequest({ params: shiftIdParamsSchema, query: shiftScopeQuerySchema }, { statusCode: 400 }),
  asyncHandler(listShiftAssignmentsController)
);

shiftAssignmentsAdminRouter.patch(
  "/:assignmentId",
  validateRequest(
    { params: shiftAssignmentIdParamsSchema, query: shiftScopeQuerySchema, body: updateShiftAssignmentSchema },
    { statusCode: 400 }
  ),
  asyncHandler(updateShiftAssignmentController)
);
shiftAssignmentsAdminRouter.delete(
  "/:assignmentId",
  validateRequest({ params: shiftAssignmentIdParamsSchema, query: shiftScopeQuerySchema }, { statusCode: 400 }),
  asyncHandler(deleteShiftAssignmentController)
);

shiftsSelfRouter.get("/me", requireAuthentication, asyncHandler(listMyShiftAssignmentsController));
