import { Router } from "express";

import { asyncHandler } from "../../middleware/asyncHandler";
import { requireAuthentication } from "../../middleware/auth.middleware";
import { requireAnyRole } from "../../middleware/role.middleware";
import { validateRequest } from "../../middleware/validation.middleware";
import {
  createDesignationController,
  getDesignationController,
  listDesignationsController,
  updateDesignationController,
  updateDesignationStatusController
} from "./designations.controller";
import {
  createDesignationSchema,
  designationIdParamsSchema,
  designationScopeQuerySchema,
  updateDesignationSchema,
  updateDesignationStatusSchema
} from "./designations.validation";

export const designationsRouter = Router();

designationsRouter.use(requireAuthentication, requireAnyRole(["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN"]));

designationsRouter.post(
  "/",
  validateRequest({ body: createDesignationSchema }, { statusCode: 400 }),
  asyncHandler(createDesignationController)
);
designationsRouter.get(
  "/",
  validateRequest({ query: designationScopeQuerySchema }, { statusCode: 400 }),
  asyncHandler(listDesignationsController)
);
designationsRouter.get(
  "/:designationId",
  validateRequest({ params: designationIdParamsSchema, query: designationScopeQuerySchema }, { statusCode: 400 }),
  asyncHandler(getDesignationController)
);
designationsRouter.patch(
  "/:designationId",
  validateRequest(
    { params: designationIdParamsSchema, query: designationScopeQuerySchema, body: updateDesignationSchema },
    { statusCode: 400 }
  ),
  asyncHandler(updateDesignationController)
);
designationsRouter.patch(
  "/:designationId/status",
  validateRequest(
    { params: designationIdParamsSchema, query: designationScopeQuerySchema, body: updateDesignationStatusSchema },
    { statusCode: 400 }
  ),
  asyncHandler(updateDesignationStatusController)
);
